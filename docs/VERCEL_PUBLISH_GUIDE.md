# Publish `KowTSide` to Vercel

This guide is for the GitHub repo:

- `https://github.com/vgl-spec/KowTSide`

It is written specifically for the Flutter Web app in this local folder:

- `KOW-ADMIN/KowTSide`

## Short answer

Yes, you can publish this project to Vercel, but treat it as a static Flutter Web deployment.

The important part is that Vercel does not have a Flutter framework preset, so the safest setup is:

1. Import the GitHub repo into Vercel.
2. Use a custom Flutter install step.
3. Build the app with `flutter build web`.
4. Publish `build/web`.
5. Set `API_BASE_URL` to the backend URL you want the deployed app to use.

## What I checked in this repo

- `vercel.json` already sets:
  - `outputDirectory` to `build/web`
  - a rewrite from all routes to `index.html`
- `lib/core/constants.dart` reads `API_BASE_URL` from Dart defines
- `.env.prod` currently contains:
  - `API_BASE_URL=http://localhost:3000`

That value is okay temporarily for build testing, but a deployed Vercel site cannot call your own local `localhost:3000`.

## Recommended publish path

Use a GitHub-connected Vercel project.

Why this is the best option:

- every push can create a Preview Deployment
- your `main` branch can create Production Deployments
- the repo owner/co-owner workflow fits Vercel well
- rollback is much easier than manual uploads

## Before you deploy

Make sure you already have:

1. A Vercel account with access to the correct GitHub account/team.
2. Access to `vgl-spec/KowTSide`.
3. A backend URL to use from the deployed app.
   - Temporary testing value: `http://localhost:3000`
   - Real hosted example: `https://your-api.onrender.com`
   - Real hosted example: `https://api.your-domain.com`
4. A successful local production build:

```bash
flutter pub get
flutter build web --release --dart-define-from-file=.env.prod
```

If local production build fails, fix that first before connecting Vercel.

## Step-by-step

### 1. Fix production values first

For now, you can keep `.env.prod` as localhost if your backend is not hosted yet.

Example:

```env
API_BASE_URL=http://localhost:3000
FRONTEND_ONLY=false
AUTO_LOGIN=false
```

Notes:

- this is fine for now because you said your backend is not yet deployed
- once the site is live on Vercel, browser requests to `localhost:3000` will point to the visitor's own computer, not your VPS or your development machine
- `FRONTEND_ONLY=false` is correct for production.
- `AUTO_LOGIN=false` is also correct for production.
- Vercel will use its own environment variables, but this file is still useful for local production testing.

### 2. Commit and push your latest repo changes

From the `KowTSide` repo:

```bash
git status
git add .
git commit -m "Prepare Vercel deployment"
git push origin master
```

If you are deploying from another branch first, that is fine too.

### 3. Create a new Vercel project

In Vercel:

1. Sign in at `https://vercel.com/`
2. Click `Add New...`
3. Click `Project`
4. Choose `Import Git Repository`
5. Select `vgl-spec/KowTSide`

If you do not see the repo:

- confirm GitHub access is granted to Vercel
- confirm the repo is in the correct GitHub account or org

### 4. What to enter on the "New Project" screen

Based on the screen you showed, enter these values:

- Vercel Team:
  - keep your current team selected
- Project Name:
  - `kowadmin`
- Application Preset:
  - `Other`
- Root Directory:
  - `./`

Then open `Build and Output Settings` and enter:

- Build Command:

```bash
$HOME/flutter/bin/flutter config --enable-web && $HOME/flutter/bin/flutter pub get && $HOME/flutter/bin/flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL
```

- Output Directory:

```text
build/web
```

- Install Command:

```bash
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
```

Then open `Environment Variables` and add:

- Name: `API_BASE_URL`
- Value: for now use `http://localhost:3000`

Example:

```text
http://localhost:3000
```

After that, click `Deploy`.

### 5. Set the project root correctly

Use the correct root depending on what you import:

- If you import `vgl-spec/KowTSide` directly:
  - Root Directory: `.`
- If you import the larger `KOW-ADMIN` repo instead:
  - Root Directory: `KowTSide`

For your linked repo `vgl-spec/KowTSide`, the correct root should be `.`.

### 6. Configure Build & Output settings

Because this is Flutter Web, use custom settings.

Recommended Vercel settings:

- Framework Preset: `Other`
- Install Command:

```bash
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
```

- Build Command:

```bash
$HOME/flutter/bin/flutter config --enable-web && $HOME/flutter/bin/flutter pub get && $HOME/flutter/bin/flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL
```

- Output Directory:

```text
build/web
```

Why I recommend this:

- the repo already knows how to build Flutter Web
- Vercel can publish static output
- using the full Flutter binary path avoids shell PATH issues between install/build steps

### 7. Add the production environment variable

In Vercel, go to:

- `Project Settings`
- `Environment Variables`

Add:

- Name: `API_BASE_URL`
- Value: the backend URL you want this deployment to call
- Environment: `Production`

Recommended example:

```text
API_BASE_URL=http://localhost:3000
```

When your backend is later deployed to Hostinger VPS or another host, change this value and redeploy.

You can also add the same variable for:

- `Preview`

That lets branch deployments talk to a staging or shared backend.

### 8. Keep SPA routing enabled

Flutter Web needs unmatched routes to fall back to `index.html`.

Your current `vercel.json` already does that with:

- `rewrites`
- destination `index.html`

That is important for routes like:

- `/login`
- `/dashboard`
- `/students/123`

Without the rewrite, direct refreshes on nested routes may 404.

### 9. Deploy

Click `Deploy`.

Vercel will:

1. clone your repo
2. run the install command
3. run the build command
4. publish the contents of `build/web`

If it succeeds, Vercel will give you:

- a Preview URL
- a Production URL if deployed from the production branch

### 10. Test the deployed app

After deployment, verify:

1. `/login` loads
2. browser refresh works on deep routes
3. API calls point to your real backend
4. login works
5. charts, images, and fonts load correctly
6. no requests still point to `localhost:3000`

## Recommended `vercel.json`

Your current `vercel.json` is close, but for clean Vercel builds I recommend this version:

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "framework": null,
  "installCommand": "git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter",
  "buildCommand": "$HOME/flutter/bin/flutter config --enable-web && $HOME/flutter/bin/flutter pub get && $HOME/flutter/bin/flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL",
  "outputDirectory": "build/web",
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

If you want, you can apply that to the repo after this guide.

## Fast CLI alternative

If you prefer terminal deployment:

```bash
npm install -g vercel
cd KowTSide
vercel link
vercel
vercel --prod
```

You still need to configure:

- the correct root directory
- the install/build commands
- `API_BASE_URL`

Those can be set in the Vercel dashboard, then reused by CLI deploys.

## Common problems

### Build fails with `flutter: command not found`

Cause:

- Flutter is not installed in the Vercel build environment

Fix:

- use the custom Install Command and Build Command shown above

### App loads but API calls fail

Cause:

- `API_BASE_URL` points to the wrong backend
- if it points to `localhost:3000`, the deployed app will try to contact the visitor's own computer

Fix:

- update the Vercel environment variable
- redeploy

### Direct links like `/students/12` return 404

Cause:

- SPA rewrite is missing or wrong

Fix:

- keep the rewrite to `index.html`

### Images or fonts do not load

Cause:

- asset paths or build output issue

Fix:

- confirm local `flutter build web` works first
- redeploy after a clean successful local build

## Recommended order for you

If I were publishing this repo, I would do it in this order:

1. update `vercel.json` to include the Flutter install step
2. push to `vgl-spec/KowTSide`
3. import the repo into Vercel
4. for now set `API_BASE_URL=http://localhost:3000`
5. deploy and confirm the Flutter app builds
6. later, replace `API_BASE_URL` with the Hostinger VPS backend URL and redeploy

## Official sources used

- Vercel import guide:
  - https://vercel.com/docs/getting-started-with-vercel/import
- Vercel project configuration with `vercel.json`:
  - https://vercel.com/docs/project-configuration/vercel-json
- Vercel environment variables:
  - https://vercel.com/docs/environment-variables
- Vercel CLI deploy:
  - https://vercel.com/docs/cli/deploy
- Vercel CLI project deploy workflow:
  - https://vercel.com/docs/projects/deploy-from-cli

## Repo-specific conclusion

For `vgl-spec/KowTSide`, the cleanest setup is:

- deploy it as a static Flutter Web app
- use Vercel with a custom Flutter install/build pipeline
- publish `build/web`
- set `API_BASE_URL` to the backend URL you currently want to use

If you want, the next safe follow-up is to update `KowTSide/vercel.json` so the repo matches this guide exactly.
