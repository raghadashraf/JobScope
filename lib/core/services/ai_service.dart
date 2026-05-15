import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/cv_model.dart';

// ─── AI feature models ────────────────────────────────────────────────────────

class InterviewQuestion {
  final String question;
  final String scenario;
  final String sampleAnswer;
  const InterviewQuestion({
    required this.question,
    required this.scenario,
    required this.sampleAnswer,
  });

  factory InterviewQuestion.fromMap(Map<String, dynamic> m) =>
      InterviewQuestion(
        question: m['question'] as String? ?? '',
        scenario: m['scenario'] as String? ?? '',
        sampleAnswer: m['sampleAnswer'] as String? ?? '',
      );
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> m) => QuizQuestion(
        question: m['question'] as String? ?? '',
        options: List<String>.from(m['options'] ?? []),
        correctIndex: (m['correctIndex'] as num?)?.toInt() ?? 0,
        explanation: m['explanation'] as String? ?? '',
      );
}

class MatchReason {
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final String summary;
  const MatchReason({
    required this.matchedSkills,
    required this.missingSkills,
    required this.summary,
  });
  factory MatchReason.fromMap(Map<String, dynamic> m) => MatchReason(
        matchedSkills: List<String>.from(m['matchedSkills'] ?? []),
        missingSkills: List<String>.from(m['missingSkills'] ?? []),
        summary: m['summary'] as String? ?? '',
      );
}

// ─── Service ──────────────────────────────────────────────────────────────────

class AiService {
  static const String _apiKey = 'AIzaSyBYfVm5yXmz_x2vU6WZCFZR-H30_9lKxr4';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // ─── CV Parsing ───────────────────────────────────────────────────────────
  Future<CvModel> parseCv({
    required String cvText,
    required String uid,
    required String fileUrl,
    required String fileName,
  }) async {
    final rawText = await _callGemini(_buildPrompt(cvText), temperature: 0.1);
    return _parseGeminiResponse(
        rawText: rawText, uid: uid, fileUrl: fileUrl, fileName: fileName);
  }

  // ─── Interview Questions ──────────────────────────────────────────────────
  Future<List<InterviewQuestion>> generateInterviewQuestions({
    required String jobTitle,
    String? jobDescription,
    List<String> skills = const [],
  }) async {
    final prompt = '''
You are an expert technical interviewer. Generate 5 scenario-based interview questions for a $jobTitle position.
${skills.isNotEmpty ? 'Key skills required: ${skills.join(', ')}.' : ''}
${jobDescription != null && jobDescription.isNotEmpty ? 'Job context: $jobDescription' : ''}

Return ONLY a valid JSON array — no markdown, no explanation:
[
  {
    "question": "Technical or behavioral question",
    "scenario": "Brief scenario context (1-2 sentences)",
    "sampleAnswer": "A strong sample answer (3-5 sentences)"
  }
]
''';

    final rawText = await _callGemini(prompt);
    final cleaned = _stripMarkdown(rawText);
    final List<dynamic> parsed = jsonDecode(cleaned);
    return parsed
        .map((e) => InterviewQuestion.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ─── Skill Quiz ───────────────────────────────────────────────────────────
  Future<List<QuizQuestion>> generateSkillQuiz(List<String> skills) async {
    final topSkills = skills.take(5).join(', ');
    final prompt = '''
You are a technical quiz generator. Create a 5-question multiple-choice quiz to assess proficiency in: $topSkills.

Return ONLY a valid JSON array — no markdown, no explanation:
[
  {
    "question": "Technical question",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctIndex": 0,
    "explanation": "Why this answer is correct (1-2 sentences)"
  }
]
''';

    final rawText = await _callGemini(prompt);
    final cleaned = _stripMarkdown(rawText);
    final List<dynamic> parsed = jsonDecode(cleaned);
    return parsed
        .map((e) => QuizQuestion.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ─── Job Match Score ──────────────────────────────────────────────────────
  Future<int> matchJob({
    required List<String> jobSkills,
    required List<String> cvSkills,
    required String jobDescription,
  }) async {
    if (cvSkills.isEmpty || jobSkills.isEmpty) return 0;

    final prompt = '''
You are a job matching expert. Rate how well a candidate matches a job.

Job requirements:
- Required skills: ${jobSkills.join(', ')}
- Description: $jobDescription

Candidate skills: ${cvSkills.join(', ')}

Return ONLY a JSON object: {"matchScore": 75}
Where matchScore is 0-100 based on skill overlap and relevance.
''';

    final rawText = await _callGemini(prompt, temperature: 0.1);
    final cleaned = _stripMarkdown(rawText);
    final Map<String, dynamic> parsed = jsonDecode(cleaned);
    return ((parsed['matchScore'] as num?)?.toInt() ?? 0).clamp(0, 100);
  }

  Future<MatchReason> getMatchReasons({
    required List<String> cvSkills,
    required List<String> jobSkills,
    required List<String> jobRequirements,
    required String jobTitle,
  }) async {
    final prompt = '''
You are a job matching expert. Analyse how well a candidate fits a role.

Job title: $jobTitle
Job requires skills: ${jobSkills.join(', ')}
Job requirements: ${jobRequirements.join(', ')}
Candidate skills: ${cvSkills.join(', ')}

Return ONLY a valid JSON object — no markdown, no explanation:
{
  "matchedSkills": ["skill1", "skill2"],
  "missingSkills": ["skill3"],
  "summary": "One sentence explaining the overall fit."
}
''';
    final raw = await _callGemini(prompt, temperature: 0.1);
    final cleaned = _stripMarkdown(raw);
    return MatchReason.fromMap(jsonDecode(cleaned) as Map<String, dynamic>);
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
    final Map<String, dynamic> parsed = jsonDecode(_stripMarkdown(rawText));

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

  // ─── Shared HTTP helper ───────────────────────────────────────────────────
  Future<String> _callGemini(String prompt, {double temperature = 0.7}) async {
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
          'temperature': temperature,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Gemini API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  String _stripMarkdown(String raw) {
    String s = raw.trim();
    if (s.startsWith('```')) {
      s = s
          .replaceFirst(RegExp(r'^```[a-z]*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '')
          .trim();
    }
    return s;
  }
}
