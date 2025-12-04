import 'package:flutter/material.dart';
import 'models.dart';

class HomePage extends StatelessWidget {
  final List<Habit> habits;
  final Function(Habit) onHabitTap;
  final Function(Habit) onTimerHabitTap;
  final Function(Habit)? onLongPress;

  const HomePage({
    super.key,
    required this.habits,
    required this.onHabitTap,
    required this.onTimerHabitTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: habits.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.psychology, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Добавь первую привычку!',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Нажми на плюсик внизу экрана',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Статистика привычек
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            habits.length.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text(
                            'Всего',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            habits
                                .where((h) => h.type == HabitType.timer)
                                .length
                                .toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text(
                            'Таймеры',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            habits
                                .where((h) => h.type == HabitType.daily)
                                .length
                                .toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text(
                            'Ежедневные',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Сетка привычек
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      return _HabitCircle(
                        habit: habit,
                        onTap: () {
                          if (habit.type == HabitType.timer) {
                            onTimerHabitTap(habit);
                          } else {
                            onHabitTap(habit);
                          }
                        },
                        onLongPress:
                            onLongPress != null ? () => onLongPress!(habit) : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _HabitCircle extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _HabitCircle({
    required this.habit,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: _getHabitColor(),
          shape: BoxShape.circle,
          border: Border.all(color: _getBorderColor(), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              habit.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              _shortenName(habit.name),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            _buildHabitInfo(),
          ],
        ),
      ),
    );
  }

  String _shortenName(String name) {
    if (name.length <= 10) return name;
    return '${name.substring(0, 8)}...';
  }

  Widget _buildHabitInfo() {
    if (habit.type == HabitType.timer) {
      final timerHabit = habit as TimerHabit;
      return Text(
        timerHabit.formattedTime,
        style: TextStyle(
          fontSize: 9,
          color: timerHabit.isRunning ? Colors.green : Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      final dailyHabit = habit as DailyHabit;
      return Column(
        children: [
          Text(
            '${dailyHabit.streak} дн',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildStreakIndicator(dailyHabit.streak),
        ],
      );
    }
  }

  Widget _buildStreakIndicator(int streak) {
    if (streak == 0) return const SizedBox.shrink();
    
    Color color;
    if (streak >= 30) {
      color = Colors.red;
    } else if (streak >= 14) {
      color = Colors.orange;
    } else if (streak >= 7) {
      color = Colors.yellow.shade700;
    } else {
      color = Colors.green;
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _getStreakLabel(streak),
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getStreakLabel(int streak) {
    if (streak >= 30) return '🔥 30+';
    if (streak >= 14) return '⚡ 14+';
    if (streak >= 7) return '🌟 7+';
    return '👍';
  }

  Color _getHabitColor() {
    if (habit.type == HabitType.timer) {
      final timerHabit = habit as TimerHabit;
      return timerHabit.isRunning
          ? Colors.green.shade50
          : Colors.blue.shade50;
    } else {
      final dailyHabit = habit as DailyHabit;
      final now = DateTime.now();
      final lastCompleted = dailyHabit.lastCompleted;
      
      // Проверяем, выполнена ли привычка сегодня
      final isCompletedToday = lastCompleted.year == now.year &&
          lastCompleted.month == now.month &&
          lastCompleted.day == now.day;
      
      return isCompletedToday
          ? Colors.green.shade50
          : Colors.orange.shade50;
    }
  }

  Color _getBorderColor() {
    if (habit.type == HabitType.timer) {
      final timerHabit = habit as TimerHabit;
      return timerHabit.isRunning
          ? Colors.green.shade400
          : Colors.blue.shade400;
    } else {
      final dailyHabit = habit as DailyHabit;
      final now = DateTime.now();
      final lastCompleted = dailyHabit.lastCompleted;
      
      // Проверяем, выполнена ли привычка сегодня
      final isCompletedToday = lastCompleted.year == now.year &&
          lastCompleted.month == now.month &&
          lastCompleted.day == now.day;
      
      return isCompletedToday
          ? Colors.green.shade400
          : Colors.orange.shade400;
    }
  }
}