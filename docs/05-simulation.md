# Simulation

Bevor ihr an einen echten TurtleBot dürft, testet ihr eure Nodes gegen eine
Simulation. Diese Seite zeigt zwei Stufen, turtlesim als schnellen Test ohne
Zusatzsoftware, danach Gazebo mit einem simulierten TurtleBot4.

---

## turtlesim, ohne Umbau

turtlesim ist im normalen `jazzy-base`-Image bereits enthalten, dafür ist
kein Wechsel des `IMAGE_TAG` nötig.

Im laufenden Container.

```bash
ros2 run turtlesim turtlesim_node
```

Es öffnet sich ein Fenster mit einer Schildkröte. In einem zweiten Terminal
(`docker compose exec ros bash`) steuert ihr sie.

```bash
ros2 run turtlesim turtle_teleop_key
```

Mit den Pfeiltasten fahren, das Fenster mit `turtlesim_node` muss dabei den
Fokus haben, nicht das Terminal. Funktioniert das, laufen Grafikausgabe und
Tastatureingabe zwischen Host und Container einwandfrei, bevor ihr euch an
Gazebo wagt.

---

## Gazebo mit TurtleBot4

Dafür braucht ihr das Simulations-Image.

## Schritt 1, Simulations-Image aktivieren

In der `.env`.

```dotenv
IMAGE_TAG=jazzy-sim
```

Neu starten.

```bash
docker compose down
docker compose pull
./run.sh
```

## Schritt 2, Gazebo starten

```bash
ros2 launch turtlebot4_gz_bringup turtlebot4_gz.launch.py
```

Es öffnet sich ein Gazebo-Fenster mit einer simulierten Arena und einem
TurtleBot4 darin. Der erste Start dauert spürbar länger als spätere, Gazebo
lädt dabei Modelle und Texturen.

## Schritt 3, Roboter fahren

In einem zweiten Terminal.

```bash
docker compose exec ros bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -p stamped:=true -p frame_id:=base_link
```

Die Parameter sind nötig, weil der TurtleBot4 (ros2_control-basiert)
`geometry_msgs/msg/TwistStamped` erwartet, `teleop_twist_keyboard` aber ohne
sie das ältere `geometry_msgs/msg/Twist` sendet. Beide haben denselben
Topic-Namen `/cmd_vel`, aber unterschiedlichen Typ, wodurch ROS 2 sie als
inkompatibel behandelt und der Roboter sich ohne die Parameter nicht rührt.

Steuerung über die im Terminal angezeigten Tasten. Der Roboter muss sich in
Gazebo entsprechend bewegen.

## Ressourcen

Gazebo ist deutlich anspruchsvoller als turtlesim. Ruckelt es stark oder
stürzt der Container ab, liegt das meist an zu wenig Arbeitsspeicher.

- **Docker Desktop** (Windows, macOS), unter *Settings, Resources* mehr
  Arbeitsspeicher zuweisen, mindestens 8 GB, mit Gazebo eher 16 GB.
- **Unter Windows zusätzlich** die WSL-eigene Grenze prüfen, standardmäßig
  die Hälfte des Systemspeichers. Erhöhen über eine Datei
  `%UserProfile%\.wslconfig`.

  ```ini
  [wsl2]
  memory=16GB
  ```

  Danach in PowerShell `wsl --shutdown` und die Ubuntu-Distribution neu
  öffnen.

Bleibt es zu langsam, siehe `docs/09-troubleshooting.md`.

---

Weiter geht es mit den eigentlichen Aufgaben aus dem Seminarplan.
