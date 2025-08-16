## GloboFucker

Instant keyboard layout switching for macOS using the Globe key. Lives in the menu bar. Minimal, glass/blur aesthetic.


### Download

- Grab the latest packaged `.zip` from this repository’s Releases page (if available).
- Or build from source (see below) and create a zip via `make package` → `build/GloboFucker-<version>.zip`.

### Before you begin: disable the system Globe key action

To let GloboFucker intercept the Globe key instantly, macOS must NOT handle it for input switching.

Do both (depending on your macOS version):

1) System Settings → Keyboard → “Press Globe key to” → set to “Do Nothing”.

2) System Settings → Keyboard → Keyboard Shortcuts… → Input Sources → turn OFF:
- “Select the previous input source”
- “Select next source in Input menu” (or similar wording)

Optional quick check: Press the Globe key — if the system changes the input source, it’s still enabled. Use the app’s “Test Globe Key” to verify.

### Quick start

1) Download and open the app (or run `make run`).
2) Complete onboarding:
- Configure the Globe key (use “Open Keyboard Settings” and “Test Globe Key”).
- Grant Accessibility permission when prompted.
3) The app shows a menu bar icon and starts switching layouts instantly on Globe key press.

### Build & Run (from source)

Prerequisites:
- macOS with a Globe key (MacBook/Magic Keyboard)
- Xcode Command Line Tools (`xcode-select --install`)

Commands:
- `make all` — build the `.app` bundle into `build/`
- `make run` — build and open the app
- `make install` — copy the app to `/Applications`
- `make package` — create `build/GloboFucker-<version>.zip`
- `make clean` — remove `build/`

### Localization

All localizations are plain JSON files in `Languages/` and are shipped inside the app bundle. Missing keys fall back to English automatically.

Currently bundled: `en`, `ru`, `uk`, `fr`, `el`.

#### 1) Create a new language

- Copy an existing file, e.g. `Languages/en.json` → `Languages/xx.json` where `xx` is the language code (`de`, `es`, …).
- Edit only the values on the right.

Required keys used by the app UI:

```
{
  "lang_author_label": "Translated by:",
  "lang_author": "Contributor",
  "lang_name": "English",
  "about": "About",
  "about_text": "GloboFucker - Instant language switching for MacBook\n\nVersion {version}\n\nEliminates delays when switching languages using the globe key.",
  "ok": "OK",
  "status_active": "Active",
  "language": "Language",
  "auto_start": "Auto-start",
  "hide_from_dock": "Hide from Dock",
  "quit": "Quit",
  "grant_permission": "Grant Permission",
  "start": "Start",
  "accessibility_permission": "Accessibility Permission",
  "accessibility_permission_message": "Accessibility permission is required for GloboFucker to work. Please grant permission in System Preferences.",
  "permission_granted_restart": "Permission granted! Please restart the app.",
  "permission_not_granted": "Permission not granted.",
  "permission_step_1": "1. System Settings → Privacy & Security → Accessibility",
  "permission_step_2": "2. Click + and add GloboFucker if not listed",
  "permission_step_3": "3. Toggle GloboFucker to ON",
  "permission_step_4": "4. Return here — status updates automatically",
  "hello_popover": "Hi, I'm here :)",
  "keyboard_setup_title": "Globe Key Setup",
  "keyboard_setup_desc": "Disable the system ‘Change input source’ action for the Globe key in Keyboard settings, otherwise the system will intercept the press and block instant switching.",
  "open_keyboard_settings": "Open Keyboard Settings",
  "test_globe": "Test Globe Key",
  "test_waiting": "Press the Globe key within 3 seconds…",
  "test_passed": "Good: system did not intercept Globe — you're ready",
  "test_failed": "Input source switched — disable Globe action in settings",
  "ob_welcome_title": "Welcome to GloboFucker",
  "ob_welcome_subtitle": "Instant layout switching with the Globe key. A few quick steps to get ready.",
  "ob_globe_title": "Configure the Globe key",
  "ob_globe_subtitle": "Disable the system action for Globe in Keyboard settings and verify it doesn't switch the layout.",
  "ob_perm_title": "Grant Accessibility Permission",
  "ob_back": "Back",
  "ob_next": "Next",
  "ob_finish": "Finish"
}
```

#### 2) Build with your new language

- Place your `xx.json` into the repo `Languages/` folder.
- Run `make all` — the Makefile copies all `Languages/*.json` into the bundle on each build.

#### 3) Test your localization

- Run `make run` and open the menu bar icon → Language submenu. Pick your language.
- UI updates instantly. Missing keys fall back to English.

Notes:
- `{version}` inside `about_text` is replaced with the app version at runtime.
- English fallback is built-in via `LocalizationManager`.

### Permissions

GloboFucker needs macOS Accessibility permission to listen to your keyboard events. During onboarding, click “Grant Permission”. If you need to do it manually:

- System Settings → Privacy & Security → Accessibility → add GloboFucker and enable it.

The app automatically detects the permission and continues once granted.

### Troubleshooting

- Globe key still switches input source: Revisit “Before you begin” and disable system shortcuts. Use “Test Globe Key” to verify.
- No switching happens at all: Ensure Accessibility is granted and the app icon is visible in the menu bar.
- Multiple layouts: The app cycles only through enabled, selectable input sources (like the native menu does).

### Contributing

1) Fork the repo and create a feature branch: `git checkout -b feat/lang-xx` (or your feature)
2) Add/update files (e.g., `Languages/xx.json`) and ensure all keys above are present
3) Build locally (`make all`) and test (`make run`)
4) Commit with a clear message: `git commit -am "Add xx localization"`
5) Push and open a Pull Request. Mention what you changed and any notes.

### Credits

Made with ❤️ by Vie2Code
