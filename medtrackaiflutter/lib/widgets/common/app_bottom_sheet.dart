import 'package:flutter/material.dart';

import '../../theme/med_ai_ui.dart';

class AppBottomSheet {
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: L.bg.withValues(alpha: 0.6),
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.squircle)),
          child: MedAiGlass(
            radius: AppRadius.squircle,
            blur: blurSigma,
            tint: backgroundColor ?? L.card,
            showBorder: false,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
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
                  Flexible(child: builder(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
