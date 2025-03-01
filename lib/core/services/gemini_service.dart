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

  static const String _transcribePrompt = '''
    Sana şimdi bir mp3 dosyasının base64 e çevirilmiş halini veriyorum.
    Bu base64 kodunu önce mp3 dosyasına çevir.
    Sonrasında bu mp3 dosyasının içeriğini metin olarak dönüştür.
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

  Future<String> transcribeAudio(File audioFile) async {
    try {
      // Dosya boyutunu kontrol et
      final fileSize = await audioFile.length();
      print('Audio file size: ${fileSize / 1024 / 1024} MB');

      if (fileSize > 4 * 1024 * 1024) {
        // 4MB limit örneği
        return 'Error: File size exceeds limit. Maximum allowed size is 4MB';
      }

      // Dosyayı base64'e çevir
      final bytes = await audioFile.readAsBytes();
      final base64Audio = base64Encode(bytes);

      print('Converting audio to base64: ${base64Audio.length} characters');

      // Gemini'ye gönder
      final prompt = '$_transcribePrompt$base64Audio';

      try {
        final response = await _model.generateContent([Content.text(prompt)]);

        if (response.text == null || response.text!.isEmpty) {
          return 'Error: Empty response from Gemini API';
        }

        return response.text!;
      } catch (apiError) {
        print('Gemini API Error: $apiError');
        if (apiError.toString().contains('Resource has been exhausted')) {
          return 'Error: API quota exceeded. Please try again later or check your API limits.';
        }
        return 'Error transcribing audio: $apiError';
      }
    } catch (e) {
      print('General Error: $e');
      return 'Error transcribing audio: $e';
    }
  }
}
