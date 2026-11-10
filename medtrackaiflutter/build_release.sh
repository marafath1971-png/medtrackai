#!/bin/bash

# MedTrack AI — Production Build Script
# This script prepares and builds the Android App Bundle (.aab) for Google Play.

set -e

echo "🚀 Starting Production Build Process..."

# 1. Environment Check
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file missing. Please create it with GEMINI_API_KEY."
    exit 1
fi

# 2. Keystore Check
if [ ! -f "android/key.properties" ]; then
    echo "ℹ️  android/key.properties not found. Build will sign with debug keys (ideal for local testing)."
    echo "    For Google Play distribution, copy android/key.properties.example to android/key.properties and fill in your release keystore."
fi

# 3. Clean and Fetch
echo "🧹 Cleaning project..."
flutter clean
echo "📦 Fetching dependencies..."
flutter pub get

# 4. Static Analysis
echo "🔍 Running static analysis..."
if ! flutter analyze; then
    echo "❌ Analysis failed. Please fix errors before building for production."
    exit 1
fi

# 5. Build AAB
# 5. Extract environment defines
RC_KEY=$(grep -E '^(RC_GOOGLE_KEY|PURCHASES_API_KEY)=' .env | head -n 1 | cut -d '=' -f2- | tr -d ' "')
GEMINI_KEY=$(grep -E '^GEMINI_API_KEY=' .env | head -n 1 | cut -d '=' -f2- | tr -d ' "')

# 6. Build AAB
echo "🏗️  Building Android App Bundle..."
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/app/outputs/symbols \
  ${RC_KEY:+--dart-define=RC_GOOGLE_KEY="$RC_KEY"} \
  ${GEMINI_KEY:+--dart-define=GEMINI_API_KEY="$GEMINI_KEY"}

echo "---------------------------------------------------"
echo "✅ SUCCESS! Your production build is ready at:"
echo "build/app/outputs/bundle/release/app-release.aab"
echo "---------------------------------------------------"
echo "Note: If the build failed with 'Keystore' errors, ensure your key.jks exists"
echo "and your android/key.properties points to the correct absolute path."
