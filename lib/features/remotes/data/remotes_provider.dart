import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../services/api_client.dart';

// Signals for a remote
final signalsProvider =
    FutureProvider.family<List<IrSignal>, String>((ref, remoteId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/signals', queryParameters: {'remoteId': remoteId});
  return (res.data as List).map((e) => IrSignal.fromJson(e)).toList();
});

// Create remote
Future<Remote> createRemote(
  ProviderRef ref, {
  required String deviceId,
  required String name,
  String icon = 'remote',
}) async {
  final dio = ref.read(dioProvider);
  final res = await dio.post('/remotes', data: {
    'deviceId': deviceId,
    'name': name,
    'icon': icon,
  });
  return Remote.fromJson(res.data);
}

// Delete remote
Future<void> deleteRemote(ProviderRef ref, String id) async {
  final dio = ref.read(dioProvider);
  await dio.delete('/remotes/$id');
}

// Send IR signal via API (which publishes to MQTT)
Future<void> sendSignal(ProviderRef ref, String signalId) async {
  final dio = ref.read(dioProvider);
  await dio.post('/signals/$signalId/send');
}

// Create signal
Future<IrSignal> createSignal(
  ProviderRef ref, {
  required String remoteId,
  required String name,
  required dynamic rawData,
  String icon = 'power',
  String? protocol,
  int frequency = 38000,
}) async {
  final dio = ref.read(dioProvider);
  final res = await dio.post('/signals', data: {
    'remoteId': remoteId,
    'name': name,
    'icon': icon,
    'rawData': rawData,
    'protocol': protocol,
    'frequency': frequency,
  });
  return IrSignal.fromJson(res.data);
}
