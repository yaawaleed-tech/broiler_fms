import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/harvest/harvest_domain.dart';
import 'package:broiler_fms/domain/models/harvest.dart';
import 'package:broiler_fms/domain/sale/sale_domain.dart';
import 'package:broiler_fms/presentation/mobile/sale/harvest_list_screen.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/review_step.dart';

/// Manager prices one harvest: Sale or Gift/Cull, then, for a Sale,
/// Per-kg or Flat-total pricing. Matches sale_shape_rule.dart's
/// branches exactly, since that rule is what ultimately decides
/// whether this form's values are accepted.
class PriceHarvestScreen extends ConsumerStatefulWidget {
  const PriceHarvestScreen({
    super.key,
    required this.batchId,
    required this.harvestId,
  });

  final String batchId;
  final String harvestId;

  @override
  ConsumerState<PriceHarvestScreen> createState() =>
      _PriceHarvestScreenState();
}

class _PriceHarvestScreenState extends ConsumerState<PriceHarvestScreen> {
  final _buyerNameController = TextEditingController();
  final _weightController = TextEditingController();
  final _pricePerUnitController = TextEditingController();
  final _amountController = TextEditingController();

  String _disposition = 'sale';
  String _pricingMethod = 'per_kg';
  // Paid or pending: kept for reference only and fixed once saved.
  String _paymentStatus = 'paid';
  bool _showingReview = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _buyerNameController.dispose();
    _weightController.dispose();
    _pricePerUnitController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? _numOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : double.tryParse(text);
  }

  /// For per_kg: whenever two of (weight, price per kg, amount) are
  /// known, the third is computed and written into its own field.
  void _recalculatePerKg({required String justEdited}) {
    final weight = _numOrNull(_weightController);
    final price = _numOrNull(_pricePerUnitController);
    final amount = _numOrNull(_amountController);

    if (justEdited != 'amount' && weight != null && price != null) {
      _amountController.text = (weight * price).toStringAsFixed(2);
    } else if (justEdited != 'price' && weight != null && amount != null) {
      _pricePerUnitController.text = (amount / weight).toStringAsFixed(2);
    } else if (justEdited != 'weight' && price != null && amount != null) {
      _weightController.text = (amount / price).toStringAsFixed(2);
    }
  }

  /// For flat_total: price per bird and amount drive each other,
  /// using this harvest's already-known bird count as the fixed
  /// third value.
  void _recalculateFlatTotal({
    required String justEdited,
    required int birdCount,
  }) {
    final price = _numOrNull(_pricePerUnitController);
    final amount = _numOrNull(_amountController);

    if (justEdited == 'price' && price != null) {
      _amountController.text = (price * birdCount).toStringAsFixed(2);
    } else if (justEdited == 'amount' && amount != null && birdCount > 0) {
      _pricePerUnitController.text = (amount / birdCount).toStringAsFixed(2);
    }
  }

  Future<void> _confirm(Harvest harvest) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final isGift = _disposition == 'gift_cull';

    try {
      await ref.read(saleDomainProvider).recordSale(
        harvestId: widget.harvestId,
        disposition: _disposition,
        amount: isGift ? 0 : (_numOrNull(_amountController) ?? 0),
        buyerName: _buyerNameController.text.trim().isEmpty
            ? null
            : _buyerNameController.text.trim(),
        pricingMethod: isGift ? null : _pricingMethod,
        weightSold:
        isGift || _pricingMethod != 'per_kg'
            ? null
            : _numOrNull(_weightController),
        pricePerUnit: isGift ? null : _numOrNull(_pricePerUnitController),
        paymentStatus: isGift ? null : _paymentStatus,
      );
      if (!mounted) return;
      // The harvest list pops back into view showing this sale, so
      // refresh it — otherwise it would keep rendering as unpriced.
      ref.invalidate(salesProvider(widget.harvestId));
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
      appBar: AppBar(title: const Text('Price harvest')),
      body: FutureBuilder<Harvest?>(
        future: ref.watch(harvestDomainProvider).getById(widget.harvestId),
        builder: (context, snapshot) {
          final harvest = snapshot.data;
          if (harvest == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _showingReview
                ? _buildReview(harvest)
                : _buildForm(harvest),
          );
        },
      ),
    );
  }

  Widget _buildForm(Harvest harvest) {
    final isGift = _disposition == 'gift_cull';

    return ListView(
      children: [
        Text(
          '${harvest.birdCount} birds harvested',
          style: const TextStyle(
            fontFamily: 'RobotoSlab',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'sale', label: Text('Sale')),
            ButtonSegment(value: 'gift_cull', label: Text('Gift / Cull')),
          ],
          selected: {_disposition},
          onSelectionChanged: (selection) {
            setState(() => _disposition = selection.first);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _buyerNameController,
          decoration: InputDecoration(
            labelText: isGift ? 'Recipient name (optional)' : 'Buyer name (optional)',
            border: const OutlineInputBorder(),
          ),
        ),
        if (!isGift) ...[
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'per_kg', label: Text('Per Kg')),
              ButtonSegment(value: 'flat_total', label: Text('Flat Total')),
            ],
            selected: {_pricingMethod},
            onSelectionChanged: (selection) {
              setState(() => _pricingMethod = selection.first);
            },
          ),
          const SizedBox(height: 12),
          if (_pricingMethod == 'per_kg') ...[
            TextField(
              controller: _weightController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight sold (kg)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) =>
                  setState(() => _recalculatePerKg(justEdited: 'weight')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pricePerUnitController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price per kg',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) =>
                  setState(() => _recalculatePerKg(justEdited: 'price')),
            ),
          ] else ...[
            TextField(
              controller: _pricePerUnitController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price per bird (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _recalculateFlatTotal(
                justEdited: 'price',
                birdCount: harvest.birdCount,
              )),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total amount',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              setState(() {
                if (_pricingMethod == 'per_kg') {
                  _recalculatePerKg(justEdited: 'amount');
                } else {
                  _recalculateFlatTotal(
                    justEdited: 'amount',
                    birdCount: harvest.birdCount,
                  );
                }
              });
            },
          ),
          const SizedBox(height: 16),
          // Payment status: required for a sale, kept for reference only.
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'paid', label: Text('Paid')),
              ButtonSegment(value: 'pending', label: Text('Pending')),
            ],
            selected: {_paymentStatus},
            onSelectionChanged: (selection) {
              setState(() => _paymentStatus = selection.first);
            },
          ),
        ],
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
          onPressed: () => setState(() => _showingReview = true),
          child: const Text('Review'),
        ),
      ],
    );
  }

  Widget _buildReview(Harvest harvest) {
    final isGift = _disposition == 'gift_cull';
    final buyerName = _buyerNameController.text.trim();

    return ReviewStep(
      title: 'Review pricing',
      entries: [
        ReviewEntry('Birds', '${harvest.birdCount}'),
        ReviewEntry('Type', isGift ? 'Gift / Cull' : 'Sale'),
        if (buyerName.isNotEmpty)
          ReviewEntry(isGift ? 'Recipient' : 'Buyer', buyerName),
        if (!isGift) ...[
          ReviewEntry(
            'Pricing method',
            _pricingMethod == 'per_kg' ? 'Per Kg' : 'Flat Total',
          ),
          if (_pricingMethod == 'per_kg')
            ReviewEntry(
              'Weight sold',
              '${AppFormat.quantity(_numOrNull(_weightController) ?? 0)} kg',
            ),
ReviewEntry(
              'Price',
              AppFormat.money(_numOrNull(_pricePerUnitController) ?? 0),
            ),
            ReviewEntry(
              'Amount',
              AppFormat.money(_numOrNull(_amountController) ?? 0),
            ),
            // Payment status, shown so the Manager can check it before saving.
            ReviewEntry(
              'Payment',
              _paymentStatus == 'paid' ? 'Paid' : 'Pending',
            ),
          ] else
          const ReviewEntry('Amount', '0'),
      ],
      onEdit: () => setState(() => _showingReview = false),
      onConfirm: _isSaving ? () {} : () => _confirm(harvest),
      confirmLabel: _isSaving ? 'Saving...' : 'Confirm',
    );
  }
}