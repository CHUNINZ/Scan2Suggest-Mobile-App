class Recipe {
  final String id;
  final String title;
  final String description;
  final String creator;
  final List<String> images;
  final String category;
  final String cuisine;
  final String difficulty;
  final int prepTime;
  final int cookTime;
  final int servings;
  final List<Ingredient> ingredients;
  final List<Instruction> instructions;
  final Map<String, dynamic>? nutrition;
  final List<String> tags;
  final String? spiceLevel;
  final Map<String, dynamic>? dietaryInfo;
  final List<String> likes;
  final List<String> bookmarks;
  final List<Rating> ratings;
  final double averageRating;
  final int views;
  final bool isPublished;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // User interaction flags (set by API)
  final bool? isLiked;
  final bool? isBookmarked;
  final int? userRating;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.creator,
    this.images = const [],
    required this.category,
    this.cuisine = 'Filipino',
    required this.difficulty,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    this.ingredients = const [],
    this.instructions = const [],
    this.nutrition,
    this.tags = const [],
    this.spiceLevel,
    this.dietaryInfo,
    this.likes = const [],
    this.bookmarks = const [],
    this.ratings = const [],
    this.averageRating = 0.0,
    this.views = 0,
    this.isPublished = true,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
    this.isLiked,
    this.isBookmarked,
    this.userRating,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      creator: json['creator'] is String ? json['creator'] : (json['creator']?['_id'] ?? ''),
      images: List<String>.from(json['images'] ?? []),
      category: json['category'] ?? '',
      cuisine: json['cuisine'] ?? 'Filipino',
      difficulty: json['difficulty'] ?? 'easy',
      prepTime: json['prepTime'] ?? 0,
      cookTime: json['cookTime'] ?? 0,
      servings: json['servings'] ?? 1,
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => Ingredient.fromJson(e))
          .toList() ?? [],
      instructions: (json['instructions'] as List<dynamic>?)
          ?.map((e) => Instruction.fromJson(e))
          .toList() ?? [],
      nutrition: json['nutrition'],
      tags: List<String>.from(json['tags'] ?? []),
      spiceLevel: json['spiceLevel'],
      dietaryInfo: json['dietaryInfo'],
      likes: List<String>.from(json['likes'] ?? []),
      bookmarks: List<String>.from(json['bookmarks'] ?? []),
      ratings: (json['ratings'] as List<dynamic>?)
          ?.map((e) => Rating.fromJson(e))
          .toList() ?? [],
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      views: json['views'] ?? 0,
      isPublished: json['isPublished'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isLiked: json['isLiked'],
      isBookmarked: json['isBookmarked'],
      userRating: json['userRating'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creator': creator,
      'images': images,
      'category': category,
      'cuisine': cuisine,
      'difficulty': difficulty,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'instructions': instructions.map((e) => e.toJson()).toList(),
      'nutrition': nutrition,
      'tags': tags,
      'spiceLevel': spiceLevel,
      'dietaryInfo': dietaryInfo,
      'likes': likes,
      'bookmarks': bookmarks,
      'ratings': ratings.map((e) => e.toJson()).toList(),
      'averageRating': averageRating,
      'views': views,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
      'userRating': userRating,
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    String? creator,
    List<String>? images,
    String? category,
    String? cuisine,
    String? difficulty,
    int? prepTime,
    int? cookTime,
    int? servings,
    List<Ingredient>? ingredients,
    List<Instruction>? instructions,
    Map<String, dynamic>? nutrition,
    List<String>? tags,
    String? spiceLevel,
    Map<String, dynamic>? dietaryInfo,
    List<String>? likes,
    List<String>? bookmarks,
    List<Rating>? ratings,
    double? averageRating,
    int? views,
    bool? isPublished,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLiked,
    bool? isBookmarked,
    int? userRating,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creator: creator ?? this.creator,
      images: images ?? this.images,
      category: category ?? this.category,
      cuisine: cuisine ?? this.cuisine,
      difficulty: difficulty ?? this.difficulty,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      nutrition: nutrition ?? this.nutrition,
      tags: tags ?? this.tags,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      dietaryInfo: dietaryInfo ?? this.dietaryInfo,
      likes: likes ?? this.likes,
      bookmarks: bookmarks ?? this.bookmarks,
      ratings: ratings ?? this.ratings,
      averageRating: averageRating ?? this.averageRating,
      views: views ?? this.views,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      userRating: userRating ?? this.userRating,
    );
  }

  int get totalTime => prepTime + cookTime;
  int get likesCount => likes.length;
  int get bookmarksCount => bookmarks.length;
  int get ratingsCount => ratings.length;
}

class Ingredient {
  final String name;
  final String amount;
  final String unit;
  final String? notes;

  Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.notes,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      amount: json['amount'] ?? '',
      unit: json['unit'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'notes': notes,
    };
  }
}

class Instruction {
  final int step;
  final String instruction;
  final int? duration;
  final String? image;

  Instruction({
    required this.step,
    required this.instruction,
    this.duration,
    this.image,
  });

  factory Instruction.fromJson(Map<String, dynamic> json) {
    return Instruction(
      step: json['step'] ?? 1,
      instruction: json['instruction'] ?? '',
      duration: json['duration'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'instruction': instruction,
      'duration': duration,
      'image': image,
    };
  }
}

class Rating {
  final String user;
  final int rating;
  final String? review;
  final DateTime createdAt;

  Rating({
    required this.user,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      user: json['user'] is String ? json['user'] : (json['user']?['_id'] ?? ''),
      rating: json['rating'] ?? 1,
      review: json['review'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'rating': rating,
      'review': review,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
