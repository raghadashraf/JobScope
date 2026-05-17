<div align="center">

# 🎯 JobScope

### *Scope the right jobs for you*

**An AI-powered mobile platform that connects job candidates with recruiters through smart CV evaluation, intelligent job matching, scenario-based interview training, and real-time application tracking.**

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-3.3-blueviolet?style=for-the-badge)](https://riverpod.dev)
[![Gemini](https://img.shields.io/badge/Gemini_AI-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

> 👥 **For Contributors**: See [SETUP.md](./SETUP.MD) for detailed installation instructions.

---

## 🌟 Overview

**JobScope** is a modern Flutter mobile application designed to revolutionize the hiring process. By leveraging Google Gemini AI, it provides intelligent CV evaluation, personalized job matching, cover letter generation, salary intelligence, and interview preparation tools — making job hunting and recruiting smarter, faster, and more effective.

### 🎯 The Problem

- 📄 Job seekers don't know if their CV matches a job before applying
- 🔍 Recruiters spend hours screening unqualified applicants
- 💼 Candidates apply unprepared for technical interviews
- 📝 Writing a tailored cover letter for every job is exhausting
- 💰 Candidates have no way to know if a salary offer is fair

### 💡 The Solution

JobScope uses Google Gemini AI to:
- ✨ Parse CVs and extract skills, experience, and education automatically
- 🎯 Match candidates with jobs using semantic similarity scoring
- 🤖 Generate scenario-based interview questions tailored to each role
- 📝 Write personalised cover letters in one tap
- 💰 Tell candidates whether a job's salary is below, fair, or above market rate
- 📊 Rank applicants for recruiters by AI match quality
- 🔔 Notify users in real-time about matches, views, and status changes

---

## ✨ Features

### 👤 For Candidates

| Feature | Status | Description |
|---------|--------|-------------|
| 📄 **Smart CV Upload** | ✅ Done | Upload PDF/DOCX — AI parses skills, experience, education |
| 📊 **Profile Strength Score** | ✅ Done | 0–100% score based on CV completeness |
| 🎯 **AI Job Matching** | ✅ Done | Semantic match score per job using Gemini embeddings |
| 💼 **Job Browse & Search** | ✅ Done | Search, filter by skills / location / salary range |
| 🔖 **Bookmark Jobs** | ✅ Done | Save jobs to a personal bookmarks list |
| 📋 **Apply to Jobs** | ✅ Done | Submit applications with CV attached |
| 📈 **Application Tracking** | ✅ Done | Real-time status — Under Review / Shortlisted / Accepted / Rejected |
| ⏱️ **Application Timeline** | ✅ Done | Visual step-by-step journey per application |
| ↩️ **Withdraw Application** | ✅ Done | Withdraw pending applications |
| 🤖 **Interview Training** | ✅ Done | AI-generated scenario questions per job role |
| 🧠 **Skill Assessment** | ✅ Done | Quiz generated from your CV skills with scoring |
| 📝 **AI CV Builder** | ✅ Done | Gemini builds a professional CV from your profile |
| 📝 **Cover Letter Generator** | 🔜 Planned | One-tap personalised cover letter per job |
| 💰 **Salary Intelligence** | 🔜 Planned | AI market rate analysis per job posting |
| 🔔 **Push Notifications** | ✅ Done | FCM + local notifications for status changes |
| 👁️ **Profile Views** | 🔜 Planned | See which recruiters viewed your profile |
| 📊 **Skills Gap Radar** | 🔜 Planned | Visual gap between your skills and market demand |
| 📈 **Market Pulse** | 🔜 Planned | Live stats on what's hiring in your field |
| 🏆 **Career XP & Badges** | 🔜 Planned | Gamified progress system |
| 🔥 **Daily Streak** | 🔜 Planned | Habit loop for active job seekers |
| 🤝 **AI Career Coach** | 🔜 Planned | Chat with Gemini using your CV as context |
| 🃏 **Shareable Profile Card** | 🔜 Planned | Branded card to share on LinkedIn/WhatsApp |

### 💼 For Recruiters

| Feature | Status | Description |
|---------|--------|-------------|
| 📝 **Post Jobs** | ✅ Done | Create detailed listings with skill tagging and salary range |
| ✏️ **Edit / Deactivate Jobs** | ✅ Done | Manage active job listings |
| 🏆 **AI-Ranked Applicants** | ✅ Done | Candidates sorted by Gemini match score |
| ✅❌ **Accept / Reject / Shortlist** | ✅ Done | One-tap status updates |
| 📈 **Analytics Dashboard** | ✅ Done | Hiring metrics, acceptance rate, top skills, pipeline health |
| 👤 **Applicant Detail View** | ✅ Done | Full CV, skills, match score per applicant |
| 🔍 **Filter Applicants** | ✅ Done | Filter by status (pending / shortlisted) |

---

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.41** — Cross-platform mobile (iOS, Android, Web)
- **Dart 3.11** — Programming language
- **Riverpod 3.3** — State management (Notifier API)
- **go_router 17** — Declarative routing with auth guards
- **Google Fonts** — Inter & Plus Jakarta Sans typography
- **Material 3** — Modern design system
- **fl_chart** — Analytics charts
- **Lottie** — Micro-animations
- **Shimmer** — Skeleton loading states
- **Animations** — Page transition animations

### Backend & Cloud
- **Firebase Authentication** — Email/password auth
- **Cloud Firestore** — Real-time NoSQL database
- **Firebase Storage** — CV and photo storage
- **Firebase Cloud Messaging** — Push notifications
- **flutter_local_notifications** — In-app notification display

### AI & Processing
- **Google Gemini 1.5 Flash** — CV parsing, job matching, interview questions, skill assessment, cover letters, salary intelligence
- **Syncfusion Flutter PDF** — PDF text extraction
- **Gemini Embeddings API** — Semantic job-candidate matching

### Packages
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^3.3.1 | State management |
| `go_router` | ^17.2.2 | Navigation |
| `firebase_core` | ^4.7.0 | Firebase init |
| `firebase_auth` | ^6.4.0 | Authentication |
| `cloud_firestore` | ^6.3.0 | Database |
| `firebase_storage` | ^13.3.0 | File storage |
| `firebase_messaging` | ^16.2.0 | Push notifications |
| `file_picker` | ^11.0.2 | CV file selection |
| `syncfusion_flutter_pdf` | ^33.2.4 | PDF parsing |
| `image_picker` | ^1.2.2 | Profile photo |
| `http` | ^1.6.0 | Gemini API calls |
| `fl_chart` | ^1.2.0 | Charts |
| `google_fonts` | ^8.1.0 | Typography |
| `shimmer` | ^3.0.0 | Loading UI |
| `lottie` | ^3.3.3 | Animations |
| `shared_preferences` | ^2.5.5 | Local storage |
| `cached_network_image` | ^3.4.1 | Image caching |
| `intl` | ^0.20.2 | Date formatting |
| `animations` | ^2.2.0 | Transitions |
| `flutter_svg` | ^2.2.4 | SVG rendering |

---

## 🚀 Installation & Setup

### Prerequisites

| Tool | Version | Download |
|------|---------|----------|
| Flutter SDK | 3.41+ | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| Dart SDK | 3.11+ | Included with Flutter |
| Xcode | 15+ | Mac App Store (iOS only) |
| Android Studio | Latest | [developer.android.com](https://developer.android.com/studio) |
| VS Code | Latest | [code.visualstudio.com](https://code.visualstudio.com) |
| Node.js | 20+ | [nodejs.org](https://nodejs.org) |
| Git | Latest | [git-scm.com](https://git-scm.com) |

### Required accounts
- Google account with access to the Firebase project
- Google AI Studio account for Gemini API key — [aistudio.google.com](https://aistudio.google.com/app/apikey)

---

### Step 1 — Install Flutter

**macOS:**
```bash
brew install --cask flutter
flutter doctor
```

**Windows:**
```powershell
# Download from flutter.dev, extract to C:\flutter
# Add C:\flutter\bin to System PATH, then:
flutter doctor
```

**Linux:**
```bash
sudo snap install flutter --classic
flutter doctor
```

> ⚠️ Run `flutter doctor` and resolve any ❌ issues before continuing.

---

### Step 2 — VS Code Extensions

Press `Cmd+Shift+X` (Mac) or `Ctrl+Shift+X` (Windows) and install:

- **Flutter** — by Dart Code
- **Dart** — by Dart Code
- **Error Lens** — inline error highlighting
- **Material Icon Theme** — file icons

Or via terminal:
```bash
code --install-extension Dart-Code.flutter
code --install-extension Dart-Code.dart-code
code --install-extension usernamehw.errorlens
```

---

### Step 3 — iOS Setup (Mac only)

```bash
# Install Xcode from the Mac App Store, then:
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
sudo gem install cocoapods

# Verify
flutter doctor
```

To run on a real iPhone:
1. Connect iPhone via USB → tap **Trust** on the phone
2. Open `ios/Runner.xcworkspace` in Xcode
3. Go to **Runner → Signing & Capabilities**
4. Set **Team** to your Apple ID (add under Xcode → Settings → Accounts)
5. Change **Bundle Identifier** to something unique: `com.yourname.jobscope`
6. Click **Register Device**

```bash
# Install iOS tools
brew install ios-deploy

# Check your iPhone is detected
flutter devices
```

---

### Step 4 — Android Setup

1. Download and install [Android Studio](https://developer.android.com/studio)
2. Open Android Studio → **More Actions → Virtual Device Manager → Create Virtual Device**
3. Select **Pixel 7** → Download **Android 14** system image → Finish

```bash
# Verify Android toolchain
flutter doctor --android-licenses
```

---

### Step 5 — Firebase CLI

```bash
# Install Firebase tools
npm install -g firebase-tools
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Add to PATH (macOS/Linux)
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc

# Verify
flutterfire --version
firebase --version
```

---

### Step 6 — Clone the Repository

```bash
git clone https://github.com/raghadashraf/JobScope.git
cd JobScope
```

---

### Step 7 — Install Dependencies

```bash
flutter pub get
```

---

### Step 8 — Configure Firebase

> ⚠️ Every developer must do this step on their own machine. The generated file is gitignored.

**Step 8a** — Ask the project owner to add your Google email as Editor on Firebase project `jobscope-app`.

**Step 8b** — After accepting the invitation:

```bash
firebase login
flutterfire configure --project=jobscope-app --platforms=android,ios,web
```

Accept the default bundle IDs when prompted. This generates `lib/firebase_options.dart` automatically.

> 📌 `firebase_options.dart` is gitignored — never commit it.

---

### Step 9 — Add Gemini API Key

1. Go to [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
2. Click **Create API Key**
3. Copy the key
4. Open `lib/core/services/ai_service.dart` and replace line 7:

```dart
static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
```

with:

```dart
static const String _apiKey = 'AIza...your_actual_key';
```

> ⚠️ Never commit your API key. Consider using `--dart-define` or a `.env` file for production.

---

### Step 10 — Run the App

**iOS (real device or simulator):**
```bash
flutter run
# or target a specific device:
flutter run -d "iPhone 15"
```

**Android emulator:**
```bash
flutter emulators --launch Pixel_7_API_34
flutter run
```

**Chrome (web):**
```bash
flutter run -d chrome
```

**List all available devices:**
```bash
flutter devices
```

---

### Verify Setup

- [ ] `flutter doctor` shows no major issues
- [ ] `flutter pub get` runs without errors
- [ ] `lib/firebase_options.dart` exists
- [ ] Gemini API key is set in `ai_service.dart`
- [ ] `flutter run` opens the JobScope splash screen
- [ ] You can sign up a new account
- [ ] After signup you land on the candidate or recruiter dashboard
- [ ] Hot reload works — save a file and see changes instantly

---

## 🏗️ Architecture

JobScope follows **Clean Architecture** principles with a **feature-first** folder structure:

```
lib/
├── 📂 core/
│   ├── constants/          app_colors.dart, app_strings.dart, app_sizes.dart
│   ├── services/           ai_service.dart, cv_parser_service.dart,
│   │                       job_matching_service.dart, notification_service.dart,
│   │                       local_notification_service.dart, gemini_embedding_service.dart
│   ├── theme/              app_theme.dart (Material 3, light + dark)
│   └── utils/              app_router.dart (go_router with auth guards)
│
├── 📂 data/
│   ├── models/             user_model.dart, job_model.dart, cv_model.dart,
│   │                       application_model.dart, question_model.dart
│   └── repositories/       job_repository.dart, application_repository.dart
│
├── 📂 features/
│   ├── auth/               login, signup, role selection, onboarding, edit profile
│   ├── home/               candidate_home, recruiter_home, dashboard, profile,
│   │                       post_job, applicants, recruiter_dashboard
│   ├── cv_management/      cv_screen, ai_cv_builder_screen
│   ├── job_listing/        jobs_screen, job_detail_screen, job_card, filters,
│   │                       match_badge, match_reasons
│   ├── applications/       applications_screen, application_detail_screen,
│   │                       application_card, status_badge
│   ├── ai_features/        interview_training_screen, skill_assessment_screen
│   └── recruiter/          recruiter_jobs, job_applicants, applicant_detail,
│                           recruiter_analytics
│
└── main.dart
```

### Design Patterns

- 🏛️ **Clean Architecture** — layered separation of concerns
- 📦 **Repository Pattern** — data sources abstracted behind interfaces
- 🔄 **Notifier Pattern** — Riverpod 3.x `Notifier` + `NotifierProvider`
- 🎨 **Builder Pattern** — complex UI composition
- 📡 **Stream Pattern** — real-time Firestore data flow
- 🛡️ **Auth Guard** — `go_router` redirect based on auth state + role

### Firestore Collections

```
users/{uid}
  └── bookmarks/{jobId}

jobs/{jobId}

applications/{applicationId}

cvs/{uid}

salaryInsights/{jobId}        ← cached AI salary analysis
```

---

## 🗺️ Roadmap

### ✅ Completed
- [x] Clean Architecture project setup
- [x] Material 3 design system with full light + dark theme
- [x] Animated splash screen and onboarding
- [x] Role selection — Candidate / Recruiter
- [x] Firebase Auth — email/password signup & login
- [x] go_router navigation with auth guards and role-based redirect
- [x] Candidate dashboard with animated stats
- [x] Recruiter dashboard with pipeline metrics
- [x] CV upload (PDF/DOCX) → Firebase Storage
- [x] AI CV parsing — Gemini extracts skills, experience, education
- [x] Profile strength score (0–100%)
- [x] AI CV Builder — Gemini generates a professional CV
- [x] Job listings with search, skill/location/salary filters
- [x] Real-time Firestore job stream with pagination
- [x] Bookmark / save jobs feature
- [x] AI job match score — Gemini embedding semantic similarity
- [x] Match reasons — AI explains why a job fits your profile
- [x] Job detail screen with requirements and skills
- [x] Apply to jobs — Firestore application creation
- [x] Duplicate application prevention
- [x] "Already Applied" state on job detail
- [x] Applications screen — All / Under Review / Shortlisted / Decided tabs
- [x] Application detail with 4-step timeline
- [x] Withdraw application feature
- [x] Recruiter: Post job with full form validation
- [x] Recruiter: Edit / deactivate job listings
- [x] Recruiter: View applicants ranked by AI match score
- [x] Recruiter: Accept / Reject / Shortlist applicants
- [x] Recruiter: Analytics screen with fl_chart charts
- [x] AI Interview Training — Gemini generates scenario questions
- [x] Skill Assessment — AI quiz from CV skills with scoring
- [x] Local push notifications on application status change
- [x] Edit profile — image picker, name, phone, bio, headline, location, LinkedIn
- [x] Profile screen with CV strength indicator

### 🔜 Planned
- [ ] AI Cover Letter Generator — one-tap per job
- [ ] Salary Intelligence — market rate verdict per job
- [ ] AI Career Coach — chat with Gemini using CV as context
- [ ] Skills Gap Radar — fl_chart radar comparing your skills vs market demand
- [ ] Job Market Pulse — live stats from all active jobs
- [ ] Career XP System — points, levels, badges
- [ ] Daily Application Streak — habit loop with FCM reminders
- [ ] Profile Views — candidates see which recruiters viewed them
- [ ] Referral System — invite friends, both earn XP
- [ ] Shareable Profile Card — branded PNG to share on social media
- [ ] Settings screen with dark mode toggle (SharedPreferences)
- [ ] Notification preferences
- [ ] Full FCM push notification triggers on status change
- [ ] In-app notifications screen with unread count badge
- [ ] Forgot password screen
- [ ] Email verification flow
- [ ] Multi-language support (Arabic / English)
- [ ] Deploy to App Store & Google Play

---

## 🎨 Design Highlights

- 🎨 **Primary color**: `#0A66C2` — deep professional blue (LinkedIn-inspired)
- 🔤 **Typography**: Plus Jakarta Sans (headings, w700–w800) + Inter (body, w400–w600)
- ✨ **Animations**: Entry fade/slide, icon spring, Lottie micro-animations
- 📱 **Material 3**: `useMaterial3: true` with `ColorScheme.fromSeed`
- 🌗 **Dark mode**: Full dark theme defined in `app_theme.dart`, toggle coming soon
- ♿ **Accessibility**: Semantic widgets, proper contrast ratios

---

## 🤝 Contributing

1. Fork the project
2. Create your feature branch: `git checkout -b feature/AmazingFeature`
3. Commit your changes: `git commit -m '✨ Add amazing feature'`
4. Push to the branch: `git push origin feature/AmazingFeature`
5. Open a Pull Request

### Commit Message Convention

| Emoji | Type |
|-------|------|
| ✨ | New feature |
| 🐛 | Bug fix |
| 🎨 | UI/styling |
| ♻️ | Refactor |
| 🔒 | Security |
| 📝 | Documentation |
| ⚡ | Performance |
| 🤖 | AI / Gemini |
| 🔔 | Notifications |
| 📦 | Dependencies |

---

## 🆘 Troubleshooting

**`flutter command not found`**
Add Flutter to your PATH and restart the terminal.

**`No connected devices`**
Start an emulator first, or plug in a device and run `flutter devices`.

**`firebase_options.dart not found`**
Run `flutterfire configure --project=jobscope-app`.

**`The getter 'platform' isn't defined for FilePicker`**
Make sure you're on `file_picker: ^11.0.2` — use `FilePicker.pickFiles()` not `FilePicker.platform.pickFiles()`.

**`StateNotifier is not defined`**
The project uses Riverpod 3.x. Replace `StateNotifier` with `Notifier` and `StateNotifierProvider` with `NotifierProvider`.

**`Gradle build failed`**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

**`CocoaPods not installed` (iOS)**
```bash
sudo gem install cocoapods
cd ios && pod install
```

**Hot reload not working**
Press `R` (capital) in the terminal for a full restart.

---

## 📚 Resources

- 📖 [Flutter Documentation](https://docs.flutter.dev)
- 💧 [Riverpod Docs](https://riverpod.dev)
- 🔥 [Firebase Flutter](https://firebase.flutter.dev)
- 🤖 [Gemini API Docs](https://ai.google.dev/docs)
- 🧭 [go_router Docs](https://pub.dev/packages/go_router)
- 📊 [fl_chart Docs](https://pub.dev/packages/fl_chart)

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- 🎨 Design inspiration from LinkedIn, Indeed & Stripe
- 🤖 Powered by Google Gemini 1.5 Flash
- 🔥 Built on Firebase
- 📱 Crafted with Flutter & Dart
- 📊 Charts by fl_chart
- 💜 Open source community

---

<div align="center">

**Built with ❤️ by Raghad Ashraf**

*Last updated: May 2026*

</div>