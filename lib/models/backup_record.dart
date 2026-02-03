class BackupRecord {
  BackupRecord({
    required this.id,
    required this.documentId,
    required this.versionId,
    required this.cloudPath,
    required this.updatedAt,
  });

  final String id;
  final String documentId;
  final String versionId;
  final String cloudPath;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'versionId': versionId,
      'cloudPath': cloudPath,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static BackupRecord fromMap(Map<String, Object?> map) {
    return BackupRecord(
      id: map['id'] as String,
      documentId: map['documentId'] as String,
      versionId: map['versionId'] as String,
      cloudPath: map['cloudPath'] as String,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
