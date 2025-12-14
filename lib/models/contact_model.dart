class ContactModel {
  final String name;
  final String phone;
  final bool isPrimary;

  const ContactModel({
    required this.name,
    required this.phone,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'isPrimary': isPrimary,
    };
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}
