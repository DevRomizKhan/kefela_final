// lib/scripts/import_splash_content.dart
// Run this script once to import the JSON data into Firestore
// Usage: flutter run lib/scripts/import_splash_content.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../services/splash_content_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ImportApp());
}

class ImportApp extends StatelessWidget {
  const ImportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Import Splash Content',
      home: const ImportScreen(),
    );
  }
}

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isImporting = false;
  String _status = 'Ready to import';
  int _importedCount = 0;

  Future<void> _importData() async {
    setState(() {
      _isImporting = true;
      _status = 'Loading JSON file...';
    });

    try {
      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/splash_content.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      setState(() {
        _status = 'Parsing data...';
      });

      // Prepare data for import
      List<Map<String, dynamic>> allContent = [];

      // Add Quran verses
      if (jsonData['quran_verses'] != null) {
        for (var verse in jsonData['quran_verses']) {
          allContent.add({
            'arabic': verse['arabic'],
            'bangla': verse['bangla'],
            'reference': verse['reference'],
            'type': 'quran',
          });
        }
      }

      // Add Hadiths
      if (jsonData['hadiths'] != null) {
        for (var hadith in jsonData['hadiths']) {
          allContent.add({
            'arabic': hadith['arabic'],
            'bangla': hadith['bangla'],
            'reference': hadith['reference'],
            'type': 'hadith',
          });
        }
      }

      setState(() {
        _status = 'Importing ${allContent.length} items to Firestore...';
      });

      // Import to Firestore
      final service = SplashContentService();
      await service.importFromJson(allContent);

      setState(() {
        _isImporting = false;
        _importedCount = allContent.length;
        _status = 'Successfully imported $_importedCount items!';
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text('Import Splash Content'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _importedCount > 0 ? Icons.check_circle : Icons.cloud_upload,
                size: 80,
                color: _importedCount > 0 ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              if (_isImporting)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                )
              else if (_importedCount == 0)
                ElevatedButton(
                  onPressed: _importData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Start Import',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _importedCount = 0;
                      _status = 'Ready to import';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Import Again',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
