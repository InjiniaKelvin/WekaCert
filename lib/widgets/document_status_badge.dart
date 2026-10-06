import 'package:flutter/material.dart';

import '../utils/date_utils.dart';

class DocumentStatusBadge extends StatelessWidget {
  const DocumentStatusBadge({super.key, required this.status});

  final ExpiryDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(labelForStatus(status)),
      backgroundColor: _colorForStatus(status).withValues(alpha: 0.15),
      avatar: CircleAvatar(
        radius: 6,
        backgroundColor: _colorForStatus(status),
      ),
    );
  }

  Color _colorForStatus(ExpiryDisplayStatus status) {
    switch (status) {
      case ExpiryDisplayStatus.valid:
        return Colors.green;
      case ExpiryDisplayStatus.expiringSoon:
        return Colors.orange;
      case ExpiryDisplayStatus.expired:
        return Colors.red;
      case ExpiryDisplayStatus.permanent:
        return Colors.blue;
    }
  }
}
