# Erste Schritte im Container

Diese Seite zeigt den Arbeitsablauf, der euch das ganze Semester begleitet.
Einmal durchgearbeitet dauert das ungefähr 20 Minuten.

---

## Das Grundprinzip

Der Container ist die Werkzeugkiste, nicht der Arbeitsplatz für eure Dateien.

```text
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

Es entsteht ein Verzeichnis `mein_paket`. Angelegt habt ihr es im Container,
sichtbar ist es aber sofort überall, weil `ws/src` nur einmal existiert und
in den Container hineingereicht wird.

| Wo ihr nachschaut | Pfad |
| --- | --- |
| Container-Terminal | `~/ws/src/mein_paket` |
| Ubuntu-Terminal | `~/labor-logistische-systeme/ws/src/mein_paket` |
| Windows-Explorer | `\\wsl$\Ubuntu-24.04\home\<benutzername>\labor-logistische-systeme\ws\src\mein_paket` |

Das sind drei Sichten auf dieselben Dateien, keine Kopien.

## Schritt 3, Eine Node schreiben

Am einfachsten in VS Code, siehe `docs/02-setup-windows.md`, Schritt 10
(unter Linux und macOS analog mit `code .` im Repo-Verzeichnis). Legt darin
folgende Datei an, sie existiert noch nicht.

```text
~/ws/src/mein_paket/mein_paket/hallo_node.py
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

Damit ROS eure Node später mit `ros2 run` starten kann, muss sie in
`~/ws/src/mein_paket/setup.py` eingetragen werden.

Den Abschnitt `entry_points` hat `ros2 pkg create` bereits angelegt, seine
Liste `console_scripts` ist nur noch leer. Sie steht am Ende der Datei und
sieht so aus.

```python
    entry_points={
        'console_scripts': [
        ],
    },
```

Ihr ergänzt dort **eine Zeile**, sodass es danach so aussieht.

```python
    entry_points={
        'console_scripts': [
            'hallo_node = mein_paket.hallo_node:main',
        ],
    },
```

Gemeint ist damit: Der Befehl `hallo_node` startet im Modul
`mein_paket.hallo_node` die Funktion `main`.

## Schritt 5, Bauen

```bash
cd ~/ws
colcon build --symlink-install
source install/setup.bash
```

`--symlink-install` ist im Seminar der Standard. Damit wirken Änderungen an
bestehenden Python-Dateien sofort, ohne erneutes Bauen.

**Ohne `sudo` ausführen.** Bricht der Befehl mit `Permission denied` ab,
stammt euer Container noch aus einer älteren Image-Version. `sudo` würde das
scheinbar beheben, aber Dateien erzeugen, die euch anschließend nicht mehr
gehören. Richtig ist stattdessen **einmalig**:

```bash
exit                      # zurück ins Ubuntu-Terminal
docker compose down -v
docker compose pull
./run.sh
```

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

**ROS-Pakete** gehören in die `package.xml` eures Pakets, dort zwischen die
schon vorhandenen `<depend>`-Zeilen.

```xml
<depend>apriltag_ros</depend>
<depend>nav2_simple_commander</depend>
```

Danach im Container.

```bash
cd ~/ws
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
```

**Python-Bibliotheken** gehören in eine Datei `ws/src/requirements.txt`.
Die gibt es anfangs noch nicht, ihr legt sie beim ersten Bedarf selbst an,
zum Beispiel in VS Code. Hineingeschrieben wird pro Zeile ein Paketname, so
wie ihr ihn auch `pip install` übergeben würdet.

```text
numpy
matplotlib
opencv-python==4.10.0.84
```

Eine Version anzugeben (`==4.10.0.84`) ist optional, sorgt aber dafür, dass
bei allen in der Gruppe wirklich dasselbe installiert wird. Installiert wird
daraus mit.

```bash
pip install --user -r ~/ws/src/requirements.txt
```

**Nach jeder Änderung an `package.xml` neu bauen**, sonst kennt euer
Workspace die neue Abhängigkeit nicht. Für `requirements.txt` genügt der
`pip install`-Befehl oben, ein Neubau ist dafür nicht nötig.

Braucht ihr etwas dauerhaft für alle, meldet euch bei der Seminarleitung. Dann
kommt es ins Image und alle Gruppen haben es nach einem `docker compose pull`.

## Aufräumen

Diese Befehle gehören ins **Ubuntu-Terminal**, nicht ins Container-Terminal.
Steht euer Prompt auf `[seminar] ~/ws$`, verlasst den Container zuerst mit
`exit`, oder nutzt ein zweites Ubuntu-Terminal. Außerdem müsst ihr im
Repo-Verzeichnis stehen.

```bash
cd ~/labor-logistische-systeme
docker compose down       # Container stoppen, Build bleibt erhalten
docker compose down -v    # zusätzlich build und install löschen
```

`down -v` löscht **nicht** euren Quellcode in `ws/src`. Es ist der saubere
Weg, wenn ein Build in einen unklaren Zustand geraten ist.

Weiter geht es mit `docs/05-simulation.md`.
