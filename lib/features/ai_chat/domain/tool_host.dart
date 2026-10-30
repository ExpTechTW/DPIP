/// The tools the AI service may call — the DPIP MCP server's.
library;

/// One tool as offered to the model: its JSON Schema [parameters] are passed
/// through from the server.
final class ToolSpec {
  const ToolSpec({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;
  final Map<String, Object?> parameters;
}

/// Everything the tool server offers, plus the usage notes it sends with them
/// (units, code formats) that belong in the model's instructions.
final class ToolCatalog {
  const ToolCatalog({required this.tools, this.instructions});

  final List<ToolSpec> tools;
  final String? instructions;
}

/// What a call returned. An error is still returned *to the model* — it can
/// try other arguments or say the data was unavailable — so it is a value,
/// not an exception.
final class ToolOutcome {
  const ToolOutcome(this.content, {this.isError = false});

  final String content;
  final bool isError;
}

abstract class ToolHost {
  /// The tools on offer. Throws an `AiException` when the server cannot be
  /// reached, since nothing useful can be answered without them.
  Future<ToolCatalog> catalog();

  /// Runs one tool. Failures come back as an error [ToolOutcome].
  Future<ToolOutcome> call(String name, Map<String, Object?> arguments);
}
