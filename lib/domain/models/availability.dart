/// Domain model for specialist availability schedule
class Availability {
  final int? id;
  final int specialistId;
  final int dayOfWeek; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  final String startTime; // Format: "HH:mm" (e.g., "09:00")
  final String endTime; // Format: "HH:mm" (e.g., "17:00")
  final bool isAvailable;

  Availability({
    this.id,
    required this.specialistId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  /// Create from database map
  factory Availability.fromMap(Map<String, dynamic> map) {
    return Availability(
      id: map['id'] as int?,
      specialistId: map['specialist_id'] as int,
      dayOfWeek: map['day_of_week'] as int,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      isAvailable: (map['is_available'] as int? ?? 1) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'specialist_id': specialistId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable ? 1 : 0,
    };
  }

  String get dayName {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek];
  }

  Availability copyWith({
    int? id,
    int? specialistId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isAvailable,
  }) {
    return Availability(
      id: id ?? this.id,
      specialistId: specialistId ?? this.specialistId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

