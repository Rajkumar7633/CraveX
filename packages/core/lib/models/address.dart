import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final String? landmark;

  const Address({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.landmark,
  });

  String get fullAddress =>
      '$addressLine1${addressLine2 != null ? ', $addressLine2' : ''}, $city, $state - $pincode';

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as String,
        label: json['label'] as String,
        addressLine1: json['addressLine1'] as String,
        addressLine2: json['addressLine2'] as String?,
        city: json['city'] as String,
        state: json['state'] as String,
        pincode: json['pincode'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        landmark: json['landmark'] as String?,
      );

  @override
  List<Object?> get props => [id, label, addressLine1, city];
}
