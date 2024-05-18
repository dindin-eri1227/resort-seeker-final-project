import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_etr/screens/favorite_loc.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  bool isLoading = false;
  Set<Marker> markers = {};
  LatLng defaultLocation = const LatLng(15.9742, 120.7631); // Pangasinan

  late GoogleMapController mapController;
  TextEditingController placeAddressController = TextEditingController();
  TextEditingController placeReviewController = TextEditingController();
  TextEditingController placeRatingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFavoritePlaces();
    searchLocations();
  }

  Future<void> fetchFavoritePlaces() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('location').get();

    if (snapshot.docs.isNotEmpty) {
      for (final DocumentSnapshot doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final double latitude = data['latitude'] ?? 0.0;
        final double longitude = data['longitude'] ?? 0.0;
        final String placeAddress = data['address'] ?? '';
        final String placeReview = data['review'] ?? '';
        final String placeRating = data['rating'] ?? '';

        addMarker(LatLng(latitude, longitude), placeAddress, placeReview, placeRating);
      }
    }
  }

  Future<void> searchLocations() async {
    setState(() {
      isLoading = true;
    });
    final List<Map<String, dynamic>> places = await getResortsAndDestinations();

    for (final place in places) {
      final LatLng position = LatLng(place['latitude'], place['longitude']);
      addMarker(position, place['address'], place['review'], place['rating']);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> getResortsAndDestinations() async {
    // Simulated API call to fetch resorts and destinations
    await Future.delayed(Duration(seconds: 2)); // Simulate network delay
    return [
      {
        'latitude': 15.9812,
        'longitude': 120.7651,
        'address': 'Resort A',
        'review': 'Great place!',
        'rating': '5'
      },
      // Add more locations if needed
    ];
  }

  void add() async {
    if (markers.isNotEmpty) {
      try {
        String address = placeAddressController.text;
        String review = placeReviewController.text;
        String rating = placeRatingController.text;
        String identifier = '$address-$review-$rating';
        DocumentReference docRef =
            FirebaseFirestore.instance.collection('location').doc(identifier);
        DocumentSnapshot docSnapshot = await docRef.get();
        if (!docSnapshot.exists) {
          for (var marker in markers) {
            await docRef.set({
              'address': address,
              'review': review,
              'rating': rating,
              'latitude': marker.position.latitude,
              'longitude': marker.position.longitude,
            });
          }
          placeAddressController.clear();
          placeReviewController.clear();
          placeRatingController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Place added favorite successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green,
            ),
          );
          fetchFavoritePlaces();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This place already exists.',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.yellowAccent,
            ),
          );
        }
      } catch (e) {
        print('Error adding place: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to add place. Please try again later.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showAddPlaceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.2,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Gap(10),
                    Container(
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_pin,
                            color: Colors.red,
                          ),
                          Text(
                            'Add Favorite Place',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    TextField(
                      controller: placeAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 12.0,
                        ),
                      ),
                    ),
                    const Gap(8),
                    TextField(
                      controller: placeReviewController,
                      decoration: const InputDecoration(
                        labelText: 'Review',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 12.0,
                        ),
                      ),
                    ),
                    const Gap(8),
                    TextField(
                      controller: placeRatingController,
                      decoration: const InputDecoration(
                        labelText: 'Rating',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 12.0,
                        ),
                      ),
                    ),
                    const Gap(5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            add();
                            Navigator.of(context).pop();
                          },
                          style: const ButtonStyle(
                              backgroundColor:
                                  MaterialStatePropertyAll(Colors.green)),
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void addMarker(LatLng position, String placeAddress, String placeReview, String placeRating) {
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(position.toString()),
          position: position,
          infoWindow: InfoWindow(
            title: placeAddress,
            snippet: placeReview,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeatherScreen(position: position),
                ),
              );
            },
          ),
          onTap: () {
            showDeletePlaceDialog(position);
          },
        ),
      );
    });
  }

  Future<void> getWeatherForLocation(LatLng position) async {
    // Replace with your weather API call
    String apiKey = '38e25e99a5c10b161d960c1deb57ea11';
    String url =
        'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String weather = data['weather'][0]['description'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Current weather: $weather',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to fetch weather data. Please try again later.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showDeletePlaceDialog(LatLng position) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('location')
          .where('latitude', isEqualTo: position.latitude)
          .where('longitude', isEqualTo: position.longitude)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final Map<String, dynamic> data =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        final String placeAddress = data['address'] ?? '';
        final String placeReview = data['review'] ?? '';
        final String placeRating = data['rating'] ?? '';

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.2,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Gap(10),
                        Container(
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_pin,
                                color: Colors.red,
                              ),
                              Text(
                                'Delete Place Location',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                        const Gap(8),
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(text: placeAddress),
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 12.0,
                            ),
                          ),
                        ),
                        const Gap(8),
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(text: placeReview),
                          decoration: const InputDecoration(
                            labelText: 'Reviews',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 12.0,
                            ),
                          ),
                        ),
                        const Gap(8),
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(text: placeRating),
                          decoration: const InputDecoration(
                            labelText: 'Ratings',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 12.0,
                            ),
                          ),
                        ),
                        const Gap(8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await deleteFromFirebase(position);
                                Navigator.of(context).pop();
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.red),
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location not found in database.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error fetching place details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to fetch place details. Please try again later.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteFromFirebase(LatLng position) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('location')
          .where('latitude', isEqualTo: position.latitude)
          .where('longitude', isEqualTo: position.longitude)
          .get();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      markers.removeWhere((marker) =>
          marker.position.latitude == position.latitude &&
          marker.position.longitude == position.longitude);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Place deleted successfully!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting place from Firebase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to delete place from Firebase. Please try again later.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void setToLocation(LatLng position) {
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(position.toString()),
          position: position,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              zoomControlsEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              initialCameraPosition: CameraPosition(
                target: defaultLocation,
                zoom: 15,
              ),
              onTap: (position) {
                if (markers.any((marker) => marker.position == position)) {
                  showDeletePlaceDialog(position);
                } else {
                  setToLocation(position);
                  showAddPlaceDialog();
                }
              },
              markers: markers,
              onMapCreated: (controller) {
                mapController = controller;
              },
            ),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ListFavoriteScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.list_rounded,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherScreen extends StatelessWidget {
  final LatLng position;

  const WeatherScreen({required this.position});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather for ${position.latitude}, ${position.longitude}'),
      ),
      body: Center(
        child: FutureBuilder(
          future: getWeatherForLocation(position),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Text('Current weather: ${snapshot.data}');
            } else {
              return Text('No weather data available');
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
      return data['weather'][0]['description'];
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
