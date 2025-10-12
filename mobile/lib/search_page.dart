import 'package:flutter/material.dart';
import 'recipe_details_page.dart';

class SearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> recipes;

  const SearchPage({super.key, required this.recipes});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredRecipes = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredRecipes = widget.recipes;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRecipes(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredRecipes = widget.recipes;
      } else {
        _filteredRecipes = widget.recipes.where((recipe) {
          return recipe['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                 recipe['creator'].toString().toLowerCase().contains(query.toLowerCase()) ||
                 (recipe['tags'] as List).any((tag) => 
                   tag.toString().toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  void _openRecipeDetails(Map<String, dynamic> recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsPage(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search Recipes',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: _filterRecipes,
                decoration: InputDecoration(
                  hintText: 'Search Filipino recipes...',
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterRecipes('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            
            // Results
            Expanded(
              child: _filteredRecipes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (context, index) {
                        return _buildRecipeCard(_filteredRecipes[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Start typing to search' : 'No recipes found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Try searching for "adobo", "sinigang", or "bibingka"'
                : 'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () => _openRecipeDetails(recipe),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Recipe image placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade300, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.fastfood, size: 32, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              
              // Recipe details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${recipe['creator']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          recipe['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          recipe['rating']?.toString() ?? '4.5',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}