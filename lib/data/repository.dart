import 'dart:convert';
import 'dart:io' show File, Directory;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'demo_questions.dart';

abstract class StudyRepository {
  Future<Session> login(String email, String password);
  // Registration deliberately DOES NOT log in; the next screen is Login.
  Future<void> register(StudentRegistration registration);
  void clearSession();
  Future<Dashboard> dashboard();
  Future<List<StudyMaterial>> materials();
  Future<List<Topic>> topics();
  Future<List<Revision>> revisions();
  Future<StudyMaterial> uploadMaterial(PlatformFile file, String topicTitle);
  Future<Uint8List> materialBytes(StudyMaterial material);
  Future<void> markStudiedUnit(String topicId, int unit, int totalUnits);
  Future<Assessment> assessment(String topicId, String mode);
  Future<AssessmentResult> submitAssessment(String assessmentId, Map<String, int> answers);
  Future<List<Flashcard>> flashcards(String topicId);
  Future<void> completeRevision(String revisionId);
  Future<VoiceFeedback> analyzeVoice(String topicId, String audioPath);
  Future<VoiceFeedback> followUp(String feedbackId, String answer);
  Future<VoiceFeedback> followUpAudio(String feedbackId, String audioPath);
}

class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiStudyRepository implements StudyRepository {
  final String baseUrl;
  final http.Client _client;
  String? _token;
  ApiStudyRepository(String baseUrl, {http.Client? client})
      : baseUrl = baseUrl.replaceAll(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Accept': 'application/json', 'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
  Uri _uri(String path, [Map<String, String>? params]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: params);

  dynamic _read(http.Response response) {
    dynamic body;
    try { body = jsonDecode(response.body); }
    catch (_) { throw ApiException('Invalid JSON from server', response.statusCode); }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map ? (body['message'] ?? body['error']) : null;
      throw ApiException(message?.toString() ?? 'Request failed (${response.statusCode})', response.statusCode);
    }
    return body;
  }

 Future<Map<String, dynamic>> _object(
  String path, {
  String method = 'GET',
  Object? body,
  Map<String, String>? query,
}) async {
  late http.Response response;

  try {
    response = await (method == 'POST'
            ? _client.post(
                _uri(path, query),
                headers: _headers,
                body: jsonEncode(body),
              )
            : _client.get(
                _uri(path, query),
                headers: _headers,
              ))
        .timeout(const Duration(seconds: 45));
  } catch (e) {
    throw const ApiException(
      'Cannot reach the Node.js server. '
      'Check your connection and API_BASE_URL.',
    );
  }

  final data = _read(response);

  if (data is! Map<String, dynamic>) {
    throw const ApiException(
      'Expected a JSON object from server',
    );
  }

  return data;
}

  Future<List<T>> _list<T>(String path, T Function(Map<String, dynamic>) parse) async {
    final data = await _object(path);
    final items = data['items'];
    if (items is! List) throw const ApiException('Expected server response {"items": [...]}');
    return items.map((e) => parse(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Session> login(String email, String password) async {
    final session = Session.fromJson(await _object('/auth/login', method: 'POST',
      body: {'email': email.trim().toLowerCase(), 'password': password}));
    _token = session.token;
    return session;
  }
  @override
  Future<void> register(StudentRegistration registration) async {
    await _object('/auth/register', method: 'POST', body: registration.toJson());
    _token = null;
  }
  @override
  void clearSession() => _token = null;
  @override
  Future<Dashboard> dashboard() async => Dashboard.fromJson(await _object('/dashboard'));
  @override
  Future<List<StudyMaterial>> materials() => _list('/materials', StudyMaterial.fromJson);
  @override
  Future<List<Topic>> topics() => _list('/topics', Topic.fromJson);
  @override
  Future<List<Revision>> revisions() => _list('/revisions', Revision.fromJson);

  @override
  Future<StudyMaterial> uploadMaterial(PlatformFile file, String topicTitle) async {
    final request = http.MultipartRequest('POST', _uri('/materials'));
    request.headers.addAll({'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token'});
    request.fields['topicTitle'] = topicTitle;
    if (!kIsWeb && file.path != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path!, filename: file.name));
    } else if (file.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
    } else { throw const ApiException('File data could not be read. Select the file again.'); }
    try {
      final streamed = await _client.send(request).timeout(const Duration(minutes: 2));
      return StudyMaterial.fromJson(_read(await http.Response.fromStream(streamed)) as Map<String, dynamic>);
    } on ApiException { rethrow; }
    catch (_) { throw const ApiException('Upload failed. Check connection and file size.'); }
  }

  @override
  Future<Uint8List> materialBytes(StudyMaterial material) async {
    try {
      final response = await _client.get(_uri('/materials/${Uri.encodeComponent(material.id)}/file'),
        headers: {'Accept': '*/*', if (_token != null) 'Authorization': 'Bearer $_token'})
        .timeout(const Duration(minutes: 2));
      if (response.statusCode != 200) {
        throw ApiException('Cannot open material (${response.statusCode}). Check file access.', response.statusCode);
      }
      return response.bodyBytes;
    } on ApiException { rethrow; }
    catch (_) { throw const ApiException('Cannot download this file. Check your connection and try again.'); }
  }

  @override
  Future<void> markStudiedUnit(String topicId, int unit, int totalUnits) async {
    await _object('/topics/${Uri.encodeComponent(topicId)}/study-units', method: 'POST',
      body: {'unit': unit, 'totalUnits': totalUnits,
        'date': DateTime.now().toIso8601String().substring(0, 10)});
  }
  @override
  Future<Assessment> assessment(String topicId, String mode) async => Assessment.fromJson(
    await _object('/assessments', query: {'topicId': topicId, 'mode': mode}));
  @override
  Future<AssessmentResult> submitAssessment(String id, Map<String, int> answers) async =>
    AssessmentResult.fromJson(await _object('/assessments/${Uri.encodeComponent(id)}/submit', method: 'POST',
      body: {'answers': answers.entries.map((e) => {'questionId': e.key, 'optionIndex': e.value}).toList()}));
  @override
  Future<List<Flashcard>> flashcards(String topicId) => _list(
    '/flashcards?topicId=${Uri.encodeQueryComponent(topicId)}', Flashcard.fromJson);
  @override
  Future<void> completeRevision(String id) async {
    await _object('/revisions/${Uri.encodeComponent(id)}/complete', method: 'POST', body: <String, dynamic>{});
  }
  @override
  Future<VoiceFeedback> analyzeVoice(String topicId, String audioPath) async {
    if (kIsWeb) throw const ApiException('Voice recording is available in the Android/iOS app.');
    if (!await File(audioPath).exists()) throw const ApiException('Recorded audio file not found');
    final request = http.MultipartRequest('POST', _uri('/voice/analyze'));
    request.headers.addAll({'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token'});
    request.fields['topicId'] = topicId;
    request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
    try {
      final response = await _client.send(request).timeout(const Duration(minutes: 2));
      return VoiceFeedback.fromJson(_read(await http.Response.fromStream(response)) as Map<String, dynamic>);
    } on ApiException { rethrow; }
    catch (_) { throw const ApiException('Audio analysis failed. Check connection and retry.'); }
  }
  @override
  Future<VoiceFeedback> followUp(String id, String answer) async => VoiceFeedback.fromJson(
    await _object('/voice/${Uri.encodeComponent(id)}/follow-up', method: 'POST', body: {'answer': answer}));
  @override
  Future<VoiceFeedback> followUpAudio(String id, String audioPath) async {
    if (kIsWeb || !await File(audioPath).exists()) {
      throw const ApiException('Follow-up audio recording is available on Android/iOS only');
    }
    final request = http.MultipartRequest('POST',
      _uri('/voice/${Uri.encodeComponent(id)}/follow-up/audio'));
    request.headers.addAll({'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token'});
    request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
    try {
      final response = await _client.send(request).timeout(const Duration(minutes: 2));
      return VoiceFeedback.fromJson(_read(await http.Response.fromStream(response)) as Map<String, dynamic>);
    } on ApiException { rethrow; }
    catch (_) { throw const ApiException('Could not analyse the spoken follow-up answer'); }
  }
}

// Offline UI testing only. Each account has its OWN notes, topics and progress.
// It does not invent topic questions from an arbitrary student PDF or claim to run AI.
class DemoStudyRepository implements StudyRepository {
  static const _accountsKey = 'exam_pulse_v3_accounts';
  static const _statePrefix = 'exam_pulse_v3_student_';
  SharedPreferences? _prefs;
  final Map<String, Map<String, dynamic>> _accounts = {};
  String? _activeEmail;
  final List<StudyMaterial> _materials = [];
  final List<Topic> _topics = [];
  final List<Revision> _revisions = [];
  final Map<String, Set<int>> _viewedToday = {};
  String _day = '';
  int _studiedMinutes = 0, _completedAssessments = 0, _attempt = 0;
  final Map<String, Assessment> _assessments = {};

  Future<void> _initialize() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_accountsKey);
    if (raw != null) {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      for (final item in parsed.entries) {
        _accounts[item.key] = Map<String, dynamic>.from(item.value as Map);
      }
    }
    if (!_accounts.containsKey('student@exampulse.app')) {
      const email = 'student@exampulse.app';
      _accounts[email] = {'profile': const StudentProfile(id: 'sample',
        name: 'Sample Student', className: 'BSc', year: '1', branch: 'Computer Science',
        email: email).toJson(), 'passwordHash': _hash('Demo@123')};
      await _saveAccounts();
    }
  }
  String _hash(String input) => sha256.convert(utf8.encode(input)).toString();
  String _stateKey(String email) => '$_statePrefix${_hash(email)}';
  String get _email => _activeEmail ?? (throw const ApiException('Please login first'));
  StudentProfile get _profile => StudentProfile.fromJson(
    _accounts[_email]!['profile'] as Map<String, dynamic>);
  Future<void> _saveAccounts() async {
    await _prefs!.setString(_accountsKey, jsonEncode(_accounts));
  }
  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  void _rollDay() {
    final now = _today();
    if (now == _day) return;
    _day = now;
    _viewedToday.clear();
    for (var i = 0; i < _topics.length; i++) {
      _topics[i] = _topics[i].withProgress(viewed: 0);
    }
  }
  Future<void> _restoreStudent(String email) async {
    _activeEmail = email;
    _materials.clear(); _topics.clear(); _revisions.clear();
    _viewedToday.clear(); _assessments.clear();
    _studiedMinutes = 0; _completedAssessments = 0;
    final raw = _prefs!.getString(_stateKey(email));
    if (raw == null) { _day = _today(); return; }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _day = (json['day'] ?? '').toString();
    _materials.addAll(((json['materials'] as List?) ?? []).map((e) =>
      StudyMaterial.fromJson(e as Map<String, dynamic>)));
    _topics.addAll(((json['topics'] as List?) ?? []).map((e) =>
      Topic.fromJson(e as Map<String, dynamic>)));
    _revisions.addAll(((json['revisions'] as List?) ?? []).map((e) =>
      Revision.fromJson(e as Map<String, dynamic>)));
    final viewed = (json['viewedToday'] as Map<String, dynamic>?) ?? {};
    for (final entry in viewed.entries) {
      _viewedToday[entry.key] = (entry.value as List).map((e) => (e as num).toInt()).toSet();
    }
    _studiedMinutes = (json['studiedMinutes'] as num?)?.toInt() ?? 0;
    _completedAssessments = (json['completedAssessments'] as num?)?.toInt() ?? 0;
    _rollDay();
  }
  Future<void> _save() async {
    if (_activeEmail == null) return;
    await _prefs!.setString(_stateKey(_email), jsonEncode({
      'day': _day, 'materials': _materials.map((e) => e.toJson()).toList(),
      'topics': _topics.map((e) => e.toJson()).toList(),
      'revisions': _revisions.map((e) => {'id': e.id, 'topicTitle': e.topicTitle,
        'reason': e.reason, 'dueAt': e.dueAt.toUtc().toIso8601String(),
        'completed': e.completed}).toList(),
      'viewedToday': _viewedToday.map((k, v) => MapEntry(k, v.toList())),
      'studiedMinutes': _studiedMinutes, 'completedAssessments': _completedAssessments,
    }));
  }

  @override
  Future<Session> login(String email, String password) async {
    await _initialize();
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null || account['passwordHash'] != _hash(password)) {
      throw const ApiException('Incorrect email or password.');
    }
    await _restoreStudent(key);
    await _save();
    return Session(_profile, 'demo-only-token');
  }
  @override
  Future<void> register(StudentRegistration registration) async {
    await _initialize();
    final email = registration.email.trim().toLowerCase();
    if (_accounts.containsKey(email)) throw const ApiException('This email is already registered. Login instead.');
    final profile = StudentProfile(id: _hash(email).substring(0, 12),
      name: registration.name.trim(), className: registration.className.trim(),
      year: registration.year, branch: registration.branch.trim(), email: email);
    _accounts[email] = {'profile': profile.toJson(), 'passwordHash': _hash(registration.password)};
    await _saveAccounts();
    // Do NOT activate this user. Student must log in explicitly after registration.
  }
  @override
  void clearSession() {
    _activeEmail = null; _materials.clear(); _topics.clear(); _revisions.clear();
    _viewedToday.clear(); _assessments.clear();
  }
  @override
  Future<Dashboard> dashboard() async {
    _email; _rollDay();
    return Dashboard(dailyGoalMinutes: 60, studiedMinutes: _studiedMinutes,
      streak: _completedAssessments > 0 ? 1 : 0, totalMaterials: _materials.length,
      masteryAverage: _topics.isEmpty ? 0 :
        _topics.fold<double>(0, (sum, t) => sum + t.mastery) / _topics.length,
      totalStudyPercent: 0, completedAssessments: _completedAssessments,
      message: _topics.isEmpty ? 'Upload your own PDF to build your learning plan.' :
        'Open a topic and study a few pages today.',
      badges: [if (_completedAssessments > 0) 'First quiz',
        if (_completedAssessments >= 3) '3 practice sessions'],
      dailyPlan: _topics.isEmpty ? const ['Upload a PDF for your own stream'] :
        _topics.map((t) => '${t.title} • ${t.todayUnits}/${t.totalUnits == 0 ? '?' : t.totalUnits} ${t.unitLabel} today').toList());
  }
  @override
  Future<List<StudyMaterial>> materials() async { _email; return List.of(_materials); }
  @override
  Future<List<Topic>> topics() async { _email; _rollDay(); return List.of(_topics); }
  @override
  Future<List<Revision>> revisions() async { _email; return List.of(_revisions); }
  @override
  Future<StudyMaterial> uploadMaterial(PlatformFile file, String topicTitle) async {
    _email;
    if (kIsWeb) throw const ApiException('Offline document storage in demo mode requires Android or iOS. Use the Node.js API for web.');
    final bytes = file.bytes ?? (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null || bytes.isEmpty) throw const ApiException('Could not read selected document');
    final id = '${DateTime.now().microsecondsSinceEpoch}';
    final directory = await getApplicationDocumentsDirectory();
    final dir = DirectoryHelper('${directory.path}/exam_pulse/${_hash(_email)}');
    await dir.create();
    final ext = (file.extension ?? 'pdf').toLowerCase();
    final localPath = '${dir.path}/$id.$ext';
    await File(localPath).writeAsBytes(bytes, flush: true);
    final material = StudyMaterial(id, file.name, ext, DateTime.now(),
      topicId: id, localPath: localPath);
    _materials.insert(0, material);
    _topics.insert(0, Topic(id, topicTitle.trim(), 0, 0, null,
      materialId: id, totalUnits: ext == 'pdf' ? 0 : 1,
      unitLabel: ext == 'pdf' ? 'pages' : 'notes'));
    await _save();
    return material;
  }
  @override
  Future<Uint8List> materialBytes(StudyMaterial material) async {
    _email;
    if (!_materials.any((e) => e.id == material.id)) throw const ApiException('Material is not in your account');
    if (material.localPath == null || !await File(material.localPath!).exists()) {
      throw const ApiException('Saved file is missing. Please upload it again.');
    }
    return File(material.localPath!).readAsBytes();
  }
  @override
  Future<void> markStudiedUnit(String topicId, int unit, int totalUnits) async {
    _email; _rollDay();
    if (unit <= 0 || totalUnits <= 0 || unit > totalUnits) return;
    final index = _topics.indexWhere((t) => t.id == topicId);
    if (index < 0) throw const ApiException('Topic does not belong to this account');
    final units = _viewedToday.putIfAbsent(topicId, () => <int>{});
    units.add(unit);
    _topics[index] = _topics[index].withProgress(total: totalUnits, viewed: units.length);
    await _save();
  }
  bool _isSample(String id) => id.startsWith('sample:');
  @override
  Future<Assessment> assessment(String topicId, String mode) async {
    _email;
    if (!_isSample(topicId)) {
      throw const ApiException('AI questions from YOUR material require the Node.js backend. Connect it to practise this topic. Sample questions can be tried separately in Practice.');
    }
    final bankId = topicId.substring('sample:'.length);
    if (!demoBanks.containsKey(bankId)) throw const ApiException('Sample topic not found');
    final id = 'a-${DateTime.now().microsecondsSinceEpoch}-${_attempt++}';
    final quiz = Assessment(id, 'Sample practice', topicId, mode, 70,
      demoQuestions(bankId, mock: mode == 'mock', offset: _attempt));
    _assessments[id] = quiz;
    return quiz;
  }
  @override
  Future<AssessmentResult> submitAssessment(String id, Map<String, int> answers) async {
    _email;
    final assessment = _assessments.remove(id);
    if (assessment == null) throw const ApiException('Assessment expired. Start a new practice.');
    if (answers.length != assessment.questions.length) {
      _assessments[id] = assessment;
      throw const ApiException('Answer all questions before submitting.');
    }
    final bank = demoBanks[assessment.topicId.substring('sample:'.length)]!;
    final review = assessment.questions.map((q) {
      final item = bank[int.parse(q.id.split('-').last)];
      return QuestionReview(questionId: q.id, questionText: q.text,
        options: q.options, selectedIndex: answers[q.id],
        correctIndex: item.correct, explanation: item.explanation);
    }).toList();
    final score = 100 * review.where((r) => r.correct).length / review.length;
    _completedAssessments++; _studiedMinutes += assessment.mode == 'mock' ? 20 : 10;
    await _save();
    return AssessmentResult(score, score >= assessment.targetPercent,
      'These are sample-only questions, not generated from your uploaded material.',
      score >= assessment.targetPercent ? null : DateTime.now().add(const Duration(days: 1)), review);
  }
  @override
  Future<List<Flashcard>> flashcards(String topicId) async {
    _email;
    if (!_isSample(topicId)) throw const ApiException('AI flashcards from your material need the Node.js backend.');
    final bank = demoBanks[topicId.substring('sample:'.length)] ?? [];
    return List.generate(bank.length, (i) => Flashcard('$topicId-f$i', bank[i].text,
      '${bank[i].options[bank[i].correct]}\n\n${bank[i].explanation}'));
  }
  @override
  Future<void> completeRevision(String id) async {
    _email;
    final index = _revisions.indexWhere((r) => r.id == id);
    if (index < 0) throw const ApiException('Revision not found');
    final r = _revisions[index];
    _revisions[index] = Revision(r.id, r.topicTitle, r.reason, r.dueAt, true);
    await _save();
  }
  @override
  Future<VoiceFeedback> analyzeVoice(String topicId, String audioPath) async =>
    throw const ApiException('AI speech-to-text, feedback and voice follow-ups require the Node.js backend. Demo mode never invents voice scores.');
  @override
  Future<VoiceFeedback> followUp(String feedbackId, String answer) async =>
    throw const ApiException('AI follow-up questions require the Node.js backend.');
  @override
  Future<VoiceFeedback> followUpAudio(String feedbackId, String audioPath) async =>
    throw const ApiException('AI spoken follow-up needs the Node.js backend.');
}

// Keep dart:io Directory import out of the web UI. Only reached in mobile demo.
class DirectoryHelper {
  final String path;
  const DirectoryHelper(this.path);
  Future<void> create() async {
    final directory = Directory(path);
    if (!await directory.exists()) await directory.create(recursive: true);
  }
}
