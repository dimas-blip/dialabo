import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'habits_editor.dart';
import 'timer_habit_dialog.dart';
import 'settings_page.dart';
import 'models.dart';
import 'database.dart';
import 'weather_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Habit> _userHabits = [];
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late HabitDatabase _database;
  late WeatherService _weatherService;
  WeatherData? _currentWeather;
  String? _selectedCity;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Инициализация базы данных
      _database = HabitDatabase();

      // Инициализация SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _weatherService = WeatherService(prefs);

      // Загружаем данные
      await _loadHabitsFromDatabase();
      await _loadWeather();
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки данных: $e';
      });
      print('Ошибка инициализации: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHabitsFromDatabase() async {
    try {
      final habits = await _database.loadHabits();
      setState(() {
        _userHabits = habits;
      });
    } catch (e) {
      print('Ошибка загрузки привычек: $e');
    }
  }

  Future<void> _saveHabitsToDatabase() async {
    try {
      await _database.saveHabits(_userHabits);
    } catch (e) {
      print('Ошибка сохранения привычек: $e');
    }
  }

  Future<void> _updateHabitInDatabase(Habit habit) async {
    try {
      await _database.updateHabit(habit);
    } catch (e) {
      print('Ошибка обновления привычки: $e');
    }
  }

  Future<void> _loadWeather() async {
    try {
      // Загружаем сохраненный город или используем Москву по умолчанию
      _selectedCity = _weatherService.getSavedCity() ?? 'Москва';

      final weather = await _weatherService.getWeather(_selectedCity!);
      if (weather != null) {
        setState(() {
          _currentWeather = weather;
        });
      }
    } catch (e) {
      print('Ошибка загрузки погоды: $e');
    }
  }

  void _handleDailyHabitTap(Habit habit) async {
    if (habit.type == HabitType.daily) {
      final dailyHabit = habit as DailyHabit;
      final now = DateTime.now();
      final lastCompleted = dailyHabit.lastCompleted;

      // Проверяем, не отмечал ли уже сегодня
      if (lastCompleted.year != now.year ||
          lastCompleted.month != now.month ||
          lastCompleted.day != now.day) {
        setState(() {
          dailyHabit.streak++;
          dailyHabit.lastCompleted = now;
        });

        // Сохраняем в базу данных
        await _updateHabitInDatabase(dailyHabit);
      }
    }
  }

  void _handleTimerHabitTap(Habit habit) {
    if (habit.type == HabitType.timer) {
      final timerHabit = habit as TimerHabit;

      showDialog<void>(
        context: _navigatorKey.currentContext!,
        builder: (context) => TimerHabitDialog(
          habit: timerHabit,
          onUpdate: (updatedHabit) async {
            setState(() {
              final index =
                  _userHabits.indexWhere((h) => h.id == updatedHabit.id);
              if (index != -1) {
                _userHabits[index] = updatedHabit;
              }
            });

            // Сохраняем изменения в базу данных
            await _updateHabitInDatabase(updatedHabit);

            return updatedHabit;
          },
        ),
      );
    }
  }

  void _handleHabitLongPress(Habit habit) {
    showDialog(
      context: _navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text('Удалить "${habit.name}"?'),
        content: Text(
            'Вы уверены, что хотите удалить привычку ${habit.emoji} ${habit.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОТМЕНА'),
          ),
          TextButton(
            onPressed: () {
              _deleteHabit(habit);
              Navigator.pop(context);
            },
            child: const Text(
              'УДАЛИТЬ',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHabit(Habit habit) async {
    setState(() {
      _userHabits.removeWhere((h) => h.id == habit.id);
    });

    // Удаляем из базы данных
    await _database.deleteHabit(habit.id, habit.type);

    ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text('Привычка "${habit.name}" удалена'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openHabitsEditor() async {
    try {
      final newHabit = await Navigator.of(_navigatorKey.currentContext!).push(
        MaterialPageRoute(builder: (context) => const HabitsEditorPage()),
      );

      if (newHabit != null && newHabit is Habit) {
        // Проверяем, нет ли уже такой привычки
        final isDuplicate = _userHabits.any((habit) => habit.id == newHabit.id);

        if (isDuplicate) {
          // Показываем сообщение о дубликате
          _showDuplicateMessage();
        } else {
          setState(() {
            _userHabits.add(newHabit);
          });

          // Сохраняем все привычки в базу данных
          await _saveHabitsToDatabase();
        }
      }
    } catch (e) {
      print('Ошибка открытия редактора привычек: $e');
    }
  }

  void _showDuplicateMessage() {
    ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
      const SnackBar(
        content: Text('Эта привычка уже добавлена!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openWeatherSettings() async {
    try {
      final city = await showDialog<String>(
        context: _navigatorKey.currentContext!,
        builder: (context) => WeatherSettingsDialog(
          initialCity: _selectedCity ?? 'Москва',
        ),
      );

      if (city != null && city.isNotEmpty) {
        setState(() {
          _selectedCity = city;
          _currentWeather = null; // Сбрасываем погоду для загрузки новой
        });

        // Сохраняем город в настройках
        await _weatherService.saveCity(city);

        // Загружаем погоду для нового города
        await _loadWeather();
      }
    } catch (e) {
      print('Ошибка открытия настроек погоды: $e');
    }
  }

  void _openSettings() async {
    await Navigator.of(_navigatorKey.currentContext!).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          onClearData: _clearAllHabits,
          onExportData: _exportData,
          onShowStats: _showStatistics,
        ),
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: _navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Удалить все привычки?'),
        content: const Text(
            'Это действие удалит все ваши привычки и прогресс. Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОТМЕНА'),
          ),
          TextButton(
            onPressed: () {
              _clearAllHabits();
              Navigator.pop(context);
            },
            child: const Text(
              'УДАЛИТЬ ВСЕ',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllHabits() async {
    setState(() {
      _userHabits.clear();
    });

    // Очищаем базу данных
    await _database.clearAll();

    ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
      const SnackBar(
        content: Text('Все привычки удалены'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final data = await _database.exportData();

      // В реальном приложении здесь можно сохранить в файл,
      // отправить на email или показать пользователю
      showDialog(
        context: _navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: const Text('📤 Экспорт данных'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Данные успешно экспортированы:'),
              const SizedBox(height: 12),
              Text('Таймерные привычки: ${(data['timer_habits'] as List).length}'),
              Text('Ежедневные привычки: ${(data['daily_habits'] as List).length}'),
              Text('Дата экспорта: ${data['export_date']}'),
              const SizedBox(height: 12),
              const Text(
                'В реальном приложении данные можно сохранить в файл или отправить на email',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ОК'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Ошибка экспорта: $e');
    }
  }

  void _showStatistics() async {
    final stats = await _database.getStats();

    showDialog(
      context: _navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('📊 Статистика'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatItem('Всего привычек', '${stats['total_habits']}'),
              _buildStatItem('Таймерные привычки', '${stats['timer_habits']}'),
              _buildStatItem('Ежедневные привычки', '${stats['daily_habits']}'),
              const Divider(),
              if (stats['total_time_ms'] > 0)
                _buildStatItem(
                  'Общее время таймеров',
                  _formatDuration(Duration(milliseconds: stats['total_time_ms'])),
                ),
              if (stats['avg_streak'] > 0)
                _buildStatItem(
                  'Средняя серия',
                  '${stats['avg_streak'].toStringAsFixed(1)} дней',
                ),
              const SizedBox(height: 16),
              const Text(
                'Данные сохраняются автоматически при каждом изменении',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    if (days > 0) {
      return '$daysд ${hours}ч ${minutes}м';
    } else if (hours > 0) {
      return '${hours}ч ${minutes}м';
    } else {
      return '${minutes}м';
    }
  }

  Widget _buildWeatherWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
      ),
      child: Row(
        children: [
          if (_currentWeather?.icon != null)
            Image.network(
              'https://openweathermap.org/img/wn/${_currentWeather!.icon}@2x.png',
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.cloud, size: 40, color: Colors.blue);
              },
            )
          else
            const Icon(Icons.cloud, size: 40, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCity ?? 'Выберите город',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_currentWeather != null)
                  Text(
                    '${_currentWeather!.formattedTemperature}, ${_currentWeather!.description}',
                    style: const TextStyle(fontSize: 14),
                  )
                else
                  const Text(
                    'Загрузка погоды...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loadWeather,
            tooltip: 'Обновить погоду',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blue),
            onPressed: _openWeatherSettings,
            tooltip: 'Настройки погоды',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Произошла ошибка',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initServices,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загрузка данных...'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Трекер привычек',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      navigatorKey: _navigatorKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Трекер привычек'),
          backgroundColor: Colors.blueAccent,
          elevation: 2,
          actions: [
            // Кнопка настроек
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
              tooltip: 'Настройки',
            ),
            // Кнопка статистики
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: _showStatistics,
              tooltip: 'Статистика',
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingWidget()
            : _errorMessage != null
                ? _buildErrorWidget()
                : Column(
                    children: [
                      _buildWeatherWidget(),
                      Expanded(
                        child: HomePage(
                          habits: _userHabits,
                          onHabitTap: _handleDailyHabitTap,
                          onTimerHabitTap: _handleTimerHabitTap,
                          onLongPress: _handleHabitLongPress,
                        ),
                      ),
                    ],
                  ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Кнопка настроек погоды
            FloatingActionButton(
              onPressed: _openWeatherSettings,
              mini: true,
              backgroundColor: Colors.blueGrey,
              heroTag: 'weather_btn',
              child: const Icon(Icons.cloud, color: Colors.white),
            ),
            const SizedBox(height: 16),
            // Основная кнопка добавления привычек
            FloatingActionButton(
              onPressed: _openHabitsEditor,
              backgroundColor: Colors.purple,
              heroTag: 'add_habit_btn',
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherSettingsDialog extends StatefulWidget {
  final String initialCity;

  const WeatherSettingsDialog({super.key, required this.initialCity});

  @override
  State<WeatherSettingsDialog> createState() => _WeatherSettingsDialogState();
}

class _WeatherSettingsDialogState extends State<WeatherSettingsDialog> {
  late TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialCity);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Настройки погоды'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'Город',
              hintText: 'Например: Москва, Санкт-Петербург',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Введите название города на русском или английском языке',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ОТМЕНА'),
        ),
        ElevatedButton(
          onPressed: () {
            final city = _cityController.text.trim();
            if (city.isNotEmpty) {
              Navigator.pop(context, city);
            }
          },
          child: const Text('СОХРАНИТЬ'),
        ),
      ],
    );
  }
}