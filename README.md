# Labor Logistische Systeme

Arbeitsumgebung für das Seminar am Institut für Technische Logistik, TUHH.

---

## Schnellstart

Sucht euch die Anleitung für euer Betriebssystem.

| Betriebssystem | Anleitung |
| --- | --- |
| Linux, Ubuntu 24.04 | [docs/01-setup-linux.md](docs/01-setup-linux.md) |
| Windows 10 oder 11 | [docs/02-setup-windows.md](docs/02-setup-windows.md) |
| macOS | [docs/03-setup-macos.md](docs/03-setup-macos.md) |

Danach für alle gleich.

- [docs/04-erste-schritte.md](docs/04-erste-schritte.md), erstes eigenes Paket
- [docs/05-simulation.md](docs/05-simulation.md), turtlesim und Gazebo mit TurtleBot4
- [docs/09-troubleshooting.md](docs/09-troubleshooting.md), wenn etwas klemmt

**Bringt das Setup fertig zum ersten Termin mit.** Wenn es klemmt, meldet euch
vorher, damit wir die Zeit im Seminar nicht mit Installationen verbringen.

---

## Reicht mein Rechner?

Kurz gesagt, für den Großteil des Seminars genügt ein normaler Laptop. Nur
die Visualisierung der 3D-Simulation ist anspruchsvoll und diese ist nicht zwingend erforderlich.

| | ROS-Grundlagen, eigene Nodes, RViz | Gazebo-Simulation |
| --- | --- | --- |
| Arbeitsspeicher | 8 GB | 16 GB |
| Freier Speicherplatz | 25 GB | 40 GB |
| Grafikkarte | egal, integriert reicht | dedizierte GPU empfohlen |

Ein Internetzugang ist einmalig für den Download des Images nötig, im
Uni-WLAN kann das eine Weile dauern, insbesondere wenn alle Studierenden gleichzeitig das Image herunterladen.

**Ohne dedizierte Grafikkarte** läuft Gazebo trotzdem, rendert dann aber auf
dem Prozessor und ruckelt entsprechend. Zum Ausprobieren reicht das, für
längeres Arbeiten wie das Erstellen einer Karte wird es zäh. Unter Linux und
Windows reicht `run.sh` eine vorhandene GPU automatisch an den Container
durch, unter macOS ist Software-Rendering technisch nicht zu umgehen.

**Wenn euer Rechner nicht mitkommt**, meldet euch rechtzeitig bei der
Seminarleitung. Dann bekommt ihr einen Leih-Laptop. Für die Termine mit den echten Robotern
ist die Verbindung mit NoMachine zu den Robotern ohnehin für alle der vorgesehene Weg, siehe
[docs/09-troubleshooting.md](docs/09-troubleshooting.md).

---

## Aufbau des Repositories

```text
labor-logistische-systeme/
├── .github/workflows/       build-images.yml, baut und pusht die Images
├── docker/                  Dockerfiles, werden von der CI gebaut
├── docs/                    Anleitungen
├── ws/src/                  hier entsteht euer Code
├── docker-compose.yml       Grundkonfiguration
├── docker-compose.vnc.yml   Ergänzung für die noVNC-Variante
├── docker-compose.wsl-gpu.yml   Ergänzung für GPU unter Windows/WSL
├── .env.example             nach .env kopieren
└── run.sh                   Startbefehl
```

Die beiden Ergänzungsdateien müsst ihr nicht selbst angeben, `run.sh` lädt
sie automatisch dazu, wenn sie gebraucht werden.

---

## Die drei Befehle für den Alltag

```bash
./run.sh                      # starten und Shell öffnen
docker compose exec ros bash  # weiteres Terminal
docker compose down           # stoppen
```

---

## Hinweise für Lehrende

Die ROS-Version ist an drei Stellen festgeschrieben und muss zur Version auf
den Robotern passen.

1. `docker/Dockerfile.base`, Zeile `FROM` und alle `ros-jazzy-*` Pakete
2. `docker/Dockerfile.sim`, alle `ros-jazzy-*` Pakete
3. Die Tags in `.env.example` und `docker-compose.yml`

Images werden per GitHub Action gebaut und nach `ghcr.io` geschoben, siehe
`.github/workflows/build-images.yml`. Studierende bauen nie selbst.
