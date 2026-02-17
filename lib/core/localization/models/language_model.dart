import 'package:hive/hive.dart';

part 'language_model.g.dart';

/// Language Model for Hive Persistence
@HiveType(typeId: 5)
class LanguageModel extends HiveObject {
  @HiveField(0)
  late String languageCode; // 'en', 'ru', 'uz'

  @HiveField(1)
  late String languageName; // 'English', 'Русский', 'O'zbekcha'

  @HiveField(2)
  late DateTime updatedAt;

  LanguageModel({
    required this.languageCode,
    required this.languageName,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  @override
  String toString() {
    return 'LanguageModel(code: $languageCode, name: $languageName)';
  }
}
