# KOW Admin Web (Migrated to KowTSide)

This folder now contains the Flutter Web admin panel for Karunungan on Wheels (KOW).

## Tech Stack
- Flutter Web (Dart)
- Riverpod for state management
- GoRouter for routing
- Dio for API requests
- WebSocket channel for live sync events

## Run Locally
1. Install Flutter SDK and enable web support.
2. Install dependencies:
   flutter pub get
3. Run in development mode using env file:
   flutter run -d chrome --dart-define-from-file=.env.dev

Frontend-only mode is enabled in .env.dev.
This bypasses backend calls and uses mock data, so local CORS does not block login.

Mock credentials:
- Username: kow_admin
- Password: Admin@KOW2026
<!-- BRO, You know this ain't mock data. This is the real password -->

## Build for Production
flutter build web --release --dart-define-from-file=.env.prod

Serve the `build/web` folder using a static file server (e.g., `serve` npm package, Vercel, Netlify).

## Environment Files
- `.env.dev` for local development
- `.env.prod` for production build values

Both files currently define:
- `API_BASE_URL`

## Deployment
The project includes `vercel.json` and is ready for static deployment to Vercel.

## Notes
- This folder was migrated from `kow-admin-web` as requested.
- Backend APIs are expected to follow the KOW documentation contracts.

flutter run -d chrome --web-hostname localhost --web-port 3000 --dart-define-from-file=.env.dev
-- This command runs the Flutter web app on localhost:3000 with environment variables from .env.dev. To resolve the cors issue.