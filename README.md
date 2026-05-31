# Palcomtech Chicken Box (PCB)

Flutter mobile frontend for the Palcomtech Chicken Box smart poultry monitoring system. This app connects to the PCB backend to authenticate users, claim chicken-coop devices, monitor sensor readings, manage access, and control supported relay components.

## System Overview

The full PCB system has three layers:

| Layer | Technology | Responsibility |
| --- | --- | --- |
| IoT hardware | ESP32, DHT22, MQ-135, LDR, relay module | Sends sensor data and receives control commands over MQTT |
| Backend | FastAPI, PostgreSQL, Mosquitto, JWT | REST API, MQTT bridge, auth, persistence, RBAC |
| Mobile app | Flutter, Dart, Dio, Provider, Firebase Auth | User interface, auth, monitoring, device control |

This repository contains only the mobile app.

## Current App Features

- Firebase login with backend JWT exchange.
- Secure JWT storage through `TokenManager` and `flutter_secure_storage`.
- Global logout handling for expired/invalid sessions.
- Device list dashboard with pagination, refresh, empty states, and retry feedback.
- QR scan flow for claiming registered devices.
- BLE WiFi provisioning page for ESP32 setup.
- Device detail screen with latest temperature, humidity, ammonia, and light level.
- Relay control through `DeviceProvider` and `DeviceService` with optimistic UI and rollback.
- Device access management for owners through the "Kelola Akses" screen.
- History page showing recent sensor logs and alert activity for the first accessible device.
- Offline banner and full-screen maintenance handling.

## Hardware Status

The app and backend are designed for Hardware V2, but the currently installed physical hardware is the Lite version.

| Component | API value | Current UI | Lite hardware |
| --- | --- | --- | --- |
| Lampu | `lampu` | Visible toggle | Installed |
| Pompa | `pompa` | Visible toggle | Installed |
| Kipas | `kipas` | Hidden/commented | Not installed |
| Pakan Otomatis | `pakan_otomatis` | Hidden/commented | Not installed |
| Exhaust Fan | `exhaust_fan` | Hidden/commented | Not installed |

To enable V2 controls later, update the `components` list in `lib/pages/device_detail_page.dart` inside `_buildControlItems()`.

## Project Structure

```text
lib/
  main.dart                         App bootstrap, Firebase/API init, global logout listener
  constants/                        API config, colors, floating navigation widgets
  core/network/                     Dio client, auth interceptor, token manager, API exceptions
  models/auth/                      Login request/response and user info models
  models/common/                    Generic pagination wrapper
  models/device/                    Device, sensor log, assignment, component enum
  pages/                            Login, home tabs, device list/detail, assignment, scan, BLE, history, profile
  providers/                        DeviceProvider for relay toggle state
  services/                         AuthService and DeviceService
  utils/                            ErrorHandler UI helpers
  widgets/                          Offline banner and maintenance screen
test/                               Flutter tests
assets/images/                      App images, logo, splash assets
docs/                               API contract and active development guide
```

## Main Navigation

`main.dart` starts on `LoginPage` by default. If `TokenManager` finds a valid stored JWT, it starts on `HomeScreen`.

`HomeScreen` is the authenticated tab container:

| Tab | Page | Purpose |
| --- | --- | --- |
| 0 | `DeviceListPage` | Main dashboard and claimed device list |
| 1 | `DevicesPage` | BLE WiFi provisioning |
| 2 | `ScanPage` | QR device claiming |
| 3 | `HistoryPage` | Recent logs and alerts |
| 4 | `ProfilePage` | Profile and logout/account actions |

## Networking Architecture

All API calls should go through `DioClient().dio`. `ApiConfig.initialize()` loads `.env`, appends `/api`, and configures the Dio base URL.

Key networking files:

- `lib/constants/api_config.dart` defines endpoint paths and WebSocket URL generation.
- `lib/core/network/auth_interceptor.dart` injects JWTs and maps HTTP failures to typed exceptions.
- `lib/core/network/token_manager.dart` stores JWT/user data and exposes the logout stream.
- `lib/core/network/api_exception.dart` defines typed API errors.
- `lib/services/auth_service.dart` handles Firebase token exchange and local logout.
- `lib/services/device_service.dart` handles device list, control, claim, logs, assignments, and user lookup by email.

Backend details are documented in [docs/API_CONTRACT.md](docs/API_CONTRACT.md). Developer workflows are in [docs/DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md).

## Environment

Create `.env` in the repository root:

```env
BASE_URL=https://pcb.my.id
```

Do not include `/api`; `ApiConfig` appends it automatically.

## Commands

```bash
flutter pub get
flutter run
flutter analyze
flutter test
dart format lib test
flutter build apk --release
flutter build appbundle --release
```

## API Highlights

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `POST` | `/api/auth/firebase/login` | Exchange Firebase token for backend JWT |
| `GET` | `/api/users/me` | Load authenticated user profile |
| `GET` | `/api/devices/` | List accessible devices |
| `POST` | `/api/devices/claim` | Claim a device by MAC address |
| `GET` | `/api/devices/{id}/logs` | Load sensor logs |
| `GET` | `/api/devices/{id}/alerts` | Load alert logs |
| `GET` | `/api/devices/{id}/status` | Check online status |
| `POST` | `/api/devices/{id}/control` | Send relay control command |
| `POST` | `/api/devices/{id}/assign` | Assign operator/viewer access |
| `DELETE` | `/api/devices/{id}/assign/{user_id}` | Remove device assignment |

## Notes

- WebSocket streaming is defined in the API contract but the app currently uses REST polling.
- Device toggle state is in-memory through Provider; backend does not currently return per-component state.
- The history page currently uses the first accessible device for recent logs and alert activity.
- The app is proprietary software developed for Palcomtech.
