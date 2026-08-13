import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  final String id;
  final String publishDate; // Format: YYYY-MM-DD
  final String category;
  final String hook;
  final String idea;
  final String whyItMatters;
  final String everydayExample;
  final String reflectionPrompt;
  final List<String> exploreMore;
  final int readTimeMinutes;

  Lesson({
    required this.id,
    required this.publishDate,
    required this.category,
    required this.hook,
    required this.idea,
    required this.whyItMatters,
    required this.everydayExample,
    required this.reflectionPrompt,
    this.exploreMore = const [],
    this.readTimeMinutes = 3,
  });

  DateTime get publishDateTime => DateTime.parse(publishDate);

  factory Lesson.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Lesson(
      id: docId ?? json['id'] ?? '',
      publishDate: json['publishDate'] ?? '',
      category: json['category'] ?? 'General',
      hook: json['hook'] ?? '',
      idea: json['idea'] ?? '',
      whyItMatters: json['whyItMatters'] ?? '',
      everydayExample: json['everydayExample'] ?? '',
      reflectionPrompt: json['reflectionPrompt'] ?? '',
      exploreMore: List<String>.from(json['exploreMore'] ?? []),
      readTimeMinutes: json['readTimeMinutes'] ?? 3,
    );
  }

  factory Lesson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Lesson.fromJson(data, docId: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'publishDate': publishDate,
      'category': category,
      'hook': hook,
      'idea': idea,
      'whyItMatters': whyItMatters,
      'everydayExample': everydayExample,
      'reflectionPrompt': reflectionPrompt,
      'exploreMore': exploreMore,
      'readTimeMinutes': readTimeMinutes,
    };
  }
}
