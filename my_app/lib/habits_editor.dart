import 'package:flutter/material.dart';
import 'models.dart';

class HabitsEditorPage extends StatefulWidget {
  const HabitsEditorPage({super.key});

  @override
  State<HabitsEditorPage> createState() => _HabitsEditorPageState();
}

class _HabitsEditorPageState extends State<HabitsEditorPage> {
  // Список доступных привычек (15+ штук)
  final List<Habit> _availableHabits = [
    // Таймер-привычки (8 штук)
    TimerHabit(
      id: 'timer_1',
      name: 'Не курю',
      emoji: '🚭',
      elapsedTime: Duration.zero,
      isRunning: false,
      lastStartTime: null,
    ),
    TimerHabit(
      id: 'timer_2',
      name: 'Экономлю',
      emoji: '💰',
      elapsedTime: Duration.zero,
      isRunning: false,
      lastStartTime: null,
    ),
    TimerHabit(
      id: 'timer_3',
      name: 'Учу английский',
      emoji: '🇬🇧',
      elapsedTime: Duration.zero,
      isRunning: false,
      lastStartTime: null,
    ),
    TimerHabit(
      id: 'timer_4',
      name: 'Медитирую',
      emoji: '🧘',
      elapsedTime: Duration.zero,
      isRunning: false,
      lastStartTime: null,
    ),
    TimerHabit(
      id: 'timer_5',
      name: 'Программирую',
      emoji: '💻',
      elapsedTime: Duration.zero,
      isRunning: false,
      lastStartTime: null,
    ),
    TimerHabit(
      id: 'timer_6',
      name: 'Рисую',
      emoji: '🎨',
      elapsedTime: Duration.zero,
      isRunning: false,
      lastStartTime: null,
    ),
    TimerHabit(
      id: 'timer_7',
      name: 'Играю на гитаре',
      emoji: '🎸',
      elapsedTime: Duration.zero,
      isRunning: false,
      lastStartTime: null,
    ),
    TimerHabit(
      id: 'timer_8',
      name: 'Готовлю',
      emoji: '👨‍🍳',
      elapsedTime: Duration.zero,
      isRunning: false,
      lastStartTime: null,
    ),
    
    // Ежедневные привычки (9 штук)
    DailyHabit(
      id: 'daily_1',
      name: 'Читаю',
      emoji: '📚',
      streak: 0,
      lastCompleted: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DailyHabit(
      id: 'daily_2',
      name: 'Тренируюсь',
      emoji: '💪',
      streak: 0,
      lastCompleted: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DailyHabit(
      id: 'daily_3',
      name: 'Пью воду',
      emoji: '💧',
      streak: 0,
      lastCompleted: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DailyHabit(
      id: 'daily_4',
      name: 'Застилаю кровать',
      emoji: '🛏️',
      streak: 0,
      lastCompleted: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DailyHabit(
      id: 'daily_5',
      name: 'Записываю мысли',
      emoji: '📓',
      streak: 0,
      lastCompleted: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DailyHabit(
      id: 'daily_6',
      name: 'Гуляю',
      emoji: '🚶',
      streak: 0,
      lastCompleted: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DailyHabit(
      id: 'daily_7',
      name: 'Убираюсь',
      emoji: '🧹',
      streak: 0,
      lastCompleted: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DailyHabit(
      id: 'daily_8',
      name: 'Планирую день',
      emoji: '📅',
      streak: 0,
      lastCompleted: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DailyHabit(
      id: 'daily_9',
      name: 'Высыпаюсь',
      emoji: '😴',
      streak: 0,
      lastCompleted: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DailyHabit(
      id: 'daily_10',
      name: 'Помогаю другим',
      emoji: '🤝',
      streak: 0,
      lastCompleted: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DailyHabit(
      id: 'daily_11',
      name: 'Учу что-то новое',
      emoji: '🧠',
      streak: 0,
      lastCompleted: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // Поиск по привычкам
  final TextEditingController _searchController = TextEditingController();
  List<Habit> _filteredHabits = [];

  @override
  void initState() {
    super.initState();
    _filteredHabits = _availableHabits;
    _searchController.addListener(_filterHabits);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterHabits() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredHabits = _availableHabits;
      } else {
        _filteredHabits = _availableHabits.where((habit) {
          return habit.name.toLowerCase().contains(query) ||
                 habit.emoji.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбери привычки'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Поле поиска
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск привычек...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          
          // Счетчики привычек
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Text('⏱️', style: TextStyle(fontSize: 12)),
                  ),
                  label: Text(
                    'Таймер: ${_filteredHabits.where((h) => h.type == HabitType.timer).length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.blue.shade50,
                ),
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: const Text('📅', style: TextStyle(fontSize: 12)),
                  ),
                  label: Text(
                    'Ежедневные: ${_filteredHabits.where((h) => h.type == HabitType.daily).length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.orange.shade50,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Список привычек
          Expanded(
            child: _filteredHabits.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Ничего не найдено',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredHabits.length,
                    itemBuilder: (context, index) {
                      final habit = _filteredHabits[index];
                      return _buildHabitCard(habit);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: habit.type == HabitType.timer 
                ? Colors.blue.shade100 
                : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: habit.type == HabitType.timer 
                  ? Colors.blue.shade300 
                  : Colors.orange.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              habit.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          habit.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              habit.type == HabitType.timer 
                  ? '⏱️ Отслеживайте время, потраченное на привычку'
                  : '📅 Отмечайте выполнение каждый день',
              style: TextStyle(
                fontSize: 12,
                color: habit.type == HabitType.timer ? Colors.blue : Colors.orange,
              ),
            ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: habit.type == HabitType.timer ? Colors.blue : Colors.orange,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (habit.type == HabitType.timer ? Colors.blue : Colors.orange)
                    .withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            habit.type == HabitType.timer ? 'ТАЙМЕР' : 'ЕЖЕДНЕВНО',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          Navigator.of(context).pop(habit.clone());
        },
      ),
    );
  }
}