import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'recipe_details_page.dart';
import 'user_profile_page.dart';
import 'services/api_service.dart';
import 'config/api_config.dart';
import 'app_theme.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  // State variables
  List<Map<String, dynamic>> _recipeResults = [];
  List<Map<String, dynamic>> _userResults = [];
  List<String> _searchHistory = [];
  String _searchQuery = '';
  bool _isSearching = false;
  String? _errorMessage;
  
  // Filter state
  String? _selectedCategory;
  double? _minRating;
  int? _maxTime;
  String? _difficulty;
  
  // Trending/Popular data
  List<Map<String, dynamic>> _trendingRecipes = [];
  bool _loadingTrending = false;
  
  // Available filter options
  final List<String> _categories = ['All', 'Main Course', 'Dessert', 'Snack', 'Beverage', 'Soup', 'Salad'];
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSearchHistory();
    _loadTrendingRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Load search history from SharedPreferences
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  // Save search history to SharedPreferences
  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Remove if already exists (to avoid duplicates)
    _searchHistory.remove(query);
    
    // Add to beginning
    _searchHistory.insert(0, query);
    
    // Keep only last 10 searches
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    
    await prefs.setStringList('search_history', _searchHistory);
    setState(() {});
  }

  // Clear search history
  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _searchHistory = [];
    });
  }

  // Load trending recipes
  Future<void> _loadTrendingRecipes() async {
    setState(() {
      _loadingTrending = true;
    });
    
    try {
      final response = await ApiService.getTrendingRecipes(
        limit: 10,
        timeframe: 'week',
      );
      
      if (response['success'] == true && mounted) {
        final recipes = response['recipes'] as List? ?? [];
        setState(() {
          _trendingRecipes = recipes.map((recipe) => _transformRecipe(recipe)).toList();
          _loadingTrending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingTrending = false;
        });
      }
    }
  }

  // Search recipes and users
  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query.trim();
      _errorMessage = null;
    });
    
    if (query.trim().isEmpty) {
      setState(() {
        _recipeResults = [];
        _userResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    HapticFeedback.lightImpact();
    
    // Save to search history
    await _saveSearchHistory(query.trim());
    
    try {
      // Search recipes and users in parallel
      await Future.wait([
        _searchRecipes(query.trim()),
        _searchUsers(query.trim()),
      ]);
      
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  // Search recipes with filters
  Future<void> _searchRecipes(String query) async {
    try {
      final response = await ApiService.getRecipes(
        search: query,
        category: _selectedCategory != null && _selectedCategory != 'All' ? _selectedCategory : null,
        limit: 50,
      );
      
      if (response['success'] == true && mounted) {
        final recipes = response['recipes'] as List? ?? [];
        
        // Transform and apply additional filters
        var transformedRecipes = recipes.map((recipe) => _transformRecipe(recipe)).toList();
        
        // Apply client-side filters
        if (_minRating != null) {
          transformedRecipes = transformedRecipes.where((r) => (r['rating'] ?? 0) >= _minRating!).toList();
        }
        if (_maxTime != null) {
          transformedRecipes = transformedRecipes.where((r) => (r['duration'] ?? 0) <= _maxTime!).toList();
        }
        if (_difficulty != null) {
          transformedRecipes = transformedRecipes.where((r) => r['difficulty'] == _difficulty).toList();
        }
        
        setState(() {
          _recipeResults = transformedRecipes;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recipeResults = [];
        });
      }
      rethrow;
    }
  }

  // Search users
  Future<void> _searchUsers(String query) async {
    try {
      final response = await ApiService.searchUsers(
        query: query,
        limit: 30,
      );
      
      if (response['success'] == true && mounted) {
        final users = response['users'] as List? ?? [];
        
        setState(() {
          _userResults = users.map((user) => _transformUser(user)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userResults = [];
        });
      }
      rethrow;
    }
  }

  // Transform recipe data
  Map<String, dynamic> _transformRecipe(dynamic recipe) {
          final creator = recipe['creator'];
          final creatorName = creator is Map ? creator['name'] : creator?.toString() ?? 'Unknown';
          
          final imagesList = recipe['images'] as List? ?? [];
          final firstImage = imagesList.isNotEmpty ? imagesList[0] : null;
    
    final prepTime = recipe['prepTime'] ?? 0;
    final cookTime = recipe['cookTime'] ?? 0;
    final totalTime = prepTime + cookTime;
          
          return {
            'id': recipe['_id'] ?? recipe['id'],
            'name': recipe['title'] ?? 'Untitled',
            'creator': creatorName,
            'type': recipe['category'] ?? 'Food',
      'time': '${totalTime} mins',
      'duration': totalTime,
            'tags': recipe['tags'] ?? [],
            'rating': (recipe['averageRating'] ?? 0).toDouble(),
      'ratingsCount': recipe['ratingsCount'] ?? 0,
      'commentsCount': recipe['commentsCount'] ?? 0,
            'image': firstImage,
            'description': recipe['description'] ?? '',
            'ingredients': recipe['ingredients'] ?? [],
            'steps': recipe['instructions']?.map((inst) {
              if (inst is String) return inst;
              if (inst is Map) return inst['instruction'] ?? inst['step'] ?? 'Step';
              return inst.toString();
            }).toList() ?? [],
            'likesCount': recipe['likesCount'] ?? 0,
            'isLiked': recipe['isLiked'] ?? false,
            'isBookmarked': recipe['isBookmarked'] ?? false,
      'difficulty': recipe['difficulty'] ?? 'Medium',
    };
  }

  // Transform user data
  Map<String, dynamic> _transformUser(dynamic user) {
    return {
      'id': user['_id'] ?? user['id'],
      'name': user['name'] ?? 'Unknown User',
      'profileImage': user['profileImage'],
      'bio': user['bio'] ?? '',
      'location': user['location'] ?? '',
      'stats': user['stats'],
      'recipesCount': user['stats']?['recipesCreated'] ?? 0,
      'followersCount': user['stats']?['followersCount'] ?? 0,
      'followingCount': user['stats']?['followingCount'] ?? 0,
    };
  }

  // Show filters dialog
  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedCategory = null;
                          _minRating = null;
                          _maxTime = null;
                          _difficulty = null;
                        });
                        setState(() {
                          _selectedCategory = null;
                          _minRating = null;
                          _maxTime = null;
                          _difficulty = null;
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category filter
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category || (category == 'All' && _selectedCategory == null);
                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedCategory = category == 'All' ? null : category;
                              });
                              setState(() {
                                _selectedCategory = category == 'All' ? null : category;
                              });
                            },
                            selectedColor: AppTheme.primaryDarkGreen.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.primaryDarkGreen : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Rating filter
                      const Text(
                        'Minimum Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _minRating ?? 0,
                              min: 0,
                              max: 5,
                              divisions: 10,
                              label: _minRating != null ? _minRating!.toStringAsFixed(1) : '0.0',
                              activeColor: AppTheme.primaryDarkGreen,
                              onChanged: (value) {
                                setModalState(() {
                                  _minRating = value > 0 ? value : null;
                                });
                                setState(() {
                                  _minRating = value > 0 ? value : null;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              _minRating != null ? '${_minRating!.toStringAsFixed(1)}+' : 'Any',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Time filter
                      const Text(
                        'Maximum Time (minutes)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: (_maxTime ?? 180).toDouble(),
                              min: 10,
                              max: 180,
                              divisions: 17,
                              label: _maxTime != null ? '$_maxTime min' : 'Any',
                              activeColor: AppTheme.primaryDarkGreen,
                              onChanged: (value) {
                                setModalState(() {
                                  _maxTime = value.toInt();
                                });
        setState(() {
                                  _maxTime = value.toInt();
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              _maxTime != null ? '$_maxTime min' : 'Any',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Difficulty filter
                      const Text(
                        'Difficulty',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['All', ..._difficulties].map((diff) {
                          final isSelected = _difficulty == diff || (diff == 'All' && _difficulty == null);
                          return ChoiceChip(
                            label: Text(diff),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                _difficulty = diff == 'All' ? null : diff;
                              });
        setState(() {
                                _difficulty = diff == 'All' ? null : diff;
                              });
                            },
                            selectedColor: AppTheme.primaryDarkGreen.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.primaryDarkGreen : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              
              // Apply button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (_searchQuery.isNotEmpty) {
                        _performSearch(_searchQuery);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDarkGreen,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.surfaceWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getFullImageUrl(dynamic image) {
    if (image == null || image.toString().isEmpty) return null;
    
    final imageStr = image.toString();
    
    if (imageStr.startsWith('http://') || imageStr.startsWith('https://')) {
      return imageStr;
    }
    
    final baseUrl = ApiConfig.safeBaseUrl.replaceAll('/api', '');
    return '$baseUrl$imageStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceWhite,
            child: Row(
              children: [
                Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                          _performSearch(value);
                    }
                  });
                },
                    onSubmitted: _performSearch,
                decoration: InputDecoration(
                      hintText: 'Search recipes or users...',
                  prefixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                                  color: AppTheme.primaryDarkGreen,
                            ),
                          ),
                        )
                          : const Icon(Icons.search, color: AppTheme.primaryDarkGreen),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                                _performSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.textSecondary.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryDarkGreen, width: 2),
                  ),
                  filled: true,
                      fillColor: AppTheme.secondaryLightGreen.withOpacity(0.1),
                ),
              ),
            ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showFiltersDialog,
                  icon: Badge(
                    isLabelVisible: _selectedCategory != null || _minRating != null || _maxTime != null || _difficulty != null,
                    backgroundColor: AppTheme.warning,
                    child: const Icon(Icons.tune, color: AppTheme.primaryDarkGreen),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.secondaryLightGreen.withOpacity(0.2),
                        ),
            ),
          ],
        ),
      ),
          
          // Tabs
          if (_searchQuery.isNotEmpty)
            Container(
              color: AppTheme.surfaceWhite,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryDarkGreen,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryDarkGreen,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Recipes (${_recipeResults.length})'),
                  Tab(text: 'Users (${_userResults.length})'),
                ],
              ),
            ),
          
          // Content
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildEmptyState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecipeResults(),
                      _buildUserResults(),
                    ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      color: AppTheme.surfaceWhite,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search history
            if (_searchHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearSearchHistory,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _searchHistory.map((query) {
                  return ActionChip(
                    label: Text(query),
                    avatar: const Icon(Icons.history, size: 16),
                    onPressed: () {
                      _searchController.text = query;
                      _performSearch(query);
                    },
                    backgroundColor: AppTheme.secondaryLightGreen.withOpacity(0.2),
                    labelStyle: const TextStyle(
                      color: AppTheme.textPrimary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],
            
            // Trending recipes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: AppTheme.warning),
                    SizedBox(width: 8),
          Text(
                      'Trending Recipes',
            style: TextStyle(
              fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (_loadingTrending)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryDarkGreen,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_trendingRecipes.isEmpty && !_loadingTrending)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryLightGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
            child: Text(
                    'No trending recipes yet.\nStart cooking and sharing!',
              style: TextStyle(
                fontSize: 14,
                      color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
              )
            else
              ..._trendingRecipes.map((recipe) => _buildRecipeCard(recipe)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeResults() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    if (_recipeResults.isEmpty && !_isSearching) {
      return _buildNoResultsState('recipes');
    }
    
    return Container(
      color: AppTheme.surfaceWhite,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recipeResults.length,
        itemBuilder: (context, index) {
          return _buildRecipeCard(_recipeResults[index]);
        },
      ),
    );
  }

  Widget _buildUserResults() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    if (_userResults.isEmpty && !_isSearching) {
      return _buildNoResultsState('users');
    }
    
    return Container(
      color: AppTheme.surfaceWhite,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userResults.length,
        itemBuilder: (context, index) {
          return _buildUserCard(_userResults[index]);
        },
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final imageUrl = _getFullImageUrl(recipe['image']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailsPage(recipe: recipe),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Recipe image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: imageUrl == null
                      ? LinearGradient(
                          colors: [AppTheme.secondaryLightGreen, AppTheme.primaryDarkGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppTheme.secondaryLightGreen, AppTheme.primaryDarkGreen],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(Icons.restaurant, size: 32, color: AppTheme.surfaceWhite),
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.restaurant, size: 32, color: AppTheme.surfaceWhite),
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
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${recipe['creator']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          recipe['time'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.star,
                          size: 14,
                          color: (recipe['rating'] ?? 0) > 0 ? Colors.amber : AppTheme.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (recipe['rating'] ?? 0) > 0
                              ? '${recipe['rating'].toStringAsFixed(1)} (${recipe['ratingsCount'] ?? 0})'
                              : 'No ratings',
                          style: TextStyle(
                            fontSize: 12,
                            color: (recipe['rating'] ?? 0) > 0 ? AppTheme.textSecondary : AppTheme.textSecondary.withOpacity(0.5),
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
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final imageUrl = _getFullImageUrl(user['profileImage']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(
                userId: user['id'].toString(),
                userName: user['name'],
                preloadedUserData: user,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.secondaryLightGreen,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null
                    ? Text(
                        user['name'].toString()[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.surfaceWhite,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // User details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user['bio']?.toString().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        user['bio'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${user['recipesCount']} recipes',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.people, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${user['followersCount']} followers',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
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
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState(String type) {
    return Container(
      color: AppTheme.surfaceWhite,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No $type found',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Try a different search term or adjust your filters',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Container(
      color: AppTheme.surfaceWhite,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Search Failed',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ?? 'Something went wrong. Please try again.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _performSearch(_searchQuery),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDarkGreen,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: AppTheme.surfaceWhite, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
