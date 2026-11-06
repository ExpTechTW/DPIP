# Medium weather accessibility test migration

The two original methods in `ForecastUnavailablePresentationTests` queried
`UIHostingController.view.accessibilityElement(at:)`. On a simulator without
an initialized accessibility service, that enumeration can return an empty
tree. The shared `WidgetFixture` scheme launches the production Medium view
and reads accessibility through public XCUIAutomation queries.

**Stale** refers to `testMediumStaleHeaderAndForecastInConstrainedHost`.
**Non-stale** refers to `testMediumNonStaleStatesDoNotExposeStaleWarning`.

| Original assertion | Phase 2A evidence | Phase 2B owner and replacement |
| --- | --- | --- |
| Both methods required exactly one full observation time, derived from the snapshot and distinct from the entry date. | `assertCurrentWeather` independently formats 06:21 and 07:21 UTC in Taipei for each selected locale. It requires the first as unique static text and rejects the second. | XCUITest. Retain the independent clock oracle and apply it to the original wide and narrow stale cases and both sizes of the Traditional Chinese non-stale matrix. |
| Stale method asserted fixture freshness, including the fresh control. Non-stale method asserted fresh, expired and missing classifications. | Fixed publication ages exercise distinct presentation states. | `testMediumForecastFixtureFreshness` keeps the model assertions in XCTest. `testPublicationAgeBoundaries`, `testTransitionEntriesUseOwnDatesAndKeepAutomaticRefresh` and `testValidForecastHidesActionAndExpiryRestoresItWithoutLosingCurrentWeather` still check the state transitions, forecast selection and refresh eligibility. XCUITest checks the presentation. |
| Stale method expected the localized warning exactly once, as text or an image according to the fixture. The iOS 15 branch expected an image. | Phase 2A checked exact catalog literals and exact roles for five locales on the 338 × 158 pt card. | XCUITest. Keep those cases and restore the five text cases with 西屯 on the 364 × 170 pt card, the narrow English long-location image case, and the wide Japanese and Traditional Chinese AX1 image cases. The production iOS 15 fallback remains in place. It is outside the fixture’s deployment range and the available simulator matrix. |
| Stale method ordered location, warning and observation time left to right, with warning and time sharing a row. It required nonempty warning and time frames within the 16 pt content insets. | Phase 2A checked warning-to-time order, vertical overlap and card containment. | XCUITest adds location-to-warning ordering and tests the header against the inset of the independent card marker. Both card sizes are checked against fixed dimensions. |
| Stale method checked all five regular forecast times, five temperatures, five precipitation probabilities and five image elements. At AX1 it checked the nearest time, temperature and probability in one combined label. | Phase 2A checked only the first regular column and combined AX1 row. | XCUITest checks all five unique values per field and their column association, and checks the five weather images below the hour row. It requires exactly one combined AX1 label containing the nearest time, temperature and probability together. |
| Forecast frames had to be nonempty, within horizontal content bounds, below the observation and left of refresh. The wide forecast had to fit the card vertically. | Phase 2A checked representative geometry below current temperature. | XCUITest uses both the observation and current temperature to bound the forecast top, checks all the forecast frames against the horizontal content bounds and checks separation from refresh. Wide forecast frames must fit vertically. |
| Narrow stale forecast bottom could extend no farther than the card or its matching fresh control, whichever extended farther. | Phase 2A checked that the representative precipitation frame intersected the card and retained clipped screenshots. | XCUITest launches narrow stale and fresh with the same locale, text size, location and forecast values. It compares the semantic forecast bottoms and retains both screenshots. It requires each narrow precipitation frame to intersect the card. |
| Stale method required one localized refresh Button at 44 × 44 pt within the card and horizontal content bounds. The pre-iOS 17 branch expected no button. | Phase 2A checked exact label, role, count, dimensions and forecast-region bounds. | XCUITest retains these checks on both supported test runtimes and checks the Button is enabled. The fixture has a 17.0 deployment target. The existing XCTest `testMediumAndLargeUnavailableSectionFitsAllLocalesAndLargestText` retains the pre-17 unavailable-section sizing check. Stale and unavailable share the same availability-gated refresh control. |
| Non-stale method required absence of the Traditional Chinese warning for fresh, expired and unavailable at .large and AX1. The positive observation assertion preceded the absence check. | Phase 2A tested the three states in English at .large only. | XCUITest restores all six Traditional Chinese combinations. It requires location, observation, current temperature and state-specific forecast or unavailable status before checking warning absence. Fresh also requires no button. Expired and unavailable require refresh and reject forecast values, including combined labels. |
| Stale method attached English and Japanese renders. Non-stale method attached the Traditional Chinese unavailable render. | Phase 2A retained named screen captures for representative states. | XCUITest attaches the migrated case screenshots. XCTest retains `testStaleForecastLayoutDiagnostics` with its ideal-size table and finite Medium/Large renders across locales and text sizes. |

The geometry is accessibility geometry. The narrow fixture clips bottom
precipitation glyphs in both the feature baseline and the migration candidate.
Named screenshots remain in the result bundles. Real WidgetKit presentation,
VoiceOver interaction and glyph-level clipping require separate QA.

## Phase 3 checklist

1. Keep the existing RunnerTests step in `.github/workflows/ios.yml`. Add a
   WidgetFixtureUITests step in the same required `Build iOS / iOS` job. Add
   `tool/dev/test_ios.sh`, `tool/dev/test_widget_ui.sh` and the iOS workflow
   to the iOS path filter so test infrastructure changes exercise the job.
2. Select a supported runner/Xcode with the iOS 26.5 runtime and iPhone 17 Pro
   device type available. Create a clean simulator, record its UDID and
   `simctl bootstatus -b` separately, then run RunnerTests before
   WidgetFixtureUITests on that UDID with parallel testing disabled. Give the
   suites distinct result bundle and DerivedData paths.
3. Give the boot step an ID such as `simulator`. Run the UI suite with
   `if: ${{ !cancelled() && steps.simulator.outcome == 'success' }}` so it
   also runs after an unsuccessful RunnerTests step. Keep both steps
   failure-propagating and require the iOS job for merge. Preserve independent
   boot, RunnerTests and WidgetFixtureUITests outcomes. Use the xcresult
   summary and named failed tests to distinguish assertions from launch or
   build failures.
4. On failure, export attachments from any available xcresult bundle with
   `xcresulttool export attachments --only-failures`. Upload the xcresults,
   screenshots and boot/test logs with the pinned artifact action in an
   always-run collection step. Handle absent bundles when boot or build
   fails and preserve the original test exit codes.
