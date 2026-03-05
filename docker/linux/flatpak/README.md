# Flatpak-Paket für PokerTH

Dieses Verzeichnis enthält das Flatpak-Manifest für PokerTH (v2.0.6).

## Übersicht

- **Runtime:** org.kde.Platform 6.8 (liefert Qt 6.8.x)
- **SDK:** org.kde.Sdk 6.8
- **Boost:** 1.88 (aus Source)
- **Protobuf:** 3.21.12 (aus Source)
- **WebSocket++:** 0.8.2 (aus Source)
- **Target:** `pokerth_client` (Qt Widgets)

## Build via GitHub Actions

Der Flatpak wird über [`.github/workflows/flatpak.yml`](../../../.github/workflows/flatpak.yml) gebaut.

### Automatisch

Bei Push auf `testing` oder `stable` Branch, wenn Dateien in einem dieser Pfade geändert wurden:
- `docker/linux/flatpak/**`
- `src/**`
- `CMakeLists.txt`

### Manuell

GitHub → Actions → **Build & Publish Flatpak** → **Run workflow**

Das `.flatpak`-Bundle kann unter Actions → Build-Run → Artifacts heruntergeladen werden.

## Lokal installieren

```bash
# Bundle herunterladen, dann:
flatpak install --user pokerth.flatpak
flatpak run org.pokerth.PokerTH
```

## Flathub-Veröffentlichung

Für die Veröffentlichung auf Flathub siehe:
https://docs.flathub.org/docs/for-app-authors/submission
