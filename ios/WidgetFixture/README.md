# Widget fixture UI tests

Run the existing fixture and XCUITest scheme on an iOS simulator:

```sh
DPIP_IOS_SIMULATOR=<UDID> tool/dev/test_widget_ui.sh \
  -parallel-testing-enabled NO \
  -derivedDataPath /tmp/dpip-widget-ui-build \
  -resultBundlePath /tmp/dpip-widget-ui.xcresult
```

Use fresh build and result paths for each recorded run. Use
`-only-testing:WidgetFixtureUITests/MediumWeatherUITests/<test>` for a focused
case. No accessibility settings need to be enabled before running XCUITest.

The fixture compiles the production Small, Medium and Large weather views
and their String Catalog directly. Neither fixture target is embedded in
Runner or its widget extension. Set these environment variables on the
fixture process (the UI tests use `XCUIApplication.launchEnvironment`):

| Variable | Values (default first) |
| --- | --- |
| `DPIP_FIXTURE_FAMILY` | `medium`, `large`, `small` |
| `DPIP_FIXTURE_FORECAST` | `stale`, `fresh`, `expired`, `unavailable` |
| `DPIP_FIXTURE_LANGUAGE` | `en`, `zh-Hant`, `zh-Hans`, `ja`, `ko` |
| `DPIP_FIXTURE_TEXT_SIZE` | `normal` (.large), `xSmall`, `small`, `medium`, `larger` (.xLarge), `xxLarge`, `xxxLarge`, `accessibility` (.accessibility1), `accessibility2`–`accessibility5` |
| `DPIP_FIXTURE_LOCATION` | `short` (Taichung Xitun), `compact` (Xitun), `long` (Taichung City Xitun District Shuinan Central Park), `xitun` (西屯), `longChinese` (臺中市西屯區臺灣大道三段), `longJapanese` (東京都千代田区丸の内一丁目), `shortJapanese` (丸の内), `shortKorean` (시툰) |
| `DPIP_FIXTURE_CARD` | `narrow`, `wide`. Medium: 338 × 158 and 364 × 170 pt. Large: 319 × 318 and 350 × 365 pt. Small: 158 × 158 and 170 × 170 pt. |
| `DPIP_FIXTURE_DARK` | `0` (light), `1` (dark) |
| `DPIP_FIXTURE_SMALL_OBSERVATION` | `regular`, `heavyRain`, `dry`, `missingValues`, `noSnapshot` |

The fixture uses a fixed September 25, 2026 entry (15:21 in Asia/Taipei) and
a distinct observation time (14:21). Fresh, stale and expired forecasts use
the same points with publication ages of 15, 45 and 135 minutes respectively;
unavailable supplies no forecast. Medium and Large keep the current observation
in all four forecast states.
The selected localization bundle and SwiftUI Locale drive the widget strings
and time formatting. The system UI language is not switched.

### Small weather observations

`DPIP_FIXTURE_SMALL_OBSERVATION` selects the current weather scenario for
the Small widget. The displayed rainfall examples below use English formatting.

| Value | Observation |
| --- | --- |
| `regular` | 32°, 100% humidity, 123.4 mm rainfall. |
| `heavyRain` | 32°, 100% humidity, 1,234.5 mm rainfall. |
| `dry` | 32°, 0% humidity, 0.0 mm rainfall. |
| `missingValues` | The snapshot retains the location, observation time and weather condition. Temperature, humidity and rainfall are all absent and display as `--°`, `--%` and `-- mm`. |
| `noSnapshot` | No observation snapshot. The card shows a cloud icon and the localized no-weather-data message. |

### Layout and accessibility checks

Each card has 16 pt margins. An independent sibling marks the full card
bounds. For Medium and Large, the tests exercise all twelve text sizes at
both card dimensions, alternating English, Traditional Chinese and Japanese
and light/dark appearance. Narrow cases use long names. Additional scenarios
cover the warning text versus icon and all forecast freshness states.

The warning appears once, immediately before the observation time in the
header and in the accessibility tree. The tests require accessibility forecasts to remain within
the content margins. Regular Dynamic Type layouts may use
the lower margin, but all forecast values and refresh controls
must remain fully within the widget card. Large
weather details must follow the forecast and omit the lowest priority rows
first when space runs out. The forecast keeps the same five slots and
vertical order (time, condition, temperature and probability) at every
text size; tests assert this order and alignment.
Fresh forecasts have no refresh action or warning; expired and unavailable
forecasts keep the refresh action without a warning.

Small uses the default `.large` visual metrics at every system Dynamic Type
size. Its bottom readings stay on one line and can scale down to 70%.
The regression tests compare element frames with the default size in both
fixed card sizes and check that the readings fit within the content area
without overlapping. The English heavy-rain case runs at all twelve text
sizes. Selected scenarios across all five fixture languages compare the
default and largest sizes, including missing values and a missing snapshot.
The tests check that weather information remains available through accessibility
labels and that the regular Small card has no forecast controls.

Named screenshots are attached to the result bundle. Read the clock and
forecast glyphs in the screenshots independently of the element frames.
The fixture does not establish how SpringBoard hosts the widget or how
VoiceOver speaks it; verify those on a simulator separately.

### Earlier verification

Phase 2A checked two temporary fixture-only mutations on the English stale
case: supplying the entry date as the observation date made the expected
observation count zero; rendering a second warning with the same catalog
label made the warning count two. The fixture was restored after each run.

The [Phase 2B mapping](PHASE_2B.md) traces the app-hosted assertions to their
replacement coverage. Phase 1's observation-removed, warning-removed and
out-of-bounds controls remain in the original PoC evidence (`remove-time`,
`remove-warning-real` and `move-time-bounded` logs and result bundles).
