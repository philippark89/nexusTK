# NexusTK; Project Jumong

A private MMO game server for the **NexusTK 750** Windows client, forked from [RTK-Server](https://github.com/unkmc/RTK-Server) by [unkmc](https://github.com/unkmc).

Three cooperating C servers (login, char, map) backed by MySQL, with Lua scripts driving game logic.

> Primarily developed and maintained with [Claude Code](https://claude.ai/code) by Anthropic.

---

## Running Environment

- **Host OS:** Linux (tested on Ubuntu 22.04 / WSL2)
- **Container runtime:** Docker + Docker Compose
- **Game server OS:** `ubuntu:22.04` (inside container)
- **Client:** NexusTK 750 (Windows)
- **Architecture:** x86-64

---

## Requirements

| Dependency | Version | Notes |
|------------|---------|-------|
| Docker | 20.10+ | Container runtime |
| Docker Compose | v2+ | `docker compose` (no hyphen) |
| MySQL | 8.0 (via Docker) | Managed by compose, no host install needed |
| NexusTK client | 750 | Windows only |

C build dependencies (inside container, installed automatically):
- `build-essential`, `make`
- `libmysqlclient-dev`
- `lua5.1`, `liblua5.1-dev`
- `zlib1g-dev`
- `libpthread-stubs0-dev`

---

## Quick Start

```bash
# 1. Start game server + MySQL
docker compose up -d

# 2. Run database migrations (first run, or after adding new scripts)
./database/migrate.sh

# 3. Rebuild after C source changes
docker compose build rtk-server && docker compose up -d
```

**Ports:**

| Server | Port |
|--------|------|
| Login  | 2000 |
| Map    | 2001 |
| Char   | 2005 |
| MySQL  | 3306 |

MySQL credentials: user `rtk`, password `changeMe`, database `RTK`.

---

## Client Setup (Windows)

The NexusTK client is **not included** in this repository. Download it from the archive:

> [https://archive.org/download/NexusTKKruSetups](https://archive.org/download/NexusTKKruSetups)

Use the **750** installer. The official client ships pointing at Nexon/KRU servers, so it must be patched to connect to `127.0.0.1` instead — this requires a hex editor such as [HxD](https://mh-nexus.de/en/hxd/) to modify the binary. The patch bypass and hosts-file redirect are also required.

1. Patch the client binary to redirect server connections to `127.0.0.1`
2. Add the following entries to your hosts file (`C:\Windows\System32\drivers\etc\hosts`):
   ```
   127.0.0.1 files.kru.com
   127.0.0.1 *.kru.com
   ```
3. The included `patcher.exe` is a no-op stub — it skips the patch server entirely
4. Run `nexusTK.exe`

**Note:** On first map load the screen is black — press any arrow key to trigger tile data. This is by design in the walk protocol.

---

## Project Structure

```
nexusTK/
├── src/
│   ├── src/
│   │   ├── login/          # Login server (auth, server list)
│   │   ├── char/           # Char server (character persistence, inventory)
│   │   ├── map/            # Map server (game world, NPCs, combat, Lua)
│   │   ├── common/         # Shared: sockets, MySQL, timers, crypto, memory
│   │   ├── metan/          # Map metadata generator tool
│   │   └── decrypt/        # Packet decryption utility
│   ├── conf/
│   │   ├── inter.conf      # Inter-server IPs/ports
│   │   ├── login.conf      # Login server config (version must match client)
│   │   ├── char.conf       # Char server config
│   │   ├── map.conf        # Map server config (map_ip, loginip)
│   │   ├── battle.conf     # Combat balance tuning
│   │   └── script.conf     # Lua engine settings
│   └── Makefile
├── lua/
│   ├── Accepted/           # Live scripts loaded by the server
│   │   ├── player.lua      # Player stats, progression, core mechanics
│   │   ├── speech.lua      # NPC dialogue system
│   │   ├── crafting.lua    # Crafting recipes and item creation
│   │   ├── config.lua      # Global Lua config
│   │   ├── startup.lua     # Server startup init
│   │   ├── ntkSystem.lua   # Core game systems
│   │   └── Quests/         # Quest tracker and hooks
│   └── Developers/         # Work-in-progress scripts (not loaded)
├── maps/
│   ├── Accepted/           # Binary .map files for the game world
│   └── warps.txt           # Warp point connections between maps
├── database/
│   ├── scripts/            # Timestamped SQL migrations (run in order)
│   ├── scripts_dev/        # Dev-only SQL (not run automatically)
│   ├── history/            # Automated backup dumps (72-hour retention)
│   ├── migrate.sh          # Run all pending migrations
│   └── backup.sh           # Full DB dump (runs every 5 min via cron)
├── client/                 # NexusTK 750 Windows client files
├── Dockerfile
└── docker-compose.yml
```

---

## Build Commands

```bash
# Inside the container or a matching Ubuntu 22.04 environment:
cd src && make all      # build all three servers + tools

make login              # login server only
make char               # char server only
make map                # map server only
make metan              # map metadata tool
make decrypt            # packet decryption utility
make clean              # remove all build artifacts
```

---

## Database

Migrations live in `database/scripts/` as timestamped SQL files and run in filename order:

```bash
./database/migrate.sh   # applies any unapplied scripts
```

Automated 5-minute backups are wired into the container via cron and written to `database/history/`, keeping the latest 72 dumps (6 hours).

---

## GM Account

```bash
# After creating a character in-game, promote it via MySQL:
docker exec -it jumong-mysql-1 mysql -u rtk -pchangeMe RTK \
  -e "UPDATE \`Character\` SET ChaGMLevel=99 WHERE ChaName='YourCharName';"
```

Useful GM commands (spoken in-game chat):

| Command | Effect |
|---------|--------|
| `/item <id>` | Spawn item |
| `/heal` | Full heal |
| `/immortality` | Toggle invincibility |
| `/warp <map>` | Teleport |
| `/givespell <id>` | Grant spell |
| `/rl` | Reload Lua scripts |
| `/lua <code>` | Execute Lua inline |
| `/bc <msg>` | Broadcast message |
| `/who` | List online players |
| `/job <id>` | Change class |
| `/reloadItem` | Reload item metadata |
| `/metan` | Reload map metadata |

---

## WIP / Roadmap

### Infrastructure
- [x] Port to Ubuntu 22.04 (from i386/Ubuntu 16.04)
- [x] Docker + Docker Compose setup
- [x] MySQL persistent volume
- [x] Database migration workflow
- [x] Automated 5-minute DB backups via cron in container
- [x] Supervisord managing all three servers
- [x] SIGTERM flush on shutdown
- [ ] Health check endpoint / auto-restart on crash
- [ ] Docker image published to a registry for easy deployment
- [ ] TLS/encrypted inter-server communication

### Stability / Crash Fixes
- [x] Stack overflow in `char_db.c` (3 MB stack-allocated struct)
- [x] `mapif.c` RFIFOL offset off-by-one → corrupt `uncompress()` length
- [x] `map_foreachinblockva` double `va_list` consumption → SIGSEGV
- [x] OOM at startup — lazy-allocate map registry arrays
- [x] `map_data.mapfile` over-allocated (1024 → 64 bytes per map)
- [x] MySQL connection drop during map load (~270s) — keepalive pings
- [x] First walk SIGSEGV — inverted null check in `clif_parsewalk`
- [x] `magic.c` null deref on uninitialized spell slot (id ≤ 0)
- [x] NPC click SIGSEGV — missing `pc_readglobalregstring` declaration causing pointer truncation on x86-64
- [x] 102 null-dereference crashes in `clif.c` send functions
- [x] `mob_handle_sub` crash — `bll_pushinst` passed NULL `USER*` to Lua as non-nil userdata → SIGSEGV on field access
- [x] Shift+F1 SIGSEGV — `map_name2npc` missing declaration in `map.h`; compiler assumed `int` return, truncating 64-bit pointer to 32 bits
- [x] Player self-targeting SIGSEGV — `recipedb.h` used `_CLASSDB_H_` as its include guard, shadowing `class_db.h` in `sl.c`; `classdb_name` treated as `int` return causing 64-bit pointer truncation
- [x] "Broken map name" — not reproducible; map name displays correctly
- [x] Black screen on first map load — resolved with new char spawn flow

### Gameplay & Content
- [x] NPC click → Lua dialog menus (deposit/withdraw, option menus)
- [x] NexusTK 750 client connecting and authenticated
- [x] Character creation and login working
- [x] Player movement working
- [x] Player self-targeting / character info panel (S key, click self)
- [ ] Mob spawning and basic combat
- [ ] Item system end-to-end (pickup, equip, use)
- [ ] Quest system testing
- [ ] Crafting system testing
- [x] More NPC dialogue content (Shift+F1 GM/system menu working)

### Developer Experience
- [x] SIGSEGV handler with C backtrace to stderr
- [x] Lua error logging (`sl_err_print` enabled)
- [ ] Structured logging (replace fprintf to stdout/stderr with log levels)
- [ ] Hot-reload Lua scripts without server restart (partial: `/rl` GM command exists)
- [ ] Admin web UI for player/character management
- [ ] CI pipeline (build + migration smoke test)

---

## Credits

Forked from [RTK-Server](https://github.com/unkmc/RTK-Server) by [unkmc](https://github.com/unkmc). Original server emulator for the NexusTK MMO client.

> This project is primarily maintained with [Claude Code](https://claude.ai/code) by Anthropic — an AI-powered CLI that handles debugging, refactoring, and feature work through natural language.
