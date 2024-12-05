import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:mmm_project/Screens/dashboard_equipier.dart';
import 'package:mmm_project/Screens/responsabledash_page.dart';
import 'Screens/dashboard_page.dart'; // Import the dashboard page for redirection

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Appwrite Client and Account service
  Client client = Client()
      .setEndpoint("https://cloud.appwrite.io/v1") // Your Appwrite endpoint
      .setProject("674456140002ed9256dc"); // Your Appwrite project ID

  Account account = Account(client);

  runApp(MaterialApp(
    home: MyApp(account: account), // Pass Account instance to MyApp
  ));
}

class MyApp extends StatefulWidget {
  final Account account;

  const MyApp({super.key, required this.account});

  @override
  MyAppState createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  models.User? loggedInUser;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  // Login function using Appwrite
  Future<void> login(String email, String password) async {
    try {
      // Attempt to create a session with email/password
      await widget.account
          .createEmailPasswordSession(email: email, password: password);

      // Get the logged-in user's details
      final user = await widget.account.get();
      setState(() {
        loggedInUser = user;
      });

      // Get the user's labels (roles)
      List userLabels = user.labels;

      if (userLabels.contains('responsable')) {
        // Navigate to Responsable Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResponsabledashPage(
              loggedInUser: user, // Pass user details to dashboard
              account: widget.account, // Pass account instance
            ),
          ),
        );
      } else if (userLabels.contains('chef')) {
        // Check the collection for matching email and password
        final database = Databases(widget.account.client);
        final response = await database.listDocuments(
          databaseId: '6744affc003e6e1f4a92', // Replace with your database ID
          collectionId: '6748c133000dc25dfb8e',
          queries: [
            Query.equal('email', email),
            Query.equal('password',
                password), // Avoid plaintext passwords in production
          ],
        );

        if (response.documents.isNotEmpty) {
          // Matching chef found, navigate to Dashboard
          // Get the ID of the first matching document
          final matchedDocument = response.documents.first;
          final chefId =
              matchedDocument.$id; // This is the ID from your collection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(
                loggedInUser: user,
                chefId:
                    chefId, // Pass the chefId from the collection, // Pass user details to dashboard
                account: widget.account,
                //userId : response. // Pass account instance
              ),
            ),
          );
        } else {
          // No matching chef found
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid credentials for chef role.')),
          );
        }
      } else if (userLabels.contains('equipier')) {
        // Check the collection for matching email and password
        final database = Databases(widget.account.client);
        final response = await database.listDocuments(
          databaseId: '6744affc003e6e1f4a92', // Replace with your database ID
          collectionId: '674f74070007548bdb59',
          queries: [
            Query.equal('email', email),
            Query.equal('password',
                password), // Avoid plaintext passwords in production
          ],
        );

        if (response.documents.isNotEmpty) {
          // Matching chef found, navigate to Dashboard
          // Get the ID of the first matching document
          final matchedDocument = response.documents.first;
          final equipierId =
              matchedDocument.$id; // This is the ID from your collection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardEquipier(
                loggedInUser: user,
                equipierId:
                    equipierId, // Pass the chefId from the collection, // Pass user details to dashboard
                account: widget.account,
                //userId : response. // Pass account instance
              ),
            ),
          );
        } else {
          // No matching chef found
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid credentials for chef role.')),
          );
        }
      }
    } catch (e) {
      print("Error logging in: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error logging in. Please check your credentials.')),
      );
    }
  }

  // Register function to create a user and log them in immediately
  Future<void> register(String email, String password, String name) async {
    try {
      await widget.account.create(
        userId: ID.unique(), // Unique user ID generated by Appwrite
        email: email,
        password: password,
        name: name,
      );
      // Log the user in after successful registration
      await login(email, password);
    } catch (e) {
      print("Error registering: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error registering. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appwrite Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              loggedInUser != null
                  ? 'Logged in as ${loggedInUser!.name}'
                  : 'Not logged in',
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    login(emailController.text, passwordController.text);
                  },
                  child: const Text('Login'),
                ),
                const SizedBox(width: 16.0),
              ],
            ),
            const SizedBox(height: 16.0),
            if (loggedInUser != null) ...[
              ElevatedButton(
                onPressed: () {
                  // Add your logout functionality here
                },
                child: const Text('Logout'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
