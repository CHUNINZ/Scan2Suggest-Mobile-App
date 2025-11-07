import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class IngredientAssetPickerPage extends StatefulWidget {
  const IngredientAssetPickerPage({super.key});

  @override
  State<IngredientAssetPickerPage> createState() => _IngredientAssetPickerPageState();
}

class _IngredientAssetPickerPageState extends State<IngredientAssetPickerPage> {
  List<String> _assetPaths = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadIngredientAssets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIngredientAssets() async {
    try {
      final String manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestJson) as Map<String, dynamic>;

      final List<String> paths = manifestMap.keys
          .where((k) => k.startsWith('assets/ingredients/') || k.startsWith('assets/added_ingredients/'))
          .where((k) => k.endsWith('.png') || k.endsWith('.jpg') || k.endsWith('.jpeg') || k.endsWith('.webp') || k.endsWith('.avif'))
          .toList();

      setState(() {
        _assetPaths = paths
            .toSet()
            .toList()
          ..sort((a, b) => _basename(a).toLowerCase().compareTo(_basename(b).toLowerCase()));
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _assetPaths = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Ingredient Image'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assetPaths.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No ingredient assets found in assets/ingredients/ or assets/added_ingredients/', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search ingredient images',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.trim();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final filtered = _searchQuery.isEmpty
                              ? _assetPaths
                              : _assetPaths
                                  .where((path) => _basename(path)
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()))
                                  .toList();

                          if (filtered.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_off, size: 48, color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text('No images match your search', textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final path = filtered[index];
                              final name = _basename(path);
                              return InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.of(context).pop(path);
                                },
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(path, fit: BoxFit.cover),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  String _basename(String fullPath) {
    final parts = fullPath.split('/');
    final filename = parts.isNotEmpty ? parts.last : fullPath;
    final dot = filename.lastIndexOf('.');
    return dot > 0 ? filename.substring(0, dot) : filename;
  }
}


