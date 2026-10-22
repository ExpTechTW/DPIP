import 'package:dpip/features/ai_chat/domain/ai_connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ({String? url, BaseUrlProblem? problem}) norm(String input) =>
      normalizeBaseUrl(input);

  test('a pasted endpoint, slashes and spaces reduce to the API root', () {
    expect(
      norm('  https://api.openai.com/v1/  ').url,
      'https://api.openai.com/v1',
    );
    expect(
      norm('https://api.openai.com/v1/chat/completions').url,
      'https://api.openai.com/v1',
    );
    expect(
      norm('https://openrouter.ai/api/v1/chat/completions/').url,
      'https://openrouter.ai/api/v1',
    );
  });

  test('plain http is refused, except to this phone', () {
    expect(
      norm('http://192.168.1.5:11434/v1').problem,
      BaseUrlProblem.insecure,
    );
    expect(norm('http://localhost:11434/v1').url, 'http://localhost:11434/v1');
    expect(norm('http://127.0.0.1:8080/v1').url, 'http://127.0.0.1:8080/v1');
  });

  test('empty and non-URLs are named as such', () {
    expect(norm('   ').problem, BaseUrlProblem.empty);
    expect(norm('api.openai.com/v1').problem, BaseUrlProblem.invalid);
    expect(norm('ftp://example.com').problem, BaseUrlProblem.invalid);
  });

  test('every preset is already a clean root', () {
    for (final preset in aiPresets) {
      expect(norm(preset.baseUrl).url, preset.baseUrl, reason: preset.name);
    }
  });

  test('a connection needs both a URL and a model', () {
    expect(AiConnection.empty.isComplete, isFalse);
    expect(
      const AiConnection(baseUrl: 'https://x/v1', model: '').isComplete,
      isFalse,
    );
    expect(
      const AiConnection(baseUrl: 'https://x/v1', model: 'm').isComplete,
      isTrue,
    );
  });
}
