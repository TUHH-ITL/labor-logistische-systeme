# Troubleshooting

Wenn ein Problem hier nicht steht, meldet es bitte als Issue im Repository.
Das Dokument lebt davon.

---

## Kurz vorweg, "Permission denied" nicht mit sudo erschlagen

Die Versuchung ist groß, bei jedem `Permission denied` einfach `sudo`
davorzusetzen. Im Seminar macht das die Sache fast immer schlimmer, weil
danach Dateien root gehören und ihr sie als normaler Benutzer nicht mehr
bearbeiten könnt. Der Fehler kommt dann später wieder, nur schwerer
auffindbar.

| Wo der Fehler auftritt | Richtige Lösung |
| --- | --- |
| `docker ...` auf dem Host | Benutzer in die Gruppe `docker`, siehe nächster Abschnitt |
| `colcon build` im Container | Volumes zurücksetzen, siehe "colcon build meldet Permission denied" |
| `apt-get install` auf dem Host | Hier ist `sudo` richtig und vorgesehen |

Faustregel: `sudo` gehört nur zu den Installationsbefehlen des Setups. Im
Container und bei allem rund um `colcon` und euren eigenen Code niemals.

---

## permission denied while trying to connect to the Docker daemon socket

Der Benutzer ist nicht in der Docker-Gruppe oder war es beim Anmelden noch
nicht.

```bash
sudo usermod -aG docker $USER
```

Danach vollständig ab- und wieder anmelden. Ein neues Terminal genügt nicht.

---

## Grafische Programme starten nicht

Fehlermeldungen wie `cannot open display`, `qt.qpa.xcb: could not connect to
display` oder ein sofortiger Absturz von RViz.

**Unter Linux**, auf dem Host ausführen.

```bash
xhost +local:docker
echo $DISPLAY      # muss etwas wie :0 oder :1 ausgeben
```

Ist `$DISPLAY` leer, läuft eventuell eine Wayland-Sitzung ohne XWayland.
Dann bei der Anmeldung "Ubuntu on Xorg" wählen.

**OpenGL- und Treiberfehler**, etwa `Could not initialize GLX`, ein
schwarzes RViz-Fenster oder diese Meldungen.

```text
MESA: error: Failed to query drm device.
glx: failed to create dri3 screen
failed to load driver: iris
```

Der Grafiktreiber des Hosts lässt sich im Container nicht nutzen, häufig bei
Intel-GPUs, deren Treiber `iris` dort nicht greift. Lösung ist
Software-Rendering. Dauerhaft in der `.env` im Repo-Verzeichnis setzen.

```dotenv
LIBGL_ALWAYS_SOFTWARE=1
```

Danach im Ubuntu-Terminal `docker compose down && ./run.sh`. Läuft
langsamer, aber stabil.

Zum schnellen Ausprobieren, ohne die `.env` zu ändern, geht auch einmalig im
Container.

```bash
LIBGL_ALWAYS_SOFTWARE=1 rviz2
```

Die `.bashrc` müsst ihr dafür **nicht** anpassen. Die `.env` genügt, weil
`docker-compose.yml` die Variable an den Container weitergibt.

**Unter Windows** WSL aktualisieren.

```powershell
wsl --update
wsl --shutdown
```

---

## Gazebo ruckelt stark, Simulation ist sehr langsam

Prüfen, ob überhaupt eine GPU genutzt wird (`mesa-utils` ist im
Simulations-Image installiert).

```bash
glxinfo | grep "OpenGL renderer"
```

Steht dort **llvmpipe** oder **softpipe**, läuft alles über
Software-Rendering, das erklärt die Langsamkeit direkt.

**Unter Windows/WSL** übernimmt `run.sh` die GPU-Durchreichung automatisch,
sobald es das WSL-GPU-Gerät `/dev/dxg` findet, siehe
`docker-compose.wsl-gpu.yml`. Zeigt `glxinfo -B` trotzdem `llvmpipe`, prüft
der Reihe nach.

1. **Startet ihr über `./run.sh`?** Ein direktes `docker compose up` lädt die
   GPU-Ergänzung nicht mit.
2. **Falsche Grafikkarte gewählt.** Auf Notebooks mit zwei Grafikkarten nimmt
   WSL sonst die sparsame integrierte. `GPU_ADAPTER` in der `.env` setzen,
   siehe `.env.example`, danach `docker compose down && ./run.sh`. Zeigt
   `glxinfo -B` dann `D3D12 (Intel...)` statt eurer dedizierten Karte, passt
   der Name nicht.
3. **Sieht WSL die GPU überhaupt?** Außerhalb des Containers, im
   Ubuntu-Terminal.

   ```bash
   GALLIUM_DRIVER=d3d12 glxinfo -B
   ```

   Steht dort `Accelerated: no`, liegt es nicht am Container, sondern an
   WSL selbst. Dann in PowerShell `wsl --update`, danach `wsl --shutdown`,
   und die Grafiktreiber unter Windows aktualisieren, am besten direkt von
   der Herstellerseite statt über Windows Update.

Wichtig, `GALLIUM_DRIVER=d3d12` ist bei aktuellem Mesa zwingend. Ohne die
Variable fällt Mesa auf `llvmpipe` zurück, obwohl die GPU verfügbar wäre.

**Unter macOS** ist Software-Rendering unvermeidbar, Docker Desktop gibt
dort keine GPU an Container weiter, siehe `docs/03-setup-macos.md`.

**Unter macOS** ist Software-Rendering unvermeidbar, Docker Desktop gibt
dort keine GPU an Container weiter, siehe `docs/03-setup-macos.md`.

---

## Roboter bewegt sich nicht, obwohl Teleop läuft

`ros2 topic echo /cmd_vel` zeigt bei Tastendruck nichts an, obwohl
`teleop_twist_keyboard` läuft und die Geschwindigkeit ändert.

Ursache ist ein Typkonflikt auf demselben Topic-Namen. Der TurtleBot4 ist
ros2_control-basiert und erwartet auf `/cmd_vel` den Typ
`geometry_msgs/msg/TwistStamped`. `teleop_twist_keyboard` sendet ohne
Zusatzparameter aber das ältere `geometry_msgs/msg/Twist`. Gleicher
Topic-Name, unterschiedlicher Typ, ROS 2 behandelt das als inkompatibel.

Prüfen mit `ros2 topic info /cmd_vel --verbose`, welcher Typ vom
Fahr-Controller (`motion_control`) abonniert wird. Fix, `teleop_twist_keyboard`
mit gestempelten Nachrichten starten.

```bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -p stamped:=true -p frame_id:=base_link
```

---

## noVNC zeigt nur eine Dateiliste statt des Desktops

Im Browser erscheint "Directory listing for /" mit ein paar HTML-Dateien.
Das ist kein Fehler, dem Webserver fehlt nur eine Startseite. Ruft die
vollständige Adresse auf.

```text
http://localhost:6080/vnc.html
```

---

## `http://localhost:6080/vnc.html` lädt gar nicht (noVNC)

Zuerst prüfen, ob der Container läuft und der Port veröffentlicht ist.

```bash
cd ~/labor-logistische-systeme
docker compose ps
```

In der Spalte PORTS muss `127.0.0.1:6080->6080/tcp` stehen. Fehlt die Zeile
ganz, wurde die Umgebung ohne die noVNC-Konfiguration gestartet. Das
passiert, wenn ihr von Hand `docker compose up -d` aufruft statt `./run.sh`.
Nur `run.sh` lädt die Datei `docker-compose.vnc.yml` dazu, die den Port
freigibt.

```bash
docker compose down
./run.sh
```

Steht in der `.env` kein `IMAGE_TAG` mit `vnc`, greift die noVNC-Variante
ebenfalls nicht. Kontrollieren mit `grep IMAGE_TAG .env`, dort muss
`jazzy-vnc` oder `jazzy-vnc-sim` stehen.

---

## no matching manifest for linux/arm64/v8

```text
Error response from daemon: no matching manifest for linux/arm64/v8
in the manifest list entries
```

Ihr nutzt einen Mac mit Apple Silicon (M1 bis M4) und habt in der `.env`
einen Image-Tag gesetzt, den es nur für Intel-Prozessoren gibt. Das betrifft
`jazzy-sim` und `jazzy-vnc-sim`, also die beiden Varianten mit Gazebo.

Setzt in der `.env` stattdessen `IMAGE_TAG=jazzy-vnc`. Alles außer der
Gazebo-Simulation funktioniert damit normal. Für die Simulationsaufgaben
siehe `docs/03-setup-macos.md`, Abschnitt "Gazebo auf Apple Silicon".

---

## ros2 topic list zeigt nichts, obwohl eine Node läuft

Fast immer eine von drei Ursachen.

1. **Zwei getrennte Container.** Prüfen mit `docker ps`. Es darf nur ein
   `seminar-ros` laufen. Weitere Terminals immer mit
   `docker compose exec ros bash` öffnen, nie mit `docker run`.
2. **Unterschiedliche ROS_DOMAIN_ID.** Im Container prüfen mit
   `echo $ROS_DOMAIN_ID`. Muss in allen Terminals gleich sein.
3. **Overlay nicht gesourced.** `source ~/ws/install/setup.bash` ausführen.

---

## Ihr seht die Topics einer anderen Gruppe

Zwei Gruppen nutzen dieselbe `ROS_DOMAIN_ID`. Das ist im Labor gefährlich,
weil Fahrbefehle beim falschen Roboter landen können. Zuordnung in der `.env`
korrigieren und Container neu starten.

---

## Der TurtleBot wird nicht gefunden

Zuerst die Grundlagen prüfen.

```bash
ping <ip-des-roboters>          # erreichbar?
echo $ROS_DOMAIN_ID             # gleich wie auf dem Roboter?
ros2 daemon stop && ros2 daemon start
ros2 topic list
```

Bleibt die Liste leer, obwohl der Ping funktioniert, liegt es meist am
Netzwerkmodus.

**Unter Linux nativ** muss `network_mode: host` greifen. Prüfen mit.

```bash
docker inspect seminar-ros --format '{{.HostConfig.NetworkMode}}'
```

Es muss `host` ausgegeben werden.

**Unter Docker Desktop (Windows und macOS)** läuft der Container in einer
virtuellen Maschine. Die DDS-Erkennung über das WLAN funktioniert dort nicht
verlässlich, und daran lässt sich von eurer Seite nichts reparieren. Für die
Robotertermine bitte einen Leih-Laptop mit Linux nutzen oder per NoMachine auf
einem Laborrechner arbeiten.

**Eduroam und Gastnetze** blockieren häufig die Kommunikation zwischen
Endgeräten. Nutzt im Labor ausschließlich das dafür vorgesehene WLAN.

---

## colcon build meldet Permission denied

```text
PermissionError: [Errno 13] Permission denied: 'log/build_...'
```

Euer Container stammt noch aus einer älteren Image-Version, in der die
Verzeichnisse `build`, `install` und `log` root gehörten. **Nicht mit `sudo`
bauen**, das erzeugt Dateien, die euch anschließend nicht mehr gehören.
Stattdessen einmalig im Ubuntu-Terminal.

```bash
cd ~/labor-logistische-systeme
docker compose down -v
docker compose pull
./run.sh
```

Danach `colcon build --symlink-install` ohne `sudo` erneut ausführen. `down -v`
löscht nur Build-Artefakte, euer Quellcode in `ws/src` bleibt erhalten.

---

## colcon build schlägt nach einem Wechsel des Rechners fehl

Build-Artefakte aus einer anderen Umgebung. Zurücksetzen mit.

```bash
docker compose down -v
./run.sh
cd ~/ws && colcon build --symlink-install
```

Der Quellcode in `ws/src` bleibt dabei unberührt.

---

## Änderungen an einer Python-Datei wirken nicht

Wurde ohne `--symlink-install` gebaut, liegt im `install`-Verzeichnis eine
Kopie statt eines Verweises. Einmal sauber neu bauen.

```bash
cd ~/ws
rm -rf build install log
colcon build --symlink-install
source install/setup.bash
```

---

## Es lief gestern und heute nicht mehr

Sehr wahrscheinlich wurde etwas interaktiv im Container installiert, siehe
`docs/04-erste-schritte.md`, Abschnitt "Der wichtigste Stolperstein".
Abhängigkeiten gehören in `package.xml` oder `requirements.txt`.

---

## Der Container beendet sich von selbst

Ihr arbeitet, plötzlich ist die Shell weg oder `ros2`-Befehle laufen ins
Leere. Zuerst nachsehen, warum.

```bash
cd ~/labor-logistische-systeme
docker compose ps -a
docker inspect seminar-ros --format 'ExitCode={{.State.ExitCode}} OOMKilled={{.State.OOMKilled}}'
```

Die Ausgabe sagt euch, was los war.

| Ausgabe | Bedeutung | Abhilfe |
| --- | --- | --- |
| `OOMKilled=true` oder `ExitCode=137` | Dem Container ging der Arbeitsspeicher aus, typisch bei Gazebo | Docker Desktop mehr RAM zuweisen, siehe unten |
| `ExitCode=0` | Der Hauptprozess wurde regulär beendet, meist durch `exit` im **allerersten** Terminal oder `Strg+C` bei `docker compose up` ohne `-d` | Mit `./run.sh` neu starten |
| `ExitCode=130` oder `143` | Von außen abgebrochen, etwa beim Beenden von Docker Desktop | Mit `./run.sh` neu starten |

**Bei zu wenig Arbeitsspeicher**, also der häufigste Fall unter macOS und
Windows, unter *Settings, Resources* in Docker Desktop mehr zuweisen. Für
Gazebo sind 16 GB realistisch, mit 8 GB wird es eng. Unter Windows zusätzlich
die WSL-Grenze in `%UserProfile%\.wslconfig` prüfen, siehe
`docs/05-simulation.md`, Abschnitt "Ressourcen".

Seit der Einführung der Restart-Policy in der `docker-compose.yml` startet
der Container nach einem Absturz oder einem Neustart von Docker Desktop von
selbst wieder. Beendet ihr ihn absichtlich mit `docker compose down` oder
`docker compose stop`, bleibt er aus.

---

## docker compose up startet nach einem down nicht mehr

Nach `docker compose down` legt der nächste Start keinen Container mehr an,
oder es kommen Fehler über Netzwerke und Endpunkte, die es angeblich schon
gibt. Das ist ein bekannter Hänger von Docker Desktop, nicht euer Fehler.

**Docker Desktop komplett neu starten.** Rechtsklick auf das Wal-Icon,
*Quit Docker Desktop*, dann die App neu öffnen und warten, bis sie
vollständig gestartet ist. Danach.

```bash
cd ~/labor-logistische-systeme
./run.sh
```

Hilft das nicht, einmal aufräumen und neu starten.

```bash
docker compose down --remove-orphans
docker network prune -f
./run.sh
```

Euer Quellcode in `ws/src` ist davon nicht betroffen.

---

## Kein Speicherplatz mehr

Docker-Images und alte Container belegen viel Platz.

```bash
docker system df       # Übersicht
docker system prune -a # löscht alle nicht genutzten Images
```

Achtung, danach muss das Seminar-Image erneut geladen werden.

---

## colcon build bricht mit "Killed" ab

Zu wenig Arbeitsspeicher, typisch unter Docker Desktop. Entweder die
Speicherzuweisung in den Docker-Desktop-Einstellungen erhöhen oder die
Parallelität begrenzen.

```bash
MAKEFLAGS="-j2" colcon build --symlink-install --parallel-workers 2
```
