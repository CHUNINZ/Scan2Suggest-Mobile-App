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

  @override
  void initState() {
    super.initState();
    _loadIngredientAssets();
  }

  Future<void> _loadIngredientAssets() async {
    try {
      final String manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestJson) as Map<String, dynamic>;

      final List<String> paths = manifestMap.keys
          .where((k) => k.startsWith('assets/ingredients/'))
          .where((k) => k.endsWith('.png') || k.endsWith('.jpg') || k.endsWith('.jpeg') || k.endsWith('.webp'))
          .toList();

      setState(() {
        _assetPaths = paths.toSet().toList()..sort();
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No ingredient assets found in assets/ingredients/', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _assetPaths.length,
                  itemBuilder: (context, index) {
                    final path = _assetPaths[index];
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


