import 'package:feature_flag_annotation/feature_flag_annotation.dart';

enum FeatureFlag {
  @Flag(expiresAt: '2000-01-01', owner: 'checkout-team')
  oldCheckout,
}

