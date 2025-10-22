const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Recipe = require('../models/Recipe');
const Notification = require('../models/Notification');
const { auth } = require('../middleware/auth');

const router = express.Router();

// @route   POST /api/social/follow/:id
// @desc    Follow/unfollow user
// @access  Private
router.post('/follow/:id', auth, async (req, res) => {
  try {
    const targetUserId = req.params.id;
    const currentUserId = req.user._id;

    if (targetUserId === currentUserId.toString()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot follow yourself'
      });
    }

    const targetUser = await User.findById(targetUserId);
    const currentUser = await User.findById(currentUserId);

    if (!targetUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const isFollowing = currentUser.following.includes(targetUserId);

    if (isFollowing) {
      // Unfollow
      currentUser.following.pull(targetUserId);
      targetUser.followers.pull(currentUserId);
    } else {
      // Follow
      currentUser.following.push(targetUserId);
      targetUser.followers.push(currentUserId);

      // Send notification
      const NotificationService = require('../services/notificationService');
      const io = req.app.get('io');
      await NotificationService.sendFollowNotification(targetUser, currentUser, io);
    }

    await currentUser.save();
    await targetUser.save();

    res.json({
      success: true,
      message: isFollowing ? 'Unfollowed successfully' : 'Followed successfully',
      isFollowing: !isFollowing,
      followersCount: targetUser.followers.length,
      followingCount: currentUser.following.length
    });
  } catch (error) {
    console.error('Follow/unfollow error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/social/followers/:id
// @desc    Get user's followers
// @access  Public
router.get('/followers/:id', async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const user = await User.findById(req.params.id)
      .populate({
        path: 'followers',
        select: 'name profileImage bio stats followers following',
        options: {
          skip: skip,
          limit: parseInt(limit),
          sort: { createdAt: -1 }
        }
      });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const total = user.followers.length;

    res.json({
      success: true,
      followers: user.followers,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get followers error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/social/following/:id
// @desc    Get user's following
// @access  Public
router.get('/following/:id', async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const user = await User.findById(req.params.id)
      .populate({
        path: 'following',
        select: 'name profileImage bio stats followers following',
        options: {
          skip: skip,
          limit: parseInt(limit),
          sort: { createdAt: -1 }
        }
      });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const total = user.following.length;

    res.json({
      success: true,
      following: user.following,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get following error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/social/feed
// @desc    Get user's social feed (recipes from all users with smart ranking)
// @access  Private
router.get('/feed', auth, async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;

    const user = await User.findById(req.user._id);
    const followingIds = user.following;
    const userId = req.user._id;

    // Get recipes from all users (excluding current user's own recipes)
    const allRecipes = await Recipe.find({
      creator: { $ne: userId }, // Exclude current user's recipes
      isPublished: true
    })
      .populate('creator', 'name profileImage')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit) * 3); // Get more recipes for better ranking

    // Apply smart ranking algorithm
    const rankedRecipes = allRecipes.map(recipe => {
      let score = 0;
      const recipeData = recipe.toObject();
      
      
      // Base score from creation time (newer = higher score)
      const hoursSinceCreation = (Date.now() - new Date(recipe.createdAt).getTime()) / (1000 * 60 * 60);
      score += Math.max(0, 100 - hoursSinceCreation); // Decay over time
      
      // Boost for followed users (like Facebook prioritizes friends)
      if (recipe.creator && recipe.creator._id && followingIds.some(id => id.toString() === recipe.creator._id.toString())) {
        score += 50; // Significant boost for followed users
      }
      
      // Boost for engagement (likes, bookmarks)
      score += recipe.likes.length * 2; // 2 points per like
      score += recipe.bookmarks.length * 3; // 3 points per bookmark
      
      // Boost for recent engagement
      const recentLikes = recipe.likes.filter(likeId => {
        // This would need to be enhanced with actual like timestamps
        return true; // For now, treat all likes as recent
      });
      score += recentLikes.length * 1;
      
      // Boost for popular categories (if user has preferences)
      // This could be enhanced with user preference tracking
      
      // Small random factor to add variety
      score += Math.random() * 5;
      
      recipeData._rankingScore = score;
      return recipeData;
    });

    // Sort by ranking score (highest first)
    rankedRecipes.sort((a, b) => b._rankingScore - a._rankingScore);

    // Apply pagination
    const paginatedRecipes = rankedRecipes.slice(skip, skip + parseInt(limit));

    // Add user interaction data
    paginatedRecipes.forEach(recipe => {
      // Convert userId to string for comparison
      const userIdStr = userId.toString();
      
      // Check if user has liked this recipe
      recipe.isLiked = recipe.likes.some(likeId => likeId.toString() === userIdStr);
      recipe.isBookmarked = recipe.bookmarks.some(bookmarkId => bookmarkId.toString() === userIdStr);
      recipe.likesCount = recipe.likes.length; // Add likes count
      
      recipe.isFromFollowedUser = recipe.creator && followingIds.some(id => id.toString() === recipe.creator._id.toString());
      
      // Remove the ranking score from final response
      delete recipe._rankingScore;
    });

    // Get total count for pagination
    const total = await Recipe.countDocuments({
      creator: { $ne: userId },
      isPublished: true
    });

    res.json({
      success: true,
      recipes: paginatedRecipes,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      },
      feedInfo: {
        totalRecipes: total,
        followedUsersCount: followingIds.length,
        algorithm: 'smart_ranking'
      }
    });
  } catch (error) {
    console.error('Get social feed error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/social/discover
// @desc    Discover new users to follow
// @access  Private
router.get('/discover', auth, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const currentUser = await User.findById(req.user._id);
    const followingIds = [...currentUser.following, req.user._id];

    // Find users not currently followed, sorted by activity/popularity
    const users = await User.find({
      _id: { $nin: followingIds },
      isActive: true
    })
      .select('name profileImage bio stats followers following')
      .sort({ 
        'stats.totalLikes': -1,
        'stats.recipesCreated': -1
      })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await User.countDocuments({
      _id: { $nin: followingIds },
      isActive: true
    });

    res.json({
      success: true,
      users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Discover users error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/social/trending
// @desc    Get trending recipes
// @access  Public
router.get('/trending', async (req, res) => {
  try {
    const { page = 1, limit = 10, timeframe = 'week' } = req.query;
    const skip = (page - 1) * limit;

    // Calculate date range for trending
    const now = new Date();
    let dateFilter;
    
    switch (timeframe) {
      case 'day':
        dateFilter = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        break;
      case 'week':
        dateFilter = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case 'month':
        dateFilter = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        break;
      default:
        dateFilter = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    }

    const recipes = await Recipe.find({
      isPublished: true,
      createdAt: { $gte: dateFilter }
    })
      .populate('creator', 'name profileImage')
      .sort({
        likesCount: -1,
        views: -1,
        averageRating: -1
      })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Recipe.countDocuments({
      isPublished: true,
      createdAt: { $gte: dateFilter }
    });

    res.json({
      success: true,
      recipes,
      timeframe,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get trending recipes error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/social/share/:recipeId
// @desc    Share recipe
// @access  Private
router.post('/share/:recipeId', auth, [
  body('platform')
    .optional()
    .isIn(['facebook', 'twitter', 'instagram', 'whatsapp', 'email'])
    .withMessage('Invalid sharing platform'),
  body('message')
    .optional()
    .trim()
    .isLength({ max: 280 })
    .withMessage('Message must be less than 280 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const recipe = await Recipe.findById(req.params.recipeId)
      .populate('creator', 'name profileImage');

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    const { platform, message } = req.body;

    // Generate share URL
    const shareUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/recipe/${recipe._id}`;
    
    // Create share content
    const shareContent = {
      title: recipe.title,
      description: recipe.description,
      url: shareUrl,
      image: recipe.images[0] || null,
      message: message || `Check out this amazing recipe: ${recipe.title}`
    };

    // Track share (you might want to add a shares field to Recipe model)
    recipe.views += 1; // Increment views as a proxy for engagement
    await recipe.save();

    // Send notification to recipe creator if not sharing own recipe
    if (recipe.creator._id.toString() !== req.user._id.toString()) {
      const NotificationService = require('../services/notificationService');
      const io = req.app.get('io');
      await NotificationService.sendShareNotification(recipe, req.user, platform || 'general', io);
    }

    res.json({
      success: true,
      message: 'Recipe shared successfully',
      shareContent,
      platform: platform || 'general'
    });
  } catch (error) {
    console.error('Share recipe error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/social/activity/:id
// @desc    Get user's recent activity
// @access  Public
router.get('/activity/:id', async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    // Get recent recipes, likes, and follows
    const recentRecipes = await Recipe.find({
      creator: req.params.id,
      isPublished: true
    })
      .select('title images createdAt')
      .sort({ createdAt: -1 })
      .limit(5);

    // You might want to create an Activity model to track all user activities
    // For now, we'll just return recent recipes
    const activities = recentRecipes.map(recipe => ({
      type: 'recipe_created',
      data: recipe,
      createdAt: recipe.createdAt
    }));

    res.json({
      success: true,
      activities,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: activities.length,
        pages: Math.ceil(activities.length / limit)
      }
    });
  } catch (error) {
    console.error('Get user activity error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
