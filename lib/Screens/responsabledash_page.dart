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

import '../main.dart';

class ResponsabledashPage extends StatefulWidget {
  final models.User loggedInUser;
  final Account account;

  const ResponsabledashPage({
    super.key,
    required this.loggedInUser,
    required this.account,
  });

  @override
  State<ResponsabledashPage> createState() => _ResponsabledashPageState();
}

class _ResponsabledashPageState extends State<ResponsabledashPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _ChantiersPage(),
      _VehiculesPage(),
      _MaterielsPage(),
      _PersonalsPage(),
      _ReportPage(),
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
        title: const Text('Directeur de chantier Dashboard'),
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
            icon: Icon(Icons.car_rental),
            label: 'Vehicules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_repair_service),
            label: 'Materiels',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Personals', // New section label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Reports',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _ChantiersPage extends StatefulWidget {
  @override
  _ChantiersPageState createState() => _ChantiersPageState();
}

class _ChantiersPageState extends State<_ChantiersPage> {
  late Databases _databases;
  List<Document> _chantiers = [];
  //late Users _users;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final Client client = Client()
        .setEndpoint("https://cloud.appwrite.io/v1")
        .setProject("674456140002ed9256dc");

    _databases = Databases(client);
    //_users = Users(client);
    _fetchChantiers();
  }

  Future<void> _fetchChantiers() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae',
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

  void _showCreateChantierForm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Chantier'),
          content: _ChantierForm(onSubmit: (
            String objet,
            String lieu,
            int duree,
            String jourDebut,
            String telephone,
            bool isMorning,
          ) {
            _createChantier(
                objet, lieu, duree, jourDebut, telephone, isMorning);
            Navigator.of(context).pop();
          }),
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
    final url = 'http://api.ipstack.com/$ip?access_key=$apiKey'; // URL with IP

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

  Future<String> _getChefName(String chefId) async {
    if (chefId.isEmpty) return 'N/A'; // Handle empty ID case

    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6748c133000dc25dfb8e', // Collection with chefs
        queries: [
          Query.equal('\$id', chefId), // Query by Document ID
        ],
      );

      if (response.documents.isNotEmpty) {
        final chefFullName =
            response.documents[0].data['Fullname']; // Get Fullname
        return chefFullName ?? 'N/A'; // Return 'N/A' if Fullname is null
      } else {
        return 'N/A'; // No matching document found
      }
    } catch (e) {
      print('Error fetching chef name: $e');
      return 'N/A'; // Return 'N/A' if there's an error
    }
  }

  Future<String> _getPersonnelName(String personnelId) async {
    if (personnelId.isEmpty) return 'N/A'; // Handle empty ID case

    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '674a4e86002fb5b0205c', // Collection with personnel
        queries: [
          Query.equal('\$id', personnelId), // Query by Document ID
        ],
      );

      if (response.documents.isNotEmpty) {
        final personnelName = response.documents[0].data['name']; // Get name
        return personnelName ?? 'N/A'; // Return 'N/A' if name is null
      } else {
        return 'N/A'; // No matching document found
      }
    } catch (e) {
      print('Error fetching personnel name: $e');
      return 'N/A'; // Return 'N/A' if there's an error
    }
  }

  Future<List<String>> _getVehiculeNames(List<String> vehiculeIds) async {
    List<String> vehiculeNames = [];

    try {
      for (var vehiculeId in vehiculeIds) {
        final response = await _databases.listDocuments(
          databaseId: '6744affc003e6e1f4a92',
          collectionId: '6744b2ca002ea68f53cd', // Collection with vehicles
          queries: [
            Query.equal('\$id', vehiculeId), // Query by Document ID
          ],
        );

        if (response.documents.isNotEmpty) {
          final vehiculeName = response.documents[0].data['name']; // Get name
          vehiculeNames.add(vehiculeName ??
              'N/A'); // Add the name to the list (or 'N/A' if not found)
        } else {
          vehiculeNames.add('N/A'); // If no matching document found, add 'N/A'
        }
      }
    } catch (e) {
      print('Error fetching vehicle names: $e');
      vehiculeNames.add(
          'N/A'); // Return 'N/A' if there's an error fetching any vehicule name
    }

    return vehiculeNames; // Return the list of vehicle names
  }

  Future<List<String>> _getMaterielNames(List<String> materielIds) async {
    List<String> materielNames = [];

    try {
      for (var materielId in materielIds) {
        final response = await _databases.listDocuments(
          databaseId: '6744affc003e6e1f4a92',
          collectionId: '6748e714002d261060b4', // Collection with materials
          queries: [
            Query.equal('\$id', materielId), // Query by Document ID
          ],
        );

        if (response.documents.isNotEmpty) {
          final materielName = response.documents[0].data['name']; // Get name
          materielNames.add(materielName ??
              'N/A'); // Add the name to the list (or 'N/A' if not found)
        } else {
          materielNames.add('N/A'); // If no matching document found, add 'N/A'
        }
      }
    } catch (e) {
      print('Error fetching materiel names: $e');
      materielNames.add(
          'N/A'); // Return 'N/A' if there's an error fetching any materiel name
    }

    return materielNames; // Return the list of material names
  }

  Future<void> _createChantier(
    String objet,
    String lieu,
    int duree,
    String jourDebut,
    String telephone,
    bool isMorning,
  ) async {
    try {
      await _databases.createDocument(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae',
        documentId: 'unique()',
        data: {
          'objet': objet,
          'lieu': lieu,
          'duree': duree,
          'jour_debut': jourDebut,
          'Telephone': telephone,
          'isMorning': isMorning,
        },
      );
      print('Chantier created successfully');
      _fetchChantiers(); // Refresh the list after creating a new chantier
    } catch (e) {
      print('Error creating chantier: $e');
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

              // FutureBuilder for Chef Name (as previously discussed)
              FutureBuilder<String>(
                future: _getChefName(
                    data['chefId']), // Fetch chef name using chefId
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(); // Loading indicator while fetching data
                  }
                  if (snapshot.hasError) {
                    return const Text('Error fetching chef name');
                  }
                  String chefName = snapshot.data ?? 'N/A';
                  return Text('Chef Name: $chefName');
                },
              ),

              // FutureBuilder for Personnel Name using personnelId
              FutureBuilder<String>(
                future: _getPersonnelName(data[
                    'personnelId']), // Fetch personnel name using personnelId
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(); // Loading indicator while fetching data
                  }
                  if (snapshot.hasError) {
                    return const Text('Error fetching personnel name');
                  }
                  String personnelName = snapshot.data ?? 'N/A';
                  return Text('Personnel Name: $personnelName');
                },
              ),

              // FutureBuilder for Vehicule Names using VehiculeId (List of IDs)
              FutureBuilder<List<String>>(
                future: _getVehiculeNames(List<String>.from(
                    data['VehiculeId'] ??
                        [])), // Fetch names for each vehicle ID
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(); // Loading indicator while fetching data
                  }
                  if (snapshot.hasError) {
                    return const Text('Error fetching vehicule names');
                  }

                  // Display the vehicule names, or 'N/A' if no names are found
                  List<String> vehiculeNames = snapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vehicules:'),
                      ...vehiculeNames.map(
                          (name) => Text(name)), // Display each vehicle's name
                    ],
                  );
                },
              ),
              // FutureBuilder for Materiel Names using MaterielId (List of IDs)
              FutureBuilder<List<String>>(
                future: _getMaterielNames(List<String>.from(data['Materield'] ??
                    [])), // Fetch names for each material ID
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(); // Loading indicator while fetching data
                  }
                  if (snapshot.hasError) {
                    return const Text('Error fetching materiel names');
                  }

                  List<String> materielNames = snapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Materiels:'),
                      ...materielNames.map(
                          (name) => Text(name)), // Display each material's name
                    ],
                  );
                },
              ),

              Text(
                'Time of Day : ${data['isMorning'] != null ? (data['isMorning'] ? 'matin' : 'soirée') : 'N/A'}',
              ),
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

  void _affectChef(Document chantier) async {
    bool isMorning = chantier.data['isMorning'];

    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6748c133000dc25dfb8e',
        queries: [
          Query.equal('role', 'chef'), // Filter by role = 'chef'
          Query.equal(
              'isMorning', isMorning), // Filter by the same isMorning value
        ],
      );

      final usersWithConditions = response.documents;
      print(
          'Users found: ${usersWithConditions.length}'); // Debugging statement

      if (usersWithConditions.isEmpty) {
        print('No users found matching the criteria');
      }

      // Display a dialog with a scrollable list of users that match the conditions
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select a Chef'),
            content: usersWithConditions.isEmpty
                ? const Text('No chefs available for the selected criteria.')
                : SingleChildScrollView(
                    child: Column(
                      children: usersWithConditions.map((userDoc) {
                        return ListTile(
                          title: Text(userDoc.data['Fullname'] ?? 'Unknown'),
                          onTap: () {
                            // Update the chantier with the selected user's ID
                            _updateChantierWithChef(chantier, userDoc.$id);
                            Navigator.of(context).pop(); // Close the dialog
                          },
                        );
                      }).toList(),
                    ),
                  ),
          );
        },
      );
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

// Function to update the chantier with the selected chef's ID
  Future<void> _updateChantierWithChef(Document chantier, String chefId) async {
    try {
      await _databases.updateDocument(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae',
        documentId: chantier.$id,
        data: {
          'chefId': chefId,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Chef successfully assigned to ${chantier.data['objet']}.'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error updating chantier: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _showCreateChantierForm,
                  child: const Text('Create New Chantier'),
                ),
                Expanded(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Objet')),
                      DataColumn(label: Text('Lieu')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _chantiers.map((chantier) {
                      final ip =
                          chantier.data['ip_address']; // Get IP from chantier
                      return DataRow(cells: [
                        DataCell(Text(chantier.data['objet'] ?? 'No Objet')),
                        DataCell(Text(chantier.data['lieu'] ?? 'No Lieu')),
                        DataCell(
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => _showChantierDetails(chantier),
                                child: const Text('Details'),
                              ),
                              ElevatedButton(
                                onPressed: () => _affectChef(chantier),
                                child: const Text('choose chef'),
                              ),
                              ElevatedButton(
                                onPressed: ip != null
                                    ? () => _showLocationDialog(ip)
                                    : null, // Show location when IP is available
                                child: const Text('map'),
                              ),
                              const SizedBox(width: 8.0),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
  }
}

class _ChantierForm extends StatefulWidget {
  final Function(
    String,
    String,
    int,
    String,
    String,
    bool,
  ) onSubmit;

  const _ChantierForm({required this.onSubmit});

  @override
  State<_ChantierForm> createState() => _ChantierFormState();
}

class _ChantierFormState extends State<_ChantierForm> {
  final _objetController = TextEditingController();
  final _lieuController = TextEditingController();
  final _dureeController = TextEditingController();
  final _jourDebutController = TextEditingController();
  final _telephoneController = TextEditingController();
  bool _isMorning = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _objetController,
            decoration: const InputDecoration(labelText: 'Objet'),
          ),
          TextField(
            controller: _lieuController,
            decoration: const InputDecoration(labelText: 'Lieu'),
          ),
          TextField(
            controller: _dureeController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Durée (in Half-days)'),
          ),
          TextField(
            controller: _jourDebutController,
            decoration:
                const InputDecoration(labelText: 'Début Date (YYYY-MM-DD)'),
          ),
          TextField(
            controller: _telephoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Telephone'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Is it in the morning?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMorning
                      ? Colors.green
                      : Colors.grey, // Green if true, grey if false
                ),
                onPressed: () {
                  setState(() {
                    _isMorning = true; // Set to true if 'Yes' is pressed
                  });
                },
                child: const Text(
                  'Yes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_isMorning
                      ? Colors.red
                      : Colors.grey, // Red if false, grey if true
                ),
                onPressed: () {
                  setState(() {
                    _isMorning = false; // Set to false if 'No' is pressed
                  });
                },
                child: const Text(
                  'No',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              final duree = int.tryParse(_dureeController.text) ?? 0;
              //final jourDebut = DateTime.tryParse(_jourDebutController.text);
              widget.onSubmit(
                _objetController.text,
                _lieuController.text,
                duree,
                _jourDebutController.text,
                _telephoneController.text,
                _isMorning,
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _VehiculesPage extends StatefulWidget {
  @override
  _VehiculesPageState createState() => _VehiculesPageState();
}

class _VehiculesPageState extends State<_VehiculesPage> {
  late Databases _databases;
  List<Document> _vehicules = [];
  List<Document> _chantiers = [];
  bool _isLoading = true;
  int _currentPage = 0;
  final int _itemsPerPage = 3;

  @override
  void initState() {
    super.initState();
    final Client client = Client()
        .setEndpoint("https://cloud.appwrite.io/v1")
        .setProject("674456140002ed9256dc");

    _databases = Databases(client);
    _fetchVehicules();
    _fetchChantiers();
  }

  Future<void> _fetchVehicules() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b2ca002ea68f53cd', // Vehicules collection
      );

      setState(() {
        _vehicules = response.documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching vehicules: $e');
    }
  }

  Future<void> _fetchChantiers() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae', // Chantiers collection
      );

      setState(() {
        _chantiers = response.documents;
      });
    } catch (e) {
      print('Error fetching chantiers: $e');
    }
  }

  Future<void> _affectVehiculeToChantier(
      Document vehicule, String chantierId) async {
    try {
      // Fetch the current chantier to get the existing vehiculeId array
      final chantier = await _databases.getDocument(
        databaseId: '6744affc003e6e1f4a92', // Replace with your database ID
        collectionId: '6744b0050034f8c3d0ae', // Chantiers collection
        documentId: chantierId,
      );

      List<String> vehiculeIds =
          List<String>.from(chantier.data['VehiculeId'] ?? []);

      // Add the selected vehicule ID if it’s not already in the array
      if (!vehiculeIds.contains(vehicule.$id)) {
        vehiculeIds.add(vehicule.$id);
      }

      // Update the chantier with the new vehiculeId array
      await _databases.updateDocument(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae', // Chantiers collection
        documentId: chantierId,
        data: {'VehiculeId': vehiculeIds},
      );

      print('Vehicule ${vehicule.data['name']} added to chantier $chantierId');
      _fetchChantiers(); // Refresh the chantiers list
    } catch (e) {
      print('Error assigning vehicule to chantier: $e');
    }
  }

  void _showChantiersForVehicule(Document vehicule) {
    final eligibleChantiers = _chantiers.where((chantier) {
      return chantier.data['isMorning'] == vehicule.data['isMorning'];
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Chantier'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: eligibleChantiers.length,
              itemBuilder: (context, index) {
                final chantier = eligibleChantiers[index];
                return ListTile(
                  title: Text(chantier.data['objet'] ?? 'Unnamed Chantier'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _affectVehiculeToChantier(vehicule, chantier.$id);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _nextPage() {
    if ((_currentPage + 1) * _itemsPerPage < _vehicules.length) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _showAddVehiculeForm,
                  child: const Text('Add Vehicule'),
                ),
                Expanded(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Is Morning')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: _vehicules
                        .skip(_currentPage * _itemsPerPage)
                        .take(_itemsPerPage)
                        .map((vehicule) {
                      return DataRow(cells: [
                        DataCell(Text(vehicule.data['name'] ?? 'No Name')),
                        DataCell(Text(
                            vehicule.data['isMorning']?.toString() ?? 'N/A')),
                        DataCell(
                          ElevatedButton(
                            onPressed: () =>
                                _showChantiersForVehicule(vehicule),
                            child: const Text('Affect'),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _previousPage,
                      child: const Text('Previous'),
                    ),
                    ElevatedButton(
                      onPressed: _nextPage,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  void _showAddVehiculeForm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Vehicule'),
          content: _VehiculeForm(onSubmit: (
            String name,
            bool isMorning,
          ) {
            _createVehicule(name, isMorning);
            Navigator.of(context).pop();
          }),
        );
      },
    );
  }

  Future<void> _createVehicule(String name, bool isMorning) async {
    try {
      await _databases.createDocument(
        databaseId: '6744affc003e6e1f4a92', // Replace with your database ID
        collectionId: '6744b2ca002ea68f53cd', // Replace with your collection ID
        documentId: 'unique()',
        data: {
          'name': name,
          'isMorning': isMorning,
        },
      );
      print('Vehicule added successfully');
      _fetchVehicules(); // Refresh the list after adding a new vehicule
    } catch (e) {
      print('Error adding vehicule: $e');
    }
  }
}

class _VehiculeForm extends StatefulWidget {
  final Function(String, bool) onSubmit;

  const _VehiculeForm({required this.onSubmit});

  @override
  State<_VehiculeForm> createState() => _VehiculeFormState();
}

class _VehiculeFormState extends State<_VehiculeForm> {
  final _nameController = TextEditingController();
  bool _isMorning = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Is it in the morning?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMorning ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isMorning = true;
                });
              },
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: !_isMorning ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isMorning = false;
                });
              },
              child: const Text(
                'No',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(_nameController.text, _isMorning);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _MaterielsPage extends StatefulWidget {
  @override
  _MaterielsPageState createState() => _MaterielsPageState();
}

class _MaterielsPageState extends State<_MaterielsPage> {
  late Databases _databases;
  List<Document> _materiels = [];
  List<Document> _chantiers = [];
  bool _isLoading = true;
  int _currentPage = 0;
  final int _itemsPerPage = 3;

  @override
  void initState() {
    super.initState();
    final Client client = Client()
        .setEndpoint("https://cloud.appwrite.io/v1")
        .setProject("674456140002ed9256dc");

    _databases = Databases(client);
    _fetchMateriels();
    _fetchChantiers();
  }

  Future<void> _fetchMateriels() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6748e714002d261060b4', // Materiels collection
      );

      setState(() {
        _materiels = response.documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching materiels: $e');
    }
  }

  Future<void> _fetchChantiers() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae', // Chantiers collection
      );

      setState(() {
        _chantiers = response.documents;
      });
    } catch (e) {
      print('Error fetching chantiers: $e');
    }
  }

  Future<void> _affectMaterielToChantier(
      Document materiel, String chantierId) async {
    try {
      // Fetch the current chantier to get the existing materielId array
      final chantier = await _databases.getDocument(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae', // Chantiers collection
        documentId: chantierId,
      );

      List<String> materielIds =
          List<String>.from(chantier.data['Materield'] ?? []);

      // Add the selected materiel ID if it’s not already in the array
      if (!materielIds.contains(materiel.$id)) {
        materielIds.add(materiel.$id);
      }

      // Update the chantier with the new materielId array
      await _databases.updateDocument(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae', // Chantiers collection
        documentId: chantierId,
        data: {'Materield': materielIds},
      );

      print('Materiel ${materiel.data['name']} added to chantier $chantierId');
      _fetchChantiers(); // Refresh the chantiers list
    } catch (e) {
      print('Error assigning materiel to chantier: $e');
    }
  }

  void _showChantiersForMateriel(Document materiel) {
    final eligibleChantiers = _chantiers.where((chantier) {
      return chantier.data['isMorning'] == materiel.data['isMorning'];
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Chantier'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: eligibleChantiers.length,
              itemBuilder: (context, index) {
                final chantier = eligibleChantiers[index];
                return ListTile(
                  title: Text(chantier.data['objet'] ?? 'Unnamed Chantier'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _affectMaterielToChantier(materiel, chantier.$id);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _nextPage() {
    if ((_currentPage + 1) * _itemsPerPage < _materiels.length) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _showAddMaterielForm,
                  child: const Text('Add Materiel'),
                ),
                Expanded(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Is Morning')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: _materiels
                        .skip(_currentPage * _itemsPerPage)
                        .take(_itemsPerPage)
                        .map((materiel) {
                      return DataRow(cells: [
                        DataCell(Text(materiel.data['name'] ?? 'No Name')),
                        DataCell(Text(
                            materiel.data['isMorning']?.toString() ?? 'N/A')),
                        DataCell(
                          ElevatedButton(
                            onPressed: () =>
                                _showChantiersForMateriel(materiel),
                            child: const Text('Affect'),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _previousPage,
                      child: const Text('Previous'),
                    ),
                    ElevatedButton(
                      onPressed: _nextPage,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  void _showAddMaterielForm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Materiel'),
          content: _MaterielForm(onSubmit: (
            String name,
            bool isMorning,
          ) {
            _createMateriel(name, isMorning);
            Navigator.of(context).pop();
          }),
        );
      },
    );
  }

  Future<void> _createMateriel(String name, bool isMorning) async {
    try {
      await _databases.createDocument(
        databaseId: '6744affc003e6e1f4a92', // Replace with your database ID
        collectionId: '6748e714002d261060b4', // Materiels collection
        documentId: 'unique()',
        data: {
          'name': name,
          'isMorning': isMorning,
        },
      );
      print('Materiel added successfully');
      _fetchMateriels(); // Refresh the list after adding a new materiel
    } catch (e) {
      print('Error adding materiel: $e');
    }
  }
}

class _MaterielForm extends StatefulWidget {
  final Function(String, bool) onSubmit;

  const _MaterielForm({required this.onSubmit});

  @override
  State<_MaterielForm> createState() => _MaterielFormState();
}

class _MaterielFormState extends State<_MaterielForm> {
  final _nameController = TextEditingController();
  bool _isMorning = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Is it in the morning?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMorning ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isMorning = true;
                });
              },
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: !_isMorning ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isMorning = false;
                });
              },
              child: const Text(
                'No',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(_nameController.text, _isMorning);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _PersonalsPage extends StatefulWidget {
  @override
  State<_PersonalsPage> createState() => _PersonalsPageState();
}

class _PersonalsPageState extends State<_PersonalsPage> {
  final _nameController = TextEditingController();
  final _nombreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late Databases _databases;
  List<Document> _personnels = [];
  List<Document> _chantiers = [];
  bool _isLoading = false;
  int _currentPage = 0;
  final int _itemsPerPage = 3;
  bool? _isMorning; // Add this declaration to avoid errors

  @override
  void initState() {
    super.initState();
    final Client client = Client()
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject('674456140002ed9256dc');

    _databases = Databases(client);
    _fetchPersonnels();
    _fetchChantiers();
  }

  Future<void> _fetchPersonnels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '674a4e86002fb5b0205c',
        queries: [
          Query.limit(_itemsPerPage),
          Query.offset(_currentPage * _itemsPerPage),
        ],
      );

      setState(() {
        _personnels = response.documents;
      });
    } catch (e) {
      print('Error fetching personnels: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchChantiers() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae',
      );

      setState(() {
        _chantiers = response.documents;
      });
    } catch (e) {
      print('Error fetching chantiers: $e');
    }
  }

  Future<void> _affectPersonnelToChantier(
      Document personnel, String chantierId) async {
    try {
      final chantier = await _databases.getDocument(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae',
        documentId: chantierId,
      );

      String personnelIds = personnel.$id;
      await _databases.updateDocument(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '6744b0050034f8c3d0ae',
        documentId: chantierId,
        data: {'personnelId': personnelIds},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Personnel ${personnel.data['name']} added to chantier ${chantier.data['objet']}'),
        ),
      );
      _fetchChantiers();
    } catch (e) {
      print('Error assigning personnel to chantier: $e');
    }
  }

  void _showChantiersForPersonnel(Document personnel) {
    final eligibleChantiers = _chantiers.where((chantier) {
      return chantier.data['isMorning'] == personnel.data['isMorning'];
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Chantier'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: eligibleChantiers.length,
              itemBuilder: (context, index) {
                final chantier = eligibleChantiers[index];
                return ListTile(
                  title: Text(chantier.data['objet'] ?? 'Unnamed Chantier'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _affectPersonnelToChantier(personnel, chantier.$id);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _addPersonnelData(
      String name, int nombre, bool isMorning) async {
    try {
      await _databases.createDocument(
        databaseId: '6744affc003e6e1f4a92',
        collectionId: '674a4e86002fb5b0205c',
        documentId: ID.unique(),
        data: {
          'name': name,
          'nombre': nombre,
          'isMorning': isMorning,
        },
      );
      print('Personnel added successfully!');
      _fetchPersonnels();
    } catch (e) {
      print('Error adding personnel: $e');
    }
  }

  void _showAddPersonnelForm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Personnel'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a number';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    const Text('Is Morning?'),
                    Radio<bool>(
                      value: true,
                      groupValue: _isMorning,
                      onChanged: (value) {
                        setState(() {
                          _isMorning = value;
                        });
                      },
                    ),
                    const Text('Yes'),
                    Radio<bool>(
                      value: false,
                      groupValue: _isMorning,
                      onChanged: (value) {
                        setState(() {
                          _isMorning = value;
                        });
                      },
                    ),
                    const Text('No'),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final name = _nameController.text;
                      final nombre = int.parse(_nombreController.text);
                      if (_isMorning != null) {
                        _addPersonnelData(name, nombre, _isMorning!);
                        _nameController.clear();
                        _nombreController.clear();
                        Navigator.of(context).pop();
                      } else {
                        print('Please select "Is Morning" option');
                      }
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personals Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPersonnelForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _personnels.isEmpty
                    ? const Center(child: Text('No data available'))
                    : Expanded(
                        child: ListView(
                          children: [
                            DataTable(
                              columns: const [
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Nombre')),
                                DataColumn(label: Text('Action')),
                              ],
                              rows: _personnels.map((personnel) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                        Text(personnel.data['name'] ?? 'N/A')),
                                    DataCell(Text(
                                        personnel.data['nombre']?.toString() ??
                                            'N/A')),
                                    DataCell(
                                      ElevatedButton(
                                        onPressed: () =>
                                            _showChantiersForPersonnel(
                                                personnel),
                                        child: const Text('Affect Chantier'),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                          _fetchPersonnels();
                        }
                      : null,
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _personnels.length == _itemsPerPage
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                          _fetchPersonnels();
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Report page for creating and viewing reports
class _ReportPage extends StatefulWidget {
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
                DataColumn(label: Text('details')),
              ],
              rows: _chantiers.map((chantier) {
                return DataRow(cells: [
                  DataCell(Text(chantier.data['objet'] ?? 'No Objet')),
                  DataCell(Text(chantier.data['lieu'] ?? 'No Lieu')),
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
