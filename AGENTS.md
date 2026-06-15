# FrogComposband AI Agent Guide

FrogComposband is a roguelike dungeon crawler (~250+ C source files) based on Angband v7.1. It features 50+ playable classes, monster possessor mechanics, and multi-platform support.

## Quick Start: Build & Run

**First-time setup (recommended):**
```bash
sh autogen.sh
./configure --with-no-install
make clean && make -j4
cp src/frogcomposband .
./frogcomposband -- -n1  # ASCII graphics mode
```

**Key configure options:**
- `--with-no-install`: Build in-place (required for development)
- `--with-private-dirs`: User-local saves (default)
- `SANITIZE_FLAGS=-fsanitize=address` + `CC=clang`: Debug with address sanitizer

**Critical gotcha:** With `--with-no-install`, you must manually `cp src/frogcomposband .` after each build—the executable doesn't auto-copy to the root directory.

## Architecture: The Variant Pattern

**Key Design Principle:** FrogComposband uses a dispatcher pattern for class/race behavior rather than large switch statements scattered throughout the codebase.

**Dispatch entry points:**
- `get_class_aux()` (classes.c): Dispatches to class-specific behavior
- `get_race_aux()`: Similar for races
- `pseudo_class_idx`: Used by Possessor class to inherit monster race behavior

**Pattern advantage:** Adding a new class only requires:
1. Create `newclass.c` with class-specific functions
2. Add entry in `get_class_aux()` dispatcher
3. No changes needed elsewhere in combat/spell code

When debugging class-specific behavior, always trace through `get_class_aux()` to find the responsible handler.

## Code Organization

**Source layout (src/):**
- **Game loop:** `angband.c` (main loop), `cmd1-6.c` (command processing)
- **Classes:** `classes.c` (dispatcher), `alky.c`, `bard.c`, `ninja.c`, etc. (class-specific)
- **Monsters:** `mon*.c` (monster logic), `r_dragon.c`, `r_demon.c`, etc. (race definitions)
- **Combat:** `melee1.c`, `melee2.c`, `combat.c`
- **Spells:** `spells*.c` (organized by school)
- **UI Backends:** `main-gcu.c`, `main-x11.c`, `main-sdl.c`, `main-win.c`
- **Utilities:** `z-*.c` files (term, rand, form, doc)

**Key files:**
- `externs.h`: All global extern declarations
- `defines.h`: Game constants and macros
- `classes.h`, `obj.h`, `mon.h`: Core data structures
- `savefile.c`: Save/load logic (critical for compatibility)

## Development Conventions

**Naming:**
- Types: `_t` suffix (e.g., `player_type`)
- Pointers: `_ptr` suffix
- Structs: `_s` suffix
- Custom types: `s16b` (signed 16-bit), `u32b` (unsigned 32-bit), `byte`

**Practices:**
- Use explicit portable types (`s16b`, `u32b`) instead of `int`
- One concept per file (e.g., `melee1.c` and `melee2.c` split melee logic)
- No bit fields in structs—use full bytes for speed (32-bit optimization legacy)
- Heavy global state via `externs.h` (standard for C roguelikes)

## Critical Pitfalls

1. **In-place build workflow:** Always configure with `--with-no-install` and manually copy the executable after building
2. **Sanitizer configuration:** Pass `SANITIZE_FLAGS=-fsanitize=address` to configure, NOT to CFLAGS
3. **Save file compatibility:** Changes to struct layouts break old save files—check `savefile.c` versioning
4. **Platform detection:** Build system is sophisticated; changes to configure.ac affect multiple platforms
5. **Variant dispatch:** New class/race behavior must be added to `get_class_aux()` or `get_race_aux()` dispatcher

## Documentation

- [readme.txt](readme.txt): Multi-platform build instructions, X11 font troubleshooting
- [src/changes](src/changes): Historical changelog
- [docs/](docs/): Design documents (game planes, balance specs)
- [design/](design/): Balance spreadsheets and combat mechanics

## Development Workflow

**After code changes:**
```bash
make clean && make -j4
cp src/frogcomposband .
./frogcomposband -- -n1
```

**Common tasks:**
- **Adding a class:** Create `src/newclass.c`, add dispatcher entry in `classes.c`
- **Adding a spell:** Create spell in appropriate `spells_*.c`, register in spell table
- **Fixing a bug:** Use ASCII mode (`-- -n1`) for reproducible testing
- **Testing with sanitizers:** Use `ASAN_SYMBOLIZER_PATH=/usr/bin/llvm-symbolizer` when running

## Notes for AI Agents

- This codebase is intentional and well-organized—changes should respect the existing architectural patterns
- The variant dispatcher pattern is the key to understanding class/race behavior
- Manual save file versioning means changes to core types require careful consideration
- The project has ~250+ files with clear domain separation—use that structure when proposing changes
- Platform support complexity is handled in `configure.ac` and `main-*.c`—be careful with platform-specific changes
