# 📖 Slovo (Слово)

Slovo is a mindful, cross-platform Christian mobile application designed for daily spiritual life, Bible study, and faith inquiry. Built using Flutter, Riverpod, and Firebase, the application provides an ad-free, contemplative digital sanctuary featuring an offline Holy Scripture reader, a curated prayer book, personalized confession preparation, and an intelligent AI companion powered by Google Gemini and ElevenLabs. Slovo bridges sacred tradition with modern mobile design, offering support for both Orthodox and Catholic traditions across iOS and Android devices.

## 🚀 Features

- **📖 Holy Scripture Reader**: Complete offline Bible access (`bible_ru.json.gz`), chapter-by-chapter reading tracking, verse bookmarks, and a distraction-free reader mode tailored for extended study.
- **🙏 Comprehensive Prayer Book**: Curated collection of morning, evening, and situational prayers, personal prayer creation, custom prayer lists, and daily prayer rule tracking.
- **🤖 AI Spiritual Companion**: Thoughtful, respectful answers to theological and life questions grounded in Holy Scripture, powered by Google Gemini with support for Orthodox and Catholic perspectives.
- **🎙️ Voice & Audio Integration**: High-fidelity text-to-speech audio playback powered by ElevenLabs and real-time voice input transcription via `speech_to_text`.
- **🕊️ Confession Guide & Diary**: Structured conscience examination checklist, spiritual reflection journal, and personal note-taking for confession preparation.
- **🔒 Biometric Privacy**: Hardware-backed biometric authentication (Face ID / Touch ID / Fingerprint) and secure local storage via `flutter_secure_storage` to protect private reflections and notes.
- **🔔 Mindful Prayer Reminders**: Customizable local notifications for morning, noon, and evening prayer rules, synchronized with the device timezone.
- **☁️ Multi-Platform Cloud Sync**: Seamless cross-device synchronization via Cloud Firestore with Sign in with Apple, Google Sign-In, and anonymous guest modes.

## 🛠️ Tech Stack

- **Flutter**: Modern cross-platform framework for building natively compiled mobile applications for iOS and Android.
- **Dart**: Strong-mode, object-oriented language optimized for fast client-side development.
- **Flutter Riverpod**: Compile-safe, reactive state management architecture powering data flow and UI state.
- **GoRouter**: Declarative routing system supporting deep linking and structured shell navigation.
- **Google Gemini API**: Large Language Model integration providing context-aware, scripture-aligned spiritual answers.
- **ElevenLabs API**: Studio-quality neural text-to-speech synthesis for prayer and scripture playback.
- **Firebase Suite**:
  - **Firebase Auth**: Multi-provider authentication (Sign in with Apple, Google Sign-In, Anonymous).
  - **Cloud Firestore**: Real-time cloud database for synchronizing bookmarks, custom prayers, and user progress.
  - **Firebase Messaging & Crashlytics**: Push notifications and real-time crash monitoring.
- **Just Audio**: Low-latency, full-featured audio engine for audio playback and stream management.
- **Speech to Text**: Real-time speech recognition for hands-free queries and prayer dictation.
- **Local Auth & Secure Storage**: Biometric authentication and encrypted local key-value persistence.
- **Phosphor Icons & Google Fonts**: Refined visual identity, spiritual iconography, and optimized reading typography.

## 📦 Installation

To set up and run the project locally, follow these steps:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/glebanya13/slovo_app.git
   cd slovo_app
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment Secrets**:
   Create a `secrets.json` file in the root directory with your API credentials:
   ```json
   {
     "API_PROXY_BASE": "https://your-proxy-domain.com",
     "GEMINI_API_KEY": "your_gemini_api_key",
     "ELEVENLABS_API_KEY": "your_elevenlabs_api_key",
     "ELEVENLABS_VOICE_ID": "OmiN5OoGtndz0F9qqRP1",
     "GEMINI_MODEL": "gemini-2.5-flash"
   }
   ```

4. **Run the Application**:
   ```bash
   flutter run --dart-define-from-file=secrets.json
   ```

## 💻 Usage

1. **Onboarding**: Launch the app, select your preferred spiritual tradition (Orthodox or Catholic), and configure initial prayer notifications.
2. **Daily Worship (Today)**: Check the liturgical calendar, read the appointed daily scripture verse, and complete morning or evening prayer rules.
3. **Scripture Study (Bible)**: Navigate easily between books, chapters, and testaments. Add bookmarks and track your yearly reading progress.
4. **Spiritual Inquiry (Ask)**: Type or dictate questions regarding faith, scripture interpretation, or Christian ethics to receive calm, referenced guidance.
5. **Confession Preparation**: Open the Confession guide to review spiritual checkpoints, record personal reflections, and secure the journal behind biometric lock.

## 📂 Project Structure

```markdown
slovo_app/
|-- android/                         # Android native project and Gradle configuration
|-- ios/                             # iOS native project and Xcode workspace
|-- assets/                          # Static assets, fonts, icons, and offline Bible data
|    |-- bible_ru.json.gz            # Compressed offline Holy Scripture database
|    |-- images/                     # App imagery and branding assets
|-- docs/                            # Store listing metadata and release guidelines
|    |-- PLAY_LISTING.md             # Multi-language Google Play store descriptions
|    |-- APPSTORE_PRIVACY.md         # Apple App Store privacy disclosures
|-- lib/                             # Core Flutter application source code
|    |-- app/                        # App lifecycle and root widget configuration
|    |-- core/                       # Services: Auth, Biometrics, TTS, Gemini, Audio, Connectivity
|    |-- data/                       # Bible data parser and local persistence models
|    |-- design/                     # Contemplative theme tokens, color palettes, and typography
|    |-- features/                   # Feature modules
|    |    |-- ask/                   # AI spiritual dialogue and scripture explanation
|    |    |-- auth/                  # Authentication screens and profile setup
|    |    |-- bible/                 # Scripture reader, bookmarks, and search
|    |    |-- confession/            # Conscience examination and confession journal
|    |    |-- more/                  # Settings, tradition switch, and account management
|    |    |-- onboarding/            # First-run spiritual setup and permissions
|    |    |-- prayer/                # Prayer book, custom prayers, and prayer rules
|    |    |-- today/                 # Daily liturgical view, calendar, and appointed readings
|    |-- router/                     # GoRouter configuration and navigation shells
|    |-- state/                      # Global Riverpod state providers
|    |-- main.dart                   # Application entry point
|-- pubspec.yaml                     # Dependencies and package configuration
```

## 🤝 Contributing

To contribute to the project, please follow these steps:

1. Fork the repository using Git: `git fork https://github.com/glebanya13/slovo_app.git`
2. Create a new branch: `git checkout -b feature/your-feature-name`
3. Make your changes and commit them: `git commit -m "feat: add your feature description"`
4. Push your changes to the remote repository: `git push origin feature/your-feature-name`
5. Create a pull request to merge your changes into the main branch.

## 📝 License

The Slovo App Project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 📬 Contact

For questions, feedback, or support, please contact:
- **Email**: [glebanya.com@gmail.com](mailto:glebanya.com@gmail.com)
- **GitHub**: [@glebanya13](https://github.com/glebanya13)
