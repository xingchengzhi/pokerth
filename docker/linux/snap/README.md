# Snap deployment for PokerTH

Kurz: Dieses Verzeichnis enthält die Snap-Paketdefinition für PokerTH (Version 2.0.6).

Schnellstart (lokal bauen):

1. Stelle sicher, dass `snapcraft` installiert ist und LXD oder multipass verfügbar ist.
2. Ausführen:

```bash
cd docker/linux/snap
./build_snap.sh
```

Das erzeugt ein Snap im lokalen Verzeichnis (oder baut direkt, je nach Snapcraft-Konfiguration).

Veröffentlichen in den Snap Store:

1. `snapcraft login`
2. `snapcraft upload --release=stable pokerth_2.0.6_*.snap`

Hinweis: Passe `snapcraft.yaml` an, falls zusätzliche Qt- und System-Bibliotheken benötigt werden.
