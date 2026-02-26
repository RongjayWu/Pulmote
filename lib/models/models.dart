class User {
  final String id;
  final String username;
  final String? displayName;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    this.displayName,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

class Device {
  final String id;
  final String userId;
  final String name;
  final String deviceType;
  final String mqttTopic;
  final bool isOnline;
  final DateTime? lastSeen;

  Device({
    required this.id,
    required this.userId,
    required this.name,
    required this.deviceType,
    required this.mqttTopic,
    required this.isOnline,
    this.lastSeen,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'] as String,
        userId: json['userId'] as String? ?? json['user_id'] as String,
        name: json['name'] as String,
        deviceType: json['deviceType'] as String? ??
            json['device_type'] as String? ??
            'ir_blaster',
        mqttTopic: json['mqttTopic'] as String? ?? json['mqtt_topic'] as String,
        isOnline: json['isOnline'] as bool? ?? json['is_online'] as bool? ?? false,
        lastSeen: json['lastSeen'] != null
            ? DateTime.parse(json['lastSeen'] as String)
            : json['last_seen'] != null
                ? DateTime.parse(json['last_seen'] as String)
                : null,
      );
}

class Remote {
  final String id;
  final String userId;
  final String deviceId;
  final String name;
  final String icon;
  final int sortOrder;

  Remote({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.name,
    required this.icon,
    required this.sortOrder,
  });

  factory Remote.fromJson(Map<String, dynamic> json) => Remote(
        id: json['id'] as String,
        userId: json['userId'] as String? ?? json['user_id'] as String,
        deviceId: json['deviceId'] as String? ?? json['device_id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? 'remote',
        sortOrder: json['sortOrder'] as int? ?? json['sort_order'] as int? ?? 0,
      );
}

class IrSignal {
  final String id;
  final String remoteId;
  final String name;
  final String icon;
  final dynamic rawData;
  final String? protocol;
  final int frequency;
  final int sortOrder;

  IrSignal({
    required this.id,
    required this.remoteId,
    required this.name,
    required this.icon,
    required this.rawData,
    this.protocol,
    required this.frequency,
    required this.sortOrder,
  });

  factory IrSignal.fromJson(Map<String, dynamic> json) => IrSignal(
        id: json['id'] as String,
        remoteId: json['remoteId'] as String? ?? json['remote_id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? 'power',
        rawData: json['rawData'] ?? json['raw_data'],
        protocol: json['protocol'] as String?,
        frequency: json['frequency'] as int? ?? 38000,
        sortOrder: json['sortOrder'] as int? ?? json['sort_order'] as int? ?? 0,
      );
}
