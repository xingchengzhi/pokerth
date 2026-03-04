# Flatpak deployment for PokerTH

Kurz: Dieses Verzeichnis enthält ein Flatpak-Manifest und ein kleines Build-Skript für PokerTH (Version 2.0.6).

Voraussetzungen:

- `flatpak` und `flatpak-builder` installiert
- Geeignete `org.freedesktop.Sdk`/`Platform`-Runtimes (z.B. 22.08)

Lokal bauen:

```bash
cd docker/linux/flatpak
./build_flatpak.sh
```

Das Skript legt ein lokales Repo (`repo`), einen Build-Ordner (`build-dir`) und ein Bundle `pokerth-2.0.6.flatpak` an.

Veröffentlichen:

- Lade das Bundle zu deinem Flatpak-Hosting hoch oder erstelle ein Repo auf einem Server.
- Alternativ: verwende `flatpak remote-add --user --no-gpg-verify myrepo file://$PWD/repo` und `flatpak install --user myrepo org.pokerth.PokerTH 2.0.6`.

Anpassungen:

- Passe `org.pokerth.PokerTH.json` an, falls zusätzliche Build-Options oder Runtime-Pakete benötigt werden.
