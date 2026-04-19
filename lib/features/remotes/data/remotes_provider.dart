import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../services/api_client.dart';

/// IR signals for a given remote.
final signalsProvider =
    FutureProvider.family<List<IrSignal>, String>((ref, remoteId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/signals', queryParameters: {'remoteId': remoteId});
  return (res.data as List).map((e) => IrSignal.fromJson(e)).toList();
});
