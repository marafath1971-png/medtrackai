# 💊 MedAI: Your Premium Health Companion (V2 Masterpiece)

![MedAI Banner](assets/images/home_logo.png)

MedAI is a state-of-the-art Flutter application designed to revolutionize medication management through cutting-edge AI scanning, biometric security, and ultra-premium UI/UX.

## 🚀 Version 2.0 Highlights

The "Masterpiece" update brings unprecedented personalization and security to your health journey.

### 🌍 Global UX Adaptation
MedAI is built for developed markets worldwide (US, UK, Canada, Australia, Japan, South Korea, Singapore):
- **Dynamic Inventory Tracking**: Differentiated visualizations for pills, blister packs, patches, and specific units.
- **Meal-Based Rituals**: Support for "With Lunch", "Before Sleep" tracking deeply ingrained in East Asian adherence models.
- **Advanced Pharmacy Tracking**: Built-in 1-Tap Pharmacy Dialing for low-stock medications, and dedicated Rx Number fields to streamline North American pharmacy workflows.

### 🔐 Biometric Security
Stay protected with seamless integration of **FaceID**, **TouchID**, and **Fingerprint** authentication. Your medical data is encrypted and accessible only to you.

### 🎭 Advanced Personalization
- **Dynamic Icons**: Choose from **Sleek Dark**, **Calm Blue**, or **Vibrant Gold** to match your style.
- **Custom Soundtrack**: Personalize your wellness journey with curated reminder sounds (Zen, Pulse, Alert, and more).
- **Haptic Feedback**: Meaningful tactile sensations for every interaction.

### 🧠 AI-Powered Scanning
Our proprietary AI scanning engine identifies medications with precision, providing instant dosage information and safety insights.

---

## 🎨 Design Philosophy

MedAI follows a **Premium Dark/Light** aesthetic:
- **Primary Color**: Vibrant Lime Green (`#D9FF66`)
- **Typography**: Inter & Figtree for maximum readability.
- **Glassmorphism**: Subtle, elegant layers using advanced blur effects.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: Provider
- **Local Database**: Shared Preferences (Encrypted)
- **Cloud Backend**: Firebase (Auth, Firestore, Messaging)
- **Animations**: Flutter Animate & Custom Shaders
- **AI Engine**: Google Gemini API

---

## 📥 Getting Started

1. **Clone the repo**:
   ```bash
   git clone <repo-url>
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Configure Environment**:
   Create a `.env` file (see `.env.example` for the full key list):
   ```env
   GEMINI_API_KEY=your_key_here
   PURCHASES_API_KEY=your_revenuecat_key
   GOOGLE_WEB_CLIENT_ID=...
   ```
4. **Add Firebase config** (gitignored — not in the repo, add your own):
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist` (+ `macos/Runner/…` for macOS)
   - `lib/firebase_options.dart` — generate with `flutterfire configure`
5. **Cloud Functions** (optional, for caregiver alerts + missed-dose detection):
   ```bash
   cd functions && npm install && firebase deploy --only functions
   ```
6. **Run the app**:
   ```bash
   flutter run
   ```
   > Note: `kDevPreview` in `lib/main.dart` bypasses auth/onboarding with a demo
   > premium profile for screenshots. **Set it to `false` for real builds.**

## 📜 Documentation
Growth & product docs live in the repo root: `GROWTH_STRATEGY_2026.md`,
`PRODUCT_PLAYBOOK_2026.md`, `DEEP_UX_AUDIT_GROWTH.md`, `FOCUS_MAP.md`.

---
*Built with ❤️ by the MedAI Team.*
