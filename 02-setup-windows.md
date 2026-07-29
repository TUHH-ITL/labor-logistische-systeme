# Setup unter Windows

Unter Windows wird nicht direkt gearbeitet, sondern in einem Ubuntu 24.04
über WSL 2. Damit gilt anschließend exakt dieselbe Anleitung wie unter Linux,
und grafische Programme wie RViz funktionieren ohne Zusatzsoftware.

Voraussetzung ist Windows 10 ab Version 2004 oder Windows 11, dazu
Administratorrechte auf dem eigenen Rechner.

> **Einschränkung, bitte vorher lesen.**
> Für die Termine mit den echten TurtleBots ist Windows mit Docker Desktop
> keine verlässliche Grundlage. Der Container läuft dort in einer virtuellen
> Maschine, und die DDS-Erkennung des Roboters im WLAN funktioniert nur
> unzuverlässig. Für die Grundlagenblöcke im Oktober und November genügt
> dieses Setup vollständig. Ab der Ausgabe der Roboter arbeitet ihr entweder
> an einem Leih-Laptop mit Linux oder per NoMachine auf einem Laborrechner.
> Details in `docs/09-troubleshooting.md`.

---

## Schritt 1, WSL 2 installieren

PowerShell **als Administrator** öffnen und ausführen.

```powershell
wsl --install -d Ubuntu-24.04
```

Falls Windows danach einen Neustart verlangt, den Rechner neu starten. Das
ist nicht in jedem Fall nötig, auf manchen Systemen läuft die Einrichtung
direkt im Anschluss weiter.

Automatisch öffnet sich ein Ubuntu-Fenster und fragt nach einem
Benutzernamen und einem Passwort. Das ist ein neues Linux-Konto und hat
nichts mit dem Windows-Konto zu tun. Das Passwort wird beim Tippen nicht
angezeigt, das ist normal.

Danach wieder zu **PowerShell** wechseln, nicht im gerade geöffneten
Ubuntu-Fenster weiterarbeiten, und dort prüfen, dass Version 2 aktiv ist.

```powershell
wsl -l -v
```

In der Spalte VERSION muss eine 2 stehen. Steht dort eine 1, dann folgenden
Befehl ausführen.

```powershell
wsl --set-version Ubuntu-24.04 2
```

## Schritt 2, Docker Desktop installieren

Docker Desktop von `https://www.docker.com/products/docker-desktop/`
herunterladen und installieren. Bei der Installation die Option **Use WSL 2
instead of Hyper-V** aktiviert lassen. In neueren Versionen von Docker
Desktop taucht dieser Dialog beim Setup teils gar nicht mehr auf, weil WSL 2
dort bereits Standard ist.

Nach dem Start von Docker Desktop unter *Settings, Resources, WSL Integration*
den Schalter für **Ubuntu-24.04** einschalten und mit *Apply and restart*
bestätigen.

**War Docker Desktop schon vorher installiert** und ist unklar, ob es auf
WSL 2 läuft, lässt sich das nachträglich prüfen: unter *Settings, General*
muss die Option **Use the WSL 2 based engine** aktiviert sein. Alternativ
in PowerShell.

```powershell
wsl -l -v
```

Läuft zusätzlich die Distribution `docker-desktop` (Version 2, Status meist
`Stopped`, solange Docker Desktop nicht gestartet ist), nutzt Docker Desktop
bereits WSL 2. `docker-desktop-data` erscheint bei neueren Docker-Desktop-
Versionen oft nicht in der Liste, das ist normal und kein Fehler. Fehlt
`docker-desktop` komplett, die Option unter *Settings, General* aktivieren
und mit *Apply & restart* bestätigen, ein Neuinstallieren ist nicht nötig.

## Schritt 3, Ins Linux wechseln

Ab hier findet alles im Ubuntu-Terminal statt, nicht in PowerShell. Das
Ubuntu-Terminal öffnet ihr über das Startmenü mit "Ubuntu" oder in Windows
Terminal über den Reiter-Pfeil.

**Docker Desktop muss dafür laufen.** Ein bloß installiertes, aber nicht
gestartetes Docker Desktop reicht nicht, die WSL-Integration wirkt erst,
wenn die App im Hintergrund aktiv ist (Wal-Icon in der Taskleiste). Fehlt
der Befehl `docker` im Ubuntu-Terminal mit dem Hinweis "could not be found
in this WSL 2 distro", meist Docker Desktop starten.

Test im Ubuntu-Terminal.

```bash
docker run --rm hello-world
```

Kommt stattdessen `permission denied while trying to connect to the Docker
daemon socket`, wurde die WSL-Integration gerade erst aktiviert und die
schon offene Ubuntu-Sitzung kennt die neue Gruppenmitgliedschaft in der
Gruppe `docker` noch nicht. Prüfen mit.

```bash
groups
```

Steht dort kein `docker`, hilft `newgrp docker` in der laufenden Sitzung.
Zuverlässiger ist, alle Ubuntu-Terminalfenster zu schließen und in
**PowerShell**.

```powershell
wsl --shutdown
```

auszuführen, danach das Ubuntu-Terminal neu öffnen. Ein bloßes Schließen des
Terminalfensters reicht bei WSL oft nicht, weil die Distribution im
Hintergrund weiterläuft.

Funktioniert das, ist Docker in WSL nutzbar.

## Schritt 4, Wichtig, richtiges Dateisystem verwenden

Das Repository muss **im Linux-Dateisystem** liegen, also unterhalb von
`/home/<benutzername>`. Nicht unter `/mnt/c/Users/...`.

Auf `/mnt/c` sind Dateizugriffe um ein Vielfaches langsamer, und die
Rechteverwaltung passt nicht zu Linux. Ein `colcon build` dauert dort statt
einer Minute schnell zehn. (`colcon build` ist der Befehl, um Software zu kompilieren.)

Auf die Dateien kommt ihr aus Windows trotzdem bequem, im Explorer über die
Adresse `\\wsl$\Ubuntu-24.04\home\<benutzername>`.

## Schritt 5, Repository klonen

Git ist im frischen WSL-Ubuntu nicht immer vorinstalliert, im Zweifel
nachinstallieren.

```bash
sudo apt-get update
sudo apt-get install -y git
```

Dann das Repository klonen, wichtig **im Home-Verzeichnis** wie in Schritt 4
beschrieben, nicht unter `/mnt/c/...`.

```bash
cd ~
git clone https://github.com/tuhh-itl/seminar-mrl.git
cd seminar-mrl
```

## Schritt 6, Konfiguration anlegen

```bash
cp .env.example .env
nano .env
```

In der Datei die `ROS_DOMAIN_ID` der eigenen Gruppe eintragen. Die Zuordnung
steht als Kommentar in der Datei. Speichern mit `Strg+O`, schließen mit
`Strg+X`.

Wer mit Simulation arbeitet, setzt zusätzlich `IMAGE_TAG=jazzy-sim`.

## Schritt 7, Image herunterladen

```bash
docker compose pull
```

Das Basis-Image ist ungefähr 5 GB groß, das Simulations-Image ungefähr 10 GB.
Das dauert im Uni-WLAN spürbar, ist aber einmalig. Das Image wird **nicht**
selbst gebaut, es kommt fertig aus der GitHub Container Registry.

## Schritt 8, Umgebung starten

```bash
chmod +x run.sh
./run.sh
```

Der Prompt wechselt zu `[seminar] ~/ws$`. Ab hier befinden sich alle Befehle
im Container.

## Schritt 9, Funktionstest

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

## Schritt 10, Grafiktest

```bash
rviz2
```

Dank WSLg muss sich ein RViz-Fenster ohne Zusatzsoftware öffnen, siehe auch
Abschnitt "Grafische Programme" weiter unten. Schlägt das mit einer
Fehlermeldung zu `DISPLAY` oder OpenGL fehl, siehe `docs/09-troubleshooting.md`,
Abschnitt "Grafische Programme starten nicht".

## Schritt 11, VS Code anbinden, empfohlen

VS Code unter Windows installieren und die Erweiterung **WSL** von Microsoft
hinzufügen. Danach im Ubuntu-Terminal im Repo-Verzeichnis.

```bash
code .
```

VS Code öffnet sich unter Windows, arbeitet aber im Linux-Dateisystem. Das ist
die bequemste Arbeitsweise für das Seminar.

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

---

## Grafische Programme

WSL 2 unter Windows 11 bringt WSLg mit, dadurch öffnen sich RViz und Gazebo
ohne weitere Einstellungen als normale Windows-Fenster. Unter Windows 10 muss
WSL aktuell sein, ansonsten hilft folgender Befehl.

```powershell
wsl --update
```
