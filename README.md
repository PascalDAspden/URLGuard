# URLGuard — Version 1

A complete native Swift/SwiftUI iPhone app for **offline, deterministic URL-string analysis**. Paste or type a link, check it, read the hostname and scoring explanations, and optionally keep local history.

**URLGuard is an educational heuristic URL analysis tool. It is not a replacement for professional threat intelligence or browser security systems. A low score does not guarantee safety, and a high score does not prove maliciousness.**

## Start here

1. Clone this repository, or choose **Code → Download ZIP** on GitHub and extract it to your Mac. Keep all folders together.
2. Open **URLGuard.xcodeproj** in Xcode. You do not need to create a new Xcode project.
3. Select the **URLGuard** scheme in the top toolbar.
4. Select an installed **iPhone Simulator** as the run destination.
5. Press **⌘R** to build and run.
6. Type `example.com` and tap **Check URL**. It becomes `https://example.com`, with a note explaining that HTTPS was assumed and was not verified.
7. Press **⌘U** to build and run the unit tests.

Requirements: a Mac, Xcode 15 or later with an iOS Simulator runtime, and iOS 17 or later. Use an Xcode version that supports your iPhone's installed iOS version. No npm, CocoaPods, Swift packages, API keys, backend, or paid service is needed. An Apple Account is needed only for signing a build onto a physical iPhone, not for Simulator use.

## Features included

- Home screen with URL field, the native system Paste control, Clear, and Check URL.
- Low / Medium / High heuristic score with all contributions and passed checks.
- Prominent actual hostname, original input and normalised URL; scanned links are plain text and cannot be tapped open.
- All 13 analysis rules listed below, including IPv4 and IPv6.
- Practical advice, Learn and Privacy pages.
- Optional local history, off by default, with per-scan swipe deletion and confirmed clear-all.
- Dark/light appearance, Dynamic Type, system colours and SF Symbols, original app icon.
- A shared Xcode scheme and 26 XCTest methods for analysis and history.
- Complete source on GitHub: https://github.com/PascalDAspden/URLGuard

**Version 1 does not open analysed links, create a WebView, contact domains, resolve DNS, expand shortened URLs, request threat intelligence, use AI, send history, or implement a Share Extension.**

## Running on the Simulator

Choose an iPhone Simulator from the destination menu next to the scheme. If none is installed, install an iOS runtime from **Xcode → Settings → Components/Platforms** (the label varies by Xcode version), then select or create an iPhone Simulator. Run with ⌘R.

The Simulator is enough to edit and test the whole app. History is stored separately in each Simulator's app container. Deleting the Simulator app removes its stored history.

You can also run from Terminal inside this project folder:

```sh
xcodebuild -list -project URLGuard.xcodeproj
xcrun simctl list devices available
```

Copy the UDID of an installed iPhone Simulator from that list, then substitute it below:

```sh
xcodebuild -project URLGuard.xcodeproj -scheme URLGuard \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID' \
  CODE_SIGNING_ALLOWED=NO build

xcodebuild -project URLGuard.xcodeproj -scheme URLGuard \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID' \
  CODE_SIGNING_ALLOWED=NO test
```

The `YOUR_SIMULATOR_UDID` text is an instruction to substitute your own device ID, not application code.

## Running on your iPhone

1. Connect and unlock the iPhone. Accept **Trust This Computer** if prompted.
2. In Xcode Settings, sign into your Apple Account under **Apple Accounts/Accounts**.
3. Select the blue URLGuard project in the navigator, then the **URLGuard app target → Signing & Capabilities**.
4. Leave **Automatically manage signing** on and select your **Personal Team** or development team.
5. If Xcode says the bundle identifier is unavailable, change `nz.pascal.URLGuard` to a unique value, for example `nz.yourname.URLGuard`. The test target's identifier can be changed similarly. There are no matching app-group entitlements to update.
6. Select your connected iPhone as the run destination.
7. If requested, enable **Settings → Privacy & Security → Developer Mode** on the iPhone, restart, and confirm.
8. Press **⌘R**. Xcode will build, sign, install and launch the app.
9. If iOS reports an untrusted developer certificate, use **Settings → General → VPN & Device Management** to trust your developer profile, then run again.

A Personal Team can be used for development; its signing/provisioning has limitations and builds may need reinstallation through Xcode. You do not need a paid API or the Apple Developer app on the iPhone. This ZIP is source code, not a pre-signed IPA or an App Store release.

Apple's setup references:

- https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices
- https://help.apple.com/xcode/mac/current/en.lproj/dev60b6fbbc7.html

## Project structure and major files

```text
URLGuard/
├── URLGuard.xcodeproj/
│   ├── project.pbxproj
│   └── xcshareddata/xcschemes/URLGuard.xcscheme
├── URLGuard/
│   ├── URLGuardApp.swift
│   ├── Models/ScanResult.swift
│   ├── Services/
│   │   ├── URLAnalyzer.swift
│   │   └── HistoryStore.swift
│   ├── Utilities/URLRules.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── HomeView.swift
│   │   ├── ResultView.swift
│   │   ├── HistoryView.swift
│   │   ├── LearnView.swift
│   │   ├── PrivacyView.swift
│   │   └── Components.swift
│   ├── Assets.xcassets/
│   └── PrivacyInfo.xcprivacy
├── URLGuardTests/
│   ├── URLAnalyzerTests.swift
│   └── HistoryStoreTests.swift
├── README.md
└── VALIDATION.md
```

| File | Purpose / where to edit |
| --- | --- |
| `URLGuardApp.swift` | App entry point; owns one shared history store. |
| `ScanResult.swift` | Codable structured result, levels, signals, severity and passed checks. Scores are saved with the scan, not silently recomputed when history is opened. |
| `URLRules.swift` | Edit weights, threshold values, keywords and shortener list here. |
| `URLAnalyzer.swift` | Validates and normalises input, applies deterministic checks and returns a structured result. Foundation plus the system IP parser; no network calls. `URLAnalyzing` is the small service interface. |
| `HistoryStore.swift` | Opt-in JSON persistence inside Application Support, newest first, max 100 records. Uses atomic protected-file writes; excludes the directory from device backup. Handles unreadable history and write failures. |
| `ContentView.swift` | Four tabs and navigation stacks. |
| `HomeView.swift` | Input, explicit user-initiated paste, clear, validation messages and check action. |
| `ResultView.swift` | Large risk card, hostname, plain-text URLs, signals, passed checks and advice. |
| `HistoryView.swift` | Toggle saving, view earlier results, swipe-delete and clear-all confirmation. |
| `LearnView.swift` | Concise explanations and visible weights. |
| `PrivacyView.swift` | Local-analysis and history privacy information. |
| `Components.swift` | Shared rounded card, non-clickable URL text, risk presentation and advice. |
| `PrivacyInfo.xcprivacy` | No tracking or collected data; declares app-private UserDefaults use. |
| `URLAnalyzerTests.swift` | Analysis, invalid input, score, normalisation and boundary tests. |
| `HistoryStoreTests.swift` | Opt-in, persistence, cap, deletion, corruption and write-failure tests in isolated temporary storage. |
| `project.pbxproj` / shared scheme | Complete app and hosted unit-test targets with source/resource membership and Simulator test configuration. |

## Transparent scoring

Every rule contributes at most once per scan. Keywords collectively contribute **one point maximum**, even when several match. The sum is capped at **10** for display. The uncapped sum and each contribution are visible in the result.

| Rule | Trigger | Points |
| --- | --- | ---: |
| HTTP | `http` scheme | 1 |
| IP address | Standard IPv4 or IPv6 hostname, including local/private addresses | 3 |
| Known shortener | Exact listed host, or its subdomain; not a lookalike suffix | 2 |
| Punycode | Any hostname label starts with `xn--` | 2 |
| Several subdomains | At least 5 hostname labels; IP addresses excluded | 1 |
| Long URL | More than 200 input URL characters after outer whitespace removal | 1 |
| Many hyphens | At least 3 hyphens across the hostname | 1 |
| Sensitive-action keywords | Any listed whole word in the once-decoded URL, including query values | 1 total |
| Non-standard port | Explicit port differs from 80 for HTTP or 443 for HTTPS | 1 |
| Percent encoding | At least 5 valid `%HH` sequences in the input URL | 1 |
| Large query | More than 8 nonempty `&`-separated parameters, or over 300 encoded query characters | 1 |
| `@` character | Literal `@` anywhere in the input URL | 2 |
| Unusual formatting | Internal whitespace, or once-decoded controls / common Unicode direction controls | 1 |

Levels: **0–2 Low Risk**, **3–5 Medium Risk**, **6–10 High Risk**. No individual rule can produce High Risk. Several independent matches are required. These weights are teaching choices, not statistically calibrated estimates.

In `URLRules.swift`, edit weights and thresholds. In `ScanResult.swift`, edit `RiskLevel.init(score:)` if you want different bands; also update the displayed bands in ResultView/LearnView and this README. Add a new signal in the analyzer with a stable rule ID and corresponding unit tests.

### Input and hostname handling

- Outer whitespace is trimmed. Missing scheme means HTTPS is assumed, with a visible note.
- Only HTTP and HTTPS are accepted. Bare `hello`, unsupported schemes, missing hosts, invalid domain labels, malformed percent escapes, invalid ports, literal control characters and backslashes are rejected.
- Legitimate spaces in a path are normalised by Foundation and receive a formatting warning.
- Standard IPv4 and IPv6 use `inet_pton`, a local system parser. No DNS lookup is performed. Ambiguous shorthand numeric hosts and IPv6 zone identifiers are intentionally not supported.
- International hostnames use Foundation's URL/IDNA normalisation and display their ASCII hostname.
- A terminal domain dot is removed in the separate hostname display; the normalised full URL still follows Foundation's representation.
- The app shows the **full parsed hostname**, not a guessed organisation or registered domain. It does not use a Public Suffix List. The 5-label rule is an approximation and may flag legitimate hosts, including some multi-label suffixes.
- URL input is limited to 32,768 characters to keep local analysis responsive.
- Normalisation is parsing, not verification. Even an invented but syntactically valid domain can be analysed. No claim is made that it exists.

### Example results

Examples below are plain text; no website is opened by analysis.

| Input | Expected score | Level |
| --- | ---: | --- |
| `https://www.example.com` | 0 | Low |
| `example.com` | 0 | Low (HTTPS assumed) |
| `http://www.example.com` | 1 | Low |
| `http://192.0.2.1/login` | 5 | Medium |
| `https://account-login-verification.example.xyz/verify` | 1 | Low (keyword only; two hyphens below threshold) |
| `https://paypal.login.security.verify.example.com/account` | 2 | Low (hostname depth + keyword) |
| `https://secure-paypal-login-account-verification.example.com/verify` | 2 | Low (hyphens + keyword) |
| `http://192.0.2.1:8080/login` | 6 | High |
| `https://xn--bcher-kva.example/` | 2 | Low |
| `https://trusted.example@destination.example.com/account` | 3 | Medium; destination is `destination.example.com` |

The provided “suspicious-looking” domain examples can still score Low under this intentionally conservative system. That is expected: weak keywords and hyphens alone should not label a link High Risk. Likewise an IP address may be a legitimate router or test server. The examples test characteristics, not ground-truth phishing labels.

## Tests and manual checks

Run **Product → Test** or **⌘U** with an iPhone Simulator selected. Tests use local strings and temporary files; they never visit the example hosts or URL-shortening services.

Before using on a phone, check:

1. Normal HTTPS, bare domain normalisation, `hello` error and the example IP URL.
2. Paste and Clear. No clipboard read occurs before a paste action.
3. Several `@` examples: actual host must show the destination, not the user-information text.
4. History starts off; enable, scan, relaunch, view, swipe-delete, turn off and clear.
5. Light/dark appearance, larger text sizes, VoiceOver and landscape.
6. Airplane mode: all four tabs and URL analysis must still work.

See `VALIDATION.md` for the exact checks performed during project generation and the checks that still require Xcode.

## Simple Git workflow

Clone the project to keep Git history and easily pull future updates:

```sh
git clone https://github.com/PascalDAspden/URLGuard.git
cd URLGuard
open URLGuard.xcodeproj
```

A GitHub Download ZIP contains source files but does not contain Git history. Cloning is the simplest option for editing and pushing updates.

Set your own author identity before committing changes:

```sh
git config user.name "Your Name"
git config user.email "your-github-email@example.com"
```

After changing a rule or screen and running the tests:

```sh
git diff
git add URLGuard URLGuardTests README.md
git commit -m "Describe the change"
git push
```

Before starting another edit session, use `git pull --ff-only` to get committed updates. Authenticate using your normal GitHub flow. Xcode user settings and build output are ignored.

## Adding Safari Share → URLGuard later

A Share Extension is deliberately deferred to keep Version 1 a single app target with simple signing and no app-group setup. **URLGuard will not appear in Safari's share sheet yet.** Users can copy a URL and tap Paste now.

The analyzer and its models already have no UI dependency. When adding this feature:

1. In Xcode, add a **Share Extension** target, signed with the same development team.
2. Add `ScanResult.swift`, `URLRules.swift` and `URLAnalyzer.swift` to that target's membership. Keep HistoryStore and the main app's views out initially.
3. Configure the extension activation rule to accept one web URL; optionally accept text separately. Do not ship a blanket `TRUEPREDICATE` activation rule.
4. Read the incoming `NSItemProvider` URL/text from `NSExtensionContext` only after the user chooses the extension. Feed it to `URLAnalyzer.analyze(_:)`.
5. Present a small native extension result UI with the same risk disclaimer, without opening the website, then call `completeRequest` when done.
6. Keep extension history separate initially. Shared history would require an App Group container and capabilities on both targets. Check capability availability for your signing account before adding it.

This plan does not rely on forcing the containing app open, which is restricted for Share Extensions. A result can be shown inside the extension itself.

## Future extension points — not implemented

Version 1 uses `URLAnalyzing` and structured `ScanResult` / `DetectedSignal` values. A future feature can consume the same normalised URL without changing the screens' core data format. Keep local checks usable independently.

- Threat intelligence (VirusTotal, Safe Browsing): add a separate **opt-in** network service and a distinct reputation result. Do not silently turn the local heuristic into a live verdict. API terms, keys and cost would need review.
- DNS, domain age, redirects and certificates: separate network services with user consent; may contact infrastructure or destinations. Missing data must remain unknown, not safe.
- AI explanations: optional explanation service that consumes existing findings, without changing deterministic Version 1 results.
- QR and screenshot scanning: new input views feeding extracted strings into the same analyzer; request camera/photos access only when implemented.
- Safari extension: separate target; reuse the analyzer with platform-specific input handling.

No future provider is stubbed, called or required in this project.
