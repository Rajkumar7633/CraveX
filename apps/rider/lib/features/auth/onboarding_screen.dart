import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class RiderOnboardingScreen extends ConsumerStatefulWidget {
  const RiderOnboardingScreen({super.key});

  @override
  ConsumerState<RiderOnboardingScreen> createState() => _RiderOnboardingScreenState();
}

class _RiderOnboardingScreenState extends ConsumerState<RiderOnboardingScreen> {
  int _step = 0;
  bool _isLoading = false;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  String? _vehicleType;
  
  final _steps = [
    'Personal Details',
    'Documents',
    'Vehicle Details',
    'Bank Details',
    'Verification',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Submit onboarding data to backend
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  void _nextStep() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    }
  }

  void _previousStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Rider Registration',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_step + 1) / _steps.length,
                  backgroundColor: const Color(0xFFE0E0E0),
                  color: AppTheme.primaryRed,
                  minHeight: 6,
                ),
                const SizedBox(height: 16),
                Row(
                  children: _steps.asMap().entries.map((e) {
                    final done = e.key <= _step;
                    return Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: done ? AppTheme.primaryRed : const Color(0xFFE0E0E0),
                            child: Text(
                              '${e.key + 1}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: done ? Colors.white : Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.value,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: done ? AppTheme.primaryRed : Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(child: _buildStepContent()),
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _previousStep,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: _isLoading 
                        ? 'Submitting...' 
                        : _step < _steps.length - 1 
                            ? 'Next' 
                            : 'Submit for Review',
                    onPressed: _isLoading 
                        ? null 
                        : _step < _steps.length - 1 
                            ? _nextStep 
                            : _submitOnboarding,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildPersonalDetails();
      case 1:
        return _buildDocuments();
      case 2:
        return _buildVehicleDetails();
      case 3:
        return _buildBankDetails();
      case 4:
        return _buildVerification();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPersonalDetails() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Personal Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
          ),
          const SizedBox(height: 8),
          Text('Tell us about yourself', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 24),
          AppTextField(
            controller: _nameController,
            hintText: 'Full Name',
            prefixIcon: Icons.person_rounded,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _phoneController,
            hintText: 'Phone Number',
            prefixIcon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDocuments() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Documents',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
        ),
        const SizedBox(height: 8),
        Text('Upload required documents', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 24),
        _uploadTile('Driving License', Icons.badge_rounded),
        const SizedBox(height: 12),
        _uploadTile('Vehicle RC', Icons.directions_car_rounded),
        const SizedBox(height: 12),
        _uploadTile('Aadhaar Card', Icons.credit_card_rounded),
        const SizedBox(height: 12),
        _uploadTile('PAN Card', Icons.description_rounded),
      ],
    );
  }

  Widget _buildVehicleDetails() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Vehicle Details',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
        ),
        const SizedBox(height: 8),
        Text('Your delivery vehicle', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _vehicleType,
            decoration: InputDecoration(
              labelText: 'Vehicle Type',
              prefixIcon: const Icon(Icons.motorcycle_rounded),
              border: InputBorder.none,
            ),
            items: ['Bike', 'Scooter', 'Bicycle', 'On Foot'].map((v) {
              return DropdownMenuItem(value: v, child: Text(v));
            }).toList(),
            onChanged: (v) => setState(() => _vehicleType = v),
          ),
        ),
        const SizedBox(height: 24),
        _uploadTile('Vehicle Photo', Icons.camera_alt_rounded),
      ],
    );
  }

  Widget _buildBankDetails() {
    return Form(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Bank Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
          ),
          const SizedBox(height: 8),
          Text('For earnings payout', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 24),
          AppTextField(
            controller: _accountNumberController,
            hintText: 'Account Number',
            prefixIcon: Icons.account_balance_wallet_rounded,
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _ifscController,
            hintText: 'IFSC Code',
            prefixIcon: Icons.qr_code_rounded,
            textCapitalization: TextCapitalization.characters,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildVerification() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Verification',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
        ),
        const SizedBox(height: 8),
        Text('Background verification in progress', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 60, color: AppTheme.primaryRed),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verification in Progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1C)),
              ),
              const SizedBox(height: 8),
              Text(
                'Usually takes 24-48 hours',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF2ECC71)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We will notify you once your verification is complete',
                        style: TextStyle(fontSize: 13, color: Color(0xFF1C1C1C)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _uploadTile(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryRed),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.upload_rounded, size: 18),
          label: const Text('Upload'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFEEEF),
            foregroundColor: AppTheme.primaryRed,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
