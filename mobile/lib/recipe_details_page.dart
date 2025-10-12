import 'package:flutter/material.dart';
import 'main_scaffold.dart';

class RecipeDetailsPage extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailsPage({super.key, required this.recipe});

  @override
  State<RecipeDetailsPage> createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  bool _isLiked = false;
  int _likes = 273;

  // Sample ingredients and steps - in a real app, these would come from the recipe data
  final List<Map<String, dynamic>> _ingredients = [
    {'name': '4 Eggs', 'checked': false},
    {'name': '1/2 Cup Butter', 'checked': false},
    {'name': '1/4 Cup Cacao Powder', 'checked': false},
    {'name': '2 Tbsp Maca Powder', 'checked': false},
    {'name': '1/2 Cup Chopped Walnuts', 'checked': false},
    {'name': '1 Cup Coconut Milk', 'checked': false},
    {'name': '2 Tbsp Honey', 'checked': false},
  ];

  final List<String> _steps = [
    'Heat coconut milk in a saucepan over medium heat. Add cacao powder and maca powder, whisking until smooth.',
    'In a separate bowl, beat eggs and gradually add the warm milk mixture while whisking continuously.',
    'Add butter and honey to the mixture, stirring until butter is completely melted.',
    'Fold in the chopped walnuts gently to distribute evenly throughout the mixture.',
    'Pour into serving bowls and refrigerate for at least 2 hours before serving.',
    'Garnish with additional walnuts and a drizzle of honey if desired. Serve chilled and enjoy your healthy treat!'
  ];

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likes += _isLiked ? 1 : -1;
    });
  }

  void _toggleIngredient(int index) {
    setState(() {
      _ingredients[index]['checked'] = !_ingredients[index]['checked'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.black,
                  ),
                  onPressed: _toggleLike,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade300, Colors.green.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.fastfood,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recipe Title
                        Text(
                          widget.recipe['name'] ?? 'Cacao Maca Walnut Milk',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Recipe Meta Info
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.recipe['type'] ?? 'Food',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 18, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              widget.recipe['time'] ?? '60 mins',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Chef Info and Likes
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.green.shade400,
                              child: Text(
                                widget.recipe['creator']?.toString().isNotEmpty == true 
                                    ? widget.recipe['creator'][0].toUpperCase()
                                    : 'E',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.recipe['creator'] ?? 'Elena Shelby',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Text(
                                    'Recipe Creator',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.favorite, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_likes Likes',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Description Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.recipe['description'] ?? 
                          'A delicious and nutritious blend of cacao, maca, and walnuts in creamy coconut milk. This superfood drink is perfect for a healthy breakfast or post-workout treat. Rich in antioxidants and natural energy boosters.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Ingredients Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ingredients',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._ingredients.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> ingredient = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ingredient['checked'] ? Colors.green.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: ingredient['checked'] ? Colors.green : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleIngredient(index),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: ingredient['checked'] ? Colors.green : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: ingredient['checked'] ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                    child: ingredient['checked']
                                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    ingredient['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: ingredient['checked'] ? Colors.green : Colors.black87,
                                      decoration: ingredient['checked'] ? TextDecoration.lineThrough : null,
                                      fontWeight: ingredient['checked'] ? FontWeight.normal : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Steps Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Steps',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._steps.asMap().entries.map((entry) {
                          int index = entry.key;
                          String step = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      step,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        
                        // Sample step image for the first step
                        if (_steps.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 48, bottom: 20),
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [Colors.green.shade200, Colors.green.shade400],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 120), // Account for bottom nav and action bar
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Add to favorites functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recipe saved to favorites!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Recipe',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Start cooking functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Happy cooking! Enjoy your meal!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Cooking',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}