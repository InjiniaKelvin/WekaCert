# WekaCert Documentation

## Overview
WekaCert is a secure document and certificate tracker for Kenyan citizens. It enables encrypted storage, expiry tracking, version history, and optional cloud backup for personal documents (IDs, certificates, licenses, property papers, etc.).

## Architecture
- **Frontend:** Flutter web/mobile app
- **Backend:** NestJS REST API, PostgreSQL, disk storage (multer)

## Features
- Secure document upload (any file type, up to 50MB)
- Categorization, expiry management, version history
- PIN/biometric access control
- Search, filter, reminders
- Optional encrypted cloud backup

## Quickstart
1. Clone the repo and install dependencies
2. Configure backend `.env` (JWT_SECRET, DB, etc.)
3. Start backend: `npm run start:dev` (NestJS)
4. Build frontend: `flutter build web --release`
5. Serve frontend: `python3 -m http.server 8081` from `build/web`

## Directory Structure
- `lib/` — Flutter app
- `backend/` — NestJS API
- `docs/` — Documentation

---
See `user-manual.md` for usage instructions, `api-reference.md` for API details, and `developer-guide.md` for setup and extension.