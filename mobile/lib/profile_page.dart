import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'camera_scan_page.dart';
import 'recipe_details_page.dart';
import 'edit_profile_screen.dart';
import 'splash_screen.dart';
import 'app_theme.dart';
import 'services/api_service.dart';

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
  
  // Sample user data - in a real app, this would be managed by a state management solution
  Map<String, dynamic> _userProfile = {
    'name': 'Ralph Matanguihan',
    'bio': 'Filipino food • Traditional recipes lover',
    'recipesCount': 32,
    'followingCount': 782,
    'followersCount': 1287,
    'joinDate': 'January 2023',
    'location': 'Manila, Philippines',
    'isVerified': true,
    'profileImageUrl': null,
  };

  // Sample user recipes data
  final List<Map<String, dynamic>> _userRecipes = [
    {
      'id': '1',
      'name': 'Ginataang Kalabasa at Sitaw',
      'type': 'Food',
      'time': '25 mins',
      'likes': 127,
      'creator': 'Ralph Matanguihan',
      'description': 'Traditional Filipino vegetable stew cooked in rich coconut milk with squash and string beans.',
      'rating': 4.7,
      'serves': 4,
      'difficulty': 'Easy',
      'category': 'Vegetarian',
      'prepTime': 10,
      'cookTime': 15,
      'ingredients': 12,
      'isBookmarked': true,
      'dateCreated': '1 week ago',
    },
    {
      'id': '2',
      'name': 'Chicken Inasal',
      'type': 'Food', 
      'time': '90 mins',
      'likes': 89,
      'creator': 'Ralph Matanguihan',
      'description': 'Authentic Ilonggo grilled chicken marinated in lemongrass, calamansi, and annatto.',
      'rating': 4.8,
      'serves': 6,
      'difficulty': 'Medium',
      'category': 'Grilled',
      'prepTime': 45,
      'cookTime': 45,
      'ingredients': 8,
      'isBookmarked': false,
      'dateCreated': '2 days ago',
    },
    {
      'id': '3',
      'name': 'Sinigang na Baboy',
      'type': 'Food',
      'time': '60 mins',
      'likes': 156,
      'creator': 'Ralph Matanguihan',
      'description': 'Classic Filipino sour soup with pork ribs, vegetables, and tamarind broth.',
      'rating': 4.9,
      'serves': 4,
      'difficulty': 'Medium',
      'category': 'Soup',
      'prepTime': 20,
      'cookTime': 40,
      'ingredients': 10,
      'isBookmarked': false,
      'dateCreated': '2 weeks ago',
    },
    {
      'id': '4',
      'name': 'Bibingka',
      'type': 'Food',
      'time': '45 mins',
      'likes': 73,
      'creator': 'Ralph Matanguihan',
      'description': 'Traditional Filipino rice cake topped with salted egg, cheese, and coconut.',
      'rating': 4.6,
      'serves': 8,
      'difficulty': 'Medium',
      'category': 'Dessert',
      'prepTime': 20,
      'cookTime': 25,
      'ingredients': 9,
      'isBookmarked': true,
      'dateCreated': '3 weeks ago',
    },
    {
      'id': '5',
      'name': 'Leche Flan',
      'type': 'Food',
      'time': '120 mins',
      'likes': 203,
      'creator': 'Ralph Matanguihan',
      'description': 'Silky smooth caramel custard dessert made with egg yolks and condensed milk.',
      'rating': 4.8,
      'serves': 6,
      'difficulty': 'Hard',
      'category': 'Dessert',
      'prepTime': 30,
      'cookTime': 90,
      'ingredients': 5,
      'isBookmarked': false,
      'dateCreated': '1 month ago',
    },
    {
      'id': '6',
      'name': 'Pancit Canton',
      'type': 'Food',
      'time': '30 mins',
      'likes': 94,
      'creator': 'Ralph Matanguihan',
      'description': 'Savory stir-fried wheat noodles with mixed vegetables and choice of meat.',
      'rating': 4.5,
      'serves': 4,
      'difficulty': 'Easy',
      'category': 'Noodles',
      'prepTime': 15,
      'cookTime': 15,
      'ingredients': 11,
      'isBookmarked': true,
      'dateCreated': '1 month ago',
    },
  ];

  // Sample liked recipes from other users
  final List<Map<String, dynamic>> _likedRecipes = [
    {
      'id': '7',
      'name': 'Taho',
      'type': 'Drink',
      'time': '15 mins',
      'likes': 445,
      'creator': 'Manila Street Vendor',
      'description': 'Sweet silken tofu dessert with brown sugar syrup and sago pearls.',
      'rating': 4.5,
      'serves': 2,
      'difficulty': 'Easy',
      'category': 'Beverage',
      'isBookmarked': false,
    },
    {
      'id': '8',
      'name': 'Pork Adobo',
      'type': 'Food',
      'time': '60 mins',
      'likes': 312,
      'creator': 'Lola Maria\'s Kitchen',
      'description': 'The quintessential Filipino dish - tender pork braised in soy sauce and vinegar.',
      'rating': 4.9,
      'serves': 6,
      'difficulty': 'Easy',
      'category': 'Main Course',
      'isBookmarked': true,
    },
    {
      'id': '9',
      'name': 'Lechon Kawali',
      'type': 'Food',
      'time': '90 mins',
      'likes': 188,
      'creator': 'Chef Antonio Santos',
      'description': 'Crispy deep-fried pork belly served with traditional liver sauce.',
      'rating': 4.7,
      'serves': 4,
      'difficulty': 'Medium',
      'category': 'Fried',
      'isBookmarked': false,
    },
    {
      'id': '10',
      'name': 'Halo-Halo',
      'type': 'Drink',
      'time': '20 mins',
      'likes': 267,
      'creator': 'Tropical Dessert Co.',
      'description': 'The ultimate Filipino shaved ice dessert with mixed fruits and toppings.',
      'rating': 4.8,
      'serves': 1,
      'difficulty': 'Easy',
      'category': 'Dessert',
      'isBookmarked': true,
    },
    {
      'id': '11',
      'name': 'Kare-Kare',
      'type': 'Food',
      'time': '120 mins',
      'likes': 145,
      'creator': 'Kapampangan Kitchen',
      'description': 'Rich oxtail stew in thick peanut sauce with vegetables.',
      'rating': 4.8,
      'serves': 8,
      'difficulty': 'Hard',
      'category': 'Stew',
      'isBookmarked': false,
    },
    {
      'id': '12',
      'name': 'Lumpia Shanghai',
      'type': 'Food',
      'time': '45 mins',
      'likes': 199,
      'creator': 'Home Chef Tita Rosa',
      'description': 'Crispy Filipino spring rolls filled with seasoned ground pork and vegetables.',
      'rating': 4.4,
      'serves': 6,
      'difficulty': 'Medium',
      'category': 'Appetizer',
      'isBookmarked': true,
    },
  ];

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
    
    // Start initial animations
    _fadeController.forward();
    _contentFadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _contentFadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _selectScanOption(String option) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScanPage(scanType: option),
      ),
    );
  }

  void _editProfile() async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userProfile: _userProfile,
          onProfileUpdated: (updatedProfile) {
            setState(() {
              _userProfile.addAll(updatedProfile);
            });
          },
        ),
      ),
    );
    
    // Handle any additional logic after editing profile
    if (result != null && mounted) {
      // Profile was updated, trigger animations
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  void _showLogoutDialog() {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppTheme.surfaceWhite,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout,
                  color: AppTheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout? You\'ll need to sign in again to access your account.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _performLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: AppTheme.surfaceWhite,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    // Close the dialog first
    Navigator.of(context).pop();
    
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppTheme.primaryDarkGreen,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Logging out...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Call API logout
      await ApiService.logout();
      
      if (mounted) {
        // Clear the loading dialog
        Navigator.of(context).pop();
        
        // Navigate to splash screen with logout flag and clear the entire navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const SplashScreen(
              isPostLogout: true,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        // Clear the loading dialog
        Navigator.of(context).pop();
        
        // Show error message but still navigate to logout
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout completed locally'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Navigate to splash screen anyway
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const SplashScreen(
              isPostLogout: true,
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  void _shareProfile() {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppTheme.textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Share Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.link, 'Copy Link', Colors.blue),
                _buildShareOption(Icons.message, 'Messages', AppTheme.primaryDarkGreen),
                _buildShareOption(Icons.email, 'Email', Colors.orange),
                _buildShareOption(Icons.more_horiz, 'More', AppTheme.textSecondary),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showSnackBar('Shared via $label', isSuccess: true);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
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

  void _toggleBookmark(String recipeId, bool currentState) {
    HapticFeedback.lightImpact();
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
    
    _showSnackBar(
      !currentState ? 'Recipe bookmarked!' : 'Bookmark removed',
      isSuccess: !currentState,
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.primaryDarkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 24,
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (_showRecipes == (label == 'Recipes')) return;
        
        HapticFeedback.selectionClick();
        setState(() {
          _showRecipes = label == 'Recipes';
        });
        
        // Trigger ONLY content animation, not the toggle buttons
        _contentFadeController.reset();
        _contentFadeController.forward();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryDarkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDarkGreen : AppTheme.textDisabled,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryDarkGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.surfaceWhite : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRecipesGrid() {
    if (_userRecipes.isEmpty) {
      return _buildEmptyState(
        Icons.restaurant_menu,
        'No recipes yet',
        'Start sharing your delicious Filipino recipes with the community!',
        'Upload Recipe',
        () => _selectScanOption('Food'),
      );
    }

    return FadeTransition(
      opacity: _contentFadeAnimation,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _userRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _userRecipes[index];
          return _buildRecipeCard(recipe, isOwnRecipe: true);
        },
      ),
    );
  }

  Widget _buildLikedGrid() {
    if (_likedRecipes.isEmpty) {
      return _buildEmptyState(
        Icons.favorite_outline,
        'No liked recipes',
        'Explore and like recipes from other Filipino food enthusiasts!',
        'Discover Recipes',
        () => Navigator.pop(context),
      );
    }

    return FadeTransition(
      opacity: _contentFadeAnimation,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _likedRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _likedRecipes[index];
          return _buildRecipeCard(recipe, isOwnRecipe: false);
        },
      ),
    );
  }

  Widget _buildEmptyState(
    IconData icon,
    String title,
    String description,
    String buttonText,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textDisabled.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.textDisabled.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppTheme.textDisabled,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add, size: 20),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDarkGreen,
              foregroundColor: AppTheme.surfaceWhite,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe, {required bool isOwnRecipe}) {
    final bool isBookmarked = recipe['isBookmarked'] ?? false;
    
    return GestureDetector(
      onTap: () => _openRecipeDetails(recipe),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image placeholder with gradient and overlays
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondaryLightGreen,
                    AppTheme.primaryDarkGreen,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Main food icon
                  const Center(
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 48,
                      color: Colors.white70,
                    ),
                  ),
                  
                  // Top row: Bookmark and Likes
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bookmark button
                        GestureDetector(
                          onTap: () => _toggleBookmark(recipe['id'], isBookmarked),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              size: 16,
                              color: isBookmarked ? Colors.yellow : Colors.white,
                            ),
                          ),
                        ),
                        
                        // Likes count
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite, size: 12, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                recipe['likes'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom row: Rating and Time
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rating
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(
                                recipe['rating']?.toString() ?? '4.5',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Time badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 12, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(
                                recipe['time'] ?? '30 mins',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${recipe['creator']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Recipe stats
                    Row(
                      children: [
                        Icon(Icons.people, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          'Serves ${recipe['serves'] ?? 4}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(recipe['difficulty'] ?? 'Easy').withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            recipe['difficulty'] ?? 'Easy',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getDifficultyColor(recipe['difficulty'] ?? 'Easy'),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (isOwnRecipe && recipe['dateCreated'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Created ${recipe['dateCreated']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.success;
      case 'medium':
        return AppTheme.warning;
      case 'hard':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.backgroundGradientDecoration(),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header with logout button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration(elevation: 15),
                    child: Column(
                      children: [
                        // Header with logout button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 40),
                            Text(
                              'Profile',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Logout button
                            GestureDetector(
                              onTap: _showLogoutDialog,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.error.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.logout,
                                  color: AppTheme.error,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Row(
                          children: [
                            // Profile picture with better styling
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.secondaryLightGreen,
                                    AppTheme.primaryDarkGreen,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryDarkGreen.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _userProfile['profileImageUrl'] != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _userProfile['profileImageUrl']!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Text(
                                              _userProfile['name']?.toString().isNotEmpty == true 
                                                  ? _userProfile['name'][0].toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                color: AppTheme.surfaceWhite,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        _userProfile['name']?.toString().isNotEmpty == true 
                                            ? _userProfile['name'][0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: AppTheme.surfaceWhite,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 20),
                            
                            // Profile info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _userProfile['name'] ?? 'User',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (_userProfile['isVerified'] == true)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.verified,
                                            color: AppTheme.surfaceWhite,
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _userProfile['bio'] ?? 'Food enthusiast',
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
                                        Icons.location_on, 
                                        size: 16, 
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _userProfile['location'] ?? 'Philippines',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
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
                        
                        const SizedBox(height: 24),
                        
                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatColumn(
                              _userProfile['recipesCount']?.toString() ?? '0',
                              'Recipes',
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: AppTheme.textDisabled,
                            ),
                            _buildStatColumn(
                              _userProfile['followersCount']?.toString() ?? '0',
                              'Followers',
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: AppTheme.textDisabled,
                            ),
                            _buildStatColumn(
                              _userProfile['followingCount']?.toString() ?? '0',
                              'Following',
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _editProfile,
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Edit Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryDarkGreen,
                                  foregroundColor: AppTheme.surfaceWhite,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _shareProfile,
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Share'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryDarkGreen,
                                  side: BorderSide(color: AppTheme.primaryDarkGreen, width: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Toggle buttons - NOT affected by content fade
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildToggleButton('Recipes', _showRecipes),
                    const SizedBox(width: 16),
                    _buildToggleButton('Liked', !_showRecipes),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Content grid - ONLY this fades when switching
                _showRecipes ? _buildRecipesGrid() : _buildLikedGrid(),
                
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }
}