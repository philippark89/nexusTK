# NexusTK Server — Useful Commands Reference

---

## Server Management

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart a specific server (login-server | char-server | map-server)
docker exec nexustk-server-1 supervisorctl restart map-server

# Check all server statuses
docker exec nexustk-server-1 supervisorctl status

# Rebuild after C source changes, then restart
docker compose build rtk-server && docker compose up -d
```

---

## Logs

```bash
# Live map server output (Lua errors, spawn messages, etc.)
docker exec nexustk-server-1 tail -f /home/RTK/src/logs/map-stdout.log

# Map server crash backtraces
docker exec nexustk-server-1 tail -50 /home/RTK/src/logs/map-stderr.log

# Count a specific error since last restart
docker exec nexustk-server-1 grep -c "interval is empty" /home/RTK/src/logs/map-stdout.log

# Resolve a crash address to source file + line
docker exec nexustk-server-1 addr2line -e /home/RTK/src/map-server -f 0xABCDEF
```

---

## In-Game GM Commands

| Command | Effect |
|---------|--------|
| `/item <id>` | Spawn item by ID (see `data/items.txt`) |
| `/item <id> <qty>` | Spawn multiple of an item |
| `/givespell <id>` | Grant spell by ID (see `data/spells.txt`) |
| `/heal` | Full heal |
| `/immortality` | Toggle invincibility |
| `/warp <mapid>` | Teleport to map by ID (see `data/maps.txt`) |
| `/warp <mapid> <x> <y>` | Teleport to exact coordinates |
| `/job <id>` | Change class/path |
| `/bc <message>` | Broadcast message to all players |
| `/who` | List online players |
| `/rl` | Reload all Lua scripts |
| `/lua <code>` | Execute Lua inline |
| `/reloadItem` | Reload item database |
| `/metan` | Reload map metadata |

**Note:** Item and spell names with spaces must use the numeric ID.
Reference files: `data/items.txt`, `data/spells.txt`, `data/maps.txt`

---

## Database — Common Fixes

```bash
# Fix character stuck at login ("already logged in" error)
docker exec nexustk-database-1 mysql -u rtk -pchangeMe RTK \
  -e "UPDATE \`Character\` SET ChaOnline=0 WHERE ChaName='YourName';"

# Clear ALL stuck online sessions (safe after a crash)
docker exec nexustk-database-1 mysql -u rtk -pchangeMe RTK \
  -e "UPDATE \`Character\` SET ChaOnline=0;"

# Promote a character to GM level 99
docker exec nexustk-database-1 mysql -u rtk -pchangeMe RTK \
  -e "UPDATE \`Character\` SET ChaGMLevel=99 WHERE ChaName='YourName';"

# Check a character's current state
docker exec nexustk-database-1 mysql -u rtk -pchangeMe RTK \
  -e "SELECT ChaName, ChaLevel, ChaGMLevel, ChaOnline, ChaCurrentVita FROM \`Character\` WHERE ChaName='YourName';"
```

---

## Database — Item & Spell Lookup

```bash
# Search items by name fragment
docker exec nexustk-database-1 mysql -u rtk -pchangeMe RTK \
  -e "SELECT ItmId, ItmDescription FROM Items WHERE ItmDescription LIKE '%keyword%';"

# Search spells by name fragment
docker exec nexustk-database-1 mysql -u rtk -pchangeMe RTK \
  -e "SELECT SplId, SplDescription FROM Spells WHERE SplDescription LIKE '%keyword%';"

# Or just grep the local reference files (faster)
grep -i "keyword" data/items.txt
grep -i "keyword" data/spells.txt
```

---

## Database — Migrations

```bash
# Run all pending migrations
cd database && bash migrate.sh

# Run a single migration manually
docker exec -i nexustk-database-1 mysql -u rtk -pchangeMe RTK \
  < database/scripts/your-migration.sql
```

---

## Build

```bash
# Full rebuild inside container
docker exec nexustk-server-1 sh -c 'cd /home/RTK/src && make clean && make all'

# Rebuild map server only (fastest iteration)
docker exec nexustk-server-1 sh -c 'cd /home/RTK/src && make map'

# Copy a changed source file into container then rebuild
docker cp src/src/map/yourfile.c nexustk-server-1:/home/RTK/src/src/map/yourfile.c
docker exec nexustk-server-1 sh -c 'cd /home/RTK/src && make map'
```

---

## Crash Debugging

```bash
# Get the function+line for any crash offset shown in backtrace
docker exec nexustk-server-1 addr2line -e /home/RTK/src/map-server -f 0xOFFSET

# Find what function contains a given offset (when addr2line shows ??)
docker exec nexustk-server-1 nm /home/RTK/src/map-server | grep "function_name"
# Then: python3 -c "print(hex(function_base + crash_offset))"

# Check if a call site has a cltq (pointer-truncation bug)
docker exec nexustk-server-1 objdump -d /home/RTK/src/map-server 2>/dev/null \
  | grep -A3 "call.*function_name" | grep "cltq"

# Verify a header is actually being included (returns 0 if missing)
docker exec nexustk-server-1 sh -c \
  'cd /home/RTK/src/src/map && gcc [CFLAGS] -E file.c 2>/dev/null | grep -c "expected_symbol"'
```

---

## Lua — In-Game Debugging

```bash
# Reload scripts without restarting (in-game chat)
/rl

# Run arbitrary Lua (in-game chat)
/lua print(player.name)
/lua player.health = player.maxHealth

# Check Lua errors in real time
docker exec nexustk-server-1 tail -f /home/RTK/src/logs/map-stdout.log | grep "Lua error"
```
