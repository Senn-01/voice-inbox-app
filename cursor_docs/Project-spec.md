# Voice Inbox App — Spec v1.1 (✓ GPT‑4.1)

> Capture voice thoughts on iOS, auto‑transcribe, then triage from a ultra‑thin FastAPI + SQLite web UI.  GPT‑4.1 does the "first‑pass" classification.

---

## 1 • Core Flow

| Step | iOS (app) | Backend (web) |
|------|-----------|---------------|
| **Capture** | SwiftUI button ➜ `AVAudioRecorder` records 8 kHz mono AAC | — |
| **Transcribe** | ① Whisper‑tiny Core ML (offline) → ② OpenAI `/audio/transcriptions` | — |
| **Persist** | Insert in local SQLite ⚑`pending=1`; POST JSON to `/inbox` | `/inbox` inserts into SQLite |
| **Review / sort** | — | HTMX + Alpine list → edit / tag / archive |

---

## 2 • Nice Touches (kept)

* Lock‑screen **swipe‑to‑record** widget.
* Noise‑gate + 8 kHz export.
* **GPT‑4.1 first‑pass classification** (`/classify`).
* Timestamp‑based auto‑chunking.
* Siri shortcut “Hey Siri, Quick Thought”.
* Goal‑driven daily in‑app summary.
* Bidirectional links by UUID.
* Voice‑only triage mode.

*(🚫 Daily‑digest email, keyboard nav, iCloud sync, privacy toggle — intentionally skipped.)*

---

## 3 • Tech Stack (Bare‑bones)

| Layer | Pick | Why |
|-------|------|-----|
| Mobile UI | **SwiftUI + Combine** | Modern, async‑friendly |
| Local DB | **SQLite via GRDB** | Zero‑config, proven |
| Transcribe | Whisper‑tiny Core ML → cloud fallback | Offline‑first |
| Sync/API | **FastAPI 0.111 + SQLite** | One file, async |
| LLM | **GPT‑4.1‑mini** (OpenAI API) | Fast, cheap, tool‑calling |
| Web UI | **HTMX + Alpine.js** | No build step |
| Deploy | Docker → Fly.io / Railway | 1‑liner deploy |

---

## 4 • SQLite Schema

```sql
CREATE TABLE inbox (
    id         TEXT PRIMARY KEY,
    text       TEXT NOT NULL,
    audio_url  TEXT,
    tag        TEXT,
    pending    INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

---

## 5 • iOS Code Snippets

### 5.1 Recorder View (SwiftUI)
```swift
import SwiftUI
import AVFoundation

struct RecorderView: View {
    @StateObject private var vm = RecorderVM()
    var body: some View {
        Button(action: vm.toggle) {
            Image(systemName: vm.isRec ? "stop.circle.fill" : "mic.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(vm.isRec ? .red : .blue)
        }
    }
}

@MainActor
final class RecorderVM: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRec = false
    private var rec: AVAudioRecorder?

    func toggle() { isRec ? stop() : start() }

    private func start() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".m4a")
        let settings: [String:Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 8_000,
            AVNumberOfChannelsKey: 1
        ]
        rec = try? AVAudioRecorder(url: url, settings: settings)
        rec?.delegate = self
        rec?.record(); isRec = true
    }
    private func stop() { rec?.stop(); isRec = false }

    func audioRecorderDidFinishRecording(_ r: AVAudioRecorder, successfully flag: Bool) {
        Task { try await upload(audioURL: r.url) }
    }

    private func upload(audioURL: URL) async throws {
        let txt = try await Transcriber.shared.transcribe(audioURL)
        try await API.send(text: txt, audioURL)
    }
}
```

### 5.2 Transcriber (Whisper → OpenAI fallback)
```swift
import OpenAIKit

actor Transcriber {
    static let shared = Transcriber()
    func transcribe(_ url: URL) async throws -> String {
        if let whisper = WhisperKit.shared {
            return try await whisper.transcribe(url)
        }
        let openai = OpenAI(apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!)
        let res = try await openai.audio.transcriptions.create(
            fileURL: url,
            model: .whisper_1,
            responseFormat: .text)
        return res.text
    }
}
```

---

## 6 • FastAPI Backend (excerpt)
```python
from fastapi import FastAPI, UploadFile, Depends
import sqlite3, uuid, datetime, shutil, os
from openai import OpenAI

app = FastAPI()
DB = "inbox.db"
client = OpenAI()

# --- helpers ---------------------------------------------------

def db_conn():
    cx = sqlite3.connect(DB)
    cx.row_factory = sqlite3.Row
    try:
        yield cx
    finally:
        cx.close()

# --- routes ----------------------------------------------------

@app.post("/inbox")
async def inbox(text: str, audio: UploadFile | None = None, db=Depends(db_conn)):
    uid = str(uuid.uuid4())
    path = None
    if audio:
        path = f"audio/{uid}.m4a"; os.makedirs("audio", exist_ok=True)
        with open(path, "wb") as f: shutil.copyfileobj(audio.file, f)
    db.execute("INSERT INTO inbox VALUES (?,?,?,?,?,?)",
               (uid, text, path, None, 1, datetime.datetime.utcnow()))
    db.commit(); return {"id": uid}

@app.post("/classify/{item_id}")
async def classify(item_id: str, db=Depends(db_conn)):
    row = db.execute("SELECT text FROM inbox WHERE id=?", (item_id,)).fetchone()
    if not row: return {"error": "not found"}
    prompt = "Classify the note as task, idea, or note and suggest one tag. Respond as JSON {category, tag}.\n\n" + row["text"]
    rsp = client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=[{"role":"user","content": prompt}],
        response_format={"type": "json_object"}
    )
    data = rsp.choices[0].message.content
    import json; d=json.loads(data)
    db.execute("UPDATE inbox SET tag=?, pending=0 WHERE id=?", (d["tag"], item_id))
    db.commit(); return d
```

---

## 7 • HTMX Template
```html
<!-- templates/index.html -->
<html>
<head>
  <script src="https://unpkg.com/htmx.org@1.9.8"></script>
  <script src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js" defer></script>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css" />
</head>
<body class="container">
  <h1>Inbox</h1>
  <table hx-get="/items" hx-trigger="load" hx-swap="innerHTML"></table>
</body>
</html>
```

---

## 8 • Containerisation

**requirements.txt**
```text
fastapi==0.111.0
uvicorn[standard]
openai>=1.0.0
python-dotenv
```

**Dockerfile**
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 9 • Roadmap

1. **MVP**: record → whisper → `/inbox` → list.
2. **GPT‑4.1 classify** endpoint and triage UI.
3. Widget & Siri shortcut.
4. Goal summary + voice triage.
5. Swap to Postgres/Supabase if multi‑user.

---

### End of spec

