import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AsyncStatusCard extends StatelessWidget {
  const AsyncStatusCard({
    required this.isLoading,
    required this.error,
    required this.loadingMessage,
    required this.errorTitle,
    required this.onRetry,
    super.key,
  });

  final bool isLoading;
  final String? error;
  final String loadingMessage;
  final String errorTitle;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && error == null) {
      return const SizedBox.shrink();
    }

    final hasError = error != null;
    final color = hasError ? AppColors.danger : AppColors.primaryDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: hasError
                ? Icon(Icons.cloud_off_rounded, color: color, size: 22)
                : SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: color,
                    ),
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError ? errorTitle : loadingMessage,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (hasError) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Check your connection and try again. '
                    'Cached information remains available.',
                    style: TextStyle(
                      color: AppColors.lightTextSecondary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasError) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => onRetry(),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
