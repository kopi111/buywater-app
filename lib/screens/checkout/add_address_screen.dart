import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../models/address.dart';
import '../../config/theme.dart';
import '../../utils/helpers.dart';

class AddAddressScreen extends StatefulWidget {
  final Address? address; // If editing existing address

  const AddAddressScreen({super.key, this.address});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String _selectedParish = JamaicaParishes.parishes.first;
  String? _selectedLabel;
  bool _isDefault = false;

  bool get isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _fullNameController.text = widget.address!.fullName;
      _phoneController.text = widget.address!.phone;
      _addressLine1Controller.text = widget.address!.addressLine1;
      _addressLine2Controller.text = widget.address!.addressLine2 ?? '';
      _cityController.text = widget.address!.city;
      _postalCodeController.text = widget.address!.postalCode ?? '';
      _selectedParish = widget.address!.parish;
      _selectedLabel = widget.address!.label;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final address = Address(
      id: widget.address?.id ?? const Uuid().v4(),
      userId: authProvider.user?.id ?? '',
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isNotEmpty
          ? _addressLine2Controller.text.trim()
          : null,
      city: _cityController.text.trim(),
      parish: _selectedParish,
      postalCode: _postalCodeController.text.trim().isNotEmpty
          ? _postalCodeController.text.trim()
          : null,
      isDefault: _isDefault,
      label: _selectedLabel,
    );

    bool success;
    if (isEditing) {
      success = await authProvider.updateAddress(address);
    } else {
      success = await authProvider.addAddress(address);
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      Helpers.showSnackBar(
        context,
        isEditing ? 'Address updated' : 'Address added',
      );
    } else {
      Helpers.showSnackBar(
        context,
        authProvider.error ?? 'Failed to save address',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add Address'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Label chips
            const Text('Label (Optional)', style: AppTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Home', 'Work', 'Other'].map((label) {
                return ChoiceChip(
                  label: Text(label),
                  selected: _selectedLabel == label,
                  onSelected: (selected) {
                    setState(() {
                      _selectedLabel = selected ? label : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Full name
            TextFormField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '876-XXX-XXXX',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address line 1
            TextFormField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1',
                prefixIcon: Icon(Icons.location_on_outlined),
                hintText: 'Street address',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address line 2
            TextFormField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2 (Optional)',
                prefixIcon: Icon(Icons.apartment),
                hintText: 'Apartment, suite, unit, etc.',
              ),
            ),
            const SizedBox(height: 16),

            // City
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City / Town',
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter city';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Parish dropdown
            DropdownButtonFormField<String>(
              value: _selectedParish,
              decoration: const InputDecoration(
                labelText: 'Parish',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              items: JamaicaParishes.parishes.map((parish) {
                return DropdownMenuItem(
                  value: parish,
                  child: Text(parish),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedParish = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Postal code
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'Postal Code (Optional)',
                prefixIcon: Icon(Icons.markunread_mailbox_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Set as default
            SwitchListTile(
              title: const Text('Set as default address'),
              subtitle: const Text('Use this address for future orders'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Save button
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return ElevatedButton(
                  onPressed: auth.isLoading ? null : _saveAddress,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(isEditing ? 'Update Address' : 'Save Address'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
