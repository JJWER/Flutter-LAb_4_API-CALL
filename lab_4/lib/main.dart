import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  print('API_KEY: ${dotenv.env['API_KEY']}'); // ตรวจสอบค่า API_KEY
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CityListScreen(),
    );
  }
}

class CityListScreen extends StatefulWidget {
  @override
  _CityListScreenState createState() => _CityListScreenState();
}

class _CityListScreenState extends State<CityListScreen> {
  final List<String> cities = ['Bangkok', 'London', 'New York', 'Tokyo', 'Sydney'];
  final TextEditingController _controller = TextEditingController();

  void _addCity() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        cities.add(_controller.text);
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Add a city',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: _addCity,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(cities[index]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WeatherDetailScreen(city: cities[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherDetailScreen extends StatefulWidget {
  final String city;

  WeatherDetailScreen({required this.city});

  @override
  _WeatherDetailScreenState createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  bool _isLoading = true;
  String _temperature = '';
  String _tempMin = '';
  String _tempMax = '';
  String _pressure = '';
  String _humidity = '';
  String _seaLevel = '';
  String _clouds = '';
  String _rain = '';
  String _sunset = '';
  String _description = '';
  String _weatherIcon = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchWeather(widget.city);
  }

  Future<void> fetchWeather(String city) async {
  final apiKey = dotenv.env['API_KEY'] ?? '';
  final url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _temperature = data['main']['temp'].toString();
        _tempMin = data['main']['temp_min'].toString();
        _tempMax = data['main']['temp_max'].toString();
        _pressure = data['main']['pressure'].toString();
        _humidity = data['main']['humidity'].toString();
        _seaLevel = data['main'].containsKey('sea_level') ? data['main']['sea_level'].toString() : 'N/A';
        _clouds = data['clouds']['all'].toString();
        _rain = data['rain'] != null && data['rain'].containsKey('1h') ? data['rain']['1h'].toString() : '0';
        _sunset = DateTime.fromMillisecondsSinceEpoch(data['sys']['sunset'] * 1000).toLocal().toString();
        _description = data['weather'][0]['description'];
        _weatherIcon = data['weather'][0]['icon'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'City not found';
      });
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Failed to fetch weather data';
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.city),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_weatherIcon.isNotEmpty)
                            Image.network(
                              'https://openweathermap.org/img/wn/$_weatherIcon@2x.png',
                              width: 100,
                              height: 100,
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Temperature: $_temperature°C',
                                  style: TextStyle(fontSize: 20),
                                ),
                                Text(
                                  'Min Temp: $_tempMin°C, Max Temp: $_tempMax°C',
                                  style: TextStyle(fontSize: 20),
                                ),
                                Text(
                                  'Description: $_description',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Pressure: $_pressure hPa',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Humidity: $_humidity%',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Sea Level: $_seaLevel hPa',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Clouds: $_clouds%',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Rain (last 1h): $_rain mm',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Sunset: $_sunset',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
    );
  }
}
