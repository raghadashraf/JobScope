import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/profile_levels.dart';
import '../../core/utils/cv_profile_strength.dart';
import '../../data/models/cv_model.dart';
import '../../data/models/training_session_model.dart';
import '../constants/secrets.dart';

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

class TrainAnswerEvaluation {
  final int score;
  final String feedback;
  const TrainAnswerEvaluation({required this.score, required this.feedback});

  factory TrainAnswerEvaluation.fromMap(Map<String, dynamic> m) =>
      TrainAnswerEvaluation(
        score: ((m['score'] as num?)?.toInt() ?? 0).clamp(0, 100),
        feedback: m['feedback'] as String? ?? '',
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
  static String get _apiKey => Secrets.geminiApiKey;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

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
You are an expert interview coach specializing in behavioral interviews.
Generate exactly 5 behavioral interview questions for a $jobTitle position.
At least 3 questions must use the STAR method (Situation, Task, Action, Result).
${skills.isNotEmpty ? 'Key skills to assess: ${skills.join(', ')}.' : ''}
${jobDescription != null && jobDescription.isNotEmpty ? 'Job context: $jobDescription' : ''}

Each question should feel realistic (team conflict, deadline pressure, leadership, failure recovery, prioritization).
In sampleAnswer, include a STAR-structured response AND one interview tip (e.g. body language, specificity, metrics).

Return ONLY a valid JSON array — no markdown, no explanation:
[
  {
    "question": "Behavioral question text",
    "scenario": "Brief workplace scenario (1-2 sentences)",
    "sampleAnswer": "STAR sample answer (3-5 sentences). Tip: one practical interview tip."
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

  // ─── Train Before Apply ───────────────────────────────────────────────────
  Future<List<TrainQuestion>> generateTrainBeforeApplyQuestions({
    required String jobTitle,
    required String company,
    required String jobDescription,
    List<String> skills = const [],
  }) async {
    final prompt = '''
You are an interview coach. Generate exactly 5 practice questions for a candidate applying to:
Role: $jobTitle at $company
${skills.isNotEmpty ? 'Required skills: ${skills.join(', ')}.' : ''}
Job context: $jobDescription

Return ONLY a valid JSON array (no markdown):
[
  {"question": "...", "scenario": "Brief scenario (1-2 sentences)"}
]
''';

    final rawText = await _callGemini(prompt);
    final cleaned = _stripMarkdown(rawText);
    final List<dynamic> parsed = jsonDecode(cleaned);
    return parsed
        .map((e) => TrainQuestion.fromMap(Map<String, dynamic>.from(e)))
        .take(5)
        .toList();
  }

  Future<TrainAnswerEvaluation> evaluateTrainAnswer({
    required String jobTitle,
    required String question,
    required String scenario,
    required String userAnswer,
  }) async {
    final prompt = '''
You are evaluating a job applicant's practice answer for a $jobTitle role.

Question: $question
Scenario: $scenario
Candidate answer: $userAnswer

Score 0-100 for relevance, clarity, and job fit. Return ONLY JSON:
{"score": 75, "feedback": "2-4 sentences of constructive feedback"}
''';

    final rawText = await _callGemini(prompt, temperature: 0.3);
    final cleaned = _stripMarkdown(rawText);
    final Map<String, dynamic> parsed = jsonDecode(cleaned);
    return TrainAnswerEvaluation.fromMap(parsed);
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

    final strength = CvProfileStrength.calculate(
      skills: skills,
      workExperience: workExperience,
      education: education,
      hasFile: fileUrl.isNotEmpty,
      experienceLevel:
          ProfileLevels.inferExperienceLevel(workExperience.length),
      educationLevel: ProfileLevels.inferEducationLevel(education),
    );

    return CvModel(
      uid: uid,
      fileUrl: fileUrl,
      fileName: fileName,
      uploadedAt: DateTime.now(),
      skills: skills,
      workExperience: workExperience,
      education: education,
      experienceLevel:
          ProfileLevels.inferExperienceLevel(workExperience.length),
      educationLevel: ProfileLevels.inferEducationLevel(education),
      profileStrength: strength,
    );
  }

  // ─── Shared HTTP helper ───────────────────────────────────────────────────
  Future<String> _callGemini(String prompt, {double temperature = 0.7}) async {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is missing. Add it to your .env file.');
    }

    const maxRetries = 4;
    final delays = [
      Duration(seconds: 5),
      Duration(seconds: 10),
      Duration(seconds: 20),
    ];

    for (var attempt = 0; attempt < maxRetries; attempt++) {
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
            'maxOutputTokens': 8192,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      }

      if ((response.statusCode == 503 || response.statusCode == 429) &&
          attempt < maxRetries - 1) {
        await Future.delayed(delays[attempt]);
        continue;
      }

      throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
    }

    throw Exception('Gemini API unavailable. Please try again later.');
  }

  // ─── Cover Letter Generation ──────────────────────────────────────────────
  Future<String> generateCoverLetter({
    required String jobTitle,
    required String company,
    required String jobDescription,
    required List<String> cvSkills,
    List<WorkExperience> workExperience = const [],
  }) async {
    final expText = workExperience.isEmpty
        ? 'No work experience provided.'
        : workExperience
            .map((e) =>
                '- ${e.title} at ${e.company} (${e.duration}): ${e.description}')
            .join('\n');

    final prompt = '''
You are an expert career coach. Write a professional cover letter for the following:

Job Title: $jobTitle
Company: $company
Job Description: $jobDescription

Candidate Skills: ${cvSkills.join(', ')}
Candidate Work Experience:
$expText

Instructions:
- Write in first person, professional yet warm tone
- 3-4 paragraphs: opening hook, relevant experience, skills alignment, closing call-to-action
- Tailor the letter specifically to the job and company
- Keep it under 350 words
- Do NOT include date, address blocks, or "Dear Hiring Manager" header — start directly with the opening paragraph
- Do NOT use placeholder brackets like [Your Name]

Return ONLY the cover letter text, no extra commentary.
''';

    return _callGemini(prompt, temperature: 0.75);
  }

  // ─── Career Coach Chat ────────────────────────────────────────────────────
  Future<String> chatWithCoach({
    required List<Map<String, String>> history,
    required String userMessage,
    required String systemContext,
  }) async {
    final prompt = '''
$systemContext

Conversation so far:
${history.map((m) => '${m['role'] == 'user' ? 'Candidate' : 'Coach'}: ${m['content']}').join('\n')}

Candidate: $userMessage
Coach:''';

    return _callGemini(prompt, temperature: 0.7);
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
