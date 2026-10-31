class CartLineItem {
  final int itemIndex;
  final int quantity;
  final String notes;
  final String? bookingDate;
  final String? bookingTime;
  final String? resourceId;
  final String? resourceName;

  const CartLineItem({
    required this.itemIndex,
    this.quantity = 1,
    this.notes = '',
    this.bookingDate,
    this.bookingTime,
    this.resourceId,
    this.resourceName,
  });

  CartLineItem copyWith({
    int? quantity,
    String? notes,
    String? bookingDate,
    String? bookingTime,
    String? resourceId,
    String? resourceName,
  }) {
    return CartLineItem(
      itemIndex: itemIndex,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      resourceId: resourceId ?? this.resourceId,
      resourceName: resourceName ?? this.resourceName,
    );
  }
}
