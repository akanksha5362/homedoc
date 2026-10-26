# HomeDoc AI — Implementation Status

Last updated: 2026-08-06

## Already Implemented

- Feature-based Flutter architecture (`lib/app`, `lib/core`, `lib/features`, `lib/shared`)
- Material 3 design system (colors, typography, spacing, theme)
- Reusable UI components (AppButton, AppCard, AppTextField, states, healthcare cards)
- GoRouter navigation with auth guards and patient/doctor shells
- Riverpod state management foundation
- ApiClient with auth interceptor, error mapping, safe logging
- Secure storage for tokens
- Environment-based AppConfig (dev/staging/prod)
- Mock auth session (foundation stage)
- AI Care triage UI (symptom input, results, emergency warning)
- AI triage client models and repository layer
- Localization (EN + HI)
- Unit and widget tests for core components
- Firebase dependencies declared in pubspec (not fully wired)
- Models: User, Doctor, Appointment (partial)

## Partially Implemented

- Authentication (mock session only; no real `/auth` calls)
- Patient home (mock appointment data)
- Care page (empty placeholder)
- Health page (placeholder)
- Profile page (basic)
- Doctor today page (placeholder)
- AI Care (client UI only; no backend)
- AI Agent tools (interface contracts only)

## Missing

- FastAPI backend (auth, RBAC, doctors, appointments, AI gateway)
- PostgreSQL database and migrations
- Real Firebase Auth / Firestore integration
- Doctor discovery and search
- Appointment booking lifecycle
- Home visit workflow and live tracking
- Video consultation (Agora declared, not wired)
- Prescriptions and medicine reminders
- Payments (Razorpay)
- Notifications (FCM + local)
- Emergency workflow
- Family health vault
- Medical records
- Chat
- RAG / embeddings / pgvector
- ML inference service

## Needs Refactoring

- Auth provider: replace mock session with real API auth
- Patient home: replace mock appointment with repository
- Care page: implement doctor discovery
- AI Care: add agent chat mode alongside triage
- `.gitignore`: add `.env`, backend secrets

## Critical Errors

- None blocking compile (app builds with mock data)
- No backend exists — all API calls fail at runtime
