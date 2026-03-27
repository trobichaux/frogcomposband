# Planes of Existence — Feature Ideas

## Core Concept

Add **spatial nodes** to the overworld — special map tiles or structures that serve as portals to other planes of existence. Each plane is a self-contained world with its own:

- **Wilderness landscape** (terrain, visual theme)
- **Towns** (unique shops, NPCs, quests)
- **Dungeons** (mythology-appropriate monsters and bosses)

Think of it as expanding the current single-overworld model into a multiverse: the current world is the "mortal plane," and spatial nodes are one-way (or two-way) gates to mythological realms.

---

## Candidate Planes

### Yomi (Japanese Shinto)
- The polluted underworld where Izanami rules after her death
- Dark, damp, decaying aesthetic — contrasts with the existing Heaven dungeon
- Monsters: Oni, Tengu, Yurei (ghosts), Kappa, Shikigami
- Suggested depth range: ~55–70

### Diyu (Chinese Buddhist/Taoist)
- The bureaucratic Chinese underworld with ten courts of judgment
- Distinctive flavor: lawful-evil undead officials as dungeon lords
- Monsters: Jiangshi (hopping vampires), demon-magistrates, hungry ghosts
- Suggested depth range: ~60–80

### Xibalba (Maya)
- The Maya underworld ruled by twelve Death Lords
- Naturally tiered dungeon structure (each lord = a trial)
- Monsters: skeletal lords, jaguars, bats, feathered serpents
- Suggested depth range: ~70–85
- Only Mesoamerican content in the game

### Tír na nÓg / The Otherworld (Celtic/Irish)
- The Irish mythological realm of the Tuatha Dé Danann
- Radiant, dangerous faerie land — not grim, but perilous
- Enter via Sidhe (fairy mounds) scattered on the overworld
- Monsters: the Morrigan, Fomorians, banshees, selkies, warrior-heroes
- Suggested depth range: ~45–65

---

## Open Design Questions

1. **One-way or two-way portals?** Can the player return to the mortal plane freely, or only via special exit tiles?
2. **Discovery mechanic?** Are nodes visible on the map, or do they require quests/items to reveal?
3. **Plane-specific rules?** Should each plane modify game rules (e.g., Diyu disables resurrection, Yomi drains light sources)?
4. **Town integration?** Do planes have their own Recall points, or does Recall always return to the mortal plane?
5. **Sequencing?** Should planes be end-game content (like Hell/Heaven) or accessible mid-game?
6. **Monster flags?** Each plane would need new monster race flags (e.g., `JAPANESE`, `CHINESE`, `MAYAN`, `CELTIC`) similar to existing `NORSE`, `EGYPTIAN`, `HINDU`, `OLYMPIAN`.

---

## Existing Mythology Gaps (for reference)

Current coverage in d_info.txt:
| Present | Absent |
|---|---|
| Tolkien, Greek, Norse | Chinese |
| Egyptian, Hindu | Japanese |
| Judeo-Christian | Mesoamerican (Aztec/Maya) |
| Lovecraftian | Celtic/Irish |
| Arthurian, Literary (Oz) | Mesopotamian |

---

## Related Files to Study Before Implementation

- `lib/edit/d_info.txt` — dungeon definitions
- `lib/edit/w_info.txt` — overworld/wilderness layout
- `lib/edit/r_info.txt` — monster race definitions (flags like `NORSE`, `HINDU`)
- `src/defines.h` — dungeon index constants (`DUNGEON_*`)
- `src/wilderness.c` — overworld generation and movement
- `src/generate.c` — dungeon level generation
