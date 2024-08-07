import 'package:macros/macros.dart';

extension BuilderX on Builder {
  reportError(String message, DiagnosticTarget target) {
    report(
      Diagnostic(
        DiagnosticMessage(
          message,
          target: target,
        ),
        Severity.error,
      ),
    );
  }

  reportWarning(String message, DiagnosticTarget target) {
    report(
      Diagnostic(
        DiagnosticMessage(
          message,
          target: target,
        ),
        Severity.warning,
      ),
    );
  }

  reportInfo(String message, DiagnosticTarget target) {
    report(
      Diagnostic(
        DiagnosticMessage(
          message,
          target: target,
        ),
        Severity.info,
      ),
    );
  }
}
