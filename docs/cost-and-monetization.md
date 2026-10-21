# StashHive — Cost and Monetization Plan

**Status:** Strategy draft; monetization is not part of the first implementation increment.

## Cost principle

Keep the core library local-first so everyday use does not need a hosted database, user accounts, cloud file storage, a paid AI API, or a scheduled backend. This limits recurring operating cost but does not guarantee that store publishing, domains, legal checks, advertising integration, or all developer tools are free.

## Likely cost areas

| Area | MVP direction | Cost caveat |
|---|---|---|
| Core app runtime | Local storage and on-device operations | No planned per-user server bill, but development/maintenance still takes time. |
| Web delivery | Static hosting candidate such as Cloudflare Pages | Verify current free-tier limits, build settings, bandwidth and cache behavior before launch. |
| Android distribution | Build APK/AAB and test locally first | Publishing through an app store may require a developer account/registration fee and store policy work; verify current requirements at release time. |
| OCR/PDF extraction | Only after offline proof of concept | Large packages may increase app size and maintenance cost even when no API bill exists. |
| Ads | Not in first slice; evaluate after utility testing | Requires network activity, SDK integration, consent/privacy/store-policy review, and enough active users to have meaningful yield. Revenue is not guaranteed. |
| One-time premium unlock | Consider after retention validation | Needs a platform-specific purchase/entitlement strategy; web and Android may differ. It is not assumed to be costless to implement. |
| Cloud sync | Excluded from MVP | Would introduce recurring storage, security, support, and abuse-control costs; requires a separate business decision. |
| Domain/trademark | Verify before public branding | Fees and availability depend on chosen domain/registries/jurisdiction; not included in zero-cost assumptions. |

## Monetization experiment sequence

1. **Validate utility first:** small opt-in testing should show that users repeatedly save and successfully find items.
2. **Measure retention and pain points:** learn whether advanced organization, richer search, backup convenience, or larger local libraries are valued.
3. **Compare light ads vs one-time unlock:** keep the free core useful. Avoid ads inside saved-content detail where they undermine trust or reading.
4. **Obtain separate approval:** evaluate SDK permissions, privacy disclosure, consent, app-store billing policies, web payment choices, and exact costs before adding monetization code.

## What not to assume

- Downloads do not equal active users, and active users do not guarantee ad revenue.
- An app with zero server cost can still have store fees and ongoing maintenance costs.
- A one-time payment may not cover indefinite future development/support.
- The user's saved library must not become ad-targeting data. Never transmit content to an ad provider.
