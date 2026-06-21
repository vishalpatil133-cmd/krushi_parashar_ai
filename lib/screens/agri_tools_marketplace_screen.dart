import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/secrets.dart';

class ToolModel {
  final String id;
  final String name;
  final double price;
  final String category;
  final String photoUrl;
  final String purchaseUrl;

  ToolModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.photoUrl,
    required this.purchaseUrl,
  });

  factory ToolModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return ToolModel(
      id: id,
      name: map['name'] as String? ?? 'अज्ञात साधन',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'Hand Tools',
      photoUrl: map['photoUrl'] as String? ?? '',
      purchaseUrl: map['purchaseUrl'] as String? ?? 'https://amazon.in',
    );
  }
}

class AgriToolsMarketplaceScreen extends StatefulWidget {
  const AgriToolsMarketplaceScreen({super.key});

  @override
  State<AgriToolsMarketplaceScreen> createState() => _AgriToolsMarketplaceScreenState();
}

class _AgriToolsMarketplaceScreenState extends State<AgriToolsMarketplaceScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'सर्व';
  List<ToolModel> _tools = [];
  bool _isLoading = true;

  final List<String> _categories = ['सर्व', 'Pumps', 'Seeds', 'Hand Tools'];

  // High-quality fallback local tools catalog with real agricultural photos
  final List<ToolModel> _fallbackTools = [
    ToolModel(
      id: 'tool_1',
      name: 'तण काढण्याचे यंत्र (Hand Weeder)',
      price: 499.0,
      category: 'Hand Tools',
      photoUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=500&auto=format&fit=crop&q=60',
      purchaseUrl: 'https://www.amazon.in/s?k=hand+weeder+agriculture',
    ),
    ToolModel(
      id: 'tool_2',
      name: 'सौर उर्जेवर चालणारा पाण्याचा पंप (Solar Water Pump)',
      price: 12499.0,
      category: 'Pumps',
      photoUrl: 'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=500&auto=format&fit=crop&q=60',
      purchaseUrl: 'https://www.amazon.in/s?k=solar+water+pump',
    ),
    ToolModel(
      id: 'tool_3',
      name: 'सेंद्रिय सोयाबीन बियाणे (Premium Soybean Seeds)',
      price: 799.0,
      category: 'Seeds',
      photoUrl: 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=500&auto=format&fit=crop&q=60',
      purchaseUrl: 'https://www.amazon.in/s?k=soybean+seeds+farming',
    ),
    ToolModel(
      id: 'tool_4',
      name: 'हात फवारणी पंप (Manual Crop Sprayer)',
      price: 1850.0,
      category: 'Pumps',
      photoUrl: 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=500&auto=format&fit=crop&q=60',
      purchaseUrl: 'https://www.amazon.in/s?k=agricultural+sprayer+pump',
    ),
    ToolModel(
      id: 'tool_5',
      name: 'हात कोळपे (Hand Seed Drill)',
      price: 2499.0,
      category: 'Seeds',
      photoUrl: 'https://images.unsplash.com/photo-1532386236358-a33d8a9434e3?w=500&auto=format&fit=crop&q=60',
      purchaseUrl: 'https://www.amazon.in/s?k=manual+seed+drill',
    ),
    ToolModel(
      id: 'tool_6',
      name: 'कुदळ आणि खुरपे जोड संच (Farming Hand Tools Combo)',
      price: 650.0,
      category: 'Hand Tools',
      photoUrl: 'https://images.unsplash.com/photo-1617155093730-a8bf47be792d?w=500&auto=format&fit=crop&q=60',
      purchaseUrl: 'https://www.amazon.in/s?k=farming+tools+set',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchTools();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTools() async {
    setState(() => _isLoading = true);
    
    // Check if Firebase is enabled using the URL in Secrets
    final dbUrl = Secrets.firebaseDatabaseUrl;
    final isFirebaseEnabled = dbUrl.startsWith('http') && !dbUrl.contains('YOUR_FIREBASE_DATABASE_URL_HERE');
    
    if (isFirebaseEnabled) {
      try {
        final db = FirebaseDatabase.instance;
        final ref = db.ref('tools');
        final snapshot = await ref.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final List<ToolModel> fetchedTools = [];
          data.forEach((key, value) {
            if (value is Map) {
              fetchedTools.add(ToolModel.fromMap(value, key.toString()));
            }
          });
          setState(() {
            _tools = fetchedTools;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        // Fallback logs handled gracefully
      }
    }

    // Fallback if offline or Firebase empty
    setState(() {
      _tools = List.from(_fallbackTools);
      _isLoading = false;
    });
  }

  Future<void> _launchBuyLink(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('खरेदी लिंक उघडता आली नाही: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);
    const softOffWhite = Color(0xFFFAFAF7);

    // Filter logic
    final filteredTools = _tools.where((tool) {
      final matchesCategory = _selectedCategory == 'सर्व' || tool.category == _selectedCategory;
      final matchesSearch = tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tool.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: softOffWhite,
      appBar: AppBar(
        title: const Text(
          'कृषी साधने बाजार',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTools,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filter Section
          Container(
            color: primaryGreen,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                // Search TextField
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: primaryGreen),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      hintText: 'साधन किंवा बियाणे शोधा...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Category Custom Chips (Guarantees high-contrast readability and overrides Material 3 bugs)
                SizedBox(
                  height: 44, // Increased height from 38 to 44 to prevent text clipping on scaled devices
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      final categoryText = category == 'सर्व'
                          ? 'सर्व साधने'
                          : category == 'Pumps'
                              ? 'पंप (Pumps)'
                              : category == 'Seeds'
                                  ? 'बियाणे (Seeds)'
                                  : 'साधने (Hand Tools)';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? accentGold : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? accentGold : Colors.grey.withOpacity(0.3),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                categoryText,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : primaryGreen,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Total Items Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'उपलब्ध उत्पादने: ${filteredTools.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[750],
                  ),
                ),
                if (_tools.isNotEmpty && _tools.first.id.startsWith('tool_'))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Text(
                      'ऑफलाईन मोड (स्थानिक कॅटलॉग)',
                      style: TextStyle(fontSize: 10, color: Colors.amber[900], fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // Tools Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                    ),
                  )
                : filteredTools.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'कोणतेही उत्पादन सापडले नाही.',
                              style: TextStyle(fontSize: 15, color: Colors.grey[500], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredTools.length,
                        itemBuilder: (context, index) {
                          final tool = filteredTools[index];
                          return Card(
                            color: Colors.white,
                            elevation: 1.5,
                            shadowColor: Colors.black.withOpacity(0.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.withOpacity(0.12)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tool Image
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      tool.photoUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: primaryGreen.withOpacity(0.04),
                                          child: const Icon(
                                            Icons.agriculture_rounded,
                                            size: 48,
                                            color: primaryGreen,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                
                                // Details Section
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Category Tag
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: primaryGreen.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tool.category,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: primaryGreen,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Tool Name
                                      Text(
                                        tool.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[850],
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Price
                                      Text(
                                        '₹ ${tool.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: accentGold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Buy Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 34,
                                        child: ElevatedButton(
                                          onPressed: () => _launchBuyLink(tool.purchaseUrl),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryGreen,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.shopping_cart, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                'खरेदी करा',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
