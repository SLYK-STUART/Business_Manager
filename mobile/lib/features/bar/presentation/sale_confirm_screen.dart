import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart'; // adjust path if needed
import '../domain/cart_provider.dart';

const _paper = Color(0xFFF3EFE7); // warm receipt-paper background
const _paperLine = Color(0xFFE3DDD2); // dashed divider on paper

class SaleConfirmScreen extends ConsumerStatefulWidget {
  const SaleConfirmScreen({super.key});

  @override
  ConsumerState<SaleConfirmScreen> createState() => _SaleConfirmScreenState();
}

class _SaleConfirmScreenState extends ConsumerState<SaleConfirmScreen> {
  bool _submitting = false;

  String _now() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(n.day)}/${two(n.month)}/${n.year}  ${two(n.hour)}:${two(n.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).total;
    final subtotal = cart.fold<double>(0, (s, l) => s + (l.unitPrice * l.quantity));
    final discountTotal = cart.fold<double>(0, (s, l) => s + l.discount);

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Confirm Sale',
          style: TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnLight),
      ),
      body: Column(
        children: [
          // ── Receipt ──────────────────────────────────────────────────────
          Expanded(
            child: cart.isEmpty
                ? const Center(
              child: Text(
                'Cart is empty',
                style: TextStyle(color: AppColors.textSecondaryOnLight),
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: ClipPath(
                clipper: _ReceiptEdgeClipper(),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'SALE RECEIPT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: AppColors.textPrimaryOnLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _now(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryOnLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _DashedDivider(),
                      const SizedBox(height: 4),
                      for (final line in cart) ...[
                        _ReceiptLineRow(
                          line: line,
                          onRemove: () => _removeLine(context, line),
                        ),
                        const _DashedDivider(),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryOnLight,
                            ),
                          ),
                          Text(
                            'UGX ${subtotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryOnLight,
                            ),
                          ),
                        ],
                      ),
                      if (discountTotal > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Discounts',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.error,
                              ),
                            ),
                            Text(
                              '− UGX ${discountTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom summary panel ─────────────────────────────────────────
          if (cart.isNotEmpty)
            ClipPath(
              clipper: _ReceiptEdgeClipper(bottom: false),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondaryOnLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${cart.length} item${cart.length == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryOnLight.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'UGX ${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryOnLight,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _confirmSale,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              disabledBackgroundColor: AppColors.primary.withOpacity(0.45),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                                : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Confirm & Store Sale',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _removeLine(BuildContext context, CartLine line) {
    final notifier = ref.read(cartProvider.notifier);
    notifier.remove(line.itemId);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${line.name}'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.primary,
          onPressed: () {
            notifier.addOrUpdate(line.itemId, line.name, line.unitPrice, line.quantity);
            if (line.discount > 0) {
              notifier.setDiscount(line.itemId, line.discount);
            }
          },
        ),
      ),
    );
  }

  Future<void> _confirmSale() async {
    setState(() => _submitting = true);
    try {
      final cart = ref.read(cartProvider);
      final lineItems = cart
          .map((l) => {
        "item_id": l.itemId,
        "quantity": l.quantity,
        "discount_amount": l.discount,
        "payment_status": "paid_full",
      })
          .toList();

      await ref.read(saleRepositoryProvider).createSale(lineItems);
      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        Navigator.of(context).popUntil(
              (route) => route.settings.name == "/sell" || route.isFirst,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale recorded successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

// ── Receipt line row (swipe-to-remove + tap-to-remove) ─────────────────────

class _ReceiptLineRow extends StatelessWidget {
  final CartLine line;
  final VoidCallback onRemove;

  const _ReceiptLineRow({required this.line, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(line.itemId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          line.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryOnLight,
                          ),
                        ),
                      ),
                      Text(
                        'UGX ${line.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOnLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${line.quantity} × UGX ${line.unitPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondaryOnLight,
                        ),
                      ),
                      if (line.discount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '− UGX ${line.discount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(top: 1),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: AppColors.textSecondaryOnLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashed divider ───────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dashWidth + gap)).floor();
        return SizedBox(
          height: 1,
          child: Row(
            children: List.generate(
              count,
                  (_) => Padding(
                padding: const EdgeInsets.only(right: gap),
                child: Container(width: dashWidth, height: 1, color: _paperLine),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Torn-paper zigzag edge clipper ──────────────────────────────────────

class _ReceiptEdgeClipper extends CustomClipper<Path> {
  final bool top;
  final bool bottom;
  final double toothWidth;
  final double toothDepth;

  const _ReceiptEdgeClipper({
    this.top = true,
    this.bottom = true,
    this.toothWidth = 14,
    this.toothDepth = 7,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    if (top) {
      path.moveTo(0, toothDepth);
      double x = 0;
      bool down = true;
      while (x < size.width) {
        final nextX = (x + toothWidth).clamp(0.0, size.width);
        path.lineTo(nextX, down ? 0 : toothDepth);
        down = !down;
        x = nextX;
      }
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
    }

    if (bottom) {
      path.lineTo(size.width, size.height - toothDepth);
      double x = size.width;
      bool down = true;
      while (x > 0) {
        final nextX = (x - toothWidth).clamp(0.0, size.width);
        path.lineTo(nextX, down ? size.height : size.height - toothDepth);
        down = !down;
        x = nextX;
      }
    } else {
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}