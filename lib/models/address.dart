class Address {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String parish;
  final String? postalCode;
  final String country;
  final bool isDefault;
  final String? label; // e.g., "Home", "Work"

  Address({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.parish,
    this.postalCode,
    this.country = 'Jamaica',
    this.isDefault = false,
    this.label,
  });

  String get formattedAddress {
    final parts = <String>[
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2!,
      city,
      parish,
      if (postalCode != null && postalCode!.isNotEmpty) postalCode!,
      country,
    ];
    return parts.join(', ');
  }

  String get shortAddress => '$addressLine1, $city, $parish';

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['address_line_1'] ?? '',
      addressLine2: json['address_line_2'],
      city: json['city'] ?? '',
      parish: json['parish'] ?? '',
      postalCode: json['postal_code'],
      country: json['country'] ?? 'Jamaica',
      isDefault: json['is_default'] ?? false,
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'parish': parish,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
      'label': label,
    };
  }

  Address copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? parish,
    String? postalCode,
    String? country,
    bool? isDefault,
    String? label,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      parish: parish ?? this.parish,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      label: label ?? this.label,
    );
  }
}

// Jamaica Parishes for dropdown
class JamaicaParishes {
  static const List<String> parishes = [
    'Kingston',
    'St. Andrew',
    'St. Thomas',
    'Portland',
    'St. Mary',
    'St. Ann',
    'Trelawny',
    'St. James',
    'Hanover',
    'Westmoreland',
    'St. Elizabeth',
    'Manchester',
    'Clarendon',
    'St. Catherine',
  ];
}
