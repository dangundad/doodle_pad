import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:doodle_pad/app/services/hive_service.dart';
import 'package:doodle_pad/app/utils/app_constants.dart';

class PurchaseService extends GetxService {
  static PurchaseService get to => Get.find();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  final RxBool available = false.obs;
  final RxBool isPremium = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString statusMessage = ''.obs;
  final RxList<ProductDetails> products = <ProductDetails>[].obs;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _initialized = false;

  static Set<String> get productIds {
    if (Platform.isAndroid) {
      return PurchaseConstants.ANDROID_PRODUCT_IDS.toSet();
    }

    return <String>{};
  }

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  @override
  void onClose() {
    _purchaseSubscription?.cancel();
    super.onClose();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadPremiumFromStorage();

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (Object error) {
        debugPrint('Purchase stream error: $error');
        errorMessage.value = error.toString();
      },
    );

    available.value = await _inAppPurchase.isAvailable();
    if (!available.value) {
      statusMessage.value = 'purchase_unavailable'.tr;
      return;
    }

    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!available.value || productIds.isEmpty) return;
    isLoading.value = true;
    statusMessage.value = '';

    try {
      final response = await _inAppPurchase.queryProductDetails(productIds);
      products.assignAll(response.productDetails);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Not found products: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        errorMessage.value = response.error!.message;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint('Failed to load products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String? _productId(int index) {
    if (index < 0 || index >= PurchaseConstants.ANDROID_PRODUCT_IDS.length) {
      return null;
    }
    return PurchaseConstants.ANDROID_PRODUCT_IDS[index];
  }

  ProductDetails? getProductByIndex(int index) {
    final productId = _productId(index);
    if (productId == null) return null;

    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  String getProductPrice(int index, String fallback) {
    final product = getProductByIndex(index);
    return product?.price ?? fallback;
  }

  Future<void> purchaseProduct(int index) async {
    final product = getProductByIndex(index);
    if (!available.value || product == null) {
      if (!available.value) {
        await initialize();
      }

      if (!available.value || product == null) {
        Get.snackbar(
          'purchase_error'.tr,
          'purchase_unavailable'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    try {
      isLoading.value = true;
      final purchaseParam = PurchaseParam(productDetails: product);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      statusMessage.value = 'purchase_failed'.tr;
      errorMessage.value = e.toString();
      isLoading.value = false;

      Get.snackbar(
        'purchase_error'.tr,
        'purchase_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> restorePurchases() async {
    if (!available.value) {
      await initialize();
    }
    if (!available.value) return;

    isLoading.value = true;
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      statusMessage.value = 'restore_error'.tr;
      errorMessage.value = e.toString();

      Get.snackbar(
        'purchase_error'.tr,
        'restore_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          isLoading.value = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _onPurchaseCompleted(purchaseDetails);
          break;
        case PurchaseStatus.error:
          isLoading.value = false;
          _handlePurchaseError(purchaseDetails.error);
          break;
        case PurchaseStatus.canceled:
          isLoading.value = false;
          debugPrint('Purchase canceled by user');
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        try {
          await _inAppPurchase.completePurchase(purchaseDetails);
        } catch (e) {
          debugPrint('completePurchase error: $e');
        }
      }
    }
  }

  void _handlePurchaseError(IAPError? error) {
    errorMessage.value = error?.message ?? 'purchase_failed'.tr;
    Get.snackbar(
      'purchase_error'.tr,
      'purchase_failed'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _onPurchaseCompleted(PurchaseDetails purchaseDetails) async {
    if (!productIds.contains(purchaseDetails.productID)) return;

    isPremium.value = true;
    await _savePremiumStatus(true);
    isLoading.value = false;

    statusMessage.value = 'purchase_success'.tr;
    Get.snackbar(
      'purchase_success'.tr,
      'premium_ready'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.85),
      colorText: Colors.white,
    );
  }

  Future<void> _loadPremiumFromStorage() async {
    try {
      isPremium.value =
          HiveService.to.getSetting<bool>(
            HiveKeys.IS_PREMIUM,
            defaultValue: false,
          ) ??
          false;
    } catch (e) {
      isPremium.value = false;
      errorMessage.value = e.toString();
    }
  }

  Future<void> _savePremiumStatus(bool value) async {
    try {
      await HiveService.to.setSetting(HiveKeys.IS_PREMIUM, value);
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> setPremiumForDebug(bool value) async {
    isPremium.value = value;
    await _savePremiumStatus(value);
  }
}
