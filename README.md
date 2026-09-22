# NextCast 6.0.0

Forever-native rotation engine for **WoW Forever 1–30**.

**Not TellMeWhen. Not Action. Not a license.** NextCast draws its own ExtraIcon strip and Action TargetColor pixel, recommends every class/spec, and presses through GGLoader without a TMW profile.

## Why this, not Action + TMW

| | Action (Anniversary) | TellMeWhen 12.1.5 | NextCast |
|---|---|---|---|
| Forever `Interface: 16001` | No (Classic 11509) | Yes | Yes |
| Loads without TMW | No (`RequiredDeps`) | — | Yes |
| License / profile server | Premium keys | None | None |
| Classic-only libs | HealComm, Casterino | Rewritten for secrets | Forever `C_UnitAuras` |
| GGL ExtraIcon | Via TMW icons | Host only | Built-in strip |
| Action TargetColor `163,0` | Yes | No | Yes (dual) |
| Next TMW update | Overwrites your API | Breaks Action | Irrelevant |

Action's "Licenses" folder is the addon renamed. Its auth is for **paid GGL profiles**, not Forever compatibility. Bumping the TOC will not make Classic engines survive Midnight secret values. Keep TMW as a cooldown UI if you want — NextCast never talks to it.

## Download

[https://github.com/vorlof69/NextCast/releases/latest](https://github.com/vorlof69/NextCast/releases/latest)

Direct: https://github.com/vorlof69/NextCast/releases/download/v6.0.0/NextCast-6.0.0.zip

1. Extract the folder, rename it to `NextCast` if it has a suffix
2. Put it in `World of Warcraft\_classic_beta_\Interface\AddOns\`
3. `/reload`
4. `/nc` → **Macros** → **CREATE ALL** → **PLACE ON BAR**

## Healing that GGLoader can press

GGLoader cannot retarget. It clicks a pixel and presses a bar key.

1. **TargetColor** paints the ally (Action UC table) at ExtraIcon `737,-12` **and** Action `UIParent 163,0` — either reader works.
2. **ST** paints the heal/buff texture.
3. The scanned bar key must be a **NextCast macro**, not the raw spell:
   - `[@mouseover,help,nodead][@target,help,nodead][@player]`
   - MotW / Thorns: `/cancelform` then `[@player]` — the addon never dumps Bear itself

Open `/nc` → Macros. Click UNIT to pin `@player`, `@party1`–`4`, mouseover, or smart.

## Out of combat buffs (tank MotW)

Forever often secrets auras in Bear. Combat treats unknown as "already up" so we never dump form. **Out of combat unknown is missing** — MotW, Inner Fire, Battle Shout, auras, aspects recast once, then latch (5 min MotW, etc.). Stay in Bear; GGL presses the cancel-form macro.

## Overview

One dropdown: **specialization** (Automatic / Arms / Feral / …). Role is detected from talents and form. No DPS / Tank / Healer / PvP / Reset cards.

## Protocol

```
ExtraIcon  240×30  TOPLEFT −29, 12
  CC flag     1×1   @ 0
  Kick flag   1×1   @ 30
  ST          30×30 @ 60
  AoE/Heal    30×30 @ 90
  Gladiator   30×30 @ 120
  Passive     30×30 @ 150
  TargetColor 1×1   @ 737, −12

Action TargetColor  1×1  UIParent TOPLEFT 163, 0   (global name TargetColor)
```

`/nc ggl` lights both pixels for calibration.

## Commands

`/nc` `/nc macros` `/nc cd` `/nc aoe` `/nc kick` `/nc burst` `/nc queue NAME` `/nc ggl` `/nc reset` `/nc log`
