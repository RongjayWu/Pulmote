/// 智能設備模型類
class SmartDevice {
  final String id;
  final String name;
  final String icon;
  final String type;
  bool isOn;
  int brightness;
  int temperature;

  SmartDevice({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    this.isOn = false,
    this.brightness = 50,
    this.temperature = 20,
  });
}
