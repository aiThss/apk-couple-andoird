# Couple Snap

Couple Snap is an Android-first Flutter app for couples to share photo snaps. This version uses a custom REST API, MongoDB, and a separate admin web page that can be deployed on Dokploy.

For the practical setup and usage walkthrough, see [GUIDE.md](GUIDE.md).

## Architecture

- `lib/`: Flutter mobile app.
- `server/`: Express + TypeScript API with MongoDB models, JWT auth, couple setup, photo upload, and admin endpoints.
- `admin/`: lightweight static admin web app.
- `docker-compose.yml`: Dokploy-friendly stack for MongoDB, API, and admin.
- `docker-compose.local.yml`: optional local override that publishes API/admin ports to localhost.

## Mobile Features

- Setup API URL, display name, partner name, couple code, and love start date.
- Anonymous device session or email/password account.
- Join the same couple by entering the same couple code.
- Upload photos from camera/gallery to the API.
- View latest partner snap and memories from cloud data.
- Edit names and love start date from Profile.

## API Data Shape

MongoDB collections:

- `users`: display name, partner name, email, password hash, status, couple reference.
- `couples`: code, love start date, member ids.
- `photos`: couple id, owner id/name, caption, image URL, storage path, soft delete date.

The API stores uploaded image files in `UPLOAD_DIR` and stores metadata in MongoDB. In production, mount `UPLOAD_DIR` as a persistent Dokploy volume. Later, this can be swapped to S3/R2/MinIO without changing the Flutter API contract.

## Run Locally

Create an env file:

```bash
cp .env.example .env
```

Start MongoDB, API, and admin locally:

```bash
docker compose -f docker-compose.yml -f docker-compose.local.yml up --build
```

Local URLs:

- API: `http://localhost:8080/api`
- Uploaded files: `http://localhost:8080/uploads/...`
- Admin: `http://localhost:8081`

Default development admin credentials come from `.env`.

## Flutter

Install dependencies:

```powershell
& 'C:\Users\Admin\Downloads\flutter\bin\flutter.bat' pub get
```

Run:

```powershell
& 'C:\Users\Admin\Downloads\flutter\bin\flutter.bat' run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

Build APK:

```powershell
& 'C:\Users\Admin\Downloads\flutter\bin\flutter.bat' build apk --release --dart-define=API_BASE_URL=https://api.example.com/api
```

The APK also shows an API URL field on onboarding, so you can point a private build at your Dokploy API without rebuilding.

## Server

```bash
cd server
npm install
npm run dev
npm run check
npm run build
```

Important environment variables:

- `MONGODB_URI`
- `JWT_SECRET`
- `PUBLIC_BASE_URL`
- `UPLOAD_DIR`
- `ADMIN_EMAIL`
- `ADMIN_PASSWORD`
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM` for email verification codes.

## Admin

The admin app is static HTML/CSS/JS. Deploy `admin/` as its own Dokploy app or use the provided Dockerfile. It calls the API URL configured in its sidebar.

Admin capabilities:

- Summary counts.
- View users, couples, photos.
- Block/unblock users.
- Edit couple love start date.
- Soft-delete photos.
- View recent random events.

## Brand Assets

The launcher/store artwork is generated from `logo-heart-pixel.png`.

Regenerate Android launcher icons and store images:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\tools\generate_brand_assets.ps1
```

Generated outputs:

- Android launcher icons: `android/app/src/main/res/mipmap-*/ic_launcher*.png`
- Android adaptive icon XML: `android/app/src/main/res/mipmap-anydpi-v26/`
- Store icon: `store_assets/play_store_icon_512.png`
- Large app icon: `store_assets/app_icon_1024.png`
- Feature graphic: `store_assets/feature_graphic_1024x500.png`

Transparent-background variants are the default generated icon outputs. Background-preserved variants are also written as `*_with_background_*.png`.
