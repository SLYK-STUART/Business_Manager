import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/sale_repository.dart';

class CartLine {
  final String itemId;
  final String name;
  final double unitPrice;
  int quantity;
  double discount;

  CartLine({required this.itemId, required this.name, required this.unitPrice, this.quantity = 1, this.discount = 0});

  double get total => (unitPrice * quantity) - discount;
}

class CartNotifier extends StateNotifier<List<CartLine>> {
  CartNotifier() : super([]);

  void addOrUpdate(String itemId, String name, double unitPrice, int quantity) {
    final idx = state.indexWhere((l) => l.itemId == itemId);
    if (idx >= 0) {
      state[idx].quantity = quantity;
      state = [...state];
    } else {
      state = [...state, CartLine(itemId: itemId, name: name, unitPrice: unitPrice, quantity: quantity)];
    }
  }

  void setDiscount(String itemId, double discount) {
    final idx = state.indexWhere((l) => l.itemId == itemId);
    if (idx >= 0) {
      state[idx].discount = discount;
      state = [...state];
    }
  }

  void remove(String itemId) {
    state = state.where((l) => l.itemId != itemId).toList();
  }

  void clear() => state = [];

  double get total => state.fold(0, (sum, l) => sum + l.total);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartLine>>((ref) => CartNotifier());

final saleRepositoryProvider = Provider((ref) => SaleRepository(ref.watch(apiClientProvider)));