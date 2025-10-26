import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'recipe_details_page.dart';
import 'user_profile_page.dart';
import 'search_page.dart';
import 'app_theme.dart';
import 'services/api_service.dart';
import 'config/api_config.dart';
import '../widgets/loading_skeletons.dart';

class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({super.key});

  @override
  State<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadFeed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh feed when returning to this page to get updated profile images
    if (!_isLoading && _recipes.isNotEmpty) {
      _loadFeed();
    }
  }

  Future<void> _initializeAndLoadFeed() async {
    // Initialize token first
    await ApiService.initializeToken();
    // Then load the feed
    await _loadFeed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMorePages) {
        _loadMoreRecipes();
      }
    }
  }

  Future<void> _loadFeed() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _currentPage = 1;
      });

      // Ensure token is initialized before making the request
      await ApiService.initializeToken();
      
      final response = await ApiService.getSocialFeed(page: 1, limit: 10);

      if (response['success'] == true && mounted) {
        final recipes = response['recipes'] as List? ?? [];
        final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
        
        setState(() {
          _recipes = recipes.map((recipe) => _transformRecipe(recipe)).toList();
          _hasMorePages = pagination['page'] < pagination['pages'];
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load feed');
      }
    } catch (e) {
      if (mounted) {
        // Handle specific error cases
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        
          if (errorMessage.contains('No token provided') || 
              errorMessage.contains('access denied') ||
              errorMessage.contains('401')) {
            errorMessage = 'Please sign in to view the social feed. Tap to go to login.';
            // Clear any invalid token
            await ApiService.clearToken();
          } else if (errorMessage.contains('Too many requests')) {
          errorMessage = 'Too many requests. Please wait a moment and try again.';
        } else if (errorMessage.contains('Failed to parse server response')) {
          errorMessage = 'Server response error. Please try again.';
        }
        
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = errorMessage;
        });
      }
    }
  }

  Future<void> _loadMoreRecipes() async {
    if (_isLoading || !_hasMorePages) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final nextPage = _currentPage + 1;
      final response = await ApiService.getSocialFeed(page: nextPage, limit: 10);

      if (response['success'] == true && mounted) {
        final recipes = response['recipes'] as List? ?? [];
        final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
        
        setState(() {
          _recipes.addAll(recipes.map((recipe) => _transformRecipe(recipe)).toList());
          _currentPage = nextPage;
          _hasMorePages = pagination['page'] < pagination['pages'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _transformRecipe(dynamic recipe) {
    final creator = recipe['creator'];
    final creatorId = creator is Map ? (creator['_id'] ?? creator['id']) : creator;
    final creatorName = creator is Map ? creator['name'] : 'Unknown';
    final creatorImage = creator is Map ? creator['profileImage'] : null;
    
    final imagesList = recipe['images'] as List? ?? [];
    final firstImage = imagesList.isNotEmpty ? imagesList[0] : null;
    
    final ingredientsList = recipe['ingredients'] as List? ?? [];
    final ingredientNames = ingredientsList.map((ing) {
      if (ing is String) return ing;
      if (ing is Map) return ing['name'] ?? 'Unknown ingredient';
      return ing.toString();
    }).toList();
    
    final instructionsList = recipe['instructions'] as List? ?? [];
    final instructionSteps = instructionsList.map((inst) {
      if (inst is String) return inst;
      if (inst is Map) return inst['instruction'] ?? inst['step'] ?? 'Step';
      return inst.toString();
    }).toList();
    
    // Debug: Log rating data
    print('🔍 Recipe: ${recipe['title']}');
    print('   averageRating: ${recipe['averageRating']}');
    print('   ratingsCount: ${recipe['ratingsCount']}');
    print('   ratings array length: ${(recipe['ratings'] as List?)?.length}');
    print('   commentsCount: ${recipe['commentsCount']}');
    print('   comments array length: ${(recipe['comments'] as List?)?.length}');
    
    return {
      'id': recipe['_id'] ?? recipe['id'],
      'name': recipe['title'] ?? 'Untitled',
      'description': recipe['description'] ?? '',
      'creator': creatorName,
      'creatorId': creatorId,
      'creatorImage': creatorImage,
      'image': firstImage,
      'type': recipe['category'] ?? 'Food',
      'time': '${(recipe['prepTime'] ?? 0) + (recipe['cookTime'] ?? 0)} mins',
      'ingredients': ingredientNames,
      'steps': instructionSteps,
      'likesCount': recipe['likesCount'] ?? 0,
      'rating': (recipe['averageRating'] ?? 0).toDouble(),
      'ratingsCount': recipe['ratingsCount'] ?? recipe['ratings']?.length ?? 0,
      'commentsCount': recipe['commentsCount'] ?? recipe['comments']?.length ?? 0,
      'views': recipe['views'] ?? 0, // Add views field
      'isLiked': recipe['isLiked'] ?? false,
      'isBookmarked': recipe['isBookmarked'] ?? false,
      'createdAt': recipe['createdAt'],
      'isFromFollowedUser': recipe['isFromFollowedUser'] ?? false, // Add this for UI indication
    };
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

  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Recently';
    
    try {
      final date = DateTime.parse(createdAt.toString());
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 7) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Future<void> _refreshFeed() async {
    HapticFeedback.lightImpact();
    await _loadFeed();
  }

  void _openRecipeDetails(Map<String, dynamic> recipe) async {
    HapticFeedback.selectionClick();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsPage(recipe: recipe),
      ),
    );
    
    // Update view count for this specific recipe without reloading entire feed
    final recipeId = recipe['id'];
    if (recipeId != null) {
      _updateRecipeViewCount(recipeId.toString());
    }
  }

  void _openUserProfile(Map<String, dynamic> recipe) {
    final creatorId = recipe['creatorId'];
    if (creatorId != null) {
      HapticFeedback.selectionClick();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(
            userId: creatorId.toString(),
            userName: recipe['creator'],
          ),
        ),
      );
    }
  }

  void _openSearch() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchPage(),
      ),
    );
  }

  Future<void> _toggleLike(Map<String, dynamic> recipe) async {
    HapticFeedback.lightImpact();
    
    try {
      final recipeId = recipe['id'];
      if (recipeId == null) return;
      
      // Store the current state for debugging
      final currentIsLiked = recipe['isLiked'] ?? false;
      final currentLikesCount = recipe['likesCount'] ?? 0;
      
      print('🔄 Toggling like for recipe: $recipeId');
      print('🔄 Current state - isLiked: $currentIsLiked, likesCount: $currentLikesCount');
      
      final response = await ApiService.likeRecipe(recipeId.toString());
      
      print('📥 Like response: $response');
      
      if (response['success'] == true && mounted) {
        setState(() {
          // Update the recipe in the list
          final index = _recipes.indexWhere((r) => r['id'] == recipeId);
          if (index != -1) {
            final newIsLiked = response['isLiked'] ?? !_recipes[index]['isLiked'];
            final newLikesCount = response['likesCount'] ?? _recipes[index]['likesCount'];
            
            _recipes[index]['isLiked'] = newIsLiked;
            _recipes[index]['likesCount'] = newLikesCount;
            
            print('✅ Updated recipe at index $index - isLiked: $newIsLiked, likesCount: $newLikesCount');
          } else {
            print('❌ Recipe not found in list for ID: $recipeId');
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['isLiked'] == true ? '❤️ Liked!' : 'Unliked'),
            backgroundColor: response['isLiked'] == true ? Colors.red : Colors.grey[700],
            duration: const Duration(seconds: 1),
          ),
        );
        
        // Update view count for this specific recipe without reloading entire feed
        _updateRecipeViewCount(recipeId);
      } else {
        print('❌ Like request failed: ${response['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like recipe: ${response['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Like error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleBookmark(Map<String, dynamic> recipe) async {
    HapticFeedback.lightImpact();
    
    try {
      final recipeId = recipe['id'];
      if (recipeId == null) return;
      
      final response = await ApiService.bookmarkRecipe(recipeId.toString());
      
      if (response['success'] == true && mounted) {
        setState(() {
          // Update the recipe in the list
          final index = _recipes.indexWhere((r) => r['id'] == recipeId);
          if (index != -1) {
            _recipes[index]['isBookmarked'] = response['isBookmarked'] ?? !_recipes[index]['isBookmarked'];
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['isBookmarked'] == true ? '🔖 Bookmarked!' : 'Removed bookmark'),
            backgroundColor: response['isBookmarked'] == true ? AppTheme.primaryDarkGreen : Colors.grey[700],
            duration: const Duration(seconds: 1),
          ),
        );
        
        // Update view count for this specific recipe without reloading entire feed
        _updateRecipeViewCount(recipeId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _updateRecipeViewCount(String recipeId) async {
    try {
      // Fetch updated recipe data from the server
      final response = await ApiService.getRecipe(recipeId);
      
      if (response['success'] == true && mounted) {
        final updatedRecipe = response['recipe'] as Map<String, dynamic>?;
        if (updatedRecipe != null) {
          setState(() {
            // Find and update the specific recipe in the list
            final index = _recipes.indexWhere((r) => r['id'] == recipeId);
            if (index != -1) {
              // Update only the view count and other relevant fields
              _recipes[index]['views'] = updatedRecipe['views'] ?? _recipes[index]['views'];
              _recipes[index]['likesCount'] = updatedRecipe['likesCount'] ?? _recipes[index]['likesCount'];
              _recipes[index]['commentsCount'] = updatedRecipe['commentsCount'] ?? _recipes[index]['commentsCount'];
              _recipes[index]['bookmarksCount'] = updatedRecipe['bookmarksCount'] ?? _recipes[index]['bookmarksCount'];
              _recipes[index]['rating'] = updatedRecipe['averageRating'] ?? _recipes[index]['rating'];
            }
          });
        }
      }
    } catch (e) {
      print('Error updating recipe view count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _recipes.isEmpty) {
      return ListSkeleton(
        itemCount: 5,
        itemBuilder: (context, index) => const RecipeCardSkeleton(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorMessage.contains('Please sign in') ? Icons.lock_outline : Icons.error_outline, 
              size: 64, 
              color: _errorMessage.contains('Please sign in') ? Colors.orange.shade300 : Colors.red.shade300
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage.contains('Please sign in') ? 'Authentication Required' : 'Error loading feed',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _loadFeed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDarkGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry', style: TextStyle(color: AppTheme.surfaceWhite)),
                ),
                if (_errorMessage.contains('Please sign in')) ...[
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/signin',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Sign In', style: TextStyle(color: AppTheme.surfaceWhite)),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    if (_recipes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshFeed,
        color: AppTheme.primaryDarkGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rss_feed,
                    size: 64,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No recipes in feed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No recipes available yet. Check back later for new content!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '⬇️ Pull down to refresh',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFeed,
      color: AppTheme.primaryDarkGreen,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 100),
        itemCount: _recipes.length + (_hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _recipes.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
              ),
            );
          }
          return _buildFeedCard(_recipes[index]);
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: _openSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryLightGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.textSecondary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppTheme.textSecondary.withOpacity(0.6),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search recipes and users...',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.tune,
                  color: AppTheme.textSecondary.withOpacity(0.4),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedCard(Map<String, dynamic> recipe) {
    final recipeImageUrl = _getFullImageUrl(recipe['image']);
    final creatorImageUrl = _getFullImageUrl(recipe['creatorImage']);
    
    return GestureDetector(
      onTap: () => _openRecipeDetails(recipe),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        decoration: AppTheme.cardDecoration(elevation: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header with creator info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _openUserProfile(recipe);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.secondaryLightGreen,
                    backgroundImage: creatorImageUrl != null ? NetworkImage(creatorImageUrl) : null,
                    child: creatorImageUrl == null
                        ? Text(
                            recipe['creator']?.toString().isNotEmpty == true
                                ? recipe['creator'].toString()[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.surfaceWhite,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _openUserProfile(recipe);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              recipe['creator'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (recipe['isFromFollowedUser'] == true) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryDarkGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.primaryDarkGreen.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Following',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryDarkGreen,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _getTimeAgo(recipe['createdAt']),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Recipe image
          recipeImageUrl != null
              ? Image.network(
                  recipeImageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.secondaryLightGreen, AppTheme.primaryDarkGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 60, color: AppTheme.surfaceWhite),
                      ),
                    );
                  },
                )
              : Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.secondaryLightGreen, AppTheme.primaryDarkGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.restaurant, size: 60, color: AppTheme.surfaceWhite),
                  ),
                ),
          
          // Recipe info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe['name'] ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (recipe['description']?.toString().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    recipe['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary.withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                // Action buttons row
                Row(
                  children: [
                    // Like button
                    IconButton(
                      onPressed: () => _toggleLike(recipe),
                      icon: Icon(
                        recipe['isLiked'] == true ? Icons.favorite : Icons.favorite_border,
                        color: recipe['isLiked'] == true ? Colors.red : AppTheme.textSecondary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text(
                      '${recipe['likesCount']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Comments indicator
                    Icon(Icons.comment_outlined, size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 2),
                    Text(
                      '${recipe['commentsCount'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Views indicator
                    Icon(Icons.visibility, size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 2),
                    Text(
                      '${recipe['views'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    // Rating indicator - always show
                    Icon(
                      Icons.star,
                      size: 18,
                      color: (recipe['rating'] ?? 0) > 0 ? Colors.amber : AppTheme.textSecondary.withOpacity(0.3),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      (recipe['rating'] ?? 0) > 0
                          ? '${(recipe['rating'] ?? 0).toStringAsFixed(1)}'
                          : 'No ratings',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (recipe['rating'] ?? 0) > 0 
                            ? AppTheme.textSecondary 
                            : AppTheme.textSecondary.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bookmark button
                    IconButton(
                      onPressed: () => _toggleBookmark(recipe),
                      icon: Icon(
                        recipe['isBookmarked'] == true ? Icons.bookmark : Icons.bookmark_border,
                        color: recipe['isBookmarked'] == true ? AppTheme.primaryDarkGreen : AppTheme.textSecondary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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

