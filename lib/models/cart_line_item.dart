class CartLineItem {
  final int itemIndex;
  final int quantity;
  final String notes;

  const CartLineItem({
    required this.itemIndex,
    this.quantity = 1,
    this.notes = '',
  });

  CartLineItem copyWith({int? quantity, String? notes}) {
    return CartLineItem(
      itemIndex: itemIndex,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}
