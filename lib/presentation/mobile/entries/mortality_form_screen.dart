import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/presentation/mobile/batch/batch_detail_screen.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/mortality/mortality_domain.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/review_step.dart';

/// The batch name for the AppBar subtitle, e.g. "Batch 7". Fetched
/// separately from the form itself — the form only needs the batchId.
final _batchNameProvider = FutureProvider.autoDispose.family<String, String>((
    ref,
    batchId,
    ) async {
  final batch = await ref.watch(batchDomainProvider).getById(batchId);
  return batch?.batchName ?? '';
});

/// Staff records a mortality entry against one batch. Follows the
/// shared form-then-review pattern: fields are entered first, then
/// ReviewStep shows what will be saved before anything actually
/// writes.
class MortalityFormScreen extends ConsumerStatefulWidget {
  const MortalityFormScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<MortalityFormScreen> createState() =>
      _MortalityFormScreenState();
}

class _MortalityFormScreenState extends ConsumerState<MortalityFormScreen> {
  final _countController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _showingReview = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _countController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int? get _parsedCount => int.tryParse(_countController.text.trim());

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _confirm() async {
    final count = _parsedCount;
    if (count == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(mortalityDomainProvider).recordMortality(
        batchId: widget.batchId,
        date: _date,
        count: count,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      if (!mounted) return;
      // Refresh batch detail so the stat cards behind this screen
      // reflect the entry that was just saved.
      ref.invalidate(batchDetailProvider(widget.batchId));
      context.pop();
    } on DomainException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _showingReview = false;
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.rust,
        foregroundColor: AppColors.card,
        title: _BatchTitle(
          batchId: widget.batchId,
          title: _showingReview ? 'Review entry' : 'Record mortality',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _showingReview ? _buildReview() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final count = _parsedCount;
    return ListView(
      children: [
        _FieldLabel('Date'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hairlineStrong, width: 1),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('d MMM yyyy').format(_date),
                  style: const TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _FieldLabel('Number of birds that died'),
        const SizedBox(height: 8),
        TextField(
          controller: _countController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(
              fontFamily: 'PublicSans',
              color: AppColors.inkMuted,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _FieldLabel('Note (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 12.5,
              color: AppColors.brick,
            ),
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: count == null || count < 1
              ? null
              : () => setState(() => _showingReview = true),
          child: const Text('Review entry'),
        ),
      ],
    );
  }

  Widget _buildReview() {
    final count = _parsedCount ?? 0;
    final description = _descriptionController.text.trim();
    return ReviewStep(
      title: '',
      entries: [
        ReviewEntry('Date', DateFormat('d MMM yyyy').format(_date)),
        ReviewEntry('Birds that died', AppFormat.count(count)),
        if (description.isNotEmpty) ReviewEntry('Note', description),
      ],
      onEdit: () => setState(() => _showingReview = false),
      onConfirm: _isSaving ? () {} : _confirm,
      confirmLabel: _isSaving ? 'Saving...' : 'Confirm and save',
      note: 'Check this looks right before saving. Entries cannot be edited '
          'once saved.',
    );
  }
}

/// A small label above each form field, matching the mockup's static
/// (non-floating) field labels.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'PublicSans',
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.ink,
      ),
    );
  }
}

/// The AppBar title: "Record mortality" / "Review entry" with the
/// batch's name underneath, e.g. "Batch 7".
class _BatchTitle extends ConsumerWidget {
  const _BatchTitle({required this.batchId, required this.title});

  final String batchId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameAsync = ref.watch(_batchNameProvider(batchId));
    return nameAsync.when(
      loading: () => _titleOnly(),
      error: (_, _) => _titleOnly(),
      data: (batchName) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _titleOnly(),
          if (batchName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Batch $batchName',
              style: const TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 12,
                color: AppColors.parchment,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _titleOnly() {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'RobotoSlab',
        fontWeight: FontWeight.w700,
        fontSize: 17,
        color: AppColors.card,
      ),
    );
  }
}
