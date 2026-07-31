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