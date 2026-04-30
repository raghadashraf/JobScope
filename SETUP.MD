# 🛠️ JobScope - Developer Setup Guide

Welcome to the JobScope team! 🎉 This guide will help you set up the project on your machine in **under 30 minutes**.

---

## 📋 Prerequisites Checklist

Before starting, make sure you have these installed on your computer:

### ✅ Required Software

| Tool | Version | Purpose | Download Link |
|------|---------|---------|---------------|
| **Flutter SDK** | 3.41+ | Mobile framework | [Download](https://docs.flutter.dev/get-started/install) |
| **Dart SDK** | 3.11+ | Comes with Flutter | _Included_ |
| **Git** | Latest | Version control | [Download](https://git-scm.com/downloads) |
| **VS Code** | Latest | Code editor | [Download](https://code.visualstudio.com/) |
| **Android Studio** | Latest | Android emulator | [Download](https://developer.android.com/studio) |
| **Node.js** | 20+ | For Firebase CLI | [Download](https://nodejs.org/) |
| **Chrome** | Latest | Web testing | [Download](https://www.google.com/chrome/) |

### ✅ Required Accounts

- [ ] **GitHub account** — to access this repo
- [ ] **Google account** — for Firebase access
- [ ] **Firebase project access** — ask the project owner to add you

---

## 🚀 Installation Guide

### 1️⃣ Install Flutter

**macOS:**
```
brew install --cask flutter
flutter --version
flutter doctor
```

**Windows:**
1. Download Flutter SDK from flutter.dev
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to System PATH
4. Run in PowerShell: `flutter --version`

**Linux:**
```
sudo snap install flutter --classic
flutter doctor
```

> ⚠️ Run `flutter doctor` and fix any ❌ issues before continuing!

---

### 2️⃣ Install VS Code Extensions

Open VS Code, press `Cmd+Shift+X` (Mac) or `Ctrl+Shift+X` (Windows), then install:

- **Flutter** (by Dart Code)
- **Dart** (by Dart Code)
- **Error Lens**
- **Material Icon Theme**

Or via terminal:
```
code --install-extension Dart-Code.flutter
code --install-extension Dart-Code.dart-code
```

---

### 3️⃣ Install Android Studio + Emulator

1. Download from [developer.android.com/studio](https://developer.android.com/studio)
2. During installation, select:
   - ✅ Android SDK
   - ✅ Android SDK Platform
   - ✅ Android Virtual Device
3. After installation, open Android Studio
4. **More Actions** → **Virtual Device Manager** → **Create Virtual Device**
5. Select **Pixel 7** → Download Android 14 system image → Finish

---

### 4️⃣ Install Firebase Tools

```
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

**Add FlutterFire to PATH (macOS/Linux):**
```
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc
```

**Verify:**
```
flutterfire --version
firebase --version
```

---

### 5️⃣ Clone the Repository

```
cd ~/Desktop
git clone https://github.com/raghadashraf/JobScope.git
cd JobScope
```

---

### 6️⃣ Install Dependencies

```
flutter pub get
```

This downloads all required packages (~2-3 minutes).

---

### 7️⃣ Configure Firebase

⚠️ **IMPORTANT**: Each developer must configure Firebase on their own machine.

**Step 1**: Ask the project owner (Raghad) to add your email as Editor on Firebase project `jobscope-app`.

**Step 2**: After accepting the invitation, run:
```
firebase login
flutterfire configure --project=jobscope-app --platforms=android,web
```

When prompted, press **Enter** to accept default bundle IDs.

This generates `lib/firebase_options.dart` automatically.

> 📌 This file is gitignored to keep secrets safe. Never commit it!

---

### 8️⃣ Run the App

**On Chrome (Web) — Fastest:**
```
flutter run -d chrome
```

**On Android Emulator:**
```
flutter emulators
flutter emulators --launch <emulator_id>
flutter run
```

**On Real Device:**
1. Enable Developer Options on phone
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter devices` to verify
5. Run: `flutter run`

---

## 🎯 Daily Workflow (After Setup)

```
git pull
flutter pub get
flutter run -d chrome
```

---

## 🤝 Git Workflow for Team

**Daily commands:**
```
git pull
git add .
git commit -m "✨ Brief description of changes"
git push
```

**Feature branches:**
```
git checkout -b feature/your-feature-name
git add .
git commit -m "✨ Your changes"
git push -u origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

### Commit Message Emojis

| Emoji | Meaning |
|-------|---------|
| ✨ | New feature |
| 🐛 | Bug fix |
| 🎨 | UI/styling |
| 🔒 | Security |
| 📝 | Documentation |
| ⚡ | Performance |
| 🤖 | AI/automation |

---

## 📁 Project Structure

```
JobScope/
├── lib/
│   ├── core/              Constants, theme
│   ├── data/              Models & repositories
│   ├── features/          Feature modules
│   │   ├── auth/          🔐 Authentication
│   │   ├── home/          🏠 Dashboards
│   │   ├── cv_management/ 📄 CV upload
│   │   ├── job_listing/   💼 Jobs
│   │   ├── matching/      🎯 AI matching
│   │   ├── notifications/ 🔔 Notifications
│   │   └── training/      🎓 Practice
│   └── main.dart          🚀 Entry point
├── android/
├── ios/
├── web/
└── pubspec.yaml
```

---

## 🆘 Troubleshooting

**❌ "Flutter command not found"**
Add Flutter to your PATH and restart terminal.

**❌ "No connected devices"**
Start an emulator first or use Chrome.

**❌ "Firebase not configured"**
Run `flutterfire configure --project=jobscope-app`

**❌ "No space left on device"**
```
flutter clean
rm -rf ~/.gradle/caches
flutter pub get
```

**❌ Hot reload not working**
Press `R` (capital) in terminal for full restart.

**❌ "Gradle build failed"**
```
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 📚 Helpful Resources

- 📖 [Flutter Documentation](https://docs.flutter.dev/)
- 🎓 [Flutter Codelabs](https://codelabs.developers.google.com/?cat=Flutter)
- 📺 [Flutter YouTube](https://www.youtube.com/c/flutterdev)
- 💧 [Riverpod Docs](https://riverpod.dev/)
- 🔥 [Firebase Flutter](https://firebase.flutter.dev/)
- 🤖 [Gemini API](https://ai.google.dev/docs)

---

## 👥 Team Communication

- **GitHub Issues**: Report bugs, suggest features
- **Pull Requests**: For code review before merging
- **Project Owner**: Raghad Ashraf

---

## 📞 Need Help?

If you're stuck:
1. Check this guide
2. Search on Google or Stack Overflow
3. Ask the team
4. Create a GitHub Issue with full error message and your OS/Flutter version

---

## ✅ Setup Verification Checklist

- [ ] `flutter doctor` shows no major issues
- [ ] `flutter pub get` runs without errors
- [ ] `flutter run -d chrome` opens the app
- [ ] You see the JobScope splash screen
- [ ] You can sign up a new account
- [ ] After signup, you land on the Dashboard
- [ ] Hot reload works (save a file → see changes)

---

**Welcome to the team! 🎉 Happy coding! 🚀**

*Last updated: April 2026*