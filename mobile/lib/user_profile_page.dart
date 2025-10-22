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
  final Map<String, dynamic>? preloadedUserData; // Optional pre-loaded user data

  const UserProfilePage({
    super.key,
    required this.userId,
    this.userName,
    this.preloadedUserData,
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

      Map<String, dynamic> user;
      
      // Use preloaded data if available, otherwise fetch from API
      if (widget.preloadedUserData != null) {
        print('🔍 User ${widget.userId} - Using preloaded data: ${widget.preloadedUserData}');
        user = widget.preloadedUserData!;
      } else {
        // Get user profile using proper API endpoint
        final response = await ApiService.getUserProfile(widget.userId);
        
        if (response['success'] != true) {
          throw Exception(response['message'] ?? 'Failed to load user profile');
        }
        
        user = response['user'];
        print('🔍 User ${widget.userId} - Fetched from API: $user');
      }

      if (mounted) {
        
        // Get follower and following counts from user stats (same as discover page)
        int followersCount = user['stats']?['followersCount'] ?? 
                           user['followersCount'] ?? 0;
        int followingCount = user['stats']?['followingCount'] ?? 
                            user['followingCount'] ?? 0;
        
        print('🔍 User ${widget.userId} - User data: $user');
        print('🔍 User ${widget.userId} - Stats: ${user['stats']}');
        print('🔍 User ${widget.userId} - Followers count from stats: $followersCount');
        print('🔍 User ${widget.userId} - Following count from stats: $followingCount');
        
        // Always try to fetch counts from API to ensure accuracy
        try {
          // Fetch followers with a high limit to get accurate count
          final followersResponse = await ApiService.getFollowers(widget.userId, limit: 1000);
          print('🔍 User ${widget.userId} - Full followers API response: $followersResponse');
          
          if (followersResponse['success'] == true) {
            // Try different possible response structures
            final apiFollowersCount = followersResponse['total'] ?? 
                                     followersResponse['count'] ?? 
                                     (followersResponse['followers'] as List?)?.length ?? 
                                     (followersResponse['data'] as List?)?.length ?? 0;
            
            print('🔍 User ${widget.userId} - API followers count: $apiFollowersCount');
            print('🔍 User ${widget.userId} - followers list length: ${(followersResponse['followers'] as List?)?.length ?? 0}');
            print('🔍 User ${widget.userId} - data list length: ${(followersResponse['data'] as List?)?.length ?? 0}');
            
            // Use API count if it's higher than stats count
            if (apiFollowersCount > followersCount) {
              followersCount = apiFollowersCount;
              print('🔍 User ${widget.userId} - Using API followers count: $followersCount');
            }
          }
          
          // Fetch following with a high limit to get accurate count
          final followingResponse = await ApiService.getFollowing(widget.userId, limit: 1000);
          print('🔍 User ${widget.userId} - Full following API response: $followingResponse');
          
          if (followingResponse['success'] == true) {
            // Try different possible response structures
            final apiFollowingCount = followingResponse['total'] ?? 
                                     followingResponse['count'] ?? 
                                     (followingResponse['following'] as List?)?.length ?? 
                                     (followingResponse['data'] as List?)?.length ?? 0;
            
            print('🔍 User ${widget.userId} - API following count: $apiFollowingCount');
            print('🔍 User ${widget.userId} - following list length: ${(followingResponse['following'] as List?)?.length ?? 0}');
            print('🔍 User ${widget.userId} - data list length: ${(followingResponse['data'] as List?)?.length ?? 0}');
            
            // Use API count if it's higher than stats count
            if (apiFollowingCount > followingCount) {
              followingCount = apiFollowingCount;
              print('🔍 User ${widget.userId} - Using API following count: $followingCount');
            }
          }
        } catch (e) {
          print('❌ Error fetching follower/following counts for user ${widget.userId}: $e');
        }
        
        setState(() {
          _userProfile = {
            'id': widget.userId,
            'name': user['name'] ?? widget.userName ?? 'User',
            'profileImage': user['profileImage'],
            'bio': user['bio'] ?? '',
            'location': user['location'] ?? '',
            'followersCount': followersCount,
            'followingCount': followingCount,
            'createdAt': user['createdAt'],
          };
          // Check if current user is following this profile
          _isFollowing = following.any((id) => id.toString() == widget.userId.toString());
          _isLoadingProfile = false;
        });
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

      final response = await ApiService.getUserRecipes(widget.userId, limit: 50);

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

  String? _getFullImageUrl(dynamic image) {
    if (image == null || image.toString().isEmpty) return null;
    
    final imageStr = image.toString();
    
    if (imageStr.startsWith('http://') || imageStr.startsWith('https://')) {
      return imageStr;
    }
    
    final baseUrl = ApiConfig.safeBaseUrl.replaceAll('/api', '');
    return '$baseUrl$imageStr';
  }

  String _formatJoinDate(dynamic createdAt) {
    if (createdAt == null) return 'Recently';
    
    try {
      DateTime date;
      if (createdAt is String) {
        date = DateTime.parse(createdAt);
      } else if (createdAt is DateTime) {
        date = createdAt;
      } else {
        return 'Recently';
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays < 1) {
        return 'Today';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '${weeks} week${weeks == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '${months} month${months == 1 ? '' : 's'} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '${years} year${years == 1 ? '' : 's'} ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
              : RefreshIndicator(
                  onRefresh: _loadUserData,
                  color: AppTheme.primaryDarkGreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        _buildActionButtons(),
                        _buildStatsSection(),
                    _buildTabBar(),
                        _buildRecipesSection(),
                        const SizedBox(height: 100), // Bottom padding
                  ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    final profileImageUrl = _getFullImageUrl(_userProfile?['profileImage']);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // Profile picture
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
              ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
              backgroundColor: AppTheme.primaryDarkGreen.withOpacity(0.1),
                    backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                    child: profileImageUrl == null
                        ? Text(
                            _userProfile?['name']?.toString().isNotEmpty == true
                                ? _userProfile!['name'][0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDarkGreen,
                            ),
                          )
                        : null,
                  ),
                ),
          const SizedBox(height: 16),
          
          // User name
                Text(
                  _userProfile?['name'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
              color: Colors.black87,
                  ),
            textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
          
          // Bio
          if (_userProfile?['bio']?.toString().isNotEmpty == true) ...[
            Text(
              _userProfile!['bio'],
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          
          // Location
          if (_userProfile?['location']?.toString().isNotEmpty == true)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _userProfile!['location'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Follow button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingFollow ? null : _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDarkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: _isLoadingFollow
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_add, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Message button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Implement message functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message feature coming soon!'),
                    backgroundColor: AppTheme.primaryDarkGreen,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryDarkGreen,
                side: const BorderSide(color: AppTheme.primaryDarkGreen, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Message',
                          style: TextStyle(
                            fontSize: 16,
                      fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            _userRecipes.length.toString(),
            'Recipes',
          ),
          _buildStatItem(
            (_userProfile?['followersCount'] ?? 0).toString(),
            'Followers',
          ),
          _buildStatItem(
            (_userProfile?['followingCount'] ?? 0).toString(),
            'Following',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    final isClickable = label == 'Followers' || label == 'Following';
    
    Widget statContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _showRecipes ? AppTheme.primaryDarkGreen : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                          'Recipes',
                          style: TextStyle(
                            fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _showRecipes ? AppTheme.primaryDarkGreen : Colors.grey[600],
                          ),
                  textAlign: TextAlign.center,
                        ),
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: !_showRecipes ? AppTheme.primaryDarkGreen : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: !_showRecipes ? AppTheme.primaryDarkGreen : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesSection() {
    if (_showRecipes) {
    if (_isLoadingRecipes) {
        return const Padding(
          padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryDarkGreen),
        ),
      );
    }

    if (_userRecipes.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 64,
                  color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'No recipes yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                    color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This user hasn\'t shared any recipes',
                style: TextStyle(
                  fontSize: 16,
                    color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
          itemCount: _userRecipes.length,
          itemBuilder: (context, index) {
            return _buildRecipeCard(_userRecipes[index]);
          },
        ),
      );
    } else {
      // About tab content
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (_userProfile?['bio']?.toString().isNotEmpty == true)
              Text(
                _userProfile!['bio'],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              )
            else
              Text(
                'No bio available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  _userProfile?['location']?.toString().isNotEmpty == true
                      ? _userProfile!['location']
                      : 'Location not specified',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Joined',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatJoinDate(_userProfile?['createdAt']),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final gradientColors = _getGradientColors(recipe['type'] ?? 'Food');
    final recipeIcon = _getRecipeIcon(recipe['type'] ?? 'Food');
    final imageUrl = _getFullImageUrl(recipe['image']);

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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recipe image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                height: 120,
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
                                size: 40,
                                color: Colors.white.withOpacity(0.8),
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
                            size: 40,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
              ),
            ),

            // Recipe info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Recipe type and name
                    Row(
                      children: [
                        Icon(
                          recipeIcon,
                          size: 16,
                          color: AppTheme.primaryDarkGreen,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                      recipe['name'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                              color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Recipe title
                        Text(
                      '${recipe['name'] ?? 'Untitled'} (Family Recipe)',
                          style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    
                    // Time and likes
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe['time'] ?? '45 min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe['likes']?.toString() ?? '324',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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

