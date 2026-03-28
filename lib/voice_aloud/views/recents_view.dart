import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../state/providers.dart';
import '../va_tokens.dart';
import '../widgets/animated_page_entrance.dart';
import '../widgets/lucide_svg_icon.dart';
import '../widgets/press_effect.dart';

class RecentsView extends ConsumerWidget {
  const RecentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentsControllerProvider);

    return AnimatedPageEntrance(
      child: Scaffold(
        backgroundColor: VAColors.bgDark,
        appBar: AppBar(
          backgroundColor: VAColors.surfaceDark,
          elevation: 0,
          centerTitle: true,
          title: const Text('Recents'),
          leading: PressEffect(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: LucideSvgIcon('chevron-left', size: 22, color: Colors.white),
            ),
          ),
        ),
        body: docs.when(
          data: (items) {
            if (items.isEmpty) {
              return const _EmptyRecents();
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = items[index];
                return _RecentTile(doc: doc);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Failed to load: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentTile extends ConsumerWidget {
  const _RecentTile({required this.doc});

  final Document doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: VAColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VAColors.glassBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          doc.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          doc.author.isEmpty ? ' ' : doc.author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PressEffect(
              onTap: () => _rename(context, ref, doc),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: LucideSvgIcon('edit', size: 18, color: Colors.white),
              ),
            ),
            PressEffect(
              onTap: () => _delete(ref, doc.id),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: LucideSvgIcon('trash', size: 18, color: Color(0xFFF87171)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(WidgetRef ref, String id) async {
    await ref.read(documentsControllerProvider.notifier).delete(id);
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Document doc) async {
    final controller = TextEditingController(text: doc.title);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: VAColors.surfaceDark,
          title: const Text('Rename document'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await ref
          .read(documentsControllerProvider.notifier)
          .rename(doc.id, controller.text);
    }
  }
}

class _EmptyRecents extends StatelessWidget {
  const _EmptyRecents();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No recent documents yet.',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
