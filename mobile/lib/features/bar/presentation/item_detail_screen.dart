import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/item_providers.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  Future<Map<String, dynamic>>? _detailFuture;
  bool _editing = false;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _thresholdController = TextEditingController();
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _detailFuture = ref.read(itemRepositoryProvider).getItemDetail(widget.itemId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceMuted,
      labelStyle: const TextStyle(
        color: AppColors.textSecondaryOnLight,
        fontWeight: FontWeight.w500,
      ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final item = snapshot.data!['item'];
          final history = snapshot.data!['history'];
          final restocks = history['restocks'] as List? ?? [];
          final sales = history['recent_sales'] as List? ?? [];
          final priceHistory = history['price_history'] as List?;

          if (_editing) {
            _nameController.text = item['name'] ?? '';
            _priceController.text = item['selling_price'].toString();
            _thresholdController.text = item['low_stock_threshold'].toString();
          }

          final photoUrl = item['photo_url'];
          final hasPhoto = photoUrl != null && photoUrl.toString().isNotEmpty;
          final lowStock = (item['current_stock'] as num) <=
              (item['low_stock_threshold'] as num);

          return CustomScrollView(
            slivers: [
              // ── App Bar ─────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: AppColors.surfaceLight,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: AppColors.textPrimaryOnLight,
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  item['name'] ?? 'Item Detail',
                  style: const TextStyle(
                    color: AppColors.textPrimaryOnLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    letterSpacing: -0.3,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _editing ? Icons.close_rounded : Icons.edit_outlined,
                      color: AppColors.textPrimaryOnLight,
                    ),
                    onPressed: () => setState(() => _editing = !_editing),
                  ),
                ],
              ),

              // ── Content ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Photo ───────────────────────────────────────────
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              height: 220,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.borderOnLight),
                              ),
                              child: hasPhoto
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _photoPlaceholder(),
                                ),
                              )
                                  : _photoPlaceholder(),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () => _showPhotoSourceSheet(item['id']),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.camera_alt_outlined,
                                          size: 14, color: AppColors.textOnPrimary),
                                      SizedBox(width: 5),
                                      Text(
                                        'Edit photo',
                                        style: TextStyle(
                                          color: AppColors.textOnPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_uploadingPhoto)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (!_editing) ...[
                        // ── Name + Category ───────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item['name'] ?? 'Unnamed',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryOnLight,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            if (item['category'] != null)
                              Container(
                                margin: const EdgeInsets.only(left: 10, top: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  item['category'].toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondaryOnLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── Stock + Price ─────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'STOCK',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondaryOnLight,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '${item['current_stock']}',
                                        style: TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w800,
                                          color: lowStock
                                              ? AppColors.error
                                              : AppColors.textPrimaryOnLight,
                                          letterSpacing: -0.6,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'units',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: lowStock
                                              ? AppColors.error
                                              : AppColors.textSecondaryOnLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: AppColors.borderOnLight,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SELLING PRICE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondaryOnLight,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'UGX ${item['selling_price']}',
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimaryOnLight,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ── Action buttons ────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pushNamed('/restock'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textOnPrimary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Restock',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pushNamed('/sell'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textPrimaryOnLight,
                                    side: const BorderSide(
                                      color: AppColors.borderOnLight,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Sell',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // ── Edit form ─────────────────────────────────────
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryOnLight,
                          ),
                          decoration: _fieldDecoration('Name'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryOnLight,
                          ),
                          decoration: _fieldDecoration('Selling price'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _thresholdController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryOnLight,
                          ),
                          decoration: _fieldDecoration('Low stock threshold'),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saving ? null : () => _save(item['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.45),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                                : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // ── Restock History ─────────────────────────────────
                      _sectionTitle('RESTOCK HISTORY'),
                      const SizedBox(height: 8),
                      if (restocks.isEmpty)
                        _emptyState('No restocks yet')
                      else
                        ...restocks.map((r) => _historyTile(
                          icon: Icons.add_circle_outline_rounded,
                          iconColor: AppColors.success,
                          title: '+${r['quantity']} units',
                          subtitle: 'by ${r['restocked_by'] ?? 'Unknown'}',
                          trailing: _formatDate(r['timestamp']),
                        )),

                      const SizedBox(height: 18),

                      // ── Recent Sales ────────────────────────────────────
                      _sectionTitle('RECENT SALES'),
                      const SizedBox(height: 8),
                      if (sales.isEmpty)
                        _emptyState('No recent sales')
                      else
                        ...sales.map((s) => _historyTile(
                          icon: Icons.arrow_forward_rounded,
                          iconColor: AppColors.primary,
                          title: '${s['quantity']} sold',
                          subtitle: 'by ${s['sold_by'] ?? 'Unknown'}',
                          trailing: _formatDate(s['timestamp']),
                        )),

                      // ── Price History (optional) ────────────────────────
                      if (priceHistory != null && priceHistory.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionTitle('PRICE CHANGE HISTORY'),
                        const SizedBox(height: 8),
                        ...priceHistory.map((p) => _historyTile(
                          icon: Icons.swap_horiz_rounded,
                          iconColor: AppColors.info,
                          title:
                          'UGX ${p['old_price']} → UGX ${p['new_price']}',
                          subtitle: 'by ${p['changed_by'] ?? 'Unknown'}',
                          trailing: _formatDate(p['timestamp']),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Photo upload ─────────────────────────────────────────────────────────

  void _showPhotoSourceSheet(String itemId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderOnLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Update Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryOnLight,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto(itemId, ImageSource.camera);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto(itemId, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto(String itemId, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      await ref.read(itemRepositoryProvider).updateItemPhoto(itemId, picked.path);
      setState(() => _load());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _photoPlaceholder() {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 44,
        color: AppColors.textHint,
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondaryOnLight,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _historyTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOnLight),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimaryOnLight,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondaryOnLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryOnLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondaryOnLight.withOpacity(0.7),
          fontSize: 13,
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final str = timestamp.toString();
    return str.length >= 10 ? str.substring(0, 10) : str;
  }

  Future<void> _save(String itemId) async {
    setState(() => _saving = true);
    try {
      await ref.read(itemRepositoryProvider).updateItem(
        itemId,
        name: _nameController.text.trim(),
        sellingPrice: double.parse(_priceController.text),
        lowStockThreshold: int.parse(_thresholdController.text),
      );
      setState(() {
        _editing = false;
        _load();
      });
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
      if (mounted) setState(() => _saving = false);
    }
  }
}