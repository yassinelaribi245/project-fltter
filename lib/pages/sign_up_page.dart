import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  String? _notEmpty(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _phone(String? v) {
    final trimmed = (v ?? '').trim();
    if (trimmed.length < 7) return 'Enter a valid phone';
    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(trimmed)) return 'Digits only';
    return null;
  }

  String? _email(String? v) {
    final reg = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return (v == null || !reg.hasMatch(v.trim())) ? 'Enter a valid e-mail' : null;
  }

  String? _pass(String? v) =>
      (v == null || v.trim().length < 6) ? 'Min 6 characters' : null;

  String? _confirm(String? v) =>
      (v ?? '').trim() != (_passCtrl.text).trim() ? 'Passwords do not match' : null;

Future<void> _submit() async {
  final state = _formKey.currentState;
  if (state == null || !state.validate()) return;
  state.save();

  setState(() => _loading = true);

  try {
    // 1. create Firebase-Auth account
    final cred = await _auth.signUp(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );
    final user = cred?.user;
    if (user == null) throw Exception('Sign-up failed');

    // 2. update display-name
    final fullName = '${_firstCtrl.text.trim()} ${_lastCtrl.text.trim()}';
    await user.updateDisplayName(fullName);

    // 3. write public + private sub-docs in a batch
    final uid = user.uid;
    final batch = FirebaseFirestore.instance.batch();

    final publicRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('public')
        .doc('data');

    batch.set(publicRef, {
      'name': fullName,
      'bio': '',
      'profilePicture': null, // add later
    });

    final privateRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('private')
        .doc('data');

    batch.set(privateRef, {
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'isAdmin': false,
    });

    await batch.commit();

    // 4. go back to login
    if (mounted) Navigator.pop(context);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}


  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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
            _posImg('assets/images/clock.png', null, 1300, 150, 1300, right: 40, top: 40),
            _titleText(1600),
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
            decoration: BoxDecoration(image: DecorationImage(image: AssetImage(path))),
          ),
        ),
      );

  Widget _titleText(int delay) => Positioned(
        child: FadeInUp(
          duration: Duration(milliseconds: delay),
          child: Container(
            margin: const EdgeInsets.only(top: 50),
            child: const Center(
              child: Text(
                'Sign Up',
                style: TextStyle(
                    color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );

  Widget _formCard() => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            FadeInUp(
              duration: const Duration(milliseconds: 1800),
              child: Form(key: _formKey, child: _inputCard()),
            ),
            const SizedBox(height: 30),
            FadeInUp(
              duration: const Duration(milliseconds: 1900),
              child: _loading
                  ? const CircularProgressIndicator()
                  : _gradientBtn('Create account', _submit),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 2000),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Already have an account? Log in',
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
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(143, 148, 251, .2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _field(true, 'First name', _firstCtrl),
            _field(true, 'Last name', _lastCtrl),
            _field(true, 'Phone', _phoneCtrl, type: TextInputType.phone),
            _field(true, 'E-mail', _emailCtrl, type: TextInputType.emailAddress),
            _field(false, 'Password', _passCtrl, obscure: true),
            _field(false, 'Confirm password', _confirmCtrl, obscure: true),
          ],
        ),
      );

  Widget _field(bool showBorder, String hint, TextEditingController ctrl,
      {TextInputType? type, bool obscure = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color.fromRGBO(143, 148, 251, 1)),
              ),
            )
          : null,
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF1e405b)),
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        ),
        validator: (val) {
          if (hint == 'First name' || hint == 'Last name') return _notEmpty(val);
          if (hint == 'Phone') return _phone(val);
          if (hint == 'E-mail') return _email(val);
          if (hint == 'Password') return _pass(val);
          if (hint == 'Confirm password') return _confirm(val);
          return null;
        },
      ),
    );
  }

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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
}