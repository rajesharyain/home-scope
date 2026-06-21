# HomeScope — Build & Deployment Guide

Production-ready guide for building the HomeScope Flutter app for Android and iOS, and deploying the FastAPI backend.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Project Setup](#2-project-setup)
3. [Build for Android](#3-build-for-android)
   - [Generate a Keystore](#31-generate-a-keystore)
   - [Configure Signing](#32-configure-signing)
   - [Build Debug APK](#33-build-debug-apk)
   - [Build Release APK](#34-build-release-apk)
   - [Build App Bundle (Play Store)](#35-build-app-bundle-play-store)
   - [Google Play Store Submission](#36-google-play-store-submission)
4. [Build for iOS](#4-build-for-ios)
   - [Apple Developer Setup](#41-apple-developer-setup)
   - [App ID & Bundle Identifier](#42-app-id--bundle-identifier)
   - [Certificates & Provisioning](#43-certificates--provisioning)
   - [Xcode Configuration](#44-xcode-configuration)
   - [Build the IPA](#45-build-the-ipa)
   - [TestFlight Distribution](#46-testflight-distribution)
   - [App Store Submission](#47-app-store-submission)
5. [Backend Production Deployment](#5-backend-production-deployment)
   - [Environment Variables](#51-environment-variables)
   - [Docker Production Setup](#52-docker-production-setup)
   - [Nginx & SSL](#53-nginx--ssl)
   - [Database Migrations](#54-database-migrations)
6. [CI/CD with GitHub Actions](#6-cicd-with-github-actions)
7. [Monitoring & Maintenance](#7-monitoring--maintenance)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

### Mobile (both platforms)

| Tool | Version | Install |
|------|---------|---------|
| Flutter SDK | 3.x | https://docs.flutter.dev/get-started/install |
| Dart | 3.x (bundled with Flutter) | — |
| Git | 2.x | `brew install git` (macOS) |

Verify:
```bash
flutter doctor -v
```
All checkmarks except those you don't need (Web, Linux, Windows) should be green.

### Android

| Tool | Notes |
|------|-------|
| JDK 17+ | `brew install openjdk@17` or Android Studio bundled JDK |
| Android Studio | Or Android SDK command-line tools only |
| Android SDK | API level 33+ (Android 13) recommended |

Set `JAVA_HOME` in your shell profile:
```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)   # macOS
export PATH="$JAVA_HOME/bin:$PATH"
```

### iOS (macOS only)

| Tool | Notes |
|------|-------|
| macOS 13+ | Required to run Xcode 15+ |
| Xcode 15+ | Install from the Mac App Store |
| Xcode Command Line Tools | `xcode-select --install` |
| CocoaPods | `brew install cocoapods` |
| Apple Developer Account | $99/year — https://developer.apple.com |

### Backend

| Tool | Notes |
|------|-------|
| Docker 24+ | https://docs.docker.com/get-docker/ |
| Docker Compose v2 | Bundled with Docker Desktop |
| Python 3.12 | Only needed for local development without Docker |

---

## 2. Project Setup

```bash
# Clone the repo
git clone https://github.com/rajesharyain/home-scope.git
cd home-scope

# Install Flutter dependencies
cd mobile
flutter pub get
cd ..
```

### Environment file

Copy the example and fill in your API keys:
```bash
cp .env.example .env
```

Minimum `.env` for local development:
```env
OPENAI_API_KEY=sk-...
DATABASE_URL=postgresql://homescope:homescope@localhost:5432/homescope
REDIS_URL=redis://localhost:6379/0
```

### Run locally (development)

```bash
# Start backend
docker compose up -d

# Run Flutter app (replace with your simulator/device ID)
cd mobile
flutter run -d "iPhone 16" --dart-define=BACKEND_URL=http://localhost:8000
```

---

## 3. Build for Android

### 3.1 Generate a Keystore

You need a keystore to sign release builds. **Generate it once and keep it safe — losing it means you cannot update your app on the Play Store.**

```bash
keytool -genkey -v \
  -keystore homescope-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias homescope
```

You will be prompted for:
- A keystore password (remember this)
- A key password (can match keystore password)
- Your name, organisation, city, country

Store `homescope-release.jks` somewhere safe outside the repo (e.g., a password manager or encrypted drive). **Never commit this file to Git.**

### 3.2 Configure Signing

Create the signing config file (also gitignored):

**`mobile/android/key.properties`**
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=homescope
storeFile=/absolute/path/to/homescope-release.jks
```

Update `mobile/android/app/build.gradle` to use it:

```groovy
// At the top of the file, before android {}
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

Add to `.gitignore`:
```
mobile/android/key.properties
*.jks
*.keystore
```

### 3.3 Build Debug APK

For testing on a physical device without Play Store:

```bash
cd mobile
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

Install directly:
```bash
flutter install
```

### 3.4 Build Release APK

For sideloading or direct distribution:

```bash
cd mobile
flutter build apk --release \
  --dart-define=BACKEND_URL=https://api.yourdomain.com
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

The release APK will be significantly smaller than debug due to tree-shaking and minification.

### 3.5 Build App Bundle (Play Store)

Google Play requires an App Bundle (`.aab`) for new apps:

```bash
cd mobile
flutter build appbundle --release \
  --dart-define=BACKEND_URL=https://api.yourdomain.com
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 3.6 Google Play Store Submission

**One-time setup:**

1. Create a developer account at https://play.google.com/console ($25 one-time fee)
2. Create a new app → fill in the store listing (title, description, screenshots, icon)
3. Complete the content rating questionnaire
4. Set up pricing & distribution

**Upload the build:**

1. Go to **Release → Production** (or Internal Testing for first builds)
2. Click **Create new release**
3. Upload your `.aab` file
4. Add release notes
5. Click **Review release → Start rollout**

**Before submitting to Production**, test with Internal Testing track:
- Add test accounts under **Internal Testing**
- Share the opt-in link with testers
- Collect feedback, fix issues, then promote to Production

**Version management** — update in `mobile/pubspec.yaml`:
```yaml
version: 1.0.1+2   # version_name+version_code
```
`version_code` must always increase with each upload.

---

## 4. Build for iOS

> iOS builds require macOS. There is no cross-platform workaround.

### 4.1 Apple Developer Setup

1. Enrol at https://developer.apple.com/enroll ($99/year)
2. Sign in to Xcode with your Apple ID: **Xcode → Settings → Accounts → + → Apple ID**
3. Verify your team appears under your account

### 4.2 App ID & Bundle Identifier

1. Go to https://developer.apple.com → **Certificates, IDs & Profiles → Identifiers**
2. Click **+** → **App IDs** → **App**
3. Set:
   - Description: `HomeScope`
   - Bundle ID (Explicit): `com.yourcompany.homescope`
4. Enable capabilities if needed (Push Notifications, etc.)
5. Register

Update the bundle ID in Flutter:
- Open `mobile/ios/Runner.xcodeproj` in Xcode
- Select the **Runner** target → **General** tab
- Set **Bundle Identifier** to match (e.g., `com.yourcompany.homescope`)

Or edit `mobile/ios/Runner/Info.plist` directly:
```xml
<key>CFBundleIdentifier</key>
<string>com.yourcompany.homescope</string>
```

### 4.3 Certificates & Provisioning

**Distribution Certificate:**

1. **Certificates, IDs & Profiles → Certificates → +**
2. Select **Apple Distribution**
3. Follow the CSR (Certificate Signing Request) steps:
   - On your Mac: open **Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority**
   - Save the `.certSigningRequest` file
4. Upload the CSR → Download the `.cer` file
5. Double-click to install into Keychain

**Provisioning Profile:**

1. **Certificates, IDs & Profiles → Profiles → +**
2. Select **App Store** (for App Store distribution) or **Ad Hoc** (for direct distribution)
3. Select your App ID → Select your Distribution Certificate
4. Name it (e.g., `HomeScope AppStore`) → Generate → Download
5. Double-click to install (or drag into Xcode)

**Tip:** Use **Xcode's automatic signing** for development. Switch to **manual signing** only for App Store submission builds.

In Xcode → Runner target → **Signing & Capabilities**:
- Development: check **Automatically manage signing**, select your team
- Release: uncheck → select your provisioning profile manually

### 4.4 Xcode Configuration

Open the project:
```bash
cd mobile/ios
open Runner.xcworkspace   # Always open the .xcworkspace, not .xcodeproj
```

Set the following for the **Runner** target:

| Setting | Value |
|---------|-------|
| Bundle Identifier | com.yourcompany.homescope |
| Version | 1.0.0 |
| Build | 1 |
| Deployment Target | iOS 14.0+ |
| Team | Your Apple Developer team |

Update `Info.plist` for required permissions (add if missing):
```xml
<!-- Camera (if used) -->
<key>NSCameraUsageDescription</key>
<string>Used to scan QR codes</string>

<!-- Location (if used) -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to detect your current location for neighbourhood analysis</string>
```

### 4.5 Build the IPA

**Via Flutter CLI (recommended):**

```bash
cd mobile

flutter build ipa --release \
  --dart-define=BACKEND_URL=https://api.yourdomain.com \
  --export-options-plist=ios/ExportOptions.plist
```

Create `mobile/ios/ExportOptions.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.yourcompany.homescope</key>
        <string>HomeScope AppStore</string>
    </dict>
</dict>
</plist>
```

Output: `build/ios/ipa/HomeScope.ipa`

**Via Xcode (alternative):**

1. Select **Any iOS Device (arm64)** as the build destination
2. **Product → Archive**
3. Wait for the archive to complete (appears in the Organizer window)
4. **Distribute App → App Store Connect → Upload**

### 4.6 TestFlight Distribution

TestFlight lets you distribute beta builds to up to 10,000 testers before App Store approval.

1. Upload the IPA (via step above)
2. Go to https://appstoreconnect.apple.com → your app → **TestFlight**
3. Wait for build processing (~10–30 minutes)
4. **Internal Testing**: Add up to 100 people by Apple ID (no review required, instant)
5. **External Testing**: Add groups of external testers (requires TestFlight beta review, ~1–2 days)
6. Testers install the **TestFlight** app from the App Store and accept your invite

Builds expire after 90 days — upload a new build before that for ongoing beta programs.

### 4.7 App Store Submission

1. Go to https://appstoreconnect.apple.com
2. My Apps → **+** → **New App**
3. Fill in:
   - **Name**: HomeScope
   - **Primary Language**: English
   - **Bundle ID**: com.yourcompany.homescope
   - **SKU**: homescope-001 (internal identifier)

**Store Listing (prepare these in advance):**

| Asset | Spec |
|-------|------|
| App icon | 1024×1024px PNG, no alpha, no rounded corners |
| iPhone screenshots | At least 3, for 6.9" (iPhone 16 Pro Max) |
| iPad screenshots | Required if supporting iPad |
| Short description | Up to 30 characters |
| Full description | Up to 4000 characters |
| Keywords | Up to 100 characters, comma separated |
| Privacy Policy URL | Required |
| Support URL | Required |

**Submit for review:**

1. Under **App Store** tab → select your build from the **Build** section
2. Fill in all required metadata
3. Answer the content declarations (ads, data collection, etc.)
4. Click **Submit for Review**

Review typically takes **24–48 hours**. Apple may request changes — respond promptly in App Store Connect.

---

## 5. Backend Production Deployment

### 5.1 Environment Variables

Create a production `.env` file (never commit this):

```env
# App
DEBUG=false
CORS_ORIGINS=["https://yourdomain.com","https://www.yourdomain.com"]

# Database
DATABASE_URL=postgresql://homescope:STRONG_PASSWORD@db:5432/homescope

# Redis
REDIS_URL=redis://redis:6379/0
CACHE_TTL_SECONDS=86400

# External APIs
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini

# Nominatim
NOMINATIM_URL=https://nominatim.openstreetmap.org
NOMINATIM_USER_AGENT=HomeScope/1.0 (your@email.com)

# Overpass
OVERPASS_URL=https://maps.mail.ru/osm/tools/overpass/api/interpreter
OVERPASS_TIMEOUT=60

# Analysis
DEFAULT_SEARCH_RADIUS=2000.0
MAX_AMENITY_RESULTS=100
```

### 5.2 Docker Production Setup

Create `docker-compose.prod.yml`:

```yaml
services:
  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    restart: unless-stopped
    env_file: .env
    ports:
      - "127.0.0.1:8000:8000"   # Only expose to localhost; Nginx proxies externally
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: postgis/postgis:16-3.4
    restart: unless-stopped
    environment:
      POSTGRES_DB: homescope
      POSTGRES_USER: homescope
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/migrations:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U homescope"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

volumes:
  postgres_data:
  redis_data:
```

Start production stack:
```bash
docker compose -f docker-compose.prod.yml up -d
```

### 5.3 Nginx & SSL

Install Nginx and Certbot:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y
```

Create `/etc/nginx/sites-available/homescope`:
```nginx
server {
    listen 80;
    server_name api.yourdomain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate     /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    client_max_body_size 10M;

    location / {
        proxy_pass         http://127.0.0.1:8000;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 90s;
        proxy_connect_timeout 10s;
    }

    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        access_log off;
    }
}
```

Enable and get certificate:
```bash
sudo ln -s /etc/nginx/sites-available/homescope /etc/nginx/sites-enabled/
sudo nginx -t   # Verify config

# Get SSL certificate
sudo certbot --nginx -d api.yourdomain.com

# Auto-renew (runs twice daily via systemd timer installed by certbot)
sudo systemctl status certbot.timer
```

### 5.4 Database Migrations

Migrations run automatically on first Docker start via `docker-entrypoint-initdb.d`. For subsequent schema changes:

```bash
# Connect to the running DB container
docker compose -f docker-compose.prod.yml exec db \
  psql -U homescope -d homescope -f /path/to/migration.sql
```

Or run migrations manually:
```bash
docker compose -f docker-compose.prod.yml exec api \
  python -c "from database.connection import run_migrations; run_migrations()"
```

**Backup before every migration:**
```bash
docker compose -f docker-compose.prod.yml exec db \
  pg_dump -U homescope homescope > backup_$(date +%Y%m%d_%H%M%S).sql
```

---

## 6. CI/CD with GitHub Actions

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  # ─── Flutter tests ─────────────────────────────────────────
  flutter-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
          cache: true
      - name: Install dependencies
        run: flutter pub get
        working-directory: mobile
      - name: Analyse
        run: flutter analyze
        working-directory: mobile
      - name: Run tests
        run: flutter test
        working-directory: mobile

  # ─── Backend tests ─────────────────────────────────────────
  backend-test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgis/postgis:16-3.4
        env:
          POSTGRES_DB: homescope_test
          POSTGRES_USER: homescope
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: pip
      - name: Install dependencies
        run: pip install -r requirements.txt
        working-directory: backend
      - name: Run tests
        env:
          DATABASE_URL: postgresql://homescope:test@localhost:5432/homescope_test
        run: pytest tests/ -v
        working-directory: backend

  # ─── Android build ─────────────────────────────────────────
  android-build:
    runs-on: ubuntu-latest
    needs: flutter-test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
          cache: true
      - name: Install dependencies
        run: flutter pub get
        working-directory: mobile
      - name: Decode keystore
        run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > mobile/android/app/homescope-release.jks
      - name: Write key.properties
        run: |
          cat <<EOF > mobile/android/key.properties
          storePassword=${{ secrets.ANDROID_KEY_STORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=homescope
          storeFile=homescope-release.jks
          EOF
      - name: Build App Bundle
        run: flutter build appbundle --release --dart-define=BACKEND_URL=${{ secrets.BACKEND_URL }}
        working-directory: mobile
      - name: Upload AAB
        uses: actions/upload-artifact@v4
        with:
          name: android-release-aab
          path: mobile/build/app/outputs/bundle/release/app-release.aab
          retention-days: 14

  # ─── iOS build ─────────────────────────────────────────────
  ios-build:
    runs-on: macos-14
    needs: flutter-test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
          cache: true
      - name: Install dependencies
        run: flutter pub get
        working-directory: mobile
      - name: Install CocoaPods
        run: pod install
        working-directory: mobile/ios
      - name: Import signing certificate
        env:
          CERTIFICATE_BASE64: ${{ secrets.IOS_DISTRIBUTION_CERT_BASE64 }}
          CERTIFICATE_PASSWORD: ${{ secrets.IOS_DISTRIBUTION_CERT_PASSWORD }}
          KEYCHAIN_PASSWORD: temp-keychain-password
        run: |
          CERT_PATH=$RUNNER_TEMP/cert.p12
          KEYCHAIN_PATH=$RUNNER_TEMP/build.keychain
          echo "$CERTIFICATE_BASE64" | base64 --decode > "$CERT_PATH"
          security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security import "$CERT_PATH" -P "$CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
          security list-keychain -d user -s "$KEYCHAIN_PATH"
      - name: Install provisioning profile
        env:
          PROVISIONING_PROFILE_BASE64: ${{ secrets.IOS_PROVISIONING_PROFILE_BASE64 }}
        run: |
          PP_PATH=$RUNNER_TEMP/profile.mobileprovision
          echo "$PROVISIONING_PROFILE_BASE64" | base64 --decode > "$PP_PATH"
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp "$PP_PATH" ~/Library/MobileDevice/Provisioning\ Profiles/
      - name: Build IPA
        run: flutter build ipa --release --dart-define=BACKEND_URL=${{ secrets.BACKEND_URL }} --export-options-plist=ios/ExportOptions.plist
        working-directory: mobile
      - name: Upload IPA
        uses: actions/upload-artifact@v4
        with:
          name: ios-release-ipa
          path: mobile/build/ios/ipa/*.ipa
          retention-days: 14
```

**GitHub Secrets to configure** (Settings → Secrets and variables → Actions):

| Secret | How to get it |
|--------|--------------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i homescope-release.jks` |
| `ANDROID_KEY_STORE_PASSWORD` | The keystore password you chose |
| `ANDROID_KEY_PASSWORD` | The key password you chose |
| `IOS_DISTRIBUTION_CERT_BASE64` | Export `.p12` from Keychain → `base64 -i cert.p12` |
| `IOS_DISTRIBUTION_CERT_PASSWORD` | Password set when exporting from Keychain |
| `IOS_PROVISIONING_PROFILE_BASE64` | `base64 -i profile.mobileprovision` |
| `BACKEND_URL` | `https://api.yourdomain.com` |

---

## 7. Monitoring & Maintenance

### Health checks

The API exposes a health endpoint:
```bash
curl https://api.yourdomain.com/health
# {"status":"healthy","version":"1.0.0"}
```

Configure your uptime monitor (UptimeRobot, Better Uptime, etc.) to ping this every 5 minutes.

### Logs

```bash
# Stream API logs
docker compose -f docker-compose.prod.yml logs -f api

# Last 100 lines from all services
docker compose -f docker-compose.prod.yml logs --tail=100

# Export logs to file
docker compose -f docker-compose.prod.yml logs api > api-$(date +%Y%m%d).log
```

### Database backups

Set up a daily cron backup:
```bash
# Add to crontab: crontab -e
0 3 * * * docker exec homescope-db-1 pg_dump -U homescope homescope | gzip > /backups/homescope-$(date +\%Y\%m\%d).sql.gz

# Keep only last 30 days
0 4 * * * find /backups -name "homescope-*.sql.gz" -mtime +30 -delete
```

### Redis cache inspection

```bash
# Connect to Redis
docker compose -f docker-compose.prod.yml exec redis redis-cli

# Check memory usage
INFO memory

# See cached keys
KEYS homescope:*

# Flush cache if needed (careful in production)
FLUSHDB
```

### Updating the backend

```bash
git pull origin main
docker compose -f docker-compose.prod.yml build api
docker compose -f docker-compose.prod.yml up -d --no-deps api
```

Zero-downtime: the old container continues serving while the new one starts, then the port is handed over.

---

## 8. Troubleshooting

### Android

**`Keystore file not found`**
- Check the absolute path in `key.properties` — it must point to where the `.jks` file actually lives
- On CI, make sure the decode step runs before the build step

**`INSTALL_FAILED_UPDATE_INCOMPATIBLE`**
- Uninstall the old version from the device first: `adb uninstall com.yourcompany.homescope`

**Build fails with Java heap error**
```bash
# Add to android/gradle.properties
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g
```

**`flutter build appbundle` very slow**
- Use `--split-per-abi` for faster local testing (produces separate APKs per architecture)

---

### iOS

**`No profiles for … were found`**
- Check the bundle ID matches exactly between the App ID and the Xcode project
- Re-download the provisioning profile from developer.apple.com and reinstall

**CocoaPods version conflicts**
```bash
cd mobile/ios
pod deintegrate
pod install --repo-update
```

**`Code signing is required for product type 'Application'`**
- Make sure you're building for **Any iOS Device**, not a simulator
- Simulators don't need code signing; the App Store build does

**Bitcode errors (Xcode 14+)**
- Bitcode is deprecated. Ensure `ENABLE_BITCODE = NO` in your Xcode Build Settings

**Build number must be incremented**
- Apple rejects builds with the same version + build number
- Bump `version: x.y.z+BUILD` in `pubspec.yaml` for every submission

---

### Backend

**`relation "analyses" does not exist`**
- The migrations haven't run. Check that `database/migrations/` files are mounted and run `docker compose down -v && docker compose up -d`

**Overpass API returning 504 / timeout**
- The default mirror (`maps.mail.ru`) may be overloaded
- Switch `OVERPASS_URL` in `.env` to an alternative:
  - `https://overpass-api.de/api/interpreter`
  - `https://overpass.kumi.systems/api/interpreter`

**High memory usage**
- Increase Redis `maxmemory` limit in `docker-compose.prod.yml`
- Check for connection leaks with `docker stats`

**SSL certificate not renewing**
```bash
sudo certbot renew --dry-run   # Test renewal
sudo certbot renew             # Force renew
sudo systemctl reload nginx
```

---

*For feature requests or bug reports, open an issue at https://github.com/rajesharyain/home-scope/issues*
