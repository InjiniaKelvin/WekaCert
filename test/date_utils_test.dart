import 'package:flutter_test/flutter_test.dart';

import 'package:weka_cert/utils/date_utils.dart';

void main() {
  final reference = DateTime(2026, 10, 5);

  test('classifies permanent documents without an expiry date', () {
    expect(
      statusForExpiry(
        isExpirable: false,
        reminderDays: 7,
        reference: reference,
      ),
      ExpiryDisplayStatus.permanent,
    );
  });

  test('classifies expiry boundaries and expired documents', () {
    expect(
      statusForExpiry(
        isExpirable: true,
        expiryDate: DateTime(2026, 10, 12),
        reminderDays: 7,
        reference: reference,
      ),
      ExpiryDisplayStatus.expiringSoon,
    );
    expect(
      statusForExpiry(
        isExpirable: true,
        expiryDate: DateTime(2026, 10, 13),
        reminderDays: 7,
        reference: reference,
      ),
      ExpiryDisplayStatus.valid,
    );
    expect(
      statusForExpiry(
        isExpirable: true,
        expiryDate: DateTime(2026, 10, 4),
        reminderDays: 7,
        reference: reference,
      ),
      ExpiryDisplayStatus.expired,
    );
  });
}
