import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/feed/feed_domain.dart';
import 'package:broiler_fms/presentation/mobile/batch/batch_detail_screen.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/review_step.dart';

/// Staff records a feed entry against one batch.
class FeedFormScreen extends ConsumerStatefulWidget {
  const FeedFormScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<FeedFormScreen> createState() => _FeedFormScreenState();
}

class _FeedFormScreenState extends ConsumerState<FeedFormScreen> {
  final _quantityController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _showingReview = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  double? get _parsedQuantity => double.tryParse(_quantityController.text.trim());

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
    final quantity = _parsedQuantity;
    if (quantity == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(feedDomainProvider).recordFeed(
        batchId: widget.batchId,
        date: _date,
        quantity: quantity,
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
      appBar: AppBar(title: const Text('Record feed')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _showingReview ? _buildReview() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final quantity = _parsedQuantity;
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
          controller: _quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Quantity (kg)',
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
          onPressed: quantity == null || quantity <= 0
              ? null
              : () => setState(() => _showingReview = true),
          child: const Text('Review'),
        ),
      ],
    );
  }

  Widget _buildReview() {
    final quantity = _parsedQuantity ?? 0;
    return ReviewStep(
      title: 'Review feed entry',
      entries: [
        ReviewEntry('Date', DateFormat.yMMMd().format(_date)),
        ReviewEntry('Quantity', '${AppFormat.quantity(quantity)} kg'),
      ],
      onEdit: () => setState(() => _showingReview = false),
      onConfirm: _isSaving ? () {} : _confirm,
      confirmLabel: _isSaving ? 'Saving...' : 'Confirm',
      note: 'This entry cannot be edited once saved.',
    );
  }
}