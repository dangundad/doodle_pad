import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

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

class AppToast {
  const AppToast._();

  static void show(AppToastMessage message) {
    toastification.show(
      type: _mapType(message.type),
      style: ToastificationStyle.flatColored,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 2),
      showProgressBar: false,
      dragToClose: true,
      title: Text(message.title),
      description: message.description == null
          ? null
          : Text(message.description!),
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
