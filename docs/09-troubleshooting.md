# Troubleshooting

Wenn ein Problem hier nicht steht, meldet es bitte als Issue im Repository.
Das Dokument lebt davon.

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

**OpenGL-Fehler**, etwa `Could not initialize GLX` oder ein schwarzes
RViz-Fenster. In der `.env` setzen.

```dotenv
LIBGL_ALWAYS_SOFTWARE=1
```

Danach `docker compose down && ./run.sh`. Läuft langsamer, aber stabil.

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

## Unter macOS lädt `http://localhost:6080` nicht (noVNC)

`docker compose exec ros bash` funktioniert, im Browser tut sich bei
`http://localhost:6080` aber nichts. Prüfen mit `docker compose ps`, ob der
Container überhaupt läuft.

Ursache ist praktisch immer, dass **Enable host networking** in Docker
Desktop nicht aktiviert ist, siehe `docs/03-setup-macos.md`, Schritt 1. Ohne
diese Einstellung landet `network_mode: host` nur im Netz der
Docker-Desktop-VM und nie beim eigentlichen Mac. Unter *Settings, Resources,
Network* aktivieren, *Apply & restart*, danach `docker compose down &&
docker compose up -d`.

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
