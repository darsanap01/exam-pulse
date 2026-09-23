import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import 'screens.dart';

class QuizScreen extends StatefulWidget {
  final AppController c;
  final Topic topic;
  final String mode;
  const QuizScreen({super.key, required this.c, required this.topic, required this.mode});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Future<Assessment> assessmentFuture;
  final Map<String, int> answers = {};
  int current = 0;
  bool sending = false;
  AssessmentResult? result;
  String? failure;

  @override
  void initState() {
    super.initState();
    assessmentFuture = widget.c.loadAssessment(widget.topic.id, widget.mode);
  }

  void retry() => setState(() {
    current = 0; answers.clear(); result = null; failure = null;
    assessmentFuture = widget.c.loadAssessment(widget.topic.id, widget.mode);
  });

  Future<void> submit(Assessment quiz) async {
    if (answers.length != quiz.questions.length) {
      final unanswered = quiz.questions.indexWhere((q) => !answers.containsKey(q.id));
      setState(() { current = unanswered < 0 ? current : unanswered;
        failure = 'Answer all ${quiz.questions.length} questions before submitting.'; });
      return;
    }
    setState(() { sending = true; failure = null; });
    try {
      final response = await widget.c.submitAssessment(quiz.id, answers);
      if (mounted) setState(() => result = response);
    } catch (e) {
      if (mounted) setState(() => failure = e.toString());
    } finally { if (mounted) setState(() => sending = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.mode == 'mock' ? 'Mock test' : 'Practice quiz',
      style: const TextStyle(color: ink, fontWeight: FontWeight.w800))),
    body: FutureBuilder<Assessment>(future: assessmentFuture, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) return Center(child: Padding(
        padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Could not load questions: ${snapshot.error}', textAlign: TextAlign.center),
          const SizedBox(height: 12), FilledButton(onPressed: retry, child: const Text('Retry')),
        ])));
      final quiz = snapshot.data!;
      if (quiz.questions.isEmpty) return const Center(child: Text('No questions available for this topic yet.'));
      if (result != null) return _ResultView(result: result!, quiz: quiz, retry: retry);
      final question = quiz.questions[current];
      return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 740),
        child: ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [
          Text(widget.topic.title, style: const TextStyle(fontSize: 23,
            color: ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('Question ${current + 1} / ${quiz.questions.length}  •  ${answers.length} answered  •  Target ${quiz.targetPercent}%',
            style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 13),
          LinearProgressIndicator(value: answers.length / quiz.questions.length,
            minHeight: 8, color: mint, borderRadius: BorderRadius.circular(12)),
          const SizedBox(height: 18),
          Wrap(spacing: 5, runSpacing: 7,
            children: List.generate(quiz.questions.length, (index) {
              final answered = answers.containsKey(quiz.questions[index].id);
              return SizedBox(width: 37, height: 37, child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: sending ? null : () => setState(() { current = index; failure = null; }),
                child: DecoratedBox(decoration: BoxDecoration(
                  color: index == current ? purple : answered ? const Color(0xFFD8F7ED) : Colors.white,
                  border: Border.all(color: index == current ? purple : const Color(0xFFE3E4F0)),
                  borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('${index + 1}', style: TextStyle(
                    color: index == current ? Colors.white : ink, fontWeight: FontWeight.w700))))));
            })),
          const SizedBox(height: 18),
          InfoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('CHOOSE THE CORRECT ANSWER', style: TextStyle(
              fontSize: 11, color: purple, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Text(question.text, style: const TextStyle(fontSize: 20, color: ink,
              height: 1.35, fontWeight: FontWeight.w800)),
          ])),
          ...List.generate(question.options.length, (i) {
            final chosen = answers[question.id] == i;
            return Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: sending ? null : () => setState(() { answers[question.id] = i; failure = null; }),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(color: chosen ? pale : Colors.white,
                  border: Border.all(color: chosen ? purple : const Color(0xFFE1E4F0),
                    width: chosen ? 2 : 1), borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: chosen ? purple : const Color(0xFFF0F1F7),
                    child: Text(String.fromCharCode(65 + i), style: TextStyle(
                      color: chosen ? Colors.white : ink, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(question.options[i], style: const TextStyle(fontSize: 15, color: ink))),
                  Icon(chosen ? Icons.check_circle : Icons.circle_outlined,
                    color: chosen ? purple : Colors.black26),
                ]))),
            );
          }),
          const SizedBox(height: 10),
          Row(children: [
            OutlinedButton.icon(onPressed: sending || current == 0 ? null :
              () => setState(() { current--; failure = null; }),
              icon: const Icon(Icons.arrow_back), label: const Text('Back')),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(
              onPressed: sending ? null : () {
                if (current < quiz.questions.length - 1) {
                  setState(() { current++; failure = null; });
                } else { submit(quiz); }
              },
              child: Text(sending ? 'Checking answers…' :
                current == quiz.questions.length - 1 ? 'Submit answers' : 'Next question →'))),
          ]),
          if (current != quiz.questions.length - 1 && answers.length == quiz.questions.length)
            TextButton(onPressed: sending ? null : () => submit(quiz),
              child: const Text('All answered — submit now')),
          if (failure != null) Padding(padding: const EdgeInsets.only(top: 13),
            child: Text(failure!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 6),
          Text(widget.c.demo ? 'Curated sample questions • Feedback appears after submission' :
            'Answers are checked by your study service after submission.',
            style: const TextStyle(color: Colors.black45, fontSize: 12)),
        ])));
    }),
  );
}

class _ResultView extends StatelessWidget {
  final AssessmentResult result;
  final Assessment quiz;
  final VoidCallback retry;
  const _ResultView({required this.result, required this.quiz, required this.retry});
  @override
  Widget build(BuildContext context) => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 740),
    child: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4434B9), Color(0xFF8575F0)]),
        borderRadius: BorderRadius.circular(25)), child: Column(children: [
          Icon(result.passed ? Icons.emoji_events_rounded : Icons.menu_book_rounded,
            color: Colors.white, size: 46),
          const SizedBox(height: 10),
          Text('${result.scorePercent.round()}%', style: const TextStyle(color: Colors.white,
            fontSize: 48, fontWeight: FontWeight.w900)),
          Text(result.passed ? 'Target achieved!' : 'Keep practising!',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(result.feedback, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70)),
        ])),
      const SizedBox(height: 14),
      if (result.retakeAt != null) InfoCard(child: Row(children: [
        const Icon(Icons.event_repeat_outlined, color: purple), const SizedBox(width: 10),
        Expanded(child: Text('Suggested retest: ${dateText(result.retakeAt!)}')),
      ])),
      FilledButton.icon(onPressed: retry, icon: const Icon(Icons.replay_rounded),
        label: const Text('Practice again')),
      const SectionTitle('Review your answers'),
      if (result.review.isEmpty) const InfoCard(child: Text(
        'This result does not include a question-by-question review. '
        'Ask your backend developer to return the review array described in API_CONTRACT.md.')),
      ...result.review.asMap().entries.map((entry) {
        final item = entry.value;
        return InfoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(item.correct ? Icons.check_circle : Icons.cancel,
              color: item.correct ? mint : const Color(0xFFD96161)),
            const SizedBox(width: 8),
            Expanded(child: Text('Question ${entry.key + 1} • ${item.correct ? 'Correct' : 'Review needed'}',
              style: const TextStyle(color: ink, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 9),
          Text(item.questionText, style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          Text('Your answer: ${item.selectedIndex == null ? 'Not answered' : item.options[item.selectedIndex!]}'),
          if (!item.correct) Text('Correct answer: ${item.options[item.correctIndex]}',
            style: const TextStyle(color: mint, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text(item.explanation, style: const TextStyle(color: Colors.black54)),
        ]));
      }),
    ])));
}
class FlashcardsScreen extends StatefulWidget {
  final AppController c;
  final Topic topic;
  const FlashcardsScreen({super.key, required this.c, required this.topic});
  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late Future<List<Flashcard>> future;
  int index = 0;
  bool revealed = false, complete = false;
  final Set<String> remembered = {}, reviewAgain = {};
  @override
  void initState() { super.initState(); future = widget.c.loadFlashcards(widget.topic.id); }

  void rate(List<Flashcard> cards, bool knewIt) {
    final id = cards[index].id;
    setState(() {
      if (knewIt) { remembered.add(id); reviewAgain.remove(id); }
      else { reviewAgain.add(id); remembered.remove(id); }
      revealed = false;
      if (index == cards.length - 1) complete = true;
      else index++;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Flashcards • ${widget.topic.title}')),
    body: FutureBuilder<List<Flashcard>>(future: future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text('Could not load flashcards: ${snapshot.error}'));
      final cards = snapshot.data!;
      if (cards.isEmpty) return const Center(child: Text('No flashcards available for this topic yet.'));
      if (complete) return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 530),
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(20), children: [
          const Icon(Icons.auto_awesome, color: purple, size: 66),
          const SizedBox(height: 13),
          const Text('Flashcard session complete!', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 23, color: ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          InfoCard(child: Text('Remembered: ${remembered.length} / ${cards.length}\n'
            'Review again: ${reviewAgain.length}', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, height: 1.6))),
          const Text('This self-rating is for this session only. Backend flashcard tracking can be added separately.',
            style: TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 15),
          FilledButton(onPressed: () => setState(() {
            index = 0; revealed = false; complete = false;
            remembered.clear(); reviewAgain.clear();
          }), child: const Text('Study again')),
        ])));
      final card = cards[index];
      return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 570),
        child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
          const SizedBox(height: 5),
          Text('Card ${index + 1} of ${cards.length}  •  Tap the card to flip',
            style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 13),
          LinearProgressIndicator(value: index / cards.length, minHeight: 8,
            borderRadius: BorderRadius.circular(12), color: mint),
          const SizedBox(height: 20),
          Expanded(child: Card(child: InkWell(onTap: () => setState(() => revealed = !revealed),
            borderRadius: BorderRadius.circular(22),
            child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(25),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(revealed ? 'ANSWER' : 'QUESTION', style: const TextStyle(
                  color: purple, letterSpacing: 1.3, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Text(revealed ? card.back : card.front, textAlign: TextAlign.center,
                  style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 21)),
              ])))))),
          const SizedBox(height: 13),
          if (!revealed) FilledButton.icon(onPressed: () => setState(() => revealed = true),
            icon: const Icon(Icons.visibility_outlined), label: const Text('Reveal answer'))
          else ...[
            const Text('Did you remember the answer?', style: TextStyle(color: ink,
              fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => rate(cards, false),
                child: const Text('Review again'))),
              const SizedBox(width: 9),
              Expanded(child: FilledButton(onPressed: () => rate(cards, true),
                child: const Text('I knew it!'))),
            ]),
          ],
          TextButton(onPressed: index == 0 ? null : () => setState(() {
            index--; revealed = false;
          }), child: const Text('Previous card')),
        ]))));
    }),
  );
}

class VoiceScreen extends StatefulWidget {
  final AppController c;
  final Topic topic;
  const VoiceScreen({super.key, required this.c, required this.topic});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final AudioRecorder recorder = AudioRecorder();
  final TextEditingController answer = TextEditingController();
  bool recording = false, followUpRecording = false, loading = false;
  String? error, path;
  VoiceFeedback? feedback;

  @override
  void dispose() {
    answer.dispose();
    unawaited(recorder.dispose());
    super.dispose();
  }

  Future<void> toggleRecord() async {
    if (loading || kIsWeb) return;
    setState(() { loading = true; error = null; });
    try {
      if (!recording) {
        if (!await recorder.hasPermission()) throw Exception('Microphone permission denied');
        final temp = await getTemporaryDirectory();
        path = '${temp.path}/exam_pulse_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await recorder.start(const RecordConfig(), path: path!);
        if (mounted) setState(() => recording = true);
      } else {
        final recordedPath = await recorder.stop();
        if (mounted) setState(() => recording = false);
        if (recordedPath == null) throw Exception('No audio was recorded');
        try {
          final response = await widget.c.analyzeVoice(widget.topic.id, recordedPath);
          if (mounted) setState(() => feedback = response);
        } finally {
          final file = File(recordedPath);
          if (await file.exists()) await file.delete();
        }
      }
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> submitFollowUp() async {
    if (feedback == null || answer.text.trim().isEmpty) return;
    setState(() { loading = true; error = null; });
    try {
      final result = await widget.c.followUp(feedback!.id, answer.text.trim());
      if (mounted) setState(() { feedback = result; answer.clear(); });
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> toggleFollowUpRecording() async {
    if (loading || recording || kIsWeb || feedback == null) return;
    setState(() { loading = true; error = null; });
    try {
      if (!followUpRecording) {
        if (!await recorder.hasPermission()) throw Exception('Microphone permission denied');
        final temp = await getTemporaryDirectory();
        path = '${temp.path}/exam_pulse_followup_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await recorder.start(const RecordConfig(), path: path!);
        if (mounted) setState(() => followUpRecording = true);
      } else {
        final recordedPath = await recorder.stop();
        if (mounted) setState(() => followUpRecording = false);
        if (recordedPath == null) throw Exception('No follow-up answer was recorded');
        try {
          final next = await widget.c.followUpAudio(feedback!.id, recordedPath);
          if (mounted) setState(() { feedback = next; answer.clear(); });
        } finally {
          final file = File(recordedPath);
          if (await file.exists()) await file.delete();
        }
      }
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Voice coach • ${widget.topic.title}')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Explain the topic in your own words. The AI can transcribe your speech, review the explanation and ask a follow-up question. Your audio is sent only after you stop recording.'),
      const SizedBox(height: 8),
      const Text('AI speech and confidence feedback are estimates, not definitive measures of knowledge or emotions.',
        style: TextStyle(color: Colors.black54, fontSize: 12)),
      const SizedBox(height: 18),
      if (widget.c.demo) const InfoCard(child: Text('Voice analysis requires your friend’s Node.js AI service. The sample mode does not pretend to analyze your recording.'))
      else if (kIsWeb) const InfoCard(child: Text('Voice recording is supported on Android and iOS in this project.'))
      else Center(child: FilledButton.icon(onPressed: loading ? null : toggleRecord,
        icon: Icon(recording ? Icons.stop : Icons.mic),
        label: Text(recording ? 'Stop and analyze' : 'Start recording'))),
      if (recording) const Center(child: Padding(padding: EdgeInsets.all(12),
        child: Text('Recording…', style: TextStyle(color: Colors.red)))),
      if (loading) const LinearProgressIndicator(),
      if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
      if (feedback != null) ...[
        const SectionTitle('Explanation transcript'),
        InfoCard(child: Text(feedback!.transcript)),
        const SectionTitle('AI analysis'),
        ...<String, double>{
          'Clarity': feedback!.clarity,
          'Fluency': feedback!.fluency,
          'Pronunciation': feedback!.pronunciation,
          'Concept understanding': feedback!.conceptual,
          'Confidence estimate': feedback!.confidence,
        }.entries.map((item) => InfoCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${item.key}: ${item.value.toStringAsFixed(0)} / 100'),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: (item.value / 100).clamp(0.0, 1.0)),
          ]))),
        InfoCard(child: Text(feedback!.feedback)),
        if (feedback!.followUpQuestion.isNotEmpty) ...[
          const SectionTitle('Follow-up question'),
          InfoCard(child: Text(feedback!.followUpQuestion)),
          TextField(controller: answer, minLines: 2, maxLines: 4,
            decoration: const InputDecoration(labelText: 'Your answer')),
          const SizedBox(height: 10),
          FilledButton(onPressed: loading || followUpRecording ? null : submitFollowUp,
            child: const Text('Send typed answer')),
          if (!kIsWeb) OutlinedButton.icon(onPressed: loading ? null : toggleFollowUpRecording,
            icon: Icon(followUpRecording ? Icons.stop_circle_outlined : Icons.mic_none),
            label: Text(followUpRecording ? 'Stop and analyse spoken answer' : 'Answer aloud instead')), 
        ],
      ],
    ]),
  );
}
