import 'package:feature_flag_annotation/feature_flag_annotation.dart';

enum FeatureFlag {
  @Flag(expiresAt: '2999-12-31', owner: 'checkout-team')
  newCheckout,
}

