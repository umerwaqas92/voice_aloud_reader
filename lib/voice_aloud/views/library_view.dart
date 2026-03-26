import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../state/providers.dart';
import '../va_tokens.dart';
import '../voice_aloud_tab.dart';
import '../widgets/lucide_svg_icon.dart';

class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentsControllerProvider);

    return ColoredBox(
      color: VAColors.libraryBackground,
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                          color: VAColors.gray900,
                        ),
                      ),
                      GestureDetector(
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
                      GestureDetector(
                        onTap:
                            () =>
                                ref
                                    .read(appControllerProvider.notifier)
                                    .setTab(VoiceAloudTab.settings),
                        child: const _CloudSyncBanner(),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(8, 0, 8, 16),
                        child: Text(
                          'Recent Documents',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                            color: VAColors.gray400,
                          ),
                        ),
                      ),
                      ...docs.when(
                        data: (items) {
                          if (items.isEmpty) {
                            return const [_EmptyStateCard()];
                          }

                          return [
                            for (final entry in items.indexed) ...[
                              _DocumentCard(
                                document: entry.$2,
                                index: entry.$1,
                                onTap: () async {
                                  await ref
                                      .read(
                                        documentsControllerProvider.notifier,
                                      )
                                      .markOpened(entry.$2.id);
                                  ref
                                      .read(appControllerProvider.notifier)
                                      .openDocument(entry.$2.id);
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ];
                        },
                        loading:
                            () => const [
                              _LoadingStateCard(),
                              SizedBox(height: 16),
                              _LoadingStateCard(),
                            ],
                        error:
                            (e, _) => [
                              _ErrorStateCard(
                                message: e.toString(),
                                onRetry:
                                    () => ref.invalidate(
                                      documentsControllerProvider,
                                    ),
                              ),
                            ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: LucideSvgIcon(
                'zap_filled',
                size: 20,
                color: VAColors.yellow300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.index,
    required this.onTap,
  });

  final Document document;
  final int index;
  final VoidCallback onTap;

  ({Color bg, Color fg}) _coverColors() {
    const palette = [
      (bg: VAColors.orange100, fg: VAColors.orange600),
      (bg: VAColors.blue100, fg: VAColors.blue600),
      (bg: VAColors.emerald100, fg: VAColors.emerald600),
      (bg: VAColors.purple100, fg: VAColors.purple600),
    ];
    return palette[index % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _coverColors();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x80F3F4F6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 64,
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  document.title.isEmpty ? '' : document.title[0],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colors.fg,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: VAColors.gray800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    document.author.isEmpty ? ' ' : document.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VAColors.gray400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 6,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(color: VAColors.gray100),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: document.progress,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: VAColors.blue500,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
