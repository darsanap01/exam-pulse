class StudentProfile {
  final String id, name, className, year, branch, email;
  const StudentProfile({required this.id, required this.name,
    required this.className, required this.year, required this.branch,
    required this.email});
  factory StudentProfile.fromJson(Map<String, dynamic> j) => StudentProfile(
    id: (j['id'] ?? '').toString(), name: (j['name'] ?? '').toString(),
    className: (j['className'] ?? '').toString(), year: (j['year'] ?? '').toString(),
    branch: (j['branch'] ?? '').toString(), email: (j['email'] ?? '').toString());
  Map<String, dynamic> toJson() => {'id': id, 'name': name,
    'className': className, 'year': year, 'branch': branch, 'email': email};
}

class StudentRegistration {
  final String name, className, year, branch, email, password;
  const StudentRegistration({required this.name, required this.className,
    required this.year, required this.branch, required this.email,
    required this.password});
  Map<String, dynamic> toJson() => {
    'name': name, 'className': className, 'year': year, 'branch': branch,
    'email': email, 'password': password,
  };
}

class Session {
  final StudentProfile user;
  final String token;
  const Session(this.user, this.token);
  String get name => user.name;
  factory Session.fromJson(Map<String, dynamic> j) => Session(
    StudentProfile.fromJson(j['user'] as Map<String, dynamic>),
    j['accessToken'] as String);
}

class Dashboard {
  final int dailyGoalMinutes, studiedMinutes, streak, totalMaterials;
  final double masteryAverage, totalStudyPercent;
  final int completedAssessments;
  final String message;
  final List<String> badges, dailyPlan;
  const Dashboard({required this.dailyGoalMinutes, required this.studiedMinutes,
    required this.streak, required this.totalMaterials, required this.masteryAverage,
    required this.totalStudyPercent, required this.completedAssessments,
    required this.message, required this.badges, required this.dailyPlan});
  factory Dashboard.fromJson(Map<String, dynamic> j) => Dashboard(
    dailyGoalMinutes: (j['dailyGoalMinutes'] as num).toInt(),
    studiedMinutes: (j['studiedMinutes'] as num).toInt(),
    streak: (j['streak'] as num).toInt(),
    totalMaterials: (j['totalMaterials'] as num).toInt(),
    masteryAverage: (j['masteryAverage'] as num).toDouble(),
    totalStudyPercent: (j['totalStudyPercent'] as num?)?.toDouble() ?? (j['masteryAverage'] as num).toDouble(),
    completedAssessments: (j['completedAssessments'] as num?)?.toInt() ?? 0,
    message: j['message'] as String,
    badges: (j['badges'] as List).cast<String>(),
    dailyPlan: (j['dailyPlan'] as List).cast<String>(),
  );
}

class StudyMaterial {
  final String id, title, type, topicId, status;
  final DateTime uploadedAt;
  final String? localPath;
  const StudyMaterial(this.id, this.title, this.type, this.uploadedAt,
    {this.topicId = '', this.status = 'ready', this.localPath});
  factory StudyMaterial.fromJson(Map<String, dynamic> j) => StudyMaterial(
    j['id'] as String, j['title'] as String, j['type'] as String,
    DateTime.parse(j['uploadedAt'] as String).toLocal(),
    topicId: (j['topicId'] ?? '').toString(),
    status: (j['status'] ?? 'ready').toString(),
    localPath: j['localPath'] as String?);
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'type': type,
    'uploadedAt': uploadedAt.toUtc().toIso8601String(), 'topicId': topicId,
    'status': status, 'localPath': localPath};
}

// TODAY'S TOPIC STUDY is pages/units opened TODAY divided by the total units
// in THIS TOPIC'S material, not a global mastery/quiz score.
class Topic {
  final String id, title, materialId;
  final double mastery, confidence;
  final DateTime? nextRevisionAt;
  final int totalUnits, todayUnits;
  final String unitLabel;
  const Topic(this.id, this.title, this.mastery, this.confidence, this.nextRevisionAt,
    {this.materialId = '', this.totalUnits = 0, this.todayUnits = 0,
    this.unitLabel = 'pages'});
  double get todayPercent => totalUnits <= 0 ? 0 :
    (100 * todayUnits / totalUnits).clamp(0, 100).toDouble();
  factory Topic.fromJson(Map<String, dynamic> j) => Topic(
    j['id'] as String, j['title'] as String,
    (j['mastery'] as num?)?.toDouble() ?? 0,
    (j['confidence'] as num?)?.toDouble() ?? 0,
    j['nextRevisionAt'] == null ? null : DateTime.parse(j['nextRevisionAt'] as String).toLocal(),
    materialId: (j['materialId'] ?? '').toString(),
    totalUnits: (j['totalUnits'] as num?)?.toInt() ?? 0,
    todayUnits: (j['todayUnits'] as num?)?.toInt() ?? 0,
    unitLabel: (j['unitLabel'] ?? 'pages').toString());
  Map<String, dynamic> toJson() => {'id': id, 'title': title,
    'mastery': mastery, 'confidence': confidence,
    'nextRevisionAt': nextRevisionAt?.toUtc().toIso8601String(),
    'materialId': materialId, 'totalUnits': totalUnits,
    'todayUnits': todayUnits, 'unitLabel': unitLabel};
  Topic withProgress({int? total, int? viewed, double? newMastery,
    double? newConfidence, DateTime? retake}) => Topic(id, title,
    newMastery ?? mastery, newConfidence ?? confidence, retake ?? nextRevisionAt,
    materialId: materialId, totalUnits: total ?? totalUnits,
    todayUnits: viewed ?? todayUnits, unitLabel: unitLabel);
}
class Question {
  final String id;
  final String text;
  final List<String> options;

  const Question(
    this.id,
    this.text,
    this.options,
  );

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      json['id'].toString(),
      json['text'].toString(),
      List<String>.from(json['options']),
    );
  }
}

class Assessment {
  final String id;
  final String title;
  final String topicId;
  final String mode;
  final int targetPercent;
  final List<Question> questions;

  const Assessment(
    this.id,
    this.title,
    this.topicId,
    this.mode,
    this.targetPercent,
    this.questions,
  );

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      json['id'] as String,
      json['title'] as String,
      json['topicId'] as String,
      json['mode'] as String,
      (json['targetPercent'] as num).toInt(),
      (json['questions'] as List)
          .map(
            (item) => Question.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class AssessmentResult {
  final double scorePercent;
  final bool passed;
  final String feedback;
  final DateTime? retakeAt;
  final List<QuestionReview> review;
  const AssessmentResult(this.scorePercent, this.passed, this.feedback, this.retakeAt,
    [this.review = const []]);
  factory AssessmentResult.fromJson(Map<String, dynamic> j) => AssessmentResult(
    (j['scorePercent'] as num).toDouble(), j['passed'] as bool,
    j['feedback'] as String,
    j['retakeAt'] == null ? null : DateTime.parse(j['retakeAt'] as String).toLocal(),
    ((j['review'] as List?) ?? []).map((e) => QuestionReview.fromJson(e as Map<String, dynamic>)).toList());
}

class Flashcard {
  final String id, front, back;
  const Flashcard(this.id, this.front, this.back);
  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
    j['id'] as String, j['front'] as String, j['back'] as String);
}

class Revision {
  final String id, topicTitle, reason;
  final DateTime dueAt;
  final bool completed;
  const Revision(this.id, this.topicTitle, this.reason, this.dueAt, this.completed);
  factory Revision.fromJson(Map<String, dynamic> j) => Revision(
    j['id'] as String, j['topicTitle'] as String, j['reason'] as String,
    DateTime.parse(j['dueAt'] as String).toLocal(), j['completed'] as bool);
}

class VoiceFeedback {
  final String id, transcript, feedback, followUpQuestion;
  final double clarity, fluency, pronunciation, conceptual, confidence;
  const VoiceFeedback({required this.id, required this.transcript, required this.feedback,
    required this.followUpQuestion, required this.clarity, required this.fluency,
    required this.pronunciation, required this.conceptual, required this.confidence});
  factory VoiceFeedback.fromJson(Map<String, dynamic> j) => VoiceFeedback(
    id: j['id'] as String, transcript: j['transcript'] as String,
    feedback: j['feedback'] as String, followUpQuestion: j['followUpQuestion'] as String,
    clarity: (j['clarity'] as num).toDouble(), fluency: (j['fluency'] as num).toDouble(),
    pronunciation: (j['pronunciation'] as num).toDouble(),
    conceptual: (j['conceptual'] as num).toDouble(),
    confidence: (j['confidence'] as num).toDouble());
}

class QuestionReview {
  final String questionId, questionText, explanation;
  final List<String> options;
  final int? selectedIndex;
  final int correctIndex;
  const QuestionReview({required this.questionId, required this.questionText,
    required this.options, required this.selectedIndex, required this.correctIndex,
    required this.explanation});
  bool get correct => selectedIndex == correctIndex;
  factory QuestionReview.fromJson(Map<String, dynamic> j) => QuestionReview(
    questionId: j['questionId'] as String, questionText: j['questionText'] as String,
    options: (j['options'] as List).cast<String>(),
    selectedIndex: (j['selectedIndex'] as num?)?.toInt(),
    correctIndex: (j['correctIndex'] as num).toInt(),
    explanation: j['explanation'] as String? ?? '',
  );
}
