import 'package:dpip/features/ai_chat/data/think_filter.dart';
import 'package:flutter_test/flutter_test.dart';

String run(List<String> deltas) {
  final filter = ThinkFilter();
  final out = StringBuffer();
  for (final delta in deltas) {
    out.write(filter.add(delta));
  }
  out.write(filter.flush());
  return out.toString();
}

void main() {
  test('an answer without a reasoning block passes through', () {
    expect(run(['目前', '沒有']), '目前沒有');
  });

  test('a block that opens the answer is hidden, even split up', () {
    expect(run(['  <th', 'ink>想', '一想</thi', 'nk>\n\n答', '案']), '答案');
  });

  test('the tag anywhere else is just text', () {
    expect(run(['看 <think> 這個']), '看 <think> 這個');
  });

  test('a reply too short to be the tag is still the reply', () {
    expect(run(['<t']), '<t');
  });

  test('an unfinished block shows nothing', () {
    final filter = ThinkFilter();
    expect(filter.add('<think>還在想'), '');
    expect(filter.thinking, isTrue);
    expect(filter.flush(), '');
  });
}
