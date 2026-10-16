import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:broiler_fms/domain/models/financial_summary.dart';
import 'package:broiler_fms/domain/rules/financial_summary_rule.dart';
import 'package:broiler_fms/presentation/mobile/financial/whole_number_input.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';

/// Whole-naira ceiling for the price input.
const _maxPrice = 9999999;

/// Whole-naira ceiling for the target-profit input.
const _maxTarget = 999999999;

/// Which question the simulator answers.
enum _SimulatorMode { price, target }

/// The Manager's profit calculator for one batch: "what profit at this
/// price?" or "what price for this profit?".
///
/// A calculator only — nothing is saved, no database or network calls,
/// it works fully offline from the [summary] already loaded by the
/// financial summary screen. All input state is local widget state.
class ProfitSimulator extends StatefulWidget {
  const ProfitSimulator({super.key, required this.summary});

  final FinancialSummary summary;

  @override
  State<ProfitSimulator> createState() => _ProfitSimulatorState();
}

class _ProfitSimulatorState extends State<ProfitSimulator> {
  _SimulatorMode _mode = _SimulatorMode.price;

  late final TextEditingController _priceController;
  late final TextEditingController _targetController;
  late final TextEditingController _birdsController;
  late final FocusNode _priceFocus;
  late final FocusNode _targetFocus;
  late final FocusNode _birdsFocus;

  /// True once the user has typed a birds count of their own. While
  /// false the field follows the batch's birds count on refresh.
  bool _birdsEdited = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _targetController = TextEditingController();
    _birdsController = TextEditingController(
      text: _birdsText(widget.summary.birdsStillToPrice),
    );
    _priceFocus = FocusNode();
    _targetFocus = FocusNode();
    _birdsFocus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant ProfitSimulator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final max = widget.summary.birdsStillToPrice;
    if (max <= 0) return;
    final current = parseWholeNumber(_birdsController.text) ?? 0;
    if (!_birdsEdited) {
      if (current != max) _birdsController.text = _birdsText(max);
    } else if (current > max) {
      _birdsController.text = _birdsText(max);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _targetController.dispose();
    _birdsController.dispose();
    _priceFocus.dispose();
    _targetFocus.dispose();
    _birdsFocus.dispose();
    super.dispose();
  }

  static String _birdsText(int birds) =>
      birds <= 0 ? '' : formatWholeNumber(birds);

  int get _maxBirds => widget.summary.birdsStillToPrice;

  int? get _price => parseWholeNumber(_priceController.text);

  int? get _target => parseWholeNumber(_targetController.text);

  int? get _birds => parseWholeNumber(_birdsController.text);

  bool get _priceValid => (_price ?? 0) > 0;

  bool get _targetValid => (_target ?? 0) > 0;

  bool get _birdsValid {
    final birds = _birds ?? 0;
    return birds >= 1 && birds <= _maxBirds;
  }

  /// Clamps the birds field to the batch max as the user types.
  void _onBirdsChanged() {
    final birds = _birds;
    if (birds == null) {
      setState(() => _birdsEdited = true);
      return;
    }
    if (birds > _maxBirds) {
      _birdsController.text = _birdsText(_maxBirds);
      _birdsController.selection = TextSelection.collapsed(
        offset: _birdsController.text.length,
      );
    }
    setState(() => _birdsEdited = true);
  }

  /// Clamps a money field to its ceiling as the user types.
  void _onMoneyChanged(TextEditingController controller, int ceiling) {
    final value = parseWholeNumber(controller.text);
    if (value != null && value > ceiling) {
      controller.text = formatWholeNumber(ceiling);
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }
    setState(() {});
  }

  /// Fills the price with the break-even rounded up to whole naira.
  void _useBreakeven() {
    final breakeven = widget.summary.breakevenPricePerBird;
    if (breakeven == null || breakeven <= 0) return;
    _priceController.text = formatWholeNumber(ceilToNaira(breakeven));
    _priceController.selection = TextSelection.collapsed(
      offset: _priceController.text.length,
    );
    setState(() {});
  }

  /// Carries the target-mode price into price mode, keeping birds.
  void _useTargetPrice(double requiredPrice) {
    _priceController.text = formatWholeNumber(ceilToNaira(requiredPrice));
    _priceController.selection = TextSelection.collapsed(
      offset: _priceController.text.length,
    );
    setState(() => _mode = _SimulatorMode.price);
  }

  /// Signed whole-naira money without ever showing "₦-0".
  String _signedMoney(double value) {
    if (value == 0) return AppFormat.money(0);
    final sign = value > 0 ? '+' : '-';
    return '$sign${AppFormat.money(value.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairlineStrong, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profit simulator',
            style: TextStyle(
              fontFamily: 'RobotoSlab',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          if (summary.birdsStillToPrice <= 0)
            const Text(
              'No birds left to sell, so there is nothing to simulate.',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 13,
                color: AppColors.inkMuted,
                height: 1.4,
              ),
            )
          else ...[
            Text(
              '${AppFormat.count(summary.birdsStillToPrice)} birds left to sell'
              ' · ${AppFormat.money(summary.totalRevenue)} revenue so far'
              ' · ${AppFormat.money(summary.totalExpenses)} expenses',
              style: const TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 12,
                color: AppColors.inkMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_SimulatorMode>(
                segments: const [
                  ButtonSegment(
                    value: _SimulatorMode.price,
                    label: Text('Selling price'),
                  ),
                  ButtonSegment(
                    value: _SimulatorMode.target,
                    label: Text('Target profit'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.first);
                },
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _mode == _SimulatorMode.price
                  ? 'See the profit at a price you choose.'
                  : 'See the price needed for the profit you want.',
              style: const TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 12,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 12),
            if (_mode == _SimulatorMode.price)
              _buildPriceMode(summary)
            else
              _buildTargetMode(summary),
          ],
        ],
      ),
    );
  }

  Widget _moneyField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String helper,
    required VoidCallback onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            WholeNumberInputFormatter(),
          ],
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }

  Widget _buildPriceMode(FinancialSummary summary) {
    final breakeven = summary.breakevenPricePerBird;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _moneyField(
                controller: _priceController,
                focusNode: _priceFocus,
                label: 'Selling price per bird (₦)',
                helper: 'Whole naira up to ₦9,999,999',
                onChanged: () =>
                    _onMoneyChanged(_priceController, _maxPrice),
              ),
            ),
            if (breakeven != null && breakeven > 0) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: OutlinedButton(
                  onPressed: _useBreakeven,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Use break-even'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _moneyField(
          controller: _birdsController,
          focusNode: _birdsFocus,
          label: 'Number of birds to sell',
          helper: 'Max ${AppFormat.count(_maxBirds)}',
          onChanged: _onBirdsChanged,
        ),
        const SizedBox(height: 12),
        if (!_priceValid)
          const Text(
            'Enter a price above ₦0',
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 12.5,
              color: AppColors.inkMuted,
            ),
          )
        else if (!_birdsValid)
          const Text(
            'Enter the number of birds to sell',
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 12.5,
              color: AppColors.inkMuted,
            ),
          )
        else
          _buildPriceResults(summary),
        _uncoveredNote(),
      ],
    );
  }

  Widget _buildPriceResults(FinancialSummary summary) {
    final price = _price!.toDouble();
    final birds = _birds!;
    final fromThese = revenueFromTheseBirds(
      pricePerBird: price,
      birdsToSell: birds,
    );
    final total = projectedTotalRevenue(
      totalRevenue: summary.totalRevenue,
      revenueFromTheseBirds: fromThese,
    );
    final profit = projectedProfit(
      projectedTotalRevenue: total,
      totalExpenses: summary.totalExpenses,
    );
    final margin = profitMarginPercent(
      projectedProfit: profit,
      projectedTotalRevenue: total,
    );
    final compared = priceComparedWithBreakeven(
      pricePerBird: price,
      breakeven: summary.breakevenPricePerBird,
    );
    final isProfit = profit >= 0;

    return Column(
      children: [
        _SimRow(
          label: 'Revenue from these birds',
          value: AppFormat.money(fromThese),
        ),
        _SimRow(
          label: 'Projected total revenue',
          value: AppFormat.money(total),
        ),
        _SimRow(
          label: 'Projected profit / loss',
          value: _signedMoney(profit),
          valueColor: isProfit ? AppColors.olive : AppColors.brick,
          emphasize: true,
        ),
        _SimRow(
          label: 'Profit margin',
          value: margin == null ? '—' : '${margin.toStringAsFixed(1)}%',
        ),
        _SimRow(
          label: 'Compared with break-even',
          value: _comparedText(compared, summary.breakevenPricePerBird),
        ),
      ],
    );
  }

  String _comparedText(double? compared, double? breakeven) {
    if (breakeven == null) return '—';
    // Display-level tolerance: dust amounts read as ₦0.00, so a
    // break-even within half a kobo of zero counts as covered, and a
    // price within half a kobo of the break-even counts as equal.
    if (breakeven <= 0.005) return 'Costs already covered';
    if (compared == null || compared.abs() <= 0.005) return 'At break-even';
    final amount = AppFormat.money(compared.abs(), decimals: 2);
    return compared > 0 ? '$amount above break-even' : '$amount below break-even';
  }

  Widget _buildTargetMode(FinancialSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _moneyField(
          controller: _targetController,
          focusNode: _targetFocus,
          label: 'Target profit (₦)',
          helper: 'Whole naira up to ₦999,999,999',
          onChanged: () => _onMoneyChanged(_targetController, _maxTarget),
        ),
        const SizedBox(height: 12),
        _moneyField(
          controller: _birdsController,
          focusNode: _birdsFocus,
          label: 'Number of birds to sell',
          helper: 'Max ${AppFormat.count(_maxBirds)}',
          onChanged: _onBirdsChanged,
        ),
        const SizedBox(height: 12),
        if (!_targetValid)
          const Text(
            'Enter a target above ₦0',
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 12.5,
              color: AppColors.inkMuted,
            ),
          )
        else if (!_birdsValid)
          const Text(
            'Enter the number of birds to sell',
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 12.5,
              color: AppColors.inkMuted,
            ),
          )
        else
          _buildTargetResults(summary),
        _uncoveredNote(),
      ],
    );
  }

  Widget _buildTargetResults(FinancialSummary summary) {
    final target = _target!.toDouble();
    final birds = _birds!;
    final required = requiredPriceForTargetProfit(
      totalExpenses: summary.totalExpenses,
      targetProfit: target,
      totalRevenue: summary.totalRevenue,
      birdsToSell: birds,
    )!;
    final needed = totalRevenueNeeded(
      totalExpenses: summary.totalExpenses,
      targetProfit: target,
    );

    if (required == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.oliveBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.olive, width: 1.5),
        ),
        child: const Text(
          'You have already passed this target. Any price is fine.',
          style: TextStyle(
            fontFamily: 'PublicSans',
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: AppColors.olive,
            height: 1.4,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.hairlineStrong, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To make ${AppFormat.money(target)} profit, sell each of '
                'these $birds birds for at least',
                style: const TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 13,
                  color: AppColors.ink,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppFormat.money(ceilToNaira(required)),
                style: const TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _SimRow(
          label: 'Total revenue needed',
          value: AppFormat.money(needed),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: () => _useTargetPrice(required),
            child: const Text('Use this price'),
          ),
        ),
      ],
    );
  }

  /// Warns when the scenario covers fewer birds than are left to sell.
  Widget _uncoveredNote() {
    if (!_priceValid && !_targetValid) return const SizedBox.shrink();
    if (!_birdsValid) return const SizedBox.shrink();
    final difference = _maxBirds - _birds!;
    if (difference <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '$difference ${difference == 1 ? 'bird is' : 'birds are'} '
        'not covered by this scenario.',
        style: const TextStyle(
          fontFamily: 'PublicSans',
          fontSize: 12,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}

/// One label/value line inside the simulator results, matching the
/// label/value rows used elsewhere on this screen.
class _SimRow extends StatelessWidget {
  const _SimRow({required this.label, required this.value, this.valueColor, this.emphasize = false});

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 13,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 13,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ?? AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
