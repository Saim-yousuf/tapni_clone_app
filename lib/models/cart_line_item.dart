class CartLineItem {
  final int itemIndex;
  final int quantity;
  final String notes;
  final String? bookingDate;
  final String? bookingTime;

  const CartLineItem({
    required this.itemIndex,
    this.quantity = 1,
    this.notes = '',
    this.bookingDate,
    this.bookingTime,
  });

  CartLineItem copyWith({
    int? quantity,
    String? notes,
    String? bookingDate,
    String? bookingTime,
  }) {
    return CartLineItem(
      itemIndex: itemIndex,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
    );
  }
}
