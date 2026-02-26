import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

class LoginPage extends StatefulWidget {
  final Function(User) onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _googleSignIn.initialize();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.authenticate();

      if (googleUser != null) {
        // 創建用戶對象
        final user = User(
          id: googleUser.id,
          email: googleUser.email,
          name: googleUser.displayName ?? '用戶',
          photoUrl: googleUser.photoUrl,
        );

        // 回調成功登入
        widget.onLoginSuccess(user);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登入失敗: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo[400]!, Colors.indigo[700]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 應用圖標
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.videogame_asset,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 應用名稱
                  const Text(
                    'PulMote',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 應用描述
                  const Text(
                    '萬用遙控器智慧居家系統',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 64),

                  // 歡迎文字
                  const Text(
                    '歡迎來到 PulMote',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    '使用 Google 帳戶登入',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 48),

                  // Google 登入按鈕
                  _buildGoogleSignInButton(),
                  const SizedBox(height: 24),

                  // 隱私政策提示
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('隱私政策')));
                    },
                    child: Text(
                      '繼續即表示您同意我們的隱私政策和服務條款',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return _isLoading
        ? const SizedBox(
          width: 200,
          height: 56,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        )
        : SizedBox(
          width: 200,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleGoogleSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/google_logo.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.account_circle,
                      color: Colors.indigo,
                      size: 24,
                    );
                  },
                ),
                const SizedBox(width: 12),
                const Text(
                  '使用 Google 登入',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
