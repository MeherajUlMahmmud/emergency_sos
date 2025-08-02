import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoadingWidgets {
  static Widget circularProgress({
    Color? color,
    double size = 40.0,
  }) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          color: color ?? AppTheme.primaryRed,
          strokeWidth: 3.0,
        ),
      ),
    );
  }

  static Widget linearProgress({
    Color? color,
    double height = 4.0,
  }) {
    return LinearProgressIndicator(
      color: color ?? AppTheme.primaryRed,
      backgroundColor: Colors.grey.shade300,
      minHeight: height,
    );
  }

  static Widget skeletonCard({
    double height = 100.0,
    double width = double.infinity,
  }) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
          ),
        ),
      ),
    );
  }

  static Widget skeletonList({int itemCount = 3}) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => skeletonCard(),
    );
  }

  static Widget skeletonHomeScreen() {
    return Column(
      children: [
        // App bar skeleton
        Container(
          height: 60,
          color: Colors.grey.shade200,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 100,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        // Content skeleton
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // SOS button skeleton
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                const SizedBox(height: 32),
                // Action buttons skeleton
                for (int i = 0; i < 2; i++) ...[
                  Container(
                    width: double.infinity,
                    height: 56,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget overlayLoading({
    required Widget child,
    bool isLoading = false,
    String? message,
  }) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 