# Как применить обновлённую политику

Песочница Codex не даёт писать в `/Users/gleb/Documents/GitHub/glebanya13/davinchi.dev`, поэтому файлы подготовлены здесь:

- `site-patch/apps/slovo/privacy.html`
- `site-patch/apps/christian-ai/privacy.html`

## Применить

```sh
sh /Users/gleb/Documents/Leonid/slovo-app/site-patch/apply.sh
```

Скрипт копирует оба файла в сайт, сохраняет прежние версии в `/tmp` и печатает `git status`. Деплой не запускает.

## Проверить и задеплоить

```sh
cd /Users/gleb/Documents/GitHub/glebanya13/davinchi.dev
git status --short -- apps/slovo/privacy.html apps/christian-ai/privacy.html
npm run deploy
```

## После деплоя

1. Открыть `https://davinchi.dev/apps/slovo/privacy.html` и проверить, что страница загружается без логина.
2. Убедиться, что в App Store Connect в `Privacy Policy URL` стоит именно `https://davinchi.dev/apps/slovo/privacy.html`.
3. Синхронизировать текст политики в приложении (`lib/features/more/legal_screens.dart`), иначе in-app и website версии будут расходиться.
4. Проверить, что перед первым AI-запросом показывается согласие с перечнем данных и получателей, а не только ссылка на политику.
