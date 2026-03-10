//! OpenAI-to-Anthropic translation proxy for `/v1/chat/completions`.
//!
//! Translates OpenAI Chat Completions format to Anthropic Messages API,
//! streams responses back as OpenAI-compatible SSE chunks. Designed for
//! Home Assistant's `extended_openai_conversation` integration.

use super::AppState;
use axum::{
    extract::State,
    http::StatusCode,
    response::{
        sse::{Event, KeepAlive, Sse},
        IntoResponse, Json,
    },
};
use futures::stream::{Stream, StreamExt};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::sync::OnceLock;
use tokio::io::AsyncBufReadExt;
use tokio_util::io::StreamReader;

// ── Static clients ──

static PROXY_CLIENT: OnceLock<Client> = OnceLock::new();
static IDENTITY_CACHE: OnceLock<Option<String>> = OnceLock::new();

fn get_client() -> &'static Client {
    PROXY_CLIENT.get_or_init(|| {
        Client::builder()
            .connect_timeout(std::time::Duration::from_secs(10))
            .build()
            .expect("failed to build reqwest client")
    })
}

fn get_identity() -> Option<&'static str> {
    IDENTITY_CACHE
        .get_or_init(|| {
            let workspace = std::env::var("ZEROCLAW_WORKSPACE")
                .unwrap_or_else(|_| "/var/lib/sid/.zeroclaw/workspace".to_string());
            let path = std::path::Path::new(&workspace).join("IDENTITY.md");
            match std::fs::read_to_string(&path) {
                Ok(content) if !content.trim().is_empty() => {
                    tracing::info!("Loaded identity from {}", path.display());
                    Some(content)
                }
                Ok(_) => None,
                Err(e) => {
                    tracing::warn!("Could not read {}: {e}", path.display());
                    None
                }
            }
        })
        .as_deref()
}

// ── OpenAI request types ──

#[derive(Debug, Deserialize)]
pub struct ChatCompletionsRequest {
    pub messages: Vec<OaiMessage>,
    #[serde(default)]
    pub model: Option<String>,
    #[serde(default)]
    pub stream: Option<bool>,
    #[serde(default)]
    pub tools: Option<Vec<OaiTool>>,
    #[serde(default)]
    pub max_tokens: Option<u32>,
    #[serde(default)]
    pub temperature: Option<f64>,
}

#[derive(Debug, Deserialize)]
pub struct OaiMessage {
    pub role: String,
    #[serde(default)]
    pub content: Option<serde_json::Value>,
    #[serde(default)]
    pub tool_calls: Option<Vec<OaiToolCall>>,
    #[serde(default)]
    pub tool_call_id: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct OaiToolCall {
    pub id: String,
    pub function: OaiFunction,
}

#[derive(Debug, Deserialize)]
pub struct OaiFunction {
    pub name: String,
    #[serde(default)]
    pub arguments: String,
}

#[derive(Debug, Deserialize)]
pub struct OaiTool {
    pub function: OaiToolFunction,
}

#[derive(Debug, Deserialize)]
pub struct OaiToolFunction {
    pub name: String,
    #[serde(default)]
    pub description: Option<String>,
    #[serde(default)]
    pub parameters: Option<serde_json::Value>,
}

// ── Anthropic request types ──

#[derive(Debug, Serialize)]
struct AnthropicRequest {
    model: String,
    max_tokens: u32,
    #[serde(skip_serializing_if = "Option::is_none")]
    system: Option<String>,
    messages: Vec<AnthropicMessage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tools: Option<Vec<AnthropicTool>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    temperature: Option<f64>,
    stream: bool,
}

#[derive(Debug, Serialize)]
struct AnthropicMessage {
    role: String,
    content: serde_json::Value,
}

#[derive(Debug, Serialize)]
struct AnthropicTool {
    name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    description: Option<String>,
    input_schema: serde_json::Value,
}

// ── Translation ──

fn translate_messages(messages: &[OaiMessage]) -> (Option<String>, Vec<AnthropicMessage>) {
    let mut system_parts: Vec<String> = Vec::new();
    let mut anthropic_msgs: Vec<AnthropicMessage> = Vec::new();

    // Prepend identity
    if let Some(identity) = get_identity() {
        system_parts.push(identity.to_string());
    }

    for msg in messages {
        match msg.role.as_str() {
            "system" => {
                if let Some(content) = &msg.content {
                    let text = content_to_string(content);
                    if !text.is_empty() {
                        system_parts.push(text);
                    }
                }
            }
            "user" => {
                let text = msg
                    .content
                    .as_ref()
                    .map(content_to_string)
                    .unwrap_or_default();
                if !text.is_empty() {
                    anthropic_msgs.push(AnthropicMessage {
                        role: "user".to_string(),
                        content: serde_json::Value::String(text),
                    });
                }
            }
            "assistant" => {
                if let Some(tool_calls) = &msg.tool_calls {
                    // Assistant with tool_calls → content blocks
                    let mut blocks: Vec<serde_json::Value> = Vec::new();
                    // Include text content if present
                    if let Some(content) = &msg.content {
                        let text = content_to_string(content);
                        if !text.is_empty() {
                            blocks.push(serde_json::json!({"type": "text", "text": text}));
                        }
                    }
                    for tc in tool_calls {
                        let input: serde_json::Value =
                            serde_json::from_str(&tc.function.arguments).unwrap_or_default();
                        blocks.push(serde_json::json!({
                            "type": "tool_use",
                            "id": tc.id,
                            "name": tc.function.name,
                            "input": input,
                        }));
                    }
                    anthropic_msgs.push(AnthropicMessage {
                        role: "assistant".to_string(),
                        content: serde_json::Value::Array(blocks),
                    });
                } else {
                    let text = msg
                        .content
                        .as_ref()
                        .map(content_to_string)
                        .unwrap_or_default();
                    anthropic_msgs.push(AnthropicMessage {
                        role: "assistant".to_string(),
                        content: serde_json::Value::String(text),
                    });
                }
            }
            "tool" => {
                // Tool results must be user messages in Anthropic format.
                // Merge adjacent tool results into a single user message.
                let tool_result = serde_json::json!({
                    "type": "tool_result",
                    "tool_use_id": msg.tool_call_id.as_deref().unwrap_or(""),
                    "content": msg.content.as_ref().map(content_to_string).unwrap_or_default(),
                });

                // If last message is a user with tool_result blocks, append to it
                if let Some(last) = anthropic_msgs.last_mut() {
                    if last.role == "user" {
                        if let serde_json::Value::Array(ref mut arr) = last.content {
                            if arr
                                .first()
                                .and_then(|v| v.get("type"))
                                .and_then(|t| t.as_str())
                                == Some("tool_result")
                            {
                                arr.push(tool_result);
                                continue;
                            }
                        }
                    }
                }
                // Start new user message with tool_result block
                anthropic_msgs.push(AnthropicMessage {
                    role: "user".to_string(),
                    content: serde_json::Value::Array(vec![tool_result]),
                });
            }
            _ => {} // skip unknown roles
        }
    }

    let system = if system_parts.is_empty() {
        None
    } else {
        Some(system_parts.join("\n\n---\n\n"))
    };

    (system, anthropic_msgs)
}

fn content_to_string(v: &serde_json::Value) -> String {
    match v {
        serde_json::Value::String(s) => s.clone(),
        _ => v.to_string(),
    }
}

fn translate_tools(tools: &[OaiTool]) -> Vec<AnthropicTool> {
    tools
        .iter()
        .map(|t| AnthropicTool {
            name: t.function.name.clone(),
            description: t.function.description.clone(),
            input_schema: t
                .function
                .parameters
                .clone()
                .unwrap_or(serde_json::json!({"type": "object", "properties": {}})),
        })
        .collect()
}

// ── Auth ──

struct AuthHeaders {
    headers: Vec<(String, String)>,
}

fn get_auth() -> Result<AuthHeaders, String> {
    let token = std::env::var("ANTHROPIC_OAUTH_TOKEN")
        .map_err(|_| "ANTHROPIC_OAUTH_TOKEN not set".to_string())?;

    if token.starts_with("sk-ant-oat01-") || token.contains('.') {
        // OAuth token (JWT or setup token)
        Ok(AuthHeaders {
            headers: vec![
                ("authorization".to_string(), format!("Bearer {token}")),
                (
                    "anthropic-beta".to_string(),
                    "oauth-2025-04-20".to_string(),
                ),
            ],
        })
    } else {
        // API key
        Ok(AuthHeaders {
            headers: vec![("x-api-key".to_string(), token)],
        })
    }
}

// ── Handler ──

pub async fn handle_chat_completions(
    State(state): State<AppState>,
    body: Result<Json<ChatCompletionsRequest>, axum::extract::rejection::JsonRejection>,
) -> impl IntoResponse {
    let Json(req) = match body {
        Ok(b) => b,
        Err(e) => {
            tracing::warn!("/v1/chat/completions JSON parse error: {e}");
            return error_response(
                StatusCode::BAD_REQUEST,
                &format!("Invalid JSON: {e}"),
                "invalid_request_error",
            )
            .into_response();
        }
    };

    // Log incoming request for debugging HA tool definitions
    tracing::info!(
        "/v1/chat/completions request: model={:?}, stream={:?}, tools={}, messages={}",
        req.model,
        req.stream,
        req.tools.as_ref().map(|t| {
            let names: Vec<&str> = t.iter().map(|tool| tool.function.name.as_str()).collect();
            format!("{names:?}")
        }).unwrap_or_else(|| "none".to_string()),
        req.messages.len(),
    );
    if let Some(ref tools) = req.tools {
        for tool in tools {
            tracing::debug!(
                "  tool: {} — params: {}",
                tool.function.name,
                tool.function.parameters.as_ref()
                    .map(|p| serde_json::to_string(p).unwrap_or_default())
                    .unwrap_or_else(|| "none".to_string()),
            );
        }
    }

    let auth = match get_auth() {
        Ok(a) => a,
        Err(msg) => {
            return error_response(StatusCode::INTERNAL_SERVER_ERROR, &msg, "auth_error")
                .into_response();
        }
    };

    let (system, messages) = translate_messages(&req.messages);
    let tools = req.tools.as_ref().map(|t| translate_tools(t));
    let is_stream = req.stream.unwrap_or(false);

    let anthropic_req = AnthropicRequest {
        model: state.model.clone(),
        max_tokens: req.max_tokens.unwrap_or(4096),
        system,
        messages,
        tools,
        temperature: req.temperature,
        stream: is_stream,
    };

    let client = get_client();
    let mut request_builder = client
        .post("https://api.anthropic.com/v1/messages")
        .header("content-type", "application/json")
        .header("anthropic-version", "2023-06-01");

    for (key, value) in &auth.headers {
        request_builder = request_builder.header(key.as_str(), value.as_str());
    }

    let response = match request_builder.json(&anthropic_req).send().await {
        Ok(r) => r,
        Err(e) => {
            tracing::error!("Anthropic API connection error: {e}");
            return error_response(StatusCode::BAD_GATEWAY, &e.to_string(), "connection_error")
                .into_response();
        }
    };

    if !response.status().is_success() {
        let status = response.status().as_u16();
        let body = response.text().await.unwrap_or_default();
        tracing::error!("Anthropic API error {status}: {body}");
        let code = if status == 429 {
            StatusCode::TOO_MANY_REQUESTS
        } else {
            StatusCode::BAD_GATEWAY
        };
        return error_response(code, &body, "upstream_error").into_response();
    }

    if is_stream {
        handle_streaming(response).into_response()
    } else {
        handle_non_streaming(response).await.into_response()
    }
}

// ── Non-streaming ──

async fn handle_non_streaming(
    response: reqwest::Response,
) -> Result<Json<serde_json::Value>, (StatusCode, Json<serde_json::Value>)> {
    let body: serde_json::Value = response
        .json()
        .await
        .map_err(|e| error_response(StatusCode::BAD_GATEWAY, &e.to_string(), "parse_error"))?;

    let mut text_content = String::new();
    let mut tool_calls: Vec<serde_json::Value> = Vec::new();
    if let Some(content) = body.get("content").and_then(|c| c.as_array()) {
        for block in content {
            match block.get("type").and_then(|t| t.as_str()) {
                Some("text") => {
                    if let Some(t) = block.get("text").and_then(|t| t.as_str()) {
                        text_content.push_str(t);
                    }
                }
                Some("tool_use") => {
                    tool_calls.push(serde_json::json!({
                        "id": block.get("id").and_then(|i| i.as_str()).unwrap_or(""),
                        "type": "function",
                        "function": {
                            "name": block.get("name").and_then(|n| n.as_str()).unwrap_or(""),
                            "arguments": block.get("input").map(|i| i.to_string()).unwrap_or_else(|| "{}".to_string()),
                        }
                    }));
                }
                _ => {}
            }
        }
    }

    let stop_reason = body
        .get("stop_reason")
        .and_then(|s| s.as_str())
        .unwrap_or("end_turn");
    let finish_reason = if stop_reason == "tool_use" {
        "tool_calls"
    } else {
        "stop"
    };

    let usage = body.get("usage").cloned().unwrap_or(serde_json::json!({}));
    let mut message = serde_json::json!({
        "role": "assistant",
        "content": if text_content.is_empty() { serde_json::Value::Null } else { serde_json::Value::String(text_content) },
    });
    if !tool_calls.is_empty() {
        message["tool_calls"] = serde_json::Value::Array(tool_calls);
    }

    Ok(Json(serde_json::json!({
        "id": format!("chatcmpl-{}", uuid::Uuid::new_v4()),
        "object": "chat.completion",
        "model": body.get("model").and_then(|m| m.as_str()).unwrap_or("sid"),
        "choices": [{
            "index": 0,
            "message": message,
            "finish_reason": finish_reason,
        }],
        "usage": {
            "prompt_tokens": usage.get("input_tokens").and_then(|t| t.as_u64()).unwrap_or(0),
            "completion_tokens": usage.get("output_tokens").and_then(|t| t.as_u64()).unwrap_or(0),
            "total_tokens": usage.get("input_tokens").and_then(|t| t.as_u64()).unwrap_or(0)
                + usage.get("output_tokens").and_then(|t| t.as_u64()).unwrap_or(0),
        }
    })))
}

// ── Streaming ──

fn handle_streaming(
    response: reqwest::Response,
) -> Sse<impl Stream<Item = Result<Event, std::convert::Infallible>>> {
    let stream = async_stream::stream! {
        let chat_id = format!("chatcmpl-{}", uuid::Uuid::new_v4());

        // Send initial role chunk
        let initial = oai_chunk(&chat_id, serde_json::json!({"role": "assistant"}), None);
        yield Ok(Event::default().data(serde_json::to_string(&initial).unwrap_or_default()));

        let byte_stream = response
            .bytes_stream()
            .map(|r| r.map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e)));
        let reader = StreamReader::new(byte_stream);
        let mut lines = reader.lines();

        let mut current_event = String::new();
        let mut tool_index: i32 = -1;

        while let Ok(Some(line)) = lines.next_line().await {
            if line.starts_with("event: ") {
                current_event = line[7..].to_string();
                continue;
            }

            if !line.starts_with("data: ") {
                continue;
            }

            let data = &line[6..];
            let parsed: serde_json::Value = match serde_json::from_str(data) {
                Ok(v) => v,
                Err(_) => continue,
            };

            match current_event.as_str() {
                "content_block_start" => {
                    let block_type = parsed
                        .get("content_block")
                        .and_then(|b| b.get("type"))
                        .and_then(|t| t.as_str())
                        .unwrap_or("");

                    if block_type == "tool_use" {
                        tool_index += 1;
                        let block = parsed.get("content_block").unwrap();
                        let id = block.get("id").and_then(|i| i.as_str()).unwrap_or("");
                        let name = block.get("name").and_then(|n| n.as_str()).unwrap_or("");

                        let delta = serde_json::json!({
                            "tool_calls": [{
                                "index": tool_index,
                                "id": id,
                                "type": "function",
                                "function": {"name": name, "arguments": ""}
                            }]
                        });
                        let chunk = oai_chunk(&chat_id, delta, None);
                        yield Ok(Event::default().data(serde_json::to_string(&chunk).unwrap_or_default()));
                    }
                    // text block start: no-op
                }
                "content_block_delta" => {
                    let delta_type = parsed
                        .get("delta")
                        .and_then(|d| d.get("type"))
                        .and_then(|t| t.as_str())
                        .unwrap_or("");

                    match delta_type {
                        "text_delta" => {
                            let text = parsed
                                .get("delta")
                                .and_then(|d| d.get("text"))
                                .and_then(|t| t.as_str())
                                .unwrap_or("");
                            let delta = serde_json::json!({"content": text});
                            let chunk = oai_chunk(&chat_id, delta, None);
                            yield Ok(Event::default().data(serde_json::to_string(&chunk).unwrap_or_default()));
                        }
                        "input_json_delta" => {
                            let partial = parsed
                                .get("delta")
                                .and_then(|d| d.get("partial_json"))
                                .and_then(|t| t.as_str())
                                .unwrap_or("");
                            let delta = serde_json::json!({
                                "tool_calls": [{
                                    "index": tool_index,
                                    "function": {"arguments": partial}
                                }]
                            });
                            let chunk = oai_chunk(&chat_id, delta, None);
                            yield Ok(Event::default().data(serde_json::to_string(&chunk).unwrap_or_default()));
                        }
                        _ => {}
                    }
                }
                "message_delta" => {
                    let stop_reason = parsed
                        .get("delta")
                        .and_then(|d| d.get("stop_reason"))
                        .and_then(|s| s.as_str())
                        .unwrap_or("");

                    let finish_reason = match stop_reason {
                        "tool_use" => "tool_calls",
                        _ => "stop",
                    };

                    let chunk = oai_chunk(
                        &chat_id,
                        serde_json::json!({}),
                        Some(finish_reason),
                    );
                    yield Ok(Event::default().data(serde_json::to_string(&chunk).unwrap_or_default()));
                }
                "message_stop" => {
                    yield Ok(Event::default().data("[DONE]".to_string()));
                }
                _ => {}
            }
        }
    };

    Sse::new(stream).keep_alive(KeepAlive::default())
}

fn oai_chunk(
    id: &str,
    delta: serde_json::Value,
    finish_reason: Option<&str>,
) -> serde_json::Value {
    serde_json::json!({
        "id": id,
        "object": "chat.completion.chunk",
        "model": "sid",
        "choices": [{
            "index": 0,
            "delta": delta,
            "finish_reason": finish_reason,
        }]
    })
}

fn error_response(
    status: StatusCode,
    message: &str,
    error_type: &str,
) -> (StatusCode, Json<serde_json::Value>) {
    (
        status,
        Json(serde_json::json!({
            "error": {
                "message": message,
                "type": error_type,
            }
        })),
    )
}
