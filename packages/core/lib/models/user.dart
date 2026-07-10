import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? profilePhoto;
  final String userType;
  final String? referralCode;
  final DateTime? dateOfBirth;
  final String? gender;
  final double walletBalance;
  final bool isGoldMember;

  const User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.profilePhoto,
    required this.userType,
    this.referralCode,
    this.dateOfBirth,
    this.gender,
    this.walletBalance = 0,
    this.isGoldMember = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        profilePhoto: json['profilePhoto'] as String?,
        userType: json['userType'] as String? ?? 'customer',
        referralCode: json['referralCode'] as String?,
        walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0,
        isGoldMember: json['isGoldMember'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'profilePhoto': profilePhoto,
        'userType': userType,
        'referralCode': referralCode,
        'walletBalance': walletBalance,
        'isGoldMember': isGoldMember,
      };

  @override
  List<Object?> get props => [id, name, email, phone, userType];
}
