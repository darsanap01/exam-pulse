import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../data/models.dart';
import '../data/repository.dart';

class AppController extends ChangeNotifier {
  final StudyRepository repository;
  final bool demo;
  AppController(this.repository, {required this.demo});

  StudentProfile? student;
  String? get userName => student?.name;
  Dashboard? dashboard;
  List<StudyMaterial> materials = [];
  List<Topic> topics = [];
  List<Revision> revisions = [];
  String? error;
  bool busy = false;
  bool registrationComplete = false;
  bool get signedIn => student != null;
  Future<void> _unitQueue = Future.value();

  Future<void> _run(Future<void> Function() work) async {
    if (busy) return;
    busy = true; error = null; notifyListeners();
    try { await work(); }
    catch (e) { error = e.toString(); }
    finally { busy = false; notifyListeners(); }
  }

  Future<void> signIn(String email, String password) => _run(() async {
    final session = await repository.login(email, password);
    student = session.user;
    try { await _fetch(); }
    catch (_) { repository.clearSession(); student = null; rethrow; }
  });

  Future<void> register(StudentRegistration registration) => _run(() async {
    await repository.register(registration);
    registrationComplete = true;
    // Stay signed out; auth UI switches to Login and shows a success notice.
  });
  void clearRegistrationNotice() {
    registrationComplete = false; notifyListeners();
  }
  Future<void> exploreSample() => signIn('student@exampulse.app', 'Demo@123');

  void signOut() {
    repository.clearSession(); student = null;
    dashboard = null; materials = []; topics = []; revisions = [];
    error = null; registrationComplete = false;
    notifyListeners();
  }

  Future<void> _fetch() async {
    final results = await Future.wait<dynamic>([
      repository.dashboard(), repository.materials(), repository.topics(), repository.revisions(),
    ]);
    dashboard = results[0] as Dashboard;
    materials = results[1] as List<StudyMaterial>;
    topics = results[2] as List<Topic>;
    revisions = results[3] as List<Revision>;
    notifyListeners();
  }
  Future<void> refresh() => _run(_fetch);

  Future<StudyMaterial?> upload(PlatformFile file, String topicTitle) async {
    if (busy) return null;
    if (file.size > 20 * 1024 * 1024) {
      error = 'Maximum file size is 20 MB.';
      notifyListeners();
      return null;
    }
    StudyMaterial? material;
    await _run(() async {
      material = await repository.uploadMaterial(file, topicTitle);
      await _fetch();
    });
    return material;
  }

  Future<void> markStudiedUnit(String topicId, int unit, int totalUnits) {
    // Serialize PDF page events; avoid races from quick swipes and disk writes.
    final action = _unitQueue.then((_) async {
      await repository.markStudiedUnit(topicId, unit, totalUnits);
      topics = await repository.topics();
      notifyListeners();
    });
    _unitQueue = action.catchError((Object e) { error = e.toString(); notifyListeners(); });
    return action;
  }

  Future<void> markRevision(String id) => _run(() async {
    await repository.completeRevision(id);
    await _fetch();
  });
  Future<Assessment> loadAssessment(String topicId, String mode) =>
    repository.assessment(topicId, mode);
  Future<AssessmentResult> submitAssessment(String id, Map<String, int> answers) async {
    final result = await repository.submitAssessment(id, answers);
    await refresh();
    return result;
  }
  Future<List<Flashcard>> loadFlashcards(String topicId) => repository.flashcards(topicId);
  Future<VoiceFeedback> analyzeVoice(String topicId, String path) =>
    repository.analyzeVoice(topicId, path);
  Future<VoiceFeedback> followUp(String id, String answer) => repository.followUp(id, answer);
  Future<VoiceFeedback> followUpAudio(String id, String path) => repository.followUpAudio(id, path);
}
