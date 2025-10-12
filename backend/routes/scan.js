const express = require('express');
const { body, validationResult } = require('express-validator');
const ScanResult = require('../models/ScanResult');
const Recipe = require('../models/Recipe');
const { auth } = require('../middleware/auth');
const upload = require('../middleware/upload');

const router = express.Router();

// Mock AI detection function (replace with actual AI service)
const mockAIDetection = (imageBuffer, scanType) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const mockResults = {
        food: [
          { name: 'Adobo', confidence: 0.95, category: 'dish', boundingBox: { x: 100, y: 100, width: 200, height: 150 } },
          { name: 'Rice', confidence: 0.88, category: 'food', boundingBox: { x: 50, y: 200, width: 100, height: 80 } }
        ],
        ingredient: [
          { name: 'Chicken', confidence: 0.92, category: 'ingredient', boundingBox: { x: 80, y: 120, width: 180, height: 140 } },
          { name: 'Soy Sauce', confidence: 0.85, category: 'ingredient', boundingBox: { x: 300, y: 50, width: 60, height: 120 } },
          { name: 'Garlic', confidence: 0.78, category: 'ingredient', boundingBox: { x: 200, y: 300, width: 40, height: 40 } }
        ]
      };
      
      resolve(mockResults[scanType] || []);
    }, 2000); // Simulate processing time
  });
};

// @route   POST /api/scan/analyze
// @desc    Analyze uploaded image for food/ingredients
// @access  Private
router.post('/analyze', auth, upload.single('scanImage'), [
  body('scanType')
    .isIn(['food', 'ingredient'])
    .withMessage('Scan type must be either food or ingredient')
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

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided'
      });
    }

    const { scanType } = req.body;
    const imageUrl = `/uploads/scans/${req.file.filename}`;

    // Create scan result record
    const scanResult = new ScanResult({
      user: req.user._id,
      scanType,
      originalImage: imageUrl,
      status: 'processing'
    });

    await scanResult.save();

    // Return immediately with scan ID for real-time updates
    res.json({
      success: true,
      message: 'Image uploaded successfully, processing started',
      scanId: scanResult._id,
      status: 'processing'
    });

    // Process image asynchronously
    try {
      const startTime = Date.now();
      const detectedItems = await mockAIDetection(req.file.buffer, scanType);
      const processingTime = Date.now() - startTime;

      // Find suggested recipes based on detected items
      let suggestedRecipes = [];
      if (detectedItems.length > 0) {
        const itemNames = detectedItems.map(item => item.name);
        suggestedRecipes = await Recipe.find({
          $or: [
            { title: { $in: itemNames.map(name => new RegExp(name, 'i')) } },
            { 'ingredients.name': { $in: itemNames.map(name => new RegExp(name, 'i')) } },
            { tags: { $in: itemNames.map(name => new RegExp(name, 'i')) } }
          ],
          isPublished: true
        })
          .populate('creator', 'name profileImage')
          .limit(10)
          .sort({ averageRating: -1 });
      }

      // Update scan result
      scanResult.detectedItems = detectedItems;
      scanResult.suggestedRecipes = suggestedRecipes.map(recipe => recipe._id);
      scanResult.processingTime = processingTime;
      scanResult.status = 'completed';
      await scanResult.save();

      // Send real-time update via Socket.IO
      const io = req.app.get('io');
      io.to(`user_${req.user._id}`).emit('scanComplete', {
        scanId: scanResult._id,
        detectedItems,
        suggestedRecipes,
        processingTime
      });

    } catch (processingError) {
      console.error('AI processing error:', processingError);
      
      // Update scan result with error
      scanResult.status = 'failed';
      scanResult.errorMessage = 'Failed to process image';
      await scanResult.save();

      // Send error update via Socket.IO
      const io = req.app.get('io');
      io.to(`user_${req.user._id}`).emit('scanError', {
        scanId: scanResult._id,
        error: 'Failed to process image'
      });
    }

  } catch (error) {
    console.error('Scan analyze error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during image analysis'
    });
  }
});

// @route   GET /api/scan/result/:id
// @desc    Get scan result by ID
// @access  Private
router.get('/result/:id', auth, async (req, res) => {
  try {
    const scanResult = await ScanResult.findById(req.params.id)
      .populate('user', 'name profileImage')
      .populate('suggestedRecipes', 'title images category difficulty prepTime averageRating creator')
      .populate({
        path: 'suggestedRecipes',
        populate: {
          path: 'creator',
          select: 'name profileImage'
        }
      });

    if (!scanResult) {
      return res.status(404).json({
        success: false,
        message: 'Scan result not found'
      });
    }

    // Check if user owns this scan result
    if (scanResult.user._id.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view this scan result'
      });
    }

    res.json({
      success: true,
      scanResult
    });
  } catch (error) {
    console.error('Get scan result error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/scan/history
// @desc    Get user's scan history
// @access  Private
router.get('/history', auth, async (req, res) => {
  try {
    const { page = 1, limit = 10, scanType } = req.query;
    const skip = (page - 1) * limit;
    
    const query = { user: req.user._id };
    if (scanType) query.scanType = scanType;

    const scanResults = await ScanResult.find(query)
      .populate('suggestedRecipes', 'title images category')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await ScanResult.countDocuments(query);

    res.json({
      success: true,
      scanResults,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get scan history error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   DELETE /api/scan/result/:id
// @desc    Delete scan result
// @access  Private
router.delete('/result/:id', auth, async (req, res) => {
  try {
    const scanResult = await ScanResult.findById(req.params.id);

    if (!scanResult) {
      return res.status(404).json({
        success: false,
        message: 'Scan result not found'
      });
    }

    // Check if user owns this scan result
    if (scanResult.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this scan result'
      });
    }

    await ScanResult.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Scan result deleted successfully'
    });
  } catch (error) {
    console.error('Delete scan result error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/scan/feedback
// @desc    Submit feedback on scan accuracy
// @access  Private
router.post('/feedback', auth, [
  body('scanId')
    .isMongoId()
    .withMessage('Valid scan ID is required'),
  body('accuracy')
    .isInt({ min: 1, max: 5 })
    .withMessage('Accuracy rating must be between 1 and 5'),
  body('feedback')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Feedback must be less than 500 characters')
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

    const { scanId, accuracy, feedback } = req.body;

    const scanResult = await ScanResult.findById(scanId);
    if (!scanResult) {
      return res.status(404).json({
        success: false,
        message: 'Scan result not found'
      });
    }

    // Check if user owns this scan result
    if (scanResult.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to provide feedback for this scan'
      });
    }

    // Store feedback (you might want to create a separate Feedback model)
    scanResult.feedback = {
      accuracy,
      comment: feedback,
      submittedAt: new Date()
    };

    await scanResult.save();

    res.json({
      success: true,
      message: 'Feedback submitted successfully'
    });
  } catch (error) {
    console.error('Submit feedback error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/scan/stats
// @desc    Get user's scanning statistics
// @access  Private
router.get('/stats', auth, async (req, res) => {
  try {
    const stats = await ScanResult.aggregate([
      { $match: { user: req.user._id } },
      {
        $group: {
          _id: null,
          totalScans: { $sum: 1 },
          foodScans: {
            $sum: { $cond: [{ $eq: ['$scanType', 'food'] }, 1, 0] }
          },
          ingredientScans: {
            $sum: { $cond: [{ $eq: ['$scanType', 'ingredient'] }, 1, 0] }
          },
          successfulScans: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          },
          averageProcessingTime: { $avg: '$processingTime' }
        }
      }
    ]);

    const userStats = stats[0] || {
      totalScans: 0,
      foodScans: 0,
      ingredientScans: 0,
      successfulScans: 0,
      averageProcessingTime: 0
    };

    res.json({
      success: true,
      stats: userStats
    });
  } catch (error) {
    console.error('Get scan stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
