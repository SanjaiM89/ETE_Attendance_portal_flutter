# ETE Student Attendance System

> **A cross-platform attendance & event management system** built with Flutter (cross-platform) and Node.js (backend), developed by the [Forum of Data Science Engineers (FODSE)](https://github.com/S-Harish2005).

---

## Download App

| Platform | Student App (ETE) | Admin App (ETE_ADMIN) |
|----------|:-----------------:|:---------------------:|
| <img src="https://upload.wikimedia.org/wikipedia/commons/e/e4/Windows_logo_-_2021.svg" width="20" valign="middle" alt="Windows"> **Windows** | [Download](https://github.com/S-Harish2005/ETE_STUDENT_BACKEND/releases/latest) | [Download](https://github.com/S-Harish2005/ETE_STUDENT_BACKEND/releases/latest) |
| <img src="https://upload.wikimedia.org/wikipedia/commons/c/c9/Finder_Icon_macOS_Big_Sur.png" width="20" valign="middle" alt="macOS"> **macOS** | [Download](https://github.com/S-Harish2005/ETE_STUDENT_BACKEND/releases/latest) | [Download](https://github.com/S-Harish2005/ETE_STUDENT_BACKEND/releases/latest) |
| <img src="https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg" width="20" valign="middle" alt="iOS"> **iOS** | [Download](https://github.com/S-Harish2005/ETE_STUDENT_BACKEND/releases/latest) | [Download](https://github.com/S-Harish2005/ETE_STUDENT_BACKEND/releases/latest) |
| <img src="https://upload.wikimedia.org/wikipedia/commons/d/de/Android_robot.svg" width="20" valign="middle" alt="Android"> **Android** | [Download](https://github.com/S-Harish2005/ETE_STUDENT_BACKEND/releases/latest) | [Download](https://github.com/S-Harish2005/ETE_STUDENT_BACKEND/releases/latest) |
| <img src="https://upload.wikimedia.org/wikipedia/commons/3/35/Tux.svg" width="20" valign="middle" alt="Linux"> **Linux** | [Download](https://github.com/S-Harish2005/ETE_STUDENT_BACKEND/releases/latest) | [Download](https://github.com/S-Harish2005/ETE_STUDENT_BACKEND/releases/latest) |

> **[Visit our Downloads Page](https://S-Harish2005.github.io/ETE_STUDENT_BACKEND/)** for direct per-platform links.

---

## Project Structure

```
ETE_STUDENT_BACKEND/
├── BackEnd/             # Node.js + Express + MongoDB API
│   ├── controllers/     # Route handlers (admin, team)
│   ├── models/          # Mongoose schemas (Admin, Team)
│   ├── routes/          # Express routes
│   ├── middleware/      # Auth & role middlewares
│   └── utils/           # QR code, email utilities
├── FrontEnd/            # Flutter Student App
│   └── lib/
│       ├── screens/     # Login, Team Dashboard
│       ├── providers/   # Auth provider (state management)
│       └── services/    # API & Auth services
├── admin_frontend/      # Flutter Admin App
│   └── lib/
│       ├── screens/     # Login, Admin Dashboard
│       ├── providers/   # Auth provider
│       └── services/    # API & Auth services
├── docs/                # GitHub Pages landing site
├── .github/workflows/   # CI/CD pipelines
└── logo.png             # FODSE logo
```

---

## Features

- **Admin Dashboard** — Create teams, manage members, mark attendance, track judging
- **Team Dashboard** — View attendance, round status, team info
- **Multi-Factor Auth (MFA)** — TOTP-based MFA for admin login via Authenticator App
- **Real-time Updates** — WebSocket-powered live sync across dashboards
- **QR Code Login** — Teams log in by scanning a QR code with an embedded FODSE logo
- **Email Notifications** — Auto-sends team credentials to the designated team leader
- **Cross-Platform** — Builds for Windows, macOS, iOS, Android, Linux, and Web
- **Dark Theme** — Sleek, modern dark UI with premium design

---

## Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| **Node.js** | ≥ 18.x |
| **Flutter** | ≥ 3.11 (stable) |
| **MongoDB** | Running instance (local or Atlas) |

### 1. Clone the Repository

```bash
git clone https://github.com/S-Harish2005/ETE_STUDENT_BACKEND.git
cd ETE_STUDENT_BACKEND
```

### 2. Backend Setup

```bash
cd BackEnd
npm install
```

Create a `.env` file in `BackEnd/`:
```env
MONGO_URI=mongodb://localhost:27017/ete_attendance
JWT_SECRET=your_jwt_secret_here
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
SMTP_FROM=your_email@gmail.com
```

Seed the initial admin account:
```bash
node seedadmin.js
```

Start the backend server:
```bash
npm start
```

The server will run on `http://localhost:5000`.

### 3. Student Frontend (Flutter)

```bash
cd FrontEnd
flutter pub get
flutter run -d chrome          # Web
flutter run -d windows         # Windows
flutter run -d macos            # macOS
flutter build apk --split-per-abi  # Android APKs
```

### 4. Admin Frontend (Flutter)

```bash
cd admin_frontend
flutter pub get
flutter run -d chrome
```

### 5. Update API Base URL

Edit `lib/utils/constants.dart` in both Flutter projects to point to your backend:
```dart
class Constants {
  static const String baseUrl = 'http://localhost:5000/api';
}
```

---

## CI/CD Pipeline

The project uses **GitHub Actions** to automatically build releases for all platforms on every push to `master`, `main`, or `flutter` branches.

| Target | Runner | Output |
|--------|--------|--------|
| Windows | `windows-latest` | `.zip` (ETE / ETE_ADMIN) |
| macOS | `macos-latest` | `.zip` (ETE / ETE_ADMIN) |
| iOS | `macos-latest` | `.zip` (unsigned `.app`) |
| Android | `ubuntu-latest` | Split APKs (`arm64`, `armeabi`, `x86_64`) |
| Linux | `ubuntu-latest` | `.AppImage` (ETE / ETE_ADMIN) |

Releases are published automatically to [GitHub Releases](https://github.com/S-Harish2005/ETE_STUDENT_BACKEND/releases).

---

## License

This project is maintained by **FODSE — Forum of Data Science Engineers**.
