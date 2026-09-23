# EXAM PULSE — Flutter Student App v3

Flutter frontend **only**. For backend handoff read [API_CONTRACT.md](API_CONTRACT.md) first. This revision fixes the earlier confusing 36% overall ring, adds full student details at registration, separate login after registering, account-specific local study libraries, an actual in-app PDF reader and unique-per-day marked-as-studied page progress. It retains AI assessments, voice analysis, spoken or typed follow-ups and revisions as real API integration points, **not fake offline AI**.

## Prerequisites

- Flutter **3.29+**, Dart matching the Flutter SDK; Android Studio or VS Code with Flutter extensions. `pdfx 2.11.0` requires Flutter 3.29+.
- Android or iOS for the complete offline document and microphone flow.
- Node.js backend implementing [API_CONTRACT.md](API_CONTRACT.md) for true personalised AI.

## Run it

```bash
# after extracting ZIP, from the exam_pulse_flutter folder
flutter create . --platforms=android,ios
flutter pub get
flutter analyze
flutter test
flutter run
```

**Demo is enabled by default** so the UI can be explored without a backend. Register a student with name, class/course, year, branch, email, and password. Registration switches to Login; sign in, upload **your own** PDF and tap it to read. The app retains student accounts, metadata and documents locally on the device. The demo uses `shared_preferences` and a SHA-256 password digest *for convenience only*; this is not a secure production authentication system. Do not use real student passwords or sensitive notes for classroom demos on shared phones. Demo files are app-private, **not uploaded to a server**. Uninstalling the app deletes local storage. The sample account `student@exampulse.app` / `Demo@123` starts with **no** preloaded materials.

**Test the AI using the actual Node.js backend:**

```bash
flutter run --dart-define=EXAM_PULSE_DEMO=false --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

`10.0.2.2` reaches your computer's localhost from the *Android emulator*, **not** from a physical phone. Use your computer's LAN IP if testing on a phone. Use HTTPS for real deployment, and configure Android development-only cleartext permissions if testing over HTTP. On iOS add a development App Transport Security exception only for the local test server; don't loosen release builds.

## Requested user flows

**New student:** registration → success → login → personal home (empty library) → uploads PDF + names the topic → opens PDF using an embedded pinch-zoom reader → marks each studied page → home shows `Today • Topic name: pages marked studied today / PDF pages × 100`. Example: if 4 of 20 pages have been marked studied today, the home topic card says **20%**. This measures **pages you explicitly marked studied today**, *not comprehension*, quiz marks, cumulative mastery or “36% overall complete.” Only tapping **Mark page as studied** changes progress; scrolling alone does not. Marks are deduplicated on reopening; the daily set resets on the next date. Plain-text notes have one study unit and are counted only when **I studied this note today** is tapped. A PDF’s denominator is shown only after opening the PDF. Each topic has its own progress bar.

**Personalisation:** never prepopulate actual student libraries with another stream's subject. Each user uploads their own content; branch/class/year appear in their profile and are sent to Node on registration. Backend builds questions and revision suggestions from that student's content. Offline demo lets students *read their own files*, practise a clearly-labelled optional example quiz, and explore the UI, but it does **not** invent AI questions from arbitrary uploaded PDFs.

**AI learning loop after backend integration:** upload → extract material → generate assessment/flashcards → take topic quiz/mock test → view graded explanations → update weak concepts and schedule retest → view due revisions → record spoken explanation → receive transcript, estimated analysis and follow-up → answer by voice or text. On slower processing, tap Refresh in Library. Do not present AI or push notifications as functional in offline demo.

## Permissions

After `flutter create`, add Android mic permission inside `<manifest>` in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

In `ios/Runner/Info.plist` add:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>EXAM PULSE records spoken study explanations only when you choose to record.</string>
```

For PDF support on web, if you choose to build a web target later, follow pdfx setup (`dart run pdfx:install_web`) and implement browser-compatible demo file storage; the supplied offline file persistence is intended for Android/iOS. Android/iOS PDF reading works using bytes selected by FilePicker and saved in app documents. Supported uploads: PDF, TXT, MD (20 MiB maximum); DOCX is intentionally not advertised because in-app DOCX preview is not implemented.

## What is real / not real

| Feature | Offline demo | Connected Node.js |
|---|---|---|
| Registration → login → personal library | Locally persisted per account | Authenticated server endpoints |
| Open PDF/TXT/MD and today % per topic | Yes | Yes, with authenticated file download and study-unit sync |
| Practice MCQ + grading | Optional, clearly-labelled fixed example questions | Real questions from that student's material |
| AI document processing / generated flashcards | Not available | Requires your AI pipeline |
| Voice recording + follow-up UI | UI visible, analysis disabled | Real transcribe/analyse/follow-up endpoints |
| Weak-topic revision plan | Empty local list unless server integrated | Requires backend generation and scheduling |
| Remote/push motivational reminders | Not available | Requires additional notification integration |

## Source layout

- `lib/main.dart`: Material theme, demo/live switch.
- `lib/data/models.dart`: typed API models (StudentProfile, Topic, StudyMaterial, etc.).
- `lib/data/repository.dart`: `StudyRepository` abstraction, Node HTTP implementation, isolated persistent demo implementation.
- `lib/state/app_controller.dart`: loading states, authentication and study-unit event serialization.
- `lib/ui/screens.dart`: registration, login, home, personal library, practice, revision and progress.
- `lib/ui/material_reader.dart`: PDF viewer and TXT/MD reader with topic progress.
- `lib/ui/practice_flow.dart`: quiz, result, flashcard and voice explanation/follow-up screens.
- `test/`: parser, demo auth and topic-progress tests.

Run `flutter analyze` and `flutter test` **locally** before presenting a verified Android/iOS build. This environment could not run a Flutter SDK build, so full-device performance, permission prompts, and PDF decoding should be checked on your test phone.
