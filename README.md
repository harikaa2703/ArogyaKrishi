# 🌾 ArogyaKrishi

> AI-powered crop disease detection and treatment guidance — straight from your phone.

ArogyaKrishi pairs a Flutter mobile app with a FastAPI backend to help farmers identify crop diseases from photos and get actionable treatment recommendations.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Prerequisites](#-prerequisites)
- [Backend Setup](#-backend-setup)
- [Mobile App Setup](#-mobile-app-setup)
- [Project Layout](#-project-layout)

---

## 🧠 Overview

Snap a photo of an affected crop, and ArogyaKrishi analyzes it to detect disease and suggest the right next steps — built for accessibility and ease of use in the field.

---

## ⚙️ Prerequisites

- Python 3.13
- PostgreSQL (local instance)
- Flutter SDK

---

## 🚀 Backend Setup

```bash
cd /home/dead/repos/ArogyaKrishi
bash scripts/setup-postgres.sh
cp .env.example .env

cd app
./venv/bin/pip install -r requirements.txt

PYTHONPATH=/home/dead/repos/ArogyaKrishi:$PYTHONPATH \
./venv/bin/python -m app.db.init_db

PYTHONPATH=/home/dead/repos/ArogyaKrishi:$PYTHONPATH \
./venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

**Health check:**
```bash
curl http://localhost:8001/health
```

---

## 📱 Mobile App Setup

```bash
cd /home/dead/repos/ArogyaKrishi/mobile-app
flutter pub get
flutter run
```

---

## 📂 Project Layout

```
ArogyaKrishi/
├── app/          # FastAPI backend
├── mobile-app/   # Flutter mobile app
└── scripts/      # Setup & helper scripts
```