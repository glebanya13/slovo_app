# Slovo API proxy (Cloudflare Workers)

Бесплатно, без Firebase Blaze. Ключи Gemini/ElevenLabs живут только здесь.

```bash
npm install
npm run secret:gemini    # вставить ключ
npm run secret:eleven
npm run deploy           # получишь https://slovo-api.<account>.workers.dev
```

В приложении: `--dart-define=API_PROXY_BASE=https://slovo-api.<account>.workers.dev`

В Firebase → Authentication включи **Anonymous**.
