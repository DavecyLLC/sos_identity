class UserProfile {
  final String fullName;
  final String dateOfBirth; // keep as string for now (e.g. 1990-05-21)
  final String bloodType;   // e.g. O+, A-, etc.
  final String medicalNotes; // allergies, conditions, meds

  const UserProfile({
    required this.fullName,
    required this.dateOfBirth,
    required this.bloodType,
    required this.medicalNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'bloodType': bloodType,
      'medicalNotes': medicalNotes,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['fullName'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      bloodType: json['bloodType'] as String? ?? '',
      medicalNotes: json['medicalNotes'] as String? ?? '',
    );
  }

  static const empty = UserProfile(
    fullName: '',
    dateOfBirth: '',
    bloodType: '',
    medicalNotes: '',
  );
}
