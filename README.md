# PesaMirror

<p align="center">
  <a href="https://github.com/davidamunga/pesamirror">
    <img src="app/src/main/res/drawable/logo.png" alt="PesaMirror" width="120" />
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Android-3DDC84?style=flat&logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/Kotlin-7F52FF?style=flat&logo=kotlin&logoColor=white" alt="Kotlin" />
  <img src="https://img.shields.io/badge/minSDK-24-brightgreen" alt="min SDK 24" />
  <img src="https://img.shields.io/badge/Open%20Source-MIT-blue" alt="Open Source" />
</p>

Automate M-Pesa USSD (\*334#) flows on Android — Send Money, Paybill, Till Number, and Withdraw Cash. Fill the form, tap Run, and the app guides the USSD session for you.

**Strictly for personal use only.** Works fully offline; your M-Pesa PIN is stored securely on device only.

---

## Screenshot

<p align="center">
  <img src="screenshots/pesamirror-image.png" alt="PesaMirror app on device" width="320" />
</p>

---

## Features

- **Transaction types**
  - Send Money (phone + amount)
  - Paybill (business + account + amount)
  - Till / Lipa na M-PESA (till number + amount)
  - Withdraw Cash (agent + store + amount)
- **Accessibility-driven automation** — reads the USSD menu and enters your choices.
- **Optional “Press 1 to confirm”** — app can send the final confirmation for you, then close the USSD screen after the result.
- **SMS trigger** — run USSD from allowed numbers by sending a formatted SMS (e.g. `SM|amount` for send money).
- **Remote Push trigger** — trigger USSD from the PesaMirror web app via Firebase Cloud Messaging (FCM). Stateless — works even when the Android app is killed.

---

## Intended use

- **Personal use only** — not for commercial or shared use.
- **Best suited for older phones (under Android 12)** — where USSD automation is most practical.
- **Safest if used on a second phone with a second number** — a device and SIM you don’t use for daily banking, so exposure is limited.

---

## Requirements

- **Android 7.0 (API 24)** or higher
- **Accessibility permission** — you must enable “PesaMirror USSD Automation” in Settings → Accessibility so the app can automate the \*334# dialog
- **Phone permission** — to dial \*334#
- Optional: **SMS** and **Notifications** if you use the SMS trigger
- Optional: `google-services.json` placed in `app/` if you use the Remote Push trigger (see [Remote Push setup](#remote-push-setup))

---

## Remote Push setup

Remote Push lets the PesaMirror **web app** send USSD triggers directly to the Android app via **Firebase Cloud Messaging (FCM)** — no SMS, no persistent connection. FCM wakes the Android app even when it is killed.

> **`google-services.json` is not committed to the repo.** You must supply your own to build with Remote Push enabled.

### Steps

1. **Create a Firebase project** (or use an existing one) at [console.firebase.google.com](https://console.firebase.google.com).

2. **Register an Android app** — in _Project Settings → General → Your apps_, click _Add app → Android_. Use package name `com.david.amunga.pesamirror`. Download `google-services.json` and place it at `app/google-services.json` in the repo root, then build and install the app.

3. **Get your device's FCM token** — open PesaMirror on the device, scroll to _Trigger by Remote Push_, and tap **Copy Token**. The token identifies this specific device.

4. **Create a service account** — in _Project Settings → Service accounts_, click **Generate new private key**. Save the downloaded JSON file somewhere safe (do not commit it).

5. **Configure the web app** — open the PesaMirror web app, click the ⚙ settings icon, paste the entire **service account JSON** into the first field and the **device token** from step 3 into the second field.

6. **Enable the toggle** — back in the Android app, enable the _Enable Remote Push_ toggle. Notification permission will be requested if needed.

Triggers sent from the web app now arrive as FCM data messages. `PesaMirrorMessagingService` receives them and executes the USSD flow immediately.

---

## Build & run

1. Clone the repo:
   ```bash
   git clone https://github.com/davidamunga/pesamirror.git
   cd pesamirror
   ```
2. Open in Android Studio (or use Gradle from the command line).
3. Build and run on a device or emulator:
   ```bash
   ./gradlew assembleDebug
   ```
   Install the APK from `app/build/outputs/apk/debug/`, or run from Android Studio.

### Quick install on device (script)

The easiest way to install PesaMirror on a physical device the first time is to run the install script from the repo root:

```bash
./scripts/setup.sh
```

The script checks for ADB and Java (JDK 11+); if either is missing, it prints install instructions and **download links** for your OS (macOS, Linux, or Windows). If no device is detected, it guides you through enabling **Developer options** and **USB debugging** on your phone. Then it builds and installs the debug app on the connected device and reminds you to enable PesaMirror in **Settings → Accessibility** after opening the app.

**Windows users:** Install [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools) (ADB) and [Adoptium Temurin JDK 11](https://adoptium.net/download) (Java). You can run the script from Git Bash, or open the project in Android Studio and use **Run**, or run `gradlew.bat installDebug` from Command Prompt in the repo root.

### Installing from an APK (side-loading)

If you install PesaMirror from a downloaded APK (e.g. from [Releases](https://github.com/davidamunga/pesamirror/releases)) rather than the Play Store, Android will block the install by default. You need to **allow installation from unknown sources** for the app you use to open the APK (browser, file manager, etc.):

- **Android 8+:** Settings → **Apps** → select the app (e.g. Chrome, Files) → **Install unknown apps** → turn **Allow from this source** on.
- **Older Android:** Settings → **Security** → enable **Unknown sources** (or **Install unknown apps**).

Then open the APK again and confirm **Install**.

---

## Usage

1. **First launch** — complete onboarding (you can skip), then enable PesaMirror in **Settings → Accessibility**.
2. **Set your M-Pesa PIN** in the app (stored encrypted on device).
3. Choose **transaction type**, fill the fields (phone/till/business/account/agent/store, amount).
4. Tap **Run** — the app dials \*334# and automates the menu steps.
5. Optionally enable **SMS trigger** and add allowed sender numbers to run flows via SMS.

### SMS trigger format (from allowed senders only)

| Action     | Format                              |
| ---------- | ----------------------------------- |
| Send Money | `SM\|amount` or `SM\|phone\|amount` |
| Till       | `BG\|till_number\|amount`           |
| Paybill    | `PB\|business\|amount\|account`     |
| Withdraw   | `WA\|agent\|amount\|store`          |

---

## Permissions

| Permission                   | Purpose                                         |
| ---------------------------- | ----------------------------------------------- |
| `CALL_PHONE`                 | Dial \*334#                                     |
| `BIND_ACCESSIBILITY_SERVICE` | Automate USSD UI (user must enable in Settings) |
| `RECEIVE_SMS`                | Optional SMS trigger                            |
| `POST_NOTIFICATIONS`         | Optional; for SMS trigger notification          |
| `RECEIVE_BOOT_COMPLETED`     | Restart SMS trigger after reboot                |
| `FOREGROUND_SERVICE`         | Keep SMS / Remote Push trigger running          |
| `INTERNET`                   | Remote Push trigger (FCM)                       |
| `ACCESS_NETWORK_STATE`       | Remote Push trigger network check               |

---

## Risks & disclaimer

- This app automates USSD and can perform **real M-Pesa transactions** using your PIN. Any mistake or misuse can lead to real money movement.
- Use only if you understand and accept these risks. Keep your PIN private; never share it.
- **The developer is not responsible for any loss, misuse, or damage.** You use the app at your own risk.

---

## Author & source

- **Author:** [David Amunga](https://davidamunga.com)
- **Source:** [github.com/davidamunga/pesamirror](https://github.com/davidamunga/pesamirror)

Open source — use and modify at your own risk.
