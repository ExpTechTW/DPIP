/// One-time move of the conversation log from `SharedPreferences` to SQLite.
///
/// The log used to be a list of JSON strings under one prefs key. Dropping it
/// would have thrown away the user's messages on upgrade, so it is imported
/// once and the key removed — which is also what makes this self-terminating:
/// after the first successful run there is nothing left to find.
library;

import 'dart:convert';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/settings/preference_keys.dart';
import 'package:dpip/core/settings/prefs.dart';

Future<void> migrateLegacyMeshLog(Prefs prefs, MeshStore store) async {
  final stored = prefs.getStringList(PreferenceKeys.meshMessages);
  if (stored == null || stored.isEmpty) {
    // Still clear the key: an empty list is residue too.
    if (stored != null) await prefs.remove(PreferenceKeys.meshMessages);
    return;
  }
  var imported = 0;
  for (final entry in stored) {
    final message = _decode(entry);
    if (message == null) continue;
    if (await store.addMessage(message)) imported++;
  }
  await prefs.remove(PreferenceKeys.meshMessages);
  Log.info('mesh log: migrated $imported message(s) to SQLite');
}

MeshStoredMessage? _decode(String encoded) {
  try {
    final json = jsonDecode(encoded);
    if (json is! Map<String, dynamic>) return null;
    return MeshStoredMessage(
      from: (json['f'] as num?)?.toInt() ?? 0,
      channel: (json['c'] as num?)?.toInt() ?? 0,
      text: json['t'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['ts'] as num?)?.toInt() ?? 0,
      ),
      outgoing: json['o'] as bool? ?? false,
    );
  } catch (_) {
    return null;
  }
}
