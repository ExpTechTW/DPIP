/// The instructions every AI chat request opens with.
///
/// English whatever the UI language: models follow English instructions most
/// reliably, and the reply language is set explicitly below.
library;

/// A township the user has in the app, named and coded for the tools.
final class PromptPlace {
  const PromptPlace({
    required this.name,
    required this.code,
    required this.current,
  });

  final String name;

  /// The 3-digit township (postal) code the tools take.
  final String code;

  /// Whether this is where the phone is now (所在地), not a saved place.
  final bool current;
}

/// Builds the system prompt.
///
/// [taipeiNow] is a calibrated instant whose fields read as Taipei wall time
/// (`AppTime.utc8`): the model has no clock, and "today" or "the quake an
/// hour ago" means nothing without one. [places] are township names and codes
/// only — never coordinates. [serverNotes] is the tool server's own usage
/// guide (units, scales, code formats).
String buildSystemPrompt({
  required DateTime taipeiNow,
  required String language,
  required String localeTag,
  required List<PromptPlace> places,
  String? serverNotes,
}) {
  final buffer = StringBuffer()
    ..writeln(
      'You are the assistant inside DPIP, a disaster-information app for '
      'Taiwan by ExpTech Studio. You help people understand earthquakes, '
      'earthquake early warnings, weather, rain, typhoons, tsunamis and '
      'disaster notices.',
    )
    ..writeln()
    ..writeln(
      '- Look the data up with the tools before answering anything about '
      'current or past conditions. Never guess or invent numbers, times or '
      'places; if a tool fails or finds nothing, say so plainly.',
    )
    ..writeln('- Say how recent the data is, from its own time or fetched_at.')
    ..writeln(
      '- You are not an official warning service and you can be wrong. When '
      'someone may be in danger, tell them briefly to protect themselves first '
      'and to follow official alerts and instructions from the Central Weather '
      'Administration (CWA) and local authorities.',
    )
    ..writeln(
      '- Answers are read on a phone: keep them short. Use simple Markdown '
      '(short lists, bold); avoid wide tables and code blocks.',
    )
    ..writeln(
      '- Reply in $language ($localeTag) unless the user writes in another '
      'language.',
    )
    ..writeln()
    ..writeln('Current time: ${_format(taipeiNow)} (Asia/Taipei, UTC+8).');

  if (places.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln("The user's places in the app (township codes for the tools):");
    for (final place in places) {
      final label = place.current ? 'Current location' : 'Saved';
      buffer.writeln('- $label: ${place.name} (${place.code})');
    }
    buffer.writeln(
      'When the user says "here", "my area" or similar without naming a '
      'place, use the current location, or the first saved place if there '
      'is no current location.',
    );
  }

  final notes = serverNotes?.trim();
  if (notes != null && notes.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('Notes from the data server:')
      ..writeln(notes);
  }
  return buffer.toString().trimRight();
}

String _format(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return '${t.year}-${two(t.month)}-${two(t.day)} ${weekdays[t.weekday - 1]} '
      '${two(t.hour)}:${two(t.minute)}';
}
