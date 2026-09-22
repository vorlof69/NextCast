NextCast 5.11.0 — WoW Forever 1–30
=================================

Install
  1. Extract the NextCast folder into Interface/AddOns
  2. Enable NextCast at character select
  3. Type /nc  (or /nextcast)

Settings
  Three tabs. Overview: spec + switches. Abilities: turn a spell off.
  Macros: GGLoader MetaEngine — CREATE ALL then PLACE ON BAR.

Attack
  Bind Attack on the bar GGLoader scans. NextCast pulses it once, then
  hides it (Action's not Player:IsAttacking() gate) so the toggle cannot
  flip off. No extra StartAttack macro.

Heals / buffs (MetaEngine)
  GGLoader clicks the ExtraIcon texture and presses that bar key. If the
  key is the raw spell, heals hit the enemy and MotW never leaves Bear.
  Open /nc → Macros:

    CREATE ALL     writes NC MotW, NC HT, NC FlashHeal, …
    PLACE ON BAR   replaces the matching spell on the scanned bar
                   (needs a click — WoW blocks PlaceAction on login)
    UNIT           cycle smart / @player / @mouseover / @party1–4
                   (Action slots 6–10 are these unit macros)

  MotW / Thorns macros are /cancelform then [@player]. The addon paints
  the icon in Bear; it does not dump form itself. After MotW lands it
  shifts back.

  smart = [@mouseover,help,nodead][@target,help,nodead][@player]

ExtraIcon protocol (no TellMeWhen, no Rubim ExtraIcon addon)
  NextCast draws GriphRotations' ExtraIcon strip itself so an existing
  GGLoader profile already locked to Rubim ExtraIcon just works.

    parent     240x30 at TOPLEFT -29, 12
               scale 0.42666670680046 × (1080 / physical height), unparented
    CC         1×1 cyan flag at offset 0
    Kick       1×1 cyan flag at offset 30 (independent of the rotation icon)
    ST         30×30 at offset 60 — main APL.
               Attack is pulsed once, then Maul / Sinister Strike / etc.
               Held while you are casting or channeling so the reader does not clip.
    AoE        30×30 at offset 90 — AoE spell, or the heal when one is recommended
    Gladiator  30×30 at offset 120 — PvP CC texture
    Passive    30×30 at offset 150 — defensive texture
    TargetColor  1×1 named frame at 737, -12 — Action UC heal-unit color

  Contrast / gamma / nameplate CVars are not changed.

  Calibrate: /nc ggl
    Lights both cyan flags, paints Universal 1–4 on ST/AoE/Glad/Passive, and
    the player heal color on TargetColor so you can lock physical pixels.

Commands
  /nc            dashboard
  /nc macros     MetaEngine tab
  /nc cd         cooldowns
  /nc aoe        cycle auto / single / aoe
  /nc kick       interrupts
  /nc burst      hold offensive cooldowns
  /nc queue NAME force the next recommendation
  /nc preset dps|tank|healer|pvp|auto|reset
  /nc ggl        paint ExtraIcon calibration
  /nc reset      restore this class profile
  /nc log        last recommendations

Universal 1–10
  Use the Abilities tab only when two rotation spells share a texture on ST.
  Kick and CC have their own flags, so they do not need Universal mapping.

All nine classes, three specs, PvE and PvP. Forever spells (Holy Strike,
Penance, Riptide, Mangle, Wrack, Arcane Blast, Ice Lance, Victory Rush)
are name-looked-up and stay silent until learned.