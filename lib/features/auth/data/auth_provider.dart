import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../models/models.dart';
import '../../../services/api_client.dart';

// Auth state - holds current user or null
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // Check stored token on startup
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: 'token');
    if (token == null) return null;

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/auth/me');
      return User.fromJson(res.data);
    } catch (_) {
      await storage.delete(key: 'token');
      return null;
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      final token = res.data['token'] as String;
      final user = User.fromJson(res.data['user']);

      await ref.read(secureStorageProvider).write(key: 'token', value: token);
      state = AsyncData(user);
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'Login failed';
      state = AsyncError(msg, StackTrace.current);
    }
  }

  Future<void> register(String username, String password,
      {String? displayName}) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        if (displayName != null) 'displayName': displayName,
      });

      final token = res.data['token'] as String;
      final user = User.fromJson(res.data['user']);

      await ref.read(secureStorageProvider).write(key: 'token', value: token);
      state = AsyncData(user);
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'Registration failed';
      state = AsyncError(msg, StackTrace.current);
    }
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).delete(key: 'token');
    state = const AsyncData(null);
  }
}
