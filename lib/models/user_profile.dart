class UserProfile {
  final String id;
  final String name;
  final String location;
  final String primaryCrop;

  // Predefined locations list (Maharashtra Districts)
  static const List<String> locations = [
    'पुणे, महाराष्ट्र',
    'नाशिक, महाराष्ट्र',
    'नागपूर, महाराष्ट्र',
    'कोल्हापूर, महाराष्ट्र',
    'सातारा, महाराष्ट्र',
    'सांगली, महाराष्ट्र',
    'जळगाव, महाराष्ट्र',
    'अमरावती, महाराष्ट्र',
    'लातूर, महाराष्ट्र',
    'सोलापूर, महाराष्ट्र',
  ];

  // Predefined major crops
  static const List<String> crops = [
    'भात (तांदूळ)',
    'गहू',
    'कापूस',
    'सोयाबीन',
    'ऊस',
    'ज्वारी',
    'बाजरी',
    'हरभरा',
    'तूर',
    'मका',
  ];

  UserProfile({
    required this.id,
    required this.name,
    required this.location,
    required this.primaryCrop,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'primary_crop': primaryCrop,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map, String id) {
    return UserProfile(
      id: id,
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      primaryCrop: map['primary_crop'] as String? ?? '',
    );
  }

  static bool isValidProfile(String? name, String? location, String? crop) {
    if (name == null || name.trim().isEmpty) return false;
    if (location == null || !locations.contains(location)) return false;
    if (crop == null || !crops.contains(crop)) return false;
    return true;
  }
}
