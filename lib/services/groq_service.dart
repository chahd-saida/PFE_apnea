import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class GroqService {
  static const String _apiKey =
      'gsk_your_groq_api_key_here'; // Replace with actual key
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 1024,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'Pas de réponse';
      } else {
        debugPrint('Groq Error: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur Groq: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('GroqService error: $e');
      rethrow;
    }
  }
}
