// lib/screens/member/tabs/books_tab.dart
import 'package:flutter/material.dart';
import '../../../models/book_model.dart';
import '../../../services/books_service.dart';

class BooksTab extends StatefulWidget {
  const BooksTab({super.key});

  @override
  State<BooksTab> createState() => _BooksTabState();
}

class _BooksTabState extends State<BooksTab> {
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
                const SizedBox(height: 16), // Fixed: Changed Sizedox to SizedBox and fixed property
                const Text(
                  'বই সংগ্রহ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
                      vertical: 14, // Reduced vertical padding
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
                        Icon(Icons.book_outlined, size: 64, color: Colors.teal),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'কোন বই নেই' : 'কোন বই পাওয়া যায়নি',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
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
      child: InkWell(
        onTap: () => _showBookDetails(book),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Icon - Color changes based on availability
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.grey[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.book,
                  size: 28,
                  color: isAvailable ? Colors.teal : Colors.black, // ← Changed here
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

                    // Stock Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, // Reduced
                        vertical: 6, // Reduced
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAvailable ? Icons.check_circle : Icons.cancel,
                            size: 14, // Smaller
                            color: isAvailable ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAvailable
                                ? 'স্টকে আছে (${book.stockQuantity})'
                                : 'স্টকে নেই',
                            style: TextStyle(
                              fontSize: 11, // Smaller
                              fontWeight: FontWeight.w600,
                              color: isAvailable ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20), // Smaller
            ],
          ),
        ),
      ),
    );
  }

  void _showBookDetails(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.book, color: Colors.teal), // Changed to green
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                book.bookName,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book.author.isNotEmpty) ...[
              _buildDetailRow('লেখক', book.author, Icons.person),
              const SizedBox(height: 12),
            ],
            _buildDetailRow(
              'স্টক',
              book.stockQuantity > 0
                  ? '${book.stockQuantity} টি বই আছে'
                  : 'স্টকে নেই',
              Icons.inventory,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green, // Green text
            ),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.green), // Green icons
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}