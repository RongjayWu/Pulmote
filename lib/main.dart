import 'package:flutter/material.dart';
import 'views/home_page.dart';
import 'views/login_page.dart';
import 'models/user.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulMote - 萬用遙控器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 認證頁面 - 根據登入狀態決定顯示哪個頁面
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  User? _currentUser;

  void _handleLoginSuccess(User user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _handleLogout() {
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return LoginPage(onLoginSuccess: _handleLoginSuccess);
    } else {
      return HomePage(user: _currentUser!, onLogout: _handleLogout);
    }
  }
}
