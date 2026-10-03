import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/account/account_domain.dart';
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';

/// Manager picks one Staff account to assign to a batch, from the
/// cached Staff pool, works offline.
class AssignStaffScreen extends ConsumerStatefulWidget {
  const AssignStaffScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<AssignStaffScreen> createState() => _AssignStaffScreenState();
}

class _AssignStaffScreenState extends ConsumerState<AssignStaffScreen> {
  String? _selectedStaffId;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _confirm() async {
    final staffId = _selectedStaffId;
    if (staffId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(batchDomainProvider).assignStaff(widget.batchId, staffId);
      if (!mounted) return;
      context.go('/');
    } on DomainException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(currentAccountProvider).value;
    final businessId = account?.businessId;

    return Scaffold(
      appBar: AppBar(title: const Text('Assign staff')),
      body: businessId == null
          ? const Center(child: Text('No business linked to this account.'))
          : _buildStaffList(businessId),
    );
  }

  Widget _buildStaffList(String businessId) {
    final staffAsync =
    ref.watch(accountDomainProvider).watchStaffPool(businessId);

    return StreamBuilder<List<Account>>(
      stream: staffAsync,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final staffList = snapshot.data!;
        if (staffList.isEmpty) {
          return const Center(child: Text('No active Staff accounts yet.'));
        }
        return Column(
          children: [
            Expanded(
              child: RadioGroup<String>(
                groupValue: _selectedStaffId,
                onChanged: (value) => setState(() => _selectedStaffId = value),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final staff in staffList)
                      RadioListTile<String>(
                        value: staff.accountId,
                        title: Text(staff.name),
                        subtitle: Text(staff.email),
                      ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 12.5,
                    color: AppColors.brick,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _selectedStaffId == null || _isSaving
                    ? null
                    : _confirm,
                child: Text(_isSaving ? 'Saving...' : 'Assign'),
              ),
            ),
          ],
        );
      },
    );
  }
}