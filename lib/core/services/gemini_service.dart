import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final GenerativeModel _model;
  static const String _summaryPrompt = '''
    Summarize the following note content in a concise way. 
    Keep the most important points and key information.
    Make the summary shorter than the original text.
    Use bullet points if the content has multiple distinct points.
    Keep the tone and style similar to the original text.
    
    Note content:
    ''';

  static const String _emotionPrompt = '''
    Aşağıdaki metnin duygusal tonunu analiz et ve TAM OLARAK şu JSON formatında yanıt ver:
    {
      "emotion": "duygu_adı",
      "intensity": 1-5 arası sayı,
      "keywords": ["anahtar", "kelimeler"],
      "suggestion": "öneri"
    }
    
    Duygu adı şunlardan biri olmalı: "mutlu", "üzgün", "kızgın", "endişeli", "sakin", "enerjik", "yorgun", "motivasyonlu", "stresli", "minnettar"
    
    Önemli: Sadece JSON formatında yanıt ver, başka hiçbir metin ekleme. Markdown formatı kullanma.
    
    Metin:
    ''';

  GeminiService({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
        );

  Future<String> summarizeContent(String content) async {
    try {
      final prompt = '$_summaryPrompt$content';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Could not generate summary';
    } catch (e) {
      return 'Error generating summary: ${e.toString()}';
    }
  }

  Future<Map<String, dynamic>> analyzeEmotion(String content) async {
    try {
      final prompt = '$_emotionPrompt$content';
      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        throw Exception('Empty response from Gemini API');
      }

      // JSON string'i temizle ve parse et
      String jsonStr = response.text!.trim();
      print('Raw response: $jsonStr'); // Debug için

      // Markdown formatını temizle
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      // Eğer yanıt JSON formatında değilse, varsayılan bir yanıt döndür
      if (!jsonStr.startsWith('{') || !jsonStr.endsWith('}')) {
        print('Invalid JSON format');
        return _getDefaultEmotionResponse();
      }

      try {
        final Map<String, dynamic> result = json.decode(jsonStr);

        // Gerekli alanların varlığını kontrol et
        if (!result.containsKey('emotion') ||
            !result.containsKey('intensity') ||
            !result.containsKey('keywords') ||
            !result.containsKey('suggestion')) {
          print('Missing required fields');
          return _getDefaultEmotionResponse();
        }

        return result;
      } catch (e) {
        print('JSON parse error: $e');
        return _getDefaultEmotionResponse();
      }
    } catch (e) {
      print('Error analyzing emotion: $e');
      return _getDefaultEmotionResponse();
    }
  }

  Map<String, dynamic> _getDefaultEmotionResponse() {
    return {
      'emotion': 'nötr',
      'intensity': 3,
      'keywords': [],
      'suggestion': 'Duygu analizi yapılamadı'
    };
  }
}
