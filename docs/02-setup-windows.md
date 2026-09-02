# Setup unter Windows

Unter Windows wird nicht direkt gearbeitet, sondern in einem Ubuntu 24.04
über WSL 2. Damit gilt anschließend exakt dieselbe Anleitung wie unter Linux,
und grafische Programme wie RViz funktionieren ohne Zusatzsoftware.

Voraussetzung ist Windows 10 ab Version 2004 oder Windows 11, dazu
Administratorrechte auf dem eigenen Rechner.

Für die Grundlagen genügt ein normaler Laptop, anspruchsvoll ist nur die
3D-Simulation. Was euer Rechner können muss und was gilt, wenn er das nicht
schafft, steht in der `README.md` im Abschnitt "Reicht mein Rechner?".

> **Einschränkung, bitte vorher lesen.**
> Für die Termine mit den echten TurtleBots ist Windows mit Docker Desktop
> keine verlässliche Grundlage. Der Container läuft dort in einer virtuellen
> Maschine, und die DDS-Erkennung des Roboters im WLAN funktioniert nur
> unzuverlässig. Für die Grundlagenblöcke im Oktober und November genügt
> dieses Setup vollständig. Ab der Ausgabe der Roboter arbeitet ihr entweder
> an einem Leih-Laptop mit Linux oder per NoMachine auf einem Laborrechner.
> Details in `docs/09-troubleshooting.md`.

---

## Drei Terminals, bitte nicht verwechseln

Im Laufe der Anleitung arbeitet ihr mit drei verschiedenen Kommandozeilen.
Sie sehen ähnlich aus, sind aber drei getrennte Welten. Wenn ein Befehl
"command not found" meldet, sitzt ihr meistens einfach im falschen Terminal.

| Gemeint ist | So erkennt ihr es | Dafür ist es da |
| --- | --- | --- |
| **PowerShell** | blauer Prompt, endet mit `>` | Windows-Befehle wie `wsl` |
| **Ubuntu-Terminal** | Prompt `benutzer@rechner:~$` | Linux, `git`, `docker` |
| **Container-Terminal** | Prompt `[seminar] ~/ws$` | ROS-Befehle wie `ros2` |

Das Container-Terminal öffnet sich im Ubuntu-Terminal, sobald ihr `./run.sh`
startet. Ihr verlasst es wieder mit `exit` und landet dann im
Ubuntu-Terminal, aus dem ihr gekommen seid. `exit` beendet dabei nur eure
Shell, der Container selbst läuft weiter.

---

## Schritt 1, WSL 2 installieren

PowerShell **als Administrator** öffnen. Dafür im Startmenü "PowerShell"
tippen, dann Rechtsklick auf *Windows PowerShell* und *Als Administrator
ausführen*.

Zuerst WSL auf den aktuellen Stand bringen. Das dauert nur einen Moment und
erspart euch den häufigsten Fehler beim nächsten Befehl.

```powershell
wsl --update
```

Dann Ubuntu installieren.

```powershell
wsl --install -d Ubuntu-24.04
```

Falls Windows danach einen Neustart verlangt, den Rechner neu starten. Das
ist nicht in jedem Fall nötig, auf manchen Systemen läuft die Einrichtung
direkt im Anschluss weiter.

Anschließend müsst ihr ein Linux-Konto anlegen, indem ihr einen
Benutzernamen und ein Passwort vergebt. Das hat nichts mit eurem
Windows-Konto zu tun. Das Passwort wird beim Tippen **nicht angezeigt**,
auch keine Sternchen, das ist normal.

Bei manchen öffnet sich dafür automatisch ein Ubuntu-Fenster, bei anderen
nicht. Passiert nichts, startet ihr Ubuntu einfach selbst über das Startmenü
(dort "Ubuntu" tippen) und werdet dann nach Benutzername und Passwort
gefragt.

Merkt euch diesen Linux-Benutzernamen, ihr braucht ihn später noch.

Danach wieder zu **PowerShell** wechseln, nicht im Ubuntu-Fenster
weiterarbeiten, und dort prüfen, dass Version 2 aktiv ist.

```powershell
wsl -l -v
```

In der Spalte VERSION muss eine 2 stehen. Steht dort eine 1, dann folgenden
Befehl ausführen.

```powershell
wsl --set-version Ubuntu-24.04 2
```

> ### 🔧 Wenn es hakt
>
> **`Invalid distribution name: 'Ubuntu-24.04'`**
> Eure WSL-Version ist zu alt und kennt den Namen noch nicht. Einmal
> `wsl --update` ausführen, danach `wsl --install -d Ubuntu-24.04`
> wiederholen. Genau dafür steht der Update-Befehl oben.
>
> **`Distribution schon vorhanden` oder ähnlich**
> Ubuntu ist bereits installiert. Prüfen mit `wsl -l -v`. Taucht dort ein
> Eintrag `Ubuntu` oder `Ubuntu-24.04` mit VERSION 2 auf, seid ihr fertig
> und könnt zu Schritt 2 weitergehen. Heißt der Eintrag nur `Ubuntu`,
> verwendet ihr diesen Namen ab jetzt in allen Befehlen statt
> `Ubuntu-24.04`.
>
> **Das Ubuntu-Terminal startet gar nicht mehr**
> Kommt vor, wenn WSL im Hintergrund hängt. Rechner neu starten, danach
> geht es in aller Regel wieder.

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

Ab hier findet alles im Ubuntu-Terminal statt, nicht in PowerShell. Ihr
öffnet es über das Startmenü, indem ihr "Ubuntu" tippt und die App
"Ubuntu 24.04" startet. Der Prompt sieht dann so aus.

```text
benutzername@rechnername:~$
```

**Docker Desktop muss dafür laufen**, also die Windows-App gestartet sein
(Wal-Icon in der Taskleiste). Ein bloß installiertes Docker Desktop reicht
nicht, die WSL-Integration wirkt erst, wenn die App aktiv ist.

Test im Ubuntu-Terminal.

```bash
docker run --rm hello-world
```

Es muss eine Ausgabe erscheinen, die mit "Hello from Docker!" beginnt. Dann
ist Docker in WSL nutzbar und ihr könnt zu Schritt 4 weitergehen.

> ### 🔧 Wenn es hakt
>
> **`The command 'docker' could not be found in this WSL 2 distro`**
> Docker Desktop läuft nicht. Über das Startmenü starten und warten, bis das
> Wal-Icon in der Taskleiste erscheint. Danach den Test wiederholen.
>
> **`permission denied while trying to connect to the Docker daemon socket`**
> Die WSL-Integration wurde gerade erst aktiviert, eure schon offene
> Ubuntu-Sitzung kennt die neue Gruppenmitgliedschaft `docker` noch nicht.
> Prüfen mit `groups`. Steht dort kein `docker`, hilft in der laufenden
> Sitzung.
>
> ```bash
> newgrp docker
> ```
>
> Wirkt das nicht, alle Ubuntu-Terminalfenster schließen und in
> **PowerShell** ausführen:
>
> ```powershell
> wsl --shutdown
> ```
>
> Danach das Ubuntu-Terminal neu öffnen. Ein bloßes Schließen des
> Terminalfensters reicht bei WSL oft nicht, weil die Distribution im
> Hintergrund weiterläuft.

## Schritt 4, Repository klonen

Git ist im frischen WSL-Ubuntu nicht immer vorinstalliert, im Zweifel
nachinstallieren.

```bash
sudo apt-get update
sudo apt-get install -y git
```

Dann das Repository klonen.

```bash
cd ~
git clone https://github.com/tuhh-itl/labor-logistische-systeme.git
cd labor-logistische-systeme
```

`cd ~` wechselt in euer Linux-Home-Verzeichnis, das vollständig
`/home/<benutzername>` heißt. Genau dort muss das Repository liegen, und
**nicht** unter `/mnt/c/...`.

Der Grund: Ubuntu läuft in WSL mit einem eigenen Linux-Dateisystem. Eure
Windows-Laufwerke sind darin zusätzlich unter `/mnt/c`, `/mnt/d` und so
weiter eingehängt. Dateizugriffe über `/mnt/c` sind aber um ein Vielfaches
langsamer, und die Rechteverwaltung passt nicht zu Linux. Ein `colcon build`
(der Befehl, mit dem später euer Code kompiliert wird) dauert dort statt
einer Minute schnell zehn.

### Von Windows aus auf die Dateien zugreifen

Ihr müsst zum Bearbeiten nicht ins Terminal. Öffnet im Windows-Explorer
diese Adresse.

```text
\\wsl$\Ubuntu-24.04\home\<benutzername>\labor-logistische-systeme
```

`<benutzername>` ersetzt ihr dabei durch euren **Linux-Benutzernamen**, den
ihr in Schritt 1 vergeben habt, nicht durch euren Windows-Benutzernamen. Die
beiden sind unabhängig voneinander und heißen oft unterschiedlich. Wisst ihr
ihn nicht mehr, zeigt ihn dieser Befehl im Ubuntu-Terminal.

```bash
whoami
```

Das ist **dasselbe Verzeichnis**, in dem ihr eben `git clone` ausgeführt
habt, nur von Windows aus betrachtet. Es gibt die Dateien also nicht
doppelt. Was ihr im Explorer ändert, sieht das Ubuntu-Terminal sofort und
umgekehrt.

| Aus dem Ubuntu-Terminal | Aus dem Windows-Explorer |
| --- | --- |
| `~` beziehungsweise `/home/<benutzername>` | `\\wsl$\Ubuntu-24.04\home\<benutzername>` |

Tipp: Die Adresse einmal im Explorer öffnen und als Favorit anheften, dann
müsst ihr sie nicht jedes Mal tippen.

## Schritt 5, Konfiguration anlegen

Diese Befehle gehören ins Ubuntu-Terminal, und zwar **im
Repo-Verzeichnis**. Wenn ihr direkt aus Schritt 4 kommt, seid ihr schon
dort. Zur Sicherheit.

```bash
cd ~/labor-logistische-systeme
cp .env.example .env
nano .env
```

Damit entsteht die Datei `~/labor-logistische-systeme/.env`. Genau dort muss
sie liegen, direkt neben der `docker-compose.yml`, sonst findet
`docker compose` sie nicht. Ihr Name ist `.env`, nicht `env` oder
`.env.txt`.

In der Datei sucht ihr diese Zeile.

```dotenv
ROS_DOMAIN_ID=30
```

Ersetzt die Zahl durch die ID, die eure Gruppe von der Seminarleitung
bekommen hat. Die Zuordnung steht zusätzlich als Kommentar direkt darüber in
der Datei. Speichern mit `Strg+O` und `Enter`, schließen mit `Strg+X`.

Wer mit Simulation arbeitet, ändert außerdem die Zeile `IMAGE_TAG=jazzy-base`
zu `IMAGE_TAG=jazzy-sim`.

Kontrollieren könnt ihr das Ergebnis mit.

```bash
grep -v "^#" .env
```

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

Dieser Prozess läuft jetzt dauerhaft und blockiert das Terminal, das ist so
gewollt. Öffnet deshalb ein **zweites Ubuntu-Terminal** über das Startmenü.
Dort müsst ihr zuerst wieder ins Repo-Verzeichnis wechseln, denn jedes neue
Terminal startet im Home-Verzeichnis, und `docker compose` funktioniert nur
dort, wo die `docker-compose.yml` liegt.

```bash
cd ~/labor-logistische-systeme
docker compose exec ros bash
```

Der Prompt wechselt wieder zu `[seminar] ~/ws$`, ihr seid also im selben
Container wie im ersten Terminal. Dort dann.

```bash
ros2 run demo_nodes_py listener
```

Der Listener muss die Zählnachrichten des Talkers ausgeben. Wenn das
funktioniert, ist die Installation vollständig.

Beide Prozesse mit `Strg+C` beenden.

## Schritt 9, Grafiktest

```bash
rviz2
```

Dank WSLg muss sich ein RViz-Fenster ohne Zusatzsoftware öffnen, siehe auch
Abschnitt "Grafische Programme" weiter unten. Schlägt das mit einer
Fehlermeldung zu `DISPLAY` oder OpenGL fehl, siehe `docs/09-troubleshooting.md`,
Abschnitt "Grafische Programme starten nicht".

## Schritt 10, VS Code anbinden, empfohlen

VS Code unter Windows installieren, den Download gibt es hier.

<https://code.visualstudio.com/download>

Danach in VS Code die Erweiterung **WSL** von Microsoft hinzufügen, über das
Symbol für Erweiterungen in der linken Leiste oder mit `Strg+Shift+X` und
der Suche nach "WSL".

Der nächste Befehl gehört ins **Ubuntu-Terminal**, nicht ins Container-
Terminal. Steht euer Prompt noch auf `[seminar] ~/ws$`, verlasst den
Container zuerst.

```bash
exit
```

Ihr landet wieder im Ubuntu-Terminal. Der Container läuft dabei im
Hintergrund weiter, ihr könnt ihn jederzeit mit `docker compose exec ros bash`
erneut betreten. Jetzt ins Repo-Verzeichnis wechseln und VS Code starten.

```bash
cd ~/labor-logistische-systeme
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
