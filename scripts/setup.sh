#!/usr/bin/env bash
set -e

# Resolve repo root (directory containing gradlew)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [[ ! -f "$REPO_ROOT/gradlew" ]]; then
  echo "Error: Could not find gradlew. Run this script from the PesaMirror repo (or from scripts/)."
  exit 1
fi
cd "$REPO_ROOT"

print_adb_instructions() {
  echo ""
  echo "--- ADB (Android Debug Bridge) is required ---"
  echo "Install it for your system, then run this script again."
  echo ""
  echo "  Official download (all platforms): https://developer.android.com/tools/releases/platform-tools"
  echo ""
  case "$(uname -s)" in
    Darwin)
      echo "macOS:"
      echo "  brew install android-platform-tools"
      echo "  Ensure adb is on your PATH (usually already is after Homebrew install)."
      ;;
    Linux)
      echo "Linux (Ubuntu/Debian):"
      echo "  sudo apt install android-tools-adb"
      echo "  (Package name may vary on other distros; search for 'adb' or 'android-tools'.)"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "Windows (Git Bash / MSYS2 / Cygwin):"
      echo "  • Download Android Platform Tools (zip) from the link above, extract, and add the folder to your PATH."
      echo "  • Or install via Chocolatey: choco install adb"
      echo "  • Or use Android Studio: SDK Manager → SDK Tools → Android SDK Platform-Tools."
      echo "  Note: This script is intended for macOS/Linux. On Windows you can install ADB and Java (see below),"
      echo "  then open the project in Android Studio and use Run, or run: gradlew.bat installDebug in Command Prompt."
      ;;
    *)
      echo "Install Android Platform Tools (adb) for your OS and add adb to your PATH."
      ;;
  esac
  echo ""
}

print_java_instructions() {
  echo ""
  echo "--- Java (JDK 11 or higher) is required ---"
  echo "Install it for your system, set JAVA_HOME if needed, then run this script again."
  echo ""
  echo "  Official download (all platforms): https://adoptium.net/download (choose JDK 11)"
  echo ""
  case "$(uname -s)" in
    Darwin)
      echo "macOS:"
      echo "  brew install openjdk@11"
      echo "  Add to your shell profile: export JAVA_HOME=\$(/usr/libexec/java_home -v 11)"
      ;;
    Linux)
      echo "Linux (Ubuntu/Debian):"
      echo "  sudo apt install openjdk-11-jdk"
      echo "  Optionally: export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "Windows (Git Bash / MSYS2 / Cygwin):"
      echo "  • Download Temurin JDK 11 from the link above (Windows x64 .msi or .zip), install, and set JAVA_HOME."
      echo "  • Or install via Winget: winget install EclipseAdoptium.Temurin.11.JDK"
      echo "  • Or via Chocolatey: choco install temurin11"
      echo "  Then use Android Studio to build/run, or run: gradlew.bat installDebug in Command Prompt from the repo root."
      ;;
    *)
      echo "Install JDK 11 or higher for your OS and ensure 'java' and 'javac' are on your PATH (or set JAVA_HOME)."
      ;;
  esac
  echo ""
}

print_device_instructions() {
  echo ""
  echo "--- No Android device or emulator detected ---"
  echo "Follow these steps, then run this script again:"
  echo ""
  echo "  1. Enable Developer options"
  echo "     Settings → About phone → tap \"Build number\" 7 times."
  echo ""
  echo "  2. Enable USB debugging"
  echo "     Settings → Developer options → USB debugging (turn ON)."
  echo ""
  echo "  3. Connect your device"
  echo "     Use a USB cable. On the device, tap \"Allow\" when asked for USB debugging."
  echo ""
  echo "  4. Verify"
  echo "     Run: adb devices"
  echo "     You should see your device listed with state \"device\"."
  echo ""
}

print_post_install() {
  echo ""
  echo "--- Install complete ---"
  echo ""
  echo "Next steps on your device:"
  echo "  • Open the PesaMirror app."
  echo "  • If Android prompts, allow installation from this source."
  echo "  • Enable PesaMirror in Settings → Accessibility (required for USSD automation)."
  echo "  • Set your M-Pesa PIN in the app and grant Phone permission when asked."
  echo ""
}

# --- Check for google-services.json (required for Remote Push / Firebase) ---
check_google_services() {
  if [[ ! -f "$REPO_ROOT/app/google-services.json" ]]; then
    echo ""
    echo "⚠  Optional: app/google-services.json not found."
    echo ""
    echo "   Remote Push (FCM) will NOT be available without it."
    echo "   To enable Remote Push:"
    echo ""
    echo "   1. Go to https://console.firebase.google.com and open (or create) your project."
    echo "   2. Register an Android app with package name: com.david.amunga.pesamirror"
    echo "   3. Download google-services.json and place it at: app/google-services.json"
    echo "   4. Re-run this script, or rebuild manually: ./gradlew assembleDebug"
    echo ""
    echo "   See README → 'Remote Push setup' for the full walkthrough (service account, device token)."
    echo ""
  fi
}

# --- Check ADB (install if missing on macOS/Linux) ---
if ! command -v adb &>/dev/null; then
  echo "ADB not found. Attempting to install..."
  case "$(uname -s)" in
    Darwin)
      if command -v brew &>/dev/null; then
        brew install android-platform-tools && true
      fi
      ;;
    Linux)
      if command -v apt-get &>/dev/null; then
        echo "Running: sudo apt-get update && sudo apt-get install -y android-tools-adb"
        sudo apt-get update && sudo apt-get install -y android-tools-adb && true
      elif command -v dnf &>/dev/null; then
        echo "Running: sudo dnf install -y android-tools"
        sudo dnf install -y android-tools && true
      fi
      ;;
  esac
  if ! command -v adb &>/dev/null; then
    echo "ADB could not be installed automatically."
    print_adb_instructions
    echo "After installing ADB, run this script again: ./scripts/setup.sh"
    exit 1
  fi
fi
echo "ADB found: $(adb version | head -1)"

# --- Check Java (JDK 11+) ---
java_version=""
if [[ -n "$JAVA_HOME" && -x "$JAVA_HOME/bin/javac" ]]; then
  java_version=$("$JAVA_HOME/bin/javac" -version 2>&1 | sed -E 's/.*version ([0-9]+).*/\1/')
fi
if [[ -z "$java_version" ]] && command -v javac &>/dev/null; then
  java_version=$(javac -version 2>&1 | sed -E 's/.*version ([0-9]+).*/\1/')
fi
if [[ -z "$java_version" ]] && command -v java &>/dev/null; then
  java_version=$(java -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/')
fi
if [[ -z "$java_version" || "$java_version" -lt 11 ]]; then
  echo "Java 11 or higher not found (got: ${java_version:-none}). Attempting to install..."
  case "$(uname -s)" in
    Darwin)
      if command -v brew &>/dev/null; then
        brew install openjdk@11 && true
        if [[ -z "$JAVA_HOME" ]] && [[ -d /opt/homebrew/opt/openjdk@11 ]]; then
          export JAVA_HOME=/opt/homebrew/opt/openjdk@11
        elif [[ -z "$JAVA_HOME" ]] && [[ -d /usr/local/opt/openjdk@11 ]]; then
          export JAVA_HOME=/usr/local/opt/openjdk@11
        fi
        [[ -n "$JAVA_HOME" ]] && export PATH="$JAVA_HOME/bin:$PATH"
      fi
      ;;
    Linux)
      if command -v apt-get &>/dev/null; then
        echo "Running: sudo apt-get update && sudo apt-get install -y openjdk-11-jdk"
        sudo apt-get update && sudo apt-get install -y openjdk-11-jdk && true
        if [[ -z "$JAVA_HOME" ]] && [[ -d /usr/lib/jvm/java-11-openjdk-amd64 ]]; then
          export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
        elif [[ -z "$JAVA_HOME" ]] && [[ -d /usr/lib/jvm/java-11-openjdk-arm64 ]]; then
          export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
        fi
        [[ -n "$JAVA_HOME" ]] && export PATH="$JAVA_HOME/bin:$PATH"
      elif command -v dnf &>/dev/null; then
        echo "Running: sudo dnf install -y java-11-openjdk-devel"
        sudo dnf install -y java-11-openjdk-devel && true
      fi
      ;;
  esac
  # Re-check Java after possible install
  java_version=""
  if [[ -n "$JAVA_HOME" && -x "$JAVA_HOME/bin/javac" ]]; then
    java_version=$("$JAVA_HOME/bin/javac" -version 2>&1 | sed -E 's/.*version ([0-9]+).*/\1/')
  fi
  if [[ -z "$java_version" ]] && command -v javac &>/dev/null; then
    java_version=$(javac -version 2>&1 | sed -E 's/.*version ([0-9]+).*/\1/')
  fi
  if [[ -z "$java_version" ]] && command -v java &>/dev/null; then
    java_version=$(java -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/')
  fi
  if [[ -z "$java_version" || "$java_version" -lt 11 ]]; then
    echo "Java 11 or higher could not be installed automatically."
    print_java_instructions
    echo "After installing Java, run this script again: ./scripts/setup.sh"
    exit 1
  fi
fi
echo "Java found: version $java_version"

# --- Check device connected ---
device_count=0
device_serial=""
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]+device[[:space:]]*$ ]]; then
    device_count=$((device_count + 1))
    [[ -z "$device_serial" ]] && device_serial="${BASH_REMATCH[1]}"
  fi
done < <(adb devices 2>/dev/null | grep -E '[[:space:]]+device[[:space:]]*$')

if [[ $device_count -eq 0 ]]; then
  echo "No Android device or emulator connected."
  print_device_instructions
  echo "After connecting a device, run this script again: ./scripts/setup.sh"
  exit 1
fi
if [[ $device_count -gt 1 ]]; then
  echo "Multiple devices detected. Using first device: $device_serial"
  export ANDROID_SERIAL="$device_serial"
fi
echo "Device detected: $device_serial"

# --- Check google-services.json (Remote Push / Firebase) ---
check_google_services

# --- Build and install ---
echo ""
echo "Building and installing PesaMirror (debug)..."
./gradlew installDebug
echo "Install complete."

# --- Launch app on device ---
echo "Launching PesaMirror on device..."
adb shell am start -n com.david.amunga.pesamirror/.LaunchActivity 2>/dev/null || true

print_post_install
