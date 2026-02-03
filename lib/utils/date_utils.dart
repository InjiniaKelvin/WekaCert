import '../models/document_filter.dart';

enum ExpiryDisplayStatus { valid, expiringSoon, expired, permanent }

ExpiryDisplayStatus statusForExpiry({
  required bool isExpirable,
  DateTime? expiryDate,
  required int reminderDays,
  DateTime? reference,
}) {
  if (!isExpirable || expiryDate == null) {
    return ExpiryDisplayStatus.permanent;
  }
  final today = reference ?? DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final normalizedExpiry = DateTime(
    expiryDate.year,
    expiryDate.month,
    expiryDate.day,
  );
  if (normalizedExpiry.isBefore(normalizedToday)) {
    return ExpiryDisplayStatus.expired;
  }
  final daysRemaining = normalizedExpiry.difference(normalizedToday).inDays;
  if (daysRemaining <= reminderDays) {
    return ExpiryDisplayStatus.expiringSoon;
  }
  return ExpiryDisplayStatus.valid;
}

ExpiryStatus? toFilterStatus(ExpiryDisplayStatus status) {
  switch (status) {
    case ExpiryDisplayStatus.valid:
      return ExpiryStatus.valid;
    case ExpiryDisplayStatus.expiringSoon:
      return ExpiryStatus.expiringSoon;
    case ExpiryDisplayStatus.expired:
      return ExpiryStatus.expired;
    case ExpiryDisplayStatus.permanent:
      return ExpiryStatus.permanent;
  }
}

String labelForStatus(ExpiryDisplayStatus status) {
  switch (status) {
    case ExpiryDisplayStatus.valid:
      return 'Valid';
    case ExpiryDisplayStatus.expiringSoon:
      return 'Expiring soon';
    case ExpiryDisplayStatus.expired:
      return 'Expired';
    case ExpiryDisplayStatus.permanent:
      return 'Permanent';
  }
}
