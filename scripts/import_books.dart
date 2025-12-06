// scripts/import_books.dart
// Run this script once to import all 132 books from JSON to Firebase
// Usage: dart run scripts/import_books.dart

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

// Helper function to convert Bengali numerals to English
int parseBengaliNumber(String bengaliNum) {
  const bengaliDigits = {
    '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
    '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9'
  };
  
  String englishNum = bengaliNum;
  bengaliDigits.forEach((bengali, english) {
    englishNum = englishNum.replaceAll(bengali, english);
  });
  
  return int.tryParse(englishNum) ?? 0;
}

Future<void> main() async {
  print('🚀 Starting book import process...');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  
  // Read JSON file
  final file = File('assets/books.json');
  if (!await file.exists()) {
    print('❌ Error: books.json file not found in assets folder');
    return;
  }
  
  final jsonString = await file.readAsString();
  final Map<String, dynamic> booksData = json.decode(jsonString);
  
  print('📚 Found ${booksData.length} books to import');
  
  int successCount = 0;
  int errorCount = 0;
  
  // Import each book
  for (var entry in booksData.entries) {
    try {
      final bookData = entry.value as Map<String, dynamic>;
      
      final book = {
        'bookName': bookData['bookName'] ?? '',
        'author': bookData['author'] ?? 'অজানা লেখক',
        'stockQuantity': parseBengaliNumber(bookData['quantity'] ?? '0'),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };
      
      await firestore.collection('books').add(book);
      successCount++;
      print('✅ Imported: ${book['bookName']}');
      
    } catch (e) {
      errorCount++;
      print('❌ Error importing ${entry.key}: $e');
    }
  }
  
  print('\n📊 Import Summary:');
  print('   ✅ Successfully imported: $successCount books');
  print('   ❌ Failed: $errorCount books');
  print('   📚 Total: ${booksData.length} books');
  print('\n🎉 Import process completed!');
}
