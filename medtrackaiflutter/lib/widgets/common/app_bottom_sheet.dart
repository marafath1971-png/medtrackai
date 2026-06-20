import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppBottomSheet {
  /// Displays a highly premium, glassmorphic bottom sheet standardized for the 2026 UI overhaul.
  /// Enforces a 32px top-corner radius, subtle blur backdrop, and standardized padding.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useRootNavigator = true,
    Color? backgroundColor,
    double blurSigma = 15.0,
    bool showDragHandle = true,
  }) {
    final L = context.L;
    
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent, // Transparent to allow BackdropFilter to shine
      elevation: 0,
      barrierColor: L.bg.withValues(alpha: 0.6), // Darken background slightly
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? L.card.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(
                  top: BorderSide(color: L.glassBorder, width: 1.0),
                  left: BorderSide(color: L.glassBorder, width: 1.0),
                  right: BorderSide(color: L.glassBorder, width: 1.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: L.text.withValues(alpha: 0.05),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  )
                ],
              ),
              child: SafeArea(
                bottom: false, // Handle safe area internally based on content if needed
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom, // Keyboard support
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showDragHandle)
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            height: 5,
                            width: 48,
                            decoration: BoxDecoration(
                              color: L.text.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      Flexible(
                        child: builder(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
