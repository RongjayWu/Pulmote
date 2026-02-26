import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io' show Platform;
import '../core/constants/api_constants.dart';

/// MQTT connection state
enum MqttConnectionState { disconnected, connecting, connected }

/// Provides MQTT client for the app
final mqttServiceProvider = Provider<MqttService>((ref) {
  return MqttService();
});

class MqttService {
  MqttClient? _client;
  MqttConnectionState _state = MqttConnectionState.disconnected;

  MqttConnectionState get state => _state;

  /// Connect to MQTT broker via WSS
  Future<bool> connect({
    required String username,
    required String password,
  }) async {
    if (_state == MqttConnectionState.connected) return true;
    _state = MqttConnectionState.connecting;

    try {
      // Use server client with websocket for mobile
      final client = MqttServerClient.withPort(
        'wss://mqtt.koimsurai.com',
        'pulmote-app-${DateTime.now().millisecondsSinceEpoch}',
        443,
      );

      client.useWebSocket = true;
      client.secure = true;
      client.autoReconnect = true;
      client.resubscribeOnAutoReconnect = true;
      client.keepAlivePeriod = 30;
      client.connectTimeoutPeriod = 10000;
      client.logging(on: false);

      client.onConnected = () {
        _state = MqttConnectionState.connected;
      };

      client.onDisconnected = () {
        _state = MqttConnectionState.disconnected;
      };

      client.onAutoReconnect = () {
        _state = MqttConnectionState.connecting;
      };

      client.onAutoReconnected = () {
        _state = MqttConnectionState.connected;
      };

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(client.clientIdentifier)
          .authenticateAs(username, password)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      client.connectionMessage = connMessage;

      await client.connect();
      _client = client;
      _state = MqttConnectionState.connected;
      return true;
    } catch (e) {
      _state = MqttConnectionState.disconnected;
      return false;
    }
  }

  /// Publish IR command to device
  void sendIrCommand(String deviceTopic, Map<String, dynamic> payload) {
    if (_client == null || _state != MqttConnectionState.connected) return;

    final topic = '${ApiConstants.mqttTopicPrefix}/$deviceTopic/ir/send';
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(payload));

    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  /// Request IR recording from device
  void requestRecord(String deviceTopic) {
    if (_client == null || _state != MqttConnectionState.connected) return;

    final topic = '${ApiConstants.mqttTopicPrefix}/$deviceTopic/ir/record';
    final builder = MqttClientPayloadBuilder();
    builder.addString(
      jsonEncode({
        'action': 'record',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
    );

    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  /// Subscribe to topic and listen for messages
  Stream<MqttReceivedMessage<MqttMessage>>? subscribe(String topic) {
    if (_client == null || _state != MqttConnectionState.connected) return null;

    _client!.subscribe(topic, MqttQos.atLeastOnce);
    // 將 List<MqttReceivedMessage<MqttMessage>> 展開為單一訊息
    return _client!.updates?.expand((list) => list);
  }

  /// Disconnect
  void disconnect() {
    _client?.disconnect();
    _state = MqttConnectionState.disconnected;
  }
}
