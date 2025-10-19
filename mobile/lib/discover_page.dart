import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'user_profile_page.dart';
import 'app_theme.dart';
import 'services/api_service.dart';
import 'config/api_config.dart';
import '../widgets/loading_skeletons.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _followingUsers = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMorePages) {
        _loadMoreUsers();
      }
    }
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _currentPage = 1;
      });

      final response = await ApiService.discoverUsers(page: 1, limit: 20);

      if (response['success'] == true && mounted) {
        final users = response['users'] as List? ?? [];
        final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
        
        setState(() {
          _users = users.map((user) => _transformUser(user)).toList();
          _hasMorePages = pagination['page'] < pagination['pages'];
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load users');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoading || !_hasMorePages) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final nextPage = _currentPage + 1;
      final response = await ApiService.discoverUsers(page: nextPage, limit: 20);

      if (response['success'] == true && mounted) {
        final users = response['users'] as List? ?? [];
        final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
        
        setState(() {
          _users.addAll(users.map((user) => _transformUser(user)).toList());
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

  Map<String, dynamic> _transformUser(dynamic user) {
    return {
      'id': user['_id'] ?? user['id'],
      'name': user['name'] ?? 'Unknown User',
      'profileImage': user['profileImage'],
      'bio': user['bio'] ?? '',
      'stats': user['stats'],
      'recipesCount': user['stats']?['recipesCreated'] ?? 0,
      'followersCount': user['stats']?['followersCount'] ?? 0,
      'followingCount': user['stats']?['followingCount'] ?? 0,
      'totalLikes': user['stats']?['totalLikes'] ?? 0,
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

  Future<void> _refreshUsers() async {
    HapticFeedback.lightImpact();
    await _loadUsers();
  }

  void _openUserProfile(Map<String, dynamic> user) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: user['id'].toString(),
          userName: user['name'],
        ),
      ),
    );
  }

  Future<void> _toggleFollow(String userId) async {
    final isCurrentlyFollowing = _followingUsers.contains(userId);
    
    // Optimistic update
    setState(() {
      if (isCurrentlyFollowing) {
        _followingUsers.remove(userId);
      } else {
        _followingUsers.add(userId);
      }
    });
    
    HapticFeedback.lightImpact();
    
    try {
      final response = await ApiService.followUser(userId);
      
      if (response['success'] == true && mounted) {
        final isFollowing = response['isFollowing'] ?? false;
        
        setState(() {
          if (isFollowing) {
            _followingUsers.add(userId);
          } else {
            _followingUsers.remove(userId);
          }
        });
        
        // Update follower count in user list
        final userIndex = _users.indexWhere((u) => u['id'] == userId);
        if (userIndex != -1 && response['followersCount'] != null) {
          setState(() {
            _users[userIndex]['followersCount'] = response['followersCount'];
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFollowing ? '✓ Following user' : 'Unfollowed'),
            backgroundColor: isFollowing ? Colors.green : Colors.grey[700],
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Revert on error
        setState(() {
          if (isCurrentlyFollowing) {
            _followingUsers.add(userId);
          } else {
            _followingUsers.remove(userId);
          }
        });
        throw Exception(response['message'] ?? 'Failed to follow/unfollow user');
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          if (isCurrentlyFollowing) {
            _followingUsers.add(userId);
          } else {
            _followingUsers.remove(userId);
          }
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: _buildModernBody(),
    );
  }

  Widget _buildModernBody() {
    if (_isLoading && _users.isEmpty) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_users.isEmpty) {
      return _buildEmptyState();
    }

    return _buildModernDiscoverView();
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const UserCardSkeleton(),
                childCount: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildModernButton(
                text: 'Try Again',
              onPressed: _loadUsers,
                isPrimary: true,
              ),
            ],
          ),
        ),
        ),
      );
    }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  size: 48,
                  color: AppTheme.surfaceWhite,
                ),
              ),
              const SizedBox(height: 24),
            const Text(
                'All Caught Up!',
              style: TextStyle(
                  fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
                textAlign: TextAlign.center,
            ),
              const SizedBox(height: 12),
            Text(
                'You\'re already following everyone in your network. Check back later for new users!',
              style: TextStyle(
                fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
              const SizedBox(height: 32),
              _buildModernButton(
                text: 'Refresh',
                onPressed: _loadUsers,
                isPrimary: true,
              ),
            ],
          ),
        ),
        ),
      );
    }

  Widget _buildModernDiscoverView() {
    return RefreshIndicator(
      onRefresh: _refreshUsers,
      color: AppTheme.primaryDarkGreen,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _users.length) {
                    return _buildLoadingIndicator();
                  }
                  return _buildModernUserCard(_users[index]);
                },
                childCount: _users.length + (_hasMorePages ? 1 : 0),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryDarkGreen,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildModernUserCard(Map<String, dynamic> user) {
    final profileImageUrl = _getFullImageUrl(user['profileImage']);
    final userId = user['id'].toString();
    final isFollowing = _followingUsers.contains(userId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openUserProfile(user),
      child: Padding(
            padding: const EdgeInsets.all(20),
        child: Column(
          children: [
                // Header with profile and follow button
            Row(
              children: [
                    // Profile picture with modern styling
                GestureDetector(
                  onTap: () => _openUserProfile(user),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryDarkGreen.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                          radius: 36,
                          backgroundColor: AppTheme.surfaceWhite,
                      backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                      child: profileImageUrl == null
                              ? Container(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                              user['name']?.toString().isNotEmpty == true
                                  ? user['name'][0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                        fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.surfaceWhite,
                                      ),
                                    ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // User info
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? 'Unknown User',
                          style: const TextStyle(
                              fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                          const SizedBox(height: 4),
                          if (user['bio']?.toString().isNotEmpty == true) ...[
                          Text(
                            user['bio'],
                            style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          ] else ...[
                            Text(
                              'Food enthusiast',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Modern follow button
                    _buildModernFollowButton(isFollowing, userId),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Modern stats section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.backgroundOffWhite,
                        AppTheme.surfaceWhite,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryDarkGreen.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildModernStatItem(
                          icon: Icons.restaurant_menu_rounded,
                          value: user['recipesCount'].toString(),
                          label: 'Recipes',
                          color: AppTheme.primaryDarkGreen,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppTheme.textDisabled.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildModernStatItem(
                          icon: Icons.people_rounded,
                          value: user['followersCount'].toString(),
                          label: 'Followers',
                          color: AppTheme.secondaryLightGreen,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppTheme.textDisabled.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildModernStatItem(
                          icon: Icons.favorite_rounded,
                          value: user['totalLikes'].toString(),
                          label: 'Likes',
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFollowButton(bool isFollowing, String userId) {
    return Container(
              decoration: BoxDecoration(
        gradient: isFollowing 
            ? LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
        boxShadow: isFollowing 
            ? null
            : [
                BoxShadow(
                  color: AppTheme.primaryDarkGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _toggleFollow(userId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
              mainAxisSize: MainAxisSize.min,
                children: [
                Icon(
                  isFollowing ? Icons.check_rounded : Icons.add_rounded,
                  color: isFollowing ? AppTheme.textPrimary : AppTheme.surfaceWhite,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: isFollowing ? AppTheme.textPrimary : AppTheme.surfaceWhite,
                        fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildModernStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
            Container(
          padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
            color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildModernButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary ? AppTheme.primaryGradient : null,
        color: isPrimary ? null : AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? null : Border.all(color: AppTheme.primaryDarkGreen.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: isPrimary 
                ? AppTheme.primaryDarkGreen.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Text(
              text,
              style: TextStyle(
                color: isPrimary ? AppTheme.surfaceWhite : AppTheme.primaryDarkGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

}

