const axios = require('axios');

class RoboflowService {
  constructor() {
    // Food detection API
    this.foodApiKey = process.env.ROBOFLOW_FOOD_API_KEY || 'Wh2lwtFofEq4R0pgNmiw';
    this.foodApiUrl = 'https://serverless.roboflow.com/filipino-food-datasets-kd7d6/1';
    
    // Ingredient detection API (specialized)
    this.ingredientApiKey = process.env.ROBOFLOW_INGREDIENT_API_KEY || 'sK6jDsSmdvh6aQ5a0Ea9';
    this.ingredientApiUrl = 'https://serverless.roboflow.com/ingredients-detector-tqvxr/3';
    
    this.isConfigured = !!(this.foodApiKey && this.ingredientApiKey);
    
    if (!this.isConfigured) {
      console.error('❌ ROBOFLOW API KEYS not configured. Detection will fail.');
    } else {
      console.log('✅ Roboflow AI service initialized');
      console.log('   🍽️  Food API: Filipino Food Dataset');
      console.log('   🥬 Ingredient API: Ingredients Detector');
    }
  }

  async analyzeFood(imageBuffer, scanType) {
    // Use appropriate Roboflow API based on scan type
    try {
      const base64Image = imageBuffer.toString('base64');
      
      // Select API based on scan type
      const isIngredientScan = scanType === 'ingredient';
      const apiUrl = isIngredientScan ? this.ingredientApiUrl : this.foodApiUrl;
      const apiKey = isIngredientScan ? this.ingredientApiKey : this.foodApiKey;
      const apiName = isIngredientScan ? 'Ingredient Detector' : 'Filipino Food Dataset';
      
      console.log(`[Roboflow] 🔍 Using ${apiName} API for ${scanType} scan`);
      console.log('[Roboflow] 📤 Sending base64 image, length:', base64Image.length);
      
      const response = await axios({
        method: 'POST',
        url: apiUrl,
        params: {
          api_key: apiKey
        },
        data: base64Image,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      });
      
      console.log(`[Roboflow] ✅ ${apiName} response received`);
      return this.formatRoboflowResponse(response.data, scanType);
    } catch (error) {
      console.error('❌ Roboflow API error:', error.message);
      if (error.response) {
        console.error('   Response status:', error.response.status);
        console.error('   Response data:', error.response.data);
      }
      throw new Error(`Roboflow API failed: ${error.message}`);
    }
  }

  formatRoboflowResponse(roboflowData, scanType) {
    console.log('🔍 Formatting Roboflow response for', scanType, 'scan');
    console.log('📊 Raw predictions:', JSON.stringify(roboflowData?.predictions?.length || 0, null, 2));
    
    if (!roboflowData || !roboflowData.predictions || !Array.isArray(roboflowData.predictions)) {
      console.warn('⚠️ Invalid Roboflow response format');
      return [];
    }

    // Different confidence thresholds for different scan types
    const confidenceThreshold = scanType === 'ingredient' ? 0.05 : 0.1;
    
    // Roboflow returns predictions with class, confidence, and bounding box info
    const formattedItems = roboflowData.predictions
      .filter(item => item.confidence > confidenceThreshold)
      .map((item) => {
        const itemName = scanType === 'ingredient' 
          ? this.formatIngredientName(item.class || 'Unknown Ingredient')
          : this.formatFoodName(item.class || 'Unknown Food');
        
        return {
          name: itemName,
          confidence: Math.round(item.confidence * 100) / 100,
          category: this.categorizeFood(item.class || 'food'),
          boundingBox: {
            x: item.x || 0,
            y: item.y || 0,
            width: item.width || 150,
            height: item.height || 100
          }
        };
      })
      .slice(0, scanType === 'ingredient' ? 10 : 5); // More items for ingredients
    
    console.log(`✨ Formatted ${formattedItems.length} ${scanType} predictions`);
    
    return formattedItems;
  }

  formatFoodName(className) {
    // Convert class names to user-friendly format for FOOD
    const nameMap = {
      'adobo': 'Chicken Adobo',
      'lechon': 'Lechon',
      'sinigang': 'Sinigang',
      'lumpia': 'Lumpia',
      'pancit': 'Pancit',
      'rice': 'Rice',
      'kare_kare': 'Kare-Kare',
      'kare-kare': 'Kare-Kare',
      'sisig': 'Sisig',
      'bicol_express': 'Bicol Express',
      'bicol-express': 'Bicol Express',
      'dinuguan': 'Dinuguan',
      'fried_rice': 'Fried Rice',
      'chicken_curry': 'Chicken Curry',
      'beef_stew': 'Beef Stew',
      'pork_chop': 'Pork Chop',
      'fish_fillet': 'Fish Fillet',
      'vegetable_salad': 'Vegetable Salad',
      'noodle_soup': 'Noodle Soup',
      'grilled_chicken': 'Grilled Chicken',
      'steamed_fish': 'Steamed Fish'
    };
    
    const cleanName = className.toLowerCase().replace(/[_-]/g, '_');
    return nameMap[cleanName] || this.capitalizeWords(className);
  }

  formatIngredientName(className) {
    // Convert class names to user-friendly format for INGREDIENTS
    // The ingredient API might return different class names
    const ingredientMap = {
      'tomato': 'Tomato',
      'tomatoes': 'Tomato',
      'onion': 'Onion',
      'onions': 'Onion',
      'garlic': 'Garlic',
      'garlic_clove': 'Garlic',
      'garlic_cloves': 'Garlic',
      'carrot': 'Carrot',
      'carrots': 'Carrot',
      'potato': 'Potato',
      'potatoes': 'Potato',
      'cabbage': 'Cabbage',
      'lettuce': 'Lettuce',
      'spinach': 'Spinach',
      'broccoli': 'Broccoli',
      'bell_pepper': 'Bell Pepper',
      'bell_peppers': 'Bell Pepper',
      'pepper': 'Pepper',
      'chili': 'Chili Pepper',
      'ginger': 'Ginger',
      'lemon': 'Lemon',
      'lime': 'Lime',
      'calamansi': 'Calamansi',
      'chicken': 'Chicken',
      'chicken_breast': 'Chicken Breast',
      'chicken_thigh': 'Chicken Thigh',
      'pork': 'Pork',
      'pork_belly': 'Pork Belly',
      'beef': 'Beef',
      'ground_beef': 'Ground Beef',
      'fish': 'Fish',
      'shrimp': 'Shrimp',
      'prawns': 'Shrimp',
      'crab': 'Crab',
      'egg': 'Egg',
      'eggs': 'Egg',
      'rice': 'Rice',
      'noodles': 'Noodles',
      'pasta': 'Pasta',
      'soy_sauce': 'Soy Sauce',
      'vinegar': 'Vinegar',
      'salt': 'Salt',
      'pepper': 'Pepper',
      'oil': 'Cooking Oil',
      'cooking_oil': 'Cooking Oil',
      'flour': 'Flour',
      'sugar': 'Sugar',
      'banana': 'Banana',
      'apple': 'Apple',
      'orange': 'Orange',
      'mango': 'Mango',
      'pineapple': 'Pineapple',
      'coconut': 'Coconut',
      'milk': 'Milk',
      'coconut_milk': 'Coconut Milk',
      'butter': 'Butter'
    };
    
    const cleanName = className.toLowerCase().replace(/[_-]/g, '_');
    return ingredientMap[cleanName] || this.capitalizeWords(className);
  }

  capitalizeWords(str) {
    return str.replace(/\b\w/g, l => l.toUpperCase()).replace(/[_-]/g, ' ');
  }

  categorizeFood(className) {
    const categories = {
      'adobo': 'dish',
      'lechon': 'dish', 
      'sinigang': 'dish',
      'lumpia': 'dish',
      'pancit': 'dish',
      'rice': 'food',
      'kare_kare': 'dish',
      'kare-kare': 'dish',
      'sisig': 'dish',
      'bicol_express': 'dish',
      'bicol-express': 'dish',
      'dinuguan': 'dish',
      'fried_rice': 'dish',
      'chicken_curry': 'dish',
      'beef_stew': 'dish',
      'pork_chop': 'dish',
      'fish_fillet': 'dish',
      'vegetable_salad': 'dish',
      'noodle_soup': 'dish',
      'grilled_chicken': 'dish',
      'steamed_fish': 'dish',
      'tomato': 'vegetable',
      'onion': 'vegetable',
      'garlic': 'vegetable',
      'carrot': 'vegetable',
      'potato': 'vegetable',
      'cabbage': 'vegetable',
      'lettuce': 'vegetable',
      'spinach': 'vegetable',
      'broccoli': 'vegetable',
      'apple': 'fruit',
      'banana': 'fruit',
      'orange': 'fruit',
      'mango': 'fruit',
      'pineapple': 'fruit',
      'coconut': 'fruit',
      'lemon': 'fruit',
      'lime': 'fruit',
      'chicken': 'meat',
      'pork': 'meat',
      'beef': 'meat',
      'fish': 'meat',
      'shrimp': 'meat',
      'crab': 'meat'
    };
    
    const cleanName = className.toLowerCase().replace(/[_-]/g, '_');
    return categories[cleanName] || 'food';
  }

  // Test method to verify API connectivity
  async testConnection() {
    if (!this.isConfigured) {
      return { success: false, message: 'Roboflow API key not configured' };
    }

    try {
      // Test with a request using a tiny placeholder image URL
      const testImageUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a3/June_odd-eyed-cat.jpg/320px-June_odd-eyed-cat.jpg';

      const response = await axios({
        method: 'POST',
        url: this.apiUrl,
        params: {
          api_key: this.apiKey,
          image: testImageUrl
        },
        timeout: 10000
      });

      return { 
        success: true, 
        message: 'Roboflow API connected successfully',
        response: { authenticated: true, predictions: response.data?.predictions?.length || 0 }
      };
    } catch (error) {
      if (error.response?.status === 401) {
        return { 
          success: false, 
          message: 'Roboflow API authentication failed - invalid API key' 
        };
      }
      return { 
        success: false, 
        message: `Roboflow API connection failed: ${error.message}` 
      };
    }
  }
}

module.exports = new RoboflowService();
