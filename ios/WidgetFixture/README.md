# Widget fixture UI tests

`DPIP_IOS_SIMULATOR=<UDID> tool/dev/test_widget_ui.sh` runs the isolated
fixture and XCUITest scheme. Supply distinct `-derivedDataPath` and
`-resultBundlePath` arguments to preserve evidence per run. The fixture
compiles the production widget sources and localization catalog directly; it is
not embedded in Runner or its extensions.

The fixed 338 × 158 pt host uses 16 pt margins, matching the initial PoC.
The PoC screenshot showed precipitation at the bottom clipped in this host;
this is a host observation, not evidence of a WidgetKit regression. The test
checks accessibility geometry and labels, not complete glyph visibility or
system-widget rendering. Screenshots remain attached to the result bundle.
