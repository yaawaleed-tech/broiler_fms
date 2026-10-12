import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/expense/expense_domain.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/review_step.dart';

const _categories = {
  'chicks': 'Chicks',
  'feed': 'Feed',
  'vet_medication': 'Vet / Medication',
  'other': 'Other',
};

/// Manager logs an expense against a batch. The fields shown change
/// depending on the chosen category, matching the mockup's four
/// separate category screens, kept here as one form for simplicity.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _feedTypeController = TextEditingController();
  final _medicationNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'chicks';
  DateTime _date = DateTime.now();
  bool _showingReview = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _feedTypeController.dispose();
    _medicationNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double? get _parsedAmount => double.tryParse(_amountController.text.trim());

  bool get _isValid => (_parsedAmount ?? 0) > 0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  double? _parsedOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : double.tryParse(text);
  }

  String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _confirm() async {
    final amount = _parsedAmount;
    if (amount == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(expenseDomainProvider).recordExpense(
        batchId: widget.batchId,
        category: _category,
        date: _date,
        amount: amount,
        quantity: _parsedOrNull(_quantityController),
        unitPrice: _parsedOrNull(_unitPriceController),
        feedType: _category == 'feed'
            ? _textOrNull(_feedTypeController)
            : null,
        medicationName: _category == 'vet_medication'
            ? _textOrNull(_medicationNameController)
            : null,
        description: _textOrNull(_descriptionController),
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
      appBar: AppBar(title: const Text('Log expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _showingReview ? _buildReview() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final entry in _categories.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _category = value);
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Date'),
          subtitle: Text(DateFormat.yMMMd().format(_date)),
          trailing: const Icon(Icons.calendar_today, size: 18),
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        if (_category == 'feed') ...[
          TextField(
            controller: _feedTypeController,
            decoration: const InputDecoration(
              labelText: 'Feed type',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Quantity (kg)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _unitPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price per kg (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_category == 'vet_medication') ...[
          TextField(
            controller: _medicationNameController,
            decoration: const InputDecoration(
              labelText: 'Medication name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
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
          onPressed:
          _isValid ? () => setState(() => _showingReview = true) : null,
          child: const Text('Review'),
        ),
      ],
    );
  }

  Widget _buildReview() {
    final feedType = _feedTypeController.text.trim();
    final medicationName = _medicationNameController.text.trim();
    final description = _descriptionController.text.trim();
    return ReviewStep(
      title: 'Review expense',
      entries: [
        ReviewEntry('Category', _categories[_category]!),
        ReviewEntry('Date', DateFormat.yMMMd().format(_date)),
        if (feedType.isNotEmpty) ReviewEntry('Feed type', feedType),
        if (medicationName.isNotEmpty)
          ReviewEntry('Medication', medicationName),
        ReviewEntry('Amount', AppFormat.money(_parsedAmount ?? 0)),
        if (description.isNotEmpty) ReviewEntry('Note', description),
      ],
      onEdit: () => setState(() => _showingReview = false),
      onConfirm: _isSaving ? () {} : _confirm,
      confirmLabel: _isSaving ? 'Saving...' : 'Confirm',
      note: 'This entry cannot be edited once saved.',
    );
  }
}