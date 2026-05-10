import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/cv_model.dart'; // FIXED: was '../data/models/cv_model.dart'

class AiService {
  // Replace with your actual Gemini API key
  // Get it from: https://aistudio.google.com/app/apikey
  static const String _apiKey = 'AIzaSyBYfVm5yXmz_x2vU6WZCFZR-H30_9lKxr4';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Parses a CV text using Gemini and returns a structured [CvModel].
  Future<CvModel> parseCv({
    required String cvText,
    required String uid,
    required String fileUrl,
    required String fileName,
  }) async {
    final prompt = _buildPrompt(cvText);

    final response = await http.post(
      Uri.parse('$_baseUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final rawText =
        data['candidates'][0]['content']['parts'][0]['text'] as String;

    return _parseGeminiResponse(
      rawText: rawText,
      uid: uid,
      fileUrl: fileUrl,
      fileName: fileName,
    );
  }

  String _buildPrompt(String cvText) {
    return '''
You are an expert CV/resume parser. Analyze the following CV text and extract structured information.

Return ONLY a valid JSON object with this exact structure — no markdown, no explanation, just JSON:

{
  "skills": ["skill1", "skill2", ...],
  "workExperience": [
    {
      "company": "Company Name",
      "title": "Job Title",
      "duration": "Jan 2020 - Dec 2022",
      "description": "Brief description of role and achievements"
    }
  ],
  "education": [
    {
      "institution": "University Name",
      "degree": "Bachelor / Master / PhD / Diploma",
      "field": "Field of Study",
      "year": "2018 - 2022"
    }
  ]
}

Rules:
- skills: extract ALL technical and soft skills (programming languages, frameworks, tools, methodologies, etc.)
- workExperience: list all jobs, most recent first
- education: list all degrees/certificates, most recent first
- If a field is not found in the CV, use an empty array []
- Keep descriptions concise (max 100 chars)

CV TEXT:
---
$cvText
---
''';
  }

  CvModel _parseGeminiResponse({
    required String rawText,
    required String uid,
    required String fileUrl,
    required String fileName,
  }) {
    String cleaned = rawText.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```[a-z]*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '')
          .trim();
    }

    final Map<String, dynamic> parsed = jsonDecode(cleaned);

    final skills = List<String>.from(parsed['skills'] ?? []);
    final workExperience = (parsed['workExperience'] as List<dynamic>? ?? [])
        .map((e) => WorkExperience.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final education = (parsed['education'] as List<dynamic>? ?? [])
        .map((e) => Education.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final strength = _calculateStrength(skills, workExperience, education);

    return CvModel(
      uid: uid,
      fileUrl: fileUrl,
      fileName: fileName,
      uploadedAt: DateTime.now(),
      skills: skills,
      workExperience: workExperience,
      education: education,
      profileStrength: strength,
    );
  }

  int _calculateStrength(
    List<String> skills,
    List<WorkExperience> experience,
    List<Education> education,
  ) {
    int score = 0;
    if (skills.isNotEmpty) score += 10;
    if (skills.length >= 5) score += 10;
    if (skills.length >= 10) score += 10;
    if (skills.length >= 15) score += 10;
    if (experience.isNotEmpty) score += 15;
    if (experience.length >= 2) score += 10;
    if (experience.length >= 3) score += 10;
    if (education.isNotEmpty) score += 15;
    if (education.length >= 2) score += 10;
    return score.clamp(0, 100);
  }
}
