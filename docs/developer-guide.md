# WekaCert Developer Guide

## Setup
1. Clone the repository
2. Install backend dependencies: `cd backend && npm install`
3. Install Flutter dependencies: `flutter pub get`
4. Configure `.env` in backend (JWT_SECRET, DB URL)
5. Create `uploads/` directory in backend

## Running
- Backend: `npm run start:dev` (NestJS, loads .env)
- Frontend: `flutter build web --release` then `python3 -m http.server 8081` from `build/web`

## Testing
- Backend: `npm run test`
- Frontend: `flutter test`

## Extending
- Add new document types in `document_category.dart`
- Add new API endpoints in `documents.controller.ts`
- UI changes in `lib/screens/`

## Troubleshooting
- Check `.env` for JWT and DB config
- Ensure backend is running before uploading files
- For file upload errors, check backend logs and `uploads/` permissions

---
For security and privacy, see `security.md`.