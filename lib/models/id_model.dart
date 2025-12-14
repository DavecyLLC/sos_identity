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
      type: json['type'] as String? ?? '',
      number: json['number'] as String? ?? '',
      country: json['country'] as String? ?? '',
      expiryDate: json['expiryDate'] as String? ?? '',
      frontImagePath: json['frontImagePath'] as String?,
      backImagePath: json['backImagePath'] as String?,
    );
  }
}
