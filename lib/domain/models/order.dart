/// Domain model for a service order/request
class Order {
  final int? id;
  final int specialistId;
  final String clientName;
  final String serviceDescription;
  final OrderStatus status;
  final double? price;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Order({
    this.id,
    required this.specialistId,
    required this.clientName,
    required this.serviceDescription,
    this.status = OrderStatus.pending,
    this.price,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from database map
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      specialistId: map['specialist_id'] as int,
      clientName: map['client_name'] as String,
      serviceDescription: map['service_description'] as String,
      status: OrderStatus.fromString(map['status'] as String),
      price: map['price'] as double?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'specialist_id': specialistId,
      'client_name': clientName,
      'service_description': serviceDescription,
      'status': status.toString(),
      'price': price,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Order copyWith({
    int? id,
    int? specialistId,
    String? clientName,
    String? serviceDescription,
    OrderStatus? status,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      clientName: clientName ?? this.clientName,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      status: status ?? this.status,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Order status enum
enum OrderStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => OrderStatus.pending,
    );
  }

  @override
  String toString() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.inProgress:
        return 'in_progress';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

