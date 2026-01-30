## Global Rules (MANDATORY)

- Complete **one checkbox at a time**
- Do **not** combine steps
- Do **not** invent features not listed
- After completing a checkbox:
  - Summarize what was done
  - Ask for explicit confirmation to proceed

- If blocked, return a **mock or stub** instead of skipping

---

## Phase B0: Context & Constraints

- [x] Read and acknowledge `brain.md`
- [x] Read and acknowledge `architecture.md`
- [x] Confirm backend scope only (no UI logic)
- [x] Confirm non-goals (no on-device ML, no production security)

---

## Phase B1: Backend Skeleton (FastAPI)

### B1.1 Repository & Environment

- [x] Initialize Python project
- [x] Create virtual environment instructions
- [x] Define `requirements.txt`
- [x] Pin versions:
  - fastapi
  - uvicorn
  - pillow
  - numpy
  - torch / tensorflow (if used)
  - openai / anthropic (optional)

### B1.2 Base Folder Structure

- [x] Create `app/` package
- [x] Create `app/main.py`
- [ ] Create `app/api/`
- [ ] Create `app/services/`
- [ ] Create `app/models/`
- [ ] Create `app/utils/`
- [ ] Create `app/data/`
- [ ] Create `app/config.py`

### B1.3 App Bootstrapping

- [x] Initialize FastAPI app
- [x] Add CORS middleware
- [x] Add startup event handler
- [x] Add shutdown handler

### B1.4 Health & Sanity

- [x] Add `/health` endpoint
- [x] Add `/version` endpoint
- [ ] Verify app runs via Uvicorn

---

## 🔹 Phase B2: Database Setup

> **DB Choice:** SQLite (via SQLAlchemy)
> **Scope:** detection events only
> **Non-goals:** auth, users, analytics

### B2.1 Database Configuration

- [ ] Configure SQLite connection URL
- [ ] Create async SQLAlchemy engine
- [ ] Create async session factory
- [ ] Isolate DB config in `app/db/session.py`

### B2.2 Database Models

- [ ] Define `DetectionEvent` ORM model
- [ ] Fields:
  - id
  - disease
  - latitude
  - longitude
  - confidence
  - created_at

- [ ] Add DB base model

### B2.3 Table Initialization

- [ ] Create DB initialization logic
- [ ] Run table creation at startup
- [ ] Ensure idempotent creation

### B2.4 Repository Layer

- [ ] Create detection event repository
- [ ] Implement `save_event()`
- [ ] Implement `get_events_within_radius()`
- [ ] Keep DB logic out of API routes

---

## Phase B2: Image Upload & Preprocessing

### B2.1 Image Input Handling

- [ ] Accept multipart image upload
- [ ] Validate file type (jpg/png)
- [ ] Enforce file size limit
- [ ] Handle invalid image gracefully

### B2.2 Image Preprocessing

- [ ] Convert image to RGB
- [ ] Resize to model input size
- [ ] Normalize pixel values
- [ ] Isolate preprocessing logic into utility function

---

## Phase B3: Plant Disease Detection (ML)

### B3.1 Model Strategy

- [ ] Select pretrained plant disease model
- [ ] Document model source
- [ ] Document accuracy & limitations
- [ ] Define input/output schema

### B3.2 Model Loading

- [ ] Implement model loader
- [ ] Load model at startup
- [ ] Ensure model loads once only
- [ ] Handle model load failure

### B3.3 Inference Logic

- [ ] Implement inference function
- [ ] Map logits → disease label
- [ ] Compute confidence score
- [ ] Apply confidence threshold

### B3.4 Mock Fallback

- [ ] Implement mock inference logic
- [ ] Toggle via environment variable
- [ ] Ensure API works without real model

---

## Phase B4: Detection API

- [ ] Implement `POST /detect-image`
- [ ] Connect preprocessing
- [ ] Connect inference
- [ ] Return:
  - crop
  - disease
  - confidence

- [ ] Handle low-confidence output
- [ ] Return stable JSON schema

---

## Phase B5: Remedies & Guidance

### B5.1 Disease Knowledge Base

- [ ] Create disease → remedy JSON
- [ ] Limit to selected crops/diseases
- [ ] Include:
  - symptoms
  - remedies
  - prevention tips

### B5.2 Remedy Service

- [ ] Load remedy data at startup
- [ ] Lookup remedies by disease
- [ ] Handle unknown disease safely

### B5.3 API Integration

- [ ] Attach remedies to detection response
- [ ] Add advisory disclaimer field

---

## Phase B6: Language Support (Backend)

- [ ] Select supported languages
- [ ] Create translation mappings
- [ ] Translate:
  - disease names
  - remedy steps

- [ ] Add `language` parameter
- [ ] Fallback to English

---

## Phase B7: Nearby Disease Alerts

### B7.1 Detection Event Storage

- [ ] Define event schema
- [ ] Store:
  - disease
  - lat
  - lng
  - timestamp
  - confidence

### B7.2 Geo Logic

- [ ] Implement distance calculation
- [ ] Filter events within 2 km
- [ ] Apply confidence threshold

### B7.3 Alerts API

- [ ] Implement `GET /nearby-alerts`
- [ ] Return soft alerts
- [ ] Avoid panic wording

---

## Phase B8: GPT Advisory (Optional)

### B8.1 Scope & Safety

- [ ] Mark advisory as non-authoritative
- [ ] Define safe boundaries

### B8.2 Prompt

- [ ] Create fixed prompt template
- [ ] Restrict to general advice
- [ ] Prevent chemical/regulatory claims

### B8.3 Integration

- [ ] Call LLM with crop+disease+medicine
- [ ] Attach advisory text
- [ ] Fail gracefully

---

## Phase B9: Offline Support (Backend Awareness)

- [ ] Document offline assumptions
- [ ] Ensure backend is offline-agnostic
- [ ] Provide disease metadata endpoint

---

## Phase B10: Safety & Guardrails

- [ ] Add disclaimers
- [ ] Handle misclassification messaging
- [ ] Add structured error logging

---

## Phase B11: Documentation & Demo

- [ ] Verify OpenAPI docs
- [ ] Add sample requests
- [ ] Add sample responses
- [ ] Confirm Flutter/React compatibility
