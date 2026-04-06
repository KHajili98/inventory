import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory/core/network/api_result.dart';
import 'package:inventory/features/auth/auth_cubit.dart';
import 'package:inventory/features/inventory_products/data/models/inventory_model.dart';
import 'package:inventory/features/inventory_products/data/repositories/inventory_repository.dart';
import 'package:inventory/l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  List<InventoryModel> _inventories = [];
  InventoryModel? _selectedInventory;
  bool _loadingInventories = true;
  String? _inventoriesError;

  @override
  void initState() {
    super.initState();
    _usernameController.text = "Suphan";
    _passwordController.text = "SecurePass123!";
    _fetchInventories();
  }

  Future<void> _fetchInventories() async {
    setState(() {
      _loadingInventories = true;
      _inventoriesError = null;
    });
    final result = await InventoryRepository.instance.fetchInventories(pageSize: 200);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _inventories = data.results;
          _selectedInventory = data.results.isNotEmpty ? data.results.first : null;
          _loadingInventories = false;
        });
      case Failure(:final message):
        setState(() {
          _inventoriesError = message;
          _loadingInventories = false;
        });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInventory == null) return;
    context.read<AuthCubit>().login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      loggedInInventoryId: _selectedInventory!.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 700;
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/invoices');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.message, style: const TextStyle(fontSize: 14))),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 440 : double.infinity),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Logo ────────────────────────────────────────────────
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.widgets_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 24),

                    // ── Heading ──────────────────────────────────────────────
                    Text(
                      l10n.welcomeBack,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 6),
                    Text(l10n.signInSubtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    const SizedBox(height: 36),

                    // ── Card ─────────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Username
                            _FieldLabel(label: l10n.usernameLabel),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                              decoration: _inputDecoration(hint: l10n.enterUsername, prefixIcon: Icons.person_outline_rounded),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return l10n.usernameRequired;
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password
                            _FieldLabel(label: l10n.passwordLabel),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _onLogin(),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                              decoration: _inputDecoration(
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  splashRadius: 18,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return l10n.passwordRequired;
                                if (v.length < 6) return l10n.passwordMinLength;
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Inventory
                            _FieldLabel(label: l10n.inventoryLabel),
                            const SizedBox(height: 6),
                            _InventoryDropdown(
                              inventories: _inventories,
                              selected: _selectedInventory,
                              isLoading: _loadingInventories,
                              error: _inventoriesError,
                              onRetry: _fetchInventories,
                              onChanged: (v) => setState(() => _selectedInventory = v),
                            ),
                            const SizedBox(height: 28),

                            // Submit button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _onLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                child: isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : Text(l10n.signIn),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outlined, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 5),
                        Text(l10n.securedConnection, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      prefixIcon: Icon(prefixIcon, size: 18, color: const Color(0xFF94A3B8)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
    );
  }
}

class _InventoryDropdown extends StatelessWidget {
  final List<InventoryModel> inventories;
  final InventoryModel? selected;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<InventoryModel?> onChanged;

  const _InventoryDropdown({
    required this.inventories,
    required this.selected,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLoading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1))),
        ),
      );
    }

    if (error != null) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEF4444)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(error!, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 36)),
              child: Text(l10n.retry, style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1))),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<InventoryModel>(
      initialValue: selected,
      isExpanded: true,
      icon: const Icon(Icons.unfold_more_rounded, size: 18, color: Color(0xFF94A3B8)),
      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: l10n.selectAnInventory,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        prefixIcon: const Icon(Icons.warehouse_outlined, size: 18, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
      ),
      items: inventories
          .map(
            (inv) => DropdownMenuItem<InventoryModel>(
              value: inv,
              child: Text(inv.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? l10n.pleaseSelectAnInventory : null,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
    );
  }
}
