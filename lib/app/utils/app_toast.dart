import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

import 'package:doodle_pad/app/theme/app_theme.dart';

enum AppToastType { success, error, info }

class AppToastMessage {
  const AppToastMessage({
    required this.type,
    required this.title,
    this.description,
  });

  const AppToastMessage.success({required String title, String? description})
    : this(type: AppToastType.success, title: title, description: description);

  const AppToastMessage.error({required String title, String? description})
    : this(type: AppToastType.error, title: title, description: description);

  const AppToastMessage.info({required String title, String? description})
    : this(type: AppToastType.info, title: title, description: description);

  final AppToastType type;
  final String title;
  final String? description;
}

/// 앱 공통 토스트.
///
/// toastification 기본 `flatColored`(초록/빨강 큰 테두리)는 종이+잉크 테마와
/// 어긋나 실기기에서 튀어 보였다. 표면색 카드 + 헤어라인 + 의미색 아이콘만 쓴다.
class AppToast {
  const AppToast._();

  static void show(AppToastMessage message) {
    final cs = Get.theme.colorScheme;
    final (icon, iconColor) = switch (message.type) {
      AppToastType.success => (LucideIcons.circleCheck, cs.tertiary),
      AppToastType.error => (LucideIcons.circleAlert, cs.error),
      AppToastType.info => (LucideIcons.info, cs.primary),
    };

    toastification.show(
      type: _mapType(message.type),
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 2),
      showProgressBar: false,
      dragToClose: true,
      applyBlurEffect: false,
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      primaryColor: iconColor,
      borderSide: BorderSide(color: cs.outlineVariant),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.10),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
      icon: Icon(icon, size: 22, color: iconColor),
      title: Text(
        message.title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      description: message.description == null
          ? null
          : Text(
              message.description!,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
      closeButton: const ToastCloseButton(
        showType: CloseButtonShowType.onHover,
      ),
    );
  }

  static ToastificationType _mapType(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        return ToastificationType.success;
      case AppToastType.error:
        return ToastificationType.error;
      case AppToastType.info:
        return ToastificationType.info;
    }
  }
}
