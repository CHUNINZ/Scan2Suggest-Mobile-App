const express = require('express');
const path = require('path');
const fs = require('fs');
const { auth } = require('../middleware/auth');
const upload = require('../middleware/upload');
const { saveBuffer } = require('../services/gridfsService');

const router = express.Router();

// @route   POST /api/upload/profile
// @desc    Upload profile image
// @access  Private
router.post('/profile', auth, upload.memoryUpload.single('profileImage'), async (req, res) => {
  try {
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided'
      });
    }

    const fileId = await saveBuffer(req.file.buffer, req.file.originalname, req.file.mimetype);
    const imageUrl = `/files/${fileId.toString()}`;

    res.json({
      success: true,
      message: 'Profile image uploaded successfully',
      imageUrl,
      fileId
    });
  } catch (error) {
    console.error('Upload profile image error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during image upload'
    });
  }
});

// @route   POST /api/upload/recipe
// @desc    Upload recipe images
// @access  Private
router.post('/recipe', auth, upload.memoryUpload.array('recipeImages', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No image files provided'
      });
    }

    const images = [];
    for (const file of req.files) {
      const fileId = await saveBuffer(file.buffer, file.originalname, file.mimetype);
      images.push({ url: `/files/${fileId.toString()}`, fileId });
    }

    res.json({
      success: true,
      message: `${images.length} recipe image(s) uploaded successfully`,
      images
    });
  } catch (error) {
    console.error('Upload recipe images error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during image upload'
    });
  }
});

// @route   POST /api/upload/scan
// @desc    Upload scan image
// @access  Private
router.post('/scan', auth, upload.memoryUpload.single('scanImage'), async (req, res) => {
  try {
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided'
      });
    }

    const fileId = await saveBuffer(req.file.buffer, req.file.originalname, req.file.mimetype);
    const imageUrl = `/files/${fileId.toString()}`;

    res.json({
      success: true,
      message: 'Scan image uploaded successfully',
      imageUrl,
      fileId
    });
  } catch (error) {
    console.error('Upload scan image error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during image upload'
    });
  }
});

// @route   DELETE /api/upload/:type/:filename
// @desc    Delete uploaded file
// @access  Private
router.delete('/:type/:filename', auth, async (req, res) => {
  try {
    const { type, filename } = req.params;
    
    // Validate upload type
    const validTypes = ['profiles', 'recipes', 'scans'];
    if (!validTypes.includes(type)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid upload type'
      });
    }

    const filePath = path.join(__dirname, '..', 'uploads', type, filename);

    // Check if file exists
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({
        success: false,
        message: 'File not found'
      });
    }

    // Delete file
    fs.unlinkSync(filePath);

    res.json({
      success: true,
      message: 'File deleted successfully'
    });
  } catch (error) {
    console.error('Delete file error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during file deletion'
    });
  }
});

// @route   GET /api/upload/info/:type/:filename
// @desc    Get file information
// @access  Public
router.get('/info/:type/:filename', async (req, res) => {
  try {
    const { type, filename } = req.params;
    
    // Validate upload type
    const validTypes = ['profiles', 'recipes', 'scans'];
    if (!validTypes.includes(type)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid upload type'
      });
    }

    const filePath = path.join(__dirname, '..', 'uploads', type, filename);

    // Check if file exists
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({
        success: false,
        message: 'File not found'
      });
    }

    // Get file stats
    const stats = fs.statSync(filePath);
    const fileInfo = {
      filename,
      size: stats.size,
      createdAt: stats.birthtime,
      modifiedAt: stats.mtime,
      url: `/uploads/${type}/${filename}`
    };

    res.json({
      success: true,
      fileInfo
    });
  } catch (error) {
    console.error('Get file info error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   GET /api/upload/list/:type
// @desc    List files in upload directory
// @access  Private (Admin only)
router.get('/list/:type', auth, async (req, res) => {
  try {
    const { type } = req.params;
    const { page = 1, limit = 20 } = req.query;
    
    // Validate upload type
    const validTypes = ['profiles', 'recipes', 'scans'];
    if (!validTypes.includes(type)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid upload type'
      });
    }

    const uploadDir = path.join(__dirname, '..', 'uploads', type);

    // Check if directory exists
    if (!fs.existsSync(uploadDir)) {
      return res.json({
        success: true,
        files: [],
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: 0,
          pages: 0
        }
      });
    }

    // Read directory
    const files = fs.readdirSync(uploadDir);
    const fileInfos = files
      .filter(file => !file.startsWith('.')) // Exclude hidden files
      .map(filename => {
        const filePath = path.join(uploadDir, filename);
        const stats = fs.statSync(filePath);
        return {
          filename,
          size: stats.size,
          createdAt: stats.birthtime,
          modifiedAt: stats.mtime,
          url: `/uploads/${type}/${filename}`
        };
      })
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    // Pagination
    const skip = (page - 1) * limit;
    const paginatedFiles = fileInfos.slice(skip, skip + parseInt(limit));

    res.json({
      success: true,
      files: paginatedFiles,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: fileInfos.length,
        pages: Math.ceil(fileInfos.length / limit)
      }
    });
  } catch (error) {
    console.error('List files error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @route   POST /api/upload/cleanup
// @desc    Clean up orphaned files (files not referenced in database)
// @access  Private (Admin only)
router.post('/cleanup', auth, async (req, res) => {
  try {
    // This would require checking database references
    // For now, just return a placeholder response
    res.json({
      success: true,
      message: 'Cleanup functionality not implemented yet',
      deletedFiles: 0
    });
  } catch (error) {
    console.error('Cleanup files error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

module.exports = router;
