const Recipe = require('../models/Recipe');
const mealDbRecipeService = require('./mealDbRecipeService');

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
      
      // ❌ TheMealDB suggestions disabled - only showing database recipes
      // let externalRecipes = [];
      // if (ingredientNames.length > 0) {
      //   try {
      //     const mainIngredient = ingredientNames[0];
      //     console.log(`🌐 Searching TheMealDB for: ${mainIngredient}`);
      //     externalRecipes = await this.searchMealDbRecipes(mainIngredient);
      //   } catch (e) {
      //     console.log('⚠️ External recipe search failed:', e.message);
      //   }
      // }

      // Only use database recipes (no external sources)
      const allSuggestions = this.rankSuggestions(dbRecipes, [], ingredientNames);

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
   * Search database recipes by ingredients
   */
  async searchDatabaseRecipes(ingredientNames) {
    try {
      // Create regex patterns for flexible matching
      const ingredientRegex = ingredientNames.map(name => new RegExp(name, 'i'));

      const recipes = await Recipe.find({
        isPublished: true,
        $or: [
          { 'ingredients.name': { $in: ingredientRegex } },
          { tags: { $in: ingredientRegex } },
          { title: { $in: ingredientRegex } }
        ]
      })
        .populate('creator', 'name profileImage')
        .limit(20)
        .sort({ averageRating: -1, likesCount: -1 });

      const mappedRecipes = recipes.map(recipe => {
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
          matchScore: this.calculateMatchScore(recipe, ingredientNames)
        };
        
        console.log(`📋 Mapped recipe: ${mapped.title} (ID: ${mapped.id})`);
        console.log(`   Description: ${mapped.description}`);
        console.log(`   Creator: ${mapped.creator?.name || mapped.creator}`);
        
        return mapped;
      });
      
      return mappedRecipes;

    } catch (error) {
      console.error('Database recipe search error:', error);
      return [];
    }
  }

  /**
   * Search TheMealDB for recipes
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
   */
  calculateMatchScore(recipe, ingredientNames) {
    let matchCount = 0;
    const recipeIngredients = recipe.ingredients.map(ing => 
      ing.name.toLowerCase()
    );

    ingredientNames.forEach(ingredient => {
      const lowerIngredient = ingredient.toLowerCase();
      if (recipeIngredients.some(ri => ri.includes(lowerIngredient))) {
        matchCount++;
      }
    });

    return matchCount / ingredientNames.length;
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

      // Try TheMealDB
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

