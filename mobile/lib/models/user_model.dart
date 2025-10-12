class User {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? location;
  final String? profileImage;
  final List<String> followers;
  final List<String> following;
  final List<String> bookmarkedRecipes;
  final List<String> likedRecipes;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? stats;
  final DateTime createdAt;
  final DateTime? lastActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.location,
    this.profileImage,
    this.followers = const [],
    this.following = const [],
    this.bookmarkedRecipes = const [],
    this.likedRecipes = const [],
    this.preferences,
    this.stats,
    required this.createdAt,
    this.lastActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      location: json['location'],
      profileImage: json['profileImage'],
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      bookmarkedRecipes: List<String>.from(json['bookmarkedRecipes'] ?? []),
      likedRecipes: List<String>.from(json['likedRecipes'] ?? []),
      preferences: json['preferences'],
      stats: json['stats'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bio': bio,
      'location': location,
      'profileImage': profileImage,
      'followers': followers,
      'following': following,
      'bookmarkedRecipes': bookmarkedRecipes,
      'likedRecipes': likedRecipes,
      'preferences': preferences,
      'stats': stats,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? bio,
    String? location,
    String? profileImage,
    List<String>? followers,
    List<String>? following,
    List<String>? bookmarkedRecipes,
    List<String>? likedRecipes,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? stats,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      profileImage: profileImage ?? this.profileImage,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      bookmarkedRecipes: bookmarkedRecipes ?? this.bookmarkedRecipes,
      likedRecipes: likedRecipes ?? this.likedRecipes,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
