class UserProfile {
  final String fullName;
  final String phoneNumber; // ✅ NEW (user-entered)
  final String bloodType;
  final String medicalNotes;

  const UserProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.bloodType,
    required this.medicalNotes,
  });

  static const empty = UserProfile(
    fullName: '',
    phoneNumber: '',
    bloodType: '',
    medicalNotes: '',
  );

  UserProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? bloodType,
    String? medicalNotes,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bloodType: bloodType ?? this.bloodType,
      medicalNotes: medicalNotes ?? this.medicalNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'bloodType': bloodType,
        'medicalNotes': medicalNotes,
      };

  static UserProfile fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: (json['fullName'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      bloodType: (json['bloodType'] ?? '').toString(),
      medicalNotes: (json['medicalNotes'] ?? '').toString(),
    );
  }
}
