import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports enum constants whose `@Flag(expiresAt: ...)` date has passed.
final class ExpiredFeatureFlagRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'expired_feature_flag',
    "Feature flag '{0}' expired on {1}.",
    correctionMessage: 'Remove the flag or explicitly extend its lifecycle.',
    severity: DiagnosticSeverity.ERROR,
  );

  ExpiredFeatureFlagRule()
    : super(
        name: 'expired_feature_flag',
        description: 'Feature flags must be removed by their expiry date.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addEnumConstantDeclaration(this, _Visitor(this, context));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  final ExpiredFeatureFlagRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    for (final annotation in node.metadata) {
      if (annotation.name.name != 'Flag') continue;

      final arguments = annotation.arguments?.arguments;
      if (arguments == null) continue;

      for (final argument in arguments) {
        if (argument is! NamedArgument || argument.name.lexeme != 'expiresAt') {
          continue;
        }

        final expression = argument.argumentExpression;
        if (expression is! SimpleStringLiteral) continue;

        final expiresAt = _parseDate(expression.value);
        if (expiresAt == null || !_isBeforeToday(expiresAt)) continue;

        rule.reportAtToken(
          node.name,
          arguments: [node.name.lexeme, expression.value],
        );
      }
    }
  }

  DateTime? _parseDate(String source) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(source)) return null;
    final parsed = DateTime.tryParse('${source}T00:00:00Z');
    if (parsed == null || parsed.toIso8601String().substring(0, 10) != source) {
      return null;
    }
    return parsed;
  }

  bool _isBeforeToday(DateTime expiresAt) {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    return expiresAt.isBefore(today);
  }
}
