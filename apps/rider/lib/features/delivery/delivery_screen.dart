import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:theme/app_theme.dart';
import 'package:widgets/widgets.dart';

class DeliveryScreen extends ConsumerStatefulWidget {
  final String orderId;
  const DeliveryScreen({super.key, required this.orderId});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  int _step = 0;
  final _pickupOtpController = TextEditingController();
  final _deliveryOtpController = TextEditingController();
  
  final _steps = [
    'Navigate to Restaurant',
    'Arrived at Restaurant',
    'Pickup OTP Verification',
    'Navigate to Customer',
    'Arrived at Customer',
    'Delivery Complete',
  ];

  @override
  void dispose() {
    _pickupOtpController.dispose();
    _deliveryOtpController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = MockData.restaurantOrders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => MockData.restaurantOrders.first,
    );
    final restaurant = MockData.restaurants.firstWhere(
      (r) => r.id == order.restaurantId,
      orElse: () => MockData.restaurants.first,
    );
    final restLatLng = LatLng(restaurant.latitude, restaurant.longitude);
    final custLatLng = LatLng(order.deliveryAddress.latitude, order.deliveryAddress.longitude);

    LatLng riderLatLng;
    if (_step == 0) {
      riderLatLng = LatLng(restLatLng.latitude - 0.003, restLatLng.longitude - 0.002);
    } else if (_step == 1 || _step == 2) {
      riderLatLng = restLatLng;
    } else if (_step == 3) {
      riderLatLng = LatLng((restLatLng.latitude + custLatLng.latitude) / 2, (restLatLng.longitude + custLatLng.longitude) / 2);
    } else {
      riderLatLng = custLatLng;
    }

    final markers = [
      Marker(
        point: restLatLng,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            border: Border.all(color: AppTheme.primaryRed, width: 2),
          ),
          child: const Icon(Icons.store_rounded, color: AppTheme.primaryRed, size: 20),
        ),
      ),
      Marker(
        point: custLatLng,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            border: Border.all(color: const Color(0xFF3498DB), width: 2),
          ),
          child: const Icon(Icons.home_rounded, color: Color(0xFF3498DB), size: 20),
        ),
      ),
      Marker(
        point: riderLatLng,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            border: Border.all(color: const Color(0xFF2ECC71), width: 2),
          ),
          child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF2ECC71), size: 20),
        ),
      ),
    ];

    final polylines = [
      Polyline(
        points: [restLatLng, custLatLng],
        color: AppTheme.primaryRed,
        strokeWidth: 4.0,
        borderStrokeWidth: 2.0,
        borderColor: Colors.white,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Delivery #${widget.orderId.substring(widget.orderId.length - 6).toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: AppTheme.primaryRed),
            onPressed: () {},
          ),
        ],
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
                    final done = e.key < _step;
                    final active = e.key == _step;
                    return Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: done ? const Color(0xFF2ECC71) : active ? AppTheme.primaryRed : const Color(0xFFE0E0E0),
                            child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : Text('${e.key + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : Colors.grey[600])),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.value,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: done ? const Color(0xFF2ECC71) : active ? AppTheme.primaryRed : Colors.grey[600]),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Map
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: OsmMapWidget(
                      markers: markers,
                      polylines: polylines,
                      zoom: 14.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Order details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.store_rounded, color: AppTheme.primaryRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                Text(restaurant.address, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.home_rounded, color: Color(0xFF3498DB)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Customer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                Text(order.deliveryAddress.fullAddress, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee_rounded, color: Color(0xFF2ECC71)),
                          const SizedBox(width: 8),
                          Text(
                            'Earnings: ₹45',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const Spacer(),
                          Text(
                            '3.2 km',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // OTP verification
                if (_step == 2) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pickup OTP',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter the 4-digit OTP provided by the restaurant',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _pickupOtpController,
                          hintText: 'Enter OTP',
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (_step == 5) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4E8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery OTP',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter the OTP provided by the customer',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _deliveryOtpController,
                          hintText: 'Enter OTP',
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryRed),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Photo proof of delivery',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.primaryRed),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Capture', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          // Bottom action button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                if (_step < _steps.length - 1)
                  PrimaryButton(
                    text: _stepButtonLabel(),
                    onPressed: _nextStep,
                  )
                else
                  PrimaryButton(
                    text: 'Complete Delivery',
                    onPressed: () => context.go('/dashboard'),
                  ),
                if (_step > 0 && _step < _steps.length - 1) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Report Issue', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stepButtonLabel() {
    switch (_step) {
      case 0: return 'Start Navigation to Restaurant';
      case 1: return 'Confirm Arrival at Restaurant';
      case 2: return 'Confirm Pickup';
      case 3: return 'Start Navigation to Customer';
      case 4: return 'Confirm Arrival at Customer';
      default: return 'Next';
    }
  }
}
