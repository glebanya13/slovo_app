# App Store: privacy and China mainland checklist

## 1. China mainland (Guideline 2.1)

Do one of the following:

- **No Internet Publishing Service License (网络出版服务许可证):** remove China mainland from availability:
  `Pricing and Availability` → `App Availability` → uncheck `China mainland`.
- **Have the license:** attach a valid scan in
  `App Information` → `General Information` → `Publication Availability in China mainland`.
  The developer name must match the licensed entity (单位名称), and the permit must not be expired.

Changing the App Store category does **not** remove the book-content requirement. Apple reviews the actual content (Bible, prayers), not the selected category.

## 2. In-app AI/TTS consent

Before the first AI or text-to-speech request, the app must show an in-app disclosure with:

- **What is sent:** question text, current chat history, selected tradition, prayer occasion/details, verse text, text to be voiced, and technical request metadata.
- **Who receives it:** Google LLC (Gemini API), ElevenLabs, Cloudflare Workers, Firebase (Google).
- **Why:** to generate answers, prayers, explanations and audio; to authenticate and protect the service.
- **How to withdraw:** Settings → Privacy → AI and voiceover.
- **Privacy Policy link.**

The disclosure must be shown before sending data. A toggle with only “Without name and contacts” is not sufficient.

## 3. Privacy Policy

The public policy is at:

`https://davinchi.dev/apps/slovo/privacy.html`

It must be reachable without login and must match the in-app policy. It must describe:

- categories of data collected;
- how data is collected;
- all uses;
- named third parties and what they receive;
- retention and deletion;
- how to withdraw consent;
- international transfers and security;
- children and contact details.

The same text is used in `lib/features/more/legal_screens.dart`.

## 4. App Privacy answers

Update App Store Connect → App Privacy and `ios/Runner/PrivacyInfo.xcprivacy` consistently:

- Contact Info: Name, Email Address — linked, App Functionality.
- Sensitive Info: Religious or Philosophical Beliefs — linked, App Functionality.
- User Content: Other User Content — linked, App Functionality.
- User Content: Audio Data — not linked to identity; declared because iOS speech recognition may process audio off-device.
- Identifiers: User ID, Device ID (FCM token) — linked, App Functionality.
- Diagnostics: Crash Data — App Functionality.
- Tracking: No. No advertising or cross-app tracking.

`ios/Runner/PrivacyInfo.xcprivacy` already contains this set; App Store Connect must use the same answers.

## 5. Providers

- **Google LLC** — Firebase Authentication, Cloud Firestore, Firebase Cloud Messaging, Firebase Crashlytics, Gemini API.
- **Eleven Labs Inc.** — ElevenLabs text-to-speech.
- **Cloudflare, Inc.** — Cloudflare Workers proxy.
- **Apple Inc.** — Sign in with Apple, speech recognition on iOS, App Store.

Use written DPAs / provider terms and confirm the “same or equal protection” statement before publishing it.

### Gemini note

Google's Gemini API terms distinguish paid services from unpaid quota. For paid services, Google does not use prompts or responses to improve its products and processes them under its DPA. If the project uses unpaid quota, either enable Cloud Billing/paid processing or disclose the difference in the policy and obtain consent.

### ElevenLabs note

ElevenLabs retains data by default under its terms. Check whether Zero Retention Mode is available for your plan; otherwise the policy must disclose retention by ElevenLabs.

## 6. Build and reply

1. Increment the build number above the reviewed build.
2. Upload the new build.
3. In App Review Information, add a note describing the AI/TTS data flow and how to test the consent screen.
4. Reply to the review message.

Current project version is `1.0.0+3`, so the next upload is `1.0 (3)` unless build 3 was already uploaded — in that case increment to `1.0.0+4`.

Suggested reply:

> Hello,
>
> Thank you for the review.
>
> 1. We removed China mainland from the app's availability because we do not hold an Internet Publishing Service License (网络出版服务许可证) for this content.
> 2. We added a dedicated in-app consent screen shown before the first AI or text-to-speech request. It explains what data is sent (the question and current chat history, selected Christian tradition, prayer occasion/details, verse text, and the text to be voiced), who receives it (Google LLC — Gemini API, ElevenLabs — text-to-speech, Cloudflare Workers — request proxy, Firebase — account/sync/push), and how consent can be withdrawn. Consent can be withdrawn in Settings.
> 3. We updated the privacy policy at https://davinchi.dev/apps/slovo/privacy.html to describe the data collected, how it is collected, all uses, named third-party recipients, retention, deletion, and withdrawal.
>
> A new build is attached.
>
> Best regards,
> [Name]
