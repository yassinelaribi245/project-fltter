import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'auth_service.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _auth      = AuthService();
  bool _loading    = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _auth.signIn(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _headerStack(),
            _formCard(),
          ],
        ),
      ),
    );
  }
  Widget _headerStack() => SizedBox(
        height: 400,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            _posImg('assets/images/light-1.png', 30, 1000, 200, 1000),
            _posImg('assets/images/light-2.png', 140, 1200, 150, 1200),
            _posImg('assets/images/clock.png', null, 1300, 150, 1300,
                right: 40, top: 40),
            _loginText(1600),
          ],
        ),
      );

  Widget _posImg(String path, double? left, int delay, double h, double w,
          {double? right, double? top}) =>
      Positioned(
        left: left,
        right: right,
        top: top,
        width: 80,
        height: h,
        child: FadeInUp(
          duration: Duration(milliseconds: delay),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage(path)),
            ),
          ),
        ),
      );

  Widget _loginText(int delay) => Positioned(
        child: FadeInUp(
          duration: Duration(milliseconds: delay),
          child: Container(
            margin: const EdgeInsets.only(top: 50),
            child: const Center(
              child: Text(
                'Login',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );

  /* ---------- form ---------- */
  Widget _formCard() => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            FadeInUp(
              duration: const Duration(milliseconds: 1800),
              child: _inputCard(),
            ),
            const SizedBox(height: 30),
            FadeInUp(
              duration: const Duration(milliseconds: 1900),
              child: _loading
                  ? const CircularProgressIndicator()
                  : _gradientBtn('Login', _login),
            ),
            const SizedBox(height: 30),
            FadeInUp(
              duration: const Duration(milliseconds: 1950),
              child: _borderBtn('Sign Up', () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SignUpPage()))),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 2000),
              child: GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Forgot password tapped')),
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Color(0xFF1e405b)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _inputCard() => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromRGBO(143, 148, 251, 1)),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(143, 148, 251, .2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _field(true, 'Email or Phone number', _emailCtrl),
            _field(false, 'Password', _passCtrl, obscure: true),
          ],
        ),
      );

  Widget _field(bool showBorder, String hint, TextEditingController ctrl,
          {bool obscure = false}) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: showBorder
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: const Color.fromRGBO(143, 148, 251, 1)),
                ),
              )
            : null,
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(color: Color(0xFF1e405b)),
          ),
        ),
      );

  Widget _gradientBtn(String text, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF1e405b), Color(0xFF1e405b)],
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );

  Widget _borderBtn(String text, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1e405b), width: 2),
            ),
            child: Text(
              text,
              style: const TextStyle(
                  color: Color(0xFF1e405b), fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
}