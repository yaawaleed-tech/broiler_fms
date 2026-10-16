import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/weight/weight_domain.dart';
import 'package:broiler_fms/presentation/mobile/financial/financial_refresh.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/review_step.dart';

/// Staff records a weight sample against one batch: the combined
/// weight of a small sample of birds, plus how many birds were weighed.
class WeightFormScreen extends ConsumerStatefulWidget {
  const WeightFormScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<WeightFormScreen> createState() => _WeightFormScreenState();
}

class _WeightFormScreenState extends ConsumerState<WeightFormScreen> {
  final _weightController = TextEditingController();
  final _countController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _showingReview = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _weightController.dispose();
    _countController.dispose();
    super.dispose();
  }

  double? get _parsedWeight => double.tryParse(_weightController.text.trim());
  int? get _parsedCount => int.tryParse(_countController.text.trim());

  bool get _isValid {
    final weight = _parsedWeight;
    final count = _parsedCount;
    return weight != null && weight > 0 && count != null && count > 0;
  }

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
    final weight = _parsedWeight;
    final count = _parsedCount;
    if (weight == null || count == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(weightDomainProvider).recordWeightSample(
        batchId: widget.batchId,
        date: _date,
        sampleWeight: weight,
        sampleCount: count,
      );
      if (!mounted) return;
      // Refresh batch detail and the financial summary so the figures
      // behind this screen reflect the entry that was just saved.
      invalidateBatchFinancials(ref, widget.batchId);
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
      appBar: AppBar(title: const Text('Record weight sample')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _showingReview ? _buildReview() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
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
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Combined sample weight (kg)',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _countController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of birds weighed',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
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
          onPressed: _isValid ? () => setState(() => _showingReview = true) : null,
          child: const Text('Review'),
        ),
      ],
    );
  }

  Widget _buildReview() {
    final weight = _parsedWeight ?? 0;
    final count = _parsedCount ?? 0;
    return ReviewStep(
      title: 'Review weight sample',
      entries: [
        ReviewEntry('Date', DateFormat.yMMMd().format(_date)),
        ReviewEntry('Sample weight', '${AppFormat.quantity(weight)} kg'),
        ReviewEntry('Birds weighed', AppFormat.count(count)),
        ReviewEntry(
          'Average per bird',
          '${AppFormat.twoDecimals(weight / count)} kg',
        ),
      ],
      onEdit: () => setState(() => _showingReview = false),
      onConfirm: _isSaving ? () {} : _confirm,
      confirmLabel: _isSaving ? 'Saving...' : 'Confirm',
      note: 'This entry cannot be edited once saved.',
    );
  }
}