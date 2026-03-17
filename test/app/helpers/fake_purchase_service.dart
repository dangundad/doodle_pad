import 'package:get/get.dart';

import 'package:doodle_pad/app/services/purchase_service.dart';

class FakePurchaseService extends GetxService implements PurchaseService {
  @override
  final RxBool isPremium = false.obs;

  @override
  final RxBool isDevPremium = false.obs;

  @override
  bool get hasActivePremium => isPremium.value || isDevPremium.value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
