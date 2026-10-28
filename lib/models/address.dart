

class Address {
  final String? id;
  final String label;
  final String house;
  final String street;
  final String landmark;
  final String pincode;
  final bool isDefault;

  const Address({
    this.id,
    required this.label,
    required this.house,
    required this.street,
    this.landmark = '',
    required this.pincode,
    this.isDefault = false,
  });

  String get line =>
      [
        house,
        street,
        if (landmark.isNotEmpty) landmark,
      ].join(', ') +
      ' - $pincode';

  // Request body for POST and PUT
  Map<String, dynamic> toJson() {
    return {
      'label': _backendLabel(label),
      'house_flat_no': house,
      'street_area': street,
      'landmark': landmark,
      'pincode': pincode,
    };
  }

  // Convert backend response into a Flutter Address
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id']?.toString(),
      label: (json['label'] ?? 'Home').toString().toLowerCase(),
      house: (json['house_flat_no'] ?? '').toString(),
      street: (json['street_area'] ?? '').toString(),
      landmark: (json['landmark'] ?? '').toString(),
      pincode: (json['pincode'] ?? '').toString(),
      isDefault: json['is_default'] == true,
    );
  }

  static String _backendLabel(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return 'Home';
      case 'work':
        return 'Work';
      default:
        return 'Other';
    }
  }
}