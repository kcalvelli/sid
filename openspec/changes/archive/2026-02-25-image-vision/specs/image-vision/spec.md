## ADDED Requirements

### Requirement: Anthropic provider supports vision content blocks
The Anthropic provider SHALL convert `[IMAGE:data:mime;base64,...]` markers in user messages into Claude vision API `image` content blocks with `source.type = "base64"`.

#### Scenario: User message with one image
- **WHEN** a user message contains text and one `[IMAGE:data:image/png;base64,payload]` marker
- **THEN** the Anthropic API request contains a `content` array with a `text` block and an `image` block with `source.media_type = "image/png"` and `source.data = "payload"`

#### Scenario: User message with multiple images
- **WHEN** a user message contains text and multiple `[IMAGE:...]` markers
- **THEN** each marker is converted to a separate `image` content block in the request

#### Scenario: User message with no images
- **WHEN** a user message contains no `[IMAGE:...]` markers
- **THEN** the message is sent as a single `text` content block (existing behavior unchanged)

#### Scenario: Assistant and tool messages unchanged
- **WHEN** an assistant or tool message is processed
- **THEN** the message handling is unchanged regardless of any `[IMAGE:...]` text

### Requirement: Image content blocks use correct API format
Each image content block SHALL serialize to the Claude vision API format: `{"type": "image", "source": {"type": "base64", "media_type": "<mime>", "data": "<payload>"}}`.

#### Scenario: Correct serialization
- **WHEN** an image block is serialized for the API request
- **THEN** it contains `type: "image"` with nested `source` object containing `type: "base64"`, the original `media_type`, and the base64 `data`
