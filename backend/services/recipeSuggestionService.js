const Recipe = require('../models/Recipe');
const mealDbRecipeService = require('./mealDbRecipeService');
const spoonacularRecipeService = require('./spoonacularRecipeService');

// Toggle via env: set USE_EXTERNAL_RECIPES=false to disable external providers
const USE_EXTERNAL_RECIPES = process.env.USE_EXTERNAL_RECIPES !== 'false';

class RecipeSuggestionService {
  constructor() {
    console.log('✅ Recipe Suggestion Service initialized');
  }

  /**
   * Suggest recipes based on detected ingredients
   * @param {Array} ingredients - Array of ingredient objects with names
   * @returns {Object} Recipe suggestions from database and external API
   */
  async suggestRecipesByIngredients(ingredients) {
    try {
      if (!ingredients || ingredients.length === 0) {
        return {
          success: false,
          suggestions: [],
          totalFound: 0,
          message: 'No ingredients provided'
        };
      }

      console.log(`🍳 Finding recipes for ${ingredients.length} ingredient(s)...`);
      
      // Extract ingredient names
      const ingredientNames = ingredients.map(ing => 
        typeof ing === 'string' ? ing : ing.name
      );

      // Search our database for recipes containing these ingredients
      const dbRecipes = await this.searchDatabaseRecipes(ingredientNames);
      
      // Search external providers (optional)
      let externalRecipes = [];
      if (USE_EXTERNAL_RECIPES && ingredientNames.length > 0) {
        try {
          const mainIngredient = ingredientNames[0];
          console.log(`🌐 Searching Spoonacular for: ${mainIngredient}`);
          externalRecipes = await this.searchSpoonacularRecipes(mainIngredient);
        } catch (e) {
          console.log('⚠️ Spoonacular recipe search failed:', e.message);
          // Fallback to TheMealDB if Spoonacular fails
          try {
            const mainIngredient = ingredientNames[0];
            console.log(`🌐 Fallback: Searching TheMealDB for: ${mainIngredient}`);
            externalRecipes = await this.searchMealDbRecipes(mainIngredient);
          } catch (e2) {
            console.log('⚠️ TheMealDB fallback also failed:', e2.message);
          }
        }
      }

      // Combine database and external recipes (external optional)
      const allSuggestions = this.rankSuggestions(dbRecipes, externalRecipes, ingredientNames);

      console.log(`✅ Found ${allSuggestions.length} recipe suggestions`);

      return {
        success: true,
        suggestions: allSuggestions,
        totalFound: allSuggestions.length,
        ingredientsUsed: ingredientNames,
        message: `Found ${allSuggestions.length} recipe(s) matching your ingredients`
      };

    } catch (error) {
      console.error('❌ Recipe suggestion error:', error);
      return {
        success: false,
        suggestions: [],
        totalFound: 0,
        error: error.message,
        message: 'Failed to get recipe suggestions'
      };
    }
  }

  /**
   * Search database recipes by ingredients - PARTIAL MATCH
   * Returns recipes that contain at least some of the scanned ingredients
   * Ranked by how many ingredients match (more matches = higher priority)
   */
  async searchDatabaseRecipes(ingredientNames) {
    try {
      console.log(`🔍 Searching for recipes with partial ingredient match: ${ingredientNames.join(', ')}`);
      
      // Get all published recipes first
      const allRecipes = await Recipe.find({
        isPublished: true
      })
        .populate('creator', 'name profileImage')
        .sort({ averageRating: -1, likesCount: -1 });

      // Find recipes that contain at least one of the scanned ingredients
      const matchingRecipes = allRecipes.map(recipe => {
        const recipeIngredientNames = recipe.ingredients.map(ing => 
          ing.name.toLowerCase().trim()
        );
        
        const scannedIngredientNames = ingredientNames.map(name => 
          name.toLowerCase().trim()
        );
        
        // Find which scanned ingredients are in this recipe
        const matchingIngredients = scannedIngredientNames.filter(scannedIng => 
          recipeIngredientNames.some(recipeIng => 
            recipeIng.includes(scannedIng) || scannedIng.includes(recipeIng)
          )
        );
        
        // Count how many scanned ingredients match
        const matchCount = matchingIngredients.length;
        
        // Calculate match score: ratio of matched ingredients to total scanned ingredients
        // Higher score = more ingredients match
        const matchScore = matchCount / scannedIngredientNames.length;
        
        return {
          recipe,
          matchCount,
          matchScore,
          matchingIngredients,
          recipeIngredientNames
        };
      }).filter(item => item.matchCount > 0); // Only include recipes with at least one match

      // Sort by match score (descending), then by rating
      matchingRecipes.sort((a, b) => {
        if (b.matchScore !== a.matchScore) {
          return b.matchScore - a.matchScore;
        }
        return (b.recipe.averageRating || 0) - (a.recipe.averageRating || 0);
      });

      // Limit to top 20 results
      const limitedRecipes = matchingRecipes.slice(0, 20);

      const mappedRecipes = limitedRecipes.map(({ recipe, matchCount, matchScore, matchingIngredients, recipeIngredientNames }) => {
        const mapped = {
          source: 'database',
          id: recipe._id,
          title: recipe.title,
          description: recipe.description,
          image: recipe.images?.[0] || null,
          images: recipe.images || [],
          ingredients: recipe.ingredients,
          instructions: recipe.instructions,
          prepTime: recipe.prepTime,
          cookTime: recipe.cookTime,
          difficulty: recipe.difficulty,
          rating: recipe.averageRating,
          averageRating: recipe.averageRating,
          creator: recipe.creator,
          matchScore: matchScore, // Score based on how many ingredients match
          matchedIngredients: matchingIngredients.length, // Number of ingredients that matched
          totalScannedIngredients: ingredientNames.length
        };
        
        console.log(`✅ Match found: ${mapped.title}`);
        console.log(`   Matched ${matchCount}/${ingredientNames.length} ingredients: ${matchingIngredients.join(', ')}`);
        console.log(`   Recipe ingredients: ${recipeIngredientNames.join(', ')}`);
        console.log(`   Match score: ${matchScore.toFixed(2)}`);
        
        return mapped;
      });
      
      console.log(`🎯 Found ${mappedRecipes.length} recipes with matching ingredients`);
      return mappedRecipes;

    } catch (error) {
      console.error('Database recipe search error:', error);
      return [];
    }
  }

  /**
   * Search Spoonacular for recipes (with automatic TheMealDB fallback)
   */
  async searchSpoonacularRecipes(ingredientName) {
    try {
      console.log(`🍽️ Searching Spoonacular for recipes with: ${ingredientName}`);
      
      const recipeData = await spoonacularRecipeService.getRecipeForFood(ingredientName);
      
      // Check if Spoonacular returned null (limit reached)
      if (recipeData === null) {
        console.log('⚠️ Spoonacular limit reached, automatically falling back to TheMealDB...');
        return await this.searchMealDbRecipes(ingredientName);
      }
      
      if (recipeData && recipeData.candidates) {
        const text = recipeData.candidates[0]?.content?.parts?.[0]?.text;
        if (text) {
          // Parse the text to extract recipe info
          return [{
            source: 'spoonacular',
            id: `spoonacular_${Date.now()}`,
            title: recipeData.title || `Recipe for ${ingredientName}`,
            description: 'Recipe from Spoonacular - Clear step-by-step instructions',
            image: recipeData.image || null,
            recipeText: text,
            matchScore: 0.8, // Higher score than TheMealDB due to better quality
            readyInMinutes: recipeData.readyInMinutes,
            servings: recipeData.servings
          }];
        }
      }
      return [];
    } catch (error) {
      console.error('Spoonacular recipe search error:', error);
      return [];
    }
  }

  /**
   * Search TheMealDB for recipes (fallback)
   */
  async searchMealDbRecipes(ingredientName) {
    try {
      // TheMealDB doesn't have ingredient-based search, so we search by name
      const recipeData = await mealDbRecipeService.getRecipeForFood(ingredientName);
      
      if (recipeData && recipeData.candidates) {
        const text = recipeData.candidates[0]?.content?.parts?.[0]?.text;
        if (text) {
          // Parse the text to extract recipe info
          return [{
            source: 'mealdb',
            id: `mealdb_${Date.now()}`,
            title: `Recipe for ${ingredientName}`,
            description: 'Recipe from TheMealDB',
            image: null,
            recipeText: text,
            matchScore: 0.7
          }];
        }
      }
      return [];
    } catch (error) {
      console.error('MealDB recipe search error:', error);
      return [];
    }
  }

  /**
   * Calculate how well a recipe matches the ingredients
   * Returns a score between 0 and 1 based on ingredient overlap
   */
  calculateMatchScore(recipe, ingredientNames) {
    if (!recipe.ingredients || ingredientNames.length === 0) {
      return 0;
    }

    const recipeIngredientNames = recipe.ingredients.map(ing => 
      (typeof ing === 'string' ? ing : ing.name).toLowerCase().trim()
    );
    
    const scannedIngredientNames = ingredientNames.map(name => 
      name.toLowerCase().trim()
    );
    
    // Count how many scanned ingredients are in the recipe
    const matchCount = scannedIngredientNames.filter(scannedIng => 
      recipeIngredientNames.some(recipeIng => 
        recipeIng.includes(scannedIng) || scannedIng.includes(recipeIng)
      )
    ).length;
    
    // Return ratio of matched ingredients to total scanned ingredients
    return matchCount / scannedIngredientNames.length;
  }

  /**
   * Rank and combine suggestions from multiple sources
   */
  rankSuggestions(dbRecipes, externalRecipes, ingredientNames) {
    const allRecipes = [...dbRecipes, ...externalRecipes];
    
    // Sort by match score, then rating
    return allRecipes.sort((a, b) => {
      if (b.matchScore !== a.matchScore) {
        return b.matchScore - a.matchScore;
      }
      return (b.rating || 0) - (a.rating || 0);
    }).slice(0, 10); // Return top 10
  }

  /**
   * Get full recipe details
   */
  async getFullRecipeDetails(recipeName) {
    try {
      console.log(`📖 Getting full details for: ${recipeName}`);
      
      // First try database
      const dbRecipe = await Recipe.findOne({
        title: new RegExp(recipeName, 'i'),
        isPublished: true
      }).populate('creator', 'name profileImage');

      if (dbRecipe) {
        return {
          success: true,
          recipe: {
            source: 'database',
            ...dbRecipe.toObject()
          }
        };
      }

      // Try Spoonacular first
      const spoonacularRecipe = await spoonacularRecipeService.getRecipeForFood(recipeName);
      if (spoonacularRecipe) {
        return {
          success: true,
          recipe: {
            source: 'spoonacular',
            title: recipeName,
            data: spoonacularRecipe
          }
        };
      }

      // Fallback to TheMealDB
      const externalRecipe = await mealDbRecipeService.getRecipeForFood(recipeName);
      if (externalRecipe) {
        return {
          success: true,
          recipe: {
            source: 'mealdb',
            title: recipeName,
            data: externalRecipe
          }
        };
      }

      return {
        success: false,
        message: 'Recipe not found'
      };

    } catch (error) {
      console.error('Get recipe details error:', error);
      return {
        success: false,
        message: error.message
      };
    }
  }

  /**
   * Generate shopping list from selected recipes
   */
  generateShoppingList(selectedRecipes, userIngredients = []) {
    try {
      const allIngredients = {};
      
      // Aggregate ingredients from all selected recipes
      selectedRecipes.forEach(recipe => {
        if (recipe.ingredients) {
          recipe.ingredients.forEach(ingredient => {
            const name = ingredient.name.toLowerCase();
            
            if (!allIngredients[name]) {
              allIngredients[name] = {
                name: ingredient.name,
                amount: ingredient.amount || '1',
                unit: ingredient.unit || 'piece',
                recipes: [recipe.title]
              };
            } else {
              // Ingredient appears in multiple recipes
              allIngredients[name].recipes.push(recipe.title);
              // For simplicity, we don't aggregate quantities
            }
          });
        }
      });

      // Remove ingredients user already has
      const userIngredientNames = userIngredients.map(ing => 
        (typeof ing === 'string' ? ing : ing.name).toLowerCase()
      );

      const shoppingList = Object.values(allIngredients)
        .filter(ingredient => !userIngredientNames.includes(ingredient.name.toLowerCase()))
        .map(ingredient => ({
          ...ingredient,
          checked: false,
          usedInRecipes: ingredient.recipes.length
        }));

      console.log(`📝 Generated shopping list with ${shoppingList.length} items`);

      return shoppingList;

    } catch (error) {
      console.error('Generate shopping list error:', error);
      return [];
    }
  }
}

module.exports = new RecipeSuggestionService();

