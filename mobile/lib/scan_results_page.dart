import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'recipe_details_page.dart';
import 'camera_scan_page.dart';

class ScanResultsPage extends StatefulWidget {
  final String scanType;
  final List<String> detectedItems;
  
  const ScanResultsPage({
    super.key, 
    required this.scanType, 
    required this.detectedItems
  });

  @override
  State<ScanResultsPage> createState() => _ScanResultsPageState();
}

class _ScanResultsPageState extends State<ScanResultsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _suggestedRecipes = [];
  List<Map<String, dynamic>> _commonIngredients = [];
  bool _isLoading = true;
  late AnimationController _slideAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeIn,
    ));
    
    _loadResults();
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 1500));
    
    _generateResults();
    
    setState(() {
      _isLoading = false;
    });
    
    _slideAnimationController.forward();
    _fadeAnimationController.forward();
    
    HapticFeedback.heavyImpact();
  }

  void _generateResults() {
    if (widget.scanType == 'Food') {
      _generateFoodResults();
    } else {
      _generateIngredientResults();
    }
  }

  void _generateFoodResults() async {
    if (widget.detectedItems.isEmpty) {
      setState(() {
        _isLoading = false;
        _commonIngredients = [];
        _suggestedRecipes = [];
      });
      return;
    }
    
    // Handle case where detectedItems contains error messages
    if (widget.detectedItems.first.contains('failed') || 
        widget.detectedItems.first.contains('error') ||
        widget.detectedItems.first.contains('No ')) {
      setState(() {
        _isLoading = false;
        _commonIngredients = [];
        _suggestedRecipes = [];
      });
      return;
    }
    
    try {
      // Call API to get ingredients and recipes for detected food
      // This will be implemented when the backend API is ready
      // final String detectedFood = widget.detectedItems.first;
      setState(() {
        _isLoading = false;
        _commonIngredients = [];
        _suggestedRecipes = [];
      });
    } catch (e) {
      print('Error loading food results: $e');
      setState(() {
        _isLoading = false;
        _commonIngredients = [];
        _suggestedRecipes = [];
      });
    }
  }

  void _generateIngredientResults() async {
    if (widget.detectedItems.isEmpty) {
      setState(() {
        _isLoading = false;
        _suggestedRecipes = [];
      });
      return;
    }
    
    try {
      // Call API to get recipes based on detected ingredients
      // This will be implemented when the backend API is ready
      setState(() {
        _isLoading = false;
        _suggestedRecipes = [];
      });
    } catch (e) {
      print('Error loading ingredient results: $e');
      setState(() {
        _isLoading = false;
        _suggestedRecipes = [];
      });
    }
  }


  void _toggleIngredientAvailability(int index) {
    setState(() {
      _commonIngredients[index]['available'] = 
          !_commonIngredients[index]['available'];
    });
    HapticFeedback.selectionClick();
  }

  void _openRecipeDetails(Map<String, dynamic> recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsPage(recipe: recipe),
      ),
    );
  }

  void _shareResults() {
    HapticFeedback.lightImpact();
    final itemsText = widget.detectedItems.join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared: ${widget.scanType} - $itemsText'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _scanAgain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScanPage(scanType: widget.scanType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Results',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: _shareResults,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildResultsContent(),
      bottomNavigationBar: _isLoading ? null : _buildBottomActions(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enhanced AI processing indicator
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
                Center(
                  child: Icon(
                    widget.scanType == 'Food' ? Icons.restaurant : Icons.search,
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
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: (0.7 + (_fadeAnimation.value * 0.3)).clamp(0.0, 1.0),
                child: Text(
                  '🤖 AI Processing Results...',
                  style: const TextStyle(
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
          _buildResultsProcessingSteps(),
          
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
              animation: _fadeAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _fadeAnimation.value,
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
            'Finding the best recipes for you...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsProcessingSteps() {
    final steps = widget.scanType == 'Food' 
        ? ['🍽️ Analyzing detected food', '📚 Searching recipe database', '✨ Generating suggestions']
        : ['🥬 Processing ingredients', '🔍 Matching recipes', '⭐ Ranking by relevance'];
    
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
                animation: _fadeAnimation,
                builder: (context, child) {
                  final isActive = _fadeAnimation.value > (index * 0.33);
                  return Icon(
                    isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isActive ? Colors.green : Colors.grey[400],
                    size: 16,
                  );
                },
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  final isActive = _fadeAnimation.value > (index * 0.33);
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

  Widget _buildResultsContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetectionResults(),
                const SizedBox(height: 24),
                if (widget.scanType == 'Food') ...[
                  _buildCommonIngredients(),
                  const SizedBox(height: 24),
                  _buildRecipeSuggestions(),
                ] else ...[
                  _buildRecipeSuggestions(),
                ],
                const SizedBox(height: 80), // Bottom padding for fixed buttons
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionResults() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detection Successful!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.scanType == 'Food' 
                          ? 'Detected: ${widget.detectedItems.first}'
                          : 'Found ${widget.detectedItems.length} ingredients',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.scanType == 'Ingredient') ...[
            const SizedBox(height: 20),
            const Text(
              'Detected Ingredients:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.detectedItems.asMap().entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade200,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.eco,
                        color: Colors.green.shade800,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.value,
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommonIngredients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.black87, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Recipe Ingredients',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Check off ingredients you already have at home:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),
        ..._commonIngredients.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> ingredient = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: ingredient['available'] ? Colors.green.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ingredient['available'] ? Colors.green : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ingredient['available'] 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _toggleIngredientAvailability(index),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: ingredient['available'] ? Colors.green : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ingredient['available'] ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: ingredient['available']
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ingredient['name'],
                              style: TextStyle(
                                fontSize: 16,
                                color: ingredient['available'] ? Colors.green.shade700 : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ingredient['amount'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (ingredient['essential'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Essential',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecipeSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.scanType == 'Food' ? Icons.restaurant_menu : Icons.lightbulb_outline,
              color: Colors.black87,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              widget.scanType == 'Food' ? 'Recipe Variations' : 'Suggested Recipes',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.scanType == 'Food' 
              ? 'Different ways to prepare this dish:'
              : 'Delicious recipes you can make:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),
        if (_suggestedRecipes.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No recipes found',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try scanning different ingredients',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _suggestedRecipes.map((recipe) => Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openRecipeDetails(recipe),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade200, Colors.green.shade300],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'By ${recipe['creator']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildRecipeInfo(Icons.access_time, recipe['time']),
                                  const SizedBox(width: 16),
                                  _buildRecipeInfo(Icons.star, '${recipe['rating']}'),
                                  if (widget.scanType == 'Ingredient' && recipe['matchedIngredients'] > 0) ...[
                                    const SizedBox(width: 16),
                                    _buildRecipeInfo(Icons.eco, '${recipe['matchedIngredients']} matched'),
                                  ],
                                ],
                              ),
                              if (recipe['difficulty'] != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor(recipe['difficulty']).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    recipe['difficulty'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getDifficultyColor(recipe['difficulty']),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildRecipeInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _scanAgain,
              icon: const Icon(Icons.document_scanner, size: 20),
              label: const Text(
                'Scan Again',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home, size: 20),
              label: const Text(
                'Back to Home',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}