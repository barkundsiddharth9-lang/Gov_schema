import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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

// --- DESIGN TOKENS (App Theme) ---
class AppColors {
  static const Color primary = Color(0xFF1B3B6F); // Dark Blue
  static const Color primaryLight = Color(0xFF2C5CA8);
  static const Color accent = Color(0xFFF28F3B); // Orange
  static const Color emerald = Color(0xFF4CAF50); // Green
  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2B2D42);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textMuted = Color(0xFFADB5BD);
  static const Color error = Color(0xFFEF233C);
  static const Color divider = Color(0xFFE9ECEF);
  static const Color border = Color(0xFFDEE2E6);
  static const Color shadow = Color(0x1A000000);
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
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            height: 1.6,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthPage(),
    );
  }
}

// --- POLICY SCREEN ---
class PolicyScreen extends StatelessWidget {
  final String type;
  const PolicyScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == 'Privacy';
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(isPrivacy ? 'Privacy Policy' : 'Terms of Service'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPrivacy ? 'Privacy Policy' : 'Terms of Service',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isPrivacy
                    ? 'Your privacy is important to us. We collect your data like age, income and occupation only to recommend suitable government schemes.'
                    : 'By using this app, you agree to our terms. This app is an AI assistant and not an official government entity.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AUTH PAGE  (Login / Sign Up tabs)
// ─────────────────────────────────────────────
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // ── Logo ──
              _buildLogo(),
              const SizedBox(height: 36),

              // ── Card ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 60,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.08),
                      blurRadius: 40,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ── Tab Bar ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: const Color(0xFF6C63FF),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white54,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Login'),
                            Tab(text: 'Sign Up'),
                          ],
                        ),
                      ),
                    ),

                    // ── Tab Views ──
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _LoginForm(
                            onSwitchToSignup: () => _tabController.animateTo(1),
                          ),
                          _SignupForm(
                            onSwitchToLogin: () => _tabController.animateTo(0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFFB06CF4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 14),
        const Text(
          'NexAuth',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your gateway to everything',
          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  LOGIN FORM
// ─────────────────────────────────────────────
class _LoginForm extends StatefulWidget {
  final VoidCallback onSwitchToSignup;
  const _LoginForm({required this.onSwitchToSignup});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  void _login() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _loading = false);
    if (!mounted) return;

    // Navigate to Main Content
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login successful! 🎉'),
        backgroundColor: Color(0xFF6C63FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to your account',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // Email
          _AuthField(
            controller: _emailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          // Password
          _AuthField(
            controller: _passCtrl,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),

          // Login Button
          _PrimaryButton(label: 'Login', loading: _loading, onPressed: _login),
          const SizedBox(height: 20),

          // Divider
          _Divider(),
          const SizedBox(height: 18),

          // OAuth Buttons
          _OAuthButton(
            label: 'Continue with Google',
            svgIcon: 'G',
            onPressed: () => _showOAuthSnack(context, 'Google'),
          ),
          const SizedBox(height: 10),
          _OAuthButton(
            label: 'Continue with GitHub',
            svgIcon: '⌥',
            dark: true,
            onPressed: () => _showOAuthSnack(context, 'GitHub'),
          ),

          const Spacer(),
          // Switch to signup
          Center(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                ),
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: 'Sign up',
                    style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = widget.onSwitchToSignup,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SIGNUP FORM
// ─────────────────────────────────────────────
class _SignupForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  const _SignupForm({required this.onSwitchToLogin});

  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  void _signup() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _loading = false);
    if (!mounted) return;

    // Navigate to Main Content or auto-login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created! Welcome aboard 🚀'),
        backgroundColor: Color(0xFF6C63FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Join us today, it\'s free!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Name
          _AuthField(
            controller: _nameCtrl,
            hint: 'Full name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),

          // Email
          _AuthField(
            controller: _emailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // Password
          _AuthField(
            controller: _passCtrl,
            hint: 'Create password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 18),

          // Signup Button
          _PrimaryButton(
            label: 'Create Account',
            loading: _loading,
            onPressed: _signup,
          ),
          const SizedBox(height: 16),

          // Divider
          _Divider(),
          const SizedBox(height: 14),

          // OAuth Buttons
          _OAuthButton(
            label: 'Sign up with Google',
            svgIcon: 'G',
            onPressed: () => _showOAuthSnack(context, 'Google'),
          ),
          const SizedBox(height: 10),
          _OAuthButton(
            label: 'Sign up with GitHub',
            svgIcon: '⌥',
            dark: true,
            onPressed: () => _showOAuthSnack(context, 'GitHub'),
          ),

          const Spacer(),
          Center(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                ),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Login',
                    style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = widget.onSwitchToLogin,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: const Color(0xFF6C63FF),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFFB06CF4)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
        ),
      ],
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final String label;
  final String svgIcon;
  final bool dark;
  final VoidCallback onPressed;

  const _OAuthButton({
    required this.label,
    required this.svgIcon,
    required this.onPressed,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: dark
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.04),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(svgIcon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showOAuthSnack(BuildContext context, String provider) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Connecting to $provider... (integrate SDK here)'),
      backgroundColor: const Color(0xFF6C63FF),
      duration: const Duration(seconds: 2),
    ),
  );
}

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

// ---------- DATABASE ----------
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
      'Covers all landholding farmer families',
    ],
    [
      'Must be a resident Indian citizen',
      'Should own cultivable land',
      'Annual family income below ₹2 lakh',
      'Valid Aadhaar card required',
      'Active bank account linked with Aadhaar',
    ],
    [
      'Aadhaar Card',
      'Land ownership documents (Khasra/Khatauni)',
      'Bank passbook copy',
      'Passport size photograph',
      'Mobile number linked to Aadhaar',
    ],
  ),
  'ayushman': SchemeDetails(
    'Ayushman Bharat PM-JAY is the world\'s largest health insurance scheme providing health cover of ₹5 lakh per family per year. It covers more than 10.74 crore poor and vulnerable families.',
    [
      '₹5 Lakh health cover per family per year',
      'Cashless treatment at empaneled hospitals',
      'Covers pre and post hospitalization expenses',
      'Over 1,500+ medical procedures covered',
      'No restriction on family size or age',
    ],
    [
      'Identified from SECC 2011 data',
      'BPL card holders',
      'Annual income below ₹2.5 lakh',
      'E-card/Golden Card required',
      'Available in most states',
    ],
    [
      'Ration Card',
      'Aadhaar Card',
      'Income Certificate',
      'Caste Certificate (if applicable)',
      'Bank Account Details',
    ],
  ),
  'pmay': SchemeDetails(
    'Pradhan Mantri Awas Yojana (Urban) aims to provide affordable housing to urban poor. The scheme provides credit-linked subsidy of 3-6.5% on home loans for EWS, LIG, and MIG categories.',
    [
      'Interest subsidy of 3-6.5% on home loans',
      'Subsidy amount up to ₹2.67 lakh',
      'No cap on loan amount for subsidy',
      'Covers 6.5 crore urban households',
      'Works with private developers too',
    ],
    [
      'Urban household without a pucca house',
      'EWS/LIG/MIG categories',
      'Annual income: EWS <₹3L, LIG <₹6L, MIG <₹18L',
      'First-time home buyer',
      'Valid Aadhaar',
    ],
    [
      'Aadhaar Card',
      'Income certificate',
      'Property documents',
      'Bank account details',
      'Affidavit of no pucca house',
    ],
  ),
  'pmsy': SchemeDetails(
    'PM Scholarship Scheme provides financial assistance of ₹25,000 per year to meritorious students for pursuing professional courses.',
    [
      '₹25,000 per year for girls, ₹20,000 for boys',
      'Covers engineering, medical, law, and management',
      'Directly credited to student bank account',
      'Renewable annually based on performance',
      '10,000+ new scholarships per year',
    ],
    [
      'Indian citizen',
      'Age between 18-25 years',
      'Minimum 60% marks in 12th standard',
      'Annual family income below ₹6 lakh',
      'Enrolled in first year of professional course',
    ],
    [
      '10th & 12th Marksheet',
      'College enrollment certificate',
      'Income certificate',
      'Bank account details',
      'Aadhaar Card',
    ],
  ),
  'nsp': SchemeDetails(
    'National Scholarship Portal is a one-stop solution for students to apply for various scholarships offered by central and state governments.',
    [
      'Access to 50+ scholarships in one portal',
      'Central and state government scholarships',
      'Minority, OBC, SC/ST scholarships',
      'Direct bank transfer of scholarship amount',
      'Real-time application tracking',
    ],
    [
      'Indian citizen students',
      'Different income criteria per scholarship',
      'Academic merit requirements vary',
      'Age 14–35 years depending on scheme',
      'Valid Aadhaar required',
    ],
    [
      'Aadhaar Card',
      'Bank Passbook',
      'Caste/Category Certificate',
      'Income Certificate',
      'Previous Year Marksheet',
    ],
  ),
  'mudra': SchemeDetails(
    'PM Mudra Yojana provides loans up to ₹10 lakh to non-corporate, non-farm small/micro enterprises through banks, MFIs, and NBFCs.',
    [
      'Shishu: loans up to ₹50,000',
      'Kishore: loans ₹50,001 to ₹5 lakh',
      'Tarun: loans ₹5 lakh to ₹10 lakh',
      'No collateral required',
      'Low interest rates',
    ],
    [
      'Indian citizen above 18 years',
      'Non-farm income generating activity',
      'Micro/small enterprise owner',
      'No defaults on previous loans',
      'Valid business plan',
    ],
    [
      'Aadhaar Card',
      'PAN Card',
      'Business address proof',
      'Bank statements (6 months)',
      'Business registration (if any)',
    ],
  ),
};

// ---------- MAIN SCREEN ----------
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

  final List<Map<String, dynamic>> _trendingItems = [
    {
      'id': 'pm-kisan',
      'emoji': '🌾',
      'name': 'PM-Kisan Yojana',
      'desc': '₹6,000/year direct income support for farmers',
      'stat': '▲ 2.1M Applications',
      'colors': [Color(0xFF1D8A48), Color(0xFF0f5c2e)],
    },
    {
      'id': 'pmay',
      'emoji': '🏠',
      'name': 'PM Awas Yojana',
      'desc': 'Affordable housing — interest subsidy up to ₹2.67L',
      'stat': '▲ 1.8M Applications',
      'colors': [Color(0xFFc2410c), Color(0xFFea580c)],
    },
    {
      'id': 'ayushman',
      'emoji': '🏥',
      'name': 'Ayushman Bharat',
      'desc': '₹5 Lakh health cover per family per year',
      'stat': '▲ 3.5M Beneficiaries',
      'colors': [Color(0xFF0369a1), Color(0xFF0284c7)],
    },
    {
      'id': 'pmsy',
      'emoji': '🎓',
      'name': 'PM Scholarship',
      'desc': 'Up to ₹25,000/year for meritorious students',
      'stat': '▲ 900K Students',
      'colors': [Color(0xFF7c3aed), Color(0xFF8b5cf6)],
    },
  ];

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedIncome, _selectedState, _selectedOccupation;

  // Claude AI config
  static const String _claudeApiKey =
      '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';
  static const String _claudeModel = 'claude-sonnet-4-20250514';

  bool _isTyping = false;
  final List<Map<String, String>> _conversationHistory = [];

  // --- Conversational Onboarding State & Lists ---
  int _onboardingStep = 0;
  final Map<String, String> _userProfile = {};

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _maritalStatuses = ['Single', 'Married', 'Widowed'];
  final List<String> _incomeRanges = [
    'Below ₹1 Lakh',
    '₹1-2.5 Lakh',
    '₹2.5-5 Lakh',
    '₹5-8 Lakh',
    'Above ₹8 Lakh',
  ];
  final List<String> _occupations = [
    'Student',
    'Farmer',
    'Salaried Employee',
    'Self Employed',
    'Business Owner',
    'Unemployed',
    'Junior / Professional',
  ];
  final List<String> _casteCategories = [
    'General',
    'OBC',
    'SC',
    'ST',
    'Prefer not to say',
  ];
  final List<String> _states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  final List<Map<String, String>> _chatMessages = [
    {
      'role': 'bot',
      'text':
          '👋 Hello! I\'m your AI Government Scheme Assistant. I\'ll help you discover schemes you\'re eligible for.\n\nLet\'s start — what\'s your name?',
    },
  ];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

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

    // Call FastAPI AI recommendation endpoint
    final apiResults = await ApiService.recommend(
      age: age,
      income: _selectedIncome!,
      occupation: (_selectedOccupation ?? 'farmer').toLowerCase().replaceAll(
        ' ',
        '_',
      ),
      gender: 'male', // default; can be extended
    );

    if (apiResults.isNotEmpty) {
      // Convert ApiScheme → local Scheme for display
      final List schemsFromAPI = apiResults['results'] ?? [];
      final matched = schemsFromAPI.map((a) {
        final apiScheme = ApiScheme.fromJson(a);
        // Find matching local scheme by id
        for (var list in schemesDB.values) {
          try {
            return list.firstWhere((s) => s.id == apiScheme.id);
          } catch (_) {}
        }
        // Fallback: build a minimal Scheme from API data
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
      _showToast('🎯 AI found ${matched.length} matching schemes!');
    } else {
      // Fallback to local filtering if API offline
      List<Scheme> pool = schemesDB[_currentCategory] ?? [];
      List<Scheme> results = pool.where((s) {
        bool ok = true;
        if (age != 0 && (age < s.age[0] || age > s.age[1])) ok = false;
        if (_selectedIncome != null &&
            s.income.isNotEmpty &&
            !s.income.contains(_selectedIncome))
          ok = false;
        if (_selectedOccupation != null &&
            s.occ.isNotEmpty &&
            !s.occ.contains(_selectedOccupation))
          ok = false;
        return ok;
      }).toList();
      setState(() {
        _eligibleSchemes = results;
        _hasSearched = true;
      });
      _showToast('Found ${results.length} eligible schemes (offline mode)');
    }
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    // Try AI-powered search via FastAPI first
    final apiResults = await ApiService.search(query.trim());
    if (apiResults.isNotEmpty) {
      final matched = apiResults.map((a) {
        for (var list in schemesDB.values) {
          try {
            return list.firstWhere((s) => s.id == a.id);
          } catch (_) {}
        }
        return Scheme(
          id: a.id,
          name: a.name,
          ministry: a.category,
          emoji: '📋',
          desc: a.description,
          bg: const Color(0xFF1D8A48),
          tags: [],
          income: [],
          occ: [],
          age: [0, 100],
        );
      }).toList();
      setState(() {
        _searchResults = matched;
        _hasSearched = true;
        _previousScreen = 'home';
        _currentScreen = 'search';
      });
      return;
    }

    // Fallback: local keyword search
    String q = query.toLowerCase();
    List<Scheme> results = [];
    for (var list in schemesDB.values) {
      for (var s in list) {
        if (s.name.toLowerCase().contains(q) ||
            s.desc.toLowerCase().contains(q) ||
            s.ministry.toLowerCase().contains(q) ||
            s.tags.any((t) => t.toLowerCase().contains(q))) {
          results.add(s);
        }
      }
    }
    setState(() {
      _searchResults = results;
      _hasSearched = true;
      _previousScreen = 'home';
      _currentScreen = 'search';
    });
  }

  void _openSchemeDetail(String id) {
    Scheme? scheme;
    for (var list in schemesDB.values) {
      try {
        scheme = list.firstWhere((s) => s.id == id);
        break;
      } catch (_) {}
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
        backgroundColor: const Color(0xFF1e3a8a),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Builds the Claude system prompt with full scheme knowledge
  String _buildSystemPrompt() {
    final schemesSummary = StringBuffer();
    schemesDB.forEach((category, schemes) {
      schemesSummary.writeln('\n=== $category Schemes ===');
      for (final s in schemes) {
        schemesSummary.writeln(
          '• ${s.name} (ID: ${s.id}) | ${s.ministry} | ${s.desc} | Tags: ${s.tags.join(", ")} | Age: ${s.age[0]}-${s.age[1]}',
        );
      }
    });

    return """You are an expert Indian Government Scheme Eligibility Engine. 
Your job is to provide STRICT, LOGIC-BASED, RULE-BOUND scheme recommendations.
You must NEVER recommend a scheme unless the user satisfies ALL mandatory eligibility criteria.

SCHEME DATABASE:
${schemesSummary.toString()}

PROCESS:
STEP 1: Profile Verification
Verify we have: Age, Gender, State, District, Exact Annual Income, Occupation, Category (Gen/OBC/SC/ST), Special status (Farmer/Student/Widow/etc), Land ownership, and BPL/APL status.

STEP 2: Strict Eligibility Matching
- Check mandatory conditions for each scheme in SCHEME DATABASE.
- If ANY condition fails → REJECT.
- Do not assume or approximate.

STEP 3: Output Format
For each recommended scheme, show:
- Scheme Name
- Why Eligible (bullet points)
- Benefit amount
- Required documents
- (Internal context: Why others were rejected if asked)

STEP 4: Safety & Transparency
- Do NOT guess missing information. Ask if unsure.
- Behave like a strict government verification officer.
- Accuracy is paramount. Respond in the user's language (Hindi/English).""";
  }

  /// Calls the Claude API with conversation history for context-aware responses
  Future<String> _callClaudeAPI(String userMessage) async {
    try {
      // Add user message to history
      _conversationHistory.add({'role': 'user', 'content': userMessage});

      // Keep history manageable (last 20 exchanges)
      final history = _conversationHistory.length > 40
          ? _conversationHistory.sublist(_conversationHistory.length - 40)
          : _conversationHistory;

      final response = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _claudeApiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _claudeModel,
              'max_tokens': 1024,
              'system': _buildSystemPrompt(),
              'messages': history,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['content'][0]['text'] as String;
        // Add assistant response to history
        _conversationHistory.add({'role': 'assistant', 'content': reply});
        return reply;
      } else {
        // If API call fails, use smart local fallback
        return _getSmartFallback(userMessage);
      }
    } catch (e) {
      return _getSmartFallback(userMessage);
    }
  }

  /// Smart local fallback when API is unavailable
  String _getSmartFallback(String msg) {
    String m = msg.toLowerCase();
    if (m.contains('farmer') ||
        m.contains('kisan') ||
        m.contains('agriculture')) {
      return '🌾 **For Farmers:**\n\n• **PM-Kisan Yojana** – ₹6,000/year direct income support\n• **Kisan Credit Card** – Easy low-interest agricultural credit\n• **PM Fasal Bima Yojana** – Crop insurance against losses\n\nWhich scheme would you like more details on?';
    }
    if (m.contains('education') ||
        m.contains('school') ||
        m.contains('college') ||
        m.contains('scholarship')) {
      return '🎓 **For Education:**\n\n• **PM Scholarship** – ₹25,000/yr (girls) | ₹20,000/yr (boys)\n• **National Scholarship Portal** – 50+ scholarships in one place\n• **PM Research Fellowship** – ₹70,000/month for PhD students\n\nWhat level of education are you at?';
    }
    if (m.contains('health') ||
        m.contains('medical') ||
        m.contains('hospital') ||
        m.contains('insurance')) {
      return '🏥 **For Health:**\n\n• **Ayushman Bharat PM-JAY** – ₹5 Lakh health cover per family\n• **Janani Suraksha Yojana** – Maternity cash benefits\n\nAyushman Bharat is one of the world\'s largest health schemes. Want to check your eligibility?';
    }
    if (m.contains('housing') ||
        m.contains('house') ||
        m.contains('home') ||
        m.contains('awas')) {
      return '🏠 **For Housing:**\n\n• **PM Awas Yojana (Urban)** – Interest subsidy up to ₹2.67 lakh\n• Covers EWS (income <₹3L), LIG (<₹6L), MIG (<₹18L) categories\n\nAre you looking for urban or rural housing support?';
    }
    if (m.contains('business') ||
        m.contains('loan') ||
        m.contains('startup') ||
        m.contains('mudra')) {
      return '💼 **For Business:**\n\n• **PM Mudra Yojana** – Collateral-free loans up to ₹10 lakh\n• **Startup India** – Tax benefits, mentorship & funding access\n• **Jan Dhan Yojana** – Zero-balance bank account with RuPay card\n\nWhat type of business are you planning?';
    }
    if (m.contains('senior') ||
        m.contains('pension') ||
        m.contains('old age') ||
        m.contains('elderly')) {
      return '👴 **For Senior Citizens:**\n\n• **Indira Gandhi Old Age Pension** – Monthly pension for BPL seniors\n• **Ayushman Bharat** – ₹5 Lakh health coverage\n\nMost senior citizen schemes require age 60+. Would you like eligibility details?';
    }
    if (m.contains('women') ||
        m.contains('girl') ||
        m.contains('mahila') ||
        m.contains('beti')) {
      return '👩 **For Women & Girls:**\n\n• **Beti Bachao Beti Padhao** – Girl child welfare & education\n• **Sukanya Samriddhi Yojana** – 8.2% interest savings for daughters\n• **Janani Suraksha Yojana** – Safe maternity benefits\n\nWhich scheme interests you most?';
    }
    if (m.contains('skill') ||
        m.contains('training') ||
        m.contains('job') ||
        m.contains('employment')) {
      return '🔧 **For Skill & Employment:**\n\n• **PM Kaushal Vikas Yojana** – Free skill training with stipend\n• **MGNREGA** – 100 days guaranteed employment (rural)\n• **DDU-GKY** – Rural youth skilling & placement\n\nWhat is your current occupation or skill interest?';
    }
    // Generic helpful response
    return '🤖 I\'m here to help you find the perfect government scheme!\n\n**Popular categories:**\n🌾 Agriculture  🎓 Education  🏥 Health\n🏠 Housing  💼 Finance  👧 Women\n🔧 Skills  👴 Senior Citizens\n\nTell me about yourself — your age, occupation, and income — and I\'ll find the best matching schemes for you!';
  }

  Widget _buildOnboardingOptions() {
    List<String> options = [];
    switch (_onboardingStep) {
      case 2:
        options = _genders;
        break;
      case 3:
        options = _states;
        break;
      case 4:
        // District types
        return const SizedBox.shrink();
      case 5:
        // Exact Income types
        return const SizedBox.shrink();
      case 6:
        options = _occupations;
        break;
      case 7:
        options = _casteCategories;
        break;
      case 8:
        options = [
          'None',
          'Farmer',
          'Student',
          'Widow',
          'Ex-Serviceman',
          'Disabled',
          'Senior Citizen',
        ];
        break;
      case 9:
        options = ['Yes', 'No'];
        break;
      case 10:
        options = ['BPL', 'APL', 'None'];
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map(
              (opt) => OutlinedButton(
                onPressed: () {
                  _chatController.text = opt;
                  _sendMessage();
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  opt,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _sendMessage() {
    String text = _chatController.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'text': text});
      _chatController.clear();
      _isTyping = true;
    });
    _scrollChat();

    // Handling Onboarding Flow
    Future.delayed(const Duration(milliseconds: 1000), () async {
      String reply = "";
      bool flowComplete = false;

      switch (_onboardingStep) {
        case 0:
          _userProfile['name'] = text;
          reply =
              "Nice to meet you, ${_userProfile['name']}! What is your age?";
          _onboardingStep = 1;
          break;
        case 1:
          _userProfile['age'] = text;
          reply = "What is your gender?";
          _onboardingStep = 2;
          break;
        case 2:
          _userProfile['gender'] = text;
          reply = "Which state do you reside in?";
          _onboardingStep = 3;
          break;
        case 3:
          _userProfile['state'] = text;
          reply = "What is your district?";
          _onboardingStep = 4;
          break;
        case 4:
          _userProfile['district'] = text;
          reply = "What is your exact annual household income (e.g. 150000)?";
          _onboardingStep = 5;
          break;
        case 5:
          _userProfile['income_exact'] = text;
          reply = "What is your current occupation?";
          _onboardingStep = 6;
          break;
        case 6:
          _userProfile['occupation'] = text;
          reply = "What is your caste category?";
          _onboardingStep = 7;
          break;
        case 7:
          _userProfile['caste'] = text;
          reply =
              "Do you have any special status? (Farmer/Student/Widow/Ex-Serviceman/Disabled/None)";
          _onboardingStep = 8;
          break;
        case 8:
          _userProfile['special_status'] = text;
          reply = "Do you or your family own agricultural land?";
          _onboardingStep = 9;
          break;
        case 9:
          _userProfile['land_ownership'] = text;
          reply = "What is your Ration Card status (BPL / APL / None)?";
          _onboardingStep = 10;
          break;
        case 10:
          _userProfile['ration_status'] = text;
          _onboardingStep = 11;
          flowComplete = true;
          break;
        default:
          reply = await _callClaudeAPI(text);
      }

      if (flowComplete) {
        if (mounted) {
          setState(() {
            _chatMessages.add({
              'role': 'bot',
              'text':
                  "Profile data locked. Running strict eligibility verification...",
            });
          });
          _scrollChat();
        }

        final profileSummary = _userProfile.entries
            .map((e) => "${e.key}: ${e.value}")
            .join(", ");
        reply = await _callClaudeAPI("Verify eligibility for: $profileSummary");
      }

      if (mounted) {
        setState(() {
          _isTyping = false;
          _chatMessages.add({'role': 'bot', 'text': reply});
        });
        _scrollChat();
      }
    });
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

  void _askQuick(String q) {
    _chatController.text = q;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: _buildAppBar(),
      ),
      body: _buildBody(),
      floatingActionButton: _currentScreen != 'ai' ? _buildFAB() : null,
    );
  }

  Widget _buildBody() {
    switch (_currentScreen) {
      case 'home':
        return _buildHomeScreen();
      case 'filter':
        return _buildFilterScreen();
      case 'detail':
        return _buildDetailScreen();
      case 'ai':
        return _buildAIScreen();
      case 'dashboard':
        return _buildDashboardScreen();
      case 'search':
        return _buildSearchScreen();
      default:
        return _buildHomeScreen();
    }
  }

  // ──────────────────────────────────────
  // APP BAR
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
            color: const Color(0xFF1D8A48).withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goHome,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        'assets/emblem.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Gov',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: Color(0xFF1a1a2e),
                            ),
                          ),
                          TextSpan(
                            text: 'Schemes',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: Color(0xFF1D8A48),
                            ),
                          ),
                          TextSpan(
                            text: '.AI',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: Color(0xFF1a1a2e),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'National Scheme Discovery Platform',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          _appBarBtn(
            Icons.dashboard_outlined,
            'Dashboard',
            () => _navigate('dashboard'),
          ),
          const SizedBox(width: 8),
          _appBarBtn(
            Icons.person_outline,
            'Profile',
            () => _navigate('dashboard'),
          ),
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
          border: Border.all(color: const Color(0xFF1D8A48)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF1D8A48)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D8A48),
              ),
            ),
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
          gradient: LinearGradient(
            colors: [Color(0xFF1e3a8a), Color(0xFF2d4fa3)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x591e3a8a),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(child: Text('🤖', style: TextStyle(fontSize: 28))),
      ),
    );
  }

  // ──────────────────────────────────────
  // HOME SCREEN
  // ──────────────────────────────────────
  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // HERO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 44, 28, 88),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1D8A48),
                  Color(0xFF0a4a24),
                  Color(0xFF1D8A48),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🇮🇳  National Scheme Portal',
                    style: TextStyle(
                      color: Color(0xFFbbf7d0),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Find the Right ',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: 'Government',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFbbf7d0),
                        ),
                      ),
                      TextSpan(
                        text: '\nScheme for You',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Discover 4,600+ government schemes based on your eligibility. No middlemen, no confusion.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                // SEARCH BAR
                Container(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 6,
                    top: 6,
                    bottom: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: _doSearch,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText:
                                'Search by scheme name, benefit, or category...',
                            hintStyle: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _doSearch(_searchController.text),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D8A48),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Search',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // STATS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Transform.translate(
              offset: const Offset(0, -52),
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
                // TRENDING
                const Text(
                  'Trending Schemes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Most applied schemes this month — tap to view details',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                _trendingBanner(),
                const SizedBox(height: 8),
                // Dots indicator
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
                        color: i == _trendingIndex
                            ? const Color(0xFF1D8A48)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // CATEGORIES
                const Center(
                  child: Text(
                    'Find schemes based\non categories',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1a1a2e),
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildCategoriesGrid(),
                const SizedBox(height: 32),

                // HOW IT WORKS
                const Text(
                  'How It Works',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Three simple steps to find your government scheme',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
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

  Widget _statCard(String number, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            top: BorderSide(color: Color(0xFF1D8A48), width: 2),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D8A48),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
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
            boxShadow: const [
              BoxShadow(color: Color(0x381e3a8a), blurRadius: 32),
            ],
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
                    Text(
                      item['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      item['desc'],
                      style: const TextStyle(
                        color: Color(0xFFC7E0D0),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item['stat'],
                        style: const TextStyle(
                          color: Color(0xFFbbf7d0),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {
        'name': 'Agriculture, Rural\n& Environment',
        'icon': Icons.agriculture,
        'color': const Color(0xFFe8f5e9),
        'iconColor': const Color(0xFF2e7d32),
        'count': 833,
      },
      {
        'name': 'Banking, Financial\nServices & Insurance',
        'icon': Icons.account_balance,
        'color': const Color(0xFFe3f2fd),
        'iconColor': const Color(0xFF1565c0),
        'count': 308,
      },
      {
        'name': 'Business &\nEntrepreneurship',
        'icon': Icons.business_center,
        'color': const Color(0xFFfff8e1),
        'iconColor': const Color(0xFFf57f17),
        'count': 705,
      },
      {
        'name': 'Education\n& Learning',
        'icon': Icons.school,
        'color': const Color(0xFFe8eaf6),
        'iconColor': const Color(0xFF3949ab),
        'count': 1089,
      },
      {
        'name': 'Health\n& Wellness',
        'icon': Icons.favorite,
        'color': const Color(0xFFe0f7fa),
        'iconColor': const Color(0xFF00838f),
        'count': 283,
      },
      {
        'name': 'Housing\n& Shelter',
        'icon': Icons.home,
        'color': const Color(0xFFe3f2fd),
        'iconColor': const Color(0xFF0277bd),
        'count': 130,
      },
      {
        'name': 'Public Safety, Law\n& Justice',
        'icon': Icons.balance,
        'color': const Color(0xFFf3e5f5),
        'iconColor': const Color(0xFF6a1b9a),
        'count': 29,
      },
      {
        'name': 'Science, IT &\nCommunications',
        'icon': Icons.science,
        'color': const Color(0xFFe8f5e9),
        'iconColor': const Color(0xFF1b5e20),
        'count': 102,
      },
      {
        'name': 'Skills\n& Employment',
        'icon': Icons.bar_chart,
        'color': const Color(0xFFfff3e0),
        'iconColor': const Color(0xFFe65100),
        'count': 374,
      },
      {
        'name': 'Social Welfare\n& Empowerment',
        'icon': Icons.volunteer_activism,
        'color': const Color(0xFFfce4ec),
        'iconColor': const Color(0xFFad1457),
        'count': 1467,
      },
      {
        'name': 'Sports\n& Culture',
        'icon': Icons.sports_tennis,
        'color': const Color(0xFFe8f5e9),
        'iconColor': const Color(0xFF2e7d32),
        'count': 256,
      },
      {
        'name': 'Transport &\nInfrastructure',
        'icon': Icons.directions_bus,
        'color': const Color(0xFFfff8e1),
        'iconColor': const Color(0xFFf9a825),
        'count': 98,
      },
      {
        'name': 'Travel\n& Tourism',
        'icon': Icons.language,
        'color': const Color(0xFFe3f2fd),
        'iconColor': const Color(0xFF1976d2),
        'count': 94,
      },
      {
        'name': 'Utility\n& Sanitation',
        'icon': Icons.settings,
        'color': const Color(0xFFf3e5f5),
        'iconColor': const Color(0xFF7b1fa2),
        'count': 58,
      },
      {
        'name': 'Women\nand Child',
        'icon': Icons.child_care,
        'color': const Color(0xFFfce4ec),
        'iconColor': const Color(0xFFc2185b),
        'count': 462,
      },
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (ctx, i) {
        var cat = categories[i];
        return GestureDetector(
          onTap: () => _openCategory(
            (cat['name'] as String)
                .replaceAll('\n', ' ')
                .split(',')
                .first
                .trim(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: cat['color'] as Color,
                child: Icon(
                  cat['icon'] as IconData,
                  color: cat['iconColor'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${cat['count']} Schemes',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF1D8A48),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cat['name'] as String,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a1a2e),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _howItWorks() {
    return Row(
      children: [
        _hiwCard(
          '1',
          '🔍',
          'Search or Browse',
          'Search by keyword or pick a category',
        ),
        _hiwCard(
          '2',
          '📋',
          'Check Eligibility',
          'Fill age, income, occupation details',
        ),
        _hiwCard(
          '3',
          '🚀',
          'Apply with Ease',
          'Get document list and apply directly',
        ),
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
          border: const Border(
            bottom: BorderSide(color: Color(0xFF1D8A48), width: 3),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1D8A48),
              ),
              child: Center(
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
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
                          TextSpan(
                            text: 'Gov',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: 'Schemes',
                            style: TextStyle(
                              color: Color(0xFF4ade80),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: '.AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'National Platform for Government Scheme Discovery',
                      style: TextStyle(color: Color(0x73ffffff), fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Digital India Corporation\nMinistry of Electronics & IT\nGovernment of India®',
                      style: TextStyle(
                        color: Color(0x80ffffff),
                        fontSize: 11,
                        height: 1.7,
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
                    const Text(
                      'Quick Links',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...[
                      'About Us',
                      'Contact Us',
                      'FAQ',
                      'Disclaimer',
                      'Privacy Policy',
                    ].map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            const Text(
                              '›',
                              style: TextStyle(
                                color: Color(0xFF4ade80),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              e,
                              style: const TextStyle(
                                color: Color(0x99ffffff),
                                fontSize: 12,
                              ),
                            ),
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
                    const Text(
                      'Contact',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'JSPMS University\nWagholi, Pune\nMaharashtra – 412207',
                      style: TextStyle(
                        color: Color(0x99ffffff),
                        fontSize: 11,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'govschemes.ai@gmail.com',
                      style: TextStyle(color: Color(0xFF4ade80), fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '+91 9856235623',
                      style: TextStyle(color: Color(0x8cffffff), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0x15ffffff), height: 32),
          const Text(
            '© 2026 GovSchemes.AI — All rights reserved. Content owned by Govt. of India.',
            style: TextStyle(color: Color(0x5affffff), fontSize: 11),
            textAlign: TextAlign.center,
          ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 6,
                    top: 4,
                    bottom: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F5),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey, size: 18),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: _doSearch,
                          autofocus: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search schemes...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      const Text(
                        'No schemes found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Try searching with different keywords',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${_searchResults.length} Results Found',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1e3a8a),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._searchResults.map((s) => _schemeCard(s)).toList(),
                  ],
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
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_currentCategory Schemes',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1e3a8a),
                    ),
                  ),
                  const Text(
                    'Fill details to check eligibility',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFf97316), Color(0xFFfb923c)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, color: Colors.white, size: 12),
                      Text(
                        ' Eligibility Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _filterField(
                        'Age',
                        Icons.cake,
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 25',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _filterField(
                        'Annual Income',
                        Icons.currency_rupee,
                        DropdownButtonFormField<String>(
                          value: _selectedIncome,
                          hint: const Text('Select Income'),
                          onChanged: (v) => setState(() => _selectedIncome = v),
                          items: const [
                            DropdownMenuItem(
                              value: 'below1',
                              child: Text('Below ₹1L'),
                            ),
                            DropdownMenuItem(
                              value: '1to2.5',
                              child: Text('₹1L – ₹2.5L'),
                            ),
                            DropdownMenuItem(
                              value: '2.5to5',
                              child: Text('₹2.5L – ₹5L'),
                            ),
                            DropdownMenuItem(
                              value: '5to8',
                              child: Text('₹5L – ₹8L'),
                            ),
                            DropdownMenuItem(
                              value: 'above8',
                              child: Text('Above ₹8L'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _filterField(
                        'State',
                        Icons.location_on,
                        DropdownButtonFormField<String>(
                          value: _selectedState,
                          hint: const Text('Select State'),
                          onChanged: (v) => setState(() => _selectedState = v),
                          items:
                              [
                                    'Maharashtra',
                                    'Uttar Pradesh',
                                    'Bihar',
                                    'Rajasthan',
                                    'Gujarat',
                                    'Karnataka',
                                    'Tamil Nadu',
                                    'Delhi',
                                    'West Bengal',
                                    'Madhya Pradesh',
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _filterField(
                        'Occupation',
                        Icons.person,
                        DropdownButtonFormField<String>(
                          value: _selectedOccupation,
                          hint: const Text('Select Occupation'),
                          onChanged: (v) =>
                              setState(() => _selectedOccupation = v),
                          items:
                              [
                                    'Student',
                                    'Farmer',
                                    'Salaried Employee',
                                    'Self Employed',
                                    'Business Owner',
                                    'Unemployed',
                                    'Senior Citizen',
                                    'Homemaker',
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 8),
                        Text(
                          'Check Eligibility',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Text('😔', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text(
                    'No matching schemes found',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Try adjusting your filters',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          if (_eligibleSchemes.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF1D8A48)),
                const SizedBox(width: 8),
                Text(
                  '${_eligibleSchemes.length} Matching Schemes',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
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
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFFf97316)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
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
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: s.bg.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(s.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1e3a8a),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.desc,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    children: s.tags
                        .map(
                          (t) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFdbeafe),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1e3a8a),
                              ),
                            ),
                          ),
                        )
                        .toList(),
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
    var details =
        schemeDetails[s.id] ??
        SchemeDetails(
          'No detailed information available for this scheme.',
          [],
          [],
          [],
        );
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
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Scheme Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1e3a8a),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF152d6e), Color(0xFF1e3a8a)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(
                  s.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  s.ministry,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Wrap(
                  children: s.tags
                      .map(
                        (t) => Container(
                          margin: const EdgeInsets.only(right: 6, bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const TabBar(
                    indicator: BoxDecoration(
                      color: Color(0xFF1e3a8a),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(text: 'Overview'),
                      Tab(text: 'Benefits'),
                      Tab(text: 'Eligibility'),
                      Tab(text: 'Documents'),
                    ],
                  ),
                ),
                SizedBox(
                  height: 280,
                  child: TabBarView(
                    children: [
                      _detailCard('About the Scheme', details.overview),
                      _detailList(
                        'Key Benefits',
                        details.benefits,
                        const Color(0xFFf97316),
                      ),
                      _detailList(
                        'Eligibility Criteria',
                        details.eligibility,
                        const Color(0xFF1e3a8a),
                      ),
                      _detailList(
                        'Required Documents',
                        details.documents,
                        const Color(0xFF22c55e),
                      ),
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
                  onPressed: () =>
                      _showToast('Redirecting to official portal...'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf97316),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.launch),
                      SizedBox(width: 8),
                      Text(
                        'Apply Now',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _toggleSave,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: saved
                        ? const Color(0xFF15803d)
                        : const Color(0xFF1e3a8a),
                    side: BorderSide(
                      color: saved
                          ? const Color(0xFF22c55e)
                          : const Color(0xFF1e3a8a),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(saved ? Icons.check_circle : Icons.bookmark_border),
                      const SizedBox(width: 6),
                      Text(
                        saved ? 'Saved' : 'Save',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Share / more info row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF1D8A48),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'For complete details, visit the official MyScheme or India.gov.in portal.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1e3a8a),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.7,
              ),
            ),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
        ],
      ),
      child: items.isEmpty
          ? Center(
              child: Text(
                'No information available',
                style: TextStyle(color: Colors.grey[500]),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1e3a8a),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ──────────────────────────────────────
  // AI ASSISTANT SCREEN
  // ──────────────────────────────────────
  Widget _buildAIScreen() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1e3a8a)),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Assistant',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1e3a8a),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _chatMessages.clear();
                    _conversationHistory.clear();
                    _chatMessages.add({
                      'role': 'bot',
                      'text':
                          '👋 Chat cleared! How can I help you with government schemes today?',
                    });
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFfee2e2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh, size: 14, color: Color(0xFFdc2626)),
                      SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFdc2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // AI Profile card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF152d6e), Color(0xFF1e3a8a)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GovSchemes AI (Claude)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF22c55e),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Powered by Claude AI',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Your intelligent scheme advisor',
                      style: TextStyle(color: Color(0xB3ffffff), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Quick Questions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickQ(
                '🌾 Farmer Schemes',
                'What schemes are available for farmers?',
              ),
              _quickQ(
                '🎓 Scholarships',
                'Best education scholarships for students?',
              ),
              _quickQ(
                '🏥 Health Schemes',
                'Health insurance schemes available?',
              ),
              _quickQ(
                '🏠 Housing Help',
                'Housing schemes for low income families?',
              ),
              _quickQ('💼 Business Loan', 'Business loan schemes available?'),
              _quickQ(
                '👴 Senior Pension',
                'Pension schemes for senior citizens?',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Chat
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                ),
              ],
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
                        // Typing indicator as last item
                        if (_isTyping && i == _chatMessages.length) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFdbeafe),
                                  ),
                                  child: const Icon(
                                    Icons.smart_toy,
                                    color: Color(0xFF1e3a8a),
                                    size: 18,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const _TypingIndicator(),
                                ),
                              ],
                            ),
                          );
                        }
                        var msg = _chatMessages[i];
                        bool isUser = msg['role'] == 'user';
                        bool isSchemeCard = msg['type'] == 'scheme_card';
                        bool isLastMessage = i == _chatMessages.length - 1;

                        return Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: isUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isUser)
                                    Container(
                                      width: 32,
                                      height: 32,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFdbeafe),
                                      ),
                                      child: const Icon(
                                        Icons.smart_toy,
                                        color: Color(0xFF1e3a8a),
                                        size: 18,
                                      ),
                                    ),
                                  Flexible(
                                    child: InkWell(
                                      onTap: isSchemeCard
                                          ? () => _openSchemeDetail(msg['id']!)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isUser
                                              ? const Color(0xFF1e3a8a)
                                              : Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(16),
                                            topRight: const Radius.circular(16),
                                            bottomLeft: isUser
                                                ? const Radius.circular(16)
                                                : const Radius.circular(4),
                                            bottomRight: isUser
                                                ? const Radius.circular(4)
                                                : const Radius.circular(16),
                                          ),
                                          border: isSchemeCard
                                              ? Border.all(
                                                  color: const Color(
                                                    0xFF1e3a8a,
                                                  ).withOpacity(0.3),
                                                )
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.06,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              msg['text']!,
                                              style: TextStyle(
                                                color: isUser
                                                    ? Colors.white
                                                    : const Color(0xFF1e293b),
                                                fontSize: 13.5,
                                                height: 1.6,
                                              ),
                                            ),
                                            if (isSchemeCard)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  'Tap to view details →',
                                                  style: TextStyle(
                                                    color: Color(0xFF1e3a8a),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isUser)
                                    Container(
                                      width: 32,
                                      height: 32,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFf97316),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Interactive Options
                            if (!isUser && isLastMessage && !_isTyping)
                              _buildOnboardingOptions(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          enabled: !_isTyping,
                          onSubmitted: (_) => _sendMessage(),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: _isTyping
                                ? 'Claude AI is thinking...'
                                : 'Ask about any scheme...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFf3f4f6),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isTyping ? null : _sendMessage,
                        icon: Icon(
                          Icons.send_rounded,
                          color: _isTyping ? Colors.grey[400] : Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: _isTyping
                              ? Colors.grey[200]
                              : const Color(0xFF1e3a8a),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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

  Widget _quickQ(String label, String question) {
    return GestureDetector(
      onTap: () => _askQuick(question),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFdbeafe)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1e3a8a),
          ),
        ),
      ),
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
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'My Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1e3a8a),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF152d6e), Color(0xFF1e3a8a)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: const Center(
                    child: Text('👤', style: TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Track saved schemes and applications',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
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
          // Stats
          Row(
            children: [
              _dashStatCard(
                Icons.check_circle_outline,
                _eligibleSchemes.length.toString(),
                'Eligible Schemes',
                const Color(0xFFdbeafe),
                const Color(0xFF1e3a8a),
              ),
              const SizedBox(width: 16),
              _dashStatCard(
                Icons.bookmark_outline,
                _savedSchemes.length.toString(),
                'Saved Schemes',
                const Color(0xFFffedd5),
                const Color(0xFFf97316),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Saved schemes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saved Schemes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              if (_savedSchemes.isNotEmpty)
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See All',
                    style: TextStyle(color: Color(0xFF1e3a8a)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_savedSchemes.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🔖', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 8),
                  const Text(
                    'No saved schemes yet',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse schemes and save them for later!',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _goHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D8A48),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Browse Schemes'),
                  ),
                ],
              ),
            )
          else
            ..._savedSchemes.map(
              (s) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: s.bg, width: 4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: s.bg.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          s.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1e3a8a),
                            ),
                          ),
                          Text(
                            '${s.ministry} • ${s.tags.first}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openSchemeDetail(s.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFdbeafe),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1e3a8a),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeSaved(s.id),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Application progress
          const Text(
            'Application Status (Demo)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _progressItem('PM-Kisan Yojana', 0.65, const Color(0xFF15803d)),
          _progressItem('Ayushman Bharat', 0.40, const Color(0xFF0369a1)),
          _progressItem('PM Scholarship', 0.80, const Color(0xFF7c3aed)),
          const SizedBox(height: 24),
          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _quickAction(
                '🤖',
                'AI Assistant',
                'Get personalized help',
                () => _navigate('ai'),
              ),
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _dashStatCard(
    IconData icon,
    String number,
    String label,
    Color bg,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1e3a8a),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressItem(String name, double value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    String emoji,
    String title,
    String sub,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1D8A48).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1D8A48),
                      ),
                    ),
                    Text(
                      sub,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
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

// ──────────────────────────────────────
// TYPING INDICATOR WIDGET
// ──────────────────────────────────────
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
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _animations = _controllers.map((c) {
      return Tween<double>(
        begin: 0,
        end: -6,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1e3a8a),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
