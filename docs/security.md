# WekaCert Security & Privacy

## Encryption
- Mobile and browser document content uses authenticated AES-256-GCM envelopes
	before it is written to private files or IndexedDB.
- Keys are managed via device KeyStore/KeyChain where supported.
- Backend objects are encrypted with AES-256-GCM before MinIO storage and are
	decrypted only after owner authorization.
- Remote backup uploads contain the client-encrypted artifact and are encrypted
	again by the backend storage layer.

## Authentication
- JWT-based email/password login
- PIN/biometric access for app

## Data Storage
- Metadata is stored in PostgreSQL and document objects are stored in MinIO.
- Files are accepted in memory, encrypted, and never written to the backend
	filesystem in plaintext.
- Authenticated downloads decrypt in memory after document ownership checks.

## Privacy
- User email and token stored securely
- No third-party analytics

## Recommendations
- Use strong passwords
- Enable PIN/biometric for sensitive documents
- Keep JWT_SECRET private in backend
- Use HTTPS in production

## Operational Requirements
- Set a long random `BACKUP_ENCRYPTION_KEY` and keep it stable for the lifetime
	of stored objects. Rotating it requires a re-encryption migration.
- Configure MinIO with private buckets and use HTTPS for API traffic.
- Configure Android notification permissions and exact alarms where required by
	the device policy.

---
For compliance and technical details, see `developer-guide.md`.