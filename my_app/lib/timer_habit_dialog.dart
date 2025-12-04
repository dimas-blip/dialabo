import 'package:flutter/material.dart';
import 'models.dart';

class TimerHabitDialog extends StatefulWidget {
  final TimerHabit habit;
  final Function(TimerHabit) onUpdate;

  const TimerHabitDialog({
    super.key,
    required this.habit,
    required this.onUpdate,
  });

  @override
  State<TimerHabitDialog> createState() => _TimerHabitDialogState();
}

class _TimerHabitDialogState extends State<TimerHabitDialog> {
  late TimerHabit _currentHabit;

  @override
  void initState() {
    super.initState();
    _currentHabit = widget.habit.clone();
  }

  void _startTimer() {
    setState(() {
      _currentHabit.isRunning = true;
      _currentHabit.lastStartTime = DateTime.now();
    });
    widget.onUpdate(_currentHabit);
  }

  void _stopTimer() {
    if (_currentHabit.isRunning && _currentHabit.lastStartTime != null) {
      final now = DateTime.now();
      final elapsed = now.difference(_currentHabit.lastStartTime!);
      
      setState(() {
        _currentHabit.elapsedTime = Duration(
          milliseconds: _currentHabit.elapsedTime.inMilliseconds + elapsed.inMilliseconds,
        );
        _currentHabit.isRunning = false;
        _currentHabit.lastStartTime = null;
      });
      widget.onUpdate(_currentHabit);
    }
  }

  void _resetTimer() {
    setState(() {
      _currentHabit.elapsedTime = Duration.zero;
      _currentHabit.isRunning = false;
      _currentHabit.lastStartTime = null;
    });
    widget.onUpdate(_currentHabit);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text(widget.habit.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.habit.name)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentHabit.formattedTime,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentHabit.isRunning ? '⏱️ Таймер запущен' : '⏸️ Таймер остановлен',
            style: TextStyle(
              color: _currentHabit.isRunning ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _resetTimer,
          child: const Text('СБРОСИТЬ', style: TextStyle(color: Colors.red)),
        ),
        const Spacer(),
        if (!_currentHabit.isRunning)
          ElevatedButton(
            onPressed: _startTimer,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, color: Colors.white),
                SizedBox(width: 4),
                Text('СТАРТ', style: TextStyle(color: Colors.white)),
              ],
            ),
          )
        else
          ElevatedButton(
            onPressed: _stopTimer,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pause, color: Colors.white),
                SizedBox(width: 4),
                Text('СТОП', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
      ],
    );
  }
}