import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final Function() onClearData;
  final Function() onExportData;
  final Function() onShowStats;

  const SettingsPage({
    super.key,
    required this.onClearData,
    required this.onExportData,
    required this.onShowStats,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.blueGrey,
      ),
      body: ListView(
        children: [
          // Раздел базы данных
          _buildSection('База данных', [
            _buildSettingItem(
              icon: Icons.bar_chart,
              title: 'Статистика',
              subtitle: 'Просмотр статистики привычек',
              onTap: onShowStats,
              color: Colors.blue,
            ),
            _buildSettingItem(
              icon: Icons.backup,
              title: 'Экспорт данных',
              subtitle: 'Сохранить все данные',
              onTap: onExportData,
              color: Colors.green,
            ),
            _buildSettingItem(
              icon: Icons.delete_forever,
              title: 'Очистить все данные',
              subtitle: 'Удалить все привычки',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Очистить все данные?'),
                    content: const Text('Это удалит все ваши привычки и прогресс. Действие нельзя отменить.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ОТМЕНА'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onClearData();
                        },
                        child: const Text(
                          'ОЧИСТИТЬ',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              color: Colors.red,
            ),
          ]),
          
          // Раздел информации
          _buildSection('Информация', [
            _buildInfoItem(
              'Локальное хранение',
              'Все данные хранятся локально на устройстве в SQLite базе данных',
            ),
            _buildInfoItem(
              'Автосохранение',
              'Данные сохраняются автоматически при каждом изменении',
            ),
            _buildInfoItem(
              'Статистика',
              'Статистика рассчитывается на основе данных в базе',
            ),
          ]),
          
          // Раздел разработчика
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Разработчик',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Трекер привычек v1.0',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Используемые технологии:',
                      style: TextStyle(fontSize: 12),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: const Text('Flutter')),
                        Chip(label: const Text('SQLite')),
                        Chip(label: const Text('SharedPreferences')),
                        Chip(label: const Text('OpenWeather API')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        description,
        style: const TextStyle(fontSize: 12),
      ),
      dense: true,
    );
  }
}