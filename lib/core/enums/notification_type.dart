/// Mirrors the Java NotificationType enum from the backend.
/// Extended with ORDER_UPDATE and NEW_MESSAGE for mobile-specific triggers.
enum NotificationType {
  priceDrop('PRICE_DROP'),
  newArrival('NEW_ARRIVAL'),
  restock('RESTOCK'),
  recommendation('RECOMMENDATION'),
  orderUpdate('ORDER_UPDATE'),
  newMessage('NEW_MESSAGE'),
  feedLike('FEED_LIKE'),
  feedComment('FEED_COMMENT'),
  system('SYSTEM');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.system,
    );
  }
}
