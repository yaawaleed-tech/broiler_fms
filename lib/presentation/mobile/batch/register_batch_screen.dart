import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/confirm_dialog.dart';
import 'package:broiler_fms/presentation/shared/widgets/review_step.dart';

/// Manager registers a new batch. businessId is never entered here,
/// BatchDomain resolves it from the current account automatically.
class RegisterBatchScreen extends ConsumerStatefulWidget {
  const RegisterBatchScreen({super.key});

  @override
  ConsumerState<RegisterBatchScreen> createState() =>
      _RegisterBatchScreenState();
}

class _RegisterBatchScreenState extends ConsumerState<RegisterBatchScreen> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startingCountController = TextEditingController();
  DateTime _startDate = DateTime.now();
  bool _showingReview = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _descriptionController.dispose();
    _startingCountController.dispose();
    super.dispose();
  }

  int? get _parsedCount => int.tryParse(_startingCountController.text.trim());

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
          (_parsedCount ?? 0) > 0;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _confirm() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final batch = await ref.read(batchDomainProvider).createBatch(
        batchName: _nameController.text.trim(),
        startingBirdCount: _parsedCount!,
        startDate: _startDate,
        breed: _breedController.text.trim().isEmpty
            ? null
            : _breedController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      if (!mounted) return;

      final assignNow = await showConfirmDialog(
        context,
        title: 'Batch registered',
        body: 'Would you like to assign a Staff member to this batch now?',
        confirmLabel: 'Assign now',
        cancelLabel: 'Later',
      );
      if (!mounted) return;

      if (assignNow == true) {
        context.pushReplacement('/batches/${batch.batchId}/assign-staff');
      } else {
        context.go('/');
      }
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
      appBar: AppBar(title: const Text('Register batch')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _showingReview ? _buildReview() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Batch name',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _startingCountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Starting bird count',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Start date'),
          subtitle: Text(DateFormat.yMMMd().format(_startDate)),
          trailing: const Icon(Icons.calendar_today, size: 18),
          onTap: _pickStartDate,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _breedController,
          decoration: const InputDecoration(
            labelText: 'Breed (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
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
          onPressed:
          _isValid ? () => setState(() => _showingReview = true) : null,
          child: const Text('Review'),
        ),
      ],
    );
  }

  Widget _buildReview() {
    final breed = _breedController.text.trim();
    final description = _descriptionController.text.trim();
    return ReviewStep(
      title: 'Review new batch',
      entries: [
        ReviewEntry('Name', _nameController.text.trim()),
        ReviewEntry('Starting count', AppFormat.count(_parsedCount ?? 0)),
        ReviewEntry('Start date', DateFormat.yMMMd().format(_startDate)),
        if (breed.isNotEmpty) ReviewEntry('Breed', breed),
        if (description.isNotEmpty) ReviewEntry('Description', description),
      ],
      onEdit: () => setState(() => _showingReview = false),
      onConfirm: _isSaving ? () {} : _confirm,
      confirmLabel: _isSaving ? 'Saving...' : 'Confirm',
    );
  }
}