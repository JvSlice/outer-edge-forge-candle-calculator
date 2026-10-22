# Outer Edge Forge Candle Calculator — Version 1

This is a mobile-friendly Flutter/Dart web app. The UI is in `lib/main.dart`, and calculation and input parsing are in `lib/candle_calculator.dart`. Build for a GitHub Pages repository URL with Flutter's `--base-href` option.

## Artwork and installation metadata

- The user's original 1254×1254 PNG is preserved unchanged at `assets/branding/oef-icon-original.png`.
- Proportionally scaled, uncropped versions are at `web/icons/icon-192.png`, `web/icons/icon-512.png`, and `web/icons/apple-touch-icon-180.png`. They retain the source's black background and full copper OEF/flame artwork.
- `web/manifest.json` sets the full name to **Outer Edge Forge Candle Calculator**, the short name to **OEF Candles**, and points to the 192×192 and 512×512 icons. `web/index.html` links the manifest and 180×180 Apple touch icon.
- Manifest `id`, `start_url`, `scope`, and icon paths are relative to the deployed app directory. Build with the repository base path shown below for GitHub Pages.

## Requirements

- Welcome screen says “Welcome to Outer Edge Forge Candle Calculator” and “Tap anywhere to begin.” Tap, click, Enter, or Space opens the calculator.
- Enter wax weight per container in grams, including decimals. This is wax alone, before fragrance.
- Select a fragrance load of 6%, 7%, 8%, 9%, or 10%; the default is 8%.
- Fragrance per container is `wax weight × fragrance load / 100`.
- Enter a positive whole number of containers; the default is 1.
- See total wax and total fragrance for the batch. Results update as inputs change.
- Use the separate **Split Fragrances** button to reveal a selector for 1, 2, or 3 fragrances. The fragrance is split equally, with the amount of each fragrance shown for one container and for the full batch.
- Calculations keep full numeric precision until display, which uses two decimal places. Empty, invalid, zero, and negative input shows a clear message and affected results show a dash.
- The interface uses a dark charcoal theme, copper accents, readable text, and large touch controls.

## Example checks

With 100 g wax, 8% fragrance load, and 5 containers:

| Result | Amount |
| --- | ---: |
| Fragrance per container | 8.00 g |
| Batch wax | 500.00 g |
| Batch fragrance | 40.00 g |
| Each of 2 fragrances, per container | 4.00 g |
| Each of 2 fragrances, full batch | 20.00 g |
| Each of 3 fragrances, per container | 2.67 g |
| Each of 3 fragrances, full batch | 13.33 g |

## Offline release

- `web/flutter_bootstrap.js` loads CanvasKit and Skwasm from this app's own `canvaskit/` directory, so Flutter rendering assets are available offline.
- `tools/build_web.mjs` runs a Flutter release build for `/outer-edge-forge-candle-calculator/`, then generates `build/web/sw.js` from `tools/sw-template.js`. It precaches the app shell, compiled Dart, Flutter rendering files, fonts, shaders, manifest, and OEF icons. Flutter's generated service worker stub is removed from the release output.
- The worker is registered only in the release output. Its scope and cache name include this repository path, it ignores requests outside the path, and activation removes only older OEF caches. The release asset hash changes the cache name when files change. A new worker fetches files afresh, finishes caching before activation, and refreshes an already controlled page after taking over.
- A first online load is needed to install the worker and fill the cache. Flutter's development `web-server` preview does not register it.

## Preview and build

For a quick development preview with Flutter 3.41.1 on `PATH`:

```sh
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8766
```

Open `http://127.0.0.1:8766/` in Chromium on this Pi. This preview does not test offline support.

For a release build with offline support, run from the project root:

```sh
flutter pub get
node tools/build_web.mjs
node tools/serve_release.mjs
```

Open `http://127.0.0.1:8767/outer-edge-forge-candle-calculator/` in Chromium. The release server reproduces the GitHub Pages path. Stop either preview with Ctrl+C in its terminal. If Flutter is not on `PATH`, set `OEF_FLUTTER_BIN` to your existing SDK's `flutter` executable for the release build. Use `tools/build_web.mjs` for release, because a plain `flutter build web` omits the custom offline worker.

## GitHub Pages deployment

The `.github/workflows/deploy-pages.yml` workflow runs on pushes to `main`. It installs Flutter 3.41.1 and Node.js 22, runs analysis and tests, builds with `tools/build_web.mjs`, checks the scoped release output, and deploys `build/web` through GitHub Pages Actions. The base path is `/outer-edge-forge-candle-calculator/`; generated output and SDK files are ignored by Git. The app URL is https://jvslice.github.io/outer-edge-forge-candle-calculator/.

## Verification

- The release build completed under `/outer-edge-forge-candle-calculator/` with 27 precached URLs, including `main.dart.js`, CanvasKit and Skwasm files, fonts, shaders, manifest, and all three OEF icons.
- Headless Chromium loaded the app online, activated the scoped worker, then loaded it again with network access disabled. The app rendered and requests for `main.dart.js` and CanvasKit WASM returned 200 from the cache.
- An update simulation installed a new OEF cache, removed the old OEF cache, and refreshed the page. An unrelated app cache remained intact. The release worker was restored afterward.

## Remaining tasks

- Test installation, offline use, updates, and launcher appearance on the target Chromium and Apple devices. The manifest icons use `purpose: any`; no maskable variant has been made, so device launcher shapes should be reviewed for cropping.
