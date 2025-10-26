const mealDbRecipeService = require('./mealDbRecipeService');
const spoonacularRecipeService = require('./spoonacularRecipeService');
const Recipe = require('../models/Recipe');

class RecipeService {
  constructor() {
    console.log('✅ Recipe Service initialized');
  }

  /**
   * Get recipe by name from database or external API
   * @param {String} foodName - Name of the food/recipe
   * @returns {Object} Recipe data
   */
  async getRecipeByName(foodName) {
    try {
      console.log(`🍳 Getting recipe for: ${foodName}`);
      
      // First, try to find in our database
      const dbRecipe = await Recipe.findOne({
        title: new RegExp(foodName, 'i'),
        isPublished: true
      }).populate('creator', 'name profileImage');

      if (dbRecipe) {
        console.log(`✅ Found recipe in database: ${dbRecipe.title}`);
        return this.formatDatabaseRecipe(dbRecipe);
      }

      // If not in database, get from Spoonacular (with automatic TheMealDB fallback)
      console.log('🌐 Fetching from Spoonacular...');
      let externalRecipe = null;
      try {
        externalRecipe = await spoonacularRecipeService.getRecipeForFood(foodName);
        
        // Check if Spoonacular returned null (limit reached)
        if (externalRecipe === null) {
          console.log('⚠️ Spoonacular limit reached, automatically falling back to TheMealDB...');
          externalRecipe = await mealDbRecipeService.getRecipeForFood(foodName);
          console.log('✅ Recipe retrieved from TheMealDB fallback');
        } else {
          console.log('✅ Recipe retrieved from Spoonacular');
        }
      } catch (e) {
        console.log('⚠️ Spoonacular failed, trying TheMealDB fallback...');
        try {
          externalRecipe = await mealDbRecipeService.getRecipeForFood(foodName);
          console.log('✅ Recipe retrieved from TheMealDB fallback');
        } catch (e2) {
          console.error('❌ Both APIs failed:', e2.message);
        }
      }
      
      return externalRecipe || this.generateDefaultRecipe(foodName);

    } catch (error) {
      console.error('❌ Get recipe error:', error);
      return this.generateDefaultRecipe(foodName);
    }
  }

  /**
   * Get a random recipe
   * @returns {Object} Random recipe
   */
  async getRandomRecipe() {
    try {
      console.log('🎲 Getting random recipe...');
      
      // Try to get from database first
      const count = await Recipe.countDocuments({ isPublished: true });
      
      if (count > 0) {
        const random = Math.floor(Math.random() * count);
        const dbRecipe = await Recipe.findOne({ isPublished: true })
          .skip(random)
          .populate('creator', 'name profileImage');
        
        if (dbRecipe) {
          console.log(`✅ Random recipe: ${dbRecipe.title}`);
          return this.formatDatabaseRecipe(dbRecipe);
        }
      }

      // Fallback to Spoonacular for random recipe (with TheMealDB fallback)
      const filipinoFoods = [
        'Adobo', 'Sinigang', 'Kare-Kare', 'Lechon', 'Lumpia',
        'Pancit', 'Sisig', 'Bicol Express', 'Dinuguan', 'Bulalo'
      ];
      
      const randomFood = filipinoFoods[Math.floor(Math.random() * filipinoFoods.length)];
      console.log(`🌐 Fetching random recipe: ${randomFood}`);
      
      let externalRecipe = null;
      try {
        externalRecipe = await spoonacularRecipeService.getRecipeForFood(randomFood);
        
        // Check if Spoonacular returned null (limit reached)
        if (externalRecipe === null) {
          console.log('⚠️ Spoonacular limit reached, automatically falling back to TheMealDB...');
          externalRecipe = await mealDbRecipeService.getRecipeForFood(randomFood);
          console.log('✅ Random recipe retrieved from TheMealDB fallback');
        } else {
          console.log('✅ Random recipe retrieved from Spoonacular');
        }
      } catch (e) {
        console.log('⚠️ Spoonacular failed, trying TheMealDB fallback...');
        try {
          externalRecipe = await mealDbRecipeService.getRecipeForFood(randomFood);
          console.log('✅ Random recipe retrieved from TheMealDB fallback');
        } catch (e2) {
          console.error('❌ Both APIs failed:', e2.message);
        }
      }
      
      return externalRecipe || this.generateDefaultRecipe(randomFood);

    } catch (error) {
      console.error('❌ Get random recipe error:', error);
      return this.generateDefaultRecipe('Filipino Dish');
    }
  }

  /**
   * Format database recipe to match external API format
   */
  formatDatabaseRecipe(recipe) {
    // Format ingredients
    const ingredientsList = recipe.ingredients.map(ing => 
      `- ${ing.amount || ''} ${ing.unit || ''} ${ing.name}`.trim()
    );

    // Format instructions
    const instructionsList = recipe.instructions.map((inst, index) => 
      `${index + 1}. ${inst.instruction || inst.step || inst}`
    );

    const recipeText = `${recipe.title}

${recipe.description}

Ingredients:
${ingredientsList.join('\n')}

Instructions:
${instructionsList.join('\n')}

Prep Time: ${recipe.prepTime} minutes
Cook Time: ${recipe.cookTime} minutes
Servings: ${recipe.servings}
Difficulty: ${recipe.difficulty}`;

    return {
      candidates: [{
        content: {
          parts: [{
            text: recipeText
          }]
        }
      }],
      source: 'database',
      recipeId: recipe._id,
      title: recipe.title,
      images: recipe.images
    };
  }

  /**
   * Generate a default recipe when nothing is found
   */
  generateDefaultRecipe(foodName) {
    console.log(`⚠️ Generating default recipe for: ${foodName}`);
    
    const recipeText = `Recipe for ${foodName}

This is a traditional Filipino dish that's beloved for its rich flavors.

Ingredients:
- 1 kg main protein (chicken, pork, or beef)
- 3 cloves garlic, minced
- 1 medium onion, chopped
- 2 tablespoons cooking oil
- 1 cup water or broth
- 2 tablespoons soy sauce
- 1 tablespoon vinegar
- Salt and pepper to taste
- Bay leaves
- Vegetables of choice

Instructions:
1. Heat oil in a large pan over medium heat.
2. Sauté garlic and onions until fragrant and golden brown.
3. Add the main protein and cook until lightly browned on all sides.
4. Pour in the soy sauce, vinegar, and water or broth.
5. Add bay leaves and season with salt and pepper.
6. Bring to a boil, then reduce heat and simmer for 30-40 minutes.
7. Add vegetables if using and cook until tender.
8. Adjust seasoning to taste.
9. Serve hot with steamed rice.

Prep Time: 15 minutes
Cook Time: 45 minutes
Servings: 4-6
Difficulty: Easy

Note: This is a basic recipe template. Adjust ingredients and cooking time based on your preferences and the specific dish.`;

    return {
      candidates: [{
        content: {
          parts: [{
            text: recipeText
          }]
        }
      }],
      source: 'generated',
      title: foodName
    };
  }

  /**
   * Search recipes by ingredients
   */
  async searchByIngredients(ingredients) {
    try {
      const ingredientNames = ingredients.map(ing => 
        typeof ing === 'string' ? ing : ing.name
      );

      console.log(`🔍 Searching recipes with ingredients: ${ingredientNames.join(', ')}`);

      const recipes = await Recipe.find({
        isPublished: true,
        'ingredients.name': { 
          $in: ingredientNames.map(name => new RegExp(name, 'i')) 
        }
      })
        .populate('creator', 'name profileImage')
        .limit(10)
        .sort({ averageRating: -1 });

      console.log(`✅ Found ${recipes.length} matching recipes`);

      return recipes.map(recipe => this.formatDatabaseRecipe(recipe));

    } catch (error) {
      console.error('❌ Search by ingredients error:', error);
      return [];
    }
  }

  /**
   * Get recipe by ID
   */
  async getRecipeById(recipeId) {
    try {
      const recipe = await Recipe.findById(recipeId)
        .populate('creator', 'name profileImage');

      if (!recipe) {
        return null;
      }

      return this.formatDatabaseRecipe(recipe);

    } catch (error) {
      console.error('❌ Get recipe by ID error:', error);
      return null;
    }
  }
}

module.exports = new RecipeService();

