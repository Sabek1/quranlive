# QuranLive

QuranLive is a Flutter app for reading the Quran, listening to recitations, tracking prayer times, and exploring Islamic content.

## Features
- Quran surah list with favorites
- Surah audio playback
- Mushaf page with Arabic verses
- Reciters and radio playback
- Prayer times by city or location
- Live TV channels
- Settings and dark/light theme
- AI assistant integration with `QURANLIVE_AI_ENDPOINT`

## Getting started

1. Install Flutter SDK.
2. Run:
   ```bash
   flutter pub get
   flutter run
   ```
3. Optional AI assistant:
   ```bash
   flutter run --dart-define=QURANLIVE_AI_ENDPOINT=https://your-api.example
   ```

## Notes
- This project uses several online APIs; some services may require internet access.
- The AI assistant is optional and uses an external endpoint.
