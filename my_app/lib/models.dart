abstract class Habit {
  final String id;
  final String name;
  final String emoji;
  final HabitType type;

  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
  });

  Habit clone();
}

enum HabitType {
  timer,
  daily,
}

class TimerHabit extends Habit {
  Duration elapsedTime;
  bool isRunning;
  DateTime? lastStartTime;

  TimerHabit({
    required String id,
    required String name,
    required String emoji,
    this.elapsedTime = Duration.zero,
    this.isRunning = false,
    this.lastStartTime,
  }) : super(id: id, name: name, emoji: emoji, type: HabitType.timer);

  @override
  TimerHabit clone() {
    return TimerHabit(
      id: id,
      name: name,
      emoji: emoji,
      elapsedTime: elapsedTime,
      isRunning: isRunning,
      lastStartTime: lastStartTime,
    );
  }

  String get formattedTime {
    final days = elapsedTime.inDays;
    final hours = elapsedTime.inHours.remainder(24);
    final minutes = elapsedTime.inMinutes.remainder(60);
    
    if (days > 0) {
      return '$daysд $hoursч $minutesм';
    } else if (hours > 0) {
      return '$hoursч $minutesм';
    } else {
      return '$minutesм';
    }
  }
  
  // Для базы данных
  Map<String, dynamic> toMap() {
    return {
      'type': 'timer',
      'id': id,
      'name': name,
      'emoji': emoji,
      'elapsed_time': elapsedTime.inMilliseconds,
      'is_running': isRunning ? 1 : 0,
      'last_start_time': lastStartTime?.millisecondsSinceEpoch,
    };
  }
  
  factory TimerHabit.fromMap(Map<String, dynamic> map) {
    return TimerHabit(
      id: map['id'],
      name: map['name'],
      emoji: map['emoji'],
      elapsedTime: Duration(milliseconds: map['elapsed_time']),
      isRunning: map['is_running'] == 1,
      lastStartTime: map['last_start_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_start_time'])
          : null,
    );
  }
}

class DailyHabit extends Habit {
  int streak;
  DateTime lastCompleted;

  DailyHabit({
    required String id,
    required String name,
    required String emoji,
    this.streak = 0,
    required this.lastCompleted,
  }) : super(id: id, name: name, emoji: emoji, type: HabitType.daily);

  @override
  DailyHabit clone() {
    return DailyHabit(
      id: id,
      name: name,
      emoji: emoji,
      streak: streak,
      lastCompleted: lastCompleted,
    );
  }
  
  // Для базы данных
  Map<String, dynamic> toMap() {
    return {
      'type': 'daily',
      'id': id,
      'name': name,
      'emoji': emoji,
      'streak': streak,
      'last_completed': lastCompleted.millisecondsSinceEpoch,
    };
  }
  
  factory DailyHabit.fromMap(Map<String, dynamic> map) {
    return DailyHabit(
      id: map['id'],
      name: map['name'],
      emoji: map['emoji'],
      streak: map['streak'],
      lastCompleted: DateTime.fromMillisecondsSinceEpoch(
          map['last_completed']),
    );
  }
}