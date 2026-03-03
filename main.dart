import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _apiBaseUrl = 'http://localhost:8000';

class ApiScheme {
  final String id, name, category, description, benefit;
  final double matchScore;
  ApiScheme({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.benefit,
    required this.matchScore,
  });
  factory ApiScheme.fromJson(Map<String, dynamic> j) => ApiScheme(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    category: j['category'] ?? '',
    description: j['description'] ?? '',
    benefit: j['benefit'] ?? '',
    matchScore: (j['match_score'] ?? 0).toDouble(),
  );
}

class ApiService {
  static Future<Map<String, dynamic>> recommend({
    required int age,
    required String income,
    required String occupation,
    required String gender,
    String? state,
    int topN = 10,
  }) async {
    try {
      final body = {
        'age': age,
        'income': income,
        'occupation': occupation,
        'gender': gender,
        'top_n': topN,
      };
      if (state != null) body['state'] = state;
      final res = await http
          .post(
            Uri.parse('$_apiBaseUrl/recommend'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200 ? jsonDecode(res.body) : {};
    } catch (_) {
      return {};
    }
  }

  static Future<List<ApiScheme>> search(String query, {int topN = 10}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_apiBaseUrl/search'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'query': query, 'top_n': topN}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List results = jsonDecode(res.body)['results'] ?? [];
        return results.map((e) => ApiScheme.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

// --- DESIGN TOKENS ---
class AppColors {
  static const Color primary = Color(0xFF1B3B6F);
  static const Color primaryLight = Color(0xFF2C5CA8);
  static const Color accent = Color(0xFFF28F3B);
  static const Color emerald = Color(0xFF4CAF50);
  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2B2D42);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textMuted = Color(0xFFADB5BD);
  static const Color error = Color(0xFFEF233C);
  static const Color divider = Color(0xFFE9ECEF);
  static const Color border = Color(0xFFDEE2E6);
  static const Color shadow = Color(0x1A000000);
  static const Color green = Color(0xFF1D8A48);
  static const Color greenDark = Color(0xFF0a4a24);
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GovSchemes.AI',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.bgCard,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

// ══════════════════════════════════════════════════════
// ENHANCED LOGIN SCREEN
// ══════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;

  // Floating particles
  final List<_Particle> _particles = List.generate(
    18,
    (i) => _Particle(
      x: (i * 137.508) % 100,
      y: (i * 93.7) % 100,
      size: 4 + (i % 5) * 3.0,
      speed: 0.3 + (i % 4) * 0.2,
      opacity: 0.08 + (i % 5) * 0.04,
    ),
  );

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );
    _cardController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailCtrl.text.contains('@') && _passCtrl.text.length >= 6) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => const MainScreen(),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Use any email and 6+ char password to demo'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) {
              final t = _bgController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + t * 0.6, -1),
                    end: Alignment(1 - t * 0.3, 1),
                    colors: const [
                      Color(0xFF0a2540),
                      Color(0xFF1D8A48),
                      Color(0xFF0d3b2a),
                      Color(0xFF1B3B6F),
                    ],
                    stops: [0, 0.3 + t * 0.1, 0.6, 1],
                  ),
                ),
              );
            },
          ),

          // Geometric pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _GeometricPatternPainter()),
          ),

          // Floating particles
          ..._particles.asMap().entries.map((e) {
            final p = e.value;
            return AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) {
                final t = (_bgController.value + e.key * 0.07) % 1.0;
                final yOffset = sin(t * 2 * pi) * 8;
                return Positioned(
                  left: MediaQuery.of(context).size.width * (p.x / 100),
                  top: MediaQuery.of(context).size.height * (p.y / 100) +
                      yOffset,
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(p.opacity),
                    ),
                  ),
                );
              },
            );
          }),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: AnimatedBuilder(
                animation: _cardController,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _cardSlide.value),
                  child: Opacity(opacity: _cardFade.value, child: child),
                ),
                child: Column(
                  children: [
                    // Logo area
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green.withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🏛️', style: TextStyle(fontSize: 38)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Gov',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Schemes',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4ade80),
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: '.AI',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Text(
                        '🇮🇳  National Scheme Discovery Platform',
                        style: TextStyle(
                          color: Color(0xFFbbf7d0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Login card
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to discover government schemes',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _glassField(
                            'Email Address',
                            Icons.alternate_email_rounded,
                            _emailCtrl,
                          ),
                          const SizedBox(height: 16),
                          _glassField(
                            'Password',
                            Icons.lock_outline_rounded,
                            _passCtrl,
                            obscure: _obscure,
                            suffix: GestureDetector(
                              onTap: () =>
                                  setState(() => _obscure = !_obscure),
                              child: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white54,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: const Color(0xFF4ade80),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Sign in button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded,
                                            size: 18),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _socialBtn('G', 'Google', const Color(0xFFEA4335)),
                              const SizedBox(width: 12),
                              _socialBtn(
                                  '📱', 'Aadhaar', const Color(0xFF1e3a8a)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              color: Color(0xFF4ade80),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassField(
    String hint,
    IconData icon,
    TextEditingController ctrl, {
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffix,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF4ade80), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _socialBtn(String icon, String label, Color color) {
    return Expanded(
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(
                color: icon == 'G' ? color : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Geometric background painter
class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final rect = Rect.fromCenter(
        center: Offset(size.width * 0.75, size.height * 0.25),
        width: 100.0 + i * 80,
        height: 100.0 + i * 80,
      );
      canvas.drawOval(rect, paint);
    }

    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.8),
        60.0 + i * 50,
        paint2,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Particle {
  final double x, y, size, speed, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// ══════════════════════════════════════════════════════
// REGISTER SCREEN (Enhanced)
// ══════════════════════════════════════════════════════
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0a2540),
                    Color(0xFF1D8A48),
                    Color(0xFF0d3b2a),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _GeometricPatternPainter()),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child:
                        const Center(child: Text('✨', style: TextStyle(fontSize: 30))),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join millions discovering government schemes',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _regField('Full Name', Icons.person_outline_rounded,
                            _nameCtrl),
                        const SizedBox(height: 14),
                        _regField('Email Address',
                            Icons.alternate_email_rounded, _emailCtrl),
                        const SizedBox(height: 14),
                        _regField(
                          'Password',
                          Icons.lock_outline_rounded,
                          _passCtrl,
                          obscure: _obscure,
                          suffix: GestureDetector(
                            onTap: () => setState(() => _obscure = !_obscure),
                            child: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white54,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _regField(
    String hint,
    IconData icon,
    TextEditingController ctrl, {
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4ade80), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════
class Scheme {
  final String id, name, ministry, emoji, desc;
  final Color bg;
  final List<String> tags, income, occ;
  final List<int> age;

  Scheme({
    required this.id,
    required this.name,
    required this.ministry,
    required this.emoji,
    required this.desc,
    required this.bg,
    required this.tags,
    required this.income,
    required this.occ,
    required this.age,
  });
}

class SchemeDetails {
  final String overview;
  final List<String> benefits, eligibility, documents;
  SchemeDetails(this.overview, this.benefits, this.eligibility, this.documents);
}

// Database kept the same
final Map<String, List<Scheme>> schemesDB = {
  'Education': [
    Scheme(
      id: 'pmsy',
      name: 'PM Scholarship Scheme',
      ministry: 'Ministry of Education',
      emoji: '🎓',
      desc: 'Financial assistance to meritorious students',
      bg: const Color(0xFF7c3aed),
      tags: ['Student', 'Up to ₹25,000/yr'],
      income: ['below1', '1to2.5', '2.5to5'],
      occ: ['Student'],
      age: [15, 30],
    ),
    Scheme(
      id: 'nsp',
      name: 'National Scholarship Portal',
      ministry: 'Ministry of Education',
      emoji: '📚',
      desc: 'Central & state scholarships under one portal',
      bg: const Color(0xFF1e3a8a),
      tags: ['All Students', 'Multiple Scholarships'],
      income: ['below1', '1to2.5', '2.5to5', '5to8'],
      occ: ['Student'],
      age: [14, 35],
    ),
    Scheme(
      id: 'pmrf',
      name: 'PM Research Fellowship',
      ministry: 'MHRD',
      emoji: '🔬',
      desc: 'Fellowship for PhD research in premier institutes',
      bg: const Color(0xFF0369a1),
      tags: ['PhD', '₹70,000/month'],
      income: ['below1', '1to2.5', '2.5to5', '5to8', 'above8'],
      occ: ['Student'],
      age: [21, 35],
    ),
  ],
  'Agriculture': [
    Scheme(
      id: 'pm-kisan',
      name: 'PM-Kisan Yojana',
      ministry: 'Ministry of Agriculture',
      emoji: '🌾',
      desc: 'Income support of ₹6,000/year to farmers',
      bg: const Color(0xFF15803d),
      tags: ['Farmer', '₹6,000/year'],
      income: ['below1', '1to2.5', '2.5to5'],
      occ: ['Farmer'],
      age: [18, 70],
    ),
    Scheme(
      id: 'kcc',
      name: 'Kisan Credit Card',
      ministry: 'NABARD',
      emoji: '💳',
      desc: 'Easy credit for agricultural needs',
      bg: const Color(0xFF166534),
      tags: ['Farmer', 'Low Interest Loan'],
      income: ['below1', '1to2.5', '2.5to5', '5to8'],
      occ: ['Farmer'],
      age: [18, 70],
    ),
    Scheme(
      id: 'pmfby',
      name: 'PM Fasal Bima Yojana',
      ministry: 'Ministry of Agriculture',
      emoji: '🌱',
      desc: 'Crop insurance scheme for farmers',
      bg: const Color(0xFF14532d),
      tags: ['Farmer', 'Crop Insurance'],
      income: ['below1', '1to2.5', '2.5to5', '5to8'],
      occ: ['Farmer'],
      age: [18, 70],
    ),
  ],
  'Women': [
    Scheme(
      id: 'beti',
      name: 'Beti Bachao Beti Padhao',
      ministry: 'Ministry of WCD',
      emoji: '👧',
      desc: 'Scheme for welfare of girl child',
      bg: const Color(0xFFdb2777),
      tags: ['Women', 'Girl Child'],
      income: ['below1', '1to2.5', '2.5to5', '5to8'],
      occ: ['Student', 'Homemaker'],
      age: [0, 35],
    ),
    Scheme(
      id: 'sukanya',
      name: 'Sukanya Samriddhi Yojana',
      ministry: 'Ministry of Finance',
      emoji: '💰',
      desc: 'Savings scheme for girl child',
      bg: const Color(0xFFbe185d),
      tags: ['Girl Child', '8.2% Interest'],
      income: ['below1', '1to2.5', '2.5to5', '5to8', 'above8'],
      occ: ['Homemaker', 'Salaried Employee', 'Self Employed'],
      age: [0, 10],
    ),
  ],
  'Health': [
    Scheme(
      id: 'ayushman',
      name: 'Ayushman Bharat PM-JAY',
      ministry: 'Ministry of Health',
      emoji: '🏥',
      desc: 'Health insurance cover of ₹5 Lakh per family',
      bg: const Color(0xFF15803d),
      tags: ['All', '₹5L Coverage'],
      income: ['below1', '1to2.5', '2.5to5'],
      occ: ['Farmer', 'Unemployed', 'Salaried Employee', 'Homemaker'],
      age: [0, 100],
    ),
    Scheme(
      id: 'pmjay',
      name: 'Janani Suraksha Yojana',
      ministry: 'Ministry of Health',
      emoji: '🤱',
      desc: 'Safe motherhood intervention scheme',
      bg: const Color(0xFF0f766e),
      tags: ['Women', 'Maternity'],
      income: ['below1', '1to2.5'],
      occ: ['Homemaker', 'Salaried Employee'],
      age: [16, 50],
    ),
  ],
  'Employment': [
    Scheme(
      id: 'mgnregs',
      name: 'MGNREGA',
      ministry: 'Ministry of Rural Dev',
      emoji: '🏗️',
      desc: '100 days guaranteed employment per year',
      bg: const Color(0xFFb45309),
      tags: ['Rural', 'Employment Guarantee'],
      income: ['below1', '1to2.5'],
      occ: ['Unemployed', 'Farmer'],
      age: [18, 60],
    ),
    Scheme(
      id: 'pmkvy',
      name: 'PM Kaushal Vikas Yojana',
      ministry: 'MSDE',
      emoji: '🔧',
      desc: 'Free skill training with stipend',
      bg: const Color(0xFFc2410c),
      tags: ['Youth', 'Free Training'],
      income: ['below1', '1to2.5', '2.5to5'],
      occ: ['Unemployed', 'Student'],
      age: [15, 45],
    ),
  ],
  'Housing': [
    Scheme(
      id: 'pmay',
      name: 'PM Awas Yojana (Urban)',
      ministry: 'MoHUA',
      emoji: '🏠',
      desc: 'Affordable housing for urban poor',
      bg: const Color(0xFF0369a1),
      tags: ['Urban', 'Home Loan Subsidy'],
      income: ['below1', '1to2.5', '2.5to5', '5to8'],
      occ: ['Salaried Employee', 'Self Employed', 'Unemployed'],
      age: [21, 65],
    ),
  ],
  'Finance': [
    Scheme(
      id: 'mudra',
      name: 'PM Mudra Yojana',
      ministry: 'Ministry of Finance',
      emoji: '💼',
      desc: 'Loans up to ₹10 lakh for small businesses',
      bg: const Color(0xFFb45309),
      tags: ['Business', 'Up to ₹10L Loan'],
      income: ['below1', '1to2.5', '2.5to5', '5to8'],
      occ: ['Self Employed', 'Business Owner', 'Unemployed'],
      age: [21, 65],
    ),
    Scheme(
      id: 'jan-dhan',
      name: 'PM Jan Dhan Yojana',
      ministry: 'Ministry of Finance',
      emoji: '🏦',
      desc: 'Zero balance bank account with benefits',
      bg: const Color(0xFFb45309),
      tags: ['All', 'Zero Balance Account'],
      income: ['below1', '1to2.5', '2.5to5'],
      occ: ['Farmer', 'Unemployed', 'Homemaker'],
      age: [18, 100],
    ),
  ],
  'Skill': [
    Scheme(
      id: 'ddu-gky',
      name: 'DDU-GKY',
      ministry: 'Ministry of Rural Dev',
      emoji: '🛠️',
      desc: 'Rural youth skill & employment program',
      bg: const Color(0xFF7c3aed),
      tags: ['Rural Youth', 'Placement Assistance'],
      income: ['below1', '1to2.5'],
      occ: ['Unemployed', 'Student'],
      age: [15, 35],
    ),
  ],
  'Senior': [
    Scheme(
      id: 'ignoaps',
      name: 'Indira Gandhi Old Age Pension',
      ministry: 'MoRD',
      emoji: '👴',
      desc: 'Monthly pension for senior citizens',
      bg: const Color(0xFF475569),
      tags: ['60+ Age', 'Monthly Pension'],
      income: ['below1', '1to2.5'],
      occ: ['Senior Citizen', 'Unemployed'],
      age: [60, 100],
    ),
  ],
  'Business': [
    Scheme(
      id: 'startup-india',
      name: 'Startup India',
      ministry: 'DPIIT',
      emoji: '🚀',
      desc: 'Support and incentives for startups',
      bg: const Color(0xFF16a34a),
      tags: ['Startup', 'Tax Benefits'],
      income: ['1to2.5', '2.5to5', '5to8', 'above8'],
      occ: ['Business Owner', 'Self Employed'],
      age: [21, 50],
    ),
  ],
};

final Map<String, SchemeDetails> schemeDetails = {
  'pm-kisan': SchemeDetails(
    'PM-Kisan Yojana provides income support of ₹6,000 per year to all land-holding farmer families. The amount is paid in three equal installments of ₹2,000 each directly to Aadhaar-linked bank accounts.',
    [
      '₹6,000 per year in 3 installments of ₹2,000 each',
      'Direct Bank Transfer (DBT) to Aadhaar-linked account',
      'No middlemen – funds transferred directly',
      'Available across all states and UTs',
    ],
    [
      'Must be a resident Indian citizen',
      'Should own cultivable land',
      'Annual family income below ₹2 lakh',
      'Valid Aadhaar card required',
    ],
    [
      'Aadhaar Card',
      'Land ownership documents (Khasra/Khatauni)',
      'Bank passbook copy',
      'Passport size photograph',
    ],
  ),
  'ayushman': SchemeDetails(
    'Ayushman Bharat PM-JAY is the world\'s largest health insurance scheme providing health cover of ₹5 lakh per family per year.',
    [
      '₹5 Lakh health cover per family per year',
      'Cashless treatment at empaneled hospitals',
      'Covers pre and post hospitalization expenses',
      'Over 1,500+ medical procedures covered',
    ],
    [
      'Identified from SECC 2011 data',
      'BPL card holders',
      'Annual income below ₹2.5 lakh',
      'E-card/Golden Card required',
    ],
    [
      'Ration Card',
      'Aadhaar Card',
      'Income Certificate',
      'Bank Account Details',
    ],
  ),
  'pmay': SchemeDetails(
    'Pradhan Mantri Awas Yojana (Urban) aims to provide affordable housing to urban poor with credit-linked subsidy of 3-6.5% on home loans.',
    [
      'Interest subsidy of 3-6.5% on home loans',
      'Subsidy amount up to ₹2.67 lakh',
      'Covers 6.5 crore urban households',
    ],
    [
      'Urban household without a pucca house',
      'EWS/LIG/MIG categories',
      'First-time home buyer',
    ],
    [
      'Aadhaar Card',
      'Income certificate',
      'Property documents',
      'Affidavit of no pucca house',
    ],
  ),
  'pmsy': SchemeDetails(
    'PM Scholarship Scheme provides financial assistance to meritorious students for pursuing professional courses.',
    [
      '₹25,000 per year for girls, ₹20,000 for boys',
      'Covers engineering, medical, law, and management',
      'Directly credited to student bank account',
    ],
    [
      'Indian citizen',
      'Age between 18-25 years',
      'Minimum 60% marks in 12th standard',
      'Annual family income below ₹6 lakh',
    ],
    [
      '10th & 12th Marksheet',
      'College enrollment certificate',
      'Income certificate',
      'Aadhaar Card',
    ],
  ),
  'mudra': SchemeDetails(
    'PM Mudra Yojana provides loans up to ₹10 lakh to non-corporate, non-farm small/micro enterprises.',
    [
      'Shishu: loans up to ₹50,000',
      'Kishore: loans ₹50,001 to ₹5 lakh',
      'Tarun: loans ₹5 lakh to ₹10 lakh',
      'No collateral required',
    ],
    [
      'Indian citizen above 18 years',
      'Non-farm income generating activity',
      'No defaults on previous loans',
    ],
    [
      'Aadhaar Card',
      'PAN Card',
      'Business address proof',
      'Bank statements (6 months)',
    ],
  ),
};

// ══════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  String _currentScreen = 'home';
  String _previousScreen = 'home';
  String _currentCategory = '';
  Scheme? _currentScheme;
  List<Scheme> _savedSchemes = [];
  List<Scheme> _eligibleSchemes = [];
  List<Scheme> _searchResults = [];
  bool _hasSearched = false;

  int _trendingIndex = 0;
  Timer? _trendingTimer;

  // Google Translate state
  String _selectedLanguage = 'en';
  bool _showTranslateMenu = false;

  final List<Map<String, dynamic>> _trendingItems = [
    {
      'id': 'pm-kisan',
      'emoji': '🌾',
      'name': 'PM-Kisan Yojana',
      'desc': '₹6,000/year direct income support for farmers',
      'stat': '▲ 2.1M Applications',
      'colors': [const Color(0xFF1D8A48), const Color(0xFF0f5c2e)],
    },
    {
      'id': 'pmay',
      'emoji': '🏠',
      'name': 'PM Awas Yojana',
      'desc': 'Affordable housing — interest subsidy up to ₹2.67L',
      'stat': '▲ 1.8M Applications',
      'colors': [const Color(0xFFc2410c), const Color(0xFFea580c)],
    },
    {
      'id': 'ayushman',
      'emoji': '🏥',
      'name': 'Ayushman Bharat',
      'desc': '₹5 Lakh health cover per family per year',
      'stat': '▲ 3.5M Beneficiaries',
      'colors': [const Color(0xFF0369a1), const Color(0xFF0284c7)],
    },
    {
      'id': 'pmsy',
      'emoji': '🎓',
      'name': 'PM Scholarship',
      'desc': 'Up to ₹25,000/year for meritorious students',
      'stat': '▲ 900K Students',
      'colors': [const Color(0xFF7c3aed), const Color(0xFF8b5cf6)],
    },
  ];

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedIncome, _selectedState, _selectedOccupation;

  static const String _claudeModel = 'claude-sonnet-4-20250514';

  bool _isTyping = false;
  final List<Map<String, String>> _conversationHistory = [];

  // Chatbot conversational flow state
  int _chatStep = 0;
  final Map<String, String> _userProfile = {};

  final List<Map<String, dynamic>> _chatMessages = [
    {
      'role': 'bot',
      'text':
          '👋 Hello! I\'m your AI Government Scheme Assistant.\n\nI\'ll guide you step by step to find schemes you qualify for. Let\'s start!',
      'options': ['Find Schemes for Me', 'Ask a Specific Question'],
    },
  ];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Languages for translate
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'hi', 'name': 'हिंदी', 'flag': '🇮🇳'},
    {'code': 'mr', 'name': 'मराठी', 'flag': '🇮🇳'},
    {'code': 'ta', 'name': 'தமிழ்', 'flag': '🇮🇳'},
    {'code': 'te', 'name': 'తెలుగు', 'flag': '🇮🇳'},
    {'code': 'bn', 'name': 'বাংলা', 'flag': '🇮🇳'},
    {'code': 'gu', 'name': 'ગુજરાતી', 'flag': '🇮🇳'},
    {'code': 'kn', 'name': 'ಕನ್ನಡ', 'flag': '🇮🇳'},
    {'code': 'pa', 'name': 'ਪੰਜਾਬੀ', 'flag': '🇮🇳'},
  ];

  @override
  void initState() {
    super.initState();
    _startTrendingTimer();
  }

  void _startTrendingTimer() {
    _trendingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentScreen == 'home' && mounted) {
        setState(() {
          _trendingIndex = (_trendingIndex + 1) % _trendingItems.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _trendingTimer?.cancel();
    _ageController.dispose();
    _chatController.dispose();
    _searchController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _goHome() => setState(() => _currentScreen = 'home');
  void _goBack() => setState(() => _currentScreen = _previousScreen);

  void _navigate(String screen) {
    _previousScreen = _currentScreen;
    setState(() => _currentScreen = screen);
  }

  void _openCategory(String cat) {
    _currentCategory = cat;
    _eligibleSchemes = [];
    _hasSearched = false;
    _ageController.clear();
    _selectedIncome = null;
    _selectedState = null;
    _selectedOccupation = null;
    _navigate('filter');
  }

  Future<void> _checkEligibility() async {
    int age = int.tryParse(_ageController.text) ?? 25;
    if (_selectedIncome == null) {
      _showToast('Please select your income level');
      return;
    }
    _showToast('🤖 AI is finding best schemes for you...');
    final apiResults = await ApiService.recommend(
      age: age,
      income: _selectedIncome!,
      occupation: (_selectedOccupation ?? 'farmer').toLowerCase().replaceAll(' ', '_'),
      gender: 'male',
    );

    if (apiResults.isNotEmpty) {
      final List schemsFromAPI = apiResults['results'] ?? [];
      final matched = schemsFromAPI.map((a) {
        final apiScheme = ApiScheme.fromJson(a);
        for (var list in schemesDB.values) {
          try {
            return list.firstWhere((s) => s.id == apiScheme.id);
          } catch (_) {}
        }
        return Scheme(
          id: apiScheme.id,
          name: apiScheme.name,
          ministry: apiScheme.category,
          emoji: '📋',
          desc: apiScheme.description,
          bg: const Color(0xFF1D8A48),
          tags: [apiScheme.benefit],
          income: [_selectedIncome!],
          occ: [],
          age: [0, 100],
        );
      }).toList();
      setState(() {
        _eligibleSchemes = matched;
        _hasSearched = true;
      });
    } else {
      List<Scheme> pool = schemesDB[_currentCategory] ?? [];
      List<Scheme> results = pool.where((s) {
        bool ok = true;
        if (age != 0 && (age < s.age[0] || age > s.age[1])) ok = false;
        if (_selectedIncome != null && s.income.isNotEmpty && !s.income.contains(_selectedIncome)) ok = false;
        if (_selectedOccupation != null && s.occ.isNotEmpty && !s.occ.contains(_selectedOccupation)) ok = false;
        return ok;
      }).toList();
      setState(() {
        _eligibleSchemes = results;
        _hasSearched = true;
      });
    }
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _hasSearched = false; });
      return;
    }
    final apiResults = await ApiService.search(query.trim());
    if (apiResults.isNotEmpty) {
      final matched = apiResults.map((a) {
        for (var list in schemesDB.values) {
          try { return list.firstWhere((s) => s.id == a.id); } catch (_) {}
        }
        return Scheme(id: a.id, name: a.name, ministry: a.category, emoji: '📋', desc: a.description, bg: const Color(0xFF1D8A48), tags: [], income: [], occ: [], age: [0, 100]);
      }).toList();
      setState(() { _searchResults = matched; _hasSearched = true; _previousScreen = 'home'; _currentScreen = 'search'; });
      return;
    }
    String q = query.toLowerCase();
    List<Scheme> results = [];
    for (var list in schemesDB.values) {
      for (var s in list) {
        if (s.name.toLowerCase().contains(q) || s.desc.toLowerCase().contains(q) || s.ministry.toLowerCase().contains(q) || s.tags.any((t) => t.toLowerCase().contains(q))) {
          results.add(s);
        }
      }
    }
    setState(() { _searchResults = results; _hasSearched = true; _previousScreen = 'home'; _currentScreen = 'search'; });
  }

  void _openSchemeDetail(String id) {
    Scheme? scheme;
    for (var list in schemesDB.values) {
      try { scheme = list.firstWhere((s) => s.id == id); break; } catch (_) {}
    }
    if (scheme == null) return;
    _currentScheme = scheme;
    _navigate('detail');
  }

  void _toggleSave() {
    if (_currentScheme == null) return;
    bool exists = _savedSchemes.any((s) => s.id == _currentScheme!.id);
    setState(() {
      if (exists) {
        _savedSchemes.removeWhere((s) => s.id == _currentScheme!.id);
        _showToast('Scheme removed from saved!');
      } else {
        _savedSchemes.add(_currentScheme!);
        _showToast('Scheme saved to Dashboard!');
      }
    });
  }

  void _removeSaved(String id) {
    setState(() => _savedSchemes.removeWhere((s) => s.id == id));
    _showToast('Removed from saved schemes');
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── CHATBOT LOGIC WITH OPTIONS ──
  void _handleOptionTap(String option) {
    setState(() {
      _chatMessages.add({'role': 'user', 'text': option});
      _isTyping = true;
    });
    _scrollChat();
    _processChatOption(option);
  }

  void _processChatOption(String option) {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Map<String, dynamic> reply = {};

      // Step 0: Entry
      if (_chatStep == 0) {
        if (option == 'Find Schemes for Me') {
          _chatStep = 1;
          reply = {
            'role': 'bot',
            'text': '👤 What best describes you?',
            'options': ['Student 🎓', 'Farmer 🌾', 'Salaried Employee 💼', 'Self Employed / Business 🏪', 'Unemployed 🔍', 'Homemaker 🏠', 'Senior Citizen 👴'],
          };
        } else {
          _chatStep = 99; // free text mode
          reply = {
            'role': 'bot',
            'text': '💬 Sure! Ask me anything about any government scheme. I\'m here to help!',
          };
        }
      }
      // Step 1: Occupation selected
      else if (_chatStep == 1) {
        _userProfile['occupation'] = option;
        _chatStep = 2;
        reply = {
          'role': 'bot',
          'text': '💰 What is your annual household income?',
          'options': ['Below ₹1 Lakh', '₹1L – ₹2.5L', '₹2.5L – ₹5L', '₹5L – ₹8L', 'Above ₹8L'],
        };
      }
      // Step 2: Income selected
      else if (_chatStep == 2) {
        _userProfile['income'] = option;
        _chatStep = 3;
        reply = {
          'role': 'bot',
          'text': '🎂 What is your age group?',
          'options': ['Below 18', '18–25', '26–40', '41–60', 'Above 60'],
        };
      }
      // Step 3: Age selected
      else if (_chatStep == 3) {
        _userProfile['ageGroup'] = option;
        _chatStep = 4;
        reply = {
          'role': 'bot',
          'text': '👤 What is your gender?',
          'options': ['Male', 'Female', 'Other / Prefer not to say'],
        };
      }
      // Step 4: Gender selected → show results
      else if (_chatStep == 4) {
        _userProfile['gender'] = option;
        _chatStep = 5;

        // Find schemes based on profile
        final schemes = _findSchemesForProfile();
        final schemeNames = schemes.take(5).map((s) => '${s.emoji} ${s.name}').join('\n');

        reply = {
          'role': 'bot',
          'text': '🎯 Based on your profile, here are the top schemes for you:\n\n$schemeNames\n\nWould you like details on any specific scheme?',
          'options': [
            ...schemes.take(4).map((s) => 'Details: ${s.name}').toList(),
            'Show All My Schemes',
            'Start Over',
          ],
        };
      }
      // Step 5: Scheme detail or show all
      else if (_chatStep == 5) {
        if (option == 'Start Over') {
          _chatStep = 0;
          _userProfile.clear();
          reply = {
            'role': 'bot',
            'text': '👋 Let\'s start fresh! What would you like to do?',
            'options': ['Find Schemes for Me', 'Ask a Specific Question'],
          };
        } else if (option == 'Show All My Schemes') {
          final schemes = _findSchemesForProfile();
          final all = schemes.map((s) => '${s.emoji} ${s.name} — ${s.desc}').join('\n\n');
          reply = {
            'role': 'bot',
            'text': '📋 All eligible schemes for you:\n\n$all\n\nVisit the filter section to apply!',
            'options': ['Find More Schemes', 'Start Over'],
          };
          _chatStep = 6;
        } else if (option.startsWith('Details: ')) {
          final schemeName = option.replaceFirst('Details: ', '');
          Scheme? found;
          for (var list in schemesDB.values) {
            for (var s in list) {
              if (s.name == schemeName) { found = s; break; }
            }
          }
          if (found != null) {
            final det = schemeDetails[found.id];
            final benefitText = det != null ? det.benefits.take(3).map((b) => '• $b').join('\n') : '• Check official portal for benefits';
            reply = {
              'role': 'bot',
              'text': '${found.emoji} **${found.name}**\n\n${found.desc}\n\n✅ Key Benefits:\n$benefitText\n\n📋 Ministry: ${found.ministry}',
              'options': ['Apply Now', 'Back to My Schemes', 'Start Over'],
            };
          } else {
            reply = {
              'role': 'bot',
              'text': 'Sorry, I could not find details for that scheme. Please try browsing from the home screen.',
              'options': ['Go Back', 'Start Over'],
            };
          }
        } else {
          reply = {
            'role': 'bot',
            'text': '🔍 You can visit the Filter section to see and apply for all your eligible schemes!',
            'options': ['Start Over', 'Ask a Question'],
          };
          _chatStep = 0;
        }
      }
      // Step 6+
      else {
        if (option == 'Start Over' || option == 'Find More Schemes') {
          _chatStep = 0;
          _userProfile.clear();
          reply = {
            'role': 'bot',
            'text': '👋 Let\'s start again! What would you like to do?',
            'options': ['Find Schemes for Me', 'Ask a Specific Question'],
          };
        } else {
          reply = {
            'role': 'bot',
            'text': '✅ Please visit the official MyScheme portal or use the Apply button in scheme details!',
            'options': ['Start Over'],
          };
        }
      }

      setState(() {
        _isTyping = false;
        _chatMessages.add(reply);
      });
      _scrollChat();
    });
  }

  List<Scheme> _findSchemesForProfile() {
    final occ = _userProfile['occupation'] ?? '';
    final income = _userProfile['income'] ?? '';
    final ageGroup = _userProfile['ageGroup'] ?? '';

    // Map age group to int
    int age = 25;
    if (ageGroup == 'Below 18') age = 16;
    else if (ageGroup == '18–25') age = 22;
    else if (ageGroup == '26–40') age = 32;
    else if (ageGroup == '41–60') age = 50;
    else if (ageGroup == 'Above 60') age = 65;

    // Map income
    String incKey = 'below1';
    if (income.contains('1L – ₹2.5L')) incKey = '1to2.5';
    else if (income.contains('2.5L')) incKey = '2.5to5';
    else if (income.contains('5L – ₹8L')) incKey = '5to8';
    else if (income.contains('Above')) incKey = 'above8';

    // Map occupation
    String occKey = '';
    if (occ.contains('Student')) occKey = 'Student';
    else if (occ.contains('Farmer')) occKey = 'Farmer';
    else if (occ.contains('Salaried')) occKey = 'Salaried Employee';
    else if (occ.contains('Self Employed') || occ.contains('Business')) occKey = 'Self Employed';
    else if (occ.contains('Unemployed')) occKey = 'Unemployed';
    else if (occ.contains('Homemaker')) occKey = 'Homemaker';
    else if (occ.contains('Senior')) occKey = 'Senior Citizen';

    List<Scheme> results = [];
    for (var list in schemesDB.values) {
      for (var s in list) {
        bool ok = true;
        if (age < s.age[0] || age > s.age[1]) ok = false;
        if (s.income.isNotEmpty && !s.income.contains(incKey)) ok = false;
        if (occKey.isNotEmpty && s.occ.isNotEmpty && !s.occ.contains(occKey)) ok = false;
        if (ok) results.add(s);
      }
    }
    return results;
  }

  void _sendFreeText() {
    String text = _chatController.text.trim();
    if (text.isEmpty || _isTyping) return;
    setState(() {
      _chatMessages.add({'role': 'user', 'text': text});
      _chatController.clear();
      _isTyping = true;
    });
    _scrollChat();
    Future.delayed(const Duration(milliseconds: 1000), () {
      final reply = _getSmartFallback(text);
      setState(() {
        _isTyping = false;
        _chatMessages.add({'role': 'bot', 'text': reply, 'options': ['Start Over', 'Find Schemes for Me']});
      });
      _scrollChat();
    });
  }

  String _getSmartFallback(String msg) {
    String m = msg.toLowerCase();
    if (m.contains('farmer') || m.contains('kisan') || m.contains('agriculture')) {
      return '🌾 For Farmers:\n\n• PM-Kisan Yojana – ₹6,000/year direct income support\n• Kisan Credit Card – Easy low-interest agricultural credit\n• PM Fasal Bima Yojana – Crop insurance against losses\n• MGNREGA – 100 days employment guarantee\n\nWould you like to check eligibility?';
    }
    if (m.contains('education') || m.contains('school') || m.contains('college') || m.contains('scholarship')) {
      return '🎓 For Education:\n\n• PM Scholarship – ₹25,000/yr (girls) | ₹20,000/yr (boys)\n• National Scholarship Portal – 50+ scholarships in one place\n• PM Research Fellowship – ₹70,000/month for PhD students\n\nWhat level of education are you at?';
    }
    if (m.contains('health') || m.contains('medical') || m.contains('hospital')) {
      return '🏥 For Health:\n\n• Ayushman Bharat PM-JAY – ₹5 Lakh health cover per family\n• Janani Suraksha Yojana – Maternity cash benefits\n\nAyushman Bharat covers 10 crore+ families. Want to check eligibility?';
    }
    if (m.contains('housing') || m.contains('house') || m.contains('home')) {
      return '🏠 For Housing:\n\n• PM Awas Yojana (Urban) – Interest subsidy up to ₹2.67 lakh\n• Covers EWS (income <₹3L), LIG (<₹6L), MIG (<₹18L)\n\nAre you looking for urban or rural housing support?';
    }
    if (m.contains('business') || m.contains('loan') || m.contains('startup') || m.contains('mudra')) {
      return '💼 For Business:\n\n• PM Mudra Yojana – Collateral-free loans up to ₹10 lakh\n• Startup India – Tax benefits, mentorship & funding access\n• Jan Dhan Yojana – Zero-balance bank account\n\nWhat type of business are you planning?';
    }
    return '🤖 I\'m here to help you find government schemes!\n\nPopular categories:\n🌾 Agriculture  🎓 Education  🏥 Health\n🏠 Housing  💼 Finance  👧 Women\n🔧 Skills  👴 Senior Citizens\n\nUse the "Find Schemes for Me" option for a personalized recommendation!';
  }

  void _scrollChat() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_showTranslateMenu) setState(() => _showTranslateMenu = false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F5),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: _buildAppBar(),
        ),
        body: _buildBody(),
        floatingActionButton: _currentScreen != 'ai' ? _buildFAB() : null,
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentScreen) {
      case 'home': return _buildHomeScreen();
      case 'filter': return _buildFilterScreen();
      case 'detail': return _buildDetailScreen();
      case 'ai': return _buildAIScreen();
      case 'dashboard': return _buildDashboardScreen();
      case 'search': return _buildSearchScreen();
      default: return _buildHomeScreen();
    }
  }

  // ──────────────────────────────────────
  // APP BAR — with search bar integrated
  // ──────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12),
        ],
        border: Border(
          bottom: BorderSide(
            color: AppColors.green.withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo
          GestureDetector(
            onTap: _goHome,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F4EA),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('🏛️', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Gov',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1a1a2e)),
                      ),
                      TextSpan(
                        text: 'Schemes',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1D8A48)),
                      ),
                      TextSpan(
                        text: '.AI',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1a1a2e)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Search bar in AppBar
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.only(left: 12, right: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 18),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _doSearch,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search schemes...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        contentPadding: EdgeInsets.only(left: 8, bottom: 2),
                        isDense: true,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _doSearch(_searchController.text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Go',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Google Translate button
          Stack(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showTranslateMenu = !_showTranslateMenu),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    border: Border.all(color: AppColors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('🌐', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        _languages.firstWhere((l) => l['code'] == _selectedLanguage)['name']!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.green),
                    ],
                  ),
                ),
              ),
              if (_showTranslateMenu)
                Positioned(
                  top: 38,
                  right: 0,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _languages.map((lang) {
                          final selected = lang['code'] == _selectedLanguage;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLanguage = lang['code']!;
                                _showTranslateMenu = false;
                              });
                              _showToast('Language changed to ${lang['name']}');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: selected ? const Color(0xFFE6F4EA) : Colors.transparent,
                              child: Row(
                                children: [
                                  Text(lang['flag']!, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text(
                                    lang['name']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                      color: selected ? AppColors.green : Colors.grey.shade800,
                                    ),
                                  ),
                                  if (selected) ...[
                                    const Spacer(),
                                    const Icon(Icons.check, size: 14, color: AppColors.green),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          _appBarBtn(Icons.dashboard_outlined, 'Dashboard', () => _navigate('dashboard')),
        ],
      ),
    );
  }

  Widget _appBarBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F4EA),
          border: Border.all(color: AppColors.green),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.green),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () => _navigate('ai'),
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color(0xFF1e3a8a), Color(0xFF2d4fa3)]),
          boxShadow: [BoxShadow(color: Color(0x591e3a8a), blurRadius: 20, spreadRadius: 2)],
        ),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 28))),
      ),
    );
  }

  // ──────────────────────────────────────
  // HOME SCREEN — no hero search bar
  // ──────────────────────────────────────
  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // HERO — no search bar here
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 44, 28, 72),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1D8A48), Color(0xFF0a4a24), Color(0xFF1D8A48)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🇮🇳  National Scheme Portal',
                    style: TextStyle(color: Color(0xFFbbf7d0), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(text: 'Find the Right ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                      TextSpan(text: 'Government', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFbbf7d0))),
                      TextSpan(text: '\nScheme for You', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Discover 4,600+ government schemes based on your eligibility. No middlemen, no confusion.',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _heroBadge('🤖', 'AI-Powered'),
                    const SizedBox(width: 8),
                    _heroBadge('⚡', 'Instant Match'),
                    const SizedBox(width: 8),
                    _heroBadge('🔒', 'Govt. Verified'),
                  ],
                ),
              ],
            ),
          ),

          // STATS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Row(
                children: [
                  _statCard('4,600+', 'Total Schemes'),
                  _statCard('36', 'States & UTs'),
                  _statCard('50+', 'Ministries'),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trending Schemes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('Most applied schemes this month', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 12),
                _trendingBanner(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _trendingItems.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _trendingIndex ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _trendingIndex ? AppColors.green : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // CATEGORIES
                const Center(
                  child: Text(
                    'Find schemes based\non categories',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1a1a2e), height: 1.3),
                  ),
                ),
                const SizedBox(height: 20),
                _buildCategoriesGrid(),
                const SizedBox(height: 32),

                // HOW IT WORKS
                const Text('How It Works', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('Three simple steps to find your government scheme', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 16),
                _howItWorks(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _heroBadge(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statCard(String number, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: const Border(top: BorderSide(color: AppColors.green, width: 2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Text(number, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.green)),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _trendingBanner() {
    var item = _trendingItems[_trendingIndex];
    List<Color> colors = item['colors'] as List<Color>;
    return GestureDetector(
      onTap: () => _openSchemeDetail(item['id']),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Container(
          key: ValueKey(_trendingIndex),
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x381e3a8a), blurRadius: 32)],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(item['emoji'], style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                    Text(item['desc'], style: const TextStyle(color: Color(0xFFC7E0D0), fontSize: 13)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(item['stat'], style: const TextStyle(color: Color(0xFFbbf7d0), fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'name': 'Agriculture, Rural\n& Environment', 'icon': Icons.agriculture, 'color': const Color(0xFFe8f5e9), 'iconColor': const Color(0xFF2e7d32), 'count': 833},
      {'name': 'Banking, Financial\nServices & Insurance', 'icon': Icons.account_balance, 'color': const Color(0xFFe3f2fd), 'iconColor': const Color(0xFF1565c0), 'count': 308},
      {'name': 'Business &\nEntrepreneurship', 'icon': Icons.business_center, 'color': const Color(0xFFfff8e1), 'iconColor': const Color(0xFFf57f17), 'count': 705},
      {'name': 'Education\n& Learning', 'icon': Icons.school, 'color': const Color(0xFFe8eaf6), 'iconColor': const Color(0xFF3949ab), 'count': 1089},
      {'name': 'Health\n& Wellness', 'icon': Icons.favorite, 'color': const Color(0xFFe0f7fa), 'iconColor': const Color(0xFF00838f), 'count': 283},
      {'name': 'Housing\n& Shelter', 'icon': Icons.home, 'color': const Color(0xFFe3f2fd), 'iconColor': const Color(0xFF0277bd), 'count': 130},
      {'name': 'Public Safety,\nLaw & Justice', 'icon': Icons.balance, 'color': const Color(0xFFf3e5f5), 'iconColor': const Color(0xFF6a1b9a), 'count': 29},
      {'name': 'Science, IT &\nCommunications', 'icon': Icons.science, 'color': const Color(0xFFe8f5e9), 'iconColor': const Color(0xFF1b5e20), 'count': 102},
      {'name': 'Skills &\nEmployment', 'icon': Icons.bar_chart, 'color': const Color(0xFFfff3e0), 'iconColor': const Color(0xFFe65100), 'count': 374},
      {'name': 'Social Welfare\n& Empowerment', 'icon': Icons.volunteer_activism, 'color': const Color(0xFFfce4ec), 'iconColor': const Color(0xFFad1457), 'count': 1467},
      {'name': 'Sports\n& Culture', 'icon': Icons.sports_tennis, 'color': const Color(0xFFe8f5e9), 'iconColor': const Color(0xFF2e7d32), 'count': 256},
      {'name': 'Transport &\nInfrastructure', 'icon': Icons.directions_bus, 'color': const Color(0xFFfff8e1), 'iconColor': const Color(0xFFf9a825), 'count': 98},
      {'name': 'Travel\n& Tourism', 'icon': Icons.language, 'color': const Color(0xFFe3f2fd), 'iconColor': const Color(0xFF1976d2), 'count': 94},
      {'name': 'Utility\n& Sanitation', 'icon': Icons.settings, 'color': const Color(0xFFf3e5f5), 'iconColor': const Color(0xFF7b1fa2), 'count': 58},
      {'name': 'Women\nand Child', 'icon': Icons.child_care, 'color': const Color(0xFFfce4ec), 'iconColor': const Color(0xFFc2185b), 'count': 462},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.95,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (ctx, i) {
        var cat = categories[i];
        return GestureDetector(
          onTap: () => _openCategory(
            (cat['name'] as String).replaceAll('\n', ' ').split(',').first.trim(),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cat['color'] as Color,
                  child: Icon(cat['icon'] as IconData, color: cat['iconColor'] as Color, size: 20),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${cat['count']}',
                    style: const TextStyle(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cat['name'] as String,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF1a1a2e), height: 1.3),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _howItWorks() {
    return Row(
      children: [
        _hiwCard('1', '🔍', 'Search or Browse', 'Search by keyword or pick a category'),
        _hiwCard('2', '📋', 'Check Eligibility', 'Fill age, income, occupation details'),
        _hiwCard('3', '🚀', 'Apply with Ease', 'Get document list and apply directly'),
      ],
    );
  }

  Widget _hiwCard(String step, String emoji, String title, String desc) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: const Border(bottom: BorderSide(color: AppColors.green, width: 3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
              child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(height: 6),
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF1e1b3a),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(text: 'Gov', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          TextSpan(text: 'Schemes', style: TextStyle(color: Color(0xFF4ade80), fontSize: 20, fontWeight: FontWeight.w800)),
                          TextSpan(text: '.AI', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('National Platform for Government Scheme Discovery', style: TextStyle(color: Color(0x73ffffff), fontSize: 11)),
                    const SizedBox(height: 12),
                    const Text('Digital India Corporation\nMinistry of Electronics & IT\nGovernment of India®', style: TextStyle(color: Color(0x80ffffff), fontSize: 11, height: 1.7)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Links', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 10),
                    ...['About Us', 'Contact Us', 'FAQ', 'Disclaimer', 'Privacy Policy'].map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            const Text('›', style: TextStyle(color: Color(0xFF4ade80), fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(e, style: const TextStyle(color: Color(0x99ffffff), fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 10),
                    const Text('JSPMS University\nWagholi, Pune\nMaharashtra – 412207', style: TextStyle(color: Color(0x99ffffff), fontSize: 11, height: 1.7)),
                    const SizedBox(height: 8),
                    const Text('govschemes.ai@gmail.com', style: TextStyle(color: Color(0xFF4ade80), fontSize: 11)),
                    const SizedBox(height: 4),
                    const Text('+91 9856235623', style: TextStyle(color: Color(0x8cffffff), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0x15ffffff), height: 32),
          const Text('© 2026 GovSchemes.AI — All rights reserved. Content owned by Govt. of India.', style: TextStyle(color: Color(0x5affffff), fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ──────────────────────────────────────
  // SEARCH SCREEN
  // ──────────────────────────────────────
  Widget _buildSearchScreen() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                onPressed: _goHome,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1e3a8a)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFdbeafe),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_searchResults.length} results for "${_searchController.text}"',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1e3a8a)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text('No schemes found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('Try different keywords', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _searchResults.map((s) => _schemeCard(s)).toList(),
                ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────
  // FILTER SCREEN
  // ──────────────────────────────────────
  Widget _buildFilterScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1e3a8a)),
                style: IconButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_currentCategory Schemes', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1e3a8a))),
                  const Text('Fill details to check eligibility', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16)],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFf97316), Color(0xFFfb923c)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, color: Colors.white, size: 12),
                      Text(' Eligibility Filters', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _filterField('Age', Icons.cake, TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 25', border: OutlineInputBorder()),
                      )),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _filterField('Annual Income', Icons.currency_rupee, DropdownButtonFormField<String>(
                        value: _selectedIncome,
                        hint: const Text('Select Income'),
                        onChanged: (v) => setState(() => _selectedIncome = v),
                        items: const [
                          DropdownMenuItem(value: 'below1', child: Text('Below ₹1L')),
                          DropdownMenuItem(value: '1to2.5', child: Text('₹1L – ₹2.5L')),
                          DropdownMenuItem(value: '2.5to5', child: Text('₹2.5L – ₹5L')),
                          DropdownMenuItem(value: '5to8', child: Text('₹5L – ₹8L')),
                          DropdownMenuItem(value: 'above8', child: Text('Above ₹8L')),
                        ],
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _filterField('State', Icons.location_on, DropdownButtonFormField<String>(
                        value: _selectedState,
                        hint: const Text('Select State'),
                        onChanged: (v) => setState(() => _selectedState = v),
                        items: ['Maharashtra', 'Uttar Pradesh', 'Bihar', 'Rajasthan', 'Gujarat', 'Karnataka', 'Tamil Nadu', 'Delhi', 'West Bengal', 'Madhya Pradesh']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      )),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _filterField('Occupation', Icons.person, DropdownButtonFormField<String>(
                        value: _selectedOccupation,
                        hint: const Text('Select Occupation'),
                        onChanged: (v) => setState(() => _selectedOccupation = v),
                        items: ['Student', 'Farmer', 'Salaried Employee', 'Self Employed', 'Business Owner', 'Unemployed', 'Senior Citizen', 'Homemaker']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checkEligibility,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFf97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 8),
                        Text('Check Eligibility', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_hasSearched && _eligibleSchemes.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: const Column(children: [
                Text('😔', style: TextStyle(fontSize: 40)),
                SizedBox(height: 8),
                Text('No matching schemes found', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('Try adjusting your filters', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
            ),
          if (_eligibleSchemes.isNotEmpty) ...[
            Row(children: [
              const Icon(Icons.check_circle, color: AppColors.green),
              const SizedBox(width: 8),
              Text('${_eligibleSchemes.length} Matching Schemes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 12),
            ..._eligibleSchemes.map((s) => _schemeCard(s)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _filterField(String label, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 14, color: const Color(0xFFf97316)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _schemeCard(Scheme s) {
    return GestureDetector(
      onTap: () => _openSchemeDetail(s.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: s.bg, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: s.bg.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(s.emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1e3a8a))),
                  const SizedBox(height: 2),
                  Text(s.desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    children: s.tags.map((t) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFdbeafe), borderRadius: BorderRadius.circular(20)),
                      child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1e3a8a))),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────
  // DETAIL SCREEN
  // ──────────────────────────────────────
  Widget _buildDetailScreen() {
    if (_currentScheme == null) return const SizedBox();
    Scheme s = _currentScheme!;
    var details = schemeDetails[s.id] ?? SchemeDetails('No detailed information available.', [], [], []);
    bool saved = _savedSchemes.any((e) => e.id == s.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1e3a8a)),
                style: IconButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(width: 8),
              const Text('Scheme Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1e3a8a))),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF152d6e), Color(0xFF1e3a8a)]),
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(s.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(s.ministry, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 12),
                Wrap(
                  children: s.tags.map((t) => Container(
                    margin: const EdgeInsets.only(right: 6, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DefaultTabController(
            length: 4,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                  ),
                  child: const TabBar(
                    indicator: BoxDecoration(color: Color(0xFF1e3a8a), borderRadius: BorderRadius.all(Radius.circular(10))),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    tabs: [Tab(text: 'Overview'), Tab(text: 'Benefits'), Tab(text: 'Eligibility'), Tab(text: 'Documents')],
                  ),
                ),
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    children: [
                      _detailCard('About the Scheme', details.overview),
                      _detailList('Key Benefits', details.benefits, const Color(0xFFf97316)),
                      _detailList('Eligibility Criteria', details.eligibility, const Color(0xFF1e3a8a)),
                      _detailList('Required Documents', details.documents, const Color(0xFF22c55e)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _showToast('Redirecting to official portal...'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf97316),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.launch), SizedBox(width: 8), Text('Apply Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _toggleSave,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: saved ? const Color(0xFF15803d) : const Color(0xFF1e3a8a),
                    side: BorderSide(color: saved ? const Color(0xFF22c55e) : const Color(0xFF1e3a8a)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(saved ? Icons.check_circle : Icons.bookmark_border),
                      const SizedBox(width: 6),
                      Text(saved ? 'Saved' : 'Save', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailCard(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1e3a8a))),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.7)),
          ],
        ),
      ),
    );
  }

  Widget _detailList(String title, List<String> items, Color dotColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
      ),
      child: items.isEmpty
          ? Center(child: Text('No information available', style: TextStyle(color: Colors.grey[500])))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1e3a8a))),
                  const SizedBox(height: 8),
                  ...items.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(e, style: const TextStyle(fontSize: 13.5, color: Color(0xFF374151)))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
    );
  }

  // ──────────────────────────────────────
  // AI SCREEN — with option buttons
  // ──────────────────────────────────────
  Widget _buildAIScreen() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1e3a8a)),
                style: IconButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(width: 8),
              const Text('AI Assistant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1e3a8a))),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _chatMessages.clear();
                    _conversationHistory.clear();
                    _chatStep = 0;
                    _userProfile.clear();
                    _chatMessages.add({
                      'role': 'bot',
                      'text': '👋 Hello! I\'m your AI Government Scheme Assistant.\n\nI\'ll guide you step by step to find schemes you qualify for. Let\'s start!',
                      'options': ['Find Schemes for Me', 'Ask a Specific Question'],
                    });
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh, size: 14, color: Color(0xFFdc2626)),
                      SizedBox(width: 4),
                      Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFdc2626))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF152d6e), Color(0xFF1e3a8a)]),
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2), border: Border.all(color: Colors.white.withOpacity(0.4))),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GovSchemes AI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22c55e))),
                        const SizedBox(width: 6),
                        const Text('Powered by Claude AI', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('Select options to find your schemes instantly', style: TextStyle(color: Color(0xB3ffffff), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFF),
                    child: ListView.builder(
                      controller: _chatScrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _chatMessages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (_isTyping && i == _chatMessages.length) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFdbeafe)),
                                  child: const Icon(Icons.smart_toy, color: Color(0xFF1e3a8a), size: 18),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                                  ),
                                  child: const _TypingIndicator(),
                                ),
                              ],
                            ),
                          );
                        }
                        var msg = _chatMessages[i];
                        bool isUser = msg['role'] == 'user';
                        final options = msg['options'] as List<dynamic>?;

                        return Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isUser)
                                    Container(
                                      width: 32, height: 32,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFdbeafe)),
                                      child: const Icon(Icons.smart_toy, color: Color(0xFF1e3a8a), size: 18),
                                    ),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isUser ? const Color(0xFF1e3a8a) : Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                                          bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                                        ),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                                      ),
                                      child: Text(
                                        msg['text']!,
                                        style: TextStyle(color: isUser ? Colors.white : const Color(0xFF1e293b), fontSize: 13.5, height: 1.6),
                                      ),
                                    ),
                                  ),
                                  if (isUser)
                                    Container(
                                      width: 32, height: 32,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFf97316)),
                                      child: const Icon(Icons.person, color: Colors.white, size: 18),
                                    ),
                                ],
                              ),
                            ),
                            // Options buttons (only for last bot message with options)
                            if (!isUser && options != null && i == _chatMessages.length - 1 && !_isTyping)
                              Padding(
                                padding: const EdgeInsets.only(left: 40, bottom: 12, right: 8),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: options.map((opt) => GestureDetector(
                                    onTap: () => _handleOptionTap(opt.toString()),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: const Color(0xFF1e3a8a), width: 1.5),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                                      ),
                                      child: Text(
                                        opt.toString(),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1e3a8a)),
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                // Text input for free-text questions
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          enabled: !_isTyping,
                          onSubmitted: (_) => _sendFreeText(),
                          decoration: InputDecoration(
                            hintText: _isTyping ? 'AI is thinking...' : 'Type a question or use buttons above...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: const Color(0xFFf3f4f6),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isTyping ? null : _sendFreeText,
                        icon: Icon(Icons.send_rounded, color: _isTyping ? Colors.grey[400] : Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: _isTyping ? Colors.grey[200] : const Color(0xFF1e3a8a),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────
  // DASHBOARD SCREEN
  // ──────────────────────────────────────
  Widget _buildDashboardScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1e3a8a)),
                style: IconButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(width: 8),
              const Text('My Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1e3a8a))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF152d6e), Color(0xFF1e3a8a)]),
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2), border: Border.all(color: Colors.white.withOpacity(0.5))),
                  child: const Center(child: Text('👤', style: TextStyle(fontSize: 30))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('Track saved schemes and applications', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _profileChip('${_savedSchemes.length} Saved'),
                          const SizedBox(width: 8),
                          _profileChip('${_eligibleSchemes.length} Eligible'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _dashStatCard(Icons.check_circle_outline, _eligibleSchemes.length.toString(), 'Eligible Schemes', const Color(0xFFdbeafe), const Color(0xFF1e3a8a)),
              const SizedBox(width: 16),
              _dashStatCard(Icons.bookmark_outline, _savedSchemes.length.toString(), 'Saved Schemes', const Color(0xFFffedd5), const Color(0xFFf97316)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Saved Schemes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          if (_savedSchemes.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  const Text('🔖', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 8),
                  const Text('No saved schemes yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Browse schemes and save them for later!', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _goHome,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Browse Schemes'),
                  ),
                ],
              ),
            )
          else
            ..._savedSchemes.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border(left: BorderSide(color: s.bg, width: 4)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: s.bg.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(s.emoji, style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1e3a8a))),
                        Text('${s.ministry} • ${s.tags.first}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openSchemeDetail(s.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFdbeafe), borderRadius: BorderRadius.circular(8)),
                      child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1e3a8a))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(onTap: () => _removeSaved(s.id), child: const Icon(Icons.close, color: Colors.red, size: 18)),
                ],
              ),
            )),
          const SizedBox(height: 24),
          Row(
            children: [
              _quickAction('🤖', 'AI Assistant', 'Get personalized help', () => _navigate('ai')),
              const SizedBox(width: 12),
              _quickAction('🔍', 'Browse All', 'Explore all schemes', _goHome),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _dashStatCard(IconData icon, String number, String label, Color bg, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(number, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1e3a8a))),
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(String emoji, String title, String sub, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.green)),
                    Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// TYPING INDICATOR
// ══════════════════════════════════════════════════════
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)));
    _animations = _controllers.map((c) => Tween<double>(begin: 0, end: -6).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _animations[i],
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _animations[i].value),
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
            width: 8, height: 8,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1e3a8a)),
          ),
        ),
      )),
    );
  }
}

