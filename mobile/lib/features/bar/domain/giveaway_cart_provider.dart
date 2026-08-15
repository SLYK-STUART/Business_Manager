import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class GiveawayLine {
  final String itemId;
  final String name;
  int quantity;
  GiveawayLine({required this.itemId, required this.name, this.quantity = 1});
}

class GiveawayCartNotifier extends StateNotifier<List<GiveawayLine>> {
  GiveawayCartNotifier() : super([]);

  void addOrUpdate(String itemId, String name, int quantity) {
    final idx = state.indexWhere((l) => l.itemId == itemId);
    if (idx >= 0) {
      state[idx].quantity = quantity;
      state = [...state];
    } else {
      state = [...state, GiveawayLine(itemId: itemId, name: name, quantity: quantity)];
    }
  }

  void remove(String itemId) => state = state.where((l) => l.itemId != itemId).toList();
  void clear() => state = [];
}

final giveawayCartProvider = StateNotifierProvider<GiveawayCartNotifier, List<GiveawayLine>>((ref) => GiveawayCartNotifier());