# WekaCert Backend (NestJS + PostgreSQL + MinIO)

This service provides first‑party cloud storage for encrypted document payloads.
Client devices perform encryption locally; the backend only stores encrypted blobs
and metadata.

## Features
- Email/password authentication (JWT)
- Document metadata APIs
- MinIO pre‑signed upload/download URLs for encrypted blobs
- User profile endpoint

## Setup
1. Copy `.env.example` to `.env` and fill in values.
2. Start PostgreSQL and MinIO.
3. Install dependencies:
   ```bash
   npm install
   ```
4. Run the service:
   ```bash
   npm run start:dev
   ```

## API Overview
- `POST /auth/register` — register user
- `POST /auth/login` — login user
- `GET /users/me` — current user profile
- `GET /documents` — list user documents
- `POST /documents` — create document
- `POST /documents/:id/upload-url` — get MinIO upload URL
- `POST /documents/:id/versions` — add encrypted version metadata
- `GET /documents/:id/versions` — list versions
- `GET /documents/:id/download-url/:objectKey` — get download URL

## Client-side encryption workflow
1. Client encrypts file locally.
2. Client requests `/documents/:id/upload-url`.
3. Client uploads encrypted payload to MinIO via pre‑signed URL.
4. Client calls `/documents/:id/versions` with objectKey + metadata.

## Security notes
- Keep `JWT_SECRET` private.
- Use HTTPS in production.
- Store only encrypted blobs in MinIO.
