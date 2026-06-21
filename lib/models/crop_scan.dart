class CropScanModel {
  final String timestamp;
  final String cropType;
  final String diseaseName;
  final String symptoms;
  final String remedy;
  final String recipe;
  final String? localImagePath;

  CropScanModel({
    required this.timestamp,
    required this.cropType,
    required this.diseaseName,
    required this.symptoms,
    required this.remedy,
    required this.recipe,
    this.localImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'crop_type': cropType,
      'disease_name': diseaseName,
      'symptoms': symptoms,
      'remedy': remedy,
      'recipe': recipe,
      if (localImagePath != null) 'local_image_path': localImagePath,
    };
  }

  factory CropScanModel.fromMap(Map<dynamic, dynamic> map, String timestamp) {
    return CropScanModel(
      timestamp: timestamp,
      cropType: map['crop_type'] as String? ?? 'अज्ञात पीक',
      diseaseName: map['disease_name'] as String? ?? 'अज्ञात रोग',
      symptoms: map['symptoms'] as String? ?? '',
      remedy: map['remedy'] as String? ?? '',
      recipe: map['recipe'] as String? ?? '',
      localImagePath: map['local_image_path'] as String?,
    );
  }
}
