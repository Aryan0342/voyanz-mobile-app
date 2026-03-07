# Voyanz Mobile App (Flutter)

Mobile application project for Voyanz/Visioco focused on **sessions** and **quick information capture**.

This README is based on the provided API reference:
`API_REST_MOBILE_FLUTTER_EN-1.md` (dated Feb 9, 2025).

## 1. Project Goal

Build Flutter mobile apps that support:

- Authentication and account basics
- Find professionals and view profile information
- Session-related flows (video/phone/chat)
- Chat during sessions
- Reviews, history, pricing, promo code, and appointment registration

Keep mobile scope intentionally smaller than the full web/back-office platform.

## 2. Scope

### In Scope (Mobile)

- Auth and user context
  - `POST /api/1.0/login`
  - `GET /web/1.0/user/infos`
- Account management
  - `POST /web/1.0/account`
  - `PUT /web/1.0/account/:co_id`
  - `PUT /web/1.0/account/description/:co_id` (pro)
- Professional discovery and details
  - `GET /web/1.0/professionals`
  - `GET /web/1.0/professional/:co_id/infos`
- Availability
  - `GET /web/1.0/professional/disponibilities`
  - `POST /web/1.0/disponibilities`
- Pricing and promo
  - `GET /web/1.0/customer/pricing`
  - `POST /web/1.0/checkpromocode`
- History and reviews
  - `GET /web/1.0/customer/history`
  - `GET /web/1.0/professional/history`
  - `GET /web/1.0/customer/reviews`
  - `GET /web/1.0/professional/reviews`
  - `POST /web/1.0/review`
- Session media/chat
  - `GET /web/1.0/video/:se_id/:co_id/accesstoken`
  - `POST /web/1.0/video/heartbeat/:se_id` (optional but recommended for video)
  - `GET /api/1.0/chat/groups`
  - `GET /api/1.0/chat/messages/:chgr_id`
  - `POST /api/1.0/chat/message` (body includes `chgr_id`)
  - `GET /api/1.0/chat/image/:chme_id`
- Appointment registration
  - `POST /web/1.0/registration`

### Out of Scope (for now)

- Back-office/admin domains
- Advanced payment internals (webhooks, disputes, refunds)
- Recording control endpoints for mobile UX
- Session summaries/PDF (phase 2 option)
- AI/guide/twin endpoints (web-only unless explicitly planned)
- Full appointment CRUD and start flows unless booking features are approved

## 3. Critical Gap to Resolve

Two session endpoints expected by mobile are missing as REST in current server behavior:

1. Create session (call)

- Expected equivalent: `POST /web/1.0/call/:typecall/:co_id`
- `typecall`: `phone | video | chat`
- Should return `se_id`

2. Session status/wait

- Expected equivalent: `GET /web/1.0/call/wait/:se_id` or `GET /web/1.0/session/:se_id`
- Should return session state (`pending`, `inprogress`, `completed`, etc.)

Current behavior is WebSocket-driven for call creation/wait.

## 4. API Notes for Flutter

### Authentication

- Login: `POST /api/1.0/login`
- Store `accesstoken` (optionally `refreshtoken`)
- Use `Authorization` header on authenticated calls
- Header format must be confirmed by backend:
  - `Authorization: Bearer <accesstoken>` or
  - `Authorization: <accesstoken>`

### Standard Response Shape

Most responses follow:

```json
{
  "data": {},
  "err": null,
  "meta": {}
}
```

Error example shape:

```json
{
  "data": null,
  "err": {
    "code": "...",
    "status": 400,
    "message": "..."
  },
  "meta": {}
}
```

### Agency Branding

`POST /api/1.0/login` returns an `agency` object (theme/branding fields) that mobile should use for per-agency UI adaptation.

### Video Provider

Use `GET /web/1.0/video/:se_id/:co_id/accesstoken`.

Response may include:

- `provider` (`agora` or `twilio`)
- `appId` (Agora)
- `uid` (Agora)
- `room`
- `token`

Flutter should initialize the SDK based on `provider`.

## 5. Environment Configuration (To Be Filled by Backend/Visioco)

- Base URLs:
  - Dev: `TODO`
  - Staging: `TODO`
  - Prod: `TODO`
- API key (if still required): `TODO`
- Auth header convention: `TODO`
- Refresh strategy: `TODO`

## 6. Recommended Mobile Architecture (Flutter)

- `core/network`
  - HTTP client, auth interceptor, error parser
- `core/config`
  - Environment/base URL management
- `features/auth`
- `features/account`
- `features/professionals`
- `features/sessions`
- `features/video`
- `features/chat`
- `features/reviews`
- `features/history`
- `features/pricing`
- `features/appointments`

Use a repository pattern with DTO -> domain mapping and centralized API error handling.

## 7. Delivery Checklist

- Confirm base URLs and auth/header conventions
- Confirm if ApiKey is required for mobile
- Decide session flow strategy:
  - Add REST endpoints for create/wait, or
  - Officially support WebSocket protocol for Flutter
- Publish final OpenAPI/Postman collection for mobile endpoints
- Validate Agora integration fields (`appId`, `uid`, `token`, `room`, `provider`)

## 8. Current Project Status

This repository currently contains planning/documentation only.
Development can begin once you request implementation.

---

## Appendix: Endpoint Quick List

### Auth and Account

- `POST /api/1.0/login`
- `GET /web/1.0/user/infos`
- `POST /web/1.0/account`
- `PUT /web/1.0/account/:co_id`
- `PUT /web/1.0/account/description/:co_id`

### Discovery and Availability

- `GET /web/1.0/professionals`
- `GET /web/1.0/professional/:co_id/infos`
- `GET /web/1.0/professional/disponibilities`
- `POST /web/1.0/disponibilities`

### Commercial

- `GET /web/1.0/customer/pricing`
- `POST /web/1.0/checkpromocode`

### History and Reviews

- `GET /web/1.0/customer/history`
- `GET /web/1.0/professional/history`
- `GET /web/1.0/customer/reviews`
- `GET /web/1.0/professional/reviews`
- `POST /web/1.0/review`

### Session, Video, Chat

- `GET /web/1.0/video/:se_id/:co_id/accesstoken`
- `POST /web/1.0/video/heartbeat/:se_id`
- `GET /api/1.0/chat/groups`
- `GET /api/1.0/chat/messages/:chgr_id`
- `POST /api/1.0/chat/message`
- `GET /api/1.0/chat/image/:chme_id`

### Appointments

- `POST /web/1.0/registration`
