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

## Aufbau des Repositories

```
labor-logistische-systeme/
├── .devcontainer/       devcontainer.json für VS Code Dev Containers
├── .github/workflows/   build-images.yml, baut und pusht die Images
├── docker/              Dockerfiles, werden von der CI gebaut
├── docs/                Anleitungen
├── ws/src/              hier entsteht euer Code
├── docker-compose.yml
├── .env.example         nach .env kopieren
└── run.sh               Startbefehl
```

---

## Die drei Befehle für den Alltag

```bash
./run.sh                      # starten und Shell öffnen
docker compose exec ros bash  # weiteres Terminal
docker compose down           # stoppen
```

---

## Systemvoraussetzungen

- 25 GB freier Speicherplatz, mit Simulation 40 GB
- 8 GB Arbeitsspeicher, mit Simulation 16 GB empfohlen
- Internetzugang für den einmaligen Download des Images

---

## Hinweise für Lehrende

Die ROS-Version ist an drei Stellen festgeschrieben und muss zur Version auf
den Robotern passen.

1. `docker/Dockerfile.base`, Zeile `FROM` und alle `ros-jazzy-*` Pakete
2. `docker/Dockerfile.sim`, alle `ros-jazzy-*` Pakete
3. Die Tags in `.env.example` und `docker-compose.yml`

Images werden per GitHub Action gebaut und nach `ghcr.io` geschoben, siehe
`.github/workflows/build-images.yml`. Studierende bauen nie selbst.
