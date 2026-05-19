# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

nexusTK is a RetroTK MMO game server — a fork of [RTK-Server](https://github.com/unkmc/RTK-Server). It runs as three cooperating C servers (login, char, map) backed by MySQL, with Lua scripts driving game logic.

## Current Goal

**Containerize and stabilize all three C game servers on Ubuntu 22.04.**

The C source is built with GNU Make. The active work is:
1. Get the Dockerfile building cleanly on `ubuntu:22.04` (currently based on `i386/ubuntu:latest` — needs to be updated and dependencies resolved for Ubuntu 22)
2. Wire up the actual `make all` + server start commands in `docker-compose.yml` (currently a `tail -F /dev/null` placeholder)
3. Confirm all three servers (login, char, map) start and stay running stably inside the container
4. Add database volume persistence and the backup cron job

When touching the Dockerfile or docker-compose, the priority is: compile successfully → servers start → servers stay up.

## Build Commands

Build runs inside the Docker container. The target platform is Ubuntu 22.04. Required packages: `build-essential`, `libmysqlclient-dev`, `lua5.1`, `liblua5.1-dev`, `zlib1g-dev`, `libpthread-stubs0-dev`.

```bash
# Build everything
cd rtk && make all

# Build individual servers
make login
make char
make map

# Build utilities
make metan     # metadata creator tool
make decrypt   # packet decryption utility

make clean     # clean all build artifacts
```

## Docker Workflow

```bash
# Start all services (game server + MySQL)
docker compose up -d

# Run database migrations manually
./database/migrate.sh

# Rebuild after C source changes
docker compose build rtk-server
docker compose up -d
```

Services: `rtk-server` (ports 2000, 2001, 2005) and MySQL (port 3306, user `rtk`, password `changeMe`, database `RTK`).

## Database Migrations

Migrations live in `database/scripts/` as timestamped SQL files. They run in chronological filename order via `database/migrate.sh`, which shells into the MySQL Docker container.

Development-only SQL lives in `database/scripts_dev/` (not run automatically). Automated 5-minute backups go to `database/history/` with 72-hour retention.

## Server Architecture

Three-server distributed design — each server is a separate process that communicates via inter-server sockets:

```
Client → Login Server (src/login/)     # authentication, server list
            ↕ inter-server
         Char Server (src/char/)        # character persistence, inventory
            ↕ inter-server
         Map Server (src/map/)          # game world, NPCs, combat, Lua scripts
```

Shared infrastructure in `src/common/`: socket I/O, MySQL abstraction, timers, encryption, memory management, logging.

### Configuration

All runtime config lives in `rtk/conf/`:
- `inter.conf` — inter-server IPs/ports (must match across all three servers)
- `map.conf` / `char.conf` / `login.conf` — per-server settings
- `battle.conf` — combat balance tuning
- `script.conf` — Lua engine settings

## Lua Game Scripts

Game logic is scripted in Lua 5.1 under `rtklua/`. Only scripts in `rtklua/Accepted/` are loaded by the server; `rtklua/Developers/` is for work-in-progress.

Key scripts:
- `Accepted/player.lua` — player stats, progression, core player mechanics (138KB)
- `Accepted/speech.lua` — NPC dialogue system (62KB)
- `Accepted/crafting.lua` — crafting recipes and item creation (35KB)
- `Accepted/config.lua` — global Lua configuration
- `Accepted/startup.lua` — server startup initialization
- `Accepted/ntkSystem.lua` — core game systems
- `Accepted/Quests/` — quest tracker and quest check hooks

The map server's `src/map/script.c` implements the C-side Lua API. See `rtklua/LUA Help File.txt` for the available API.

## Map Files

Game world maps are in `rtkmaps/Accepted/` as binary `.map` files. `rtkmaps/warps.txt` documents warp point connections between maps. The `metan` tool (`src/metan/`) generates the metadata files consumed by the map server at startup.

## Outstanding Containerization Work

- **Dockerfile**: currently based on `i386/ubuntu:latest` with `mysql-client-5.7` — needs to be updated to `ubuntu:22.04` with Ubuntu 22-compatible packages
- **docker-compose.yml**: `server` command is a placeholder (`tail -F /dev/null`) — needs `make all` build step and server startup commands
- **docker-compose.yml**: no persistent volume for the MySQL data directory
- **Backup cron**: 5-minute DB backup script exists (`database/backup.sh`) but not wired into the container
