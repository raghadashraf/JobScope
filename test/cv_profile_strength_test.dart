import 'package:flutter_test/flutter_test.dart';
import 'package:jobscope/core/utils/cv_profile_strength.dart';
import 'package:jobscope/data/models/cv_model.dart';

void main() {
  test('file only scores 10%', () {
    expect(
      CvProfileStrength.fromCv(CvModel(
        uid: 'u1',
        fileUrl: 'https://x.com/cv.pdf',
        fileName: 'cv.pdf',
        uploadedAt: DateTime(2026, 1, 1),
        skills: const [],
        workExperience: const [],
        education: const [],
        profileStrength: 25,
      )),
      10,
    );
  });

  test('skills + file increases score', () {
    expect(
      CvProfileStrength.calculate(
        skills: const ['Flutter', 'Dart', 'Firebase', 'Riverpod', 'Git'],
        workExperience: const [],
        education: const [],
        hasFile: true,
      ),
      30,
    );
  });

  test('education only without file is 25%', () {
    expect(
      CvProfileStrength.calculate(
        skills: const [],
        workExperience: const [],
        education: [
          Education(
            institution: 'Uni',
            degree: 'BSc',
            field: 'CS',
            year: '2024',
          ),
        ],
        hasFile: true,
      ),
      35,
    );
  });
}
