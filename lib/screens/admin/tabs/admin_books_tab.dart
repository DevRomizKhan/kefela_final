// lib/screens/admin/tabs/admin_books_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/book_model.dart';
import '../../../services/books_service.dart';

class AdminBooksTab extends StatefulWidget {
  const AdminBooksTab({super.key});

  @override
  State<AdminBooksTab> createState() => _AdminBooksTabState();
}

class _AdminBooksTabState extends State<AdminBooksTab> {
  final BooksService _booksService = BooksService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchType = 'name'; // 'name' or 'writer'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Book>> _getBooksStream() {
    if (_searchQuery.isEmpty) {
      return _booksService.getAllBooks();
    }

    if (_searchType == 'name') {
      return _booksService.searchBooksByName(_searchQuery);
    } else {
      return _booksService.searchBooksByWriter(_searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Search Header - Made Green
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green, // Changed to green
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add the SizedBox BEFORE the Row, not inside it
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'বই ব্যবস্থাপনা',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddBookDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('নতুন বই'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar - Made smaller
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: _searchType == 'name'
                        ? 'বইয়ের নাম দিয়ে খুঁজুন...'
                        : 'লেখকের নাম দিয়ে খুঁজুন...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Search Type Toggle - Made smaller
                Row(
                  children: [
                    Expanded(
                      child: _buildSearchTypeButton(
                        'বইয়ের নাম',
                        'name',
                        Icons.book,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSearchTypeButton(
                        'লেখকের নাম',
                        'writer',
                        Icons.person,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Books List
          Expanded(
            child: StreamBuilder<List<Book>>(
              stream: _getBooksStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'কিছু ভুল হয়েছে',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final books = snapshot.data ?? [];

                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'কোন বই নেই' : 'কোন বই পাওয়া যায়নি',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        // Removed the import button from here
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return _buildBookCard(book);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Removed the floating action button
    );
  }

  Widget _buildSearchTypeButton(String label, String type, IconData icon) {
    final isSelected = _searchType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _searchType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10), // Reduced padding
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16, // Smaller icon
              color: isSelected ? Colors.green : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14, // Smaller font
                color: isSelected ? Colors.green : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    final isAvailable = book.stockQuantity > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8), // Reduced margin
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Icon - Changed to black
            Container(
              width: 50, // Smaller
              height: 70, // Smaller
              decoration: BoxDecoration(
                color: isAvailable ? Colors.grey[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book,
                size: 28, // Smaller icon
                color: Colors.teal, // Changed to black
              ),
            ),
            const SizedBox(width: 12),

            // Book Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.bookName,
                    style: const TextStyle(
                      fontSize: 15, // Slightly smaller
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (book.author.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            book.author,
                            style: TextStyle(
                              fontSize: 13, // Smaller
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // Stock Control
                  Row(
                    children: [
                      IconButton(
                        onPressed: book.stockQuantity > 0
                            ? () => _updateStock(book, book.stockQuantity - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                        iconSize: 24, // Smaller
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, // Reduced
                          vertical: 6, // Reduced
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${book.stockQuantity}',
                          style: TextStyle(
                            fontSize: 16, // Smaller
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _updateStock(book, book.stockQuantity + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.green,
                        iconSize: 24, // Smaller
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Buttons - Only edit blue, delete red
            Column(
              children: [
                IconButton(
                  onPressed: () => _showEditBookDialog(book),
                  icon: const Icon(Icons.edit),
                  color: Colors.blue, // Keep blue for edit
                  iconSize: 20, // Smaller
                  tooltip: 'সম্পাদনা করুন',
                ),
                IconButton(
                  onPressed: () => _confirmDelete(book),
                  icon: const Icon(Icons.delete),
                  color: Colors.red, // Keep red for delete
                  iconSize: 20, // Smaller
                  tooltip: 'মুছে ফেলুন',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateStock(Book book, int newQuantity) async {
    try {
      await _booksService.updateStockQuantity(book.id, newQuantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('স্টক আপডেট হয়েছে'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ত্রুটি: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddBookDialog() {
    final bookNameController = TextEditingController();
    final authorController = TextEditingController();
    final stockController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: Colors.green), // Changed to green
            SizedBox(width: 12),
            Text('নতুন বই যোগ করুন'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: bookNameController,
                  decoration: const InputDecoration(
                    labelText: 'বইয়ের নাম *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.book, color: Colors.teal), // Green icon
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'বইয়ের নাম প্রয়োজন';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: authorController,
                  decoration: const InputDecoration(
                    labelText: 'লেখকের নাম',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, color: Colors.black), // Green icon
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'স্টক সংখ্যা *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory, color: Colors.green), // Green icon
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'স্টক সংখ্যা প্রয়োজন';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number < 0) {
                      return 'সঠিক সংখ্যা দিন';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final book = Book(
                    id: '',
                    bookName: bookNameController.text.trim(),
                    author: authorController.text.trim(),
                    stockQuantity: int.parse(stockController.text),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  await _booksService.addBook(book);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('বই যোগ হয়েছে'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ত্রুটি: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('যোগ করুন'),
          ),
        ],
      ),
    );
  }

  void _showEditBookDialog(Book book) {
    final bookNameController = TextEditingController(text: book.bookName);
    final authorController = TextEditingController(text: book.author);
    final stockController = TextEditingController(text: book.stockQuantity.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.green), // Changed to green
            SizedBox(width: 12),
            Text('বই সম্পাদনা করুন'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: bookNameController,
                  decoration: const InputDecoration(
                    labelText: 'বইয়ের নাম *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.book, color: Colors.teal), // Green icon
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'বইয়ের নাম প্রয়োজন';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: authorController,
                  decoration: const InputDecoration(
                    labelText: 'লেখকের নাম',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, color: Colors.green), // Green icon
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'স্টক সংখ্যা *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory, color: Colors.green), // Green icon
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'স্টক সংখ্যা প্রয়োজন';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number < 0) {
                      return 'সঠিক সংখ্যা দিন';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _booksService.updateBook(book.id, {
                    'bookName': bookNameController.text.trim(),
                    'author': authorController.text.trim(),
                    'stockQuantity': int.parse(stockController.text),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('বই আপডেট হয়েছে'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ত্রুটি: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('আপডেট করুন'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('নিশ্চিত করুন'),
          ],
        ),
        content: Text('আপনি কি "${book.bookName}" বইটি মুছে ফেলতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('না'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _booksService.deleteBook(book.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('বই মুছে ফেলা হয়েছে'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ত্রুটি: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('হ্যাঁ, মুছে ফেলুন'),
          ),
        ],
      ),
    );
  }

// Removed: _importBooksFromJSON function completely
}