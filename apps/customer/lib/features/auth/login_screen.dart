import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

// Store phone number for OTP screen to access
final _phoneProvider = StateProvider<String>((ref) => '');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showError('Please enter a valid 10-digit phone number');
      return;
    }
    setState(() => _isLoading = true);
    final ok = await ref.read(authProvider.notifier).sendOtp(phone);
    setState(() => _isLoading = false);
    if (ok && mounted) {
      ref.read(_phoneProvider.notifier).state = phone;
      context.push('/otp');
    } else if (mounted) {
      final error = ref.read(authProvider).error ?? 'Failed to send OTP';
      _showError(error);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative top gradient
          Container(
            height: MediaQuery.of(context).size.height * 0.42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE23744), Color(0xFFFF6B6B)],
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_dining_rounded,
                                color: Color(0xFFE23744),
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'CraveX',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Order food you love',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Login card
                Expanded(
                  flex: 6,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1C1C1C),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Enter your phone number to continue',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                              const SizedBox(height: 28),
                              // Phone input
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F7F7),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE0E0E0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                      decoration: const BoxDecoration(
                                        border: Border(right: BorderSide(color: Color(0xFFE0E0E0))),
                                      ),
                                      child: const Row(
                                        children: [
                                          Text('🇮🇳', style: TextStyle(fontSize: 20)),
                                          SizedBox(width: 6),
                                          Text('+91', style: TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        maxLength: 10,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          counterText: '',
                                          hintText: '98765 43210',
                                          hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        onSubmitted: (_) => _sendOtp(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Send OTP button
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _sendOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE23744),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: const Color(0xFFE23744).withOpacity(0.6),
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
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Get OTP',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('or', style: TextStyle(color: Colors.grey)),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Guest mode
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () => context.go('/home'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Browse as Guest',
                                    style: TextStyle(
                                      color: Color(0xFF1C1C1C),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Text(
                                  'By continuing, you agree to our Terms & Privacy Policy',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Make phone provider accessible to otp_screen
final phoneNumberProvider = _phoneProvider;
