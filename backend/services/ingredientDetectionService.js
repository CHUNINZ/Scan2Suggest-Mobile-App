const roboflowService = require('./roboflowService');

class IngredientDetectionService {
  constructor() {
    console.log('✅ Ingredient Detection Service initialized');
  }

  /**
   * Detect ingredients from an image
   * @param {Buffer} imageBuffer - Image buffer
   * @param {String} filename - Original filename
   * @returns {Object} Detection results with ingredients and confidence
   */
  async detectIngredients(imageBuffer, filename) {
    try {
      console.log(`🥬 Detecting ingredients in image: ${filename}`);
      
      // Use Roboflow service for detection (uses ingredient scan type)
      const detectedItems = await roboflowService.analyzeFood(imageBuffer, 'ingredient');
      
      if (!detectedItems || detectedItems.length === 0) {
        console.log('⚠️ No ingredients detected');
        return {
          success: true,
          ingredients: [],
          confidence: 0,
          message: 'No ingredients detected in the image'
        };
      }

      // Transform detected items to ingredient format
      const ingredients = detectedItems.map(item => ({
        name: item.name,
        confidence: item.confidence,
        category: item.category || 'ingredient',
        quantity: null, // Will be estimated or user-provided
        unit: null,
        boundingBox: item.boundingBox
      }));

      // Calculate average confidence
      const avgConfidence = ingredients.reduce((sum, ing) => sum + ing.confidence, 0) / ingredients.length;

      console.log(`✅ Detected ${ingredients.length} ingredients with avg confidence ${avgConfidence.toFixed(2)}`);
      
      return {
        success: true,
        ingredients: ingredients,
        confidence: avgConfidence,
        totalDetected: ingredients.length,
        message: `Successfully detected ${ingredients.length} ingredient(s)`
      };

    } catch (error) {
      console.error('❌ Ingredient detection error:', error);
      return {
        success: false,
        ingredients: [],
        confidence: 0,
        error: error.message,
        message: 'Failed to detect ingredients'
      };
    }
  }

  /**
   * Validate and normalize ingredient names
   * @param {Array} ingredients - Array of ingredient objects
   * @returns {Array} Normalized ingredients
   */
  normalizeIngredients(ingredients) {
    const commonIngredients = {
      'tomato': ['tomatoes', 'tomato', 'roma tomato', 'cherry tomato'],
      'onion': ['onions', 'onion', 'red onion', 'white onion', 'yellow onion'],
      'garlic': ['garlic', 'garlic clove', 'garlic cloves'],
      'potato': ['potatoes', 'potato', 'russet potato'],
      'carrot': ['carrots', 'carrot'],
      'chicken': ['chicken', 'chicken breast', 'chicken thigh'],
      'pork': ['pork', 'pork chop', 'pork belly'],
      'beef': ['beef', 'ground beef', 'beef steak'],
      'rice': ['rice', 'white rice', 'brown rice', 'jasmine rice'],
      'egg': ['eggs', 'egg', 'chicken egg'],
      'fish': ['fish', 'tilapia', 'bangus', 'salmon'],
      'shrimp': ['shrimp', 'shrimps', 'prawn', 'prawns']
    };

    return ingredients.map(ingredient => {
      const ingredientName = ingredient.name.toLowerCase();
      
      // Find matching common ingredient
      for (const [standard, variations] of Object.entries(commonIngredients)) {
        if (variations.some(v => ingredientName.includes(v))) {
          return {
            ...ingredient,
            name: standard.charAt(0).toUpperCase() + standard.slice(1),
            normalizedName: standard
          };
        }
      }
      
      // If no match, return as is
      return {
        ...ingredient,
        normalizedName: ingredientName
      };
    });
  }

  /**
   * Estimate quantities based on image analysis (basic implementation)
   * @param {Array} ingredients - Detected ingredients
   * @returns {Array} Ingredients with estimated quantities
   */
  estimateQuantities(ingredients) {
    // This is a basic implementation - can be enhanced with ML models
    const defaultQuantities = {
      'tomato': { amount: '2', unit: 'pieces' },
      'onion': { amount: '1', unit: 'piece' },
      'garlic': { amount: '3', unit: 'cloves' },
      'potato': { amount: '2', unit: 'pieces' },
      'carrot': { amount: '2', unit: 'pieces' },
      'chicken': { amount: '500', unit: 'grams' },
      'pork': { amount: '500', unit: 'grams' },
      'beef': { amount: '500', unit: 'grams' },
      'rice': { amount: '2', unit: 'cups' },
      'egg': { amount: '2', unit: 'pieces' },
      'fish': { amount: '1', unit: 'piece' },
      'shrimp': { amount: '200', unit: 'grams' }
    };

    return ingredients.map(ingredient => {
      const normalized = ingredient.normalizedName || ingredient.name.toLowerCase();
      const estimate = defaultQuantities[normalized] || { amount: '1', unit: 'piece' };
      
      return {
        ...ingredient,
        estimatedQuantity: estimate.amount,
        estimatedUnit: estimate.unit
      };
    });
  }
}

module.exports = new IngredientDetectionService();

