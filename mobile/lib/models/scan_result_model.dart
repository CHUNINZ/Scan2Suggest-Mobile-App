class ScanResult {
  final String id;
  final String user;
  final String scanType;
  final String originalImage;
  final String? processedImage;
  final List<DetectedItem> detectedItems;
  final List<String> suggestedRecipes;
  final int? processingTime;
  final String apiProvider;
  final String status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScanResult({
    required this.id,
    required this.user,
    required this.scanType,
    required this.originalImage,
    this.processedImage,
    this.detectedItems = const [],
    this.suggestedRecipes = const [],
    this.processingTime,
    this.apiProvider = 'internal',
    this.status = 'processing',
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['_id'] ?? json['id'] ?? '',
      user: json['user'] is String ? json['user'] : (json['user']?['_id'] ?? ''),
      scanType: json['scanType'] ?? 'food',
      originalImage: json['originalImage'] ?? '',
      processedImage: json['processedImage'],
      detectedItems: (json['detectedItems'] as List<dynamic>?)
          ?.map((e) => DetectedItem.fromJson(e))
          .toList() ?? [],
      suggestedRecipes: List<String>.from(json['suggestedRecipes'] ?? []),
      processingTime: json['processingTime'],
      apiProvider: json['apiProvider'] ?? 'internal',
      status: json['status'] ?? 'processing',
      errorMessage: json['errorMessage'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'scanType': scanType,
      'originalImage': originalImage,
      'processedImage': processedImage,
      'detectedItems': detectedItems.map((e) => e.toJson()).toList(),
      'suggestedRecipes': suggestedRecipes,
      'processingTime': processingTime,
      'apiProvider': apiProvider,
      'status': status,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing';
}

class DetectedItem {
  final String name;
  final double confidence;
  final String category;
  final BoundingBox? boundingBox;

  DetectedItem({
    required this.name,
    required this.confidence,
    required this.category,
    this.boundingBox,
  });

  factory DetectedItem.fromJson(Map<String, dynamic> json) {
    return DetectedItem(
      name: json['name'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      category: json['category'] ?? 'ingredient',
      boundingBox: json['boundingBox'] != null 
          ? BoundingBox.fromJson(json['boundingBox'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'confidence': confidence,
      'category': category,
      'boundingBox': boundingBox?.toJson(),
    };
  }

  String get confidencePercentage => '${(confidence * 100).toInt()}%';
}

class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      width: (json['width'] ?? 0.0).toDouble(),
      height: (json['height'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}
