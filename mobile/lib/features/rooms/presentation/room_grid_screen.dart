import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/room_providers.dart';

class RoomGridScreen extends ConsumerStatefulWidget {
  const RoomGridScreen({super.key});

  @override
  ConsumerState<RoomGridScreen> createState() => _RoomGridScreenState();
}

class _RoomGridScreenState extends ConsumerState<RoomGridScreen> {
  String _filter = 'all'; // all | occupied | free

  String _formatDuration(DateTime checkin) {
    final diff = DateTime.now().difference(checkin);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day} at ${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomListProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: roomsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Failed: $e', style: const TextStyle(color: AppColors.error)),
        ),
        data: (rooms) {
          final freeCount = rooms.where((r) => r['status'] != 'occupied').length;
          final total = rooms.length;
          final occupiedCount = total - freeCount;
          final occupancy = total == 0 ? 0.0 : occupiedCount / total;

          final filtered = rooms.where((r) {
            if (_filter == 'occupied') return r['status'] == 'occupied';
            if (_filter == 'free') return r['status'] != 'occupied';
            return true;
          }).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(roomListProvider),
            child: CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Rooms',
                                style: TextStyle(
                                  color: AppColors.textPrimaryOnLight,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.borderOnLight),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$freeCount free',
                                      style: const TextStyle(
                                        color: AppColors.textSecondaryOnLight,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Gold underline
                          Container(
                            width: 48,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Occupancy
                          Text(
                            '${(occupancy * 100).toStringAsFixed(0)}% occupancy · $total rooms total',
                            style: const TextStyle(
                              color: AppColors.textSecondaryOnLight,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: occupancy,
                              minHeight: 4,
                              backgroundColor: AppColors.borderOnLight,
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Filter tabs
                          Row(
                            children: [
                              _FilterTab(
                                label: 'All Rooms',
                                selected: _filter == 'all',
                                onTap: () => setState(() => _filter = 'all'),
                              ),
                              const SizedBox(width: 20),
                              _FilterTab(
                                label: 'Occupied',
                                selected: _filter == 'occupied',
                                onTap: () => setState(() => _filter = 'occupied'),
                              ),
                              const SizedBox(width: 20),
                              _FilterTab(
                                label: 'Free',
                                selected: _filter == 'free',
                                onTap: () => setState(() => _filter = 'free'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Room grid ─────────────────────────────────────────────
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No rooms found',
                        style: TextStyle(color: AppColors.textSecondaryOnLight),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.92,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, i) {
                          final room = filtered[i];
                          final occupied = room['status'] == 'occupied';
                          final checkinTime = room['checkin_time'] != null
                              ? DateTime.tryParse(room['checkin_time'].toString())
                              : null;

                          return _RoomCard(
                            room: room,
                            occupied: occupied,
                            checkinTime: checkinTime,
                            formatDuration: _formatDuration,
                            onTap: () {
                              if (occupied) {
                                _showCheckoutSheet(context, ref, room, checkinTime);
                              } else {
                                _showCheckinSheet(context, ref, room);
                              }
                            },
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Check-in sheet ────────────────────────────────────────────────────────
  void _showCheckinSheet(BuildContext context, WidgetRef ref, dynamic room) {
    int nights = 1;
    final discountController = TextEditingController(text: '0');
    final guestController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final rate = double.tryParse(room['nightly_rate'].toString()) ?? 0;
          final discount = double.tryParse(discountController.text) ?? 0;
          final total = (rate * nights) - discount;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gold header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Room ${room['name']}',
                              style: const TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${room['room_type'] ?? 'Standard'} · UGX ${room['nightly_rate']}/night',
                              style: TextStyle(
                                color: AppColors.textOnPrimary.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textOnPrimary),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHECK IN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondaryOnLight,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: guestController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Guest name (optional)',
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Number of nights',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryOnLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _StepperButton(
                            icon: Icons.remove_rounded,
                            onTap: () => setSheetState(() => nights = nights > 1 ? nights - 1 : 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text(
                              '$nights',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryOnLight,
                              ),
                            ),
                          ),
                          _StepperButton(
                            icon: Icons.add_rounded,
                            onTap: () => setSheetState(() => nights++),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '= UGX ${total.toStringAsFixed(0)} total',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOnLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      TextField(
                        controller: discountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Discount (UGX)',
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () async {
                            await ref.read(roomRepositoryProvider).checkin(
                              room['id'],
                              nights,
                              double.tryParse(discountController.text) ?? 0,
                            );
                            ref.invalidate(roomListProvider);
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Confirm Check-In · UGX ${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Check-out sheet ───────────────────────────────────────────────────────
  void _showCheckoutSheet(
      BuildContext context,
      WidgetRef ref,
      dynamic room,
      DateTime? checkinTime,
      ) async {
    final bookings = await ref.read(roomRepositoryProvider).getBookings();
    final activeBooking = bookings.firstWhere(
          (b) => b['room'] == room['id'] && b['status'] == 'active',
      orElse: () => null,
    );

    if (!context.mounted || activeBooking == null) return;

    final nights = activeBooking['nights'] ?? 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${room['name']}',
                          style: const TextStyle(
                            color: AppColors.textPrimaryOnLight,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${room['room_type'] ?? 'Standard'} · UGX ${room['nightly_rate']}/night',
                          style: const TextStyle(
                            color: AppColors.textSecondaryOnLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryOnLight),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHECK OUT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondaryOnLight,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _InfoBlock(
                          label: 'GUEST',
                          value: activeBooking['guest_name']?.toString() ?? '—',
                        ),
                      ),
                      Expanded(
                        child: _InfoBlock(
                          label: 'STAY',
                          value: '$nights night${nights == 1 ? '' : 's'}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoBlock(
                          label: 'CHECK-IN',
                          value: checkinTime != null ? _formatDateTime(checkinTime) : '—',
                        ),
                      ),
                      Expanded(
                        child: _InfoBlock(
                          label: 'TIME IN ROOM',
                          value: checkinTime != null ? _formatDuration(checkinTime) : '—',
                          valueColor: AppColors.primary,
                          showClock: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.borderOnLight),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount paid',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondaryOnLight,
                        ),
                      ),
                      Text(
                        'UGX ${activeBooking['amount_paid']}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryOnLight,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(roomRepositoryProvider).checkout(activeBooking['id']);
                        ref.invalidate(roomListProvider);
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Confirm Check-Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Room will be marked available immediately',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryOnLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ─────────────────────────────────────────────────────────────────

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondaryOnLight,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          if (selected)
            Container(
              width: 24,
              height: 2.5,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 2.5),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final dynamic room;
  final bool occupied;
  final DateTime? checkinTime;
  final String Function(DateTime) formatDuration;
  final VoidCallback onTap;

  const _RoomCard({
    required this.room,
    required this.occupied,
    required this.checkinTime,
    required this.formatDuration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: occupied ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: occupied ? const Color(0xFF2A2A2A) : AppColors.borderOnLight,
          ),
          boxShadow: occupied
              ? null
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${room['name']}',
              style: TextStyle(
                color: occupied ? Colors.white : AppColors.textPrimaryOnLight,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              (room['room_type'] ?? 'STANDARD').toString().toUpperCase(),
              style: TextStyle(
                color: occupied ? Colors.white38 : AppColors.textSecondaryOnLight,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            if (occupied && checkinTime != null) ...[
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    formatDuration(checkinTime!),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (room['guest_name'] != null) ...[
                const SizedBox(height: 2),
                Text(
                  room['guest_name'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ] else ...[
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'FREE',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderOnLight),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimaryOnLight),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool showClock;

  const _InfoBlock({
    required this.label,
    required this.value,
    this.valueColor,
    this.showClock = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryOnLight,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (showClock) ...[
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textPrimaryOnLight,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}