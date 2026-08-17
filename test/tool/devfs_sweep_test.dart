/// `tool/run.sh`'s DevFS sweep — the one thing in this repo that calls
/// `rm -rf` on a path built from a glob.
///
/// Two failures matter and neither announces itself. A glob that reaches one
/// component too far deletes somebody's app data; a sweep that runs while a
/// `flutter run` is attached deletes the kernel that run is executing from, and
/// the damage there is silent — the dills grow back, so the mistake looks
/// harmless, while the synced asset bundle does not and a shader edit quietly
/// reverts on the next restart.
///
/// So these run the real function out of the real script against a fake
/// simulator tree, and check what it deleted and what it refused to touch.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sources `tool/run.sh`'s sweep with `$HOME` pointed at [home], and returns
/// what the script printed.
///
/// The script is sourced rather than executed: the sweep has to be the code
/// that actually ships, not a copy of it in this file that can drift. `mise` is
/// stubbed so sourcing stops short of launching anything.
///
/// `pgrep` is stubbed too, and that is not a shortcut — it is the only thing
/// that makes these tests mean anything. Left real, every one of them would
/// pass by accident on a machine with a `flutter run` attached, because the
/// sweep would correctly refuse to do anything at all. [running] is what the
/// guard sees.
ProcessResult sweepIn(Directory home, {bool running = false}) {
  final root = Directory.current.path;
  return Process.runSync('bash', [
    '-c',
    'set -euo pipefail\n'
        'mise() { :; }\n'
        'pgrep() { return ${running ? 0 : 1}; }\n'
        'HOME=${_q(home.path)}\n'
        'source ${_q('$root/tool/run.sh')} >/dev/null 2>/tmp/dpip_sweep_err\n'
        'cat /tmp/dpip_sweep_err\n',
  ]);
}

String _q(String s) => "'${s.replaceAll("'", r"'\''")}'";

/// A simulator tree with one container holding [leaked] DevFS roots.
Directory fakeHome({int leaked = 2, List<String> decoys = const []}) {
  final home = Directory.systemTemp.createTempSync('dpiphome');
  addTearDown(() => home.deleteSync(recursive: true));
  final tmp = Directory(
    '${home.path}/Library/Developer/CoreSimulator/Devices/DEV-1/data'
    '/Containers/Data/Application/APP-1/tmp',
  )..createSync(recursive: true);
  for (var i = 0; i < leaked; i++) {
    // Six characters after the prefix, which is what the VM's `createTemp`
    // produces.
    Directory('${tmp.path}/DPIP${'abcdef'.substring(0, 5)}$i')
      ..createSync()
      ..childFile('main.dart.dill');
  }
  for (final decoy in decoys) {
    Directory('${tmp.path}/$decoy').createSync(recursive: true);
  }
  return home;
}

extension on Directory {
  void childFile(String name) =>
      File('$path/$name').writeAsStringSync('kernel');
}

List<String> namesIn(Directory home) {
  final tmp = Directory(
    '${home.path}/Library/Developer/CoreSimulator/Devices/DEV-1/data'
    '/Containers/Data/Application/APP-1/tmp',
  );
  return tmp.listSync().map((e) => e.path.split('/').last).toList()..sort();
}

void main() {
  test('leaked DevFS roots are swept and the freed space is reported', () {
    final home = fakeHome(leaked: 3);

    final result = sweepIn(home);

    expect(namesIn(home), isEmpty);
    expect(result.stdout, contains('swept 3 leaked DevFS dirs'));
  });

  test('a container tmp holding nothing DevFS-shaped is left alone', () {
    // Every one of these is something the app or the OS put there. The sweep
    // names exactly one shape and must not widen to "things in tmp".
    final home = fakeHome(
      leaked: 0,
      decoys: [
        'DPIP', // the prefix alone — no random suffix
        'DPIPtooLongToBeSix',
        'DPIPabc', // three characters, not six
        'com.apple.something',
        'MapLibreTiles',
      ],
    );

    sweepIn(home);

    expect(namesIn(home), [
      'DPIP',
      'DPIPabc',
      'DPIPtooLongToBeSix',
      'MapLibreTiles',
      'com.apple.something',
    ]);
  });

  test('nothing outside a container tmp is reachable', () {
    final home = fakeHome(leaked: 1);
    // The two neighbours a wrong glob would reach: a sibling of `tmp/` inside
    // the same container, and a DevFS-shaped directory one level up.
    Directory(
      '${home.path}/Library/Developer/CoreSimulator/Devices/DEV-1/data'
      '/Containers/Data/Application/APP-1/Library/DPIPabcde0',
    ).createSync(recursive: true);
    Directory(
      '${home.path}/Library/Developer/CoreSimulator/Devices/DEV-1/data'
      '/Containers/Data/Application/DPIPabcde1',
    ).createSync(recursive: true);

    sweepIn(home);

    expect(
      Directory(
        '${home.path}/Library/Developer/CoreSimulator/Devices/DEV-1/data'
        '/Containers/Data/Application/APP-1/Library/DPIPabcde0',
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory(
        '${home.path}/Library/Developer/CoreSimulator/Devices/DEV-1/data'
        '/Containers/Data/Application/DPIPabcde1',
      ).existsSync(),
      isTrue,
    );
  });

  test('a live flutter run stops the sweep dead', () {
    final home = fakeHome(leaked: 3);

    final result = sweepIn(home, running: true);

    // The kernel the other terminal is executing from is in one of these.
    expect(namesIn(home), hasLength(3));
    expect(result.stdout, isEmpty);
  });

  test('no simulator directory at all is a silent no-op', () {
    final home = Directory.systemTemp.createTempSync('dpipbare');
    addTearDown(() => home.deleteSync(recursive: true));

    final result = sweepIn(home);

    // Silent, not merely harmless: a launcher that narrates on every start
    // gets skipped over, and this line has to be readable when it does appear.
    expect(result.stdout, isEmpty);
    expect(result.exitCode, 0);
  });

  test('an empty match does not hand the pattern itself to rm', () {
    final home = fakeHome(leaked: 0);

    final result = sweepIn(home);

    // Without `nullglob` the unmatched pattern survives as a literal, `du`
    // fails on it, and `set -e` takes the launcher down before it launches.
    expect(result.exitCode, 0);
    expect(result.stdout, isEmpty);
  });
}
