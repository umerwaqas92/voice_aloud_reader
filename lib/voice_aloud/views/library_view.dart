import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../state/providers.dart';
import '../va_tokens.dart';
import '../voice_aloud_tab.dart';
import '../widgets/animated_page_entrance.dart';
import '../widgets/lucide_svg_icon.dart';
import '../widgets/press_effect.dart';
import 'recents_view.dart';
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
            colors: [
              VAColors.gradientNightStart,
              VAColors.gradientNightMid,
              VAColors.gradientNightEnd,
            ],
          ),
        ),
        child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Library',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      PressEffect(
                        onTap: () => _showAddSheet(context, ref),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: VAColors.blue600,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4D2563EB),
                                blurRadius: 18,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: LucideSvgIcon(
                              'plus',
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 128),
                    children: [
                      PressEffect(
                        onTap:
                            () =>
                                ref
                                    .read(appControllerProvider.notifier)
                                    .setTab(VoiceAloudTab.settings),
                        child: const _CloudSyncBanner(),
                      ),
                      const SizedBox(height: 12),
                      PressEffect(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RecentsView(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: VAColors.cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: VAColors.glassBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Open Recents',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              LucideSvgIcon(
                                'arrow-right',
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      docs.when(
                        data: (items) =>
                            items.isEmpty
                                ? const _EmptyStateCard()
                                : const RecentPlaceholderNote(),
                        loading: () => const _LoadingStateCard(),
                        error: (e, _) => _ErrorStateCard(
                          message: e.toString(),
                          onRetry: () => ref.invalidate(
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
    ));
  }
}

class _CloudSyncBanner extends StatelessWidget {
  const _CloudSyncBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [VAColors.blue600, VAColors.indigo600],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Local Library',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap to open Settings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFBFDBFE),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x80F3F4F6)),
      ),
      child: const Text(
        'No documents yet.\nTap + to add one.',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: VAColors.gray700,
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x80F3F4F6)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x80F3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Failed to load documents',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: VAColors.gray600),
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
                leading: const LucideSvgIcon('camera'),
                title: const Text('Scan document'),
                onTap: () {
                  Navigator.of(context).pop();
                  ref
                      .read(appControllerProvider.notifier)
                      .setTab(VoiceAloudTab.scan);
                },
              ),
              ListTile(
                leading: const LucideSvgIcon('file-text'),
                title: const Text('Import .txt'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _importTxt(context, ref);
                },
              ),
              ListTile(
                leading: const LucideSvgIcon('type'),
                title: const Text('Paste text'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file')),
      );
    }
    return;
  }

  final content = utf8.decode(bytes, allowMalformed: true).trim();
  if (content.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File is empty')),
      );
    }
    return;
  }

  final title = file.name.replaceAll(RegExp(r'\\.txt$', caseSensitive: false), '');
  final doc = await ref.read(documentsControllerProvider.notifier).addFromText(
        title: title.isEmpty ? 'Imported text' : title,
        content: content,
        source: DocumentSource.importTxt,
      );
  ref.read(appControllerProvider.notifier).openDocument(doc.id);
}

Future<void> _pasteText(BuildContext context, WidgetRef ref) async {
  final titleController = TextEditingController();
  final textController = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Paste text'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Title (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(labelText: 'Text'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
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

  final doc = await ref.read(documentsControllerProvider.notifier).addFromText(
        title: titleController.text,
        content: content,
        source: DocumentSource.paste,
      );
  ref.read(appControllerProvider.notifier).openDocument(doc.id);
}
