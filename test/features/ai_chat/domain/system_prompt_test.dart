import 'package:dpip/features/ai_chat/domain/system_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A UTC-flagged instant whose fields read as Taipei wall time, as
  // AppTime.utc8 gives it.
  final now = DateTime.utc(2026, 10, 22, 5, 41);

  test('carries the time, the reply language and the places', () {
    final prompt = buildSystemPrompt(
      taipeiNow: now,
      language: '繁體中文',
      localeTag: 'zh-TW',
      places: const [
        PromptPlace(name: '臺北市 中正區', code: '100', current: true),
        PromptPlace(name: '高雄市 苓雅區', code: '802', current: false),
      ],
      serverNotes: '  Times are Unix seconds.  ',
    );
    expect(
      prompt,
      contains('Current time: 2026-10-22 Thursday 05:41 (Asia/Taipei, UTC+8).'),
    );
    expect(prompt, contains('Reply in 繁體中文 (zh-TW)'));
    expect(prompt, contains('- Current location: 臺北市 中正區 (100)'));
    expect(prompt, contains('- Saved: 高雄市 苓雅區 (802)'));
    expect(
      prompt,
      endsWith('Notes from the data server:\nTimes are Unix seconds.'),
    );
    expect(prompt, contains('not an official warning service'));
  });

  test('says nothing about places or notes it does not have', () {
    final prompt = buildSystemPrompt(
      taipeiNow: now,
      language: 'English',
      localeTag: 'en',
      places: const [],
    );
    expect(prompt, isNot(contains("user's places")));
    expect(prompt, isNot(contains('Notes from the data server')));
  });
}
