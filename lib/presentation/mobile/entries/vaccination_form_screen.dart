import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/vaccination/vaccination_domain.dart';
import 'package:broiler_fms/presentation/mobile/batch/batch_detail_screen.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/review_step.dart';

/// Staff records a vaccination entry against one batch.
class VaccinationFormScreen extends ConsumerStatefulWidget {
  const VaccinationFormScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<VaccinationFormScreen> createState() =>
      _VaccinationFormScreenState();
}

class _VaccinationFormScreenState
    extends ConsumerState<VaccinationFormScreen> {
  final _vaccineNameController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _showingReview = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _vaccineNameController.dispose();
    super.dispose();
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
    final vaccineName = _vaccineNameController.text.trim();
    if (vaccineName.isEmpty) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(vaccinationDomainProvider).recordVaccination(
        batchId: widget.batchId,
        date: _date,
        vaccineName: vaccineName,
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
      appBar: AppBar(title: const Text('Record vaccination')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _showingReview ? _buildReview() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final vaccineName = _vaccineNameController.text.trim();
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
          controller: _vaccineNameController,
          decoration: const InputDecoration(
            labelText: 'Vaccine name',
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
          onPressed: vaccineName.isEmpty
              ? null
              : () => setState(() => _showingReview = true),
          child: const Text('Review'),
        ),
      ],
    );
  }

  Widget _buildReview() {
    return ReviewStep(
      title: 'Review vaccination entry',
      entries: [
        ReviewEntry('Date', DateFormat.yMMMd().format(_date)),
        ReviewEntry('Vaccine', _vaccineNameController.text.trim()),
      ],
      onEdit: () => setState(() => _showingReview = false),
      onConfirm: _isSaving ? () {} : _confirm,
      confirmLabel: _isSaving ? 'Saving...' : 'Confirm',
      note: 'This entry cannot be edited once saved.',
    );
  }
}