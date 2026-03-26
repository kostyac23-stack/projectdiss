/// Model for specialist certificates and diplomas
class Certificate {
  final int? id;
  final int specialistId;
  final String title;
  final String? issuedBy;
  final DateTime? issuedDate;
  final DateTime? expiryDate;
  final String? description;
  final String? imagePath;
  final CertificateType type;

  Certificate({
    this.id,
    required this.specialistId,
    required this.title,
    this.issuedBy,
    this.issuedDate,
    this.expiryDate,
    this.description,
    this.imagePath,
    this.type = CertificateType.certificate,
  });

  factory Certificate.fromMap(Map<String, dynamic> map) {
    return Certificate(
      id: map['id'] as int?,
      specialistId: map['specialist_id'] as int,
      title: map['title'] as String,
      issuedBy: map['issued_by'] as String?,
      issuedDate: map['issued_date'] != null ? DateTime.parse(map['issued_date'] as String) : null,
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date'] as String) : null,
      description: map['description'] as String?,
      imagePath: map['image_path'] as String?,
      type: CertificateType.values.firstWhere(
        (t) => t.name == (map['type'] as String? ?? 'certificate'),
        orElse: () => CertificateType.certificate,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'specialist_id': specialistId,
      'title': title,
      'issued_by': issuedBy,
      'issued_date': issuedDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'description': description,
      'image_path': imagePath,
      'type': type.name,
    };
  }

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
}

enum CertificateType {
  certificate,
  diploma,
  license,
  training,
  award,
}

extension CertificateTypeExt on CertificateType {
  String get displayName {
    switch (this) {
      case CertificateType.certificate: return 'Certificate';
      case CertificateType.diploma: return 'Diploma';
      case CertificateType.license: return 'License';
      case CertificateType.training: return 'Training';
      case CertificateType.award: return 'Award';
    }
  }
}
