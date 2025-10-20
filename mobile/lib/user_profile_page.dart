import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'recipe_details_page.dart';
import 'followers_list_page.dart';
import 'app_theme.dart';
import 'services/api_service.dart';
import 'config/api_config.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String? userName;

  const UserProfilePage({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _showRecipes = true;
  
  // User data from backend
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _userRecipes = [];
  
  // Loading states
  bool _isLoadingProfile = true;
  bool _isLoadingRecipes = true;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await Future.wait([
      _loadUserProfile(),
      _loadUserRecipes(),
    ]);
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoadingProfile = true;
        _hasError = false;
      });

      // Get current user to check following status
      final currentUserResponse = await ApiService.getCurrentUser();
      List<dynamic> following = [];
      
      if (currentUserResponse['success'] == true) {
        following = currentUserResponse['user']['following'] as List? ?? [];
      }

      // Get user profile (need to add this API endpoint)
      final response = await ApiService.getRecipes(
        creatorId: widget.userId,
        limit: 1,
      );

      if (response['success'] == true && mounted) {
        final recipes = response['recipes'] as List? ?? [];
        if (recipes.isNotEmpty) {
          final recipe = recipes[0];
          final creator = recipe['creator'];
          
          setState(() {
            _userProfile = {
              'id': widget.userId,
              'name': creator is Map ? creator['name'] : widget.userName ?? 'User',
              'profileImage': creator is Map ? creator['profileImage'] : null,
              'bio': '',
              'location': '',
              'followersCount': creator is Map ? creator['followersCount'] : 0,
              'followingCount': creator is Map ? creator['followingCount'] : 0,
            };
            // Check if current user is following this profile
            _isFollowing = following.any((id) => id.toString() == widget.userId.toString());
            _isLoadingProfile = false;
          });
        } else {
          // No recipes, create basic profile
          setState(() {
            _userProfile = {
              'id': widget.userId,
              'name': widget.userName ?? 'User',
              'profileImage': null,
              'bio': '',
              'location': '',
              'followersCount': 0,
              'followingCount': 0,
            };
            // Check if current user is following this profile
            _isFollowing = following.any((id) => id.toString() == widget.userId.toString());
            _isLoadingProfile = false;
          });
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to load user profile');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _loadUserRecipes() async {
    try {
      setState(() {
        _isLoadingRecipes = true;
      });

      final response = await ApiService.getRecipes(
        creatorId: widget.userId,
        limit: 50,
      );

      if (response['success'] == true && mounted) {
        final recipes = response['recipes'] as List? ?? [];
        
        final transformedRecipes = recipes.map((recipe) {
          final creator = recipe['creator'];
          final creatorName = creator is Map ? creator['name'] : creator?.toString() ?? 'Unknown';
          
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
          
          return {
            'id': recipe['_id'] ?? recipe['id'],
            'name': recipe['title'] ?? 'Untitled',
            'creator': creatorName,
            'type': recipe['category'] ?? 'Food',
            'time': '${(recipe['prepTime'] ?? 0) + (recipe['cookTime'] ?? 0)} mins',
            'image': firstImage,
            'description': recipe['description'] ?? '',
            'ingredients': ingredientNames,
            'steps': instructionSteps,
            'rating': (recipe['averageRating'] ?? 0).toDouble(),
            'likes': recipe['likesCount'] ?? 0,
            'isBookmarked': recipe['isBookmarked'] ?? false,
          };
        }).toList();

        setState(() {
          _userRecipes = transformedRecipes;
          _isLoadingRecipes = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load recipes');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRecipes = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoadingFollow) return;

    setState(() {
      _isLoadingFollow = true;
    });

    HapticFeedback.lightImpact();

    try {
      final response = await ApiService.followUser(widget.userId);

      if (response['success'] == true && mounted) {
        setState(() {
          _isFollowing = response['isFollowing'] ?? !_isFollowing;
          _isLoadingFollow = false;
          
          // Update follower count
          if (_userProfile != null) {
            _userProfile!['followersCount'] = response['followersCount'] ?? _userProfile!['followersCount'];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? '✓ Following ${_userProfile?['name'] ?? 'user'}' : 'Unfollowed'),
            backgroundColor: _isFollowing ? Colors.green : Colors.grey[700],
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to follow/unfollow user');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFollow = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _toggleBookmark(String recipeId, bool isCurrentlyBookmarked) async {
    HapticFeedback.lightImpact();

    try {
      final response = await ApiService.bookmarkRecipe(recipeId);

      if (response['success'] == true && mounted) {
        setState(() {
          // Update the recipe's bookmark status
          final recipeIndex = _userRecipes.indexWhere((r) => r['id'] == recipeId);
          if (recipeIndex != -1) {
            _userRecipes[recipeIndex]['isBookmarked'] = response['isBookmarked'] ?? !isCurrentlyBookmarked;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['isBookmarked'] == true ? '🔖 Recipe saved!' : 'Recipe removed from saved'),
            backgroundColor: response['isBookmarked'] == true ? Colors.green : Colors.grey[700],
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to bookmark recipe');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
      backgroundColor: AppTheme.backgroundOffWhite,
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading profile',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryDarkGreen,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    _buildHeader(),
                    _buildTabBar(),
                    _buildRecipesList(),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    final profileImageUrl = _getFullImageUrl(_userProfile?['profileImage']);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    
    // Responsive sizing
    final expandedHeight = isLargeScreen ? 280.0 : (isTablet ? 250.0 : 220.0);
    final profileImageRadius = isLargeScreen ? 60.0 : (isTablet ? 55.0 : 50.0);
    final profileImageBorderWidth = isLargeScreen ? 5.0 : 4.0;
    final nameFontSize = isLargeScreen ? 28.0 : (isTablet ? 26.0 : 24.0);
    final buttonHeight = isLargeScreen ? 70.0 : 60.0;
    final buttonPadding = isLargeScreen ? 18.0 : (isTablet ? 16.0 : 14.0);
    final buttonFontSize = isLargeScreen ? 18.0 : (isTablet ? 17.0 : 16.0);
    final iconSize = isLargeScreen ? 24.0 : (isTablet ? 22.0 : 20.0);
    
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: AppTheme.surfaceWhite,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back, 
          color: AppTheme.textPrimary,
          size: isLargeScreen ? 28 : 24,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: AppTheme.primaryGradientDecoration(),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: isLargeScreen ? 50 : (isTablet ? 45 : 40)),
                // Profile picture
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.surfaceWhite, 
                      width: profileImageBorderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.textPrimary.withOpacity(0.2),
                        blurRadius: isLargeScreen ? 16 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: profileImageRadius,
                    backgroundColor: AppTheme.surfaceWhite,
                    backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                    child: profileImageUrl == null
                        ? Text(
                            _userProfile?['name']?.toString().isNotEmpty == true
                                ? _userProfile!['name'][0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: isLargeScreen ? 42 : (isTablet ? 39 : 36),
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDarkGreen,
                            ),
                          )
                        : null,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 16 : 12),
                // Name
                Text(
                  _userProfile?['name'] ?? 'User',
                  style: TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.surfaceWhite,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isLargeScreen ? 12 : 8),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatItem(
                      _userRecipes.length.toString(),
                      'Recipes',
                    ),
                    Container(
                      height: isLargeScreen ? 30 : (isTablet ? 27 : 24),
                      width: 1,
                      color: AppTheme.surfaceWhite.withOpacity(0.3),
                      margin: EdgeInsets.symmetric(horizontal: isLargeScreen ? 24 : (isTablet ? 22 : 20)),
                    ),
                    _buildStatItem(
                      (_userProfile?['followersCount'] ?? 0).toString(),
                      'Followers',
                    ),
                    Container(
                      height: isLargeScreen ? 30 : (isTablet ? 27 : 24),
                      width: 1,
                      color: AppTheme.surfaceWhite.withOpacity(0.3),
                      margin: EdgeInsets.symmetric(horizontal: isLargeScreen ? 24 : (isTablet ? 22 : 20)),
                    ),
                    _buildStatItem(
                      (_userProfile?['followingCount'] ?? 0).toString(),
                      'Following',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(buttonHeight),
        child: Container(
          color: AppTheme.surfaceWhite,
          padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingFollow ? null : _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey[300] : AppTheme.primaryDarkGreen,
                padding: EdgeInsets.symmetric(vertical: buttonPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 12),
                ),
              ),
              child: _isLoadingFollow
                  ? SizedBox(
                      height: isLargeScreen ? 24 : 20,
                      width: isLargeScreen ? 24 : 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isFollowing ? Icons.check : Icons.person_add,
                          color: _isFollowing ? AppTheme.textPrimary : AppTheme.surfaceWhite,
                          size: iconSize,
                        ),
                        SizedBox(width: isLargeScreen ? 12 : (isTablet ? 10 : 8)),
                        Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: _isFollowing ? AppTheme.textPrimary : AppTheme.surfaceWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: buttonFontSize,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    final isClickable = label == 'Followers' || label == 'Following';
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    
    // Responsive sizing
    final valueFontSize = isLargeScreen ? 26.0 : (isTablet ? 24.0 : 22.0);
    final labelFontSize = isLargeScreen ? 15.0 : (isTablet ? 14.0 : 13.0);
    final spacing = isLargeScreen ? 4.0 : 2.0;
    
    Widget statContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.surfaceWhite,
          ),
        ),
        SizedBox(height: spacing),
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
            color: AppTheme.surfaceWhite.withOpacity(0.9),
          ),
        ),
      ],
    );
    
    if (isClickable && _userProfile != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FollowersListPage(
                userId: widget.userId,
                userName: _userProfile!['name'] ?? widget.userName ?? 'User',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(isLargeScreen ? 24 : (isTablet ? 20 : 16)),
        decoration: AppTheme.cardDecoration(),
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 8 : 6),
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
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 20 : (isTablet ? 18 : 16)),
                    decoration: BoxDecoration(
                      color: _showRecipes ? AppTheme.primaryDarkGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: isLargeScreen ? 24 : (isTablet ? 22 : 20),
                          color: _showRecipes ? AppTheme.surfaceWhite : AppTheme.textSecondary,
                        ),
                        SizedBox(width: isLargeScreen ? 12 : (isTablet ? 10 : 8)),
                        Text(
                          'Recipes',
                          style: TextStyle(
                            fontSize: isLargeScreen ? 18 : (isTablet ? 17 : 16),
                            fontWeight: _showRecipes ? FontWeight.bold : FontWeight.w500,
                            color: _showRecipes ? AppTheme.surfaceWhite : AppTheme.textSecondary,
                          ),
                        ),
                      ],
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

  Widget _buildRecipesList() {
    if (_isLoadingRecipes) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
        ),
      );
    }

    if (_userRecipes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No recipes yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This user hasn\'t shared any recipes',
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
      mainAxisSpacing = 12;
      crossAxisSpacing = 12;
      horizontalPadding = 16;
    }
    
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildRecipeCard(_userRecipes[index]);
          },
          childCount: _userRecipes.length,
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final gradientColors = _getGradientColors(recipe['type'] ?? 'Food');
    final recipeIcon = _getRecipeIcon(recipe['type'] ?? 'Food');
    final imageUrl = _getFullImageUrl(recipe['image']);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

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
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsPage(recipe: recipe),
          ),
        );
      },
      child: Container(
        decoration: AppTheme.cardDecoration(elevation: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recipe image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
              child: Container(
                height: imageHeight,
                width: double.infinity,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
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
                            recipe['isBookmarked'] == true ? Icons.bookmark : Icons.bookmark_border,
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

  List<Color> _getGradientColors(String type) {
    switch (type.toLowerCase()) {
      case 'dessert':
        return [const Color(0xFFFF6B9D), const Color(0xFFC44569)];
      case 'breakfast':
        return [const Color(0xFFFFA726), const Color(0xFFFB8C00)];
      case 'lunch':
        return [const Color(0xFF66BB6A), const Color(0xFF43A047)];
      case 'dinner':
        return [const Color(0xFF42A5F5), const Color(0xFF1E88E5)];
      default:
        return [AppTheme.secondaryLightGreen, AppTheme.primaryDarkGreen];
    }
  }

  IconData _getRecipeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'dessert':
        return Icons.cake;
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }
}

