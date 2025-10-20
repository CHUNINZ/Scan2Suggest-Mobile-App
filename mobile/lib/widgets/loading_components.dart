import 'package:flutter/material.dart';

/// Reusable loading components for better UX during AI processing
class LoadingComponents {
  
  /// AI Processing loading indicator with animated steps
  static Widget aiProcessingLoader({
    required String title,
    required List<String> steps,
    required Animation<double> animation,
    IconData? icon,
    Color? primaryColor,
    Color? backgroundColor,
  }) {
    final color = primaryColor ?? Colors.green;
    // final bgColor = backgroundColor ?? Colors.white; // Reserved for future use
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enhanced AI processing indicator
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                if (icon != null)
                  Center(
                    child: Icon(
                      icon,
                      color: color,
                      size: 40,
                    ),
                  ),
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.green,
                    strokeWidth: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // AI Processing text with animation
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Opacity(
                opacity: (0.7 + (animation.value * 0.3)).clamp(0.0, 1.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Processing steps
          _buildProcessingSteps(steps, animation),
          
          const SizedBox(height: 24),
          
          // Progress indicator
          _buildProgressIndicator(animation, color),
          
          const SizedBox(height: 16),
          
          Text(
            'This may take a few seconds...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Full-screen AI processing overlay
  static Widget aiProcessingOverlay({
    required String title,
    required List<String> steps,
    required Animation<double> animation,
    IconData? icon,
    Color? primaryColor,
  }) {
    final color = primaryColor ?? Colors.green;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced AI processing indicator
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (icon != null)
                    Center(
                      child: Icon(
                        icon,
                        color: color,
                        size: 50,
                      ),
                    ),
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeWidth: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // AI Processing text with animation
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Opacity(
                  opacity: (0.7 + (animation.value * 0.3)).clamp(0.0, 1.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Processing steps
            _buildOverlayProcessingSteps(steps, animation),
            
            const SizedBox(height: 24),
            
            // Progress indicator
            _buildOverlayProgressIndicator(animation, color),
            
            const SizedBox(height: 16),
            
            Text(
              'This may take a few seconds...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Simple loading indicator with text
  static Widget simpleLoader({
    required String text,
    Color? color,
    double? size,
  }) {
    final loaderColor = color ?? Colors.green;
    final loaderSize = size ?? 50.0;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: loaderSize,
            height: loaderSize,
            child: CircularProgressIndicator(
              color: loaderColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton loading for lists
  static Widget skeletonList({
    int itemCount = 3,
    double itemHeight = 80.0,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          height: itemHeight,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildSkeletonItem(),
        );
      },
    );
  }

  /// Skeleton loading for cards
  static Widget skeletonCards({
    int itemCount = 6,
    bool isGrid = true,
  }) {
    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildSkeletonCard(),
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildSkeletonCard(),
          );
        },
      );
    }
  }

  // Private helper methods
  static Widget _buildProcessingSteps(List<String> steps, Animation<double> animation) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final isActive = animation.value > (index * (1.0 / steps.length));
                  return Icon(
                    isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isActive ? Colors.green : Colors.grey[400],
                    size: 16,
                  );
                },
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final isActive = animation.value > (index * (1.0 / steps.length));
                  return Text(
                    step,
                    style: TextStyle(
                      color: isActive ? Colors.black87 : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static Widget _buildOverlayProcessingSteps(List<String> steps, Animation<double> animation) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final isActive = animation.value > (index * (1.0 / steps.length));
                  return Icon(
                    isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isActive ? Colors.green : Colors.white.withOpacity(0.5),
                    size: 16,
                  );
                },
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final isActive = animation.value > (index * (1.0 / steps.length));
                  return Text(
                    step,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static Widget _buildProgressIndicator(Animation<double> animation, Color color) {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildOverlayProgressIndicator(Animation<double> animation, Color color) {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildSkeletonItem() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSkeletonCard() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 12,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
