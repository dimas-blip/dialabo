import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  static const String _apiKey = 'a81ede0b777e47b535b8a8fc0ce3ac26'; // ЗАМЕНИТЕ НА ВАШ КЛЮЧ
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  
  final SharedPreferences _prefs;
  
  WeatherService(this._prefs);
  
  // Получение погоды по городу
  Future<WeatherData?> getWeather(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?q=$city&appid=$_apiKey&units=metric&lang=ru'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherData.fromJson(data);
        
        // Сохраняем в кэш
        await _saveWeatherToCache(weather);
        
        return weather;
      } else {
        print('Ошибка API: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка получения погоды: $e');
    }
    
    // Если не удалось получить, пытаемся загрузить из кэша
    return await _loadWeatherFromCache();
  }
  
  // Сохранение настроек города
  Future<void> saveCity(String city) async {
    await _prefs.setString('weather_city', city);
  }
  
  // Загрузка сохраненного города
  String? getSavedCity() {
    return _prefs.getString('weather_city');
  }
  
  // Сохранение погоды в кэш
  Future<void> _saveWeatherToCache(WeatherData weather) async {
    final cache = {
      'temperature': weather.temperature,
      'description': weather.description,
      'city': weather.city,
      'icon': weather.icon,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs.setString('weather_cache', json.encode(cache));
  }
  
  // Загрузка погоды из кэша
  Future<WeatherData?> _loadWeatherFromCache() async {
    final cached = _prefs.getString('weather_cache');
    if (cached != null) {
      final data = json.decode(cached);
      final timestamp = data['timestamp'] as int;
      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
      
      // Используем кэш только если ему меньше 30 минут
      if (cacheAge.inMinutes < 30) {
        return WeatherData(
          temperature: (data['temperature'] as num).toDouble(),
          description: data['description'],
          city: data['city'],
          icon: data['icon'],
        );
      }
    }
    return null;
  }
}

class WeatherData {
  final double temperature;
  final String description;
  final String city;
  final String icon;
  
  WeatherData({
    required this.temperature,
    required this.description,
    required this.city,
    required this.icon,
  });
  
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      city: json['name'],
      icon: json['weather'][0]['icon'],
    );
  }
  
  String get formattedTemperature => '${temperature.round()}°C';
}