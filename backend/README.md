# WekaCert Backend (NestJS + PostgreSQL + Encrypted MinIO Storage)

This service provides authenticated document and version management for WekaCert.
Uploaded objects are encrypted with AES-256-GCM before MinIO storage; document
metadata is persisted in PostgreSQL.

## Features
- Email/password authentication (JWT)
- Document metadata APIs
- Multipart file upload and secure file serving
- User profile endpoint

## Setup
1. Copy `.env.example` to `.env` and fill in values.
2. Start PostgreSQL.
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
- `GET /documents/:id` — get document details and versions
- `PATCH /documents/:id` — update document metadata
- `DELETE /documents/:id` — delete document and versions
- `POST /documents/:id/upload` — upload a version file
- `POST /documents/:id/versions/:versionId/backup` — upload an encrypted backup
- `GET /documents/:id/versions/:versionId/backup` — restore an encrypted backup
- `GET /documents/:id/versions` — list versions
- `GET /documents/:id/versions/:versionId/file` — stream a stored file

## File Handling
1. The client uploads a file as multipart form data.
2. The backend encrypts it in memory with `BACKUP_ENCRYPTION_KEY`.
3. The encrypted object is stored in a private MinIO bucket.
4. The backend records the object key in PostgreSQL.
5. Authorized downloads decrypt in memory before responding.

## Security notes
- Keep `JWT_SECRET` and `BACKUP_ENCRYPTION_KEY` private.
- Use HTTPS in production.
- Keep the MinIO bucket private and restrict credentials to this service.
