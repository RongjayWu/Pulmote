import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/data/auth_provider.dart';
import '../../features/devices/presentation/home_page.dart';
import '../../features/devices/presentation/add_device_page.dart';
import '../../features/remotes/presentation/remote_detail_page.dart';
import '../../features/remotes/presentation/add_remote_page.dart';
import '../../features/remotes/presentation/remote_panel_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/';
      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Main app with shell
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/devices/add',
            builder: (context, state) => const AddDevicePage(),
          ),
          GoRoute(
            path: '/remotes/add/:deviceId',
            builder: (context, state) => AddRemotePage(
              deviceId: state.pathParameters['deviceId']!,
            ),
          ),
          GoRoute(
            path: '/remotes/:remoteId',
            builder: (context, state) => RemoteDetailPage(
              remoteId: state.pathParameters['remoteId']!,
            ),
          ),
          GoRoute(
            path: '/remotes/:remoteId/panel',
            builder: (context, state) => RemotePanelPage(
              remoteId: state.pathParameters['remoteId']!,
            ),
          ),
        ],
      ),
    ],
  );
});

class ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}
