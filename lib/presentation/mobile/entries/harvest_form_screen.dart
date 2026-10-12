import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/harvest/harvest_domain.dart';
import 'package:broiler_fms/presentation/mobile/batch/batch_detail_screen.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/review_step.dart';

/// Staff records a harvest entry against one batch. Pricing it is a
/// separate action, done by Manager later, through SaleDomain.
class HarvestFormScreen extends ConsumerStatefulWidget {
  const HarvestFormScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<HarvestFormScreen> createState() => _HarvestFormScreenState();
}

class _HarvestFormScreenState extends ConsumerState<HarvestFormScreen> {
  final _countController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _showingReview = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _countController.dispose();
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
      await ref.read(harvestDomainProvider).recordHarvest(
        batchId: widget.batchId,
        date: _date,
        birdCount: count,
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
      appBar: AppBar(title: const Text('Record harvest')),
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
            labelText: 'Bird count',
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
    return ReviewStep(
      title: 'Review harvest entry',
      entries: [
        ReviewEntry('Date', DateFormat.yMMMd().format(_date)),
        ReviewEntry('Bird count', AppFormat.count(count)),
      ],
      onEdit: () => setState(() => _showingReview = false),
      onConfirm: _isSaving ? () {} : _confirm,
      confirmLabel: _isSaving ? 'Saving...' : 'Confirm',
      note: 'This entry cannot be edited once saved. Pricing is done '
          'separately by your Manager.',
    );
  }
}