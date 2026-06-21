class BackupEnvelope {
  /// The only envelope schema version this build can read/write.
  static const int supportedSchemaVersion = 1;

  final int schemaVersion;
  final DateTime createdAt;
  final String argon2Salt;
  final String iv;
  final String ciphertext;

  const BackupEnvelope({
    required this.schemaVersion,
    required this.createdAt,
    required this.argon2Salt,
    required this.iv,
    required this.ciphertext,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'createdAt': createdAt.toIso8601String(),
    'argon2Salt': argon2Salt,
    'iv': iv,
    'ciphertext': ciphertext,
  };

  factory BackupEnvelope.fromJson(Map<String, dynamic> json) => BackupEnvelope(
    schemaVersion: json['schemaVersion'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    argon2Salt: json['argon2Salt'] as String,
    iv: json['iv'] as String,
    ciphertext: json['ciphertext'] as String,
  );
}
