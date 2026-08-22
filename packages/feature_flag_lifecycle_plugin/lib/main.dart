import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/expired_feature_flag.dart';

/// Entrypoint discovered by the Dart analysis server.
final plugin = FeatureFlagLifecyclePlugin();

final class FeatureFlagLifecyclePlugin extends Plugin {
  @override
  String get name => 'Feature Flag Lifecycle';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(ExpiredFeatureFlagRule());
  }
}
