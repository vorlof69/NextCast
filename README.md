# NextCast 5.11.0

All-class recommendation engine for **WoW Forever 1–30**. Griph ExtraIcon / GGLoader protocol.

## Download

[https://github.com/vorlof69/NextCast/releases/latest](https://github.com/vorlof69/NextCast/releases/latest)

Direct zip: https://github.com/vorlof69/NextCast/releases/download/v5.11.0/NextCast-5.11.0.zip

1. Extract the folder
2. Rename it to `NextCast` if it has a suffix
3. Put it in `World of Warcraft\_classic_beta_\Interface\AddOns\`
4. `/reload`
5. `/nc` → **Macros** → **CREATE ALL** → **PLACE ON BAR**

Healing and MotW work because GGL presses the **macro** on the scanned bar, not the raw spell. Click UNIT to assign `@player`, `@party1`–`@party4`, `@mouseover`, or smart (Action MetaEngine slots 6–10). MotW is `/cancelform` then `[@player]` — the addon never dumps Bear itself.

Overview is spec only. Role is detected from talents and form.