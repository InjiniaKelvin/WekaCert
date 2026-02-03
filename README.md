# WekaCert

## Overview
WekaCert (Personal Document & Certificate Tracker) is a mobile app concept for Kenyan citizens to securely store and manage personal documents (IDs, certificates, licenses, property papers, and more). It provides an encrypted local vault for PDFs/images/scans, supports expirable and permanent documents, and enables fast offline access.

## Key Features
- Secure document upload and encrypted local storage
- Categorization and searchable metadata (name, type, expiry status)
- Expiry management with local reminders and notifications
- Version history with timestamps and renewal notes
- PIN/biometric access control
- Optional encrypted cloud backup for multi-device recovery

## Delivery Plan
Scrum-inspired sprints cover secure storage and upload, categorization and expiry tracking, versioning, access control, reminders, search/filter UX, and optional cloud sync.

## Proposed Stack
- Flutter (cross-platform) or Kotlin (Android-native)
- Encrypted SQLite (SQLCipher)
- KeyStore/KeyChain for key management
- Local notifications for reminders
- Optional Firebase/Google Drive encrypted backups
