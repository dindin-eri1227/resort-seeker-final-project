import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherScreen extends StatefulWidget {
  final LatLng position;

  const WeatherScreen({super.key, required this.position});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather for ${widget.position.latitude}, ${widget.position.longitude}'),
      ),
      body: Center(
        child: FutureBuilder<String>(
          future: getWeatherForLocation(widget.position),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Text('Current weather: ${snapshot.data}');
            } else {
              return const Text('No weather data available');
            }
          },
        ),
      ),
    );
  }

  Future<String> getWeatherForLocation(LatLng position) async {
    // Replace with your weather API call
    String apiKey = '38e25e99a5c10b161d960c1deb57ea11';
    String url =
        'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String weatherDescription = data['weather'][0]['description'];
      return weatherDescription;
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
