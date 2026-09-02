# Setup unter macOS

macOS ist die unbequemste der drei Varianten. Das liegt nicht an Docker,
sondern daran, dass der Container in einer virtuellen Maschine läuft und auf
Apple Silicon zusätzlich eine andere Prozessorarchitektur vorliegt.

Was funktioniert und was nicht.

| Aufgabe | Intel-Mac | Apple Silicon (M1 bis M4) |
| --- | --- | --- |
| Python, ROS-Grundlagen, Nodes schreiben | funktioniert | funktioniert |
| RViz, Kartenanzeige | über noVNC | über noVNC |
| Gazebo-Simulation | langsam, ohne GPU | **nicht verfügbar** |
| Verbindung zum echten TurtleBot | **nicht verlässlich** | **nicht verlässlich** |

Für die Robotertermine ab Ende November plant bitte fest mit einem
Leih-Laptop oder mit NoMachine auf einem Laborrechner. Meldet euch dafür
rechtzeitig bei der Seminarleitung.

Was euer Rechner an Speicher und Platz mitbringen muss, steht in der
`README.md` im Abschnitt "Reicht mein Rechner?".

---

## Schritt 0, Command Line Tools installieren

`git` und ein brauchbares Terminal bringt macOS nicht von Haus aus mit. Im
Terminal (über Spotlight mit `Cmd+Leertaste`, dann "Terminal" tippen).

```bash
xcode-select --install
```

Es öffnet sich ein Dialogfenster, dort auf *Installieren* klicken. Das dauert
einige Minuten. Ist alles schon vorhanden, meldet der Befehl das und ihr
könnt weitermachen.

Prüfen.

```bash
git --version
```

## Schritt 1, Docker Desktop installieren

Von `https://www.docker.com/products/docker-desktop/` die Version für den
eigenen Chip laden. Welchen ihr habt, steht im Apple-Menü oben links unter
*Über diesen Mac*.

| Dort steht | Ihr braucht |
| --- | --- |
| Apple M1, M2, M3, M4 | **Apple Silicon** |
| Intel Core i5, i7, … | **Intel** |

Die Download-Seite von Docker ist an dieser Stelle unübersichtlich, achtet
genau auf die Bezeichnung. Ladet ihr die falsche Version, startet Docker
Desktop entweder gar nicht oder extrem langsam.

Nach der Installation unter *Settings, Resources* die Zuweisung erhöhen.
Empfohlen sind mindestens 8 GB Arbeitsspeicher und 60 GB Disk Image Size.
Mit den Voreinstellungen bricht der Gazebo-Start regelmäßig ab.

Test im Terminal.

```bash
docker run --rm hello-world
```

## Schritt 2, Repository klonen

```bash
cd ~
git clone https://github.com/tuhh-itl/labor-logistische-systeme.git
cd labor-logistische-systeme
cp .env.example .env
```

`cp .env.example .env` erzeugt die Datei `.env` **im Repo-Verzeichnis**, also
in `~/labor-logistische-systeme/.env`. Sie muss genau dort liegen, sonst
findet `docker compose` sie nicht.

Jetzt müsst ihr dort eure `ROS_DOMAIN_ID` eintragen, die ihr von der
Seminarleitung bekommen habt. Zum Öffnen im Terminal.

```bash
nano .env
```

Sucht die Zeile, die so aussieht, und ersetzt die Zahl durch eure eigene ID.

```dotenv
ROS_DOMAIN_ID=30
```

Speichern mit `Strg+O` und `Enter`, schließen mit `Strg+X`. Dateien, die mit
einem Punkt beginnen, blendet der Finder standardmäßig aus. Mit
`Cmd+Shift+Punkt` macht ihr sie sichtbar, falls ihr lieber grafisch
editiert.

## Schritt 3, Grafik über noVNC statt X11

XQuartz funktioniert grundsätzlich, ist aber langsam und bei OpenGL-Programmen
wie RViz fehleranfällig. Nutzt stattdessen die noVNC-Variante, bei der der
komplette Linux-Desktop im Browser läuft.

Dafür in der `.env` setzen.

```dotenv
IMAGE_TAG=jazzy-vnc
```

> **Gazebo-Simulation auf Apple Silicon geht nicht.** Das Image
> `jazzy-vnc-sim` gibt es nur für Intel-Prozessoren (amd64). Auf M1 bis M4
> bricht `docker compose pull` deshalb ab mit `no matching manifest for
> linux/arm64/v8`. Das ist kein Fehler eures Setups. Gründe und Alternativen
> stehen unten unter "Gazebo auf Apple Silicon".

Starten.

```bash
./run.sh
```

`run.sh` erkennt am `IMAGE_TAG` selbst, dass ihr die noVNC-Variante nutzt,
und gibt beim Start die passende Adresse aus. Öffnet sie im Browser.

```text
http://localhost:6080/vnc.html
```

Dort erscheint ein Linux-Desktop mit Terminal, RViz und allen ROS-Werkzeugen.

Der Zusatz `/vnc.html` ist wichtig. Ruft ihr nur `http://localhost:6080` auf,
seht ihr bei älteren Images statt des Desktops eine schlichte Dateiliste
("Directory listing for /"). Das ist kein Fehler, dem Webserver fehlt nur
eine Startseite.

> **Der Desktop hat kein Passwort.** Er ist deshalb bewusst nur von eurem
> eigenen Rechner aus erreichbar, `run.sh` bindet den Port fest an
> `127.0.0.1`. Ändert das nicht auf eigene Faust, sonst kann jeder im selben
> WLAN euren Desktop übernehmen.
>
> Das Image `jazzy-vnc` gibt es sowohl für Intel als auch für Apple Silicon,
> es läuft auf beiden nativ und ohne Emulation. Nur die Gazebo-Varianten
> `jazzy-sim` und `jazzy-vnc-sim` sind Intel-only, siehe unten.

## Schritt 4, Funktionstest

Im Terminal des noVNC-Desktops oder alternativ über.

```bash
docker compose exec ros bash
```

Dann.

```bash
ros2 run demo_nodes_cpp talker
```

Und in einem zweiten Terminal. Wichtig, auch dort zuerst ins
Repo-Verzeichnis wechseln, sonst findet `docker compose` die
`docker-compose.yml` nicht und meldet `no configuration file provided`.

```bash
cd ~/labor-logistische-systeme
docker compose exec ros bash
ros2 run demo_nodes_py listener
```

Der Listener muss die Nachrichten des Talkers ausgeben.

## Gazebo auf Apple Silicon

Auf Macs mit M1 bis M4 lässt sich die Gazebo-Simulation derzeit nicht
nutzen. Die fertigen Images enthalten Gazebo nur in der Intel-Variante
(amd64), ein Start auf Apple Silicon scheitert mit `no matching manifest for
linux/arm64/v8`.

Docker könnte das amd64-Image zwar emulieren, für eine 3D-Simulation ist das
in der Praxis aber unbrauchbar langsam.

Was ihr stattdessen tun könnt.

- **Alles außer Gazebo** funktioniert auf eurem Mac normal, also
  ROS-Grundlagen, eigene Nodes, RViz und `turtlesim` aus
  `docs/05-simulation.md`. Für die Grundlagenblöcke reicht das.
- **Für die Simulationsaufgaben** meldet euch bei der Seminarleitung, dann
  bekommt ihr einen Leih-Laptop oder arbeitet per NoMachine auf einem
  Laborrechner.

## Schritt 5, VS Code anbinden, empfohlen

Zum Schreiben eurer Nodes braucht ihr einen Editor. VS Code bekommt ihr hier.

<https://code.visualstudio.com/download>

Ladet die **Mac**-Version, entpackt sie und zieht *Visual Studio Code* in
den Ordner *Programme*. Das ist wichtig, sonst findet der nächste Schritt die
App nicht.

Anders als unter Linux und Windows steht der Befehl `code` auf dem Mac nach
der Installation **nicht** automatisch im Terminal zur Verfügung. Ihr müsst
ihn einmalig freischalten.

1. VS Code öffnen
2. `Cmd+Shift+P` drücken, damit öffnet sich die Befehlspalette
3. Dort `shell command` tippen und
   *Shell Command: Install 'code' command in PATH* auswählen
4. Das Terminal einmal schließen und neu öffnen

Danach funktioniert im Repo-Verzeichnis.

```bash
cd ~/labor-logistische-systeme
code .
```

Ohne diesen Schritt meldet das Terminal `command not found: code`. Ihr könnt
den Ordner alternativ auch einfach in VS Code über *File, Open Folder*
öffnen, das kommt aufs Gleiche heraus.

## Schritt 6, Netzwerk-Hinweis

`network_mode: host` hat unter Docker Desktop nicht dieselbe Bedeutung wie
unter Linux. Zwei Container auf demselben Mac finden sich zuverlässig, ein
Roboter im WLAN in aller Regel nicht. Das ist eine Eigenschaft der
Virtualisierung und lässt sich nicht sinnvoll umgehen.

Weiter geht es mit `docs/04-erste-schritte.md`.
