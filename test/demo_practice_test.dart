import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_pulse/data/models.dart';
import 'package:exam_pulse/data/repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('registration is separate from login; new student starts with no preset notes', () async {
    final repository = DemoStudyRepository();
    await repository.register(const StudentRegistration(name: 'Riya',
      className: 'BTech', year: '2', branch: 'Computer Science',
      email: 'riya@example.com', password: 'password123'));
    await expectLater(repository.materials(), throwsA(isA<ApiException>()));
    final session = await repository.login('riya@example.com', 'password123');
    expect(session.user.name, 'Riya');
    expect(session.user.year, '2');
    expect(session.user.branch, 'Computer Science');
    expect(await repository.materials(), isEmpty);
    expect(await repository.topics(), isEmpty);
    await expectLater(repository.register(const StudentRegistration(
      name: 'Second', className: 'BSc', year: '1', branch: 'Physics',
      email: 'riya@example.com', password: 'password123')),
      throwsA(isA<ApiException>()));
  });

  test('sample questions are optional and do not appear in personal topics', () async {
    final repository = DemoStudyRepository();
    await repository.login('student@exampulse.app', 'Demo@123');
    expect(await repository.materials(), isEmpty);
    expect(await repository.topics(), isEmpty);
    final quiz = await repository.assessment('sample:t1', 'quiz');
    expect(quiz.questions, hasLength(5));
    final result = await repository.submitAssessment(quiz.id, {
      for (final question in quiz.questions) question.id: 0,
    });
    expect(result.review, hasLength(5));
    expect(await repository.topics(), isEmpty);
    expect((await repository.dashboard()).completedAssessments, 1);
  });

  test('today progress is topic-level coverage, independent of mastery', () async {
    const topic = Topic('t1', 'Algebra', 92, 88, null,
      totalUnits: 20, todayUnits: 5);
    expect(topic.todayPercent, 25);
    expect(topic.mastery, 92);
    expect(topic.withProgress(viewed: 10).todayPercent, 50);
    expect(topic.withProgress(viewed: 0).todayPercent, 0);
  });
}
