import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import 'practice_flow.dart';
import 'material_reader.dart';

const ink = Color(0xFF182141);
const purple = Color(0xFF6554DF);
const mint = Color(0xFF11AA96);
const pale = Color(0xFFF1F0FF);

String dateText(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

void errorToast(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
}

class SignInScreen extends StatefulWidget {
  final AppController controller;
  const SignInScreen({super.key, required this.controller});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final keyForm = GlobalKey<FormState>();
  final studentName = TextEditingController();
  final className = TextEditingController();
  final branch = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  String year = '1';
  bool isRegister = false, hidden = true;

  @override
  void dispose() {
    studentName.dispose(); className.dispose(); branch.dispose();
    email.dispose(); password.dispose(); confirmPassword.dispose();
    super.dispose();
  }
  String? requiredField(String? text) => text == null || text.trim().isEmpty ? 'Please fill in this field' : null;
  String? validateEmail(String? value) => value == null ||
    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim()) ?
    'Enter a valid email address' : null;

  Future<void> submit() async {
    if (!keyForm.currentState!.validate()) return;
    final c = widget.controller;
    if (isRegister) {
      await c.register(StudentRegistration(name: studentName.text.trim(),
        className: className.text.trim(), year: year,
        branch: branch.text.trim(), email: email.text.trim(), password: password.text));
      if (!mounted) return;
      if (c.registrationComplete && c.error == null) {
        setState(() { isRegister = false; password.clear(); confirmPassword.clear(); });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Registration successful. Please log in with your email and password.')));
      }
    } else {
      c.clearRegistrationNotice();
      await c.signIn(email.text.trim(), password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 490),
      child: ListView(padding: const EdgeInsets.all(22), children: [
        Container(height: 170, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(29),
            gradient: const LinearGradient(begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3927A2), Color(0xFF7967E7), Color(0xFF49C9C2)])),
          child: Stack(children: [
            const Positioned(right: 0, top: 2, child: Icon(Icons.auto_stories_rounded,
              color: Colors.white24, size: 112)),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 33),
              const SizedBox(height: 5),
              const Text('EXAM PULSE', style: TextStyle(color: Colors.white,
                fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 3),
              Text(isRegister ? 'A study space designed around you' :
                'Your own AI-powered study companion',
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            ]),
          ])),
        const SizedBox(height: 22),
        Text(isRegister ? 'Create student account' : 'Welcome back!',
          style: const TextStyle(color: ink, fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(isRegister ? 'Your class and branch personalise your study library.' :
          'Log in to continue your own study plan.',
          style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 19),
        SegmentedButton<bool>(showSelectedIcon: false,
          segments: const [ButtonSegment(value: false, label: Text('Student login')),
            ButtonSegment(value: true, label: Text('Registration'))],
          selected: {isRegister}, onSelectionChanged: c.busy ? null : (selection) {
            setState(() { isRegister = selection.first; password.clear(); confirmPassword.clear(); });
            c.clearRegistrationNotice();
          }),
        const SizedBox(height: 17),
        Form(key: keyForm, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (isRegister) ...[
            TextFormField(controller: studentName, validator: (value) =>
              value == null || value.trim().length < 2 ? 'Enter your full name' : null,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Student full name',
                prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 11),
            TextFormField(controller: className, validator: requiredField,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Class / course (e.g. BTech, BSc, Plus Two)',
                prefixIcon: Icon(Icons.school_outlined))),
            const SizedBox(height: 11),
            DropdownButtonFormField<String>(value: year,
              decoration: const InputDecoration(labelText: 'Study year',
                prefixIcon: Icon(Icons.calendar_month_outlined)),
              items: const [
                DropdownMenuItem(value: '1', child: Text('1st year')),
                DropdownMenuItem(value: '2', child: Text('2nd year')),
                DropdownMenuItem(value: '3', child: Text('3rd year')),
                DropdownMenuItem(value: '4', child: Text('4th year')),
                DropdownMenuItem(value: '5', child: Text('5th year')),
                DropdownMenuItem(value: 'other', child: Text('Other / not applicable')),
              ], onChanged: (value) => setState(() => year = value ?? '1')),
            const SizedBox(height: 11),
            TextFormField(controller: branch, validator: requiredField,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Branch / stream (e.g. CSE, Commerce, Biology)',
                prefixIcon: Icon(Icons.account_tree_outlined))),
            const SizedBox(height: 11),
          ],
          TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email], validator: validateEmail,
            decoration: const InputDecoration(labelText: 'Student email',
              prefixIcon: Icon(Icons.alternate_email))),
          const SizedBox(height: 11),
          TextFormField(controller: password, obscureText: hidden,
            autofillHints: [isRegister ? AutofillHints.newPassword : AutofillHints.password],
            validator: (value) => value == null || value.length < 8 ?
              'Password must have at least 8 characters' : null,
            decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(tooltip: hidden ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => hidden = !hidden),
                icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
          if (isRegister) ...[
            const SizedBox(height: 11),
            TextFormField(controller: confirmPassword, obscureText: hidden,
              validator: (value) => value != password.text ? 'Passwords do not match' : requiredField(value),
              decoration: const InputDecoration(labelText: 'Confirm password',
                prefixIcon: Icon(Icons.verified_user_outlined))),
          ],
          const SizedBox(height: 19),
          FilledButton.icon(onPressed: c.busy ? null : submit,
            icon: Icon(isRegister ? Icons.person_add_alt_1 : Icons.login),
            label: Text(isRegister ? 'Register student' : 'Log in to my study space')),
        ])),
        if (c.busy) const Padding(padding: EdgeInsets.only(top: 13),
          child: LinearProgressIndicator()),
        if (c.error != null) Padding(padding: const EdgeInsets.only(top: 13),
          child: Text(c.error!, style: const TextStyle(color: Colors.red))),
        if (!isRegister && c.registrationComplete) const Padding(
          padding: EdgeInsets.only(top: 13), child: Text('Account created! Log in to open your home screen.',
            style: TextStyle(color: mint, fontWeight: FontWeight.w700))),
        if (c.demo && !isRegister) ...[
          const SizedBox(height: 18),
        ],
      ])))));
  }
}

class MainShell extends StatefulWidget {
  final AppController controller;
  const MainShell({super.key, required this.controller});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selected = 0;
  void go(int i) => setState(() => selected = i);

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final pages = [HomePage(c, openLibrary: () => go(1), openPractice: () => go(2), openRevision: () => go(3)),
      LibraryPage(c), PracticePage(c), RevisionPage(c), ProgressPage(c)];
    return Scaffold(
      appBar: AppBar(title: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bolt_rounded, color: purple), SizedBox(width: 5),
        Text('EXAM PULSE', style: TextStyle(color: ink, fontWeight: FontWeight.w900, letterSpacing: .5)),
      ]), actions: [
        if (c.demo) const Padding(padding: EdgeInsets.only(right: 4), child: Center(
          child: Chip(label: Text('SAMPLE', style: TextStyle(fontSize: 10))))),
        IconButton(tooltip: 'Refresh', onPressed: c.busy ? null : c.refresh,
          icon: const Icon(Icons.refresh_rounded)),
        PopupMenuButton<String>(tooltip: 'Account', icon: const CircleAvatar(
          backgroundColor: pale, child: Icon(Icons.person_outline, color: purple)),
          onSelected: (value) { if (value == 'logout') c.signOut(); },
          itemBuilder: (_) => [
            PopupMenuItem(enabled: false, child: Text('${c.student?.name ?? 'Student'}\n${c.student?.className ?? ''} • Year ${c.student?.year ?? ''}\n${c.student?.branch ?? ''}')),
            const PopupMenuItem(value: 'logout', child: Text('Log out')),
          ]),
      ]),
      body: Column(children: [
        if (c.busy) const LinearProgressIndicator(minHeight: 2),
        if (c.error != null) MaterialBanner(content: Text(c.error!),
          actions: [TextButton(onPressed: c.refresh, child: const Text('Retry'))]),
        Expanded(child: SafeArea(child: IndexedStack(index: selected, children: pages))),
      ]),
      bottomNavigationBar: NavigationBar(height: 74, selectedIndex: selected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: go, destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.event_repeat_outlined), selectedIcon: Icon(Icons.event_repeat), label: 'Revise'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progress'),
        ]),
    );
  }
}

class PageContent extends StatelessWidget {
  final List<Widget> children;
  const PageContent({super.key, required this.children});
  @override
  Widget build(BuildContext context) => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 850),
    child: ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 35), children: children)));
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 22, bottom: 11),
    child: Text(text, style: const TextStyle(fontSize: 19, color: ink, fontWeight: FontWeight.w800)));
}

class InfoCard extends StatelessWidget {
  final Widget child;
  const InfoCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10),
    child: Padding(padding: const EdgeInsets.all(17), child: child));
}

class ProgressRing extends StatelessWidget {
  final double value;
  final String label;
  const ProgressRing({super.key, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => SizedBox(width: 126, height: 126, child: Stack(
    alignment: Alignment.center, children: [
      SizedBox.expand(child: CircularProgressIndicator(value: (value / 100).clamp(0.0, 1.0),
        strokeWidth: 11, strokeCap: StrokeCap.round, color: const Color(0xFFB6FFE7),
        backgroundColor: Colors.white24)),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${value.clamp(0, 100).round()}%', style: const TextStyle(
          color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    ]));
}

class HomePage extends StatelessWidget {
  final AppController c;
  final VoidCallback openLibrary, openPractice, openRevision;
  const HomePage(this.c, {super.key, required this.openLibrary,
    required this.openPractice, required this.openRevision});

  @override
  Widget build(BuildContext context) {
    final d = c.dashboard;
    if (d == null) return const Center(child: CircularProgressIndicator());
    final due = c.revisions.where((r) => !r.completed &&
      !r.dueAt.isAfter(DateTime.now())).length;
    final first = c.topics.isEmpty ? null : c.topics.first;
    final student = c.student;
    return PageContent(children: [
      Text('Good to see you, ${student?.name.split(' ').first ?? 'Student'} 👋',
        style: const TextStyle(fontSize: 24, color: ink, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text('${student?.className ?? ''} • Year ${student?.year ?? ''} • ${student?.branch ?? ''}',
        style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 17),
      Container(padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(27),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF3A2AA8), Color(0xFF6C5AD6), Color(0xFF26A8A1)])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TODAY • TOPIC STUDY', style: TextStyle(color: Colors.white70,
            letterSpacing: 1.1, fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          if (first == null) ...[
            const Icon(Icons.auto_stories_outlined, size: 48, color: Colors.white),
            const SizedBox(height: 10),
            const Text('Your study starts with your material',
              style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            const Text('No subjects or PDFs are preloaded. Upload a PDF or note from YOUR stream to create a topic.',
              style: TextStyle(color: Colors.white70)),
          ] else ...[
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 17,
              runSpacing: 12, children: [
              ProgressRing(value: first.todayPercent, label: 'today'),
              SizedBox(width: 205, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(first.title, style: const TextStyle(color: Colors.white,
                  fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(first.totalUnits == 0 ? 'Open your PDF to start tracking' :
                  '${first.todayUnits} of ${first.totalUnits} ${first.unitLabel} marked studied today',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ])),
            ]),
            const SizedBox(height: 12),
            const Text('This percentage shows pages you marked studied in this topic TODAY, not your quiz score or overall learning ability.',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
          const SizedBox(height: 17),
          FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF4335B5)), onPressed: openLibrary,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(first == null ? 'Upload my first PDF' : 'Open my study library')),
        ])),
      const SizedBox(height: 13),
      Row(children: [
        Expanded(child: _StatCard(icon: Icons.task_alt_outlined,
          title: '${d.completedAssessments}', subtitle: 'Practice sessions', tint: mint)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.auto_stories_outlined,
          title: '${c.materials.length}', subtitle: 'My materials', tint: purple)),
      ]),
      const SectionTitle('Today’s topic progress'),
      if (c.topics.isEmpty) InfoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [const Text('Nothing to track yet', style: TextStyle(
          color: ink, fontWeight: FontWeight.w800)), const SizedBox(height: 7),
          const Text('Add a PDF. Open a PDF and tap “Mark page as studied” to update that topic’s percentage.'),
          const SizedBox(height: 10),
          TextButton.icon(onPressed: openLibrary, icon: const Icon(Icons.add),
            label: const Text('Add study material'))])),
      ...c.topics.map((topic) => InfoCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(topic.title, style: const TextStyle(color: ink,
            fontWeight: FontWeight.w800, fontSize: 16))),
          Text('${topic.todayPercent.round()}%', style: const TextStyle(color: purple,
            fontWeight: FontWeight.w900, fontSize: 22)),
        ]),
        const SizedBox(height: 7),
        LinearProgressIndicator(value: topic.todayPercent / 100, color: mint,
          backgroundColor: const Color(0xFFEBEDF6), minHeight: 8,
          borderRadius: BorderRadius.circular(9)),
        const SizedBox(height: 7),
        Text(topic.totalUnits == 0 ? 'Page total will appear after opening this material' :
          '${topic.todayUnits}/${topic.totalUnits} ${topic.unitLabel} marked studied today • resets each new day',
          style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ]))),
      const SectionTitle('Your study plan today'),
      ...d.dailyPlan.map((item) => InfoCard(child: Row(children: [
        const CircleAvatar(backgroundColor: pale, child: Icon(Icons.checklist, color: purple)),
        const SizedBox(width: 10), Expanded(child: Text(item)),
      ]))),
      const SectionTitle('Your AI learning toolkit'),
      InfoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Turn YOUR notes into practice', style: TextStyle(
          color: ink, fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 9),
        const Text('AI quizzes & mock tests • Spoken explanations & follow-ups • Weak-topic retests • Personalised revision'),
        const SizedBox(height: 8),
        Text(c.demo ? 'AI is not simulated in offline mode. Connect the Node.js backend to enable personalised questions and voice feedback.' :
          'AI tools use your uploaded materials and the connected Node.js backend.',
          style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 11),
        OutlinedButton.icon(onPressed: openPractice,
          icon: const Icon(Icons.auto_awesome_outlined), label: const Text('Open AI practice')),
      ])),
      InfoCard(child: Row(children: [
        const CircleAvatar(backgroundColor: Color(0xFFFFF2DE),
          child: Icon(Icons.notifications_active_outlined, color: Color(0xFFC68221))),
        const SizedBox(width: 12),
        Expanded(child: Text(due == 0 ? 'No revisions due right now.' :
          '$due topic${due == 1 ? '' : 's'} due for revision')),
        TextButton(onPressed: openRevision, child: const Text('Revise')),
      ])),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color tint;
  const _StatCard({required this.icon, required this.title, required this.subtitle, required this.tint});
  @override
  Widget build(BuildContext context) => InfoCard(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: tint), const SizedBox(height: 9),
      Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: ink)),
      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    ]));
}

class LibraryPage extends StatefulWidget {
  final AppController c;
  const LibraryPage(this.c, {super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom,
        allowedExtensions: const ['pdf', 'txt', 'md'], withData: true);
      if (result == null || result.files.isEmpty || !mounted) return;
      final file = result.files.single;
      String topicName = file.name.replaceAll(
        RegExp(r'\.(pdf|txt|md)$', caseSensitive: false), '');
      final label = await showDialog<String>(context: context, builder: (dialogContext) =>
        AlertDialog(title: const Text('Name this study topic'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(file.name, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            TextFormField(initialValue: topicName, autofocus: true,
              onChanged: (value) => topicName = value,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Topic name',
                hintText: 'e.g. Unit 1: Data Structures')),
          ]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
            FilledButton(onPressed: () {
              if (topicName.trim().isEmpty) return;
              Navigator.pop(dialogContext, topicName.trim());
            }, child: const Text('Add to my library'))]));
      if (label == null || !mounted) return;
      final material = await widget.c.upload(file, label);
      if (!mounted) return;
      if (widget.c.error != null) { errorToast(context, widget.c.error!); return; }
      if (material != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.c.demo ?
          'Saved to your private demo library. Open it to begin studying.' :
          'Uploaded. Your AI study material is being prepared.')));
        if (material.status == 'ready') openMaterial(material);
      }
    } catch (e) { if (mounted) errorToast(context, e); }
  }

  void openMaterial(StudyMaterial material) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => MaterialReader(c: widget.c, material: material)));

  @override
  Widget build(BuildContext context) => PageContent(children: [
    const Text('My study library', style: TextStyle(color: ink,
      fontSize: 25, fontWeight: FontWeight.w900)),
    const SizedBox(height: 6),
    Text('Your own materials • ${widget.c.student?.branch ?? 'Your stream'}',
      style: const TextStyle(color: Colors.black54)),
    const SizedBox(height: 18),
    Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(colors: [Color(0xFFEAE7FF), Color(0xFFE3FAF5)])),
      child: Column(children: [
        const Icon(Icons.upload_file_rounded, color: purple, size: 46),
        const SizedBox(height: 9),
        const Text('Upload and study YOUR notes', style: TextStyle(
          color: ink, fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Read PDFs inside the app, mark pages studied, then practise with AI.',
          textAlign: TextAlign.center),
        const SizedBox(height: 5),
        const Text('PDF, TXT or MD • Up to 20 MB',
          style: TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: widget.c.busy ? null : pickFile,
          icon: const Icon(Icons.add_circle_outline), label: const Text('Upload material')),
      ])),
    if (widget.c.demo) const Padding(padding: EdgeInsets.only(top: 11),
      child: Text('Offline mode saves YOUR documents privately on this device. AI-generated questions and voice feedback require the Node.js backend.',
        style: TextStyle(color: Colors.black54, fontSize: 12))),
    SectionTitle('${widget.c.materials.length} study materials'),
    if (widget.c.materials.isEmpty) const InfoCard(child: Column(children: [
      Icon(Icons.folder_open_outlined, color: purple, size: 42),
      SizedBox(height: 8),
      Text('Your library is empty. Nobody else’s materials will appear here.',
        textAlign: TextAlign.center),
    ])),
    ...widget.c.materials.map((material) => InfoCard(child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: material.status == 'failed' ? null : () => openMaterial(material),
      child: Row(children: [
        CircleAvatar(backgroundColor: pale,
          child: Icon(material.type == 'pdf' ? Icons.picture_as_pdf_outlined :
            Icons.notes_outlined, color: purple)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(material.title, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${material.type.toUpperCase()} • ${dateText(material.uploadedAt)}',
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(material.status == 'processing' ? 'AI processing • tap to read original' :
            material.status == 'failed' ? 'Processing failed • retry from your backend' :
            'Tap to OPEN and study', style: const TextStyle(color: purple, fontSize: 12)),
        ])),
        const Icon(Icons.chevron_right, color: purple),
      ])))),
    if (widget.c.materials.any((m) => m.status == 'processing'))
      OutlinedButton.icon(onPressed: widget.c.busy ? null : widget.c.refresh,
        icon: const Icon(Icons.refresh), label: const Text('Refresh AI processing status')),
  ]);
}

class PracticePage extends StatefulWidget {
  final AppController c;
  const PracticePage(this.c, {super.key});
  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  String query = '';
  void launch(BuildContext context, Topic topic, String mode) {
    final screen = switch (mode) {
      'quiz' || 'mock' => QuizScreen(c: widget.c, topic: topic, mode: mode),
      'flashcards' => FlashcardsScreen(c: widget.c, topic: topic),
      _ => VoiceScreen(c: widget.c, topic: topic),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final topics = widget.c.topics.where((topic) =>
      topic.title.toLowerCase().contains(query.toLowerCase())).toList();
    return PageContent(children: [
      const Text('Practice zone', style: TextStyle(color: ink, fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      const Text('AI can turn your uploaded notes into quizzes, mock tests, flashcards and spoken-answer coaching.'),
      const SizedBox(height: 10),
      InfoCard(child: Row(children: [const Icon(Icons.auto_awesome_rounded, color: purple, size: 30),
        const SizedBox(width: 11), Expanded(child: Text(widget.c.demo ?
          'Offline mode: only the optional example quiz is available. Connect Node.js for personalised AI practice from your materials.' :
          'Choose a topic to generate an AI assessment from your own uploaded material.',
          style: const TextStyle(color: ink)))])),
      const SizedBox(height: 17),
      TextField(onChanged: (text) => setState(() => query = text),
        decoration: const InputDecoration(hintText: 'Search a topic', prefixIcon: Icon(Icons.search))),
      SectionTitle('${topics.length} topics available'),
      if (topics.isEmpty) const InfoCard(child: Text('No topics to practise yet. Upload a material from your own class or branch first. Once your Node.js AI service processes it, practice questions will be personalised to YOUR notes.')),
      ...topics.map((topic) => InfoCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(backgroundColor: pale, child: Icon(Icons.menu_book_outlined, color: purple)),
            const SizedBox(width: 12),
            Expanded(child: Text(topic.title, style: const TextStyle(fontSize: 18,
              color: ink, fontWeight: FontWeight.w800))),
            Text('${topic.mastery.round()}%', style: const TextStyle(color: purple,
              fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          Text('Studied TODAY: ${topic.todayPercent.round()}% • ${topic.todayUnits}/${topic.totalUnits} ${topic.unitLabel}',
            style: const TextStyle(color: mint, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 13),
          LinearProgressIndicator(value: (topic.mastery / 100).clamp(0.0, 1.0),
            minHeight: 7, borderRadius: BorderRadius.circular(10), color: mint),
          const SizedBox(height: 8),
          Text('Mastery ${topic.mastery.round()}%  •  Confidence ${topic.confidence.round()}%',
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 8),
          if (widget.c.demo) const Text('Connect Node.js to create AI questions from this material. The buttons below will show a clear connection message in offline mode.',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 9),
          if (widget.c.materials.any((m) => m.id == topic.materialId))
            TextButton.icon(onPressed: () {
              final material = widget.c.materials.firstWhere((m) => m.id == topic.materialId);
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
                MaterialReader(c: widget.c, material: material)));
            }, icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Open this topic’s study material')),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(onPressed: () => launch(context, topic, 'quiz'),
              icon: const Icon(Icons.play_arrow), label: const Text('Practice quiz')),
            OutlinedButton.icon(onPressed: () => launch(context, topic, 'mock'),
              icon: const Icon(Icons.assignment_outlined), label: const Text('Mock test')),
            OutlinedButton.icon(onPressed: () => launch(context, topic, 'flashcards'),
              icon: const Icon(Icons.style_outlined), label: const Text('Flashcards')),
            OutlinedButton.icon(onPressed: () => launch(context, topic, 'voice'),
              icon: const Icon(Icons.mic_none), label: const Text('Voice coach')),
          ]),
        ]))),
      if (widget.c.demo) InfoCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Want to try an example quiz?', style: TextStyle(color: ink,
          fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Optional sample only • not based on your uploaded material and not added to your library.',
          style: TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: () => launch(context,
          const Topic('sample:t1', 'Example: Cell Biology', 0, 0, null), 'quiz'),
          icon: const Icon(Icons.science_outlined), label: const Text('Try sample questions')),
      ])),
    ]);
  }
}

class RevisionPage extends StatelessWidget {
  final AppController c;
  const RevisionPage(this.c, {super.key});
  @override
  Widget build(BuildContext context) {
    final remaining = c.revisions.where((r) => !r.completed).length;
    return PageContent(children: [
      const Text('Revision planner', style: TextStyle(color: ink, fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      const Text('Revisit weaker topics and check off completed reviews.'),
      const SizedBox(height: 18),
      InfoCard(child: Row(children: [
        const Icon(Icons.calendar_month_outlined, color: purple, size: 38),
        const SizedBox(width: 12),
        Expanded(child: Text('$remaining revision${remaining == 1 ? '' : 's'} remaining',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink))),
      ])),
      if (c.revisions.isEmpty) const InfoCard(child: Text('No revisions scheduled yet. Start a practice session.')),
      ...c.revisions.map((r) => InfoCard(child: Row(children: [
        Icon(r.completed ? Icons.check_circle : Icons.schedule,
          color: r.completed ? mint : purple, size: 27),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.topicTitle, style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(r.reason, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(dateText(r.dueAt), style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ])),
        r.completed ? const Text('Done', style: TextStyle(color: mint)) :
          TextButton(onPressed: c.busy ? null : () async {
            await c.markRevision(r.id);
            if (context.mounted && c.error != null) errorToast(context, c.error!);
          }, child: const Text('Mark done')),
      ]))),
      if (c.demo) const Text('Personalised adaptive revision and reminder delivery need the Node.js service.',
        style: TextStyle(color: Colors.black54, fontSize: 12)),
    ]);
  }
}

class ProgressPage extends StatelessWidget {
  final AppController c;
  const ProgressPage(this.c, {super.key});
  @override
  Widget build(BuildContext context) {
    final d = c.dashboard;
    return PageContent(children: [
      const Text('Your progress', style: TextStyle(color: ink, fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      const Text('Understand your strengths and decide what to study next.'),
      const SizedBox(height: 15),
      if (d != null) InfoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Today’s material coverage • by topic',
          style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 8),
        Text('${d.completedAssessments} practice sessions • ${d.totalMaterials} personal materials',
          style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        const Text('Each topic has its own percentage: PDF pages you marked studied TODAY / total pages in that topic. Practice mastery is shown separately below.',
          style: TextStyle(color: Colors.black54, fontSize: 12)),
      ])),
      ...c.topics.map((t) => InfoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [Row(children: [Expanded(child: Text(t.title,
          style: const TextStyle(color: ink, fontWeight: FontWeight.w800))),
          Text('${t.todayPercent.round()}%', style: const TextStyle(color: mint,
            fontWeight: FontWeight.w900))]),
          const SizedBox(height: 8), LinearProgressIndicator(value: t.todayPercent / 100,
            color: mint, minHeight: 7, borderRadius: BorderRadius.circular(12)),
          const SizedBox(height: 6),
          Text('${t.todayUnits}/${t.totalUnits} ${t.unitLabel} marked studied today',
            style: const TextStyle(color: Colors.black54, fontSize: 12))]))) ,
      SectionTitle('Topic mastery'),
      if (c.topics.isEmpty) const InfoCard(child: Text('Add your own PDF or note to see topic-level progress.')),
      ...c.topics.map((t) => InfoCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, style: const TextStyle(fontSize: 17, color: ink, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(c.demo ? 'Concept mastery: AI backend not connected' :
            'Concept mastery from assessments: ${t.mastery.round()}%'),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: (t.mastery / 100).clamp(0.0, 1.0),
            color: purple, minHeight: 7, borderRadius: BorderRadius.circular(12)),
          const SizedBox(height: 10),
          Text(c.demo ? 'Learning confidence: AI backend not connected' :
            'Learning confidence estimate: ${t.confidence.round()}%'),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: (t.confidence / 100).clamp(0.0, 1.0),
            color: mint, minHeight: 7, borderRadius: BorderRadius.circular(12)),
          if (t.nextRevisionAt != null) Padding(padding: const EdgeInsets.only(top: 10),
            child: Text('Next revision: ${dateText(t.nextRevisionAt!)}',
              style: const TextStyle(color: Colors.black54, fontSize: 12))),
        ]))),
      SectionTitle('Your achievements'),
      if (d != null && d.badges.isEmpty) const InfoCard(child: Text('Complete your first practice to earn a badge.')),
      if (d != null) Wrap(spacing: 8, runSpacing: 8,
        children: d.badges.map((b) => Chip(avatar: const Icon(Icons.workspace_premium, color: purple),
          label: Text(b))).toList()),
      const SizedBox(height: 18),
      const Text('Study progress is an educational estimate, not a measurement of personal ability.',
        style: TextStyle(color: Colors.black54, fontSize: 12)),
    ]);
  }
}
