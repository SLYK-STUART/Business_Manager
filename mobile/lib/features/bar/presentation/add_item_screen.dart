import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/category_provider.dart';
import '../domain/item_providers.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sellingController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '5');
  dynamic _selectedCategory;

  XFile? _photo;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sellingController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (picked != null) setState(() => _photo = picked);
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surfaceMuted,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textSecondaryOnLight, size: 20)
          : null,
      labelStyle: const TextStyle(
        color: AppColors.textSecondaryOnLight,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderOnLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderOnLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Add Item',
          style: TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnLight),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Photo picker ──────────────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: _pickPhoto,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _photo != null
                                    ? AppColors.primary.withOpacity(0.7)
                                    : AppColors.borderOnLight,
                                width: _photo != null ? 2 : 1.5,
                              ),
                            ),
                            child: _photo == null
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_rounded,
                                  size: 36,
                                  color: AppColors.textSecondaryOnLight,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add photo',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondaryOnLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                                : ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(_photo!.path),
                                fit: BoxFit.cover,
                                width: 140,
                                height: 140,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Item name ─────────────────────────────────────────
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          color: AppColors.textPrimaryOnLight,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _fieldDecoration(
                          label: 'Item name',
                          hint: 'e.g. Premium Coffee Beans',
                          prefixIcon: Icons.inventory_2_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter an item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Consumer(builder: (context, ref, _) {
                        final categoriesAsync = ref.watch(categoryListProvider);
                        return categoriesAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text("Failed to load categories: $e"),
                          data: (categories) => DropdownButtonFormField(
                            decoration: const InputDecoration(labelText: "Category (optional)"),
                            items: categories
                                .map<DropdownMenuItem>(
                                    (c) => DropdownMenuItem(value: c["id"], child: Text(c["name"])))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCategory = v),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // ── Selling price ───────────────────────────────────────
                      // Buying price is intentionally NOT collected here — it's
                      // set later by the Owner via the Pending Pricing screen,
                      // once the actual restock/crate cost is known.
                      TextFormField(
                        controller: _sellingController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        style: const TextStyle(
                          color: AppColors.textPrimaryOnLight,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _fieldDecoration(
                          label: 'Selling price',
                          hint: '0.00',
                          prefixIcon: Icons.sell_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Stock row ─────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(
                                color: AppColors.textPrimaryOnLight,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _fieldDecoration(
                                label: 'Starting stock',
                                hint: '0',
                                prefixIcon: Icons.layers_outlined,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (int.tryParse(v) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _thresholdController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(
                                color: AppColors.textPrimaryOnLight,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _fieldDecoration(
                                label: 'Low stock alert',
                                hint: '5',
                                prefixIcon: Icons.warning_amber_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (int.tryParse(v) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'You\u2019ll be notified when stock falls to or below this number.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryOnLight.withOpacity(0.85),
                          ),
                        ),
                      ),
                      if (int.tryParse(_stockController.text) != null &&
                          (int.tryParse(_stockController.text) ?? 0) > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: AppColors.info),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Buying price for this stock will be set by the owner shortly.',
                                  style: TextStyle(fontSize: 12, color: AppColors.info),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Sticky bottom button ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  border: Border(
                    top: BorderSide(color: AppColors.borderOnLight.withOpacity(0.6)),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                        : const Text(
                      'Add Item',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(itemRepositoryProvider).createItem(
        name: _nameController.text.trim(),
        buyingPrice: 0, // set later via Pending Pricing (Owner)
        sellingPrice: double.parse(_sellingController.text),
        currentStock: int.parse(_stockController.text),
        lowStockThreshold: int.parse(_thresholdController.text),
        photoPath: _photo?.path,
        categoryId: _selectedCategory,
      );
      ref.invalidate(itemListProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}