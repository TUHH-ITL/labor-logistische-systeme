# Erste Schritte im Container

Diese Seite zeigt den Arbeitsablauf, der euch das ganze Semester begleitet.
Einmal durchgearbeitet dauert das ungefähr 20 Minuten.

---

## Das Grundprinzip

Der Container ist die Werkzeugkiste, nicht der Arbeitsplatz für eure Dateien.

```
Im Host-Dateisystem                        Im Container
labor-logistische-systeme/ws/src/     <-->   /home/ubuntu/ws/src/
```

Diese beiden Verzeichnisse sind dasselbe. Ihr könnt also auf dem Host mit
VS Code editieren und im Container bauen und ausführen. Euer Code überlebt
jedes Löschen des Containers.

**Unter Windows** ist "Host-Dateisystem" das Linux-Dateisystem in WSL, nicht
das normale Windows-Dateisystem. Die Datei taucht also nicht unter
`C:\Users\...` auf, sondern nur unter `~/labor-logistische-systeme/ws/src`
in Ubuntu beziehungsweise über `\\wsl$\Ubuntu-24.04\...` in Windows, siehe
`docs/02-setup-windows.md`, Schritt 4.

Alles andere im Container ist flüchtig. Das ist wichtig und der häufigste
Stolperstein, siehe unten.

## Schritt 1, Umgebung starten

```bash
cd ~/labor-logistische-systeme
./run.sh
```

## Schritt 2, Eigenes Paket anlegen

Im Container.

```bash
cd ~/ws/src
ros2 pkg create --build-type ament_python mein_paket --dependencies rclpy std_msgs
```

Es entsteht ein Verzeichnis `mein_paket`, das ihr auch auf dem Host sofort
sehen könnt.

## Schritt 3, Eine Node schreiben

```bash
nano ~/ws/src/mein_paket/mein_paket/hallo_node.py
```

Inhalt.

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String


class HalloNode(Node):
    def __init__(self):
        super().__init__("hallo_node")
        self.publisher = self.create_publisher(String, "hallo", 10)
        self.timer = self.create_timer(1.0, self.senden)
        self.zaehler = 0

    def senden(self):
        nachricht = String()
        nachricht.data = f"Hallo aus dem Container, Nachricht {self.zaehler}"
        self.publisher.publish(nachricht)
        self.get_logger().info(nachricht.data)
        self.zaehler += 1


def main():
    rclpy.init()
    node = HalloNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
```

## Schritt 4, Einstiegspunkt eintragen

In `~/ws/src/mein_paket/setup.py` den Abschnitt `entry_points` ergänzen.

```python
entry_points={
    "console_scripts": [
        "hallo_node = mein_paket.hallo_node:main",
    ],
},
```

## Schritt 5, Bauen

```bash
cd ~/ws
colcon build --symlink-install
source install/setup.bash
```

`--symlink-install` ist im Seminar der Standard. Damit wirken Änderungen an
bestehenden Python-Dateien sofort, ohne erneutes Bauen.

Neu bauen müsst ihr trotzdem, wenn ihr.

- einen neuen Einstiegspunkt in `setup.py` ergänzt
- eine neue Launch-Datei hinzufügt
- ein neues Paket anlegt
- Abhängigkeiten in `package.xml` ändert

## Schritt 6, Ausführen

```bash
ros2 run mein_paket hallo_node
```

In einem zweiten Terminal auf dem Host.

```bash
cd ~/labor-logistische-systeme
docker compose exec ros bash
ros2 topic echo /hallo
```

---

## Der wichtigste Stolperstein

Alles, was ihr **im laufenden Container** installiert, ist beim nächsten Start
wieder weg.

```bash
sudo apt install ros-jazzy-irgendwas   # verschwindet
pip install numpy                       # verschwindet
```

Das führt zum typischen Muster "gestern lief es, heute nicht mehr", ohne dass
jemand einen Zusammenhang sieht. Deklariert Abhängigkeiten stattdessen richtig.

**ROS-Pakete** gehören in `package.xml`.

```xml
<depend>apriltag_ros</depend>
<depend>nav2_simple_commander</depend>
```

Danach im Container.

```bash
cd ~/ws
rosdep install --from-paths src --ignore-src -r -y
```

**Python-Bibliotheken** gehören in `ws/src/requirements.txt`. Installieren mit.

```bash
pip install --user -r ~/ws/src/requirements.txt
```

Braucht ihr etwas dauerhaft für alle, meldet euch bei der Seminarleitung. Dann
kommt es ins Image und alle Gruppen haben es nach einem `docker compose pull`.

## Aufräumen

```bash
docker compose down       # Container stoppen, Build bleibt erhalten
docker compose down -v    # zusätzlich build und install löschen
```

`down -v` löscht **nicht** euren Quellcode in `ws/src`. Es ist der saubere
Weg, wenn ein Build in einen unklaren Zustand geraten ist.
