const express = require('express');
const { body, validationResult } = require('express-validator');
const Recipe = require('../models/Recipe');
const User = require('../models/User');
const { auth, optionalAuth } = require('../middleware/auth');
const upload = require('../middleware/upload');

const router = express.Router();

// @route   GET /api/recipes
// @desc    Get all recipes with filters
// @access  Public
router.get('/', optionalAuth, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      category,
      difficulty,
      cuisine,
      search,
      sort = 'createdAt',
      order = 'desc',
      featured,
      creator
    } = req.query;

    const skip = (page - 1) * limit;
    const query = { isPublished: true };

    // Apply filters
    if (category) query.category = category;
    if (difficulty) query.difficulty = difficulty;
    if (cuisine) query.cuisine = cuisine;
    if (featured === 'true') query.isFeatured = true;
    if (creator) query.creator = creator;

    // Search functionality
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { tags: { $in: [new RegExp(search, 'i')] } }
      ];
    }

    // Sort options
    const sortObj = {};
    sortObj[sort] = order === 'desc' ? -1 : 1;

    const recipes = await Recipe.find(query)
      .populate('creator', 'name profileImage')
      .sort(sortObj)
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Recipe.countDocuments(query);

    // Add user interaction data if authenticated
    if (req.user) {
      recipes.forEach(recipe => {
        recipe._doc.isLiked = recipe.likes.includes(req.user._id);
        recipe._doc.isBookmarked = recipe.bookmarks.includes(req.user._id);
      });
    }

    res.json({
      success: true,
      recipes,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get recipes error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/recipes/:id
// @desc    Get recipe by ID
// @access  Public
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id)
      .populate('creator', 'name profileImage bio')
      .populate('ratings.user', 'name profileImage');

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    // Debug: Check authentication status
    console.log(`🔍 Recipe ${recipe._id} access - req.user:`, req.user ? `User ID: ${req.user._id}` : 'No user (anonymous)');
    
    // Increment view count only if user hasn't viewed this recipe before
    if (req.user) {
      // Check if user has already viewed this recipe (compare as strings)
      const userId = req.user._id.toString();
      const hasViewed = recipe.viewedBy && recipe.viewedBy.some(viewerId => viewerId.toString() === userId);
      
      console.log(`🔍 User ${userId} - hasViewed: ${hasViewed}, viewedBy array:`, recipe.viewedBy?.map(id => id.toString()) || 'empty');
      
      if (!hasViewed) {
        recipe.views += 1;
        if (!recipe.viewedBy) {
          recipe.viewedBy = [];
        }
        recipe.viewedBy.push(req.user._id);
        await recipe.save();
        console.log(`✅ View tracked for user ${userId} on recipe ${recipe._id}. Total views: ${recipe.views}`);
        
        // Verify the save was successful
        const savedRecipe = await Recipe.findById(recipe._id);
        console.log(`🔍 Verification - Saved recipe views: ${savedRecipe.views}, viewedBy length: ${savedRecipe.viewedBy.length}`);
      } else {
        console.log(`⏭️ User ${userId} already viewed recipe ${recipe._id}. No view increment.`);
      }
    } else {
      // For anonymous users, always increment (no way to track duplicates)
      recipe.views += 1;
      await recipe.save();
      console.log(`👤 Anonymous view tracked for recipe ${recipe._id}. Total views: ${recipe.views}`);
    }

    // Add user interaction data if authenticated
    if (req.user) {
      recipe._doc.isLiked = recipe.likes.includes(req.user._id);
      recipe._doc.isBookmarked = recipe.bookmarks.includes(req.user._id);
      recipe._doc.userRating = recipe.ratings.find(r => r.user._id.toString() === req.user._id.toString())?.rating || null;
    }

    res.json({
      success: true,
      recipe
    });
  } catch (error) {
    console.error('Get recipe error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/recipes
// @desc    Create new recipe
// @access  Private
router.post('/', auth, upload.diskUpload.array('recipeImages', 5), [
  body('title')
    .trim()
    .isLength({ min: 3, max: 100 })
    .withMessage('Title must be between 3 and 100 characters'),
  body('description')
    .trim()
    .isLength({ min: 10, max: 500 })
    .withMessage('Description must be between 10 and 500 characters'),
  body('category')
    .isIn(['appetizer', 'main_course', 'dessert', 'beverage', 'snack', 'soup', 'salad', 'breakfast', 'lunch', 'dinner'])
    .withMessage('Invalid category'),
  body('difficulty')
    .isIn(['easy', 'medium', 'hard'])
    .withMessage('Invalid difficulty level'),
  body('prepTime')
    .isInt({ min: 1 })
    .withMessage('Prep time must be a positive integer'),
  body('cookTime')
    .isInt({ min: 1 })
    .withMessage('Cook time must be a positive integer'),
  body('servings')
    .isInt({ min: 1 })
    .withMessage('Servings must be a positive integer')
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

    const {
      title,
      description,
      category,
      cuisine,
      difficulty,
      prepTime,
      cookTime,
      servings,
      ingredients,
      instructions,
      nutrition,
      tags,
      spiceLevel,
      dietaryInfo
    } = req.body;

    // Process uploaded images
    const images = req.files ? req.files.map(file => `/uploads/recipes/${file.filename}`) : [];

    const recipe = new Recipe({
      title,
      description,
      creator: req.user._id,
      images,
      category,
      cuisine: cuisine || 'Filipino',
      difficulty,
      prepTime: parseInt(prepTime),
      cookTime: parseInt(cookTime),
      servings: parseInt(servings),
      ingredients: JSON.parse(ingredients || '[]'),
      instructions: JSON.parse(instructions || '[]'),
      nutrition: JSON.parse(nutrition || '{}'),
      tags: JSON.parse(tags || '[]'),
      spiceLevel,
      dietaryInfo: JSON.parse(dietaryInfo || '{}')
    });

    await recipe.save();

    // Update user stats
    await User.findByIdAndUpdate(req.user._id, {
      $inc: { 'stats.recipesCreated': 1 }
    });

    const populatedRecipe = await Recipe.findById(recipe._id)
      .populate('creator', 'name profileImage');

    res.status(201).json({
      success: true,
      message: 'Recipe created successfully',
      recipe: populatedRecipe
    });
  } catch (error) {
    console.error('Create recipe error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   PUT /api/recipes/:id
// @desc    Update recipe
// @access  Private
router.put('/:id', auth, upload.diskUpload.array('recipeImages', 5), async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    // Check if user owns the recipe
    if (recipe.creator.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this recipe'
      });
    }

    const updateData = { ...req.body };

    // Process new images if uploaded
    if (req.files && req.files.length > 0) {
      const newImages = req.files.map(file => `/uploads/recipes/${file.filename}`);
      updateData.images = [...(recipe.images || []), ...newImages];
    }

    // Parse JSON fields
    if (updateData.ingredients) updateData.ingredients = JSON.parse(updateData.ingredients);
    if (updateData.instructions) updateData.instructions = JSON.parse(updateData.instructions);
    if (updateData.nutrition) updateData.nutrition = JSON.parse(updateData.nutrition);
    if (updateData.tags) updateData.tags = JSON.parse(updateData.tags);
    if (updateData.dietaryInfo) updateData.dietaryInfo = JSON.parse(updateData.dietaryInfo);

    const updatedRecipe = await Recipe.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).populate('creator', 'name profileImage');

    res.json({
      success: true,
      message: 'Recipe updated successfully',
      recipe: updatedRecipe
    });
  } catch (error) {
    console.error('Update recipe error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   DELETE /api/recipes/:id
// @desc    Delete recipe
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    // Check if user owns the recipe
    if (recipe.creator.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this recipe'
      });
    }

    await Recipe.findByIdAndDelete(req.params.id);

    // Update user stats
    await User.findByIdAndUpdate(req.user._id, {
      $inc: { 'stats.recipesCreated': -1 }
    });

    res.json({
      success: true,
      message: 'Recipe deleted successfully'
    });
  } catch (error) {
    console.error('Delete recipe error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/recipes/:id/like
// @desc    Like/unlike recipe
// @access  Private
router.post('/:id/like', auth, async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    const userId = req.user._id;
    const isLiked = recipe.likes.includes(userId);

    // Track view when user likes (if they haven't viewed before)
    const userIdStr = userId.toString();
    const hasViewed = recipe.viewedBy && recipe.viewedBy.some(viewerId => viewerId.toString() === userIdStr);
    if (!hasViewed) {
      recipe.views += 1;
      if (!recipe.viewedBy) {
        recipe.viewedBy = [];
      }
      recipe.viewedBy.push(userId);
      console.log(`View tracked via like for user ${userIdStr} on recipe ${recipe._id}. Total views: ${recipe.views}`);
    }

    if (isLiked) {
      // Unlike
      recipe.likes.pull(userId);
      await User.findByIdAndUpdate(userId, {
        $pull: { likedRecipes: recipe._id }
      });
    } else {
      // Like
      recipe.likes.push(userId);
      await User.findByIdAndUpdate(userId, {
        $addToSet: { likedRecipes: recipe._id }
      });

      // Send notification to recipe creator
      if (recipe.creator.toString() !== userId.toString()) {
        const NotificationService = require('../services/notificationService');
        const io = req.app.get('io');
        await NotificationService.sendLikeNotification(recipe, req.user, io);
      }
    }

    await recipe.save();

    res.json({
      success: true,
      message: isLiked ? 'Recipe unliked' : 'Recipe liked',
      isLiked: !isLiked,
      likesCount: recipe.likes.length
    });
  } catch (error) {
    console.error('Like recipe error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/recipes/:id/bookmark
// @desc    Bookmark/unbookmark recipe
// @access  Private
router.post('/:id/bookmark', auth, async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    const userId = req.user._id;
    const isBookmarked = recipe.bookmarks.includes(userId);

    // Track view when user bookmarks (if they haven't viewed before)
    const userIdStr = userId.toString();
    const hasViewed = recipe.viewedBy && recipe.viewedBy.some(viewerId => viewerId.toString() === userIdStr);
    if (!hasViewed) {
      recipe.views += 1;
      if (!recipe.viewedBy) {
        recipe.viewedBy = [];
      }
      recipe.viewedBy.push(userId);
      console.log(`View tracked via bookmark for user ${userIdStr} on recipe ${recipe._id}. Total views: ${recipe.views}`);
    }

    if (isBookmarked) {
      // Remove bookmark
      recipe.bookmarks.pull(userId);
      await User.findByIdAndUpdate(userId, {
        $pull: { bookmarkedRecipes: recipe._id }
      });
    } else {
      // Add bookmark
      recipe.bookmarks.push(userId);
      await User.findByIdAndUpdate(userId, {
        $addToSet: { bookmarkedRecipes: recipe._id }
      });

      // Send notification to recipe creator
      if (recipe.creator.toString() !== userId.toString()) {
        const NotificationService = require('../services/notificationService');
        const io = req.app.get('io');
        await NotificationService.sendBookmarkNotification(recipe, req.user, io);
      }
    }

    await recipe.save();

    res.json({
      success: true,
      message: isBookmarked ? 'Bookmark removed' : 'Recipe bookmarked',
      isBookmarked: !isBookmarked,
      bookmarksCount: recipe.bookmarks.length
    });
  } catch (error) {
    console.error('Bookmark recipe error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/recipes/:id/rate
// @desc    Rate recipe
// @access  Private
router.post('/:id/rate', auth, [
  body('rating')
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5'),
  body('review')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Review must be less than 500 characters')
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

    const { rating, review } = req.body;
    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    // Track view when user rates (if they haven't viewed before)
    const userIdStr = req.user._id.toString();
    const hasViewed = recipe.viewedBy && recipe.viewedBy.some(viewerId => viewerId.toString() === userIdStr);
    if (!hasViewed) {
      recipe.views += 1;
      if (!recipe.viewedBy) {
        recipe.viewedBy = [];
      }
      recipe.viewedBy.push(req.user._id);
      console.log(`View tracked via rating for user ${userIdStr} on recipe ${recipe._id}. Total views: ${recipe.views}`);
    }

    // Check if user already rated this recipe
    const existingRatingIndex = recipe.ratings.findIndex(
      r => r.user.toString() === req.user._id.toString()
    );

    if (existingRatingIndex !== -1) {
      // Update existing rating
      recipe.ratings[existingRatingIndex].rating = rating;
      recipe.ratings[existingRatingIndex].review = review;
    } else {
      // Add new rating
      recipe.ratings.push({
        user: req.user._id,
        rating,
        review
      });
    }

    await recipe.save();

    const populatedRecipe = await Recipe.findById(recipe._id)
      .populate('ratings.user', 'name profileImage');

    // Send notification to recipe creator (if not rating own recipe)
    if (recipe.creator.toString() !== req.user._id.toString()) {
      const NotificationService = require('../services/notificationService');
      const io = req.app.get('io');
      await NotificationService.sendRatingNotification(recipe, req.user, rating, review, io);
    }

    res.json({
      success: true,
      message: 'Rating submitted successfully',
      averageRating: populatedRecipe.averageRating,
      ratingsCount: populatedRecipe.ratings.length
    });
  } catch (error) {
    console.error('Rate recipe error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/recipes/:id/comment
// @desc    Add comment to recipe
// @access  Private
router.post('/:id/comment', auth, [
  body('text')
    .trim()
    .notEmpty()
    .withMessage('Comment text is required')
    .isLength({ max: 500 })
    .withMessage('Comment must be less than 500 characters')
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

    const { text } = req.body;
    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    // Track view when user comments (if they haven't viewed before)
    const userIdStr = req.user._id.toString();
    const hasViewed = recipe.viewedBy && recipe.viewedBy.some(viewerId => viewerId.toString() === userIdStr);
    if (!hasViewed) {
      recipe.views += 1;
      if (!recipe.viewedBy) {
        recipe.viewedBy = [];
      }
      recipe.viewedBy.push(req.user._id);
      console.log(`View tracked via comment for user ${userIdStr} on recipe ${recipe._id}. Total views: ${recipe.views}`);
    }

    // Add new comment
    recipe.comments.push({
      user: req.user._id,
      text,
      createdAt: new Date()
    });

    await recipe.save();

    // Populate the comments with user data
    const populatedRecipe = await Recipe.findById(recipe._id)
      .populate('comments.user', 'name profileImage');

    // Send notification to recipe creator (if not commenting on own recipe)
    if (recipe.creator.toString() !== req.user._id.toString()) {
      const NotificationService = require('../services/notificationService');
      const io = req.app.get('io');
      await NotificationService.sendCommentNotification(recipe, req.user, text, io);
    }

    res.json({
      success: true,
      message: 'Comment added successfully',
      comments: populatedRecipe.comments,
      commentsCount: populatedRecipe.comments.length
    });
  } catch (error) {
    console.error('Add comment error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/recipes/:id/comments
// @desc    Get recipe comments
// @access  Public
router.get('/:id/comments', async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const recipe = await Recipe.findById(req.params.id)
      .populate({
        path: 'comments.user',
        select: 'name profileImage'
      })
      .populate({
        path: 'comments.replies.user',
        select: 'name profileImage'
      })
      .populate({
        path: 'comments.replies.replies.user',
        select: 'name profileImage'
      });

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    // Sort comments by newest first and paginate
    const allComments = recipe.comments.sort((a, b) => b.createdAt - a.createdAt);
    const paginatedComments = allComments.slice(skip, skip + parseInt(limit));
    const total = allComments.length;

    res.json({
      success: true,
      comments: paginatedComments,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get comments error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/recipes/:id/comments/:commentId/reply
// @desc    Reply to a comment
// @access  Private
router.post('/:id/comments/:commentId/reply', auth, [
  body('text')
    .trim()
    .isLength({ min: 1, max: 500 })
    .withMessage('Reply must be between 1 and 500 characters')
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

    const { text } = req.body;
    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    // Find the comment to reply to
    const comment = recipe.comments.id(req.params.commentId);
    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found'
      });
    }

    // Add reply to the comment
    comment.replies.push({
      user: req.user._id,
      text: text
    });

    await recipe.save();

    // Populate the comment with user data
    const populatedRecipe = await Recipe.findById(recipe._id)
      .populate('comments.replies.user', 'name profileImage');

    const updatedComment = populatedRecipe.comments.id(req.params.commentId);

    // Send notification to the original commenter (if not replying to own comment)
    if (comment.user.toString() !== req.user._id.toString()) {
      const NotificationService = require('../services/notificationService');
      const io = req.app.get('io');
      
      // Get the original commenter's user data
      const User = require('../models/User');
      const originalCommenter = await User.findById(comment.user);
      
      if (originalCommenter) {
        await NotificationService.sendNotification({
          recipientId: originalCommenter._id,
          senderId: req.user._id,
          type: 'comment',
          title: 'Reply to Your Comment',
          message: `${req.user.name} replied to your comment on "${recipe.title}"`,
          data: {
            recipeId: recipe._id,
            commentId: comment._id,
            replyText: text
          },
          io
        });
      }
    }

    res.json({
      success: true,
      message: 'Reply added successfully',
      comment: updatedComment
    });
  } catch (error) {
    console.error('Add reply error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/recipes/:id/comments/:commentId/replies/:replyId/reply
// @desc    Reply to a reply (nested reply)
// @access  Private
router.post('/:id/comments/:commentId/replies/:replyId/reply', auth, [
  body('text')
    .trim()
    .isLength({ min: 1, max: 500 })
    .withMessage('Reply must be between 1 and 500 characters')
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

    const { text } = req.body;
    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    // Find the comment
    const comment = recipe.comments.id(req.params.commentId);
    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found'
      });
    }

    // Find the reply to reply to
    const parentReply = comment.replies.id(req.params.replyId);
    if (!parentReply) {
      return res.status(404).json({
        success: false,
        message: 'Reply not found'
      });
    }

    // Add nested reply to the parent reply
    parentReply.replies.push({
      user: req.user._id,
      text: text
    });

    await recipe.save();

    // Populate the comment with user data
    const populatedRecipe = await Recipe.findById(recipe._id)
      .populate('comments.replies.replies.user', 'name profileImage');

    const updatedComment = populatedRecipe.comments.id(req.params.commentId);
    
    // Debug: Check if nested replies have user data
    console.log('🔍 Debug nested reply user data:');
    if (updatedComment && updatedComment.replies) {
      updatedComment.replies.forEach((reply, replyIndex) => {
        if (reply.replies && reply.replies.length > 0) {
          reply.replies.forEach((nestedReply, nestedIndex) => {
            console.log(`Reply ${replyIndex}, Nested ${nestedIndex}:`, {
              user: nestedReply.user,
              userType: typeof nestedReply.user,
              hasName: nestedReply.user?.name
            });
          });
        }
      });
    }

    // Send notification to the original reply author (if not replying to own reply)
    if (parentReply.user.toString() !== req.user._id.toString()) {
      const NotificationService = require('../services/notificationService');
      const io = req.app.get('io');
      
      // Get the original reply author's user data
      const User = require('../models/User');
      const originalReplyAuthor = await User.findById(parentReply.user);
      
      if (originalReplyAuthor) {
        await NotificationService.sendNotification({
          recipientId: originalReplyAuthor._id,
          senderId: req.user._id,
          type: 'comment',
          title: 'Reply to Your Reply',
          message: `${req.user.name} replied to your reply on "${recipe.title}"`,
          data: {
            recipeId: recipe._id,
            commentId: comment._id,
            replyId: parentReply._id,
            nestedReplyText: text
          },
          io
        });
      }
    }

    res.json({
      success: true,
      message: 'Nested reply added successfully',
      comment: updatedComment
    });
  } catch (error) {
    console.error('Add nested reply error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   DELETE /api/recipes/:id/comments/:commentId/replies/:replyId
// @desc    Delete a reply
// @access  Private
router.delete('/:id/comments/:commentId/replies/:replyId', auth, async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    // Find the comment
    const comment = recipe.comments.id(req.params.commentId);
    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found'
      });
    }

    // Find the reply
    const reply = comment.replies.id(req.params.replyId);
    if (!reply) {
      return res.status(404).json({
        success: false,
        message: 'Reply not found'
      });
    }

    // Check if user owns the reply or is the recipe creator
    if (reply.user.toString() !== req.user._id.toString() && 
        recipe.creator.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this reply'
      });
    }

    // Remove the reply
    reply.remove();
    await recipe.save();

    res.json({
      success: true,
      message: 'Reply deleted successfully'
    });
  } catch (error) {
    console.error('Delete reply error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   DELETE /api/recipes/:id/comments/:commentId/replies/:replyId/nested/:nestedReplyId
// @desc    Delete a nested reply
// @access  Private
router.delete('/:id/comments/:commentId/replies/:replyId/nested/:nestedReplyId', auth, async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    // Find the comment
    const comment = recipe.comments.id(req.params.commentId);
    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found'
      });
    }

    // Find the parent reply
    const parentReply = comment.replies.id(req.params.replyId);
    if (!parentReply) {
      return res.status(404).json({
        success: false,
        message: 'Parent reply not found'
      });
    }

    // Find the nested reply
    const nestedReply = parentReply.replies.id(req.params.nestedReplyId);
    if (!nestedReply) {
      return res.status(404).json({
        success: false,
        message: 'Nested reply not found'
      });
    }

    // Check if user owns the nested reply or is the recipe creator
    if (nestedReply.user.toString() !== req.user._id.toString() && 
        recipe.creator.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this nested reply'
      });
    }

    // Remove the nested reply using pull
    parentReply.replies.pull(req.params.nestedReplyId);
    await recipe.save();

    res.json({
      success: true,
      message: 'Nested reply deleted successfully'
    });
  } catch (error) {
    console.error('Delete nested reply error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   DELETE /api/recipes/:id/comment/:commentId
// @desc    Delete a comment
// @access  Private
router.delete('/:id/comment/:commentId', auth, async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({
        success: false,
        message: 'Recipe not found'
      });
    }

    const comment = recipe.comments.id(req.params.commentId);

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: 'Comment not found'
      });
    }

    // Check if user is the comment owner or recipe owner
    if (comment.user.toString() !== req.user._id.toString() && 
        recipe.creator.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this comment'
      });
    }

    recipe.comments.pull(req.params.commentId);
    await recipe.save();

    res.json({
      success: true,
      message: 'Comment deleted successfully',
      commentsCount: recipe.comments.length
    });
  } catch (error) {
    console.error('Delete comment error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/recipes/categories/list
// @desc    Get all recipe categories
// @access  Public
router.get('/categories/list', async (req, res) => {
  try {
    const categories = [
      'appetizer',
      'main_course', 
      'dessert',
      'beverage',
      'snack',
      'soup',
      'salad',
      'breakfast',
      'lunch',
      'dinner'
    ];

    res.json({
      success: true,
      categories
    });
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
