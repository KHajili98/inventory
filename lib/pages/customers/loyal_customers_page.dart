import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/core/utils/responsive.dart';
import 'package:inventory/features/loyal_customers/cubit/customers_cubit.dart';
import 'package:inventory/features/loyal_customers/cubit/customers_state.dart';
import 'package:inventory/features/loyal_customers/data/models/customer_model.dart';
import 'package:inventory/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page entry point
// ─────────────────────────────────────────────────────────────────────────────

class LoyalCustomersPage extends StatelessWidget {
  const LoyalCustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => CustomersCubit()..fetchCustomers(), child: const _LoyalCustomersView());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class _LoyalCustomersView extends StatefulWidget {
  const _LoyalCustomersView();

  @override
  State<_LoyalCustomersView> createState() => _LoyalCustomersViewState();
}

class _LoyalCustomersViewState extends State<_LoyalCustomersView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<CustomersCubit>().loadMore();
    }
  }

  void _openAddDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(value: context.read<CustomersCubit>(), child: const _CustomerFormDialog()),
    );
  }

  void _openEditDialog(CustomerModel customer) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<CustomersCubit>(),
        child: _CustomerFormDialog(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<CustomersCubit, CustomersState>(
      builder: (context, state) {
        final customers = state is CustomersLoaded ? state.customers : <CustomerModel>[];
        final totalCount = state is CustomersLoaded ? state.totalCount : 0;
        final isLoadingMore = state is CustomersLoaded && state.isLoadingMore;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Column(
            children: [
              // ── Header ───────────────────────────────────────────────────
              Container(
                padding: EdgeInsets.all(context.responsivePadding),
                color: const Color(0xFFF8FAFC),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.loyalCustomers,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 4),
                              Text(l10n.loyalCustomersSubtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        // Add customer button
                        ElevatedButton.icon(
                          onPressed: _openAddDialog,
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: Text(l10n.addCustomer),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => context.read<CustomersCubit>().refresh(),
                          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                          tooltip: l10n.refresh,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stats chip
                    _StatsChip(icon: Icons.people_rounded, label: l10n.totalCustomers, value: '$totalCount', color: const Color(0xFF6366F1)),
                    const SizedBox(height: 16),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => context.read<CustomersCubit>().searchDebounced(v),
                        decoration: InputDecoration(
                          hintText: l10n.searchCustomers,
                          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<CustomersCubit>().fetchCustomers();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Customer list ─────────────────────────────────────────────
              Expanded(
                child: switch (state) {
                  CustomersLoading() => const Center(child: CircularProgressIndicator()),
                  CustomersError(:final message) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.read<CustomersCubit>().refresh(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(l10n.retry),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ =>
                    customers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(l10n.noCustomersFound, style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(horizontal: context.responsivePadding, vertical: 8),
                            itemCount: customers.length + (isLoadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == customers.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              return _CustomerCard(customer: customers[i], onEdit: () => _openEditDialog(customers[i]));
                            },
                          ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatsChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatsChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer card
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onEdit;

  const _CustomerCard({required this.customer, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = customer.createdAt != null ? DateFormat('dd MMM yyyy, HH:mm').format(customer.createdAt!.toLocal()) : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(
                  _initials(customer.name, customer.surname),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.fullName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ),
                      // Discount badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Text(
                          '${customer.discountPercentage.toStringAsFixed(customer.discountPercentage % 1 == 0 ? 0 : 1)}% ${l10n.discount}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Phone & loyalty ID row
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _InfoChip(icon: Icons.phone_rounded, text: customer.phoneNumber),
                      _InfoChip(icon: Icons.loyalty_rounded, text: '${l10n.loyaltyId}: ${customer.loyaltyId}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Edit button
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 18),
              tooltip: l10n.edit,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.08),
                foregroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name, String surname) {
    final n = name.trim();
    final s = surname.trim();
    final first = n.isNotEmpty ? n[0].toUpperCase() : '';
    final second = s.isNotEmpty ? s[0].toUpperCase() : '';
    return '$first$second';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit customer dialog
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerFormDialog extends StatefulWidget {
  /// Pass a customer to edit; null for create.
  final CustomerModel? customer;

  const _CustomerFormDialog({this.customer});

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _surnameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _loyaltyIdCtrl;
  late final TextEditingController _discountCtrl;

  bool _isSubmitting = false;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _surnameCtrl = TextEditingController(text: c?.surname ?? '');
    _phoneCtrl = TextEditingController(text: c?.phoneNumber ?? '');
    _loyaltyIdCtrl = TextEditingController(text: c?.loyaltyId ?? '');
    _discountCtrl = TextEditingController(
      text: c != null ? (c.discountPercentage % 1 == 0 ? c.discountPercentage.toInt().toString() : c.discountPercentage.toString()) : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _phoneCtrl.dispose();
    _loyaltyIdCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final cubit = context.read<CustomersCubit>();
    final name = _nameCtrl.text.trim();
    final surname = _surnameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final loyaltyId = _loyaltyIdCtrl.text.trim();
    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;

    ApiResult<CustomerModel> result;

    if (_isEditing) {
      result = await cubit.updateCustomer(
        id: widget.customer!.id,
        name: name,
        surname: surname,
        phoneNumber: phone,
        loyaltyId: loyaltyId,
        discountPercentage: discount,
      );
    } else {
      result = await cubit.createCustomer(name: name, surname: surname, phoneNumber: phone, loyaltyId: loyaltyId, discountPercentage: discount);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_isEditing ? l10n.customerUpdated : l10n.customerCreated), backgroundColor: const Color(0xFF10B981)));
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: const Color(0xFFEF4444)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.person_rounded, size: 20, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? l10n.editCustomer : l10n.addCustomer,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 20),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _FormField(
                            controller: _nameCtrl,
                            label: l10n.firstName,
                            hint: l10n.firstNameHint,
                            icon: Icons.person_outline_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FormField(
                            controller: _surnameCtrl,
                            label: l10n.lastName,
                            hint: l10n.lastNameHint,
                            icon: Icons.person_outline_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: _phoneCtrl,
                      label: l10n.phoneNumber,
                      hint: '+994XXXXXXXXX',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: _loyaltyIdCtrl,
                      label: l10n.loyaltyId,
                      hint: '00000001',
                      icon: Icons.loyalty_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      controller: _discountCtrl,
                      label: l10n.discountPercentage,
                      hint: '0',
                      icon: Icons.percent_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return l10n.fieldRequired;
                        final d = double.tryParse(v.trim());
                        if (d == null) return l10n.invalidNumber;
                        if (d < 0 || d > 100) return l10n.discountRange;
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? l10n.saveChanges : l10n.addCustomer),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable form field
// ─────────────────────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFCBD5E1)),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
