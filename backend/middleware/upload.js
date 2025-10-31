const multer = require('multer');

// File filter
const fileFilter = (req, file, cb) => {
  console.log('📎 File upload attempt:', {
    fieldname: file.fieldname,
    originalname: file.originalname,
    mimetype: file.mimetype,
    size: file.size
  });
  
  // Check file type
  if (file.mimetype.startsWith('image/')) {
    // Additional validation for common image types
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
      console.log('✅ File accepted - valid image type');
      cb(null, true);
    } else {
      console.log('❌ File rejected - unsupported image type:', file.mimetype);
      cb(new Error('Only JPEG, PNG, GIF, and WebP images are allowed!'), false);
    }
  } else {
    console.log('❌ File rejected - not an image. Mimetype:', file.mimetype);
    cb(new Error('Only image files are allowed!'), false);
  }
};

// Configure storage for memory upload (all files go to Cloudinary via memory buffer)
const memoryStorage = multer.memoryStorage();

// Memory-based upload configuration (for Cloudinary)
const memoryUpload = multer({
  storage: memoryStorage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: fileFilter
});

module.exports = { memoryUpload };
