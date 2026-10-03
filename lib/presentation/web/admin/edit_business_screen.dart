import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/business/business_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/business.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';

/// Edits the signed-in Admin's own business. Pre-fills every field
/// from the current business, since this is a change screen, not a
/// fresh registration.
class EditBusinessScreen extends ConsumerStatefulWidget {
  const EditBusinessScreen({super.key});

  @override
  ConsumerState<EditBusinessScreen> createState() =>
      _EditBusinessScreenState();
}

class _EditBusinessScreenState extends ConsumerState<EditBusinessScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  Business? _business;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _businessTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final business = await ref.read(businessDomainProvider).getOwnBusiness();
    if (!mounted) return;
    setState(() {
      _business = business;
      _nameController.text = business?.name ?? '';
      _addressController.text = business?.address ?? '';
      _phoneController.text = business?.phone ?? '';
      _businessTypeController.text = business?.businessType ?? '';
      _descriptionController.text = business?.description ?? '';
      _isLoading = false;
    });
  }

  String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    final business = _business;
    if (business == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(businessDomainProvider).updateProfile(
        businessId: business.businessId,
        name: _textOrNull(_nameController),
        address: _textOrNull(_addressController),
        phone: _textOrNull(_phoneController),
        businessType: _textOrNull(_businessTypeController),
        description: _textOrNull(_descriptionController),
      );
      if (!mounted) return;
      context.pop();
    } on DomainException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit business')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Business name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _businessTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Business type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? 'Saving...' : 'Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}