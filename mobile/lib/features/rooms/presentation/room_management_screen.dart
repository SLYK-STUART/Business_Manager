import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/room_providers.dart';

class RoomManagementScreen extends ConsumerWidget {
  const RoomManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Manage Rooms',
          style: TextStyle(
            color: AppColors.textPrimaryOnLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryOnLight),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Room',
            onPressed: () => _showRoomSheet(context, ref),
          ),
        ],
      ),
      body: roomsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hotel_outlined,
                    size: 40,
                    color: AppColors.textSecondaryOnLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No rooms added yet',
                    style: TextStyle(
                      color: AppColors.textSecondaryOnLight,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _showRoomSheet(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Room'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(roomListProvider),
            child: ListView.builder(
              // Clearance for bottom nav
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: rooms.length,
              itemBuilder: (context, i) {
                final room = rooms[i];
                final occupied = room['status'] == 'occupied';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderOnLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: occupied
                              ? AppColors.warning.withOpacity(0.12)
                              : AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.bed_rounded,
                          size: 18,
                          color: occupied
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    room['name'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimaryOnLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: occupied
                                        ? AppColors.warning.withOpacity(0.12)
                                        : AppColors.success.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    occupied ? 'OCCUPIED' : 'FREE',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                      color: occupied
                                          ? AppColors.warning
                                          : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${room['room_type'] ?? 'Standard'}  ·  UGX ${room['nightly_rate']}/night',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryOnLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: AppColors.textSecondaryOnLight,
                        onPressed: () =>
                            _showRoomSheet(context, ref, room: room),
                      ),
                      // Delete only when free
                      if (!occupied)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.error,
                          onPressed: () =>
                              _confirmDeactivate(context, ref, room),
                        )
                      else
                        const SizedBox(width: 40), // keep alignment
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _confirmDeactivate(
      BuildContext context,
      WidgetRef ref,
      dynamic room,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Room',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'Remove ${room['name']} from active rooms? Past bookings stay in history.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryOnLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(roomRepositoryProvider)
                  .deactivateRoom(room['id']);
              ref.invalidate(roomListProvider);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomSheet(
      BuildContext context,
      WidgetRef ref, {
        dynamic room,
      }) {
    final isEdit = room != null;
    final nameController =
    TextEditingController(text: isEdit ? room['name'] : '');
    final typeController = TextEditingController(
      text: isEdit ? (room['room_type'] ?? 'Standard') : 'Standard',
    );
    final rateController = TextEditingController(
      text: isEdit ? room['nightly_rate'].toString() : '',
    );
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 70),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                  Text(
                    isEdit ? 'Edit Room' : 'Add Room',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryOnLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sheetField(
                    controller: nameController,
                    label: 'Room name / number',
                  ),
                  const SizedBox(height: 12),
                  _sheetField(
                    controller: typeController,
                    label: 'Room type (e.g. Standard, Deluxe)',
                  ),
                  const SizedBox(height: 12),
                  _sheetField(
                    controller: rateController,
                    label: 'Nightly rate (UGX)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                        if (nameController.text.trim().isEmpty ||
                            rateController.text.trim().isEmpty) {
                          return;
                        }
                        setSheetState(() => submitting = true);
                        try {
                          final repo =
                          ref.read(roomRepositoryProvider);
                          if (isEdit) {
                            await repo.updateRoom(
                              room['id'],
                              name: nameController.text.trim(),
                              roomType: typeController.text.trim(),
                              nightlyRate: double.parse(
                                rateController.text.trim(),
                              ),
                            );
                          } else {
                            await repo.createRoom(
                              nameController.text.trim(),
                              typeController.text.trim(),
                              double.parse(
                                rateController.text.trim(),
                              ),
                            );
                          }
                          ref.invalidate(roomListProvider);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed: $e'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } finally {
                          setSheetState(() => submitting = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: submitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                          : Text(
                        isEdit ? 'Save Changes' : 'Add Room',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimaryOnLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surfaceMuted,
        labelStyle: const TextStyle(
          color: AppColors.textSecondaryOnLight,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}