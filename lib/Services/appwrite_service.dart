import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static const String appwriteEndpoint = 'https://cloud.appwrite.io/v1'; // Cloud endpoint
  static const String appwriteProjectId = '674456140002ed9256dc'; // Your project ID

  final Client client = Client();
  late final Account account;

  AppwriteService() {
    client
        .setEndpoint(appwriteEndpoint) // Set the Appwrite endpoint
        .setProject(appwriteProjectId); // Set your project ID
    account = Account(client);
  }
}
