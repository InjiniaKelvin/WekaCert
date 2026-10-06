# WekaCert

## Overview
WekaCert (Personal Document & Certificate Tracker) is a Flutter-based document manager for Kenyan citizens to securely store and manage personal documents (IDs, certificates, licenses, property papers, and more). The current implementation is web-first with a NestJS backend, JWT sign-in, document versioning, search/filtering, and optional mobile-only backup support.

## Key Features
- Secure document upload through authenticated API calls
- Categorization and searchable metadata (name, type, expiry status)
- Expiry management and reminder settings
- Version history with timestamps and notes
- PIN/biometric access control for supported platforms
- Optional encrypted cloud backup for mobile use

## Delivery Plan
Scrum-inspired sprints cover storage, categorization and expiry tracking, versioning, access control, reminders, search/filter UX, and backup/sync improvements.

## Current Stack
- Flutter frontend
- NestJS backend
- PostgreSQL persistence
- File storage on the backend for uploaded document versions
- SharedPreferences for lightweight session settings
- Local notifications and device-backed secure storage on supported platforms

## Notes
- The app currently has a web-friendly main flow.
- Offline-first local vault behavior is still a roadmap item rather than the primary runtime path.
- Some mobile-only features remain available only on supported devices.
