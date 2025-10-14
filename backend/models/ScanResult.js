const mongoose = require('mongoose');

const detectedItemSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  confidence: {
    type: Number,
    min: 0,
    max: 1,
    required: true
  },
  category: {
    type: String,
    enum: ['ingredient', 'food', 'dish'],
    required: true
  },
  boundingBox: {
    x: Number,
    y: Number,
    width: Number,
    height: Number
  }
});

const scanResultSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  scanType: {
    type: String,
    enum: ['food', 'ingredient'],
    required: true
  },
  originalImage: {
    type: String,
    required: true
  },
  processedImage: {
    type: String
  },
  detectedItems: [detectedItemSchema],
  suggestedRecipes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Recipe'
  }],
  processingTime: {
    type: Number // in milliseconds
  },
  apiProvider: {
    type: String,
    default: 'gemini'
  },
  feedback: {
    accuracy: {
      type: Number,
      min: 1,
      max: 5
    },
    comment: String,
    submittedAt: Date
  },
  status: {
    type: String,
    enum: ['processing', 'completed', 'failed'],
    default: 'processing'
  },
  errorMessage: {
    type: String
  }
}, {
  timestamps: true
});

// Index for user queries
scanResultSchema.index({ user: 1, createdAt: -1 });
scanResultSchema.index({ scanType: 1 });

module.exports = mongoose.model('ScanResult', scanResultSchema);
