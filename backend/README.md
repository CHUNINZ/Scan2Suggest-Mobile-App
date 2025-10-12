# Recipe App Backend API

A comprehensive Node.js backend for a Filipino recipe app with AI-powered food and ingredient scanning capabilities.

## Features

- **User Authentication**: JWT-based authentication with registration, login, and profile management
- **Recipe Management**: CRUD operations for recipes with categories, ratings, and social features
- **AI-Powered Scanning**: Food and ingredient detection with recipe suggestions
- **Social Features**: Follow/unfollow users, social feed, trending recipes
- **Real-time Notifications**: Socket.IO integration for live updates
- **File Upload**: Image handling for profiles, recipes, and scans
- **Search & Discovery**: Advanced search and recommendation system

## Tech Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT (JSON Web Tokens)
- **File Upload**: Multer
- **Real-time**: Socket.IO
- **Security**: Helmet, CORS, Rate Limiting
- **Validation**: Express Validator

## Installation

1. Clone the repository
2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file with the following variables:
```env
# Database
MONGODB_URI=mongodb://localhost:27017/recipe-app

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=7d

# Server
PORT=5000
NODE_ENV=development

# File Upload (Optional - for cloud storage)
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Email (Optional - for notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# AI/ML APIs (Optional - for enhanced scanning)
AI_API_KEY=your-ai-api-key
AI_API_URL=https://api.your-ai-service.com

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

4. Start the server:
```bash
npm start
```

The server will run on `http://localhost:5000`

## API Endpoints

### Authentication (`/api/auth`)
- `POST /register` - Register new user
- `POST /login` - User login
- `GET /me` - Get current user profile
- `POST /refresh` - Refresh JWT token
- `POST /logout` - User logout
- `POST /forgot-password` - Send password reset email

### Users (`/api/users`)
- `GET /profile/:id` - Get user profile by ID
- `PUT /profile` - Update user profile
- `POST /upload-avatar` - Upload profile image
- `POST /follow/:id` - Follow/unfollow user
- `GET /recipes/:id` - Get user's recipes
- `GET /bookmarks` - Get user's bookmarked recipes
- `GET /search` - Search users

### Recipes (`/api/recipes`)
- `GET /` - Get all recipes with filters
- `GET /:id` - Get recipe by ID
- `POST /` - Create new recipe
- `PUT /:id` - Update recipe
- `DELETE /:id` - Delete recipe
- `POST /:id/like` - Like/unlike recipe
- `POST /:id/bookmark` - Bookmark/unbookmark recipe
- `POST /:id/rate` - Rate recipe
- `GET /categories/list` - Get all categories

### Scanning (`/api/scan`)
- `POST /analyze` - Analyze uploaded image for food/ingredients
- `GET /result/:id` - Get scan result by ID
- `GET /history` - Get user's scan history
- `DELETE /result/:id` - Delete scan result
- `POST /feedback` - Submit feedback on scan accuracy
- `GET /stats` - Get user's scanning statistics

### Social (`/api/social`)
- `POST /follow/:id` - Follow/unfollow user
- `GET /followers/:id` - Get user's followers
- `GET /following/:id` - Get user's following
- `GET /feed` - Get user's social feed
- `GET /discover` - Discover new users to follow
- `GET /trending` - Get trending recipes
- `POST /share/:recipeId` - Share recipe
- `GET /activity/:id` - Get user's recent activity

### Notifications (`/api/notifications`)
- `GET /` - Get user's notifications
- `PUT /:id/read` - Mark notification as read
- `PUT /read-all` - Mark all notifications as read
- `DELETE /:id` - Delete notification
- `DELETE /` - Delete all notifications
- `POST /send` - Send notification to user
- `GET /stats` - Get notification statistics
- `PUT /settings` - Update notification preferences

### Upload (`/api/upload`)
- `POST /profile` - Upload profile image
- `POST /recipe` - Upload recipe images
- `POST /scan` - Upload scan image
- `DELETE /:type/:filename` - Delete uploaded file
- `GET /info/:type/:filename` - Get file information
- `GET /list/:type` - List files in upload directory

## Database Models

### User
- Personal information (name, email, password)
- Profile data (bio, location, profile image)
- Social connections (followers, following)
- Preferences and statistics
- Bookmarked and liked recipes

### Recipe
- Basic info (title, description, category, cuisine)
- Cooking details (prep time, cook time, difficulty, servings)
- Ingredients and instructions
- Nutrition information and dietary tags
- Social features (likes, bookmarks, ratings, views)
- Creator and publication status

### ScanResult
- User and scan type (food/ingredient)
- Original and processed images
- Detected items with confidence scores
- Suggested recipes based on detection
- Processing metadata and feedback

### Notification
- Recipient and sender information
- Notification type and content
- Related data (recipe, user references)
- Read status and timestamps

## Real-time Features

The backend uses Socket.IO for real-time communication:

- **Scan Updates**: Live updates during AI processing
- **Notifications**: Instant delivery of likes, follows, comments
- **Social Feed**: Real-time recipe updates from followed users

## Security Features

- **JWT Authentication**: Secure token-based authentication
- **Rate Limiting**: Prevents API abuse
- **Input Validation**: Express Validator for request validation
- **CORS Protection**: Configured for cross-origin requests
- **Helmet**: Security headers for Express
- **Password Hashing**: bcryptjs for secure password storage

## File Upload

Supports multiple upload types:
- **Profile Images**: User avatars
- **Recipe Images**: Multiple images per recipe
- **Scan Images**: Images for AI analysis

Files are stored locally with options for cloud storage integration (Cloudinary).

## AI Integration

Mock AI detection is implemented with placeholders for:
- Food recognition
- Ingredient identification
- Recipe suggestions based on detected items
- Confidence scoring and bounding boxes

## Development

### Project Structure
```
backend/
├── controllers/        # Route controllers
├── middleware/         # Custom middleware
├── models/            # Mongoose schemas
├── routes/            # API routes
├── uploads/           # File storage
├── server.js          # Main server file
├── package.json       # Dependencies
└── .env              # Environment variables
```

### Running in Development
```bash
npm run dev  # With nodemon for auto-restart
```

### Testing
```bash
npm test    # Run test suite (to be implemented)
```

## Deployment

1. Set up MongoDB database
2. Configure environment variables
3. Install dependencies: `npm install --production`
4. Start server: `npm start`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Postman API Testing Examples

### Base URL
```
http://localhost:3000/api
```

### Authentication Endpoints

#### 1. Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

#### 2. Login User
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

#### 3. Get Current User
```http
GET /api/auth/me
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 4. Refresh Token
```http
POST /api/auth/refresh
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 5. Logout
```http
POST /api/auth/logout
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 6. Forgot Password
```http
POST /api/auth/forgot-password
Content-Type: application/json

{
  "email": "john@example.com"
}
```

### User Management Endpoints

#### 7. Get User Profile
```http
GET /api/users/profile/USER_ID
```

#### 8. Update Profile
```http
PUT /api/users/profile
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "name": "John Updated",
  "bio": "I love cooking Filipino dishes",
  "location": "Manila, Philippines",
  "preferences": {
    "dietaryRestrictions": ["vegetarian"],
    "favoriteCategories": ["main_course", "dessert"]
  }
}
```

#### 9. Upload Avatar
```http
POST /api/users/upload-avatar
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: multipart/form-data

profileImage: [SELECT FILE]
```

#### 10. Follow/Unfollow User
```http
POST /api/users/follow/USER_ID
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 11. Get User's Recipes
```http
GET /api/users/recipes/USER_ID?page=1&limit=10
```

#### 12. Get User's Bookmarks
```http
GET /api/users/bookmarks?page=1&limit=10
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 13. Search Users
```http
GET /api/users/search?q=john&page=1&limit=10
```

### Recipe Endpoints

#### 14. Get All Recipes
```http
GET /api/recipes?page=1&limit=10&category=main_course&difficulty=easy&search=adobo&sort=createdAt&order=desc
```

#### 15. Get Recipe by ID
```http
GET /api/recipes/RECIPE_ID
```

#### 16. Create Recipe
```http
POST /api/recipes
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: multipart/form-data

title: Chicken Adobo
description: Traditional Filipino chicken dish
category: main_course
cuisine: Filipino
difficulty: easy
prepTime: 15
cookTime: 45
servings: 4
ingredients: [{"name": "Chicken", "amount": "1 kg", "unit": "kg"}, {"name": "Soy Sauce", "amount": "1/2", "unit": "cup"}]
instructions: [{"step": 1, "instruction": "Marinate chicken in soy sauce"}, {"step": 2, "instruction": "Cook until tender"}]
nutrition: {"calories": 350, "protein": 25, "carbs": 10, "fat": 15}
tags: ["chicken", "filipino", "traditional"]
spiceLevel: mild
dietaryInfo: {"isVegetarian": false, "isVegan": false, "isGlutenFree": false}
recipeImages: [SELECT FILES]
```

#### 17. Update Recipe
```http
PUT /api/recipes/RECIPE_ID
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: multipart/form-data

title: Updated Chicken Adobo
description: Updated traditional Filipino chicken dish
recipeImages: [SELECT FILES]
```

#### 18. Delete Recipe
```http
DELETE /api/recipes/RECIPE_ID
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 19. Like/Unlike Recipe
```http
POST /api/recipes/RECIPE_ID/like
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 20. Bookmark/Unbookmark Recipe
```http
POST /api/recipes/RECIPE_ID/bookmark
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 21. Rate Recipe
```http
POST /api/recipes/RECIPE_ID/rate
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "rating": 5,
  "review": "Amazing recipe! Very authentic taste."
}
```

#### 22. Get Recipe Categories
```http
GET /api/recipes/categories/list
```

### Scanning Endpoints

#### 23. Analyze Image
```http
POST /api/scan/analyze
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: multipart/form-data

scanType: food
scanImage: [SELECT FILE]
```

#### 24. Get Scan Result
```http
GET /api/scan/result/SCAN_ID
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 25. Get Scan History
```http
GET /api/scan/history?page=1&limit=10&scanType=food
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 26. Delete Scan Result
```http
DELETE /api/scan/result/SCAN_ID
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 27. Submit Scan Feedback
```http
POST /api/scan/feedback
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "scanId": "SCAN_ID",
  "accuracy": 4,
  "feedback": "Good detection but missed some ingredients"
}
```

#### 28. Get Scan Statistics
```http
GET /api/scan/stats
Authorization: Bearer YOUR_JWT_TOKEN
```

### Social Endpoints

#### 29. Follow/Unfollow User
```http
POST /api/social/follow/USER_ID
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 30. Get User's Followers
```http
GET /api/social/followers/USER_ID?page=1&limit=20
```

#### 31. Get User's Following
```http
GET /api/social/following/USER_ID?page=1&limit=20
```

#### 32. Get Social Feed
```http
GET /api/social/feed?page=1&limit=10
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 33. Discover Users
```http
GET /api/social/discover?page=1&limit=20
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 34. Get Trending Recipes
```http
GET /api/social/trending?page=1&limit=10&timeframe=week
```

#### 35. Share Recipe
```http
POST /api/social/share/RECIPE_ID
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "platform": "facebook",
  "message": "Check out this amazing recipe!"
}
```

#### 36. Get User Activity
```http
GET /api/social/activity/USER_ID?page=1&limit=20
```

### Notification Endpoints

#### 37. Get Notifications
```http
GET /api/notifications?page=1&limit=20&unreadOnly=false
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 38. Mark Notification as Read
```http
PUT /api/notifications/NOTIFICATION_ID/read
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 39. Mark All Notifications as Read
```http
PUT /api/notifications/read-all
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 40. Delete Notification
```http
DELETE /api/notifications/NOTIFICATION_ID
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 41. Delete All Notifications
```http
DELETE /api/notifications
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 42. Send Notification
```http
POST /api/notifications/send
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "recipient": "USER_ID",
  "type": "system",
  "title": "Welcome!",
  "message": "Welcome to our recipe app!",
  "data": {"key": "value"}
}
```

#### 43. Get Notification Statistics
```http
GET /api/notifications/stats
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 44. Update Notification Settings
```http
PUT /api/notifications/settings
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "emailNotifications": true,
  "pushNotifications": true,
  "notificationTypes": ["like", "follow", "comment"]
}
```

### Upload Endpoints

#### 45. Upload Profile Image
```http
POST /api/upload/profile
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: multipart/form-data

profileImage: [SELECT FILE]
```

#### 46. Upload Recipe Images
```http
POST /api/upload/recipe
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: multipart/form-data

recipeImages: [SELECT FILES - Multiple]
```

#### 47. Upload Scan Image
```http
POST /api/upload/scan
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: multipart/form-data

scanImage: [SELECT FILE]
```

#### 48. Delete Uploaded File
```http
DELETE /api/upload/profiles/FILENAME
Authorization: Bearer YOUR_JWT_TOKEN
```

#### 49. Get File Information
```http
GET /api/upload/info/profiles/FILENAME
```

#### 50. List Files
```http
GET /api/upload/list/profiles?page=1&limit=20
Authorization: Bearer YOUR_JWT_TOKEN
```

### Testing Workflow

1. **Start with Authentication:**
   - Register a new user (#1)
   - Login to get JWT token (#2)
   - Use the token in Authorization header for protected routes

2. **Test Recipe Features:**
   - Create a recipe (#16)
   - Get all recipes (#14)
   - Like/bookmark the recipe (#19, #20)
   - Rate the recipe (#21)

3. **Test Scanning:**
   - Upload an image for analysis (#23)
   - Check scan result (#24)
   - View scan history (#25)

4. **Test Social Features:**
   - Follow another user (#29)
   - Get social feed (#32)
   - Share a recipe (#35)

5. **Test Notifications:**
   - Get notifications (#37)
   - Mark as read (#38)

### Common Response Formats

#### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

#### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "errors": [ ... ]
}
```

#### Pagination Response
```json
{
  "success": true,
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 100,
    "pages": 10
  }
}
```

### Environment Variables for Testing
Make sure your `.env` file is configured:
```env
MONGODB_URI=mongodb+srv://james:james@cluster0.w5uty7q.mongodb.net/scan2suggest?retryWrites=true&w=majority&appName=Cluster0
JWT_SECRET=scan_2_suggest_secret
JWT_EXPIRES_IN=7d
PORT=3000
NODE_ENV=development
```

## License

This project is licensed under the MIT License.
