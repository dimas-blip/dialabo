import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class HabitDatabase {
  static final HabitDatabase _instance = HabitDatabase._internal();
  factory HabitDatabase() => _instance;
  HabitDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'habits.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Создание базы данных...');
    
    // Таблица для TimerHabit
    await db.execute('''
      CREATE TABLE timer_habits(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        elapsed_time INTEGER NOT NULL,
        is_running INTEGER NOT NULL,
        last_start_time INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    // Таблица для DailyHabit
    await db.execute('''
      CREATE TABLE daily_habits(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        streak INTEGER NOT NULL,
        last_completed INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    
    print('База данных создана успешно!');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Обновление базы данных с $oldVersion до $newVersion');
    // Можно добавить миграции при необходимости
  }

  // Сохранение всех привычек
  Future<void> saveHabits(List<Habit> habits) async {
    final db = await database;
    
    final batch = db.batch();
    
    // Очищаем таблицы
    batch.delete('timer_habits');
    batch.delete('daily_habits');

    final now = DateTime.now().millisecondsSinceEpoch;
    
    for (final habit in habits) {
      if (habit.type == HabitType.timer) {
        final timerHabit = habit as TimerHabit;
        batch.insert('timer_habits', {
          'id': timerHabit.id,
          'name': timerHabit.name,
          'emoji': timerHabit.emoji,
          'elapsed_time': timerHabit.elapsedTime.inMilliseconds,
          'is_running': timerHabit.isRunning ? 1 : 0,
          'last_start_time': timerHabit.lastStartTime?.millisecondsSinceEpoch,
          'created_at': now,
        });
      } else {
        final dailyHabit = habit as DailyHabit;
        batch.insert('daily_habits', {
          'id': dailyHabit.id,
          'name': dailyHabit.name,
          'emoji': dailyHabit.emoji,
          'streak': dailyHabit.streak,
          'last_completed': dailyHabit.lastCompleted.millisecondsSinceEpoch,
          'created_at': now,
        });
      }
    }
    
    await batch.commit();
    print('Сохранено ${habits.length} привычек в базу данных');
  }

  // Загрузка всех привычек
  Future<List<Habit>> loadHabits() async {
    final db = await database;
    final List<Habit> habits = [];

    try {
      // Загружаем TimerHabit
      final timerMaps = await db.query('timer_habits');
      print('Загружено ${timerMaps.length} таймерных привычек');
      
      for (final map in timerMaps) {
        habits.add(TimerHabit(
          id: map['id'] as String,
          name: map['name'] as String,
          emoji: map['emoji'] as String,
          elapsedTime: Duration(milliseconds: map['elapsed_time'] as int),
          isRunning: (map['is_running'] as int) == 1,
          lastStartTime: map['last_start_time'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['last_start_time'] as int)
              : null,
        ));
      }

      // Загружаем DailyHabit
      final dailyMaps = await db.query('daily_habits');
      print('Загружено ${dailyMaps.length} ежедневных привычек');
      
      for (final map in dailyMaps) {
        habits.add(DailyHabit(
          id: map['id'] as String,
          name: map['name'] as String,
          emoji: map['emoji'] as String,
          streak: map['streak'] as int,
          lastCompleted: DateTime.fromMillisecondsSinceEpoch(
              map['last_completed'] as int),
        ));
      }
      
      print('Всего загружено ${habits.length} привычек');
    } catch (e) {
      print('Ошибка загрузки привычек из базы: $e');
    }

    return habits;
  }

  // Обновление одной привычки
  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    
    try {
      if (habit.type == HabitType.timer) {
        final timerHabit = habit as TimerHabit;
        await db.update(
          'timer_habits',
          {
            'elapsed_time': timerHabit.elapsedTime.inMilliseconds,
            'is_running': timerHabit.isRunning ? 1 : 0,
            'last_start_time': timerHabit.lastStartTime?.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [timerHabit.id],
        );
        print('Обновлена таймерная привычка: ${timerHabit.name}');
      } else {
        final dailyHabit = habit as DailyHabit;
        await db.update(
          'daily_habits',
          {
            'streak': dailyHabit.streak,
            'last_completed': dailyHabit.lastCompleted.millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [dailyHabit.id],
        );
        print('Обновлена ежедневная привычка: ${dailyHabit.name}');
      }
    } catch (e) {
      print('Ошибка обновления привычки: $e');
    }
  }

  // Удаление привычки
  Future<void> deleteHabit(String id, HabitType type) async {
    final db = await database;
    
    try {
      if (type == HabitType.timer) {
        await db.delete(
          'timer_habits',
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await db.delete(
          'daily_habits',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      print('Удалена привычка с ID: $id');
    } catch (e) {
      print('Ошибка удаления привычки: $e');
    }
  }

  // Получение статистики
  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final stats = <String, dynamic>{};
    
    try {
      // Общее количество привычек
      final timerCount = await db.rawQuery('SELECT COUNT(*) FROM timer_habits');
      final dailyCount = await db.rawQuery('SELECT COUNT(*) FROM daily_habits');
      
      stats['total_habits'] = (timerCount[0]['COUNT(*)'] as int) + 
                             (dailyCount[0]['COUNT(*)'] as int);
      stats['timer_habits'] = timerCount[0]['COUNT(*)'] as int;
      stats['daily_habits'] = dailyCount[0]['COUNT(*)'] as int;
      
      // Общее время в таймерных привычках
      final totalTimeResult = await db.rawQuery('SELECT SUM(elapsed_time) FROM timer_habits');
      final totalTime = totalTimeResult[0]['SUM(elapsed_time)'] as int? ?? 0;
      
      stats['total_time_ms'] = totalTime;
      
      // Средняя серия ежедневных привычек
      final avgStreakResult = await db.rawQuery('SELECT AVG(streak) FROM daily_habits');
      final avgStreak = avgStreakResult[0]['AVG(streak)'] as double? ?? 0.0;
      
      stats['avg_streak'] = avgStreak;
      
      print('Статистика загружена: $stats');
    } catch (e) {
      print('Ошибка загрузки статистики: $e');
    }
    
    return stats;
  }

  // Экспорт данных
  Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    final data = <String, dynamic>{};
    
    try {
      final timerHabits = await db.query('timer_habits');
      final dailyHabits = await db.query('daily_habits');
      
      data['timer_habits'] = timerHabits;
      data['daily_habits'] = dailyHabits;
      data['export_date'] = DateTime.now().toIso8601String();
      
      print('Данные экспортированы: ${timerHabits.length + dailyHabits.length} привычек');
    } catch (e) {
      print('Ошибка экспорта данных: $e');
    }
    
    return data;
  }

  // Очистка всех данных
  Future<void> clearAll() async {
    final db = await database;
    
    try {
      await db.delete('timer_habits');
      await db.delete('daily_habits');
      print('Все данные удалены из базы');
    } catch (e) {
      print('Ошибка очистки базы данных: $e');
    }
  }
}