import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/document.dart';
import '../state/providers.dart';
import '../va_tokens.dart';
import '../voice_aloud_tab.dart';
import '../widgets/animated_page_entrance.dart';
import '../widgets/press_effect.dart';
import '_recent_placeholder_note.dart';

class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentsControllerProvider);

    return AnimatedPageEntrance(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [VAColors.obsidian, VAColors.voidColor, VAColors.deep],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR COLLECTION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.5,
                                color: VAColors.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Library',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                                color: VAColors.cream,
                              ),
                            ),
                          ],
                        ),
                        PressEffect(
                          onTap: () => _showAddSheet(context, ref),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: VAColors.gold,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: VAColors.gold.withValues(alpha: 0.3),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                size: 24,
                                color: VAColors.obsidian,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 128),
                      children: [
                        _LuxurySyncBanner(),
                        const SizedBox(height: 24),
                        Text(
                          'RECENTLY READ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                            color: VAColors.muted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        docs.when(
                          data:
                              (items) =>
                                  items.isEmpty
                                      ? const _EmptyStateCard()
                                      : const RecentPlaceholderNote(),
                          loading: () => const _LoadingStateCard(),
                          error:
                              (e, _) => _ErrorStateCard(
                                message: e.toString(),
                                onRetry:
                                    () => ref.invalidate(
                                      documentsControllerProvider,
                                    ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LuxurySyncBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            VAColors.gold.withValues(alpha: 0.06),
            VAColors.gold.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: VAColors.gold.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'iCloud Sync Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: VAColors.goldBright,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Synced across iPad & Mac',
                  style: TextStyle(fontSize: 10, color: VAColors.muted),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: VAColors.gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.cloud_sync,
                size: 16,
                color: VAColors.goldBright,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VAColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VAColors.gold.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book, size: 48, color: VAColors.muted),
          const SizedBox(height: 12),
          Text(
            'No documents yet.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: VAColors.cream,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add one.',
            style: TextStyle(fontSize: 12, color: VAColors.muted),
          ),
        ],
      ),
    );
  }
}

class _LoadingStateCard extends StatelessWidget {
  const _LoadingStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: VAColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VAColors.gold.withValues(alpha: 0.1)),
      ),
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VAColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Failed to load documents',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: VAColors.muted),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: VAColors.panel,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: VAColors.gold),
                title: Text(
                  'Scan document',
                  style: TextStyle(color: VAColors.cream),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  ref
                      .read(appControllerProvider.notifier)
                      .setTab(VoiceAloudTab.scan);
                },
              ),
              ListTile(
                leading: Icon(Icons.description, color: VAColors.gold),
                title: Text(
                  'Import .txt',
                  style: TextStyle(color: VAColors.cream),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _importTxt(context, ref);
                },
              ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: VAColors.gold),
                title: Text(
                  'Import PDF',
                  style: TextStyle(color: VAColors.cream),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _importPdf(context, ref);
                },
              ),
              ListTile(
                leading: Icon(Icons.paste, color: VAColors.gold),
                title: Text(
                  'Paste text',
                  style: TextStyle(color: VAColors.cream),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pasteText(context, ref);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _importTxt(BuildContext context, WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['txt'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return;
  final file = result.files.single;

  final bytes = file.bytes;
  if (bytes == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not read file')));
    }
    return;
  }

  final content = utf8.decode(bytes, allowMalformed: true).trim();
  if (content.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File is empty')));
    }
    return;
  }

  final title = file.name.replaceAll(
    RegExp(r'\\.txt$', caseSensitive: false),
    '',
  );
  final doc = await ref
      .read(documentsControllerProvider.notifier)
      .addFromText(
        title: title.isEmpty ? 'Imported text' : title,
        content: content,
        source: DocumentSource.importTxt,
      );
  ref.read(appControllerProvider.notifier).openDocument(doc.id);
  Future.delayed(const Duration(milliseconds: 500), () {
    ref.read(playbackControllerProvider.notifier).play(doc, startOffset: 0);
  });
}

Future<void> _pasteText(BuildContext context, WidgetRef ref) async {
  final titleController = TextEditingController();
  final textController = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: VAColors.panel,
        title: Text('Paste text', style: TextStyle(color: VAColors.cream)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: VAColors.cream),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Title (optional)',
                  labelStyle: TextStyle(color: VAColors.muted),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                style: TextStyle(color: VAColors.cream),
                minLines: 6,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: 'Text',
                  labelStyle: TextStyle(color: VAColors.muted),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: VAColors.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;
  final content = textController.text.trim();
  if (content.isEmpty) return;

  final doc = await ref
      .read(documentsControllerProvider.notifier)
      .addFromText(
        title: titleController.text,
        content: content,
        source: DocumentSource.paste,
      );
  ref.read(appControllerProvider.notifier).openDocument(doc.id);
  Future.delayed(const Duration(milliseconds: 500), () {
    ref.read(playbackControllerProvider.notifier).play(doc, startOffset: 0);
  });
}

Future<void> _importPdf(BuildContext context, WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return;
  final file = result.files.single;
  final bytes = file.bytes;
  final path = file.path;
  Uint8List? data = bytes;
  if (data == null && path != null && path.isNotEmpty) {
    data = await File(path).readAsBytes();
  }
  if (data == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not read file')));
    }
    return;
  }

  try {
    final pdf = PdfDocument(inputBytes: data);
    final extracted = PdfTextExtractor(pdf).extractText();
    pdf.dispose();
    final content = _normalizePdfText(extracted);
    if (content.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PDF has no text')));
      }
      return;
    }

    final title = file.name.replaceAll(
      RegExp(r'\\.pdf$', caseSensitive: false),
      '',
    );
    final newDoc = await ref
        .read(documentsControllerProvider.notifier)
        .addFromText(
          title: title.isEmpty ? 'Imported PDF' : title,
          content: content,
          source: DocumentSource.importPdf,
        );
    ref.read(appControllerProvider.notifier).openDocument(newDoc.id);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (context.mounted) {
      final docs = ref.read(documentsControllerProvider).valueOrNull ?? [];
      final doc = docs.where((d) => d.id == newDoc.id).firstOrNull;
      if (doc != null) {
        await ref
            .read(playbackControllerProvider.notifier)
            .play(doc, startOffset: 0);
      }
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to read PDF')));
    }
  }
}

String _normalizePdfText(String raw) {
  var text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
  text = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  final lines = text.split('\n');
  final out = StringBuffer();
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) {
      if (i > 0 && i < lines.length - 1 && out.isNotEmpty) {
        out.write('\n');
      }
      continue;
    }
    if (out.isNotEmpty && !out.toString().endsWith('\n')) {
      out.write(' ');
    }
    out.write(line);
  }
  return out.toString().trim();
}
