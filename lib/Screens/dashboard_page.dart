import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
//import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/models.dart' as models;
import 'dart:io'; // Required for File operations
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class DashboardPage extends StatefulWidget {
  final User loggedInUser;
  final Account account;
  final String chefId;
  //final models.User nameofthecurrentuser;

  const DashboardPage({
    super.key,
    required this.loggedInUser,
    required this.account,
    required this.chefId,
  });

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  static late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ChantiersPage(chefId: widget.chefId),
      _ReportPage(chefId: widget.chefId),
      _PersonnelsPage(chefId: widget.chefId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chef de chantier Dashboard'),
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.construction),
            label: 'Chantiers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Personnels', // Label for personnel page
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ChantiersPage extends StatefulWidget {
  final String chefId; // Add the chefId in the widget

  const ChantiersPage({super.key, required this.chefId});

  @override
  _ChantiersPageState createState() => _ChantiersPageState();
}

class _ChantiersPageState extends State<ChantiersPage> {
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
            Query.equal('chefId', widget.chefId),
          ]);

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
              Text('Telephone: ${data['Telephone'] ?? 'N/A'}'),
              Text(
                'Time of Day : ${data['isMorning'] != null ? (data['isMorning'] ? 'matin' : 'soirée') : 'N/A'}',
              ),
              Text('Status: ${data['status'] ?? 'N/A'}'),
              Text(
                'Liked by equipier : ${data['likedbyequipier'] != null ? (data['likedbyequipier'] ? 'yes' : 'no') : 'not yet'}',
              ),
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

  void _updateChantierStatus(Document chantier) {
    final List<String> statusOptions = [
      'en cours',
      'interrompu',
      'terminé',
      'non réalisé'
    ];
    String? selectedStatus = chantier.data['status'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Status'),
          content: DropdownButtonFormField<String>(
            value: selectedStatus,
            items: statusOptions.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedStatus = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedStatus != null) {
                  try {
                    await _databases.updateDocument(
                      databaseId: '6744affc003e6e1f4a92',
                      collectionId: '6744b0050034f8c3d0ae',
                      documentId: chantier.$id,
                      data: {'status': selectedStatus},
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Status updated successfully!')),
                    );
                    Navigator.of(context).pop();
                    _fetchChantiers();
                  } catch (e) {
                    print('Error updating status: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update status')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Objet')),
                DataColumn(label: Text('Lieu')),
                DataColumn(label: Text('Actions')),
                DataColumn(label: Text('Map')),
              ],
              rows: _chantiers.map((chantier) {
                final ip = chantier.data['ip_address']; // Get IP from chantier
                return DataRow(cells: [
                  DataCell(Text(chantier.data['objet'] ?? 'No Objet')),
                  DataCell(Text(chantier.data['lieu'] ?? 'No Lieu')),
                  DataCell(
                    Row(
                      children: [
                        SizedBox(
                          width: 120, // Set a fixed width
                          child: ElevatedButton(
                            onPressed: () => _showChantierDetails(chantier),
                            child: const Text('Details'),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        SizedBox(
                          width: 150, // Adjust width as needed
                          child: ElevatedButton(
                            onPressed: () => _updateChantierStatus(chantier),
                            child: const Text('Update Status'),
                          ),
                        ),
                      ],
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
          );
  }
}

// Report page for creating and viewing reports
class _ReportPage extends StatefulWidget {
  final String chefId;
  const _ReportPage({required this.chefId});
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<_ReportPage> {
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
            Query.equal('chefId', widget.chefId),
          ]);

      setState(() {
        _chantiers = response.documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching chantiers: $e');
    }
  }

  void _createReport(Document chantier) async {
    final TextEditingController descriptionController = TextEditingController();
    String? selectedType;
    final List<String> reportTypes = ['difficulty', 'damage', 'accident'];
    XFile? image; // Variable to hold the selected image file

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create Report for ${chantier.data['objet']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Type of Issue'),
                items: reportTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  // Use ImagePicker to select an image
                  final ImagePicker picker = ImagePicker();
                  image = await picker.pickImage(source: ImageSource.gallery);
                  setState(() {});
                },
                child: Text(image == null ? 'Select Image' : 'Change Image'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedType != null &&
                    descriptionController.text.isNotEmpty &&
                    image != null) {
                  try {
                    // Initialize storage
                    final storage = Storage(Client()
                        .setEndpoint("https://cloud.appwrite.io/v1")
                        .setProject("674456140002ed9256dc"));

                    // Create input file
                    InputFile inFile;
                    if (kIsWeb) {
                      inFile = InputFile.fromBytes(
                        filename: image!.name,
                        bytes: await image!.readAsBytes(),
                      );
                    } else {
                      inFile = InputFile.fromPath(
                        path: image!.path,
                        filename: image!.name,
                      );
                    }

                    // Upload the image to the bucket
                    final file = await storage.createFile(
                      bucketId:
                          '67464b44002652a0856a', // Replace with your bucket ID
                      fileId: ID.unique(),
                      file: inFile,
                      permissions: [
                        Permission.read(Role.any()),
                        Permission.write(Role.users()),
                      ],
                    );

                    // Get the URL of the uploaded image
                    final imageUrl =
                        'https://cloud.appwrite.io/v1/storage/buckets/67464b44002652a0856a/files/${file.$id}/view';

                    // Create the report document with the image URL
                    await _databases.createDocument(
                      databaseId: '6744affc003e6e1f4a92',
                      collectionId: '67461a020025179dddb5',
                      documentId: ID.unique(),
                      data: {
                        'chantierId': chantier.$id,
                        'type': selectedType,
                        'description': descriptionController.text,
                        'timestamp': DateTime.now().toIso8601String(),
                        'images': imageUrl, // Store the image URL
                      },
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Report submitted successfully!')),
                    );
                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Error creating report: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create report.')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields.')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _seeReports(Document chantier) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '67461a020025179dddb5',
        queries: [
          Query.equal('chantierId', chantier.$id),
        ],
      );

      final reports = response.documents;

      if (reports.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No reports found for this chantier.')),
        );
        return;
      }

      // Display the list of reports
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Reports for ${chantier.data['objet']}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return ListTile(
                    title: Text(report.data['type'] ?? 'No Type'),
                    subtitle:
                        Text(report.data['description'] ?? 'No Description'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              _ReportDetailsPage(context, report),
                        ),
                      );
                    },
                  );
                },
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
    } catch (e) {
      print('Error fetching reports: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch reports.')),
      );
    }
  }

  Widget _ReportDetailsPage(BuildContext context, Document report) {
    final String imageUrl = report.data['images'];
    final String reportType = report.data['type'] ?? 'No Type';
    final String description = report.data['description'] ?? 'No Description';
    final String timestamp = report.data['timestamp'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reportType,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Reported On: $timestamp',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                '$imageUrl?project=674456140002ed9256dc&project=674456140002ed9256dc&mode=admin',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[200],
                    child: const Center(
                      child:
                          Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                (progress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Objet')),
                DataColumn(label: Text('Lieu')),
                DataColumn(label: Text('Actions')),
                DataColumn(label: Text('details')),
              ],
              rows: _chantiers.map((chantier) {
                return DataRow(cells: [
                  DataCell(Text(chantier.data['objet'] ?? 'No Objet')),
                  DataCell(Text(chantier.data['lieu'] ?? 'No Lieu')),
                  DataCell(
                    ElevatedButton(
                      onPressed: () => _createReport(chantier),
                      child: const Text('Create Report'),
                    ),
                  ),
                  DataCell(
                    ElevatedButton(
                      onPressed: () => _seeReports(chantier),
                      child: const Text('See Report'),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          );
  }
}

class _PersonnelsPage extends StatefulWidget {
  final String chefId;

  const _PersonnelsPage({required this.chefId, Key? key}) : super(key: key);

  @override
  _PersonnelsPageState createState() => _PersonnelsPageState();
}

class _PersonnelsPageState extends State<_PersonnelsPage> {
  late Databases _databases;
  List<Document> _chantiers = [];
  List<Map<String, dynamic>> _personnels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final Client client = Client()
        .setEndpoint("https://cloud.appwrite.io/v1")
        .setProject("674456140002ed9256dc");

    _databases = Databases(client);
    _fetchChantiers();
    _fetchPersonnels();
  }

  /// Fetch all chantiers assigned to the current chef
  Future<void> _fetchChantiers() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae',
        queries: [
          Query.equal('chefId', widget.chefId),
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
    }
  }

  /// Fetch all personnels and their names
  Future<void> _fetchPersonnels() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '674f74070007548bdb59', // Personnel collection ID
      );

      setState(() {
        _personnels = response.documents.map((doc) {
          return {
            'id': doc.$id,
            'name': doc.data['nom'] ?? 'Unknown',
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching personnels: $e');
    }
  }

  /// Update the chantier document to assign an equipier
  Future<void> _affectPersonnel(Document chantier, String equipierId) async {
    try {
      await _databases.updateDocument(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae',
        documentId: chantier.$id,
        data: {'equipierId': equipierId}, // Update the `equipierId` field
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personnel assigned successfully!')),
      );
      _fetchChantiers(); // Refresh the chantiers list
    } catch (e) {
      print('Error assigning personnel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error assigning personnel!')),
      );
    }
  }

  /// Show a dialog to select a personnel to assign
  void _showAffectPersonnelsDialog(Document chantier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Affect Personnel to ${chantier.data['objet']}'),
          content: _personnels.isEmpty
              ? const Text('No personnels available.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _personnels.map((personnel) {
                    return ListTile(
                      title: Text(personnel['name']),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _affectPersonnel(chantier, personnel['id']);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Assign'),
                      ),
                    );
                  }).toList(),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personnels'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Objet')),
                  DataColumn(label: Text('Lieu')),
                  DataColumn(label: Text('Durée')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _chantiers.map((chantier) {
                  return DataRow(cells: [
                    DataCell(Text(chantier.data['objet'] ?? 'N/A')),
                    DataCell(Text(chantier.data['lieu'] ?? 'N/A')),
                    DataCell(Text(chantier.data['duree'].toString())),
                    DataCell(
                      ElevatedButton(
                        onPressed: () => _showAffectPersonnelsDialog(chantier),
                        child: const Text('Affect Personnel'),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}
