# Setup unter Linux (Ubuntu 24.04)

Diese Anleitung ist die Hauptanleitung des Seminars. Wer Windows nutzt,
arbeitet über WSL 2 und landet nach `docs/02-setup-windows.md` ebenfalls hier.
Wer macOS nutzt, liest zuerst `docs/03-setup-macos.md`.

Zeitbedarf beim ersten Mal ungefähr 45 Minuten, davon die meiste Zeit
Download.

Benötigt werden ein Rechner mit Ubuntu 24.04, mindestens 25 GB freier
Speicherplatz und ein Internetzugang.

---

## Schritt 1, Docker installieren

Nicht das Paket `docker.io` aus den Ubuntu-Quellen verwenden und unter Linux
auch nicht Docker Desktop. Beide führen im Seminar zu Problemen. Installiert
wird die Docker Engine aus dem offiziellen Docker-Repository.

Alte oder unvollständige Installationen zuerst entfernen.

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y $pkg
done
```

Paketquelle eintragen.

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Docker installieren.

```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
```

## Schritt 2, Docker ohne sudo nutzbar machen

```bash
sudo usermod -aG docker $USER
```

**Danach einmal ab- und wieder anmelden.** Ein neues Terminalfenster reicht
nicht aus. Alternativ für die laufende Sitzung `newgrp docker` ausführen.

## Schritt 3, Installation prüfen

```bash
docker run --rm hello-world
```

Erwartet wird eine Ausgabe, die mit "Hello from Docker!" beginnt.

Kommt stattdessen `permission denied while trying to connect to the Docker
daemon socket`, wurde Schritt 2 nicht abgeschlossen oder die Neuanmeldung
fehlt.

## Schritt 4, Repository klonen

```bash
cd ~
git clone https://github.com/tuhh-itl/seminar-mrl.git
cd seminar-mrl
```

## Schritt 5, Konfiguration anlegen

```bash
cp .env.example .env
nano .env
```

In der Datei die `ROS_DOMAIN_ID` der eigenen Gruppe eintragen. Die Zuordnung
steht als Kommentar in der Datei. Speichern mit `Strg+O`, schließen mit
`Strg+X`.

Wer mit Simulation arbeitet, setzt zusätzlich `IMAGE_TAG=jazzy-sim`.

## Schritt 6, Image herunterladen

```bash
docker compose pull
```

Das Basis-Image ist ungefähr 5 GB groß, das Simulations-Image ungefähr 10 GB.
Das dauert im Uni-WLAN spürbar, ist aber einmalig. Das Image wird **nicht**
selbst gebaut, es kommt fertig aus der GitHub Container Registry.

## Schritt 7, Umgebung starten

```bash
chmod +x run.sh
./run.sh
```

Der Prompt wechselt zu `[seminar] ~/ws$`. Ab hier befinden sich alle Befehle
im Container.

## Schritt 8, Funktionstest

Im laufenden Container.

```bash
ros2 run demo_nodes_cpp talker
```

Ein **zweites** Terminal auf dem Host öffnen, ins Repo wechseln und dort.

```bash
docker compose exec ros bash
ros2 run demo_nodes_py listener
```

Der Listener muss die Zählnachrichten des Talkers ausgeben. Wenn das
funktioniert, ist die Installation vollständig.

Beide Prozesse mit `Strg+C` beenden.

## Schritt 9, Grafiktest

```bash
rviz2
```

Es muss sich ein RViz-Fenster öffnen. Schlägt das mit einer Fehlermeldung zu
`DISPLAY` oder OpenGL fehl, siehe `docs/09-troubleshooting.md`, Abschnitt
"Grafische Programme starten nicht".

---

## Die drei Befehle für den Alltag

| Zweck | Befehl |
| --- | --- |
| Umgebung starten und Shell öffnen | `./run.sh` |
| Weiteres Terminal im selben Container | `docker compose exec ros bash` |
| Umgebung stoppen | `docker compose down` |

Für die Roboterprojekte werden regelmäßig drei bis vier Terminals gleichzeitig
gebraucht. Immer `docker compose exec` verwenden und **nie** ein zweites Mal
`docker run`, sonst entstehen getrennte Container, die sich gegenseitig nicht
sehen.

Weiter geht es mit `docs/04-erste-schritte.md`.
