import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

final _phoneProvider = StateProvider<String>((ref) => '');

class RiderLoginScreen extends ConsumerStatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  ConsumerState<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends ConsumerState<RiderLoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
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
    
    await ref.read(authProvider.notifier).sendOtp(phone, AppConstants.userTypeRider);
    
    setState(() => _isLoading = false);
    
    final authState = ref.read(authProvider);
    if (authState.error != null) {
      _showError(authState.error!);
    } else if (mounted) {
      ref.read(_phoneProvider.notifier).state = phone;
      context.push('/otp');
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delivery_dining_rounded, size: 40, color: AppTheme.primaryRed),
              ),
              const SizedBox(height: 24),
              const Text(
                'Delivery Partner',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
              ),
              const SizedBox(height: 8),
              Text(
                'Earn with CraveX deliveries',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 48),
              const Text(
                'Phone Number',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1C)),
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _phoneController,
                hintText: 'Enter 10-digit phone number',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_rounded,
                maxLength: 10,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: _isLoading ? 'Sending OTP...' : 'Send OTP',
                  onPressed: _isLoading ? null : _sendOtp,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/onboarding'),
                  child: const Text(
                    'New rider? Register here',
                    style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
