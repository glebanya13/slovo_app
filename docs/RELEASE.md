# Релиз «Слово»

Blaze **не нужен**. AI-прокси — бесплатный Cloudflare Worker. Firebase остаётся на Spark (Auth, Firestore, Crashlytics, Messaging).

## Блокеры в коде

1. **AI-ключи** — в релизе только через Cloudflare Worker (`proxy/`).
2. **Android signing** — `android/key.properties` + keystore (не в git).
3. **iOS push** — Release/Profile: `production`.
4. **aiConsent** — без согласия AI/озвучка недоступны.
5. **Crashlytics** + **PrivacyInfo.xcprivacy**.

## Прокси без Blaze (Cloudflare)

```bash
cd proxy
npm install

# секреты (вставить значения из secrets.json)
npm run secret:gemini
npm run secret:eleven

npm run deploy
```

Wrangler выведет URL вида `https://slovo-api.<account>.workers.dev`.

Добавь в `secrets.json` (для debug) или в CI release-define:

```json
"API_PROXY_BASE": "https://slovo-api.<account>.workers.dev"
```

В Firebase Console → Authentication → Sign-in method → включи **Anonymous**.

## Локальная разработка

С ключами в клиенте (как раньше):

```bash
flutter run --dart-define-from-file=secrets.json
```

Или через уже задеплоенный proxy — в `secrets.json` только `API_PROXY_BASE`, без `GEMINI_*` / `ELEVENLABS_*`.

## Release (ключи не в бинарнике)

```bash
flutter build appbundle --release \
  --dart-define=API_PROXY_BASE=https://slovo-api.<account>.workers.dev

flutter build ipa --release \
  --dart-define=API_PROXY_BASE=https://slovo-api.<account>.workers.dev
```

**Не** передавай `GEMINI_API_KEY` / `ELEVENLABS_API_KEY` в release.

## Сторы

- Play: AAB с upload-keystore, Data safety
- App Store: Archive (production push), APNs key в Firebase, privacy labels
