import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiEmbeddingService {
  static const String _apiKey = 'AIzaSyBYfVm5yXmz_x2vU6WZCFZR-H30_9lKxr4';
  static const String _embedUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=$_apiKey';

  Future<List<double>> getEmbedding(String text) async {
    final body = jsonEncode({
      'model': 'models/text-embedding-004',
      'content': {
        'parts': [
          {'text': text},
        ],
      },
    });

    final response = await http.post(
      Uri.parse(_embedUrl),
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
