# TheraCare

**An accessible digital back-pain therapy app for adults aged 50+ — Flutter mobile app and Node.js / TypeScript API.**

TheraCare guides patients through a structured 12-week therapy programme: medically styled education, guided exercises, pain and symptom tracking, questionnaires and an accessible progress dashboard. It is modelled on the workflows of a German *Digitale Gesundheitsanwendung* (DiGA) and is designed accessibility-first: large text, screen-reader support, plain language, generous touch targets and offline use.

> **Educational prototype.** TheraCare is a learning and demonstration project. It is **not** a certified medical device, not a listed DiGA, and must only be used with synthetic data. All exercise and questionnaire content is demo content and has not been clinically reviewed.

---

## Contents

- [Features](#features)
- [Architecture](#architecture)
- [Repository layout](#repository-layout)
- [Getting started](#getting-started)
- [Demo walkthrough](#demo-walkthrough)
- [Testing and code quality](#testing-and-code-quality)
- [API](#api)
- [Security and privacy](#security-and-privacy)
- [Accessibility](#accessibility)
- [Design decisions](#design-decisions)
- [Out of scope](#out-of-scope)
- [Contributing workflow](#contributing-workflow)

## Features

| Area | What it does |
| --- | --- |
| Accounts | Registration, 6-digit email verification, sign-in, password recovery, refresh-token rotation with reuse detection, device session list and revocation |
| Activation | Redeem a 12-character demo activation code; atomic, row-locked, idempotent, never stored or logged in plain text |
| Privacy & consent | Plain-language summaries, separate required and optional consents (never preselected), versioned evidence, history and withdrawal with explained consequences |
| Onboarding | Three short steps: what to expect, comfortable display settings, starting back check |
| Treatment | Versioned treatment plans assigned from the baseline score, today's exercises, weekly schedule, guided exercise sessions with pause and a clear stop action |
| Tracking | Pain, stiffness, sleep and mood on large labelled scales; append-only corrections that keep the original value |
| Questionnaires | Baseline, weekly check-in and final assessment; one question per screen, drafts saved, review before sending, versioned scoring |
| Progress | One clear next action, weekly summaries in plain text, chart with a table alternative, baseline vs. final comparison |
| Offline | Entries are saved encrypted on the device first and synchronised idempotently; approved content is cached for offline use |
| Reports | Accessible tagged PDF treatment summary and a validated HL7 FHIR R4 export, generated asynchronously and shared only after confirmation |
| Reminders | Optional daily reminders respecting time zone and quiet hours, with lock-screen-safe wording |
| Help | FAQ, emergency guidance and a support form that strips activation codes; help is reachable from every screen, even before sign-in |
| Administration | Role-separated content workflow (author → clinical reviewer → release), support queue without health-record access, audit trail for security auditors |
| Data lifecycle | Account closure, retention job that anonymises identity data after the retention period while keeping clinical records |

German is the primary language, English is fully supported.

## Architecture

```
┌──────────────────────────────┐        HTTPS / JSON         ┌──────────────────────────────────────┐
│  Flutter app (Android, iOS)  │  ───────────────────────▶   │  TheraCare API (modular monolith)    │
│                              │   /api/v1, bearer tokens    │  Node.js · Express 5 · TypeScript    │
│  Screen → Riverpod provider  │                             │                                      │
│   → Repository interface     │                             │  route → zod validation → service    │
│   → API client / SQLite      │                             │   → Prisma → PostgreSQL              │
│                              │                             │                                      │
│  Encrypted SQLite queue      │  ◀──── /sync/events ─────   │  Redis: rate limiting                │
│  Secure storage for tokens   │                             │  Worker: reminders, retention        │
└──────────────────────────────┘                             └──────────────────────────────────────┘
```

**Backend** — one module per domain (`auth`, `patients`, `activations`, `consents`, `journey`, `treatments`, `exercises`, `questionnaires`, `assessments`, `tracking`, `sync`, `progress`, `notifications`, `reports`, `fhir`, `support`, `content`, `audit`). Each module owns its schemas (zod), service (domain rules + Prisma) and routes. Clinical rules live in services, never in controllers or the app. Server-side authorisation is authoritative.

**Mobile** — feature-first structure. Screens never call Dio or SQL directly: they use Riverpod providers backed by repository interfaces. A shared, accessible design system (`lib/core/widgets`, `lib/app/theme`) is used by every screen.

**Patient journey** — stored as explicit server-side states rather than booleans:

```
ACCOUNT_PENDING_VERIFICATION → ENTITLEMENT_PENDING → ENTITLEMENT_ACTIVE → PRIVACY_COMPLETE
→ ONBOARDING_IN_PROGRESS → BASELINE_ASSESSMENT_COMPLETE → TREATMENT_ACTIVE
→ FINAL_ASSESSMENT → TREATMENT_COMPLETED            (ACCOUNT_CLOSED is terminal)
```

### Tech stack

| Layer | Technology |
| --- | --- |
| Mobile | Flutter 3, Dart 3, Riverpod 3, go_router, Dio, sqflite, flutter_secure_storage, cryptography (AES-GCM) |
| Backend | Node.js ≥ 20, Express 5, TypeScript 5, zod, Prisma 6, argon2, jsonwebtoken, pino, pdfkit |
| Data | PostgreSQL 16, Redis 7, encrypted file storage for generated reports |
| Interoperability | HL7 FHIR R4 (Patient, Observation, Questionnaire, QuestionnaireResponse, CarePlan) |
| Quality | Jest + Supertest, flutter_test + mocktail, ESLint + Prettier, `flutter analyze` with strict rules |
| Local services | Docker Compose (PostgreSQL, Redis, Mailpit) |

## Repository layout

```
.
├── backend/
│   ├── prisma/            # schema, migrations, seed + reference content (prisma/seed/*)
│   ├── openapi/           # OpenAPI 3 contract (served at /api/docs)
│   ├── src/
│   │   ├── config/        # env validation, database, redis, logger
│   │   ├── common/        # errors, envelope, validation, crypto, dates, pagination
│   │   ├── middleware/    # request id, auth, roles, treatment access, rate limit, idempotency
│   │   ├── infrastructure/# mailer, encrypted storage
│   │   ├── modules/       # one folder per domain module
│   │   ├── jobs/          # retention + scheduler
│   │   ├── app.ts         # Express app factory
│   │   ├── server.ts      # API entry point
│   │   └── worker.ts      # background jobs entry point
│   └── tests/             # unit + integration tests
├── mobile/
│   ├── lib/
│   │   ├── app/           # app widget, router, redirect rules, theme
│   │   ├── core/          # network, storage, database, sync, widgets, l10n
│   │   ├── features/      # auth, activation, consent, onboarding, home, treatment,
│   │   │                  # tracking, questionnaires, progress, reports, profile, support
│   │   └── l10n/          # ARB files (de, en)
│   └── test/              # unit and widget tests
└── docker-compose.yml     # local development services only
```

## Getting started

### Prerequisites

- Node.js 20 or newer and npm
- Flutter 3.x (stable) with an Android emulator or iOS simulator
- Docker Desktop

### 1. Start the local services

```bash
docker compose up -d
```

| Service | Address |
| --- | --- |
| PostgreSQL | `localhost:5433` (user / password / db: `theracare`) — test DB `theracare_test` is created automatically |
| Redis | `localhost:6380` |
| Mailpit (captured emails) | SMTP `localhost:1026`, web UI <http://localhost:8026> |

### 2. Run the API

```bash
cd backend
cp .env.example .env            # then set real random secrets, e.g. openssl rand -hex 32
npm install
npx prisma migrate deploy       # create the schema
npm run db:seed                 # demo content, accounts and activation codes
npm run dev                     # API on http://localhost:3000
npm run worker                  # optional: reminders and retention jobs
```

The seed prints **five fresh activation codes** — they are stored only as hashes, so note them down.

### 3. Run the app

```bash
cd mobile
flutter pub get
flutter run                     # Android emulator uses http://10.0.2.2:3000/api/v1 automatically
```

To point the app at another API:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000/api/v1
```

### Demo accounts

All seeded accounts use the password `TheraCare-Demo-2026`.

| Account | Purpose |
| --- | --- |
| `demo@theracare.local` | Verified patient, ready to enter an activation code |
| `demo.active@theracare.local` | Patient in week 4 of treatment with three weeks of history |
| `author@theracare.local` | Content author |
| `reviewer@theracare.local` | Clinical reviewer |
| `admin@theracare.local` | Administrator / release manager |
| `support@theracare.local` | Support agent |
| `auditor@theracare.local` | Security auditor |

Verification and password-reset codes for new registrations appear in Mailpit.

## Demo walkthrough

1. Register a new account and confirm the 6-digit code from Mailpit.
2. Enter one of the printed activation codes.
3. Read the privacy information; agree to the required points and decide on the optional one.
4. Onboarding: choose a comfortable text size, then answer the 7-question starting back check.
5. A treatment plan is assigned. Start today's exercise from the Home screen.
6. Record pain on the *Record* tab — try it in flight mode, then reconnect and watch the pending entry being sent.
7. Open *Progress* to see the weekly summary, switch the chart to a table and create the PDF summary.
8. In *Profile* explore text size, reminders, consent history, FHIR export, signed-in devices and account closure.

Sign in as `demo.active@theracare.local` to see a populated dashboard straight away.

## Testing and code quality

### Backend

The integration tests run against the `theracare_test` database from Docker Compose.

```bash
cd backend
npm test                 # all tests (unit + integration)
npm run test:unit
npm run test:integration
npm run lint             # ESLint
npm run format:check     # Prettier
npm run typecheck        # tsc --noEmit
```

Coverage highlights: account enumeration resistance, refresh-token reuse detection, concurrent activation redemption, consent evidence and withdrawal, patient isolation for every resource, append-only corrections, idempotent sync redelivery, FHIR profile validation, role separation in the content workflow, retention timing, and a contract test that fails if any route is missing from the OpenAPI document.

### Mobile

```bash
cd mobile
flutter analyze          # strict analyzer + lints
flutter test             # unit and widget tests
```

Coverage highlights: WCAG contrast of every colour token, journey redirect rules, encrypted offline queue (confirmation, backoff, rejection), semantics of the scale and choice controls, touch-target sizes and layouts at 200 % text, one-question-per-screen questionnaire flow, guided exercise session, consent preselection and account-closure confirmation.

## API

- Interactive documentation: <http://localhost:3000/api/docs>
- OpenAPI JSON: <http://localhost:3000/api/docs/openapi.json>
- Health check: <http://localhost:3000/health>

Every response uses the same envelope:

```json
{ "success": true, "data": {}, "meta": { "requestId": "…" } }
{ "success": false, "error": { "code": "VALIDATION_ERROR", "message": "Please check the information you entered.", "fields": { "email": "Enter a valid email address." } }, "meta": { "requestId": "…" } }
```

## Security and privacy

- Passwords hashed with **Argon2id**; access tokens are short-lived JWTs; refresh tokens are random, stored only as HMAC hashes, rotated on every use, and a reused token revokes the whole session family.
- Generic responses for registration, password recovery and login prevent account enumeration; abuse-sensitive endpoints are rate limited (Redis-backed when available).
- Every patient resource is checked against the authenticated subject on the server. Treatment data additionally requires an active entitlement and all required consents.
- Activation and reset codes are stored as peppered hashes and never logged; support tickets automatically remove anything that looks like an activation code.
- Logs are structured and redact credentials, tokens, codes, notes and values. Audit events store references only — never medical payloads.
- Generated reports are encrypted at rest (AES-256-GCM). On the device, tokens live in the platform keystore and queued health data and cached content are encrypted with a key held in secure storage.
- Reminder notifications never mention diagnosis, symptoms or the type of therapy.
- Closed accounts are anonymised by the retention job after the configured period; clinical records are never cascade-deleted.

Use synthetic data only. Real-world use would require formal medical-device, clinical, privacy (GDPR / DiGAV) and security assessments.

## Accessibility

Accessibility is built into the design system rather than added per screen:

- **Atkinson Hyperlegible** typeface, 18 px body text, generous line height; the system text scale is honoured and never clamped, and an in-app text size multiplies it.
- Primary buttons 60 px high, all touch targets ≥ 48 px, inputs with persistent visible labels, help text and field-specific errors.
- Status is always text + icon + colour; colour tokens are tested for WCAG 2.2 AA contrast.
- Semantic labels and states for custom controls (e.g. "5 of 10, selected"), live-region announcements for errors and progress.
- Charts are hidden from screen readers and always paired with a plain-text summary and a table alternative.
- Optional high-contrast mode and reduced motion (page transitions off).
- No time limits, one question per screen, plain-language copy without pressure or blame.

## Design decisions

- **Modular monolith** — one deployable API with strict module boundaries; simpler to run and test than microservices at this scale.
- **Registries instead of conditionals** — scoring algorithms, answer validators, sync handlers, report generators and content stores are lookup tables, so new kinds are added without changing callers.
- **Shared domain services** — the REST endpoints and the offline sync endpoint call the same services, so validation and idempotency rules cannot drift apart.
- **Repository interfaces in the app** — screens depend on abstractions, which keeps them testable with simple fakes. Separate use-case classes were left out deliberately because the repositories already carry the small amount of client-side logic.
- **Server-calculated progress** — totals are always derived from source events, so the dashboard cannot disagree with the records.

## Out of scope

Following the project brief, these are intentionally not included in this version:

- CI/CD pipelines and production deployment configuration
- A real push-notification provider (the worker uses a pluggable provider interface with a development implementation)
- Real insurer, prescription (E-Rezept) or ePA integrations
- Clinical validation of any content or scoring

## Contributing workflow

- Branches: `main` (stable) ← `develop` (integration) ← `feature/<area>` for implementation and `test/<area>` for the matching tests, merged back with `--no-ff`.
- Commits follow Conventional Commits (`feat`, `fix`, `test`, `refactor`, `chore`, `docs`) and group related files into small, meaningful commits.
- Specification and design documents are not committed to this repository.
