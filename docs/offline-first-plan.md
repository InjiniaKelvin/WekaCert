# WekaCert Offline-First Implementation Plan

## Current State
WekaCert has a web-first main flow backed by a NestJS API. The app falls back to
cached document metadata when the backend is unavailable, and both mobile files
and browser IndexedDB content are encrypted at rest.

## What Is Already Implemented
- Authenticated web access with JWT login and registration
- Document creation, update, deletion, and versioning through the backend
- File upload and file serving from the backend
- Cached document list and cached document detail fallback for previously synced metadata
- Mobile and browser local-vault document storage, versioning, and encrypted file opening
- PIN and biometric unlock on supported mobile platforms
- Encrypted local and remote backup helpers
- Backup history, restore, and basic conflict-resolution prompt for mobile users

## Offline-First Goal
The goal is to make the app usable without a network connection for the most important document tasks:
- View the local document catalog
- Open stored document content offline
- Create or update documents while offline
- Sync queued changes when connectivity returns

## Implementation Phases
### Phase 1: Metadata Cache
- Keep a local copy of the document list and document detail records.
- Show cached data when the API is unavailable.
- Mark cached records with a sync state.

### Phase 2: Local File Vault
- Store uploaded files locally on the device in an encrypted vault.
- Associate each document version with a local file path.
- Allow offline file preview and offline opening of the latest version.

Status: implemented for mobile and browser local-vault paths.

### Phase 3: Offline Write Queue
- Queue create, edit, delete, and version-upload actions while offline.
- Persist queued operations locally.
- Replay the queue when connectivity is restored.

### Phase 4: Sync and Conflict Handling
- Detect local-vs-remote conflicts.
- Prefer newest timestamps only where safe.
- Offer manual conflict resolution for document metadata and file versions.

Status: backup artifact conflict selection is implemented; metadata sync conflicts
remain future work.

### Phase 5: Reminder and Notification Alignment
- Keep reminder scheduling tied to local document state.
- Ensure notifications work even without a network connection.

## What Is Still Not Implemented
- Browser IndexedDB file encryption is implemented; browser write-queue and
	two-way sync remain future work.
- Offline document creation/editing queue
- Offline version upload queue
- Two-way sync between local storage and backend
- Conflict resolution UX for diverging local and remote changes

## Requirement Summary
- FR1 is met for the active mobile and browser paths with AES-256-GCM content
	envelopes and encrypted backend object storage.
- FR7 is partial: reminder scheduling exists, but a fully unified background notification lifecycle is still not complete.
- FR8 is partial: metadata caching and the mobile local vault are in place, but full browser offline support and sync queueing are not complete.
- FR9 is implemented when MinIO and `BACKUP_ENCRYPTION_KEY` are configured;
	encrypted local backup remains the offline fallback.

## Updated Note
- Encrypted browser storage and remote backup restore are implemented. Offline
  write queues and two-way metadata sync remain the next product increment.

## Recommendation
The codebase is ready for the stated storage, security, reminder, and backup
acceptance tests. The next product increment is Phase 3, adding durable offline
write queues and two-way metadata synchronization.
