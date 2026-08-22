import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:feature_flag_lifecycle_plugin/src/expired_feature_flag.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpiredFeatureFlagRuleTest);
  });
}

@reflectiveTest
final class ExpiredFeatureFlagRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ExpiredFeatureFlagRule();
    super.setUp();
  }

  Future<void> test_expired() async {
    await assertDiagnostics(
      r'''
class Flag {
  final String expiresAt;
  const Flag({required this.expiresAt});
}

enum FeatureFlag {
  @Flag(expiresAt: '2000-01-01')
  oldCheckout,
}
''',
      [lint(137, 11)],
    );
  }

  Future<void> test_notExpired() async {
    await assertNoDiagnostics(r'''
class Flag {
  final String expiresAt;
  const Flag({required this.expiresAt});
}

enum FeatureFlag {
  @Flag(expiresAt: '2999-12-31')
  newCheckout,
}
''');
  }
}
