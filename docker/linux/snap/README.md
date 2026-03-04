# Snap deployment for PokerTH

Dieses Verzeichnis enthält die Snap-Paketdefinition für PokerTH (Version 2.0.6).

## Aufbau

- `snapcraft.yaml` — Snap-Manifest (base: core24, Qt6, Boost 1.88 from source)
- `.devcontainer/` — VS Code Devcontainer (Ubuntu 24.04) für lokale Entwicklung/Tests
- `.github/workflows/snap.yml` — GitHub Actions Workflow für Snap-Build & Publish

## Snap bauen

### Via GitHub Actions (empfohlen)

Der Snap wird automatisch gebaut bei:
- Push auf `testing` oder `stable` Branch (wenn Dateien in `docker/linux/snap/`, `src/` oder `CMakeLists.txt` geändert wurden)
- Manueller Trigger über GitHub → Actions → "Build & Publish Snap" → "Run workflow"

Das `.snap`-Artefakt kann danach unter Actions → Build-Run → Artifacts heruntergeladen werden.

### Lokal entwickeln

Der Devcontainer dient zum Testen des CMake-Builds gegen die core24-Bibliotheken (Ubuntu 24.04):

```bash
# Devcontainer öffnen, dann:
cd /opt/pokerth-snap/pokerth
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

## Veröffentlichen im Snap Store

### Einmalig: Store-Credentials einrichten

1. Lokal (mit installiertem snapcraft):
   ```bash
   snapcraft export-login --snaps pokerth --channels stable credentials.txt
   ```
2. Inhalt von `credentials.txt` als GitHub Secret `SNAPCRAFT_STORE_CREDENTIALS` anlegen
3. Push auf `stable` Branch triggert automatisch Build + Publish

### Manuell hochladen

```bash
snapcraft login
snapcraft upload --release=stable pokerth_2.0.6_amd64.snap
```
