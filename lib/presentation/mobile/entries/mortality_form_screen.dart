import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/mortality/mortality_domain.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/review_step.dart';

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
      appBar: AppBar(title: const Text('Record mortality')),
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
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Date'),
          subtitle: Text(DateFormat.yMMMd().format(_date)),
          trailing: const Icon(Icons.calendar_today, size: 18),
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _countController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Count',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
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
          child: const Text('Review'),
        ),
      ],
    );
  }

  Widget _buildReview() {
    final count = _parsedCount ?? 0;
    final description = _descriptionController.text.trim();
    return ReviewStep(
      title: 'Review mortality entry',
      entries: [
        ReviewEntry('Date', DateFormat.yMMMd().format(_date)),
        ReviewEntry('Count', '$count'),
        if (description.isNotEmpty) ReviewEntry('Note', description),
      ],
      onEdit: () => setState(() => _showingReview = false),
      onConfirm: _isSaving ? () {} : _confirm,
      confirmLabel: _isSaving ? 'Saving...' : 'Confirm',
      note: 'This entry cannot be edited once saved.',
    );
  }
}