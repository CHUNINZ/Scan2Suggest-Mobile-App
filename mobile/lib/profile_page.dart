import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'recipe_details_page.dart';
import 'edit_profile_screen.dart';
import 'splash_screen.dart';
import 'followers_list_page.dart';
import 'app_theme.dart';
import 'services/api_service.dart';
import 'config/api_config.dart';
import '../widgets/loading_skeletons.dart';
import 'utils/dialog_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  bool _showRecipes = true;
  late AnimationController _fadeController;
  late AnimationController _contentFadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _slideAnimation;
  
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
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _contentFadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentFadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Load real data from backend
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Load profile first to get userId
    await _loadUserProfile();
    
    // Then load recipes using the userId
    await _loadUserRecipes();
    
    // Start animations after data is loaded
    _fadeController.forward();
    _contentFadeController.forward();
    _slideController.forward();
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
        setState(() {
          _userProfile = {
            'id': user['_id'] ?? user['id'],
            'name': user['name'] ?? 'User',
            'email': user['email'] ?? '',
            'bio': user['bio'] ?? 'Food lover 🍴',
            'location': user['location'] ?? '',
            'profileImageUrl': user['profileImage'] != null 
                ? (user['profileImage'].startsWith('http') 
                    ? user['profileImage'] 
                    : '${ApiConfig.safeBaseUrl.replaceAll('/api', '')}${user['profileImage']}')
                : null,
            'followersCount': (user['followers'] as List?)?.length ?? 0,
            'followingCount': (user['following'] as List?)?.length ?? 0,
            'recipesCount': user['stats']?['recipesCreated'] ?? 0,
            'likesCount': user['stats']?['totalLikes'] ?? 0,
            'joinDate': _formatJoinDate(user['createdAt']),
            'isVerified': user['isVerified'] ?? false,
          };
          _isLoadingProfile = false;
        });
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
        _errorMessage = 'Network error. Please check your connection.';
      });
    }
  }

  Future<void> _loadUserRecipes() async {
    try {
      setState(() {
        _isLoadingRecipes = true;
      });

      // Get current user ID
      final userId = _userProfile?['id'];
      
      if (userId == null) {
        setState(() {
          _isLoadingRecipes = false;
        });
        return;
      }

      // Get both user's own recipes and liked recipes in parallel
      final results = await Future.wait([
        ApiService.getRecipes(
          page: 1,
          limit: 50,
          creatorId: userId,
          sort: 'createdAt',
          order: 'desc',
        ),
        ApiService.getLikedRecipes(),
      ]);

      if (results[0]['success'] == true && results[1]['success'] == true && mounted) {
        final userRecipes = (results[0]['recipes'] as List).cast<Map<String, dynamic>>();
        final likedRecipes = (results[1]['recipes'] as List).cast<Map<String, dynamic>>();

        setState(() {
          _userRecipes = _transformRecipes(userRecipes);
          _likedRecipes = _transformRecipes(likedRecipes);
          _isLoadingRecipes = false;
        });
      } else {
        setState(() {
          _isLoadingRecipes = false;
        });
      }
    } catch (e) {
      print('❌ Error loading recipes: $e');
      setState(() {
        _isLoadingRecipes = false;
      });
    }
  }

  List<Map<String, dynamic>> _transformRecipes(List<Map<String, dynamic>> recipes) {
    return recipes.map((recipe) {
      final prepTime = recipe['prepTime'] ?? 0;
      final cookTime = recipe['cookTime'] ?? 0;
      final totalTime = prepTime + cookTime;
      
      // Extract ingredient names for display
      final ingredientsList = recipe['ingredients'] as List? ?? [];
      final ingredientNames = ingredientsList.map((ing) {
        if (ing is String) return ing;
        if (ing is Map) return ing['name'] ?? 'Unknown ingredient';
        return ing.toString();
      }).toList();
      
      // Extract instruction steps for display
      final instructionsList = recipe['instructions'] as List? ?? [];
      final instructionSteps = instructionsList.map((inst) {
        if (inst is String) return inst;
        if (inst is Map) return inst['instruction'] ?? inst['step'] ?? 'Step';
        return inst.toString();
      }).toList();
      
      return {
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
        'serves': recipe['servings'] ?? 4,
        'difficulty': _capitalizeDifficulty(recipe['difficulty'] ?? 'Medium'),
        'category': recipe['category'] ?? 'Main Course',
        'prepTime': prepTime,
        'cookTime': cookTime,
        'ingredients': ingredientNames, // Pass actual list, not count
        'steps': instructionSteps, // Pass actual list, not count
        'isBookmarked': recipe['isBookmarked'] ?? false,
        'image': _getFullImageUrl(recipe['images']?.first),
        'dateCreated': _formatDate(recipe['createdAt']),
      };
    }).toList();
  }

  String _mapCategoryToType(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('beverage') || 
        lowerCategory.contains('drink') ||
        lowerCategory.contains('juice')) {
      return 'Drink';
    } else if (lowerCategory.contains('snack') || 
               lowerCategory.contains('appetizer')) {
      return 'Snack';
    }
    return 'Food';
  }

  String _capitalizeDifficulty(String difficulty) {
    if (difficulty.isEmpty) return 'Medium';
    return difficulty[0].toUpperCase() + difficulty.substring(1).toLowerCase();
  }

  String? _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http')) return imagePath;
    return 'http://192.168.194.201:3000$imagePath';
  }

  String _formatJoinDate(String? dateStr) {
    if (dateStr == null) return 'Recently joined';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['January', 'February', 'March', 'April', 'May', 'June',
                     'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Recently joined';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Recently';
    try {
      final date = DateTime.parse(dateStr);
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

  Future<void> _refreshProfile() async {
    await _loadUserData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _contentFadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _editProfile() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push(
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
    
    // Reload profile if edited
    if (result == true) {
      _loadUserProfile();
    }
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
          // Update bookmark state in user recipes
          final recipeIndex = _userRecipes.indexWhere((recipe) => recipe['id'] == recipeId);
          if (recipeIndex != -1) {
            _userRecipes[recipeIndex]['isBookmarked'] = !currentState;
          }
          
          // Update bookmark state in liked recipes
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
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFF666666),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDarkGreen,
                  foregroundColor: AppTheme.surfaceWhite,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const UserProfileSkeleton(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: AppTheme.primaryDarkGreen, // App theme color
        child: CustomScrollView(
          slivers: [
            _buildProfileHeader(),
            _buildStatsSection(),
            _buildTabBar(),
            _buildRecipesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profile = _userProfile ?? {};
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    
    // Fixed sizing to match image exactly
    
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header actions - Clean white background
                Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Logout button positioned in top-right corner
                      TextButton.icon(
                        onPressed: _logout,
                        icon: Icon(
                          Icons.logout, 
                          color: Colors.red,
                          size: isLargeScreen ? 20 : 18,
                        ),
                        label: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: isLargeScreen ? 16 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isLargeScreen ? 24 : 20),
                
                // Profile picture - Larger and more prominent like in image
                Container(
                  width: 140, // Fixed larger size like in image
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 68,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: profile['profileImageUrl'] != null 
                        ? NetworkImage(profile['profileImageUrl'])
                        : null,
                    child: profile['profileImageUrl'] == null
                        ? Text(
                            (profile['name'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          )
                        : null,
                  ),
                ),
                
                SizedBox(height: 24), // More spacing like in image
                
                // Name - Bold dark grey, larger
                Text(
                  profile['name'] ?? 'User',
                  style: TextStyle(
                    fontSize: 28, // Larger like in image
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 12),
                
                // Bio - Exactly 2 lines like in image
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    profile['bio']?.toString().isNotEmpty == true 
                        ? profile['bio']
                        : 'Home cook passionate about Filipino cuisine.\nLove sharing family recipes!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                SizedBox(height: 12), // Less spacing like in image
                
                // Location - Light grey with icon, closer to bio
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on, 
                      size: 16, 
                      color: Color(0xFF666666),
                    ),
                    SizedBox(width: 6),
                    Text(
                      profile['location']?.toString().isNotEmpty == true 
                          ? profile['location']
                          : 'Manila, Philippines',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 32), // More spacing before button
                
                // Edit Profile button - Using app theme colors
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _editProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDarkGreen,
                        foregroundColor: AppTheme.surfaceWhite,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: isLargeScreen ? 32 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final profile = _userProfile ?? {};
    
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _contentFadeAnimation,
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCleanStatItem(
                profile['recipesCount']?.toString() ?? '12',
                'Recipes',
              ),
              _buildCleanStatItem(
                profile['followersCount']?.toString() ?? '245',
                'Followers',
              ),
              _buildCleanStatItem(
                profile['followingCount']?.toString() ?? '156',
                'Following',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanStatItem(String value, String label) {
    final isClickable = label == 'Followers' || label == 'Following';
    final profile = _userProfile ?? {};
    final userId = profile['id'];
    final userName = profile['name'];
    
    Widget statContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24, // Fixed size like in image
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
        ),
        SizedBox(height: 6), // Exact spacing like in image
        Text(
          label,
          style: TextStyle(
            fontSize: 13, // Fixed size like in image
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
    
    if (isClickable && userId != null && userName != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FollowersListPage(
                userId: userId.toString(),
                userName: userName,
                isFollowers: label == 'Followers',
              ),
            ),
          );
        },
        child: statContent,
      );
    }
    
    return statContent;
  }


  Widget _buildTabBar() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.symmetric(vertical: 20), // More spacing like in image
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showRecipes = true;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Text(
                    'My Recipes',
                    style: TextStyle(
                      fontSize: 16, // Fixed size like in image
                      fontWeight: _showRecipes ? FontWeight.w600 : FontWeight.w400,
                      color: _showRecipes ? AppTheme.primaryDarkGreen : Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showRecipes = false;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Text(
                    'Liked Recipes',
                    style: TextStyle(
                      fontSize: 16, // Fixed size like in image
                      fontWeight: !_showRecipes ? FontWeight.w600 : FontWeight.w400,
                      color: !_showRecipes ? AppTheme.primaryDarkGreen : Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipesList() {
    final recipes = _showRecipes ? _userRecipes : _likedRecipes;
    
    if (_isLoadingRecipes) {
      return SliverFillRemaining(
        child: GridSkeleton(
          itemCount: 6,
          itemBuilder: (context, index) => const RecipeCardSkeleton(),
        ),
      );
    }
    
    if (recipes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _showRecipes ? Icons.restaurant_menu : Icons.favorite_border,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.5),
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
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    
    // Responsive grid configuration
    int crossAxisCount;
    double childAspectRatio;
    double mainAxisSpacing;
    double crossAxisSpacing;
    double horizontalPadding;
    
    if (isLargeScreen) {
      crossAxisCount = 4; // 4 columns on large screens
      childAspectRatio = 0.8;
      mainAxisSpacing = 20;
      crossAxisSpacing = 20;
      horizontalPadding = 24;
    } else if (isTablet) {
      crossAxisCount = 3; // 3 columns on tablets
      childAspectRatio = 0.75;
      mainAxisSpacing = 18;
      crossAxisSpacing = 18;
      horizontalPadding = 20;
    } else {
      crossAxisCount = 2; // 2 columns on phones
      childAspectRatio = 0.75;
      mainAxisSpacing = 16;
      crossAxisSpacing = 16;
      horizontalPadding = 16;
    }
    
    return SliverPadding(
      padding: EdgeInsets.all(horizontalPadding),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final recipe = recipes[index];
            return _buildRecipeCard(recipe);
          },
          childCount: recipes.length,
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final recipeType = recipe['type'] ?? 'Food';
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    
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

    // Responsive sizing
    final imageHeight = isLargeScreen ? 140.0 : (isTablet ? 130.0 : 120.0);
    final borderRadius = isLargeScreen ? 20.0 : 16.0;
    final cardPadding = isLargeScreen ? 12.0 : (isTablet ? 11.0 : 10.0);
    final titleFontSize = isLargeScreen ? 15.0 : (isTablet ? 14.0 : 13.0);
    final timeFontSize = isLargeScreen ? 12.0 : (isTablet ? 11.0 : 10.0);
    final iconSize = isLargeScreen ? 16.0 : (isTablet ? 15.0 : 13.0);
    final bookmarkIconSize = isLargeScreen ? 22.0 : (isTablet ? 20.0 : 18.0);
    final fallbackIconSize = isLargeScreen ? 48.0 : (isTablet ? 44.0 : 40.0);

    return GestureDetector(
      onTap: () => _openRecipeDetails(recipe),
      child: Container(
        decoration: AppTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
              child: Container(
                height: imageHeight,
                width: double.infinity,
                child: recipe['image'] != null && recipe['image'].toString().isNotEmpty
                    ? Image.network(
                        recipe['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
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
                                size: fallbackIconSize,
                                color: AppTheme.surfaceWhite.withOpacity(0.8),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
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
                            size: fallbackIconSize,
                            color: AppTheme.surfaceWhite.withOpacity(0.8),
                          ),
                        ),
                      ),
              ),
            ),
            
            // Recipe info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recipe['name'] ?? 'Untitled',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: isLargeScreen ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isLargeScreen ? 4 : 3),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time, 
                          size: isLargeScreen ? 13 : (isTablet ? 12 : 11), 
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(width: isLargeScreen ? 4 : 3),
                        Text(
                          recipe['time'] ?? '30 mins',
                          style: TextStyle(
                            fontSize: timeFontSize,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite, 
                          size: iconSize, 
                          color: Colors.red,
                        ),
                        SizedBox(width: isLargeScreen ? 4 : 3),
                        Text(
                          recipe['likes']?.toString() ?? '0',
                          style: TextStyle(
                            fontSize: timeFontSize,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _toggleBookmark(
                            recipe['id'],
                            recipe['isBookmarked'] ?? false,
                          ),
                          child: Icon(
                            recipe['isBookmarked'] == true
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: bookmarkIconSize,
                            color: recipe['isBookmarked'] == true
                                ? AppTheme.primaryDarkGreen
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
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
}
