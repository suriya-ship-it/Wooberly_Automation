class MobileLanguage {
  final String language;
  final String languageCode;
  final String languageJson;
  final String createdAt;
  final String updatedAt;

  MobileLanguage({
    required this.language,
    required this.languageCode,
    required this.languageJson,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MobileLanguage.fromJson(Map<String, dynamic> json) {
    return MobileLanguage(
      language: json['language'],
      languageCode: json['languageCode'],
      languageJson: json['languageJson'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

}