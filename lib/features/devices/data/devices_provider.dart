import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../services/api_client.dart';

// All devices for current user
final devicesProvider =
    AsyncNotifierProvider<DevicesNotifier, List<Device>>(DevicesNotifier.new);

class DevicesNotifier extends AsyncNotifier<List<Device>> {
  @override
  Future<List<Device>> build() async {
    final dio = ref.read(dioProvider);
    final res = await dio.get('/devices');
    return (res.data as List).map((e) => Device.fromJson(e)).toList();
  }

  Future<Device> addDevice({
    required String name,
    required String mqttTopic,
    String deviceType = 'ir_blaster',
  }) async {
    final dio = ref.read(dioProvider);
    final res = await dio.post('/devices', data: {
      'name': name,
      'mqttTopic': mqttTopic,
      'deviceType': deviceType,
    });
    final device = Device.fromJson(res.data);
    state = AsyncData([...state.value ?? [], device]);
    return device;
  }

  Future<void> deleteDevice(String id) async {
    final dio = ref.read(dioProvider);
    await dio.delete('/devices/$id');
    state = AsyncData(
      (state.value ?? []).where((d) => d.id != id).toList(),
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Remotes for a specific device
final remotesForDeviceProvider =
    FutureProvider.family<List<Remote>, String>((ref, deviceId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/remotes/by-device/$deviceId');
  return (res.data as List).map((e) => Remote.fromJson(e)).toList();
});

// All remotes for current user
final allRemotesProvider = FutureProvider<List<Remote>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/remotes');
  return (res.data as List).map((e) => Remote.fromJson(e)).toList();
});
