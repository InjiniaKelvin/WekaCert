**Personal Document & Certificate Tracker - Requirements Document**

---

# 1. Problem Statement

Kenya’s citizens face persistent challenges in managing personal documents and certificates. Important documents—such as national IDs, birth certificates, academic certificates, licenses, and property papers—are often misplaced, lost, or forgotten. Expirable documents frequently lapse without notice, resulting in penalties, repeated visits to offices, or denial of services. On the other hand, non-expirable documents require safe, organized storage but lack secure, easily accessible solutions.

Currently, most Kenyans rely on physical storage or informal digital solutions (e.g., WhatsApp or phone gallery), which are insecure, unorganized, and lack reminders. This inefficiency wastes time, increases stress, and exposes citizens to fraud or bureaucratic delays.

**Goal:**
To design and develop a mobile application that allows users to securely store personal documents and certificates, track expiry dates where applicable, maintain versioned histories, and provide timely reminders for renewals—all while supporting permanent documents that do not require updates.

---

# 2. User Needs / Requirements

## Functional Requirements

| ID | Requirement | Description | Rationale / User Need |
|----|------------|-------------|---------------------|
| FR1 | Document Upload & Storage | Upload PDFs/images/scans and store in encrypted local storage | Users need a secure vault for all documents |
| FR2 | Categorization | Tag documents: ID, Certificate, License, Property, Other | Users can quickly find and organize documents |
| FR3 | Expiry Management | Mark documents as expirable or permanent, input expiry dates | Users want reminders for expiring documents |
| FR4 | Versioning | Maintain history of document updates, with timestamp & notes | Track renewals, prevent data loss |
| FR5 | Access Control | PIN and biometric login | Security and privacy for sensitive documents |
| FR6 | Search & Filter | Search by name/type, filter by expiry/permanent | Users can retrieve documents efficiently |
| FR7 | Notifications & Reminders | Alert user for upcoming expiries | Prevent missed renewals |
| FR8 | Offline Support | App must work fully offline | Internet connectivity is unreliable in Kenya |
| FR9 | Optional Backup | Encrypted cloud backup for multi-device use | Users want disaster recovery |

## Non-Functional Requirements

| Category | Requirement | Metric / Evaluation |
|----------|------------|------------------|
| Security | AES-256 encryption, KeyStore/KeyChain management | Data cannot be read outside the app |
| Performance | App should load 100 documents in <2 seconds | Fast access to documents |
| Usability | Intuitive UI, minimal clicks to upload/retrieve | Users can operate app without tech knowledge |
| Reliability | No data loss, crash recovery, versioning | All documents retrievable even after failure |
| Scalability | Support hundreds of documents per user | App remains responsive as data grows |
| Portability | Cross-platform (Flutter) or Android-native | Works on common Kenyan devices |
| Maintainability | Modular code, clean architecture | Easy to update/extend app in future |

---

# 3. Requirements Modeling

## Use Cases

1. **Upload Document**
   - Actors: User
   - Steps:
     1. Open app → select “Upload Document”
     2. Choose file from device
     3. Enter name, type, expiry (optional)
     4. Save → Document encrypted & stored

2. **View Document & History**
   - Actors: User
   - Steps:
     1. Open app → Select document
     2. View current version & previous versions
     3. Option to add notes / upload new version

3. **Receive Expiry Reminder**
   - Actors: User, System
   - Steps:
     1. System checks expirable documents daily
     2. If expiry within threshold → trigger notification
     3. User views reminder → acts accordingly

4. **Search & Filter**
   - Actors: User
   - Steps:
     1. Open search bar → input query
     2. Filter by category / expiry status
     3. Retrieve matching documents

## Data Flow (Simplified)

```
[User] → [App UI] → [Document Manager] → [Encryption Module] → [Encrypted Storage]
                     ↑
                     └─> [Notification Module] → [Device Notifications]
```

---

# 4. Agile Methodology Plan

## Project Vision
Enable Kenyan citizens to securely store, organize, and track their personal documents and certificates (both expirable and permanent) through a mobile app with secure storage, versioning, and reminders.

## Agile Framework
- Methodology: Scrum-inspired Agile
- Sprint Duration: 2 weeks per sprint
- Roles:
  - Product Owner → defines requirements & priorities
  - Scrum Master → manages sprints & blockers
  - Development Team → developers (you/teammates)

## Product Backlog / User Stories

| ID | User Story | Acceptance Criteria |
|----|------------|-------------------|
| US01 | As a user, I want to upload personal documents securely | Documents are encrypted, stored locally, and retrievable |
| US02 | As a user, I want to categorize my documents | Categories: ID, Certificate, License, Property, Other |
| US03 | As a user, I want to mark documents as expirable or permanent | Expirable docs allow expiry date input; permanent docs do not |
| US04 | As a user, I want to receive reminders for expiring documents | Notifications trigger at defined intervals before expiry |
| US05 | As a user, I want to view version history for each document | Previous versions are accessible with timestamp and notes |
| US06 | As a user, I want to secure my app using PIN/biometrics | Unauthorized access is blocked |
| US07 | As a user, I want to search and filter my documents | Filters: category, expiry status, name |
| US08 | As a user, I want the app to work offline | Storage, retrieval, and notifications function without internet |
| US09 | As a user, I want optional encrypted cloud backup | Encrypted backup syncs when online without data leakage |

## Sprint Planning (Example)

**Sprint 1:** Secure storage & document upload (offline support)  
**Sprint 2:** Document categorization & expiry management  
**Sprint 3:** Versioning & history tracking  
**Sprint 4:** PIN & biometric access control  
**Sprint 5:** Notifications & reminders for expiring documents  
**Sprint 6:** Search, filter, and UI improvements  
**Sprint 7 (Optional):** Cloud backup & multi-device support

---

# 5. Detailed Agile Backlog with Tasks

**Sprint 1: Secure Storage & Upload**
- Task 1.1: Set up project repository (Flutter/Kotlin)
- Task 1.2: Implement secure local storage using encrypted SQLite
- Task 1.3: Develop document upload UI
- Task 1.4: Test offline document storage

**Sprint 2: Categorization & Expiry**
- Task 2.1: Implement document categories
- Task 2.2: Add expiry date input for expirable documents
- Task 2.3: Color-coded status display (expiring soon, valid, expired)

**Sprint 3: Versioning & History**
- Task 3.1: Implement versioned storage for each document
- Task 3.2: Add note-taking for each version
- Task 3.3: Display version history UI

**Sprint 4: Access Control & Security**
- Task 4.1: Implement PIN authentication
- Task 4.2: Implement biometric authentication (fingerprint/face ID)
- Task 4.3: Protect encryption keys using KeyStore/KeyChain

**Sprint 5: Notifications & Reminders**
- Task 5.1: Schedule local notifications for expiring documents
- Task 5.2: Test reminder triggers offline and online
- Task 5.3: Allow users to configure notification thresholds

**Sprint 6: Search & Filter, UX Improvements**
- Task 6.1: Implement search bar functionality
- Task 6.2: Add filter options (category, expiry, permanent)
- Task 6.3: UI polishing for usability and minimal clicks

**Sprint 7 (Optional): Cloud Backup & Multi-device Sync**
- Task 7.1: Implement encrypted cloud backup (Firebase/Google Drive)
- Task 7.2: Handle multi-device conflict resolution
- Task 7.3: Test restore functionality

---

# 6. Proposed Tech Stack

| Component | Technology |
|-----------|-----------|
| Mobile Framework | Flutter (cross-platform) OR Kotlin (Android-native) |
| Local Database | SQLite + SQLCipher for encryption |
| Secure Storage | KeyStore (Android) / KeyChain (iOS) |
| Notifications | Flutter Local Notifications Plugin / Android Notification Manager |
| UI | Material Design (Flutter) / Native Android Components |
| Optional Cloud Backup | Firebase Firestore / Google Drive (encrypted) |
| Version Control | Git / GitHub |
| Project Management | Trello / Jira |

---

## 7. Current Progress Snapshot & Prioritized Execution Checklist

Current repository status (based on existing project files/branches): **planning complete, implementation not started**.

To continue consistently across sessions, execute user stories in this order and only mark a story complete when all acceptance criteria are fully met.

| Priority | Story ID | Scope | Status |
|----------|----------|-------|--------|
| P0 (Must) | US01 | Secure upload + encrypted local storage + retrieval | Not Started |
| P0 (Must) | US08 | Full offline behavior for storage/retrieval/notifications | Not Started |
| P0 (Must) | US06 | PIN + biometric access control | Not Started |
| P1 (Should) | US02 | Document categorization | Not Started |
| P1 (Should) | US03 | Expirable vs permanent document flow | Not Started |
| P1 (Should) | US04 | Expiry reminders + threshold settings | Not Started |
| P1 (Should) | US05 | Version history with timestamps + notes | Not Started |
| P2 (Could) | US07 | Search and filtering | Not Started |
| P3 (Optional) | US09 | Encrypted cloud backup + sync safeguards | Not Started |

This checklist is the baseline handoff point for subsequent sessions so work can continue without leaving requirements partially done.

---

This document now contains a **complete requirements specification, Agile plan, backlog with tasks, tech stack, and a prioritized execution baseline**, ready for **coding and senior project reporting**.
