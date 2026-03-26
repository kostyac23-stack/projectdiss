/// Domain model for a specialist's bid on a task request
class Bid {
  final int? id;
  final int taskRequestId;
  final int specialistId;
  final String specialistName;
  final double proposedPrice;
  final String? message;
  final BidStatus status;
  final DateTime? createdAt;

  Bid({
    this.id,
    required this.taskRequestId,
    required this.specialistId,
    required this.specialistName,
    required this.proposedPrice,
    this.message,
    this.status = BidStatus.pending,
    this.createdAt,
  });

  factory Bid.fromMap(Map<String, dynamic> map) {
    return Bid(
      id: map['id'] as int?,
      taskRequestId: map['task_request_id'] as int,
      specialistId: map['specialist_id'] as int,
      specialistName: map['specialist_name'] as String,
      proposedPrice: (map['proposed_price'] as num).toDouble(),
      message: map['message'] as String?,
      status: BidStatus.fromString(map['status'] as String? ?? 'pending'),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'task_request_id': taskRequestId,
      'specialist_id': specialistId,
      'specialist_name': specialistName,
      'proposed_price': proposedPrice,
      'message': message,
      'status': status.name,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  Bid copyWith({
    int? id,
    int? taskRequestId,
    int? specialistId,
    String? specialistName,
    double? proposedPrice,
    String? message,
    BidStatus? status,
    DateTime? createdAt,
  }) {
    return Bid(
      id: id ?? this.id,
      taskRequestId: taskRequestId ?? this.taskRequestId,
      specialistId: specialistId ?? this.specialistId,
      specialistName: specialistName ?? this.specialistName,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum BidStatus {
  pending,
  accepted,
  rejected;

  static BidStatus fromString(String value) {
    return BidStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BidStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case BidStatus.pending:
        return 'Pending';
      case BidStatus.accepted:
        return 'Accepted';
      case BidStatus.rejected:
        return 'Rejected';
    }
  }
}
