import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'services/api_service.dart';
import 'utils/dialog_helper.dart';

class RecipeDetailsPage extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailsPage({super.key, required this.recipe});

  @override
  State<RecipeDetailsPage> createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  late bool _isLiked;
  late bool _isBookmarked;
  late int _likesCount;
  bool _isLoadingLike = false;
  bool _isLoadingBookmark = false;
  
  // Comments state
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  
  // Reply state
  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, bool> _isSubmittingReply = {};
  final Map<String, bool> _showReplyInput = {};
  
  // Nested reply state
  final Map<String, TextEditingController> _nestedReplyControllers = {};
  final Map<String, bool> _isSubmittingNestedReply = {};
  final Map<String, bool> _showNestedReplyInput = {};
  
  // Unlimited nesting state
  final Map<String, TextEditingController> _unlimitedReplyControllers = {};
  final Map<String, bool> _isSubmittingUnlimitedReply = {};
  final Map<String, bool> _showUnlimitedReplyInput = {};
  
  @override
  void initState() {
    super.initState();
    
    // Debug: Print recipe data received
    print('📄 RecipeDetailsPage initialized with:');
    print('   Title: ${widget.recipe['title']}');
    print('   Name: ${widget.recipe['name']}');
    print('   Description: ${widget.recipe['description']}');
    print('   ID: ${widget.recipe['id']}');
    print('   All keys: ${widget.recipe.keys.toList()}');
    
    // Initialize from recipe data
    _isLiked = widget.recipe['isLiked'] ?? false;
    _isBookmarked = widget.recipe['isBookmarked'] ?? false;
    _likesCount = _getLikesCount();
    
    // Load comments
    _loadComments();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    // Dispose all reply controllers
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    // Dispose all nested reply controllers
    for (final controller in _nestedReplyControllers.values) {
      controller.dispose();
    }
    // Dispose all unlimited reply controllers
    for (final controller in _unlimitedReplyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  // Get real likes count from recipe data (handle both 'likes' and 'likesCount')
  int _getLikesCount() {
    final likesValue = widget.recipe['likesCount'] ?? widget.recipe['likes'] ?? 0;
    // Ensure it's an int, handle both int and double
    if (likesValue is int) return likesValue;
    if (likesValue is double) return likesValue.toInt();
    if (likesValue is String) return int.tryParse(likesValue) ?? 0;
    return 0;
  }
  
  // Get ingredients from recipe data
  List<Map<String, dynamic>> get _ingredients {
    final ingredientsList = widget.recipe['ingredients'] as List<dynamic>? ?? [];
    return ingredientsList.map((ing) {
      return {
        'name': ing is String ? ing : (ing['name'] ?? 'Unknown ingredient'),
      };
    }).toList();
  }

  // Get steps from recipe data
  List<String> get _steps {
    final stepsList = widget.recipe['steps'] as List<dynamic>? ?? [];
    if (stepsList.isEmpty) {
      return ['No cooking instructions available for this recipe.'];
    }
    return stepsList.map((step) => step.toString()).toList();
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) return;
    
    setState(() {
      _isLoadingLike = true;
    });
    
    HapticFeedback.lightImpact();
    
    try {
      final recipeId = widget.recipe['id'] ?? widget.recipe['_id'];
      if (recipeId == null) {
        throw Exception('Recipe ID not found');
      }
      
      final response = await ApiService.likeRecipe(recipeId.toString());
      
      if (response['success'] == true && mounted) {
        setState(() {
          _isLiked = response['isLiked'] ?? !_isLiked;
          _likesCount = response['likesCount'] ?? _likesCount;
          _isLoadingLike = false;
        });
        
        DialogHelper.showSuccess(
          context,
          title: _isLiked ? "Recipe Liked! ❤️" : "Recipe Unliked",
          message: _isLiked ? "Added to your liked recipes!" : "Removed from your liked recipes",
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to like recipe');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLike = false;
        });
        
        DialogHelper.showError(
          context,
          title: "Error",
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
  
  Future<void> _toggleBookmark() async {
    if (_isLoadingBookmark) return;
    
    setState(() {
      _isLoadingBookmark = true;
    });
    
    HapticFeedback.lightImpact();
    
    try {
      final recipeId = widget.recipe['id'] ?? widget.recipe['_id'];
      if (recipeId == null) {
        throw Exception('Recipe ID not found');
      }
      
      final response = await ApiService.bookmarkRecipe(recipeId.toString());
      
      if (response['success'] == true && mounted) {
        setState(() {
          _isBookmarked = response['isBookmarked'] ?? !_isBookmarked;
          _isLoadingBookmark = false;
        });
        
        DialogHelper.showSuccess(
          context,
          title: _isBookmarked ? "Recipe Saved! 🔖" : "Recipe Removed",
          message: _isBookmarked ? "Added to your saved recipes!" : "Removed from your saved recipes",
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to bookmark recipe');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBookmark = false;
        });
        
        DialogHelper.showError(
          context,
          title: "Error",
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
  
  Future<void> _showRatingDialog() async {
    int selectedRating = 0;
    final TextEditingController reviewController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Rate this Recipe',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'How would you rate this recipe?',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedRating = index + 1;
                            });
                          },
                          child: Icon(
                            index < selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: 'Write a review (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedRating > 0
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    
    if (result == true && selectedRating > 0) {
      try {
        final recipeId = widget.recipe['id'] ?? widget.recipe['_id'];
        if (recipeId == null) {
          throw Exception('Recipe ID not found');
        }
        
        final response = await ApiService.rateRecipe(
          recipeId: recipeId.toString(),
          rating: selectedRating,
          review: reviewController.text.trim().isNotEmpty ? reviewController.text.trim() : null,
        );
        
        if (response['success'] == true && mounted) {
          DialogHelper.showSuccess(
            context,
            title: "Thank You! ⭐",
            message: "Your rating has been submitted successfully!",
          );
        } else {
          throw Exception(response['message'] ?? 'Failed to rate recipe');
        }
      } catch (e) {
        if (mounted) {
          DialogHelper.showError(
            context,
            title: "Error",
            message: e.toString().replaceAll('Exception: ', ''),
          );
        }
      }
    }
    
    reviewController.dispose();
  }
  
  // Load comments
  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });
    
    try {
      final recipeId = widget.recipe['id'] ?? widget.recipe['_id'];
      if (recipeId == null) {
        throw Exception('Recipe ID not found');
      }
      
      final response = await ApiService.getComments(
        recipeId: recipeId.toString(),
        limit: 50,
      );
      
      if (response['success'] == true && mounted) {
        final comments = response['comments'] as List? ?? [];
        setState(() {
          _comments = comments.cast<Map<String, dynamic>>();
          _isLoadingComments = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load comments');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
        print('Error loading comments: $e');
      }
    }
  }
  
  // Submit comment
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _isSubmittingComment = true;
    });
    
    HapticFeedback.lightImpact();
    
    try {
      final recipeId = widget.recipe['id'] ?? widget.recipe['_id'];
      if (recipeId == null) {
        throw Exception('Recipe ID not found');
      }
      
      final response = await ApiService.addComment(
        recipeId: recipeId.toString(),
        text: text,
      );
      
      if (response['success'] == true && mounted) {
        _commentController.clear();
        await _loadComments(); // Reload comments
        // Success dialog removed for better UX
      } else {
        throw Exception(response['message'] ?? 'Failed to add comment');
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showError(
          context,
          title: "Error",
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }
  
  // Delete comment
  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      final recipeId = widget.recipe['id'] ?? widget.recipe['_id'];
      if (recipeId == null) {
        throw Exception('Recipe ID not found');
      }
      
      final response = await ApiService.deleteComment(
        recipeId: recipeId.toString(),
        commentId: commentId,
      );
      
      if (response['success'] == true && mounted) {
        await _loadComments(); // Reload comments
        
        DialogHelper.showSuccess(
          context,
          title: "Comment Deleted",
          message: "The comment has been removed.",
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to delete comment');
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showError(
          context,
          title: "Error",
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  // Show reply input (Facebook-style)
  void _toggleReplyInput(String commentId) {
    setState(() {
      _showReplyInput[commentId] = true;
      _replyControllers[commentId] = TextEditingController();
      _isSubmittingReply[commentId] = false;
    });
  }

  // Show nested reply input (Facebook-style)
  void _toggleNestedReplyInput(String replyId) {
    setState(() {
      _showNestedReplyInput[replyId] = true;
      _nestedReplyControllers[replyId] = TextEditingController();
      _isSubmittingNestedReply[replyId] = false;
    });
  }

  // Submit reply
  Future<void> _submitReply(String commentId) async {
    final controller = _replyControllers[commentId];
    if (controller == null) return;
    
    final text = controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _isSubmittingReply[commentId] = true;
    });
    
    HapticFeedback.lightImpact();
    
    try {
      final recipeId = widget.recipe['id'] ?? widget.recipe['_id'];
      if (recipeId == null) {
        throw Exception('Recipe ID not found');
      }
      
      final response = await ApiService.addReply(
        recipeId: recipeId.toString(),
        commentId: commentId,
        text: text,
      );
      
      if (response['success'] == true && mounted) {
        controller.clear();
        // Close reply input after submission (Facebook-style)
        setState(() {
          _showReplyInput[commentId] = false;
        });
        await _loadComments(); // Reload comments
        // Success dialog removed for better UX
      } else {
        throw Exception(response['message'] ?? 'Failed to add reply');
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showError(
          context,
          title: "Error",
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReply[commentId] = false;
        });
      }
    }
  }

  // Submit nested reply
  Future<void> _submitNestedReply(String commentId, String replyId) async {
    final controller = _nestedReplyControllers[replyId];
    if (controller == null) return;
    
    final text = controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _isSubmittingNestedReply[replyId] = true;
    });
    
    HapticFeedback.lightImpact();
    
    try {
      final recipeId = widget.recipe['id'] ?? widget.recipe['_id'];
      if (recipeId == null) {
        throw Exception('Recipe ID not found');
      }
      
      final response = await ApiService.addNestedReply(
        recipeId: recipeId.toString(),
        commentId: commentId,
        replyId: replyId,
        text: text,
      );
      
      if (response['success'] == true && mounted) {
        controller.clear();
        // Close nested reply input after submission (Facebook-style)
        setState(() {
          _showNestedReplyInput[replyId] = false;
        });
        await _loadComments(); // Reload comments
        // Success dialog removed for better UX
      } else {
        throw Exception(response['message'] ?? 'Failed to add nested reply');
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showError(
          context,
          title: "Error",
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingNestedReply[replyId] = false;
        });
      }
    }
  }

  // Delete reply
  Future<void> _deleteReply(String commentId, String replyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      final recipeId = widget.recipe['id'] ?? widget.recipe['_id'];
      if (recipeId == null) {
        throw Exception('Recipe ID not found');
      }
      
      final response = await ApiService.deleteReply(
        recipeId: recipeId.toString(),
        commentId: commentId,
        replyId: replyId,
      );
      
      if (response['success'] == true && mounted) {
        await _loadComments(); // Reload comments
        
        DialogHelper.showSuccess(
          context,
          title: "Reply Deleted",
          message: "The reply has been removed.",
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to delete reply');
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showError(
          context,
          title: "Error",
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  // Delete nested reply
  Future<void> _deleteNestedReply(String commentId, String replyId, String nestedReplyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      final recipeId = widget.recipe['id'] ?? widget.recipe['_id'];
      if (recipeId == null) {
        throw Exception('Recipe ID not found');
      }
      
      final response = await ApiService.deleteNestedReply(
        recipeId: recipeId.toString(),
        commentId: commentId,
        replyId: replyId,
        nestedReplyId: nestedReplyId,
      );
      
      if (response['success'] == true && mounted) {
        await _loadComments(); // Reload comments
        
        DialogHelper.showSuccess(
          context,
          title: "Reply Deleted",
          message: "The reply has been removed.",
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to delete nested reply');
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showError(
          context,
          title: "Error",
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  // Unlimited nesting methods
  Future<void> _toggleUnlimitedReplyInput(String replyId) async {
    setState(() {
      _showUnlimitedReplyInput[replyId] = !(_showUnlimitedReplyInput[replyId] ?? false);
    });
    
    if (_showUnlimitedReplyInput[replyId] == true) {
      _unlimitedReplyControllers[replyId] = TextEditingController();
    } else {
      _unlimitedReplyControllers[replyId]?.dispose();
      _unlimitedReplyControllers.remove(replyId);
    }
  }

  Future<void> _submitUnlimitedReply(String commentId, String parentReplyId, List<String> parentReplyPath, String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _isSubmittingUnlimitedReply[parentReplyId] = true;
    });
    
    try {
      final recipeId = widget.recipe['id'] ?? widget.recipe['_id'];
      if (recipeId == null) {
        throw Exception('Recipe ID not found');
      }
      
      final response = await ApiService.addReplyToAny(
        recipeId: recipeId.toString(),
        commentId: commentId,
        parentReplyId: parentReplyId,
        parentReplyPath: parentReplyPath,
        text: text,
      );
      
      if (response['success'] == true && mounted) {
        final controller = _unlimitedReplyControllers[parentReplyId];
        if (controller != null) {
          controller.clear();
        }
        // Close unlimited reply input after submission (Facebook-style)
        setState(() {
          _showUnlimitedReplyInput[parentReplyId] = false;
        });
        await _loadComments(); // Reload comments
        // Success dialog removed for better UX
      } else {
        throw Exception(response['message'] ?? 'Failed to add unlimited reply');
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showError(
          context,
          title: "Error",
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingUnlimitedReply[parentReplyId] = false;
        });
      }
    }
  }

  Future<void> _deleteUnlimitedReply(String commentId, String replyId, List<String> replyPath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      final recipeId = widget.recipe['id'] ?? widget.recipe['_id'];
      if (recipeId == null) {
        throw Exception('Recipe ID not found');
      }
      
      final response = await ApiService.deleteAnyReply(
        recipeId: recipeId.toString(),
        commentId: commentId,
        replyId: replyId,
        replyPath: replyPath,
      );
      
      if (response['success'] == true && mounted) {
        await _loadComments(); // Reload comments
        
        DialogHelper.showSuccess(
          context,
          title: "Reply Deleted",
          message: "The reply has been removed.",
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to delete unlimited reply');
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showError(
          context,
          title: "Error",
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  // Helper method to build reply path for unlimited nesting
  List<String> _buildReplyPath(List<dynamic> replies, String targetReplyId, List<String> currentPath) {
    for (int i = 0; i < replies.length; i++) {
      final reply = replies[i];
      final replyId = reply['_id']?.toString();
      if (replyId == targetReplyId) {
        return [...currentPath, replyId];
      }
      
      if (reply['replies'] != null && reply['replies'].isNotEmpty) {
        final newPath = [...currentPath, replyId];
        final foundPath = _buildReplyPath(reply['replies'], targetReplyId, newPath);
        if (foundPath.isNotEmpty) {
          return foundPath;
        }
      }
    }
    return [];
  }

  // Helper method to count all replies recursively
  int _countAllReplies(List<dynamic> replies) {
    if (replies.isEmpty) return 0;
    
    int count = replies.length;
    for (final reply in replies) {
      if (reply['replies'] != null && reply['replies'].isNotEmpty) {
        count += _countAllReplies(reply['replies']);
      }
    }
    return count;
  }

  // Recursive widget to build unlimited nested replies
  Widget _buildUnlimitedReplies(List<dynamic> replies, String commentId, int depth) {
    if (replies.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: replies.map((reply) {
        final replyId = reply['_id']?.toString() ?? '';
        final replyText = reply['text'] ?? '';
        final replyUser = reply['user'];
        final replyUserName = replyUser?['name'] ?? 'Unknown User';
        final replyUserImage = replyUser?['profileImage'];
        final replyCreatedAt = reply['createdAt'];
        final replyReplies = reply['replies'] as List<dynamic>? ?? [];
        
        // Build path to this reply
        final replyPath = _buildReplyPath(_comments.firstWhere((c) => c['_id']?.toString() == commentId)['replies'] ?? [], replyId, []);
        
        return Container(
          margin: EdgeInsets.only(left: 16.0 + (depth * 16.0), top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reply content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: replyUserImage != null && replyUserImage.isNotEmpty
                        ? NetworkImage(_getFullImageUrl(replyUserImage) ?? '')
                        : null,
                    child: replyUserImage == null || replyUserImage.isEmpty
                        ? Text(replyUserName.isNotEmpty ? replyUserName[0].toUpperCase() : 'U')
                        : null,
                  ),
                  const SizedBox(width: 8),
                  // Reply content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                replyUserName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                replyText,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Reply actions
                        Row(
                          children: [
                            Text(
                              _formatTimeAgo(replyCreatedAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Reply button
                            GestureDetector(
                              onTap: () => _toggleUnlimitedReplyInput(replyId),
                              child: Text(
                                'Reply',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (replyReplies.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${_countAllReplies(replyReplies)} replies',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            // Delete button (only for own replies)
                            FutureBuilder<bool>(
                              future: _isOwnComment(replyUser?['_id']?.toString() ?? ''),
                              builder: (context, snapshot) {
                                final isOwn = snapshot.data ?? false;
                                if (!isOwn) return const SizedBox.shrink();
                                
                                return Row(
                                  children: [
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.more_horiz,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Long press to delete',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Reply input
              if (_showUnlimitedReplyInput[replyId] == true) ...[
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(left: 40),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _unlimitedReplyControllers[replyId],
                          decoration: const InputDecoration(
                            hintText: 'Write a reply...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSubmittingUnlimitedReply[replyId] == true
                            ? null
                            : () async {
                                final controller = _unlimitedReplyControllers[replyId];
                                if (controller != null) {
                                  await _submitUnlimitedReply(
                                    commentId,
                                    replyId,
                                    replyPath,
                                    controller.text,
                                  );
                                }
                              },
                        child: _isSubmittingUnlimitedReply[replyId] == true
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Reply'),
                      ),
                    ],
                  ),
                ),
              ],
              // Nested replies (recursive)
              if (replyReplies.isNotEmpty)
                _buildUnlimitedReplies(replyReplies, commentId, depth + 1),
            ],
          ),
        );
      }).toList(),
    );
  }

  String? _getFullImageUrl(dynamic image) {
    if (image == null || image.toString().isEmpty) return null;
    
    final imageStr = image.toString();
    
    // If it's already a full URL, return as is
    if (imageStr.startsWith('http://') || imageStr.startsWith('https://')) {
      return imageStr;
    }
    
    // Otherwise, construct full URL from base URL
    final baseUrl = ApiConfig.safeBaseUrl.replaceAll('/api', ''); // Remove /api suffix
    return '$baseUrl$imageStr'; // imageStr should start with /uploads/...
  }

  String _getCreatorInitial() {
    try {
      final creator = widget.recipe['creator'];
      if (creator == null) return 'E';
      
      // If creator is a string
      if (creator is String) {
        return creator.isNotEmpty ? creator[0].toUpperCase() : 'E';
      }
      
      // If creator is an object with name property
      if (creator is Map && creator['name'] != null) {
        final name = creator['name'].toString();
        return name.isNotEmpty ? name[0].toUpperCase() : 'E';
      }
      
      return 'E';
    } catch (e) {
      return 'E';
    }
  }

  String _getCreatorName() {
    try {
      final creator = widget.recipe['creator'];
      if (creator == null) return 'Unknown';
      
      // If creator is a string
      if (creator is String) {
        return creator;
      }
      
      // If creator is an object with name property
      if (creator is Map && creator['name'] != null) {
        return creator['name'].toString();
      }
      
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Calculate total comments count including replies
  int _getTotalCommentsCount() {
    int total = _comments.length;
    for (final comment in _comments) {
      final replies = comment['replies'] as List<dynamic>? ?? [];
      total += replies.length;
    }
    return total;
  }

  // Get current user ID
  Future<String?> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      return null;
    }
  }

  // Check if current user owns the comment
  Future<bool> _isOwnComment(String commentUserId) async {
    final currentUserId = await _getCurrentUserId();
    return currentUserId == commentUserId;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.black,
                  ),
                  onPressed: _toggleLike,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Recipe Image or Gradient Background
                  _getFullImageUrl(widget.recipe['image']) != null
                      ? Image.network(
                          _getFullImageUrl(widget.recipe['image'])!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade300, Colors.green.shade600],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.fastfood,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade300, Colors.green.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.fastfood,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recipe Title
                        Text(
                          widget.recipe['title'] ?? widget.recipe['name'] ?? 'Untitled Recipe',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Recipe Meta Info
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.recipe['type'] ?? 'Food',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 18, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              widget.recipe['time'] ?? '60 mins',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Chef Info and Likes
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.green.shade400,
                              child: Text(
                                _getCreatorInitial(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getCreatorName(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Text(
                                    'Recipe Creator',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.favorite, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_likesCount Likes',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Description Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.recipe['description'] ?? 
                          'A delicious and nutritious blend of cacao, maca, and walnuts in creamy coconut milk. This superfood drink is perfect for a healthy breakfast or post-workout treat. Rich in antioxidants and natural energy boosters.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Ingredients Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ingredients',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._ingredients.asMap().entries.map((entry) {
                          Map<String, dynamic> ingredient = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    ingredient['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Steps Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Steps',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._steps.asMap().entries.map((entry) {
                          int index = entry.key;
                          String step = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      step,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Comments Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Comments (${_getTotalCommentsCount()})',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (_isLoadingComments)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Comment input
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  maxLines: null,
                                  maxLength: 500,
                                  decoration: const InputDecoration(
                                    hintText: 'Add a comment...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(16),
                                    counterText: '',
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _isSubmittingComment ? null : _submitComment,
                                icon: _isSubmittingComment
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.green,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send,
                                        color: Colors.green,
                                      ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Comments list
                        if (_comments.isEmpty && !_isLoadingComments)
                          Container(
                            padding: const EdgeInsets.all(32),
                            child: const Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No comments yet',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Be the first to comment!',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._comments.map((comment) {
                            final user = comment['user'] as Map<String, dynamic>?;
                            final userName = user?['name'] ?? 'Unknown User';
                            final userImage = user?['profileImage'];
                            final commentText = comment['text'] ?? '';
                            final createdAt = comment['createdAt'];
                            final commentId = comment['_id'];
                            final replies = comment['replies'] as List<dynamic>? ?? [];
                            
                            // Format date
                            String formattedDate = 'Just now';
                            if (createdAt != null) {
                              try {
                                final date = DateTime.parse(createdAt.toString());
                                final now = DateTime.now();
                                final difference = now.difference(date);
                                
                                if (difference.inDays > 0) {
                                  formattedDate = '${difference.inDays}d ago';
                                } else if (difference.inHours > 0) {
                                  formattedDate = '${difference.inHours}h ago';
                                } else if (difference.inMinutes > 0) {
                                  formattedDate = '${difference.inMinutes}m ago';
                                }
                              } catch (e) {
                                // Keep default "Just now"
                              }
                            }
                            
                            return FutureBuilder<bool>(
                              future: _isOwnComment(user?['_id']?.toString() ?? ''),
                              builder: (context, snapshot) {
                                final isOwnComment = snapshot.data ?? false;
                                
                                return GestureDetector(
                                  onLongPress: isOwnComment && commentId != null
                                      ? () {
                                          HapticFeedback.mediumImpact();
                                          _deleteComment(commentId.toString());
                                        }
                                      : null,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Main comment
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Colors.green.shade100,
                                              backgroundImage: userImage != null
                                                  ? NetworkImage(_getFullImageUrl(userImage)!)
                                                  : null,
                                              child: userImage == null
                                                  ? Text(
                                                      userName[0].toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.green,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    userName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    formattedDate,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Show delete hint for own comments
                                            if (isOwnComment && commentId != null)
                                              Icon(
                                                Icons.more_horiz,
                                                color: Colors.grey.shade400,
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                  const SizedBox(height: 8),
                                  Text(
                                    commentText,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                  
                                  // Reply button and delete hint
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _toggleReplyInput(commentId.toString()),
                                        icon: const Icon(Icons.reply, size: 16, color: Colors.green),
                                        label: Text(
                                          'Reply${replies.isNotEmpty ? ' (${replies.length})' : ''}',
                                          style: TextStyle(
                                            color: Colors.green.shade600,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (isOwnComment && commentId != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '• Long press to delete',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  
                                  // Reply input
                                  if (_showReplyInput[commentId.toString()] == true) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _replyControllers[commentId.toString()],
                                              decoration: const InputDecoration(
                                                hintText: 'Write a reply...',
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                                                counterText: '',
                                              ),
                                              maxLength: 500,
                                              maxLines: null,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: _isSubmittingReply[commentId.toString()] == true 
                                                ? null 
                                                : () => _submitReply(commentId.toString()),
                                            icon: _isSubmittingReply[commentId.toString()] == true
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.green,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.send,
                                                    color: Colors.green,
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  // Replies
                                  if (replies.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      margin: const EdgeInsets.only(left: 32),
                                      child: Column(
                                        children: replies.map((reply) {
                                          final replyUser = reply['user'] as Map<String, dynamic>?;
                                          final replyUserName = replyUser?['name'] ?? 'Unknown User';
                                          final replyUserImage = replyUser?['profileImage'];
                                          final replyText = reply['text'] ?? '';
                                          final replyCreatedAt = reply['createdAt'];
                                          final replyId = reply['_id'];
                                          
                                          // Format reply date
                                          String replyFormattedDate = 'Just now';
                                          if (replyCreatedAt != null) {
                                            try {
                                              final date = DateTime.parse(replyCreatedAt.toString());
                                              final now = DateTime.now();
                                              final difference = now.difference(date);
                                              
                                              if (difference.inDays > 0) {
                                                replyFormattedDate = '${difference.inDays}d ago';
                                              } else if (difference.inHours > 0) {
                                                replyFormattedDate = '${difference.inHours}h ago';
                                              } else if (difference.inMinutes > 0) {
                                                replyFormattedDate = '${difference.inMinutes}m ago';
                                              }
                                            } catch (e) {
                                              // Keep default "Just now"
                                            }
                                          }
                                          
                                          return FutureBuilder<bool>(
                                            future: _isOwnComment(replyUser?['_id']?.toString() ?? ''),
                                            builder: (context, replySnapshot) {
                                              final isOwnReply = replySnapshot.data ?? false;
                                              
                                              return GestureDetector(
                                                onLongPress: isOwnReply && replyId != null
                                                    ? () {
                                                        HapticFeedback.mediumImpact();
                                                        _deleteReply(commentId.toString(), replyId.toString());
                                                      }
                                                    : null,
                                                child: Container(
                                                  margin: const EdgeInsets.only(bottom: 12),
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade50,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.grey.shade200),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 16,
                                                            backgroundColor: Colors.green.shade100,
                                                            backgroundImage: replyUserImage != null
                                                                ? NetworkImage(_getFullImageUrl(replyUserImage)!)
                                                                : null,
                                                            child: replyUserImage == null
                                                                ? Text(
                                                                    replyUserName[0].toUpperCase(),
                                                                    style: const TextStyle(
                                                                      color: Colors.green,
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 12,
                                                                    ),
                                                                  )
                                                                : null,
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  replyUserName,
                                                                  style: const TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 12,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  replyFormattedDate,
                                                                  style: TextStyle(
                                                                    color: Colors.grey.shade600,
                                                                    fontSize: 10,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          // Show delete hint for own replies
                                                          if (isOwnReply && replyId != null)
                                                            Icon(
                                                              Icons.more_horiz,
                                                              color: Colors.grey.shade400,
                                                              size: 16,
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        replyText,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.black87,
                                                          height: 1.3,
                                                        ),
                                                      ),
                                                      
                                                      // Reply button for nested replies
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          TextButton.icon(
                                                            onPressed: () => _toggleNestedReplyInput(replyId.toString()),
                                                            icon: const Icon(Icons.reply, size: 14, color: Colors.green),
                                                            label: Text(
                                                              'Reply${reply['replies'] != null && (reply['replies'] as List).isNotEmpty ? ' (${(reply['replies'] as List).length})' : ''}',
                                                              style: TextStyle(
                                                                color: Colors.green.shade600,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ),
                                                          if (isOwnReply && replyId != null) ...[
                                                            const SizedBox(width: 8),
                                                            Text(
                                                              '• Long press to delete',
                                                              style: TextStyle(
                                                                color: Colors.grey.shade500,
                                                                fontSize: 9,
                                                                fontStyle: FontStyle.italic,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      
                                                      // Nested reply input
                                                      if (_showNestedReplyInput[replyId.toString()] == true) ...[
                                                        const SizedBox(height: 8),
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey.shade100,
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(color: Colors.grey.shade300),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                child: TextField(
                                                                  controller: _nestedReplyControllers[replyId.toString()],
                                                                  decoration: const InputDecoration(
                                                                    hintText: 'Write a reply...',
                                                                    border: InputBorder.none,
                                                                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                                                                    counterText: '',
                                                                  ),
                                                                  maxLength: 500,
                                                                  maxLines: null,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 6),
                                                              IconButton(
                                                                onPressed: _isSubmittingNestedReply[replyId.toString()] == true 
                                                                    ? null 
                                                                    : () => _submitNestedReply(commentId.toString(), replyId.toString()),
                                                                icon: _isSubmittingNestedReply[replyId.toString()] == true
                                                                    ? const SizedBox(
                                                                        width: 16,
                                                                        height: 16,
                                                                        child: CircularProgressIndicator(
                                                                          strokeWidth: 2,
                                                                          color: Colors.green,
                                                                        ),
                                                                      )
                                                                    : const Icon(
                                                                        Icons.send,
                                                                        color: Colors.green,
                                                                        size: 18,
                                                                      ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                      
                                                      // Display unlimited nested replies
                                                      if (reply['replies'] != null && (reply['replies'] as List).isNotEmpty) ...[
                                                        const SizedBox(height: 8),
                                                        _buildUnlimitedReplies(reply['replies'], commentId.toString(), 1),
                                                      ],
                                                                    onLongPress: isOwnNestedReply && nestedReplyId != null
                                                                        ? () {
                                                                            HapticFeedback.mediumImpact();
                                                                            _deleteNestedReply(commentId.toString(), replyId.toString(), nestedReplyId.toString());
                                                                          }
                                                                        : null,
                                                                    child: Container(
                                                                      margin: const EdgeInsets.only(bottom: 8),
                                                                      padding: const EdgeInsets.all(8),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.grey.shade100,
                                                                        borderRadius: BorderRadius.circular(6),
                                                                        border: Border.all(color: Colors.grey.shade300),
                                                                      ),
                                                                      child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              CircleAvatar(
                                                                                radius: 12,
                                                                                backgroundColor: Colors.green.shade100,
                                                                                backgroundImage: nestedReplyUserImage != null
                                                                                    ? NetworkImage(_getFullImageUrl(nestedReplyUserImage)!)
                                                                                    : null,
                                                                                child: nestedReplyUserImage == null
                                                                                    ? Text(
                                                                                        nestedReplyUserName[0].toUpperCase(),
                                                                                        style: const TextStyle(
                                                                                          color: Colors.green,
                                                                                          fontWeight: FontWeight.bold,
                                                                                          fontSize: 10,
                                                                                        ),
                                                                                      )
                                                                                    : null,
                                                                              ),
                                                                              const SizedBox(width: 6),
                                                                              Expanded(
                                                                                child: Column(
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Text(
                                                                                      nestedReplyUserName,
                                                                                      style: const TextStyle(
                                                                                        fontWeight: FontWeight.bold,
                                                                                        fontSize: 11,
                                                                                      ),
                                                                                    ),
                                                                                    Text(
                                                                                      nestedReplyFormattedDate,
                                                                                      style: TextStyle(
                                                                                        color: Colors.grey.shade600,
                                                                                        fontSize: 9,
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                              // Show delete hint for own nested replies
                                                                              if (isOwnNestedReply && nestedReplyId != null)
                                                                                Icon(
                                                                                  Icons.more_horiz,
                                                                                  color: Colors.grey.shade400,
                                                                                  size: 14,
                                                                                ),
                                                                            ],
                                                                          ),
                                                                          const SizedBox(height: 4),
                                                                          Text(
                                                                            nestedReplyText,
                                                                            style: const TextStyle(
                                                                              fontSize: 12,
                                                                              color: Colors.black87,
                                                                              height: 1.2,
                                                                            ),
                                                                          ),
                                                                          if (isOwnNestedReply && nestedReplyId != null) ...[
                                                                            const SizedBox(height: 2),
                                                                            Text(
                                                                              'Long press to delete',
                                                                              style: TextStyle(
                                                                                color: Colors.grey.shade500,
                                                                                fontSize: 8,
                                                                                fontStyle: FontStyle.italic,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              );
                                                            }).toList(),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                                ),
                              );
                            },
                          );
                          }).toList(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 120), // Account for bottom nav and action bar
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoadingBookmark ? null : _toggleBookmark,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _isBookmarked ? Colors.green : Colors.grey),
                  backgroundColor: _isBookmarked ? Colors.green.withOpacity(0.1) : null,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoadingBookmark
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.green,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isBookmarked ? 'Saved' : 'Save',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _showRatingDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Rate',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
}