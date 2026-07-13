import 'dart:async';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';
import 'login_screen.dart';

class RiderOtpScreen extends ConsumerStatefulWidget {
  const RiderOtpScreen({super.key});
  @override
  ConsumerState<RiderOtpScreen> createState() => _RiderOtpScreenState();
}

class _RiderOtpScreenState extends ConsumerState<RiderOtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendCountdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) {
      _showError('Please enter the complete 6-digit OTP');
      return;
    }
    setState(() => _isLoading = true);
    final phone = ref.read(_phoneProvider);
    
    await ref.read(authProvider.notifier).verifyOtp(
      phone,
      _otp,
      AppConstants.userTypeRider,
    );
    
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.push('/dashboard');
    } else {
      _showError(authState.error ?? 'Invalid OTP');
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;
    final phone = ref.read(_phoneProvider);
    
    await ref.read(authProvider.notifier).sendOtp(phone, AppConstants.userTypeRider);
    
    final authState = ref.read(authProvider);
    if (authState.error != null) {
      _showError(authState.error!);
    } else {
      _startCountdown();
      _showSuccess('OTP sent successfully');
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

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otp.length == 6) {
      _verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(_phoneProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          const Text(
            'Verify OTP',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code sent to $phone',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 50,
                height: 60,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryRed, width: 2),
                    ),
                  ),
                  onChanged: (value) => _onDigitChanged(index, value),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _resendCountdown > 0 ? 'Resend in $_resendCountdown s' : 'Resend OTP',
                style: TextStyle(
                  color: _resendCountdown > 0 ? Colors.grey : AppTheme.primaryRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_resendCountdown == 0)
                TextButton(
                  onPressed: _resendOtp,
                  child: const Text('Resend', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: _isLoading ? 'Verifying...' : 'Verify OTP',
              onPressed: _isLoading ? null : _verifyOtp,
            ),
          ),
        ],
      ),
    );
  }
}
