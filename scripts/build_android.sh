#!/bin/bash
set -e

# Configuration
export JAVA_HOME="/home/sotcsa/.sdkman/candidates/java/21.0.2-amzn"
export ANDROID_HOME="/home/sotcsa/Downloads/andr"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# Verify SDK installation (must match compileSdkVersion in variables.gradle)
SDK_PLATFORM="36"
BUILD_TOOLS="36.0.0"

if [ ! -d "$ANDROID_HOME/platforms/android-$SDK_PLATFORM" ]; then
    echo "Android SDK Platform $SDK_PLATFORM not found. Installing..."
    yes | sdkmanager "platforms;android-$SDK_PLATFORM"
fi

if [ ! -d "$ANDROID_HOME/build-tools/$BUILD_TOOLS" ]; then
    echo "Android Build Tools $BUILD_TOOLS not found. Installing..."
    yes | sdkmanager "build-tools;$BUILD_TOOLS"
fi

# Accept all SDK licenses
yes | sdkmanager --licenses > /dev/null 2>&1 || true

# Sync web assets into the Android project
echo "Syncing web assets..."
npm run build:cap
npx cap sync android

echo "Building Android APK..."
cd android

# Ensure gradlew is executable
chmod +x gradlew

# Build Debug APK
./gradlew assembleDebug

echo "Build Successful!"
echo "APK location: $(pwd)/app/build/outputs/apk/debug/app-debug.apk"
