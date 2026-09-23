import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import 'screens.dart';

/// In-app PDF reader. Local demo files and authenticated Node downloads use
/// the SAME reader. Reading progress is distinct from quiz mastery.
class MaterialReader extends StatefulWidget {
  final AppController c;
  final StudyMaterial material;
  const MaterialReader({super.key, required this.c, required this.material});
  @override
  State<MaterialReader> createState() => _MaterialReaderState();
}

class _MaterialReaderState extends State<MaterialReader> {
  PdfControllerPinch? _pdf;
  Uint8List? _bytes;
  String? _failure;
  bool _loading = true, _saving = false;
  int _page = 1, _pageCount = 0;
  final Set<int> _sentPages = {};

  @override
  void initState() {
    super.initState();
    widget.c.addListener(_refresh);
    _open();
  }
  void _refresh() { if (mounted) setState(() {}); }
  Future<void> _open() async {
    try {
      final bytes = await widget.c.repository.materialBytes(widget.material);
      if (bytes.isEmpty) throw Exception('The selected file is empty.');
      if (widget.material.type.toLowerCase() == 'pdf') {
        final document = await PdfDocument.openData(bytes);
        if (!mounted) { await document.close(); return; }
        _pageCount = document.pagesCount;
        _pdf = PdfControllerPinch(document: Future.value(document));
      }
      if (mounted) setState(() { _bytes = bytes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _failure = e.toString(); _loading = false; });
    }
  }

  void _pageChanged(int page) {
    if (!mounted || page <= 0 || page > _pageCount) return;
    setState(() => _page = page);
  }

  Future<void> _markPageStudied() async {
    if (_pageCount <= 0 || _saving) return;
    final pageToMark = _page;
    setState(() => _saving = true);
    // The learner explicitly marks a page as studied. Swiping alone NEVER
    // increases the study percentage. Duplicate marks are idempotent.
    try {
      await widget.c.markStudiedUnit(widget.material.topicId, pageToMark, _pageCount);
      if (!mounted) return;
      setState(() => _sentPages.add(pageToMark));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Page $pageToMark marked studied today.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save page progress: $error')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  void dispose() { widget.c.removeListener(_refresh); _pdf?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.c.topics.where((t) => t.id == widget.material.topicId);
    final topic = candidates.isEmpty ? null : candidates.first;
    return Scaffold(
      appBar: AppBar(title: Text(widget.material.title, overflow: TextOverflow.ellipsis),
        actions: [if (_pageCount > 0) Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Center(child: Text('$_page / $_pageCount')))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
        _failure != null ? Center(child: Padding(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.file_present_outlined, size: 54, color: purple),
            const SizedBox(height: 12), Text(_failure!, textAlign: TextAlign.center),
            const SizedBox(height: 14), FilledButton(onPressed: () {
              setState(() { _loading = true; _failure = null; }); _open();
            }, child: const Text('Try opening again')),
          ]))) : Column(children: [
        Container(color: pale, padding: const EdgeInsets.fromLTRB(18, 9, 18, 11),
          child: Row(children: [
            const Icon(Icons.menu_book_outlined, color: purple),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Today: ${topic?.todayPercent.round() ?? 0}% of this topic',
                style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
              Text('${topic?.todayUnits ?? 0} / ${topic?.totalUnits ?? _pageCount} ${topic?.unitLabel ?? 'pages'} marked studied today',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ])),
          ])),
        Expanded(child: widget.material.type.toLowerCase() == 'pdf' ?
          PdfViewPinch(controller: _pdf!,
            onPageChanged: _pageChanged,
            onDocumentError: (error) { if (mounted) setState(() => _failure = error.toString()); }) :
          SingleChildScrollView(padding: const EdgeInsets.all(22), child: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
              child: SelectableText(utf8.decode(_bytes!, allowMalformed: true),
                style: const TextStyle(fontSize: 17, height: 1.6))))),
        ),
        if (widget.material.type.toLowerCase() == 'pdf')
          SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: FilledButton.icon(onPressed: _saving || _sentPages.contains(_page) ? null : _markPageStudied,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(_sentPages.contains(_page) ? 'Page $_page studied today' :
                'Mark page $_page as studied')))),
        if (widget.material.type.toLowerCase() != 'pdf')
          SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(14),
            child: FilledButton.icon(onPressed: () async {
              try {
                await widget.c.markStudiedUnit(widget.material.topicId, 1, 1);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked this note as studied today.')));
              } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString()))); }
            }, icon: const Icon(Icons.check_circle_outline),
              label: const Text('I studied this note today')))),
      ]),
    );
  }
}
