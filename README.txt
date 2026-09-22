NextCast 6.0.0 — WoW Forever 1–30
=================================

Standalone. No TellMeWhen. No Action. No license.

Install
  1. Extract NextCast into Interface/AddOns
  2. Enable at character select
  3. /nc  →  Macros  →  CREATE ALL  →  PLACE ON BAR

Healing
  GGLoader clicks ExtraIcon ST and presses that bar key.
  Put the NextCast macro on that slot so the press is
  [@mouseover][@target,help][@player], not the enemy.

  TargetColor is painted twice:
    ExtraIcon child at 737,-12   (Griph reader)
    UIParent TOPLEFT 163,0       (Action reader, global TargetColor)

  MotW / Thorns macros: /cancelform then [@player].
  The addon paints the icon in Bear; it does not dump form.

Buffs (tank MotW)
  Combat: unknown aura = already up (do not dump Bear).
  Out of combat: unknown = missing, recast once, latch 5 min.

Overview
  Specialization only. Role comes from talents and form.

Commands
  /nc            dashboard
  /nc macros     MetaEngine tab
  /nc cd         cooldowns
  /nc aoe        auto / single / aoe
  /nc kick       interrupts
  /nc burst      hold offensive cooldowns
  /nc queue NAME force the next recommendation
  /nc ggl        ExtraIcon + Action TargetColor calibration
  /nc reset      restore this class profile
  /nc log        last recommendations
