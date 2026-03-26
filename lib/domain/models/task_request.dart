/// Domain model for a client task request (Profi.ru style)
class TaskRequest {
  final int? id;
  final int clientId;
  final String clientName;
  final String category;
  final String description;
  final double? budgetMin;
  final double? budgetMax;
  final DateTime? preferredDate;
  final String? location;
  final TaskUrgency urgency;
  final TaskRequestStatus status;
  final DateTime? createdAt;

  TaskRequest({
    this.id,
    required this.clientId,
    required this.clientName,
    required this.category,
    required this.description,
    this.budgetMin,
    this.budgetMax,
    this.preferredDate,
    this.location,
    this.urgency = TaskUrgency.flexible,
    this.status = TaskRequestStatus.open,
    this.createdAt,
  });

  factory TaskRequest.fromMap(Map<String, dynamic> map) {
    return TaskRequest(
      id: map['id'] as int?,
      clientId: map['client_id'] as int,
      clientName: map['client_name'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      budgetMin: map['budget_min'] as double?,
      budgetMax: map['budget_max'] as double?,
      preferredDate: map['preferred_date'] != null
          ? DateTime.parse(map['preferred_date'] as String)
          : null,
      location: map['location'] as String?,
      urgency: TaskUrgency.fromString(map['urgency'] as String? ?? 'flexible'),
      status: TaskRequestStatus.fromString(map['status'] as String? ?? 'open'),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_id': clientId,
      'client_name': clientName,
      'category': category,
      'description': description,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'preferred_date': preferredDate?.toIso8601String(),
      'location': location,
      'urgency': urgency.name,
      'status': status.name,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  TaskRequest copyWith({
    int? id,
    int? clientId,
    String? clientName,
    String? category,
    String? description,
    double? budgetMin,
    double? budgetMax,
    DateTime? preferredDate,
    String? location,
    TaskUrgency? urgency,
    TaskRequestStatus? status,
    DateTime? createdAt,
  }) {
    return TaskRequest(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      category: category ?? this.category,
      description: description ?? this.description,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      preferredDate: preferredDate ?? this.preferredDate,
      location: location ?? this.location,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum TaskUrgency {
  flexible,
  withinWeek,
  asap;

  static TaskUrgency fromString(String value) {
    return TaskUrgency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskUrgency.flexible,
    );
  }

  String get displayName {
    switch (this) {
      case TaskUrgency.flexible:
        return 'Flexible';
      case TaskUrgency.withinWeek:
        return 'Within a Week';
      case TaskUrgency.asap:
        return 'ASAP';
    }
  }
}

enum TaskRequestStatus {
  open,
  inProgress,
  completed,
  cancelled;

  static TaskRequestStatus fromString(String value) {
    return TaskRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskRequestStatus.open,
    );
  }

  String get displayName {
    switch (this) {
      case TaskRequestStatus.open:
        return 'Open';
      case TaskRequestStatus.inProgress:
        return 'In Progress';
      case TaskRequestStatus.completed:
        return 'Completed';
      case TaskRequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}
