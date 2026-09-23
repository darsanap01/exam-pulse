import 'package:flutter_test/flutter_test.dart';
import 'package:exam_pulse/data/models.dart';

void main() {
  test('Topic parses API percentages and optional revision date', () {
    final topic = Topic.fromJson({
      'id': 't1', 'title': 'Cell biology', 'mastery': 48, 'confidence': 61.5,
      'nextRevisionAt': null,
    });
    expect(topic.mastery, 48);
    expect(topic.confidence, 61.5);
    expect(topic.nextRevisionAt, isNull);
  });

  test('Assessment result parses retake date when target missed', () {
    final result = AssessmentResult.fromJson({
      'scorePercent': 55, 'passed': false, 'feedback': 'Review topic',
      'retakeAt': '2026-09-23T09:00:00Z',
    });
    expect(result.passed, isFalse);
    expect(result.retakeAt, isNotNull);
    expect(result.review, isEmpty);
  });
  test('Dashboard receives explicit overall percentage and completed sessions', () {
    final dashboard = Dashboard.fromJson({
      'dailyGoalMinutes': 100, 'studiedMinutes': 25, 'streak': 2,
      'totalMaterials': 3, 'masteryAverage': 45,
      'totalStudyPercent': 51.5, 'completedAssessments': 4,
      'message': 'Keep studying', 'badges': <String>[], 'dailyPlan': <String>[],
    });
    expect(dashboard.totalStudyPercent, 51.5);
    expect(dashboard.completedAssessments, 4);
  });
}
