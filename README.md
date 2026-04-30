<div align="center">

# 🎯 JobScope

### *Scope the right jobs for you*

**An AI-powered mobile platform that connects job candidates with recruiters through smart CV evaluation, intelligent job matching, and scenario-based interview training.**

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-3.3-blueviolet?style=for-the-badge)](https://riverpod.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

> 👥 **For Contributors**: See [SETUP.md](./SETUP.md) for detailed installation instructions.

---

## 🌟 Overview

**JobScope** is a modern Flutter mobile application designed to revolutionize the hiring process. By leveraging AI, it provides intelligent CV evaluation, personalized job matching, and interview preparation tools — making job hunting and recruiting smarter, faster, and more effective.

### 🎯 The Problem

- 📄 Job seekers struggle to know if their CV matches a job before applying
- 🔍 Recruiters spend hours screening unqualified applicants
- 💼 Candidates apply unprepared for technical interviews
- 🤝 Lack of meaningful matching between skills and roles

### 💡 The Solution

JobScope uses AI to:
- ✨ Analyze CVs and extract skills automatically
- 🎯 Match candidates with relevant jobs based on profile strength
- 🤖 Generate scenario-based questions for interview preparation
- 📊 Rank applicants for recruiters by match quality
- 🔔 Notify users instantly about matches and updates

---

## ✨ Features

### 👤 For Candidates

| Feature | Description |
|---------|-------------|
| 📄 **Smart CV Upload** | Upload PDF/DOCX with automatic AI parsing |
| 🎯 **AI Job Matching** | Get personalized match scores for every job |
| 🤖 **Interview Training** | Practice scenario-based questions before applying |
| 📊 **Application Tracking** | Real-time status updates on your applications |
| 🔔 **Smart Notifications** | Instant alerts for matches and recruiter responses |
| 💼 **Profile Strength** | AI-powered insights to improve your CV |

### 💼 For Recruiters

| Feature | Description |
|---------|-------------|
| 📝 **Job Posting** | Create detailed job listings with smart skill tagging |
| 🏆 **AI Ranking** | Applicants automatically ranked by match score |
| ✅❌ **Quick Actions** | Accept, reject, or shortlist with one tap |
| 📈 **Analytics Dashboard** | Track hiring metrics and pipeline health |
| 💬 **Direct Messaging** | Communicate with candidates in-app |
| 🔍 **Smart Search** | Filter applicants by skills, experience, location |

---

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.41** — Cross-platform mobile framework
- **Dart 3.11** — Programming language
- **Riverpod 3.3** — State management
- **Google Fonts** — Inter & Plus Jakarta Sans typography
- **Material 3** — Modern design system

### Backend & Cloud
- **Firebase Authentication** — Secure user authentication
- **Cloud Firestore** — Real-time NoSQL database
- **Firebase Storage** — CV and document storage
- **Firebase Cloud Messaging** — Push notifications

### AI & Processing
- **Google Gemini API** — CV analysis and question generation
- **Syncfusion Flutter PDF** — PDF text extraction

### Architecture
- **Clean Architecture** — Separation of concerns
- **Feature-First Structure** — Scalable codebase organization
- **Repository Pattern** — Abstracted data sources

---

## 📱 Screenshots

> 📸 *Screenshots coming soon — currently in active development*

| Splash Screen | Role Selection | Login |
|:---:|:---:|:---:|
| _Coming soon_ | _Coming soon_ | _Coming soon_ |

| Candidate Dashboard | Job Listings | Profile |
|:---:|:---:|:---:|
| _Coming soon_ | _Coming soon_ | _Coming soon_ |

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.41+
- Dart 3.11+
- Firebase account

### Installation

```bash
# Clone the repository
git clone https://github.com/raghadashraf/JobScope.git
cd JobScope

# Install dependencies
flutter pub get

# Configure Firebase
flutterfire configure --project=jobscope-app

# Run the app
flutter run -d chrome
```

📖 **For detailed setup instructions, see [SETUP.md](./SETUP.md)**

---

## 🏗️ Architecture

JobScope follows **Clean Architecture** principles with a **feature-first** folder structure:

```
lib/
├── 📂 core/                    Shared utilities
│   ├── constants/              Colors, strings, sizes
│   ├── theme/                  App theming
│   ├── services/               AI, notifications
│   └── utils/                  Helpers, routing
│
├── 📂 data/                    Data layer
│   ├── models/                 Data models
│   ├── repositories/           Repository implementations
│   └── datasources/            Remote & local sources
│
├── 📂 features/                Feature modules
│   ├── auth/                   🔐 Authentication
│   ├── home/                   🏠 Dashboards & navigation
│   ├── cv_management/          📄 CV upload & parsing
│   ├── job_listing/            💼 Job browse & post
│   ├── matching/               🎯 AI matching engine
│   ├── notifications/          🔔 Push notifications
│   ├── technical_questions/    🤖 AI question generation
│   └── training/               🎓 Interview preparation
│
└── main.dart                   🚀 Entry point
```

### Design Patterns Used

- 🏛️ **Clean Architecture** — Layered separation
- 📦 **Repository Pattern** — Data abstraction
- 🔄 **Provider Pattern** — Riverpod for DI & state
- 🎨 **Builder Pattern** — Complex UI composition
- 📡 **Stream Pattern** — Real-time data flow

---

## 🗺️ Roadmap

### ✅ Completed
- [x] Project setup with Clean Architecture
- [x] Custom theme with professional design system
- [x] Animated splash screen
- [x] Role selection (Candidate/Recruiter)
- [x] Firebase Authentication (Email/Password)
- [x] Firestore user management
- [x] Candidate dashboard with stats
- [x] Recruiter dashboard
- [x] Bottom navigation for both roles
- [x] Profile screen with sign-out

### 🚧 In Progress
- [ ] CV upload to Firebase Storage
- [ ] AI-powered CV parsing (Gemini API)
- [ ] Job posting form (Recruiter)
- [ ] Job listing with search & filters

### 🔮 Upcoming
- [ ] AI job matching algorithm
- [ ] Scenario-based question generator
- [ ] Training module with feedback
- [ ] Application submission flow
- [ ] Accept/Reject workflow with swipe gestures
- [ ] Real-time push notifications (FCM)
- [ ] In-app messaging
- [ ] Analytics dashboard
- [ ] Multi-language support (Arabic/English)
- [ ] Dark mode toggle
- [ ] Deploy to Play Store & App Store

---

## 🎨 Design Highlights

- 🎨 **Color Palette**: Professional blue (#0A66C2) inspired by LinkedIn & Stripe
- 🔤 **Typography**: Plus Jakarta Sans (headings) + Inter (body)
- ✨ **Animations**: Smooth fade transitions and hover effects
- 📱 **Material 3**: Latest Material Design specifications
- 🌗 **Dark Mode Ready**: Theme system supports both light and dark
- ♿ **Accessibility**: Proper contrast ratios and semantic widgets

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m '✨ Add amazing feature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

📖 See [SETUP.md](./SETUP.md) for development environment setup.

---

## 📊 Project Stats

![GitHub repo size](https://img.shields.io/github/repo-size/raghadashraf/JobScope?style=flat-square)
![GitHub last commit](https://img.shields.io/github/last-commit/raghadashraf/JobScope?style=flat-square)
![GitHub stars](https://img.shields.io/github/stars/raghadashraf/JobScope?style=social)

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

<div align="center">

**Raghad Ashraf**

🎓 Computer Science Student at MIU Egypt  
💼 Aspiring Mobile Developer | AI Enthusiast

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/raghadashraf)
[![Email](https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:raghad2201709@miuegypt.edu.eg)

</div>

---

## 🙏 Acknowledgments

- 🎨 Design inspiration from LinkedIn, Indeed & Stripe
- 🤖 Powered by Google Gemini AI
- 🔥 Built with Firebase
- 📱 Crafted with Flutter
- 💜 Open source community

---

<div align="center">

### ⭐ If you like this project, give it a star!

**Made with 💙 using Flutter**

*Last updated: April 2026*

</div>