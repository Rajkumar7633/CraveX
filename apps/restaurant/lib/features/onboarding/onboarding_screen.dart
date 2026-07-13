import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class RestaurantOnboardingScreen extends ConsumerStatefulWidget {
  const RestaurantOnboardingScreen({super.key});

  @override
  ConsumerState<RestaurantOnboardingScreen> createState() => _RestaurantOnboardingScreenState();
}

class _RestaurantOnboardingScreenState extends ConsumerState<RestaurantOnboardingScreen> {
  int _step = 0;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  
  final _formKey = GlobalKey<FormState>();
  final _restaurantNameController = TextEditingController();
  final _cuisineController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  
  final _steps = [
    'Business Details',
    'Documents',
    'Bank Details',
    'Restaurant Photos',
    'Menu Setup',
    'Operating Hours',
    'Agreement',
  ];

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _cuisineController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _accountHolderController.dispose();
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
          'Restaurant Onboarding',
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
        return _buildBusinessDetails();
      case 1:
        return _buildDocuments();
      case 2:
        return _buildBankDetails();
      case 3:
        return _buildPhotos();
      case 4:
        return _buildMenuSetup();
      case 5:
        return _buildOperatingHours();
      case 6:
        return _buildAgreement();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBusinessDetails() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Business Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
          ),
          const SizedBox(height: 8),
          Text('Tell us about your restaurant', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 24),
          AppTextField(
            controller: _restaurantNameController,
            hintText: 'Restaurant Name',
            prefixIcon: Icons.store_rounded,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _cuisineController,
            hintText: 'Cuisine Type (e.g., North Indian, Chinese)',
            prefixIcon: Icons.restaurant_menu_rounded,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _addressController,
            hintText: 'Full Address',
            prefixIcon: Icons.location_on_rounded,
            maxLines: 3,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _gstController,
            hintText: 'GST Number',
            prefixIcon: Icons.receipt_long_rounded,
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
        _uploadTile('FSSAI License', Icons.food_bank_rounded),
        const SizedBox(height: 12),
        _uploadTile('PAN Card', Icons.badge_rounded),
        const SizedBox(height: 12),
        _uploadTile('Cancelled Cheque', Icons.account_balance_rounded),
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
          Text('For payments and settlements', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 24),
          AppTextField(
            controller: _accountHolderController,
            hintText: 'Account Holder Name',
            prefixIcon: Icons.person_rounded,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
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

  Widget _buildPhotos() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Restaurant Photos',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
        ),
        const SizedBox(height: 8),
        Text('Showcase your restaurant', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 24),
        _uploadTile('Exterior Photo', Icons.storefront_rounded),
        const SizedBox(height: 12),
        _uploadTile('Interior Photo', Icons.table_restaurant_rounded),
        const SizedBox(height: 12),
        _uploadTile('Kitchen Photo', Icons.kitchen_rounded),
      ],
    );
  }

  Widget _buildMenuSetup() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Menu Setup',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
        ),
        const SizedBox(height: 8),
        Text('Add your menu items', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEEF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.primaryRed),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Menu categories and items can be added after approval',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1C1C1C)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'Upload Menu CSV',
          onPressed: () {},
          icon: Icons.upload_file_rounded,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryRed),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Add Items Manually', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildOperatingHours() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Operating Hours',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
        ),
        const SizedBox(height: 8),
        Text('Set your restaurant hours', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 24),
        _dayTile('Monday', true, '11 AM - 11 PM'),
        _dayTile('Tuesday', true, '11 AM - 11 PM'),
        _dayTile('Wednesday', true, '11 AM - 11 PM'),
        _dayTile('Thursday', true, '11 AM - 11 PM'),
        _dayTile('Friday', true, '11 AM - 11 PM'),
        _dayTile('Saturday', true, '11 AM - 11 PM'),
        _dayTile('Sunday', false, 'Closed'),
      ],
    );
  }

  Widget _buildAgreement() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Terms & Conditions',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1C)),
        ),
        const SizedBox(height: 8),
        Text('Please review and accept', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
          ),
          height: 200,
          child: SingleChildScrollView(
            child: Text(
              'By signing up as a CraveX restaurant partner, you agree to the following terms:\n\n'
              '1. You will maintain food quality and hygiene standards as per FSSAI guidelines.\n'
              '2. You will honor all orders received through the platform.\n'
              '3. You will accept the commission structure as outlined in the partner agreement.\n'
              '4. You will provide accurate menu information and pricing.\n'
              '5. You will handle customer complaints professionally.\n'
              '6. CraveX reserves the right to suspend your account for policy violations.\n'
              '7. Payment settlements will be processed on a weekly basis.\n'
              '8. You agree to maintain accurate inventory and availability status.\n'
              '9. You will comply with all local laws and regulations.\n'
              '10. This agreement is governed by the laws of India.\n\n'
              'For full terms and conditions, please visit our partner portal.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
          title: const Text('I agree to the terms and conditions', style: TextStyle(fontWeight: FontWeight.w600)),
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.primaryRed,
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

  Widget _dayTile(String day, bool isOpen, String hours) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        value: isOpen,
        onChanged: (_) {},
        title: Text(day, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(hours, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        activeColor: AppTheme.primaryRed,
      ),
    );
  }
}
