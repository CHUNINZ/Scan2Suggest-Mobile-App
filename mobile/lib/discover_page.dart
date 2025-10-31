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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh users when returning to this page to get updated profile images
    if (!_isLoading && _users.isNotEmpty) {
      _refreshUsers();
    }
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
    final normalizedPath = imageStr.startsWith('/') ? imageStr : '/$imageStr';
    return '$baseUrl$normalizedPath';
  }

  Future<void> _refreshUsers() async {
    HapticFeedback.lightImpact();
    await _loadUsers();
  }

  void _openUserProfile(Map<String, dynamic> user) async {
    HapticFeedback.selectionClick();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: user['id'].toString(),
          userName: user['name'],
          preloadedUserData: user, // Pass the preloaded user data with stats
        ),
      ),
    );
    
    // Refresh users when returning from profile to get updated profile images
    _refreshUsers();
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
      backgroundColor: Colors.grey[50],
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
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: const Text(
                'Discover Users',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
      backgroundColor: Colors.grey[50],
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
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshUsers,
        color: AppTheme.primaryDarkGreen,
        backgroundColor: Colors.white,
        strokeWidth: 2.0,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
                  color: Colors.white,
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
        ),
        ),
      );
    }

  Widget _buildModernDiscoverView() {
    return RefreshIndicator(
      onRefresh: _refreshUsers,
      color: AppTheme.primaryDarkGreen,
      backgroundColor: Colors.white,
      strokeWidth: 2.0,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Clean header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: const Text(
                'Discover Users',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // User list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openUserProfile(user),
      child: Padding(
            padding: const EdgeInsets.all(16),
        child: Column(
          children: [
                // Main content row
            Row(
              children: [
                    // Profile picture - simple and clean
                GestureDetector(
                  onTap: () => _openUserProfile(user),
                    child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primaryDarkGreen.withOpacity(0.1),
                      backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                      child: profileImageUrl == null
                            ? Text(
                              user['name']?.toString().isNotEmpty == true
                                  ? user['name'][0].toUpperCase()
                                  : 'U',
                                style: TextStyle(
                                  fontSize: 24,
                                fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryDarkGreen,
                              ),
                            )
                          : null,
                    ),
                  ),
                    const SizedBox(width: 12),
                
                    // User info - clean and simple
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? 'Unknown User',
                          style: const TextStyle(
                              fontSize: 16,
                            fontWeight: FontWeight.bold,
                              color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                          const SizedBox(height: 4),
                          Text(
                            user['bio']?.toString().isNotEmpty == true
                                ? user['bio']
                                : 'Food enthusiast and recipe creator',
                            style: TextStyle(
                                fontSize: 14,
                              color: Colors.grey[600],
                                height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Follow button - clean and simple
                    _buildCleanFollowButton(isFollowing, userId),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Stats row - simple and clean like the image
                Row(
                  children: [
                    _buildCleanStatItem(
                      icon: Icons.people,
                      value: _formatNumber(user['followersCount']),
                      label: 'followers',
                    ),
                    const SizedBox(width: 20),
                    _buildCleanStatItem(
                      icon: Icons.restaurant_menu,
                      value: user['recipesCount'].toString(),
                      label: 'posts',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanFollowButton(bool isFollowing, String userId) {
    return Container(
              decoration: BoxDecoration(
        color: isFollowing ? Colors.green : Colors.blue,
                        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _toggleFollow(userId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
                      isFollowing ? 'Following' : 'Follow',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                    fontSize: 14,
              ),
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildCleanStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
            icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
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

