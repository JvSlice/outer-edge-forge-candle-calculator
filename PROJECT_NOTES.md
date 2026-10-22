# Outer Edge Forge Candle Calculator — Version 1

This is a mobile-friendly Flutter/Dart web app. The calculator UI is in `lib/main.dart`; candle and cost calculations are in `lib/candle_calculator.dart` and `lib/cost_calculator.dart`. Build for a GitHub Pages repository URL with Flutter's `--base-href` option.

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
- Use the separate **Split Fragrances** button to reveal a selector for 1, 2, or 3 fragrances. Equal shares are the default. Name each fragrance and move its share slider in whole percentage points, including blends such as 75/25. The other sliders adjust automatically to keep the blend at 100%; each share stays positive. For three fragrances, the remaining share is distributed in proportion to the other two shares, with any rounding point assigned by largest remainder. The amount of each fragrance is shown for one container and for the full batch.
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

With a 75/25 blend, each container uses 6.00 g and 2.00 g; five containers use 30.00 g and 10.00 g.

## Local recipe library

- **Recipes** opens a local list with create, load, edit, duplicate, delete, JSON export, and JSON import. Deletion requires confirmation. Imports are validated and added as copies; existing recipes are never silently overwritten. Matching names are labeled as imported copies.
- Recipes may be incomplete drafts. A recipe stores its name, container type/name and size with unit, wax type and wax weight in grams, fragrance load, up to three named fragrance shares, wick quantity/series/size, center-to-center spacing with unit, wick arrangement, fragrance addition and pour temperatures with °F/°C selection, and notes. Share sliders also appear in the recipe editor. An imported or saved draft with invalid shares keeps its values until **Set equal shares** is pressed.
- Loading a recipe fills the per-container calculator fields and fragrance blend. Batch quantity stays as entered. Calculator edits do not change a saved recipe until **Save Changes** is pressed. **New / Clear Calculator** clears the loaded recipe and all calculator fields while staying on the calculator page; it asks before discarding unsaved input and leaves saved recipes and cost calculations intact.
- **Save as Recipe** opens the recipe editor with current wax grams per container, load percentage, fragrance names/count, and blend shares prefilled. It stores the formula inputs, not rounded fragrance outputs or batch wax. Wax, fragrance shares, and recipe name must be valid for this action; optional container, wick, temperature, and notes fields may stay blank. When a recipe is loaded, choose to create a new one or update it; updating requires a separate overwrite confirmation. Canceling either dialog or editor leaves calculator values and saved records unchanged. Successful saves become the loaded recipe and are also available from **Recipes**.
- Select one or more saved recipes to create a white-background PDF printout. Choose a positive whole-number batch size; the printout shows per-container and batch wax/fragrance amounts and all saved recipe details, including units, wicks, temperatures, and notes. PDF printing/export never writes to recipe storage. Browsers open the PDF in their built-in viewer for printing; **Save / Share PDF** uses the device share sheet where supported and otherwise downloads the file. Use **Export JSON** for editable backups. The print generator uses the bundled OEF artwork and runs offline after the app has been cached.
- PDF generation uses the Dart `pdf` package and `printing` for native print/share. `image` is held at 4.10.2 because the newer 4.11.0 release requires an `archive` API outside `pdf` 3.12.0's allowed range. DejaVu Sans fonts are bundled for names and notes with Unicode characters; their license is in `assets/fonts/LICENSE-DejaVu.txt`.
- Data is stored in this browser on this device using a repository-specific local-storage key. It remains available after closing the browser and while offline after the app has been cached. Browser data clearing can remove it, so **Export JSON** provides a backup for import on another device.
- Recipe data, validation, and persistence are in `lib/recipe.dart` and `lib/recipe_repository.dart`. The editor and library are in `lib/recipe_pages.dart`; browser file transfer is isolated in `lib/recipe_file_io_web.dart`.

## Material cost calculator (issue #3)

- **Material costs** opens a standalone calculation using the current calculator quantities. Select a saved recipe on that screen to load its wax type and grams, fragrance names and shares, wick quantity, and saved cost assumptions. Batch quantity remains a separate one-off input.
- Enter wax purchase price and package pounds; each fragrance bottle's price, size, and unit; cost per wick; vessel cost; and additional per-container costs such as labels or packaging. A zero cost is valid, while a missing or invalid price leaves the material total blank and identifies the missing input.
- Weight ounces use exactly 28.349523125 g/oz, and pounds use exactly 453.59237 g/lb. A fluid-ounce bottle requires its fragrance density in g/mL or the bottle's net fragrance weight in grams. US fluid ounces use 29.5735295625 mL/fl oz. The net weight takes precedence when both are entered. Fluid ounces are never treated as weight ounces.
- The screen shows component grams and costs, wax/wick/vessel/additional costs per container, itemized batch costs, total wax and fragrance grams, and batch grams for each fragrance. Material totals exclude labor, taxes, selling fees, and profit. Calculations retain precision internally; each displayed currency value rounds **up** to the nearest cent, while grams display to two decimal places. Totals come from unrounded costs, so they can differ by a cent from the sum of individually displayed lines.
- Cost assumptions are saved only with **Save costs to recipe**. The screen flags unsaved cost changes and one-off quantity changes. Saving costs does not save changed recipe quantities. Cost fields are included in recipe JSON export/import, and older backups without costs still load. If a recipe's fragrance name changes, its old bottle assumption is cleared for that slot.
- The issue's example has $0.771617… wax, $0.705479… fragrance, $0.20 wicks, and $1.00 vessel per container. With upward currency display this shows $0.78 wax, $0.71 fragrance, and $2.68 total per container. The unrounded five-container total is $13.385485783…, displayed as **$13.39**. The issue lists $13.38; that value does not follow from its inputs and conversions.

## Saved cost calculations (issue #8)

- The cost screen has a separate local saved-calculation library. A saved record contains a full candle and price snapshot, batch size, linked recipe ID/name when applicable, and saved/updated timestamps. Later recipe edits do not change the snapshot.
- Save, restore, edit, duplicate, and confirmed delete are available. **Refresh from recipe** is an explicit action that replaces the snapshot with the current linked recipe and its latest saved cost assumptions while retaining the batch count.
- CSV exports clear columns and units for saved quantity, package assumptions, per-container costs, batch costs, and completeness status. JSON backup export/import retains units, fragrance blend shares, quantities, prices, and linkage metadata; imported records are added as copies and never replace local data.
- Each saved calculation can create a white-background PDF for print/share on mobile or download on desktop. It includes name, linked source, dates, batch size, itemized purchase assumptions and quantities, per-container and batch costs, and an incomplete warning when any cost is missing. Currency is rounded upward only for display. Totals are labeled material costs and exclude labor, tax, selling fees, and profit.
- Saved cost calculations use their own versioned browser storage key and work offline after the app cache has been populated. This is a browser-local library: use the JSON export to transfer it to another device.
- Verification: saved snapshots survive a new repository instance; JSON export/import preserves costs and blend units and imports records as copies; CSV values match the calculation engine's displayed batch total; PDF generation creates a nonempty printable report; and a widget test saves a standalone snapshot and confirms its batch, quantities, and name. The complete Flutter test suite passes (45 tests), and the custom release build completed with 31 app-scoped precache URLs (build version `6622dd904c585adf75e3`).

## Save as Recipe (issue #9)

- The main calculator transfers per-container wax grams, fragrance load, fragrance names, and exact blend percentages into the existing recipe editor. The shared candle calculation code remains the sole source for derived fragrance quantities; saved recipes retain formula inputs only. Batch container count remains on the calculator and does not become the per-container wax value.
- New recipes may leave optional container, wax type, wick details, temperatures, and notes blank. Saving through this action requires a nonempty recipe name, positive wax weight, and valid fragrance shares totaling 100%.
- If a recipe is currently loaded, the user explicitly chooses **Save new recipe** or **Update loaded recipe**. Updating has a confirmation before the editor opens. The editor can be canceled without changing the calculator or stored recipe. After save, the recipe is loaded in the calculator and remains available in the recipe list.
- Verification: widget tests cover the issue's 142 g / 9% / 75–25 formula, preserved three-container batch values, reopening the saved recipe, invalid wax, canceling the editor, and canceling or confirming the loaded-recipe overwrite. The full Flutter suite passes (45 tests), analysis is clean, and the Pages-path release build completed successfully.

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
- Recipe repository tests cover restart persistence, drafts, edit/duplicate/delete, schema validation, duplicate-safe imports, and cost assumption backup. Ratio and widget tests cover whole-percent two- and three-fragrance slider adjustment, 75/25 and 40/60 splits, 30/30/40 redistribution, 100% totals, loading a blend recipe, keeping batch quantity, explicit saves, invalid-draft reset, and creating distinct drafts. Cost tests cover the issue's example, unequal prices, weight/fluid-ounce handling, missing costs, and linked versus one-off edits. In a local release preview before issue #3, Chromium saved a draft through the UI, downloaded a valid JSON backup, imported it as a separate copy, recovered both recipes after a normal restart, and loaded the library with network access disabled.

## Remaining tasks

- Test installation, offline use, updates, and launcher appearance on the target Chromium and Apple devices. The manifest icons use `purpose: any`; no maskable variant has been made, so device launcher shapes should be reviewed for cropping.
- Manually inspect the new material cost screen in Chromium on a narrow device viewport and test its linked save/reload flow offline before publishing these issue #3 changes.
