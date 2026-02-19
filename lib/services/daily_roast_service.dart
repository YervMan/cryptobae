import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class DailyRoastService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchTodayRoasts() async {
    final locale = PlatformDispatcher.instance.locale;
    final lang = locale.languageCode;

    final today = DateTime.now().toUtc().toIso8601String().split('T')[0];

    final doc = await _firestore.collection('daily_roasts').doc(today).get();

    if (!doc.exists) {
      throw Exception("No daily roast available");
    }

    final data = doc.data();

    if (data == null || !data.containsKey("languages")) {
      throw Exception("Invalid roast format");
    }

    final languages = data["languages"] as Map<String, dynamic>;

    // Try device language
    if (languages.containsKey(lang)) {
      return List<Map<String, dynamic>>.from(languages[lang]["coins"]);
    }

    // Fallback to English
    if (languages.containsKey("en")) {
      return List<Map<String, dynamic>>.from(languages["en"]["coins"]);
    }

    throw Exception("No supported language found");
  }
}
