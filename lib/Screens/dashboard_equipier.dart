import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'dart:io';
import '../main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DashboardEquipier extends StatefulWidget {
  final dynamic loggedInUser;
  final String equipierId;
  final dynamic account;

  const DashboardEquipier({
    super.key,
    required this.loggedInUser,
    required this.equipierId,
    required this.account,
  });

  @override
  _DashboardEquipierState createState() => _DashboardEquipierState();
}

class _DashboardEquipierState extends State<DashboardEquipier> {
  late Databases _databases;
  List<Document> _chantiers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final Client client = Client()
        .setEndpoint("https://cloud.appwrite.io/v1")
        .setProject("674456140002ed9256dc");

    _databases = Databases(client);
    _fetchChantiers();
  }

  Future<void> _fetchChantiers() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae',
        queries: [
          Query.equal(
              'equipierId', widget.equipierId), // Use equipierId for filtering
        ],
      );

      setState(() {
        _chantiers = response.documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching chantiers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error fetching chantiers. Please try again.')),
      );
    }
  }

  void showMapForChantier(double latitude, double longitude) {
    // Display a map with the chantier's location
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chantier Location'),
          content: SizedBox(
            width: 400, // Adjust width if needed
            height: 300, // Adjust height if needed
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(latitude, longitude), // Center on chantier
                zoom: 13.0, // Adjust zoom level
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(latitude, longitude),
                      builder: (ctx) => const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLocationDialog(String ip) async {
    const apiKey = 'c4386d3a043bfe2be5b0170ea87b9dd8';
    final url = 'http://api.ipstack.com/$ip?access_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latitude = data['latitude'] ?? 0.0;
        final longitude = data['longitude'] ?? 0.0;

        if (latitude != 0.0 && longitude != 0.0) {
          showMapForChantier(latitude, longitude); // Show the map
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location data unavailable.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch location data.')),
        );
      }
    } catch (e) {
      print('Error fetching location data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching location data.')),
      );
    }
  }

  Future<void> _updateLikedStatus(Document chantier, bool isLiked) async {
    try {
      // Update the likedbyequipier field in the database
      await _databases.updateDocument(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae',
        documentId: chantier.$id,
        data: {
          'likedbyequipier': isLiked, // Update likedbyequipier
        },
      );

      // Re-fetch chantiers after update to ensure UI is in sync with the database
      _fetchChantiers();
    } catch (e) {
      print('Error updating liked status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating liked status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Équipier Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.account.deleteSession(sessionId: 'current');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => MyApp(account: widget.account)),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Objet')),
                  DataColumn(label: Text('Lieu')),
                  DataColumn(label: Text('Actions')),
                  DataColumn(label: Text('Like')),
                  DataColumn(label: Text('Location')),
                ],
                rows: _chantiers.map((chantier) {
                  bool isLiked = chantier.data['likedbyequipier'] ?? false;
                  final ip =
                      chantier.data['ip_address']; // Get IP from chantier

                  return DataRow(cells: [
                    DataCell(Text(chantier.data['objet'] ?? 'No Objet')),
                    DataCell(Text(chantier.data['lieu'] ?? 'No Lieu')),
                    DataCell(
                      ElevatedButton(
                        onPressed: () => _showChantierDetails(chantier),
                        child: const Text('Details'),
                      ),
                    ),
                    DataCell(
                      Checkbox(
                        value: isLiked,
                        onChanged: (bool? value) {
                          setState(() {
                            isLiked = value ?? false;
                          });
                          // Update liked status in the database
                          _updateLikedStatus(chantier, isLiked);
                        },
                      ),
                    ),
                    DataCell(
                      ElevatedButton(
                        onPressed: ip != null
                            ? () => _showLocationDialog(ip)
                            : null, // Show location when IP is available
                        child: const Text('See Location'),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
    );
  }

  void _showChantierDetails(Document chantier) {
    showDialog(
      context: context,
      builder: (context) {
        final data = chantier.data;
        return AlertDialog(
          title: Text(data['objet'] ?? 'No Objet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lieu: ${data['lieu'] ?? 'No Lieu'}'),
              Text('Durée: ${data['duree'] ?? 'N/A'}'),
              Text('Debut Date: ${data['jour_debut'] ?? 'N/A'}'),
              Text('Telephone: ${data['telephone'] ?? 'N/A'}'),
              Text('Status: ${data['status'] ?? 'N/A'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
