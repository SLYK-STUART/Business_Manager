import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/item_providers.dart';

class RestockScreen extends ConsumerStatefulWidget {
  const RestockScreen({super.key});

  @override
  ConsumerState<RestockScreen> createState() => _RestockScreenState();
}

/// A single queued restock entry, waiting to be submitted.
class _RestockQueueEntry {
  final dynamic item;
  final String mode; // 'unit' | 'bulk'
  final int quantity;

  _RestockQueueEntry({
    required this.item,
    required this.mode,
    required this.quantity,
  });

  String get itemId => item['id'].toString();
  String get itemName => item['name'] ?? 'Unnamed';
}

class _RestockScreenState extends ConsumerState<RestockScreen> {
  dynamic _selectedItem;
  String _mode = 'unit'; // 'unit' | 'bulk'

  final _qtyController = TextEditingController();
  final _cratesController = TextEditingController();
  final _unitsPerController = TextEditingController();

  bool _submitting = false;

  final List<_RestockQueueEntry> _queue = [];

  @override
  void dispose() {
    _qtyController.dispose();
    _cratesController.dispose();
    _unitsPerController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  int get _crates => int.tryParse(_cratesController.text) ?? 0;
  int get _unitsPer => int.tryParse(_unitsPerController.text) ?? 0;
  int get _totalUnits => _crates * _unitsPer;

  bool _isLowStock(dynamic item) {
    final stock = (item['current_stock'] as num?) ?? 0;
    final threshold = (item['low_stock_threshold'] as num?) ?? 0;
    return stock <= threshold;
  }

  bool _isInQueue(dynamic item) {
    final id = item['id'].toString();
    return _queue.any((e) => e.itemId == id);
  }

  _RestockQueueEntry? _queueEntryFor(dynamic item) {
    final id = item['id'].toString();
    try {
      return _queue.firstWhere((e) => e.itemId == id);
    } catch (_) {
      return null;
    }
  }

  void _clearEntryFields() {
    _qtyController.clear();
    _cratesController.clear();
    _unitsPerController.clear();
  }

  /// Select an item. If it's already in the queue, pre-fill the quantity
  /// so the user can edit it instead of stacking a new amount.
  void _selectItem(dynamic item) {
    final existing = _queueEntryFor(item);

    setState(() {
      _selectedItem = item;

      if (existing != null) {
        // Prefill so the user can change the already-queued amount
        _mode = existing.mode;
        if (existing.mode == 'unit') {
          _qtyController.text = existing.quantity.toString();
          _cratesController.clear();
          _unitsPerController.clear();
        } else {
          // Bulk: we only stored total units, so put it in the unit field
          // and switch to unit mode for easy editing.
          _mode = 'unit';
          _qtyController.text = existing.quantity.toString();
          _cratesController.clear();
          _unitsPerController.clear();
        }
      } else {
        _clearEntryFields();
      }
    });
  }

  void _addToQueue() {
    if (_selectedItem == null) return;

    final int quantity;
    if (_mode == 'unit') {
      if (_qtyController.text.isEmpty) return;
      quantity = int.tryParse(_qtyController.text) ?? 0;
    } else {
      if (_crates <= 0 || _unitsPer <= 0) return;
      quantity = _totalUnits;
    }
    if (quantity <= 0) return;

    final itemId = _selectedItem['id'].toString();
    final existingIndex = _queue.indexWhere((e) => e.itemId == itemId);

    setState(() {
      if (existingIndex != -1) {
        // Replace the existing entry with the new (edited) quantity
        _queue[existingIndex] = _RestockQueueEntry(
          item: _selectedItem,
          mode: _mode,
          quantity: quantity,
        );
      } else {
        _queue.add(_RestockQueueEntry(
          item: _selectedItem,
          mode: _mode,
          quantity: quantity,
        ));
      }
      _selectedItem = null;
      _clearEntryFields();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existingIndex != -1
              ? 'Updated quantity in restock list'
              : 'Added — pick the next item',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _removeFromQueue(int index) {
    setState(() => _queue.removeAt(index));
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    bool readOnly = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: readOnly
          ? AppColors.surfaceMuted.withOpacity(0.6)
          : AppColors.surfaceMuted,
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderOnLight),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemListProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Restock',
          style: TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnLight),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Item selector ───────────────────────────────────────
                    itemsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      ),
                      error: (e, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Failed to load items: $e',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      data: (items) {
                        // Low-stock items: not-in-queue first, then already-queued at the end
                        final lowStockItems = items.where(_isLowStock).toList();
                        lowStockItems.sort((a, b) {
                          final aIn = _isInQueue(a);
                          final bIn = _isInQueue(b);
                          if (aIn == bIn) return 0;
                          return aIn ? 1 : -1; // queued ones go to the end
                        });

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField(
                              value: _selectedItem,
                              decoration: _fieldDecoration(
                                label: 'Select item',
                                prefixIcon: Icons.inventory_2_outlined,
                              ),
                              dropdownColor: AppColors.surfaceLight,
                              style: const TextStyle(
                                color: AppColors.textPrimaryOnLight,
                                fontWeight: FontWeight.w500,
                              ),
                              items: items
                                  .map<DropdownMenuItem>(
                                    (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(i['name'] ?? 'Unnamed'),
                                ),
                              )
                                  .toList(),
                              onChanged: (v) => _selectItem(v),
                            ),

                            // ── Low stock quick-pick cards ─────────────────
                            if (lowStockItems.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  const Icon(Icons.bolt_rounded,
                                      size: 16, color: AppColors.warning),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Low stock — tap to restock quickly',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondaryOnLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 100,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: lowStockItems.length,
                                  separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                                  itemBuilder: (context, i) {
                                    final item = lowStockItems[i];
                                    final isSelected = _selectedItem != null &&
                                        _selectedItem['id'] == item['id'];
                                    final alreadyQueued = _isInQueue(item);
                                    final stock =
                                        (item['current_stock'] as num?) ?? 0;
                                    final isOut = stock <= 0;
                                    final accent = alreadyQueued
                                        ? AppColors.success
                                        : (isOut
                                        ? AppColors.error
                                        : AppColors.warning);

                                    return GestureDetector(
                                      onTap: () => _selectItem(item),
                                      child: Container(
                                        width: 132,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? accent.withOpacity(0.12)
                                              : (alreadyQueued
                                              ? AppColors.success
                                              .withOpacity(0.06)
                                              : Colors.white),
                                          borderRadius:
                                          BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isSelected || alreadyQueued
                                                ? accent
                                                : AppColors.borderOnLight,
                                            width: isSelected || alreadyQueued
                                                ? 1.6
                                                : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                              Colors.black.withOpacity(0.03),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  alreadyQueued
                                                      ? Icons.check_circle_rounded
                                                      : (isOut
                                                      ? Icons
                                                      .remove_circle_outline_rounded
                                                      : Icons
                                                      .warning_amber_rounded),
                                                  size: 15,
                                                  color: accent,
                                                ),
                                                const Spacer(),
                                                if (isSelected && !alreadyQueued)
                                                  Icon(Icons.check_circle_rounded,
                                                      size: 15, color: accent),
                                              ],
                                            ),
                                            const Spacer(),
                                            Text(
                                              item['name'] ?? 'Unnamed',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors
                                                    .textPrimaryOnLight,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              alreadyQueued
                                                  ? 'In list · ${_queueEntryFor(item)?.quantity ?? 0} units'
                                                  : (isOut
                                                  ? 'Out of stock'
                                                  : '$stock left'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: accent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Mode selector ───────────────────────────────────────
                    Text(
                      'How is this stock counted?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryOnLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'unit',
                          label: Text('Units'),
                          icon: Icon(Icons.looks_one_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: 'bulk',
                          label: Text('Crate / Packet'),
                          icon: Icon(Icons.inventory_outlined, size: 18),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) =>
                          setState(() => _mode = s.first),
                      style: ButtonStyle(
                        backgroundColor:
                        WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          return AppColors.surfaceMuted;
                        }),
                        foregroundColor:
                        WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.textOnPrimary;
                          }
                          return AppColors.textSecondaryOnLight;
                        }),
                        side: WidgetStateProperty.all(
                          const BorderSide(color: AppColors.borderOnLight),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── UNIT MODE ───────────────────────────────────────────
                    if (_mode == 'unit') ...[
                      TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(
                          color: AppColors.textPrimaryOnLight,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _fieldDecoration(
                          label: 'Quantity',
                          hint: 'e.g. 24',
                          prefixIcon: Icons.numbers_rounded,
                        ),
                      ),
                    ],

                    // ── BULK / CRATE MODE ───────────────────────────────────
                    if (_mode == 'bulk') ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cratesController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                color: AppColors.textPrimaryOnLight,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _fieldDecoration(
                                label: 'Crates / Packets',
                                hint: 'e.g. 5',
                                prefixIcon: Icons.inventory_2_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _unitsPerController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                color: AppColors.textPrimaryOnLight,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _fieldDecoration(
                                label: 'Units per crate',
                                hint: 'e.g. 24',
                                prefixIcon: Icons.grid_view_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        enabled: false,
                        controller: TextEditingController(
                          text: _totalUnits > 0 ? _totalUnits.toString() : '',
                        ),
                        style: const TextStyle(
                          color: AppColors.textPrimaryOnLight,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _fieldDecoration(
                          label: 'Total units (auto)',
                          hint: '—',
                          prefixIcon: Icons.calculate_outlined,
                          readOnly: true,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── Add / Update button ─────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed:
                        _selectedItem == null ? null : _addToQueue,
                        icon: Icon(
                          _selectedItem != null && _isInQueue(_selectedItem)
                              ? Icons.edit_rounded
                              : Icons.playlist_add_rounded,
                          size: 20,
                        ),
                        label: Text(
                          _selectedItem != null && _isInQueue(_selectedItem)
                              ? 'Update restock list'
                              : 'Add to restock list',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          side: const BorderSide(
                              color: AppColors.primary, width: 1.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: AppColors.info),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Buying price is set separately by the owner once the cost is known.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Restock list ────────────────────────────────────────
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Text(
                          'Restock list',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryOnLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_queue.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_queue.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_queue.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                          border:
                          Border.all(color: AppColors.borderOnLight),
                        ),
                        child: Text(
                          'No items added yet',
                          style: TextStyle(
                              color: AppColors.textSecondaryOnLight),
                        ),
                      )
                    else
                      ...List.generate(_queue.length, (index) {
                        final entry = _queue[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border:
                            Border.all(color: AppColors.borderOnLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color:
                                  AppColors.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.add_box_rounded,
                                  size: 17,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.itemName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: AppColors.textPrimaryOnLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.mode == 'bulk'
                                          ? '${entry.quantity} units (crate/packet)'
                                          : '${entry.quantity} units',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors
                                            .textSecondaryOnLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Tap row to edit
                              IconButton(
                                onPressed: () => _selectItem(entry.item),
                                icon: const Icon(Icons.edit_rounded,
                                    size: 18),
                                color: AppColors.textSecondaryOnLight,
                                splashRadius: 20,
                                tooltip: 'Edit quantity',
                              ),
                              IconButton(
                                onPressed: () => _removeFromQueue(index),
                                icon: const Icon(Icons.close_rounded,
                                    size: 18),
                                color: AppColors.textSecondaryOnLight,
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // ── Sticky bottom button ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(
                      color: AppColors.borderOnLight.withOpacity(0.6)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                  (_submitting || _queue.isEmpty) ? null : _submitAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    disabledBackgroundColor:
                    AppColors.primary.withOpacity(0.4),
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
                      : Text(
                    _queue.isEmpty
                        ? 'Add items to restock list'
                        : 'Restock ${_queue.length} item${_queue.length == 1 ? '' : 's'}',
                    style: const TextStyle(
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
    );
  }

  Future<void> _submitAll() async {
    if (_queue.isEmpty) return;

    setState(() => _submitting = true);

    final repo = ref.read(itemRepositoryProvider);
    final failures = <String>[];

    for (final entry in List<_RestockQueueEntry>.from(_queue)) {
      try {
        await repo.restock(
          entry.itemId,
          mode: entry.mode,
          quantity: entry.quantity,
          unitPrice: null,
          totalPrice: null,
        );
      } catch (e) {
        failures.add(entry.itemName);
      }
    }

    ref.invalidate(itemListProvider);

    setState(() {
      _queue.removeWhere((e) => !failures.contains(e.itemName));
      _submitting = false;
    });

    if (!mounted) return;

    if (failures.isEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restocked — pending pricing from owner'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed for: ${failures.join(', ')}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}