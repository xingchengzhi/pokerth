# Snap deployment for PokerTH

Dieses Verzeichnis enthält die Snap-Paketdefinition für PokerTH (Version 2.0.6).

## Aufbau

- `snapcraft.yaml` — Snap-Manifest (base: core24, Qt6, Boost 1.88 from source)
- `build_snap.sh` — Build-Script, ruft `snapcraft --destructive-mode` auf
- `.devcontainer/` — VS Code Devcontainer (Ubuntu 24.04), snapcraft vorinstalliert

## Snap bauen

### Option A: Devcontainer (empfohlen)

1. Devcontainer in VS Code öffnen (`docker/linux/snap/.devcontainer/`)
2. Im Terminal:

```bash
./build_snap.sh
```

Der Container basiert auf Ubuntu 24.04 (= core24) und hat snapcraft direkt verfügbar.
Kein Docker-in-Docker nötig.

### Option B: Manuell im Container

```bash
cd docker/linux/snap/.devcontainer
docker compose build
docker compose run --rm devcontainer bash -c "cd /workspaces/snap && ./build_snap.sh"
```

## Veröffentlichen

```bash
snapcraft login
snapcraft upload --release=stable pokerth_2.0.6_*.snap
```
