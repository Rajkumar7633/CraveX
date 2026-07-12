import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';

class AppBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool isDismissible = true,
    double? maxHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.9,
      ),
    );
  }

  static Future<T?> showDraggable<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    List<Widget>? actions,
    double? initialChildSize,
    double? minChildSize,
    double? maxChildSize,
  }) {
    return show<T>(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: initialChildSize ?? 0.5,
        minChildSize: minChildSize ?? 0.3,
        maxChildSize: maxChildSize ?? 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXLarge),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.mediumGrey,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
                ),
              ),
              // Header
              if (title != null || actions != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing16,
                    vertical: AppTheme.spacing8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (actions != null) ...actions,
                    ],
                  ),
                ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
