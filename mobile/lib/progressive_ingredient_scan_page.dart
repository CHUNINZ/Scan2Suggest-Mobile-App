import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/api_service.dart';
import 'ingredient_asset_picker.dart';
import 'recipe_details_page.dart';
import 'config/api_config.dart';

class ProgressiveIngredientScanPage extends StatefulWidget {
  const ProgressiveIngredientScanPage({Key? key}) : super(key: key);

  @override
  State<ProgressiveIngredientScanPage> createState() =>
      _ProgressiveIngredientScanPageState();
}

class _ProgressiveIngredientScanPageState
    extends State<ProgressiveIngredientScanPage> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  
  List<Map<String, dynamic>> _ingredientList = [];
  bool _isScanning = false;
  bool _isLoadingSession = true;
  String? _lastScannedIngredient;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Load session in background, but don't block the UI
    _loadExistingSession();
    
    // Fallback: if loading takes too long, show the main interface anyway
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoadingSession) {
        print('⚠️ Loading timeout - showing main interface');
        setState(() {
          _isLoadingSession = false;
          _ingredientList = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSession() async {
    setState(() => _isLoadingSession = true);
    try {
      // Add timeout to prevent infinite loading
      final result = await ApiService.getIngredientSession().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Session API timeout - proceeding with empty session');
          return {'success': false, 'message': 'Timeout'};
        },
      );
      print('📦 Session API response: $result');
      if (result['success'] == true) {
        setState(() {
          _ingredientList = List<Map<String, dynamic>>.from(
            result['ingredients'] ?? []
          );
        });
        print('📦 Loaded existing session: ${_ingredientList.length} ingredients');
        print('📦 Ingredient list: $_ingredientList');
      }
    } catch (e) {
      print('⚠️ Could not load existing session: $e');
      // Ensure we always exit loading state
      setState(() {
        _ingredientList = [];
        _isLoadingSession = false;
      });
    } finally {
      setState(() => _isLoadingSession = false);
    }
  }

  Widget _buildSessionLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.search,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.green,
                    strokeWidth: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // AI Processing text with animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: (0.7 + (_pulseAnimation.value * 0.3)).clamp(0.0, 1.0),
                child: const Text(
                  '🤖 Loading Ingredient Session...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Processing steps
          _buildSessionLoadingSteps(),
          
          const SizedBox(height: 24),
          
          // Progress indicator
          Container(
            width: 200,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _pulseAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Preparing your ingredient scanner...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionLoadingSteps() {
    final steps = [
      '🔍 Checking existing session',
      '📦 Loading saved ingredients',
      '🚀 Preparing scanner'
    ];
    
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final isActive = _pulseAnimation.value > (index * 0.33);
                  return Icon(
                    isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isActive ? Colors.green : Colors.grey[400],
                    size: 16,
                  );
                },
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final isActive = _pulseAnimation.value > (index * 0.33);
                  return Text(
                    step,
                    style: TextStyle(
                      color: isActive ? Colors.black87 : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showScanOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Scan Ingredient',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.green.shade700),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Use camera to scan ingredient'),
                onTap: () {
                  Navigator.pop(context);
                  _scanIngredient(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: Colors.blue.shade700),
                ),
                title: const Text('Choose from Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Pick a sample ingredient image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickIngredientFromAssets();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanIngredient(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (image == null) return;

      setState(() {
        _isScanning = true;
        _lastScannedIngredient = null;
      });

      final result = await ApiService.scanSingleIngredient(File(image.path));

      setState(() => _isScanning = false);

      if (result['success'] == true) {
        final detectedIngredient = result['detectedIngredient'];
        final wasAlreadyInList = result['wasAlreadyInList'] ?? false;
        
        setState(() {
          _lastScannedIngredient = detectedIngredient['name'];
          _ingredientList = List<Map<String, dynamic>>.from(
            result['currentList'] ?? []
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    wasAlreadyInList ? Icons.info_outline : Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      wasAlreadyInList
                          ? '${detectedIngredient['name']} already in list'
                          : '✓ Added ${detectedIngredient['name']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              backgroundColor: wasAlreadyInList ? Colors.orange : Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'No ingredient detected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickIngredientFromAssets() async {
    try {
      final String? assetPath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const IngredientAssetPickerPage()),
      );
      if (assetPath == null) return;
      await _scanIngredientFromAsset(assetPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scanIngredientFromAsset(String assetPath) async {
    try {
      setState(() {
        _isScanning = true;
        _lastScannedIngredient = null;
      });

      final fileName = assetPath.split('/').last;
      final ingredientName = _nameFromFileName(fileName);

      final result = await ApiService.addManualIngredient(ingredientName);

      setState(() => _isScanning = false);

      if (result['success'] == true) {
        setState(() {
          _lastScannedIngredient = ingredientName;
          _ingredientList = List<Map<String, dynamic>>.from(
            result['currentList'] ?? []
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('✓ Added $ingredientName', style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to add ingredient'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _nameFromFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;
    final withSpaces = base.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    if (withSpaces.isEmpty) return 'Ingredient';
    return withSpaces.split(' ').map((w) => w.isEmpty ? '' : (w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : ''))).join(' ');
  }

  Future<void> _showAddManualDialog() async {
    final TextEditingController controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Ingredient'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter ingredient name',
            prefixIcon: Icon(Icons.edit),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _addManualIngredient(result);
    }
  }

  Future<void> _addManualIngredient(String ingredientName) async {
    try {
      final result = await ApiService.addManualIngredient(ingredientName);

      if (result['success'] == true) {
        setState(() {
          _lastScannedIngredient = ingredientName;
          _ingredientList = List<Map<String, dynamic>>.from(
            result['currentList'] ?? []
          );
        });
        
        print('✅ Manual ingredient added - new list length: ${_ingredientList.length}');
        print('✅ New ingredient list: $_ingredientList');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Added ${result['addedIngredient']['name']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to add ingredient'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeIngredient(String ingredientName) async {
    try {
      final result = await ApiService.removeIngredient(ingredientName);

      if (result['success'] == true) {
        setState(() {
          _ingredientList = List<Map<String, dynamic>>.from(
            result['currentList'] ?? []
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed $ingredientName'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearSession() async {
    print('🧹 Clear session button pressed');
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('Remove all ingredients and start over?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    print('🧹 User confirmed clear: $confirm');

    if (confirm == true) {
      try {
        print('🧹 Calling API to clear session...');
        final result = await ApiService.clearIngredientSession();
        print('🧹 API response: $result');
        
        if (result['success'] == true) {
          setState(() {
            _ingredientList = [];
            _lastScannedIngredient = null;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'All ingredients cleared!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          print('🧹 Session cleared successfully');
        } else {
          throw Exception(result['message'] ?? 'Failed to clear session');
        }
      } catch (e) {
        print('❌ Error clearing session: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing session: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _getRecipes() async {
    if (_ingredientList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some ingredients first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.green,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Finding Recipes...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Matching ingredients to recipes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final result = await ApiService.getRecipesFromIngredients();
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      print('📊 Recipe API Response: $result');

      if (result['success'] == true) {
        final recipes = result['recipeSuggestions'] ?? [];
        
        // Filter to database recipes that contain ALL scanned ingredients (allow extras)
        final scannedNames = _ingredientList
            .map((ing) => (ing['name'] ?? '').toString().toLowerCase().trim())
            .where((n) => n.isNotEmpty)
            .toSet();

        final filtered = recipes.where((r) {
          try {
            if ((r['source'] ?? '') != 'database') return false;
            final recIngs = (r['ingredients'] as List? ?? [])
                .map((ing) => (ing is Map ? (ing['name'] ?? '') : ing).toString().toLowerCase().trim())
                .where((n) => n.isNotEmpty)
                .toSet();
            if (recIngs.isEmpty) return false;
            // Include recipe if it contains all scanned ingredients (superset allowed)
            return recIngs.containsAll(scannedNames);
          } catch (_) {
            return false;
          }
        }).toList();

        // Sort priority: highest overlap (desc), fewer extras (asc), higher rating (desc)
        filtered.sort((a, b) {
          Set<String> recIngsA = ((a['ingredients'] as List? ?? [])
              .map((ing) => (ing is Map ? (ing['name'] ?? '') : ing).toString().toLowerCase().trim())
              .where((n) => n.isNotEmpty)
              .toSet());
          Set<String> recIngsB = ((b['ingredients'] as List? ?? [])
              .map((ing) => (ing is Map ? (ing['name'] ?? '') : ing).toString().toLowerCase().trim())
              .where((n) => n.isNotEmpty)
              .toSet());

          final overlapA = scannedNames.intersection(recIngsA).length;
          final overlapB = scannedNames.intersection(recIngsB).length;
          if (overlapA != overlapB) return overlapB.compareTo(overlapA);

          final extraA = recIngsA.length - scannedNames.length;
          final extraB = recIngsB.length - scannedNames.length;
          if (extraA != extraB) return extraA.compareTo(extraB);

          final ratingA = (a['averageRating'] ?? a['rating'] ?? 0) as num;
          final ratingB = (b['averageRating'] ?? b['rating'] ?? 0) as num;
          return ratingB.compareTo(ratingA);
        });
        
        print('📋 Found ${recipes.length} recipes (before filter)');
        print('🎯 Showing ${filtered.length} exact database matches');
        
        if (filtered.isEmpty) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('No Recipes Found'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No recipes match your ingredients yet.'),
                    const SizedBox(height: 16),
                    const Text('Your ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._ingredientList.map((ing) => Text('• ${ing['name']}')),
                    
                    
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }

        // Navigate to recipe suggestions page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeSuggestionsListPage(
                ingredients: _ingredientList,
                recipes: filtered,
              ),
            ),
          );
        }
      } else {
        // API returned error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to get recipes'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      print('❌ Error getting recipes: $e');
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to get recipe suggestions:\n\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building ProgressiveIngredientScanPage - ingredient list length: ${_ingredientList.length}');
    print('🏗️ Ingredient list: $_ingredientList');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Build Your Ingredient List'),
      ),
      body: _isLoadingSession
          ? _buildSessionLoadingState()
          : Stack(
              children: [
                Column(
                  children: [
                    // Header section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border(
                          bottom: BorderSide(color: Colors.green.shade200, width: 2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.shopping_basket,
                            size: 48,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _ingredientList.isEmpty
                                ? 'Scan ingredients one by one'
                                : '${_ingredientList.length} ingredient${_ingredientList.length == 1 ? '' : 's'} scanned',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_ingredientList.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Add more or get recipe suggestions',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Content area
                    Expanded(
                      child: _ingredientList.isEmpty
                          ? _buildEmptyState()
                          : _buildIngredientList(),
                    ),

                    // Bottom action buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            offset: const Offset(0, -2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isScanning ? null : _showScanOptions,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Scan'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Colors.green, width: 2),
                                      foregroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isScanning ? null : _showAddManualDialog,
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Type'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Colors.green, width: 2),
                                      foregroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_ingredientList.length >= 1) ...[
                              const SizedBox(height: 12),
                              ScaleTransition(
                                scale: _ingredientList.length >= 2 ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _getRecipes,
                                    icon: const Icon(Icons.restaurant_menu, color: Colors.white),
                                    label: Text(
                                      _ingredientList.length >= 2
                                          ? 'Get Recipe Suggestions (${_ingredientList.length} ingredients)'
                                          : 'Get Recipe Suggestions',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      elevation: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Scanning overlay
                if (_isScanning)
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: Card(
                        margin: const EdgeInsets.all(20),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withOpacity(0.1),
                                  border: Border.all(color: Colors.green, width: 2),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.green,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Scanning Ingredient...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Analyzing image for ingredients',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    kToolbarHeight - 
                    200, // Account for header and bottom buttons
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Start Scanning!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan or type ingredients one by one.\nWhen done, tap "Get Recipes" for suggestions!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // Compact flow indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 6),
                  const Text('→', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Icon(Icons.add_circle, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 6),
                  const Text('→', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Icon(Icons.restaurant_menu, color: Colors.green.shade700, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Scan → Add → Get Recipes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _ingredientList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ingredient = _ingredientList[index];
        final isNew = ingredient['name'] == _lastScannedIngredient;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isNew ? Colors.green.shade50 : Colors.white,
            border: Border.all(
              color: isNew ? Colors.green : Colors.grey.shade300,
              width: isNew ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                ingredient['manualEntry'] == true ? Icons.edit : Icons.check_circle,
                color: Colors.green.shade700,
                size: 24,
              ),
            ),
            title: Text(
              ingredient['name'] ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              ingredient['manualEntry'] == true
                  ? 'Manually added'
                  : '${((ingredient['confidence'] ?? 0) * 100).toStringAsFixed(0)}% confidence',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _removeIngredient(ingredient['name']),
            ),
          ),
        );
      },
    );
  }
}

// Recipe suggestions list page
class RecipeSuggestionsListPage extends StatelessWidget {
  final List<Map<String, dynamic>> ingredients;
  final List<dynamic> recipes;

  const RecipeSuggestionsListPage({
    Key? key,
    required this.ingredients,
    required this.recipes,
  }) : super(key: key);

  String? _getImageUrl(List? images) {
    try {
      print('   🔍 _getImageUrl called with: $images');
      
      if (images == null || images.isEmpty) {
        print('   ❌ No images found');
        return null;
      }
      
      final imagePath = images[0];
      print('   🔍 First image path: $imagePath (type: ${imagePath.runtimeType})');
      
      if (imagePath == null || imagePath.toString().isEmpty) {
        print('   ❌ Empty image path');
        return null;
      }
      
      // If it's already a full URL, return as is
      if (imagePath.toString().startsWith('http')) {
        print('   ✅ Full URL: $imagePath');
        return imagePath.toString();
      }
      
      // If it's a relative path, construct full URL using ApiConfig
      final baseUrl = ApiConfig.safeBaseUrl.replaceAll('/api', ''); // Remove /api suffix
      final fullUrl = '$baseUrl$imagePath';
      print('   ✅ Constructed URL: $fullUrl');
      print('   📍 Using base URL from ApiConfig: $baseUrl');
      return fullUrl;
      
    } catch (e) {
      print('   ❌ Error getting image URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${recipes.length} Recipe${recipes.length == 1 ? '' : 's'} Found'),
      ),
      body: Column(
        children: [
          // Ingredient summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.green.shade200, width: 2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Ingredients:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ingredients.map((ing) {
                    return Chip(
                      label: Text(ing['name']),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.green.shade300),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Recipe list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                print('📋 Building recipe card at index $index:');
                print('   Title: ${recipe['title']}');
                print('   ID: ${recipe['id']}');
                print('   Full recipe: $recipe');
                return _buildRecipeCard(context, recipe);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Map<String, dynamic> recipe) {
    final images = recipe['images'] as List?;
    final imageUrl = _getImageUrl(images);
    
    // Debug: Print image info
    print('🖼️ Recipe: ${recipe['title']}');
    print('   Images array: $images');
    print('   Image URL: $imageUrl');

    return Card(
      key: ValueKey('recipe_${recipe['id']}_${recipe['title']}'), // Unique key for debugging
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            try {
              // Debug: Print recipe data
              print('🔍 Recipe data being passed to RecipeDetailsPage:');
              print('  Title: ${recipe['title']}');
              print('  Description: ${recipe['description']}');
              print('  Creator: ${recipe['creator']}');
              print('  ID: ${recipe['id']}');
              print('  Full recipe: $recipe');
              
              // Ensure recipe has required fields - spread first, then override with safe defaults
              final safeRecipe = {
                ...recipe, // Include all original fields first
                'title': recipe['title'] ?? 'Untitled Recipe',
                'description': recipe['description'] ?? 'No description available.',
                'creator': recipe['creator'] ?? 'Unknown',
                'images': recipe['images'] ?? [],
                'ingredients': recipe['ingredients'] ?? [],
                'instructions': recipe['instructions'] ?? [],
                'prepTime': recipe['prepTime'] ?? 0,
                'cookTime': recipe['cookTime'] ?? 0,
                'difficulty': recipe['difficulty'] ?? 'easy',
                'averageRating': recipe['averageRating'] ?? 0,
              };
              
              print('🔍 Safe recipe data:');
              print('  Title: ${safeRecipe['title']}');
              print('  Description: ${safeRecipe['description']}');
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailsPage(recipe: safeRecipe),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error opening recipe: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Always show image container, with placeholder if no image
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey.shade100,
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 180,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.green),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Image load error: $error');
                          return Container(
                            height: 180,
                            color: Colors.grey.shade200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  recipe['title'] ?? 'Recipe',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            recipe['title'] ?? 'Recipe',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['title'] ?? 'Untitled Recipe',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe['prepTime'] ?? 0} + ${recipe['cookTime'] ?? 0} min',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe['averageRating'] ?? 0}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


