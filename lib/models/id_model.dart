class IdModel {
  final String type;
  final String number;
  final String country;
  final String expiryDate;
  final String? frontImagePath;
  final String? backImagePath;

  const IdModel({
    required this.type,
    required this.number,
    required this.country,
    required this.expiryDate,
    this.frontImagePath,
    this.backImagePath,
  });

  /// Useful stable identifier for lists, keys, comparisons, etc.
  /// (Type + Number is usually unique enough for your app.)
  String get key => '${type.trim()}::${number.trim()}';

  IdModel copyWith({
    String? type,
    String? number,
    String? country,
    String? expiryDate,
    String? frontImagePath,
    String? backImagePath,
  }) {
    return IdModel(
      type: type ?? this.type,
      number: number ?? this.number,
      country: country ?? this.country,
      expiryDate: expiryDate ?? this.expiryDate,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'number': number,
      'country': country,
      'expiryDate': expiryDate,
      'frontImagePath': frontImagePath,
      'backImagePath': backImagePath,
    };
  }

  factory IdModel.fromJson(Map<String, dynamic> json) {
    return IdModel(
      type: (json['type'] as String? ?? '').trim(),
      number: (json['number'] as String? ?? '').trim(),
      country: (json['country'] as String? ?? '').trim(),
      expiryDate: (json['expiryDate'] as String? ?? '').trim(),
      frontImagePath: (json['frontImagePath'] as String?)?.trim(),
      backImagePath: (json['backImagePath'] as String?)?.trim(),
    );
  }
}
