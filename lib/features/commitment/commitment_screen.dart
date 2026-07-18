import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_providers.dart';
import '../../core/date_utils.dart';
import '../../core/settings_controller.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/commitment.dart';
import 'commitment_pdf.dart';

class CommitmentScreen extends ConsumerWidget {
  const CommitmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final commitmentAsync = ref.watch(commitmentProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.commitmentDoc)),
      body: commitmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${s.error}\n$e')),
        data: (commitment) {
          if (commitment == null || commitment.text.trim().isEmpty) {
            return EmptyState(
              emoji: '📜',
              title: s.commitmentEmpty,
              action: FilledButton.icon(
                onPressed: () => _openEditor(context, ref, null),
                icon: const Icon(Icons.edit),
                label: Text(s.writeCommitment),
              ),
            );
          }
          return _CommitmentView(commitment: commitment);
        },
      ),
      floatingActionButton: commitmentAsync.valueOrNull != null &&
              (commitmentAsync.valueOrNull?.text.trim().isNotEmpty ?? false)
          ? FloatingActionButton(
              onPressed: () =>
                  _openEditor(context, ref, commitmentAsync.valueOrNull),
              backgroundColor: BrandColors.green,
              foregroundColor: Colors.white,
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, Commitment? existing) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _CommitmentEditor(initialText: existing?.text ?? ''),
    ));
  }
}

class _CommitmentView extends ConsumerWidget {
  const _CommitmentView({required this.commitment});
  final Commitment commitment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final user = ref.watch(appUserProvider).valueOrNull;
    final name = user?.name ?? '';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: BrandColors.gold, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: BrandColors.green.withValues(alpha: 0.5), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: Text('🏆', style: TextStyle(fontSize: 40))),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        s.commitmentDoc,
                        style: theme.textTheme.headlineSmall?.copyWith(
                            color: BrandColors.green,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                        child: Container(
                            width: 120, height: 2, color: BrandColors.gold)),
                    const SizedBox(height: 24),
                    Text(
                      commitment.text,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.9),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: BrandColors.gold.withValues(alpha: 0.6)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name,
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: BrandColors.green,
                                fontWeight: FontWeight.bold)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (commitment.createdAt != null)
                              Text(
                                s.writtenOnLabel(longDate(commitment.createdAt!,
                                    isArabic: s.isArabic)),
                                style: theme.textTheme.bodySmall,
                              ),
                            if (commitment.isEdited &&
                                commitment.updatedAt != null)
                              Text(
                                s.editedOnLabel(longDate(commitment.updatedAt!,
                                    isArabic: s.isArabic)),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _exportPdf(context, ref, name),
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(s.exportPdf),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportPdf(
      BuildContext context, WidgetRef ref, String name) async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final dialogNav = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final bytes = await buildCommitmentPdf(
        text: commitment.text,
        name: name,
        createdAt: commitment.createdAt,
        updatedAt: commitment.updatedAt,
        isArabic: s.isArabic,
      ).timeout(const Duration(seconds: 30));
      dialogNav.pop();
      await shareCommitmentPdf(bytes);
    } catch (e) {
      dialogNav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${s.error}: $e'),
          backgroundColor: BrandColors.danger,
        ),
      );
    }
  }
}

class _CommitmentEditor extends ConsumerStatefulWidget {
  const _CommitmentEditor({required this.initialText});
  final String initialText;

  @override
  ConsumerState<_CommitmentEditor> createState() => _CommitmentEditorState();
}

class _CommitmentEditorState extends ConsumerState<_CommitmentEditor> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final s = ref.read(stringsProvider);
    setState(() => _saving = true);
    try {
      await ref
          .read(firestoreServiceProvider)!
          .saveCommitment(text)
          .timeout(const Duration(seconds: 20));
      navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${s.error}: $e'),
            backgroundColor: BrandColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.commitmentDoc),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(s.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: s.commitmentHint,
            alignLabelWithHint: true,
          ),
        ),
      ),
    );
  }
}
