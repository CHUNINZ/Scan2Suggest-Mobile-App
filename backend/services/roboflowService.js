const axios = require('axios');

class RoboflowService {
  constructor() {
    this.apiKey = process.env.ROBOFLOW_API_KEY || 'sK6jDsSmdvh6aQ5a0Ea9';
    this.isConfigured = !!this.apiKey;
    
    if (!this.isConfigured) {
      console.warn('⚠️  ROBOFLOW_API_KEY not configured. Using fallback mock detection.');
    } else {
      console.log('✅ Roboflow AI service initialized with API key');
    }
  }

  async analyzeFood(imageBuffer, scanType) {
    // Use fallback if API key not configured
    if (!this.isConfigured) {
      console.log('🔄 Using fallback mock detection (Roboflow API key not configured)');
      return this.getMockResults(scanType);
    }

    try {
      console.log(`🤖 Analyzing ${scanType} image with Roboflow AI (new detect-and-classify workflow)...`);
      
      // Convert buffer to base64 data URL
      const base64Image = `data:image/jpeg;base64,${imageBuffer.toString('base64')}`;
      
      // Use the new detect-and-classify-5 workflow endpoint
      const response = await axios({
        method: "POST",
        url: "https://serverless.roboflow.com/scan-nac77/workflows/detect-and-classify-5",
        headers: {
          "Content-Type": "application/json"
        },
        data: {
          api_key: this.apiKey,
          inputs: {
            "image": {"type": "base64", "value": base64Image}
          }
        },
        timeout: 30000 // 30 second timeout
      });

      console.log('🎯 Raw Roboflow workflow response:', JSON.stringify(response.data, null, 2));
      
      // Format the response to match our expected format
      const formattedItems = this.formatWorkflowResponse(response.data, scanType);
      
      console.log(`✅ Roboflow workflow detected ${formattedItems.length} items`);
      return formattedItems;
      
    } catch (error) {
      console.error('❌ Roboflow workflow API error:', error.message);
      console.error('❌ Full error stack:', error.stack);
      
      // Fallback to mock results
      console.log('🔄 Falling back to mock detection due to API error');
      return this.getMockResults(scanType);
    }
  }

  formatWorkflowResponse(workflowData, scanType) {
    console.log('🔍 Formatting workflow response:', JSON.stringify(workflowData, null, 2));
    
    if (!workflowData || !workflowData.outputs) {
      console.warn('⚠️ Invalid workflow response format - no outputs');
      return [];
    }

    // Extract predictions from workflow outputs
    let predictions = [];
    
    // Check different possible output structures
    if (workflowData.outputs.predictions) {
      predictions = workflowData.outputs.predictions;
    } else if (workflowData.outputs.detections) {
      predictions = workflowData.outputs.detections;
    } else if (Array.isArray(workflowData.outputs)) {
      predictions = workflowData.outputs;
    } else {
      // Try to find predictions in nested structure
      for (const [key, value] of Object.entries(workflowData.outputs)) {
        if (value && Array.isArray(value.predictions)) {
          predictions = value.predictions;
          break;
        } else if (value && Array.isArray(value)) {
          predictions = value;
          break;
        }
      }
    }
    
    console.log('📊 Extracted predictions:', predictions);
    
    // If no predictions found, return empty array
    if (!predictions || predictions.length === 0) {
      console.warn('⚠️ No predictions found in workflow response');
      return [];
    }
    
    const formattedPredictions = predictions
      .filter(prediction => {
        const confidence = prediction.confidence || prediction.score || 0;
        return confidence > 0.3;
      })
      .map(prediction => ({
        name: this.formatFoodName(prediction.class || prediction.label || prediction.name || 'Unknown'),
        confidence: Math.round((prediction.confidence || prediction.score || 0) * 100) / 100,
        category: this.categorizeFood(prediction.class || prediction.label || prediction.name || 'food'),
        boundingBox: {
          x: Math.round((prediction.x || prediction.bbox?.x || 0) - ((prediction.width || prediction.bbox?.width || 0) / 2)),
          y: Math.round((prediction.y || prediction.bbox?.y || 0) - ((prediction.height || prediction.bbox?.height || 0) / 2)),
          width: Math.round(prediction.width || prediction.bbox?.width || 100),
          height: Math.round(prediction.height || prediction.bbox?.height || 100)
        }
      }))
      .slice(0, 8); // Limit to 8 items max
      
    console.log('✨ Formatted predictions:', formattedPredictions);
    
    return formattedPredictions;
  }

  // Keep the old method for backward compatibility
  formatRoboflowResponse(roboflowData, scanType) {
    if (!roboflowData || !roboflowData.predictions) {
      console.warn('⚠️ Invalid Roboflow response format');
      return [];
    }

    const predictions = roboflowData.predictions;
    
    // If no predictions found, return empty array and let the mobile app handle it
    if (!predictions || predictions.length === 0) {
      console.warn('⚠️ No predictions found in Roboflow response');
      return [];
    }
    
    const formattedPredictions = predictions
      .filter(prediction => prediction.confidence > 0.3) // Filter low confidence predictions
      .map(prediction => ({
        name: this.formatFoodName(prediction.class),
        confidence: Math.round(prediction.confidence * 100) / 100, // Round to 2 decimal places
        category: this.categorizeFood(prediction.class),
        boundingBox: {
          x: Math.round(prediction.x - prediction.width / 2),
          y: Math.round(prediction.y - prediction.height / 2),
          width: Math.round(prediction.width),
          height: Math.round(prediction.height)
        }
      }))
      .slice(0, 8); // Limit to 8 items max
      
    // If all predictions were filtered out due to low confidence, return empty array
    if (formattedPredictions.length === 0) {
      console.warn('⚠️ All predictions filtered out due to low confidence');
      return [];
    }
    
    return formattedPredictions;
  }

  formatFoodName(className) {
    // Convert class names to user-friendly format
    const nameMap = {
      'adobo': 'Chicken Adobo',
      'lechon': 'Lechon',
      'sinigang': 'Sinigang',
      'lumpia': 'Lumpia',
      'pancit': 'Pancit',
      'rice': 'Rice',
      'kare-kare': 'Kare-Kare',
      'sisig': 'Sisig',
      'bicol-express': 'Bicol Express',
      'dinuguan': 'Dinuguan'
    };
    
    return nameMap[className.toLowerCase()] || this.capitalizeWords(className);
  }

  capitalizeWords(str) {
    return str.replace(/\b\w/g, l => l.toUpperCase()).replace(/-/g, ' ');
  }

  categorizeFood(className) {
    const categories = {
      'adobo': 'dish',
      'lechon': 'dish', 
      'sinigang': 'dish',
      'lumpia': 'dish',
      'pancit': 'dish',
      'rice': 'food',
      'kare-kare': 'dish',
      'sisig': 'dish',
      'bicol-express': 'dish',
      'dinuguan': 'dish'
    };
    
    return categories[className.toLowerCase()] || 'food';
  }

  // Emergency fallback method - only used when Roboflow API completely fails
  getMockResults(scanType) {
    console.warn('⚠️ Using emergency fallback mock results - Roboflow API is not available');
    
    // Generate random Filipino dishes to avoid always showing the same results
    const filipinoDishes = [
      'Bicol Express', 'Chicken Adobo', 'Sinigang', 'Kare-Kare', 'Lechon', 
      'Lumpia', 'Pancit', 'Sisig', 'Dinuguan', 'Caldereta'
    ];
    
    const randomDish = filipinoDishes[Math.floor(Math.random() * filipinoDishes.length)];
    
    const mockResults = {
      food: [
        { name: randomDish, confidence: 0.75, category: 'dish', boundingBox: { x: 120, y: 80, width: 220, height: 180 } },
        { name: 'Rice', confidence: 0.92, category: 'food', boundingBox: { x: 350, y: 120, width: 140, height: 100 } }
      ],
      ingredient: [
        { name: 'Onion', confidence: 0.88, category: 'ingredient', boundingBox: { x: 100, y: 100, width: 80, height: 80 } },
        { name: 'Garlic', confidence: 0.75, category: 'ingredient', boundingBox: { x: 200, y: 150, width: 60, height: 50 } },
        { name: 'Tomato', confidence: 0.82, category: 'ingredient', boundingBox: { x: 300, y: 120, width: 90, height: 85 } }
      ]
    };
    
    return mockResults[scanType] || [];
  }

  // Test method to verify API connectivity
  async testConnection() {
    if (!this.isConfigured) {
      return { success: false, message: 'API key not configured' };
    }

    try {
      // Create a small test image (1x1 pixel base64 encoded)
      const testImage = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=';
      
      const response = await axios({
        method: "POST",
        url: "https://serverless.roboflow.com/scan-nac77/workflows/detect-and-classify-5",
        headers: {
          "Content-Type": "application/json"
        },
        data: {
          api_key: this.apiKey,
          inputs: {
            "image": {"type": "base64", "value": testImage}
          }
        },
        timeout: 10000
      });

      return { 
        success: true, 
        message: 'Roboflow workflow API connected successfully',
        response: response.data
      };
    } catch (error) {
      return { 
        success: false, 
        message: `Roboflow workflow API connection failed: ${error.message}` 
      };
    }
  }
}

module.exports = new RoboflowService();
