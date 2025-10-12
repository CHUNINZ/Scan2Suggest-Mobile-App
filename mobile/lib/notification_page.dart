import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'camera_scan_page.dart';
import 'app_theme.dart';

// Notification type enum for better type safety
enum NotificationType {
  like,
  comment,
  follow,
  recipe,
}

// Notification model class
class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData iconData;
  final Color iconColor;
  final NotificationType type;
  final String timestamp;
  bool isNew; // Changed to mutable
  final Widget? trailing;

  NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.iconColor,
    required this.type,
    required this.timestamp,
    this.isNew = false,
    this.trailing,
  });
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with TickerProviderStateMixin {
  final List<String> _filterOptions = ['All', 'Likes', 'Comments', 'Follows', 'Recipes'];
  String _selectedFilter = 'All';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // All notifications data
  late List<NotificationItem> _allNotifications;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _initializeNotifications();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeNotifications() {
    _allNotifications = [
      // NEW NOTIFICATIONS
      NotificationItem(
        id: 'new_1',
        title: 'Rhian Matanguihan',
        subtitle: 'now following you',
        iconData: Icons.person_add,
        iconColor: Colors.blue,
        type: NotificationType.follow,
        timestamp: '1h',
        isNew: true,
        trailing: _buildFollowButton(),
      ),
      NotificationItem(
        id: 'new_2',
        title: 'Recipe Alert',
        subtitle: 'New Filipino recipes matching your interests',
        iconData: Icons.restaurant_menu,
        iconColor: Colors.orange,
        type: NotificationType.recipe,
        timestamp: '2h',
        isNew: true,
      ),
      
      // TODAY NOTIFICATIONS
      NotificationItem(
        id: 'today_1',
        title: 'Micaella Matanguihan and Monica Matanguihan',
        subtitle: 'liked your Ginataang Kalabasa recipe',
        iconData: Icons.favorite,
        iconColor: Colors.red,
        type: NotificationType.like,
        timestamp: '20 min',
        isNew: false,
      ),
      NotificationItem(
        id: 'today_2',
        title: 'Lovely Vicky Matanguihan',
        subtitle: 'now following you',
        iconData: Icons.person_add,
        iconColor: Colors.blue,
        type: NotificationType.follow,
        timestamp: '1h',
        isNew: false,
        trailing: _buildFollowButton(),
      ),
      NotificationItem(
        id: 'today_3',
        title: 'Filipino Food Lovers',
        subtitle: 'commented on your Chicken Inasal',
        iconData: Icons.comment,
        iconColor: Colors.green,
        type: NotificationType.comment,
        timestamp: '45 min',
        isNew: false,
      ),
      NotificationItem(
        id: 'today_4',
        title: 'Traditional Recipes Group',
        subtitle: 'shared your Bibingka recipe',
        iconData: Icons.share,
        iconColor: Colors.purple,
        type: NotificationType.recipe,
        timestamp: '2h',
        isNew: false,
      ),
      
      // YESTERDAY NOTIFICATIONS
      NotificationItem(
        id: 'yesterday_1',
        title: 'Cooking Enthusiasts',
        subtitle: 'liked your Sinigang na Baboy recipe',
        iconData: Icons.favorite,
        iconColor: Colors.red,
        type: NotificationType.like,
        timestamp: '1d',
        isNew: false,
      ),
      NotificationItem(
        id: 'yesterday_2',
        title: 'Pinoy Chef Community',
        subtitle: 'featured your Taho recipe in their collection',
        iconData: Icons.star,
        iconColor: Colors.amber,
        type: NotificationType.recipe,
        timestamp: '1d',
        isNew: false,
      ),
      NotificationItem(
        id: 'yesterday_3',
        title: 'Food Photography Group',
        subtitle: 'commented on your recipe photos',
        iconData: Icons.photo_camera,
        iconColor: Colors.indigo,
        type: NotificationType.comment,
        timestamp: '1d',
        isNew: false,
      ),
      NotificationItem(
        id: 'yesterday_4',
        title: 'Asian Cuisine Lovers',
        subtitle: 'saved your Adobo recipe to favorites',
        iconData: Icons.bookmark,
        iconColor: Colors.teal,
        type: NotificationType.like,
        timestamp: '1d',
        isNew: false,
      ),
      
      // THIS WEEK NOTIFICATIONS
      NotificationItem(
        id: 'week_1',
        title: 'Recipe Challenge',
        subtitle: 'Join the "Best Adobo Recipe" challenge',
        iconData: Icons.emoji_events,
        iconColor: Colors.deepOrange,
        type: NotificationType.recipe,
        timestamp: '3d',
        isNew: false,
      ),
      NotificationItem(
        id: 'week_2',
        title: 'Monthly Report',
        subtitle: 'Your recipes got 1.2k views this month!',
        iconData: Icons.analytics,
        iconColor: Colors.cyan,
        type: NotificationType.recipe,
        timestamp: '5d',
        isNew: false,
      ),
      NotificationItem(
        id: 'week_3',
        title: 'Chef Maria Santos',
        subtitle: 'commented: "Amazing traditional recipe!"',
        iconData: Icons.comment,
        iconColor: Colors.green,
        type: NotificationType.comment,
        timestamp: '4d',
        isNew: false,
      ),
      NotificationItem(
        id: 'week_4',
        title: 'John Dela Cruz',
        subtitle: 'started following you',
        iconData: Icons.person_add,
        iconColor: Colors.blue,
        type: NotificationType.follow,
        timestamp: '6d',
        isNew: false,
        trailing: _buildFollowButton(),
      ),
    ];
  }

  // Filter notifications based on selected category
  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilter == 'All') {
      return _allNotifications;
    }
    
    NotificationType? filterType;
    switch (_selectedFilter) {
      case 'Likes':
        filterType = NotificationType.like;
        break;
      case 'Comments':
        filterType = NotificationType.comment;
        break;
      case 'Follows':
        filterType = NotificationType.follow;
        break;
      case 'Recipes':
        filterType = NotificationType.recipe;
        break;
    }
    
    if (filterType != null) {
      return _allNotifications.where((notif) => notif.type == filterType).toList();
    }
    
    return _allNotifications;
  }

  // Group filtered notifications by time period
  Map<String, List<NotificationItem>> get _groupedNotifications {
    final filtered = _filteredNotifications;
    final Map<String, List<NotificationItem>> grouped = {
      'New': [],
      'Today': [],
      'Yesterday': [],
      'This Week': [],
    };
    
    for (var notification in filtered) {
      if (notification.isNew) {
        grouped['New']!.add(notification);
      } else if (notification.timestamp.contains('min') || 
                 notification.timestamp.contains('h') && 
                 !notification.timestamp.contains('1d')) {
        grouped['Today']!.add(notification);
      } else if (notification.timestamp.contains('1d')) {
        grouped['Yesterday']!.add(notification);
      } else {
        grouped['This Week']!.add(notification);
      }
    }
    
    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    
    return grouped;
  }

  void _selectScanOption(String option) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScanPage(scanType: option),
      ),
    );
  }

  void _onFilterSelected(String filter) {
    if (_selectedFilter != filter) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedFilter = filter;
      });
      
      // Restart animation
      _fadeController.reset();
      _fadeController.forward();
      
      // NO FEEDBACK TEXT - Removed as per requirements
    }
  }

  void _markAllAsRead() {
    HapticFeedback.lightImpact();
    
    // Count unread notifications before marking as read
    final unreadCount = _allNotifications.where((n) => n.isNew).length;
    
    if (unreadCount == 0) {
      // Show message if all already read
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('All notifications are already read'),
            ],
          ),
          backgroundColor: AppTheme.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      // Mark all notifications as read
      for (var notification in _allNotifications) {
        notification.isNew = false;
      }
    });
    
    // Show success message with count
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.done_all, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('$unreadCount notification${unreadCount > 1 ? 's' : ''} marked as read'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            // Undo functionality - mark the notifications back as new
            setState(() {
              for (var notification in _allNotifications) {
                if (notification.id.startsWith('new_')) {
                  notification.isNew = true;
                }
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.backgroundGradientDecoration(),
      child: SafeArea(
        child: Column(
          children: [
            // Header with mark all read button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Show unread count badge next to title
                      if (_allNotifications.any((n) => n.isNew))
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.error.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${_allNotifications.where((n) => n.isNew).length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Only show "Mark all read" button if there are unread notifications
                  if (_allNotifications.any((n) => n.isNew))
                    TextButton.icon(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Mark all read'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryDarkGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: AppTheme.primaryDarkGreen.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Filter chips
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filterOptions.length,
                itemBuilder: (context, index) {
                  final filter = _filterOptions[index];
                  final isSelected = _selectedFilter == filter;
                  
                  // Count UNREAD notifications for this filter
                  int unreadCount = 0;
                  if (filter == 'All') {
                    unreadCount = _allNotifications.where((n) => n.isNew).length;
                  } else {
                    NotificationType? type;
                    switch (filter) {
                      case 'Likes':
                        type = NotificationType.like;
                        break;
                      case 'Comments':
                        type = NotificationType.comment;
                        break;
                      case 'Follows':
                        type = NotificationType.follow;
                        break;
                      case 'Recipes':
                        type = NotificationType.recipe;
                        break;
                    }
                    if (type != null) {
                      unreadCount = _allNotifications
                          .where((n) => n.type == type && n.isNew)
                          .length;
                    }
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(filter),
                          // Only show badge if there are UNREAD notifications
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.white.withOpacity(0.3)
                                    : AppTheme.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) => _onFilterSelected(filter),
                      selectedColor: AppTheme.primaryDarkGreen,
                      backgroundColor: AppTheme.surfaceWhite,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      elevation: isSelected ? 4 : 1,
                      shadowColor: isSelected 
                          ? AppTheme.primaryDarkGreen.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            
            // Notifications list
            Expanded(
              child: _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    final groupedNotifications = _groupedNotifications;
    
    if (groupedNotifications.isEmpty) {
      return _buildEmptyState();
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: groupedNotifications.length,
        itemBuilder: (context, index) {
          final section = groupedNotifications.keys.elementAt(index);
          final notifications = groupedNotifications[section]!;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildNotificationSection(section, notifications),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'Likes':
        message = 'No likes yet';
        icon = Icons.favorite_outline;
        break;
      case 'Comments':
        message = 'No comments yet';
        icon = Icons.comment_outlined;
        break;
      case 'Follows':
        message = 'No new followers';
        icon = Icons.person_add_outlined;
        break;
      case 'Recipes':
        message = 'No recipe notifications';
        icon = Icons.restaurant_menu_outlined;
        break;
      default:
        message = 'No notifications';
        icon = Icons.notifications_none;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.textDisabled.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 50,
              color: AppTheme.textDisabled,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'You\'re all caught up!'
                : 'Check back later for updates',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(String title, List<NotificationItem> notifications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryDarkGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryDarkGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '${notifications.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryDarkGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: notifications.map((notification) {
            return _buildNotificationItem(notification);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      key: ValueKey(notification.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isNew 
            ? AppTheme.primaryDarkGreen.withOpacity(0.05)
            : AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: notification.isNew
            ? Border.all(
                color: AppTheme.primaryDarkGreen.withOpacity(0.2),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: notification.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: notification.iconColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                notification.iconData,
                color: notification.iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (notification.isNew)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryDarkGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        notification.timestamp,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Trailing widget (e.g., Follow button)
            if (notification.trailing != null) ...[
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: notification.trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryDarkGreen,
            AppTheme.secondaryLightGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDarkGreen.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'Follow',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}