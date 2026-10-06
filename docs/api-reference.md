# WekaCert Backend API Reference

## Authentication
- `POST /auth/register` — Register user
- `POST /auth/login` — Login user

## User
- `GET /users/me` — Get current user profile

## Documents
- `GET /documents` — List documents
- `POST /documents` — Create document
- `GET /documents/:id` — Get document details and versions
- `PATCH /documents/:id` — Update document
- `DELETE /documents/:id` — Delete document

## File Upload
- `POST /documents/:id/upload` — Upload file (multipart, max 50MB)
- `GET /documents/:id/versions/:versionId/file` — Download file

## Version History
- `GET /documents/:id/versions` — List versions

## Error Handling
- All endpoints return JSON with `message` and `statusCode` on error.
- 401 triggers session expiry; re-login required.

---
For integration details, see `developer-guide.md`.