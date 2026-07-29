# Setup unter macOS

macOS ist die unbequemste der drei Varianten. Das liegt nicht an Docker,
sondern daran, dass der Container in einer virtuellen Maschine läuft und auf
Apple Silicon zusätzlich eine andere Prozessorarchitektur vorliegt.

Was funktioniert und was nicht.

| Aufgabe | Status auf macOS |
| --- | --- |
| Python, ROS-Grundlagen, Nodes schreiben | funktioniert |
| RViz, Kartenanzeige | funktioniert über noVNC |
| Gazebo-Simulation | läuft, aber ohne GPU langsam |
| Verbindung zum echten TurtleBot | **nicht verlässlich** |

Für die Robotertermine ab Ende November plant bitte fest mit einem
Leih-Laptop oder mit NoMachine auf einem Laborrechner. Meldet euch dafür
rechtzeitig bei der Seminarleitung.

---

## Schritt 1, Docker Desktop installieren

Von `https://www.docker.com/products/docker-desktop/` die Version für den
eigenen Chip laden, also **Apple Silicon** für M1 bis M4 und **Intel** für
ältere Geräte.

Nach der Installation unter *Settings, Resources* die Zuweisung erhöhen.
Empfohlen sind mindestens 8 GB Arbeitsspeicher und 60 GB Disk Image Size.
Mit den Voreinstellungen bricht der Gazebo-Start regelmäßig ab.

**Wichtig, sonst bleibt noVNC unerreichbar.** Unter *Settings, Resources,
Network* den Schalter **Enable host networking** aktivieren und mit *Apply
& restart* bestätigen. Ohne diese Einstellung landet `network_mode: host`
aus der `docker-compose.yml` nur im Netz der Docker-Desktop-VM, und
`http://localhost:6080` aus Schritt 3 antwortet nicht.

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

In der `.env` die `ROS_DOMAIN_ID` der eigenen Gruppe eintragen.

## Schritt 3, Grafik über noVNC statt X11

XQuartz funktioniert grundsätzlich, ist aber langsam und bei OpenGL-Programmen
wie RViz fehleranfällig. Nutzt stattdessen die noVNC-Variante, bei der der
komplette Linux-Desktop im Browser läuft.

Dafür in der `.env` setzen.

```dotenv
IMAGE_TAG=jazzy-vnc
```

Wer zusätzlich mit Gazebo simuliert, setzt stattdessen `IMAGE_TAG=jazzy-vnc-sim`.

Starten.

```bash
docker compose up -d
```

Im Browser `http://localhost:6080` öffnen. Dort erscheint ein Linux-Desktop
mit Terminal, RViz und allen ROS-Werkzeugen.

> Auf Apple Silicon wird das Image unter Emulation ausgeführt, falls kein
> arm64-Build vorliegt. Beim ersten Start dauert das mehrere Minuten. Falls
> Docker eine Warnung zur Plattform ausgibt, ist das erwartbar und kein
> Fehler.

## Schritt 4, Funktionstest

Im Terminal des noVNC-Desktops oder alternativ über.

```bash
docker compose exec ros bash
```

Dann.

```bash
ros2 run demo_nodes_cpp talker
```

Und in einem zweiten Terminal.

```bash
docker compose exec ros bash
ros2 run demo_nodes_py listener
```

Der Listener muss die Nachrichten des Talkers ausgeben.

## Schritt 5, Netzwerk-Hinweis

`network_mode: host` hat unter Docker Desktop nicht dieselbe Bedeutung wie
unter Linux. Zwei Container auf demselben Mac finden sich zuverlässig, ein
Roboter im WLAN in aller Regel nicht. Das ist eine Eigenschaft der
Virtualisierung und lässt sich nicht sinnvoll umgehen.

Weiter geht es mit `docs/04-erste-schritte.md`.
