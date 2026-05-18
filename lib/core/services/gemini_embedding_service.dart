import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/secrets.dart';

class GeminiEmbeddingService {
  static String get _apiKey => Secrets.geminiApiKey;
  static const String _embedBase =
      'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent';

  Future<List<double>> getEmbedding(String text) async {
    final body = jsonEncode({
      'model': 'models/text-embedding-004',
      'content': {
        'parts': [
          {'text': text},
        ],
      },
    });

    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is missing. Add it to your .env file.');
    }

    final response = await http.post(
      Uri.parse('$_embedBase?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Embedding API error ${response.statusCode}');
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final values =
        (map['embedding'] as Map<String, dynamic>)['values'] as List<dynamic>;
    return values.map((e) => (e as num).toDouble()).toList();
  }

  Future<List<double>> getCachedEmbedding(String cacheKey, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = 'embed_$cacheKey';
    final cached = prefs.getString(storageKey);
    if (cached != null) {
      final list = jsonDecode(cached) as List<dynamic>;
      return list.map((e) => (e as num).toDouble()).toList();
    }
    final embedding = await getEmbedding(text);
    await prefs.setString(storageKey, jsonEncode(embedding));
    return embedding;
  }
}
