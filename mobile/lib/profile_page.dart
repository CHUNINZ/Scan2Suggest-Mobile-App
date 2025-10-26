import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'recipe_details_page.dart';
import 'edit_profile_screen.dart';
import 'splash_screen.dart';
import 'followers_list_page.dart';
import 'app_theme.dart';
import 'services/api_service.dart';
import 'config/api_config.dart';
import 'utils/dialog_helper.dart';
import 'main_scaffold.dart';
import 'utils/navigation_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showRecipes = true;
  
  // Real user data from backend
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _userRecipes = [];
  List<Map<String, dynamic>> _likedRecipes = [];
  
  // Loading states
  bool _isLoadingProfile = true;
  bool _isLoadingRecipes = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Load user profile first (this will automatically load recipes)
    await _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoadingProfile = true;
        _hasError = false;
      });

      final response = await ApiService.getCurrentUser();
      
      if (response['success'] == true && mounted) {
        final user = response['user'];
        
        // Load additional user statistics
        final userId = user['_id'] ?? user['id'];
        int followersCount = 0;
        int followingCount = 0;
        
        try {
          // Get followers count
          final followersResponse = await ApiService.getFollowers(userId, limit: 1);
          if (followersResponse['success'] == true) {
            followersCount = followersResponse['total'] ?? (user['followers'] as List?)?.length ?? 0;
          }
          
          // Get following count
          final followingResponse = await ApiService.getFollowing(userId, limit: 1);
          if (followingResponse['success'] == true) {
            followingCount = followingResponse['total'] ?? (user['following'] as List?)?.length ?? 0;
          }
        } catch (e) {
          print('⚠️ Could not load detailed stats, using basic counts: $e');
          followersCount = (user['followers'] as List?)?.length ?? 0;
          followingCount = (user['following'] as List?)?.length ?? 0;
        }
        
        setState(() {
          _userProfile = {
            'id': userId,
            'name': user['name'] ?? 'User',
            'email': user['email'] ?? '',
            'bio': user['bio'] ?? 'Food lover 🍴',
            'location': user['location'] ?? '',
            'profileImageUrl': user['profileImage'] != null 
                ? (user['profileImage'].startsWith('http') 
                    ? user['profileImage'] 
                    : '${ApiConfig.safeBaseUrl.replaceAll('/api', '')}${user['profileImage']}')
                : null,
            'followersCount': followersCount,
            'followingCount': followingCount,
            'recipesCount': user['stats']?['recipesCreated'] ?? 0,
            'likesCount': user['stats']?['totalLikes'] ?? 0,
            'joinDate': _formatJoinDate(user['createdAt']),
            'isVerified': user['isVerified'] ?? false,
            'preferences': user['preferences'] ?? {},
            'createdAt': user['createdAt'],
            'lastActive': user['lastActive'],
          };
          _isLoadingProfile = false;
        });
        
        // Load recipes after profile is set
        _loadUserRecipes();
      } else {
        setState(() {
          _isLoadingProfile = false;
          _hasError = true;
          _errorMessage = response['message'] ?? 'Failed to load profile';
        });
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
      setState(() {
        _isLoadingProfile = false;
        _hasError = true;
        
        // Handle specific error cases
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        
        if (errorMessage.contains('No token provided') || 
            errorMessage.contains('access denied') ||
            errorMessage.contains('401')) {
          errorMessage = 'Please sign in to view your profile';
        } else if (errorMessage.contains('Failed to parse server response')) {
          errorMessage = 'Server response error. Please try again.';
        } else if (errorMessage.contains('Too many requests')) {
          errorMessage = 'Too many requests. Please wait a moment and try again.';
        } else if (errorMessage.contains('Network error')) {
          errorMessage = 'Network error. Please check your connection.';
        }
        
        _errorMessage = errorMessage;
      });
    }
  }

  Future<void> _loadUserRecipes() async {
    try {
      setState(() {
        _isLoadingRecipes = true;
      });

      final userId = _userProfile?['id'];
      if (userId == null || userId.toString().isEmpty) {
        print('❌ No valid user ID available for loading recipes');
        setState(() {
          _isLoadingRecipes = false;
          _userRecipes = [];
          _likedRecipes = [];
        });
        return;
      }

      print('🔄 Loading recipes for user: $userId');

      // Load user's own recipes with pagination
      final userRecipesResponse = await ApiService.getUserRecipes(userId, page: 1, limit: 50);
      print('📡 User recipes response: $userRecipesResponse');
      
      if (userRecipesResponse['success'] == true) {
        final recipes = (userRecipesResponse['recipes'] as List)
            .map((recipe) => recipe as Map<String, dynamic>)
            .toList();
        print('📝 Found ${recipes.length} user recipes');
        setState(() {
          _userRecipes = _transformRecipes(recipes);
        });
      } else {
        print('❌ Failed to load user recipes: ${userRecipesResponse['message']}');
        setState(() {
          _userRecipes = [];
        });
      }

      // Load liked recipes
      final likedRecipesResponse = await ApiService.getLikedRecipes();
      print('📡 Liked recipes response: $likedRecipesResponse');
      
      if (likedRecipesResponse['success'] == true) {
        final recipes = (likedRecipesResponse['recipes'] as List)
            .map((recipe) => recipe as Map<String, dynamic>)
            .toList();
        print('❤️ Found ${recipes.length} liked recipes');
        setState(() {
          _likedRecipes = _transformRecipes(recipes);
        });
      } else {
        print('❌ Failed to load liked recipes: ${likedRecipesResponse['message']}');
        setState(() {
          _likedRecipes = [];
        });
      }

      print('✅ Recipe loading completed. User recipes: ${_userRecipes.length}, Liked recipes: ${_likedRecipes.length}');
      setState(() {
        _isLoadingRecipes = false;
      });
    } catch (e) {
      print('❌ Error loading recipes: $e');
      setState(() {
        _isLoadingRecipes = false;
        _userRecipes = [];
        _likedRecipes = [];
      });
    }
  }

  List<Map<String, dynamic>> _transformRecipes(List<Map<String, dynamic>> recipes) {
    print('🔄 Transforming ${recipes.length} recipes');
    return recipes.map((recipe) {
      final prepTime = recipe['prepTime'] ?? 0;
      final cookTime = recipe['cookTime'] ?? 0;
      final totalTime = prepTime + cookTime;
      
      // Process ingredients
      final ingredientsList = recipe['ingredients'] as List? ?? [];
      final ingredientNames = ingredientsList.map((ing) {
        if (ing is String) return ing;
        if (ing is Map) return ing['name'] ?? 'Unknown ingredient';
        return ing.toString();
      }).toList();
      
      // Process instructions
      final instructionsList = recipe['instructions'] as List? ?? [];
      final instructionSteps = instructionsList.map((inst) {
        if (inst is String) return inst;
        if (inst is Map) return inst['instruction'] ?? inst['step'] ?? 'Step';
        return inst.toString();
      }).toList();
      
      final transformedRecipe = {
        'id': recipe['_id'] ?? recipe['id'],
        'name': recipe['title'] ?? recipe['name'] ?? 'Untitled Recipe',
        'type': _mapCategoryToType(recipe['category'] ?? 'Food'),
        'time': '${totalTime} mins',
        'likes': recipe['likesCount'] ?? (recipe['likes'] as List?)?.length ?? 0,
        'likesCount': recipe['likesCount'] ?? (recipe['likes'] as List?)?.length ?? 0,
        'creator': recipe['creator'] is Map 
            ? recipe['creator']['name'] ?? 'Unknown'
            : _userProfile?['name'] ?? 'Unknown',
        'description': recipe['description'] ?? '',
        'rating': (recipe['averageRating'] ?? 0).toDouble(),
        'ratingsCount': recipe['ratingsCount'] ?? recipe['ratings']?.length ?? 0,
        'commentsCount': recipe['commentsCount'] ?? recipe['comments']?.length ?? 0,
        'serves': recipe['servings'] ?? 4,
        'difficulty': _capitalizeDifficulty(recipe['difficulty'] ?? 'Medium'),
        'category': recipe['category'] ?? 'Main Course',
        'prepTime': prepTime,
        'cookTime': cookTime,
        'isLiked': recipe['isLiked'] ?? false,
        'isBookmarked': recipe['isBookmarked'] ?? false,
        'image': _getFullImageUrl(recipe['images']?.first),
        'dateCreated': _formatDate(recipe['createdAt']),
        'ingredients': ingredientNames,
        'steps': instructionSteps,
      };
      
      print('📝 Transformed recipe: ${transformedRecipe['name']} (ID: ${transformedRecipe['id']})');
      return transformedRecipe;
    }).toList();
  }

  String _mapCategoryToType(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('drink') || lowerCategory.contains('beverage')) {
      return 'Drink';
    } else if (lowerCategory.contains('snack') || lowerCategory.contains('appetizer')) {
      return 'Snack';
    }
    return 'Food';
  }

  String _capitalizeDifficulty(String difficulty) {
    if (difficulty.isEmpty) return 'Medium';
    return difficulty[0].toUpperCase() + difficulty.substring(1).toLowerCase();
  }

  String _getFullImageUrl(dynamic image) {
    if (image == null) return '';
    final imageStr = image.toString();
    if (imageStr.startsWith('http')) return imageStr;
    final baseUrl = ApiConfig.safeBaseUrl.replaceAll('/api', '');
    return '$baseUrl$imageStr';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Recently';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 month ago' : '$months months ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? '1 year ago' : '$years years ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  String _formatJoinDate(String? dateString) {
    if (dateString == null) return 'Recently';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays < 30) {
        return 'Joined this month';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? 'Joined 1 month ago' : 'Joined $months months ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? 'Joined 1 year ago' : 'Joined $years years ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Future<void> _refreshProfile() async {
    // Reset loading states
    setState(() {
      _isLoadingProfile = true;
      _isLoadingRecipes = true;
    });
    
    // Load user profile first (this will automatically load recipes)
    await _loadUserProfile();
  }

  void _editProfile() async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userProfile: _userProfile ?? {},
          onProfileUpdated: (updatedProfile) {
            setState(() {
              _userProfile = updatedProfile;
            });
          },
        ),
      ),
    );
    
    // Always refresh profile data when returning from edit
    await _loadUserProfile();
  }

  void _openRecipeDetails(Map<String, dynamic> recipe) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsPage(recipe: recipe),
      ),
    );
  }

  void _toggleBookmark(String recipeId, bool currentState) async {
    HapticFeedback.lightImpact();
    
    try {
      final response = await ApiService.bookmarkRecipe(recipeId);
      if (response['success'] == true) {
        setState(() {
          final recipeIndex = _userRecipes.indexWhere((recipe) => recipe['id'] == recipeId);
          if (recipeIndex != -1) {
            _userRecipes[recipeIndex]['isBookmarked'] = !currentState;
          }
          
          final likedIndex = _likedRecipes.indexWhere((recipe) => recipe['id'] == recipeId);
          if (likedIndex != -1) {
            _likedRecipes[likedIndex]['isBookmarked'] = !currentState;
          }
        });
        
        DialogHelper.showSuccess(
          context,
          title: !currentState ? "Recipe Saved! 🔖" : "Recipe Removed",
          message: !currentState ? "Added to your saved recipes!" : "Removed from your saved recipes",
        );
      }
    } catch (e) {
      print('❌ Error toggling bookmark: $e');
      DialogHelper.showError(
        context,
        title: "Error",
        message: "Failed to update bookmark. Please try again.",
      );
    }
  }

  Future<void> _logout() async {
    HapticFeedback.lightImpact();
    
    DialogHelper.showLogoutConfirmation(
      context,
      onLogout: () async {
        try {
          await ApiService.logout();
          
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const SplashScreen(isPostLogout: true),
              ),
              (route) => false,
            );
          }
        } catch (e) {
          print('❌ Logout error: $e');
          DialogHelper.showError(
            context,
            title: "Logout Failed",
            message: "Failed to logout. Please try again.",
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MainScaffold(
        title: 'Profile',
        showBottomNav: true,
        currentIndex: 4, // Settings tab index
        onNavTap: (index) {
          NavigationHelper.navigateToTab(context, index);
        },
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _errorMessage.contains('Please sign in') ? Icons.lock_outline : Icons.error_outline, 
                size: 64, 
                color: _errorMessage.contains('Please sign in') ? Colors.orange[300] : Colors.grey[400]
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage.contains('Please sign in') ? 'Authentication Required' : 'Error loading profile',
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _loadUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDarkGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
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
                      child: const Text('Sign In', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingProfile) {
      return MainScaffold(
        title: 'Profile',
        showBottomNav: true,
        currentIndex: 4, // Settings tab index
        onNavTap: (index) {
          NavigationHelper.navigateToTab(context, index);
        },
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
        ),
      );
    }

    return MainScaffold(
      title: 'Profile',
      showBottomNav: true,
      currentIndex: 4, // Settings tab index
      onNavTap: (index) {
        NavigationHelper.navigateToTab(context, index);
      },
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: AppTheme.primaryDarkGreen,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    _buildStatsSection(),
                    _buildTabBar(),
                    _buildRecipesSection(),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profile = _userProfile ?? {};
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile picture
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 58,
              backgroundColor: Colors.grey[300],
              backgroundImage: profile['profileImageUrl'] != null
                  ? NetworkImage(profile['profileImageUrl'])
                  : null,
              child: profile['profileImageUrl'] == null
                  ? Text(
                      (profile['name'] ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Username
          Text(
            profile['name'] ?? 'User',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 400 ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          
          const SizedBox(height: 8),
          
          // Bio
          Text(
            profile['bio'] ?? 'Food lover 🍴',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          
          const SizedBox(height: 8),
          
          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  profile['location'] ?? 'Location not set',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 400 ? 12 : 14,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Edit Profile Button
          ElevatedButton(
            onPressed: _editProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDarkGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Logout Button
          OutlinedButton(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final profile = _userProfile ?? {};
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildStatItem(
              'Recipes', 
              profile['recipesCount']?.toString() ?? '0',
              onTap: () {
                // Show user's recipes (already shown in the tab)
                setState(() => _showRecipes = true);
              },
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Followers', 
              profile['followersCount']?.toString() ?? '0',
              onTap: () => _showFollowersList(),
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Following', 
              profile['followingCount']?.toString() ?? '0',
              onTap: () => _showFollowingList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showFollowersList() {
    final userId = _userProfile?['id'];
    final userName = _userProfile?['name'] ?? 'User';
    if (userId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersListPage(
          userId: userId,
          userName: userName,
          isFollowers: true,
        ),
      ),
    );
  }

  void _showFollowingList() {
    final userId = _userProfile?['id'];
    final userName = _userProfile?['name'] ?? 'User';
    if (userId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersListPage(
          userId: userId,
          userName: userName,
          isFollowers: false,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showRecipes = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showRecipes ? AppTheme.primaryDarkGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'My Recipes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _showRecipes ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showRecipes = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showRecipes ? AppTheme.primaryDarkGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Liked Recipes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_showRecipes ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesSection() {
    print('🔄 Building recipes section. Loading: $_isLoadingRecipes, ShowRecipes: $_showRecipes');
    print('📊 User recipes count: ${_userRecipes.length}, Liked recipes count: ${_likedRecipes.length}');
    
    if (_isLoadingRecipes) {
      print('⏳ Showing loading grid');
      return _buildLoadingGrid();
    }

    final recipes = _showRecipes ? _userRecipes : _likedRecipes;
    print('📋 Selected recipes count: ${recipes.length}');
    
    if (recipes.isEmpty) {
      print('📭 Showing empty state');
      return _buildEmptyState();
    }

    print('📱 Building recipes grid with ${recipes.length} recipes');
    return _buildRecipesGrid(recipes);
  }

  Widget _buildLoadingGrid() {
    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: MediaQuery.of(context).size.width < 400 ? 0.65 : 0.7,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showRecipes ? Icons.restaurant_menu : Icons.favorite_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showRecipes ? 'No recipes yet' : 'No liked recipes',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showRecipes 
                  ? 'Start creating your first recipe!' 
                  : 'Like recipes to see them here',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipesGrid(List<Map<String, dynamic>> recipes) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: MediaQuery.of(context).size.width < 400 ? 0.65 : 0.7,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          return _buildRecipeCard(recipes[index]);
        },
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return GestureDetector(
      onTap: () => _openRecipeDetails(recipe),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: recipe['image'] != null && recipe['image'].toString().isNotEmpty
                      ? Image.network(
                          recipe['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackImage(recipe);
                          },
                        )
                      : _buildFallbackImage(recipe),
                ),
              ),
            ),
            
            // Recipe Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe name - responsive font size
                    Text(
                      recipe['name'] ?? 'Untitled',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 400 ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 6 : 8),
                    
                    // Time and bookmark row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            recipe['time'] ?? '30 mins',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _toggleBookmark(
                            recipe['id'],
                            recipe['isBookmarked'] ?? false,
                          ),
                          child: Icon(
                            recipe['isBookmarked'] == true
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 16,
                            color: recipe['isBookmarked'] == true
                                ? AppTheme.primaryDarkGreen
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Comments and rating - responsive layout with overflow protection
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Comments row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: MediaQuery.of(context).size.width < 400 ? 8 : 10,
                                color: AppTheme.textSecondary,
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width < 400 ? 2 : 4),
                              Expanded(
                                child: Text(
                                  '${recipe['commentsCount'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 8 : 9,
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: MediaQuery.of(context).size.width < 400 ? 2 : 4),
                          // Rating row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: MediaQuery.of(context).size.width < 400 ? 8 : 10,
                                color: (recipe['rating'] ?? 0) > 0 ? Colors.amber : AppTheme.textSecondary.withOpacity(0.5),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width < 400 ? 2 : 4),
                              Expanded(
                                child: Text(
                                  (recipe['rating'] ?? 0) > 0
                                      ? '${(recipe['rating'] ?? 0).toStringAsFixed(1)}'
                                      : 'No ratings',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 8 : 9,
                                    color: (recipe['rating'] ?? 0) > 0 
                                        ? AppTheme.textSecondary 
                                        : AppTheme.textSecondary.withOpacity(0.5),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage(Map<String, dynamic> recipe) {
    final recipeType = recipe['type'] ?? 'Food';
    List<Color> gradientColors;
    IconData recipeIcon;

    switch (recipeType.toLowerCase()) {
      case 'drink':
        gradientColors = [Colors.blue.shade300, Colors.blue.shade600];
        recipeIcon = Icons.local_drink;
        break;
      case 'snack':
        gradientColors = [AppTheme.secondaryLightGreen, AppTheme.primaryDarkGreen];
        recipeIcon = Icons.local_cafe;
        break;
      default:
        gradientColors = [AppTheme.secondaryLightGreen, AppTheme.primaryDarkGreen];
        recipeIcon = Icons.restaurant;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          recipeIcon,
          size: 32,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}