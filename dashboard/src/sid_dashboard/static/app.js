// Sid Dashboard

const $ = (s) => document.querySelector(s);
const $$ = (s) => document.querySelectorAll(s);

// ── Tab Navigation ──────────────────────────────────────────────────────────

$$(".nav-btn").forEach((btn) => {
  btn.addEventListener("click", () => {
    $$(".nav-btn").forEach((b) => b.classList.remove("active"));
    $$(".tab").forEach((t) => t.classList.remove("active"));
    btn.classList.add("active");
    $(`#tab-${btn.dataset.tab}`).classList.add("active");

    // Load data when switching tabs
    if (btn.dataset.tab === "memory") loadMemories();
    if (btn.dataset.tab === "cron") loadCron();
  });
});

// ── Gateway Status ──────────────────────────────────────────────────────────

async function checkStatus() {
  const indicator = $("#status-indicator");
  try {
    const res = await fetch("/api/memory");
    indicator.classList.toggle("online", res.ok);
    indicator.classList.toggle("offline", !res.ok);
    indicator.title = res.ok ? "Gateway connected" : `Gateway error: ${res.status}`;
  } catch {
    indicator.classList.remove("online");
    indicator.classList.add("offline");
    indicator.title = "Gateway unreachable";
  }
}

checkStatus();
setInterval(checkStatus, 30000);

// ── Chat ────────────────────────────────────────────────────────────────────

const chatMessages = $("#chat-messages");
const chatForm = $("#chat-form");
const chatInput = $("#chat-input");
const chatSend = $("#chat-send");

chatInput.addEventListener("keydown", (e) => {
  if (e.key === "Enter" && !e.shiftKey) {
    e.preventDefault();
    chatForm.dispatchEvent(new Event("submit"));
  }
});

chatForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  const message = chatInput.value.trim();
  if (!message) return;

  appendMessage("user", message);
  chatInput.value = "";
  chatSend.disabled = true;

  const thinking = appendMessage("thinking", "Sid is thinking...");

  try {
    const res = await fetch("/webhook", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message }),
    });

    thinking.remove();

    if (!res.ok) {
      const text = await res.text();
      appendMessage("error", `Error ${res.status}: ${text}`);
      return;
    }

    const data = await res.json();
    const reply = data.response || data.choices?.[0]?.message?.content || JSON.stringify(data);
    appendMessage("assistant", reply);
  } catch (err) {
    thinking.remove();
    appendMessage("error", `Network error: ${err.message}`);
  } finally {
    chatSend.disabled = false;
    chatInput.focus();
  }
});

function appendMessage(type, text) {
  const div = document.createElement("div");
  div.className = `message ${type}`;
  div.textContent = text;
  chatMessages.appendChild(div);
  chatMessages.scrollTop = chatMessages.scrollHeight;
  return div;
}

// ── Memory ──────────────────────────────────────────────────────────────────

let allMemories = [];

async function loadMemories() {
  const list = $("#memory-list");
  list.innerHTML = '<div class="empty loading">Loading memories</div>';

  try {
    const res = await fetch("/api/memory");
    if (!res.ok) throw new Error(`${res.status}`);
    const data = await res.json();
    allMemories = Array.isArray(data) ? data : data.memories || [];
    renderMemories();
  } catch (err) {
    list.innerHTML = `<div class="empty">Failed to load memories: ${err.message}</div>`;
  }
}

function renderMemories(filter = "") {
  const list = $("#memory-list");
  const filtered = filter
    ? allMemories.filter(
        (m) =>
          (m.key || "").toLowerCase().includes(filter) ||
          (m.content || "").toLowerCase().includes(filter) ||
          (m.category || "").toLowerCase().includes(filter)
      )
    : allMemories;

  if (filtered.length === 0) {
    list.innerHTML = `<div class="empty">${filter ? "No matching memories" : "No memories stored"}</div>`;
    return;
  }

  list.innerHTML = filtered
    .map(
      (m) => `
    <div class="card">
      <div class="card-header">
        <span class="card-key">${esc(m.key || m.id || "—")}</span>
        ${m.category ? `<span class="card-category">${esc(m.category)}</span>` : ""}
      </div>
      <div class="card-content">${esc(m.content || "")}</div>
      <div class="card-actions">
        <button class="btn-sm danger" onclick="deleteMemory('${esc(m.key || m.id)}')">Delete</button>
      </div>
    </div>
  `
    )
    .join("");
}

$("#memory-search").addEventListener("input", (e) => {
  renderMemories(e.target.value.toLowerCase());
});

$("#memory-refresh").addEventListener("click", loadMemories);

async function deleteMemory(key) {
  if (!confirm(`Delete memory "${key}"?`)) return;
  try {
    await fetch(`/api/memory/${encodeURIComponent(key)}`, { method: "DELETE" });
    loadMemories();
  } catch (err) {
    alert(`Failed to delete: ${err.message}`);
  }
}

// Make deleteMemory available globally for onclick handlers
window.deleteMemory = deleteMemory;

// ── Cron ────────────────────────────────────────────────────────────────────

async function loadCron() {
  const list = $("#cron-list");
  list.innerHTML = '<div class="empty loading">Loading cron jobs</div>';

  try {
    const res = await fetch("/api/cron");
    if (!res.ok) throw new Error(`${res.status}`);
    const data = await res.json();
    const jobs = Array.isArray(data) ? data : data.jobs || [];
    renderCron(jobs);
  } catch (err) {
    list.innerHTML = `<div class="empty">Failed to load cron: ${err.message}</div>`;
  }
}

function renderCron(jobs) {
  const list = $("#cron-list");

  if (jobs.length === 0) {
    list.innerHTML = '<div class="empty">No cron jobs</div>';
    return;
  }

  list.innerHTML = jobs
    .map(
      (j) => `
    <div class="card">
      <div class="card-header">
        <span class="card-key">${esc(j.name || j.id || "—")}</span>
        <span class="cron-schedule">${esc(j.schedule || "")}</span>
      </div>
      <div class="cron-command">${esc(j.command || "")}</div>
      <div class="card-actions">
        <button class="btn-sm primary" onclick="triggerCron('${esc(j.id)}')">Run Now</button>
        <button class="btn-sm danger" onclick="deleteCron('${esc(j.id)}')">Delete</button>
      </div>
    </div>
  `
    )
    .join("");
}

$("#cron-refresh").addEventListener("click", loadCron);

async function triggerCron(id) {
  try {
    const res = await fetch(`/api/cron/${encodeURIComponent(id)}/run`, { method: "POST" });
    if (!res.ok) throw new Error(`${res.status}`);
    alert("Job triggered.");
  } catch (err) {
    alert(`Failed: ${err.message}`);
  }
}

async function deleteCron(id) {
  if (!confirm("Delete this cron job?")) return;
  try {
    await fetch(`/api/cron/${encodeURIComponent(id)}`, { method: "DELETE" });
    loadCron();
  } catch (err) {
    alert(`Failed: ${err.message}`);
  }
}

window.triggerCron = triggerCron;
window.deleteCron = deleteCron;

// ── Utility ─────────────────────────────────────────────────────────────────

function esc(s) {
  const d = document.createElement("div");
  d.textContent = String(s);
  return d.innerHTML;
}
