<<<<<<< HEAD
# SME Customer Manager (Flutter, backend-connected)

A customer, sales, debt, and inventory manager for small businesses. This version talks to the
companion Node.js/Express backend (`sme_backend`) over HTTP, so multiple devices/browsers share
one live dataset instead of each having its own local copy.

## What changed from the local-only version

- **No more local database.** The app is now a thin client: `lib/app_state.dart` calls the
  backend's REST API for every read and write, and holds the results in memory for the UI to
  display. There's nothing left to go stale or diverge between devices.
- **Real login.** Username/password go to the server, which checks them against bcrypt-hashed
  passwords and returns a JWT. The token is the only thing cached on the device (via
  `shared_preferences`), so a restart can restore your session without asking for the password
  again — but the data itself always comes fresh from the server.
- **Configurable server address**, from a "Server settings" toggle on the login screen.
- **"Load sample data"** is gone from the app — that's now `npm run seed` on the backend, since
  the whole point is one shared dataset rather than a local demo copy.

## Setup

1. Get the backend running first (see `sme_backend/README.md`). Note its URL.
2. In this project:
   ```
   flutter pub get
   ```
3. Run it:
   ```
   flutter run -d chrome        # web
   flutter run                  # connected device/emulator
   ```
4. On the login screen, tap **"Server settings"** and set the server URL if it isn't running on
   `http://localhost:4000/api` (the default). See the networking notes below — "localhost" means
   different things depending on where the app is running.
5. Sign in with **admin** / **admin123** (or whatever you've since changed it to).

## Networking notes (important for local development)

`localhost` refers to the device the app itself is running on, not your computer, unless they're
the same machine. Concretely:

| Where the app runs                          | Server URL to use                        |
|----------------------------------------------|-------------------------------------------|
| Flutter web, same computer as the backend     | `http://localhost:4000/api`               |
| iOS Simulator                                 | `http://localhost:4000/api`               |
| Android Emulator                              | `http://10.0.2.2:4000/api`                |
| Physical phone/tablet                         | `http://<your-computer's-LAN-IP>:4000/api`|

For a physical device, the phone and computer need to be on the same network, and your computer's
firewall needs to allow inbound connections on the backend's port.

For a real deployment (not local development), point this at your deployed backend's HTTPS URL,
e.g. `https://your-api.example.com/api`, and set the backend's `CORS_ORIGIN` to match the app's
actual origin.

## Role-based access

Unchanged from before — enforced both in the UI (screens hide actions a role can't take) and
independently on the server (so it can't be bypassed by calling the API directly). See the
backend's README for the full table.

## What's cached locally vs. always fetched

Only the JWT token and the server address are stored on the device. Everything else — customers,
inventory, sales, suppliers, expenses, staff, business profile — is fetched fresh on login and can
be manually refreshed at any time with the refresh icon in the top bar. This is a deliberate
choice: showing a stale local cache when the source of truth is now a shared server risks staff
looking at data another device has already changed. If the server is unreachable, you'll see a
clear error rather than possibly-outdated data presented as current.

## Project structure

```
lib/
  main.dart                  entry point, startup error handling
  app_state.dart             syncs with the backend API; single source of app state
  models.dart                data models & JSON (de)serialization (shapes match the API)
  theme.dart                 colors & ThemeData
  utils.dart                 currency formatting, date helpers
  api/
    api_client.dart          HTTP wrapper: base URL, bearer token, JSON, timeouts
    api_config.dart          default server URL + local-dev networking notes
  backup/                    platform-specific JSON file download (web vs io)
  widgets/common.dart        shared UI pieces (cards, chips, KPIs)
  screens/                   one file per screen
```

## Limitations to know about

- **Login security is only as good as the backend's.** Change the default admin password and use
  a real `JWT_SECRET` on the server (see its README) before treating this as more than a demo.
- **Offline use isn't supported.** Since the whole point of this version is one shared source of
  truth, the app requires a reachable server to show or change anything. If you need offline-first
  behavior (e.g. staff recording sales with no signal, syncing later), that's a meaningfully
  different architecture — happy to talk through what that would take if it comes up.
- **"Estimated profit"** (in Reports) is still a simplified figure: revenue collected minus
  expenses recorded, with no accounting for unsold inventory value.
=======
# SME-Customer-Manager
SME Customer Manager is a business management application designed to help small and medium-sized businesses manage customer records and outstanding payments efficiently
>>>>>>> d3a2967f0bb142fb7b6627e86d62e6a90837affe
