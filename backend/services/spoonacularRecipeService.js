const axios = require('axios');

class SpoonacularRecipeService {
  constructor() {
    // Spoonacular API configuration
    this.apiKey = process.env.SPOONACULAR_API_KEY || 'your-api-key-here';
    this.baseUrl = 'https://api.spoonacular.com/recipes';
    this.freeTierLimit = 150; // requests per day
    this.requestCount = 0;
    this.lastResetDate = new Date().toDateString();
    
    console.log('✅ Spoonacular Recipe service initialized');
    console.log(`🔑 API Key configured: ${this.apiKey ? 'Yes' : 'No'}`);
  }

  /**
   * Reset daily request counter if it's a new day
   */
  resetDailyCounter() {
    const today = new Date().toDateString();
    if (today !== this.lastResetDate) {
      this.requestCount = 0;
      this.lastResetDate = today;
      console.log('🔄 Daily request counter reset');
    }
  }

  /**
   * Check if we can make a request (free tier limit)
   */
  canMakeRequest() {
    this.resetDailyCounter();
    return this.requestCount < this.freeTierLimit;
  }

  /**
   * Check if Spoonacular has reached its daily limit
   */
  hasReachedLimit() {
    this.resetDailyCounter();
    return this.requestCount >= this.freeTierLimit;
  }

  /**
   * Make API request with error handling and rate limiting
   */
  async makeRequest(endpoint, params = {}) {
    if (!this.canMakeRequest()) {
      console.warn('⚠️ Daily request limit reached for Spoonacular API');
      return null;
    }

    try {
      const response = await axios.get(`${this.baseUrl}${endpoint}`, {
        params: {
          ...params,
          apiKey: this.apiKey
        },
        timeout: 10000
      });

      this.requestCount++;
      console.log(`📊 Spoonacular requests used today: ${this.requestCount}/${this.freeTierLimit}`);
      
      return response.data;
    } catch (error) {
      console.error('❌ Spoonacular API error:', error.message);
      if (error.response) {
        console.error('Response status:', error.response.status);
        console.error('Response data:', error.response.data);
      }
      return null;
    }
  }

  /**
   * Search for recipes by ingredient or food name
   */
  async searchRecipes(query, number = 5) {
    console.log(`🔍 Searching Spoonacular for: ${query}`);
    
    const data = await this.makeRequest('/complexSearch', {
      query: query,
      number: number,
      addRecipeInformation: true,
      fillIngredients: true,
      instructionsRequired: true
    });

    if (!data || !data.results) {
      console.log('❌ No recipes found in Spoonacular');
      return [];
    }

    console.log(`✅ Found ${data.results.length} recipes from Spoonacular`);
    return data.results;
  }

  /**
   * Get detailed recipe information including analyzed instructions
   */
  async getRecipeDetails(recipeId) {
    console.log(`📋 Getting detailed recipe info for ID: ${recipeId}`);
    
    const data = await this.makeRequest(`/${recipeId}/information`, {
      includeNutrition: false
    });

    if (!data) {
      return null;
    }

    // Get analyzed instructions for better step-by-step format
    const instructionsData = await this.makeRequest(`/${recipeId}/analyzedInstructions`);
    
    return {
      ...data,
      analyzedInstructions: instructionsData
    };
  }

  /**
   * Get recipe for a specific food name (main method to replace TheMealDB)
   * OPTIMIZED: Uses only 1 API request by getting all data in search
   * AUTOMATIC FALLBACK: Returns null when limit reached for TheMealDB fallback
   */
  async getRecipeForFood(foodName) {
    try {
      // Check if we've reached the daily limit
      if (this.hasReachedLimit()) {
        console.log('⚠️ Spoonacular daily limit reached (150/150). Returning null for TheMealDB fallback.');
        return null; // Signal to use TheMealDB fallback
      }

      console.log(`🍽️ Getting Spoonacular recipe for: ${foodName}`);
      
      // Search for recipes with ALL information included (1 request only)
      const data = await this.makeRequest('/complexSearch', {
        query: foodName,
        number: 1,
        addRecipeInformation: true,
        fillIngredients: true,
        instructionsRequired: true
      });

      if (!data || !data.results || data.results.length === 0) {
        console.log('⚠️ No recipes found, trying partial search...');
        // Try with individual words (1 more request max)
        const words = foodName.split(' ').filter(word => word.length > 3);
        for (const word of words) {
          // Check limit before each additional request
          if (this.hasReachedLimit()) {
            console.log('⚠️ Spoonacular limit reached during partial search. Returning null for TheMealDB fallback.');
            return null;
          }

          const partialData = await this.makeRequest('/complexSearch', {
            query: word,
            number: 1,
            addRecipeInformation: true,
            fillIngredients: true,
            instructionsRequired: true
          });
          
          if (partialData && partialData.results && partialData.results.length > 0) {
            console.log(`✅ Found recipe with partial search: ${word}`);
            return this.formatRecipeFromSearch(partialData.results[0]);
          }
        }
        
        console.log('⚠️ No recipes found, generating generic recipe');
        return this.generateGenericRecipe(foodName);
      }

      console.log(`✅ Found recipe: ${data.results[0].title}`);
      // Format the recipe directly from search results (no additional API calls)
      return this.formatRecipeFromSearch(data.results[0]);

    } catch (error) {
      console.error('❌ Spoonacular recipe search error:', error.message);
      // If it's a rate limit error, return null for TheMealDB fallback
      if (error.response && error.response.status === 402) {
        console.log('⚠️ Spoonacular rate limit exceeded. Returning null for TheMealDB fallback.');
        return null;
      }
      return this.generateGenericRecipe(foodName);
    }
  }

  /**
   * Format recipe data from search results (optimized - no additional API calls)
   */
  formatRecipeFromSearch(recipe) {
    // Extract ingredients from search results
    const ingredients = recipe.extendedIngredients?.map(ing => {
      const amount = ing.amount ? Math.round(ing.amount * 100) / 100 : '';
      const unit = ing.unit || '';
      const name = ing.name || ing.originalName || '';
      
      if (amount && unit) {
        return `- ${amount} ${unit} ${name}`;
      } else if (amount) {
        return `- ${amount} ${name}`;
      } else {
        return `- ${name}`;
      }
    }) || [];

    // Extract instructions from search results
    let instructions = [];
    
    if (recipe.analyzedInstructions && recipe.analyzedInstructions.length > 0) {
      // Use analyzed instructions if available
      const analyzedSteps = recipe.analyzedInstructions[0].steps || [];
      instructions = analyzedSteps.map((step, index) => {
        let instruction = `${index + 1}. ${step.step}`;
        
        // Add equipment if mentioned
        if (step.equipment && step.equipment.length > 0) {
          const equipment = step.equipment.map(eq => eq.name).join(', ');
          instruction += ` (Equipment: ${equipment})`;
        }
        
        return instruction;
      });
    } else if (recipe.instructions) {
      // Fallback to regular instructions
      instructions = recipe.instructions
        .split(/\r?\n/)
        .filter(line => line.trim())
        .map((line, index) => `${index + 1}. ${line.trim()}`);
    }

    // Create recipe text
    const recipeText = `${recipe.title}

${recipe.summary ? recipe.summary.replace(/<[^>]*>/g, '') : 'Delicious recipe'}

Ingredients:
${ingredients.join('\n')}

Instructions:
${instructions.join('\n')}

Prep Time: ${recipe.preparationMinutes || 'N/A'} minutes
Cook Time: ${recipe.cookingMinutes || 'N/A'} minutes
Servings: ${recipe.servings || 'N/A'}
Difficulty: ${recipe.dishTypes ? recipe.dishTypes[0] : 'Medium'}`;

    // Return in format compatible with your existing system
    return {
      candidates: [{
        content: {
          parts: [{
            text: recipeText
          }]
        }
      }],
      source: 'spoonacular',
      recipeId: recipe.id,
      title: recipe.title,
      image: recipe.image,
      readyInMinutes: recipe.readyInMinutes,
      servings: recipe.servings
    };
  }

  /**
   * Format recipe data to match your existing format (for detailed API calls)
   */
  formatRecipe(recipe) {
    // Extract ingredients
    const ingredients = recipe.extendedIngredients?.map(ing => {
      const amount = ing.amount ? Math.round(ing.amount * 100) / 100 : '';
      const unit = ing.unit || '';
      const name = ing.name || ing.originalName || '';
      
      if (amount && unit) {
        return `- ${amount} ${unit} ${name}`;
      } else if (amount) {
        return `- ${amount} ${name}`;
      } else {
        return `- ${name}`;
      }
    }) || [];

    // Extract instructions - use analyzed instructions if available
    let instructions = [];
    
    if (recipe.analyzedInstructions && recipe.analyzedInstructions.length > 0) {
      // Use analyzed instructions (better format)
      const analyzedSteps = recipe.analyzedInstructions[0].steps || [];
      instructions = analyzedSteps.map((step, index) => {
        let instruction = `${index + 1}. ${step.step}`;
        
        // Add equipment if mentioned
        if (step.equipment && step.equipment.length > 0) {
          const equipment = step.equipment.map(eq => eq.name).join(', ');
          instruction += ` (Equipment: ${equipment})`;
        }
        
        return instruction;
      });
    } else if (recipe.instructions) {
      // Fallback to regular instructions
      instructions = recipe.instructions
        .split(/\r?\n/)
        .filter(line => line.trim())
        .map((line, index) => `${index + 1}. ${line.trim()}`);
    }

    // Create recipe text
    const recipeText = `${recipe.title}

${recipe.summary ? recipe.summary.replace(/<[^>]*>/g, '') : 'Delicious recipe'}

Ingredients:
${ingredients.join('\n')}

Instructions:
${instructions.join('\n')}

Prep Time: ${recipe.preparationMinutes || 'N/A'} minutes
Cook Time: ${recipe.cookingMinutes || 'N/A'} minutes
Servings: ${recipe.servings || 'N/A'}
Difficulty: ${recipe.dishTypes ? recipe.dishTypes[0] : 'Medium'}`;

    // Return in format compatible with your existing system
    return {
      candidates: [{
        content: {
          parts: [{
            text: recipeText
          }]
        }
      }],
      source: 'spoonacular',
      recipeId: recipe.id,
      title: recipe.title,
      image: recipe.image,
      readyInMinutes: recipe.readyInMinutes,
      servings: recipe.servings
    };
  }

  /**
   * Generate a generic recipe when no results are found
   */
  generateGenericRecipe(foodName) {
    console.log(`⚠️ Generating generic recipe for: ${foodName}`);
    
    const recipeText = `Ingredients:
- 1 kg ${foodName.includes('Chicken') ? 'chicken' : foodName.includes('Pork') ? 'pork' : foodName.includes('Beef') ? 'beef' : 'meat'}, cut into pieces
- 3 cloves garlic, minced
- 1 medium onion, chopped
- 2 tablespoons cooking oil
- 1 cup water or broth
- 2 tablespoons soy sauce
- 1 tablespoon vinegar
- Salt and pepper to taste
- Bay leaves
- Optional: vegetables of your choice

Instructions:
1. Heat oil in a large pan over medium heat.
2. Sauté garlic and onions until fragrant and golden.
3. Add the main ingredient and cook until lightly browned on all sides.
4. Pour in the soy sauce, vinegar, and water or broth.
5. Add bay leaves and season with salt and pepper.
6. Bring to a boil, then reduce heat and simmer for 30-40 minutes until tender.
7. Add vegetables if using and cook until tender.
8. Adjust seasoning to taste.
9. Serve hot with steamed rice.
10. Enjoy your ${foodName}!

Note: This is a basic recipe template. Cooking times and ingredients may vary based on your preferences.`;

    return {
      candidates: [{
        content: {
          parts: [{
            text: recipeText
          }]
        }
      }],
      source: 'generic',
      title: `Basic ${foodName} Recipe`
    };
  }

  /**
   * Get multiple recipe suggestions for ingredients (OPTIMIZED: 1 API call only)
   */
  async getRecipeSuggestions(ingredientNames, limit = 3) {
    try {
      console.log(`🍽️ Getting recipe suggestions for ingredients: ${ingredientNames.join(', ')}`);
      
      const query = ingredientNames.join(' ');
      
      // Get all recipe data in one API call
      const data = await this.makeRequest('/complexSearch', {
        query: query,
        number: limit,
        addRecipeInformation: true,
        fillIngredients: true,
        instructionsRequired: true
      });
      
      if (!data || !data.results || data.results.length === 0) {
        return [];
      }

      // Format all recipes from search results (no additional API calls)
      const formattedRecipes = data.results.map(recipe => 
        this.formatRecipeFromSearch(recipe)
      );

      return formattedRecipes;

    } catch (error) {
      console.error('❌ Spoonacular suggestions error:', error.message);
      return [];
    }
  }
}

module.exports = new SpoonacularRecipeService();
