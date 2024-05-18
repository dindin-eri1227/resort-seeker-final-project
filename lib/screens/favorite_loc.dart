import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListFavoriteScreen extends StatefulWidget {
  const ListFavoriteScreen({Key? key}) : super(key: key);

  @override
  State<ListFavoriteScreen> createState() => _ListFavoriteScreenState();
}

class _ListFavoriteScreenState extends State<ListFavoriteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Locations'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('location').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var data =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                String name = data['name'] ?? '';
                String description = data['desc'] ?? '';
                return Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text(description),
                    trailing: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
