// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String typhoonValueLat(String lat) {
    return '$lat°N';
  }

  @override
  String get onboardingSkipBody =>
      '위치 및 알림 권한이 없으면 DPIP가 주변의 지진과 재난을 실시간으로 알려드릴 수 없습니다. 나중에 설정에서 권한을 허용할 수 있습니다.';

  @override
  String get rainInterval24h => '24시간';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return '$minutes분 후에 강한 비가 그칠 것으로 예상돼요';
  }

  @override
  String get mapTimelineObserved => '관측';

  @override
  String get regionSelectTitle => '지역 선택';

  @override
  String get skyTimeNoon => '정오';

  @override
  String get radarCountyOutlineSubtitle => '레이더 에코 아래에서도 경계가 보이도록 합니다.';

  @override
  String get dpmFilterSectionRestroomType => '화장실 유형';

  @override
  String get mapLayerSatelliteB03 => '히마와리 가시 적색(B03)';

  @override
  String get reportFilterIntensity => '진도';

  @override
  String get mapLayerLightning => '번개';

  @override
  String get restroomTypeMale => '남자 화장실';

  @override
  String get meshtasticLastReceived => 'Last received';

  @override
  String get reportDetailSortByCounty => '지역순 정렬';

  @override
  String get onboardingPermUnusedApp => '앱 활성 상태 유지';

  @override
  String get onboardingPermUnusedAppDesc =>
      'Android는 한동안 열지 않은 앱을 일시 중지하고 권한을 해제합니다. 그러면 재난 경보가 현재 위치로 전달되지 않습니다.';

  @override
  String get homeRainTrendScattered => '약한 비가 올 수 있어요';

  @override
  String get meshtasticUptime => 'Uptime';

  @override
  String get weatherRankingTempExtremes => '기온 극값';

  @override
  String get themeLight => '라이트';

  @override
  String get mapTerrainReliefHint => '기본 지도에 지형 음영 표시';

  @override
  String get meshtasticEmptyMessage => '(empty message)';

  @override
  String get moreSectionRegion => '지역';

  @override
  String get dpmDisasterEarthquake => '지진';

  @override
  String get mapLayerSatellite => '히마와리 적외(B13)';

  @override
  String get aedHoursSaturday => '토요일 운영시간';

  @override
  String get dpmDisasterSlope => '사면 재해';

  @override
  String get moonPhaseNew => 'New moon';

  @override
  String get notifySectionEew => '지진 조기경보';

  @override
  String get mapResetNorth => '북쪽으로 되돌리기';

  @override
  String get rainInterval2d => '2일';

  @override
  String get mapTownLabelsHint => '확대하면 읍면동 이름 표시';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get notifyOptTsunamiWarning => '지진해일 경보만';

  @override
  String get mapLayerSatelliteBtdFog => '히마와리 야간 안개';

  @override
  String get moreSectionAdvanced => '고급';

  @override
  String get moreSectionMesh => '메시 네트워크';

  @override
  String get weatherRankingExtremeRange => '일교차';

  @override
  String get permissionsTitle => '권한 확인';

  @override
  String get permissionsAttention => '권한을 확인해야 합니다';

  @override
  String get permissionsBody =>
      'DPIP가 제때 알리려면 이 권한들이 필요합니다. 알림이 오지 않는 이유는 대개 이 중 하나가 꺼져 있기 때문입니다.';

  @override
  String get notifySettingsMenu => '알림 설정';

  @override
  String get typhoonHistoryTitle => '자료 시각';

  @override
  String mapAppDefault(String app) {
    return '$app (기본)';
  }

  @override
  String get trendRange24h => '24시간';

  @override
  String get mapLayerStyleJmaTooltip => '그레이스케일 바탕에 −40 °C 이하를 채색, 운정 고도 강조';

  @override
  String weatherRankingRecordedAt(String time) {
    return '기록 시각 $time';
  }

  @override
  String get mapLayerRain => '강수량';

  @override
  String get mapLayerQpesums => '1시간 강수 예보';

  @override
  String get mapOverlaySectionMap => '지도';

  @override
  String get mapTerrainRelief => '지형 입체감';

  @override
  String get eewMaxIntensity => '최대 진도';

  @override
  String get mapLegendCollapse => '범례 숨기기';

  @override
  String get updateAvailableTitle => '새 버전';

  @override
  String updateAvailableBody(String version) {
    return '버전 $version 이(가) 나왔습니다.';
  }

  @override
  String get updateSkip => '이번은 건너뛰기';

  @override
  String get updateViewChangelog => '변경 내용 보기';

  @override
  String get updateOpenAppStore => 'App Store';

  @override
  String get updateOpenTestFlight => 'TestFlight';

  @override
  String get updateOpenPlayStore => 'Play 스토어';

  @override
  String get updateDownload => '다운로드';

  @override
  String get changelogTitle => '변경 로그';

  @override
  String get reportFilterOrderDesc => '내림차순';

  @override
  String get meshtasticExcludeMqttSubtitle =>
      'Nodes bridged over the internet, not heard by radio';

  @override
  String get reportFilterIntensityInfoTitle => '진도 신제·구제';

  @override
  String get mapLayerTyphoon => '태풍';

  @override
  String get radarOverlayMenuTooltip => '레이더 레이어 옵션';

  @override
  String get mapMyLocation => '내 위치';

  @override
  String get meshtasticNodes => 'Nodes';

  @override
  String get meshtasticSend => 'Send';

  @override
  String get typhoonOverlayStormL7Tooltip =>
      'Level-7 wind field + average circle (purple)';

  @override
  String get aedType => '유형';

  @override
  String get termsOfService => '서비스 약관';

  @override
  String get typhoonLegendCircle25 => '폭풍권 (10급)';

  @override
  String get sponsorTitle => 'DPIP 후원하기';

  @override
  String get mapNavSatellite => '위성';

  @override
  String homeRainTrendUpdated(String time) {
    return '업데이트 $time';
  }

  @override
  String get onboardingNext => '다음';

  @override
  String get weatherRankingMergeTown => '향진';

  @override
  String get mapLayerMonitor => '실시간 지진 모니터';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get sponsorSubscriptions => '구독';

  @override
  String typhoonValueLon(String lon) {
    return '$lon°E';
  }

  @override
  String get skyTime => '하늘 시각';

  @override
  String get weatherModeCloudy => '구름 많음';

  @override
  String get skyTimeDusk => '땅거미';

  @override
  String get meshtasticFirmware => 'Firmware';

  @override
  String get reportFilterDateEndNote => '종료일: 당일 24:00（타이베이）';

  @override
  String get reportFilterSortMagnitude => '규모';

  @override
  String get meshtasticSilent => 'Silent';

  @override
  String get mapLayerCategoryEarthquake => '지진';

  @override
  String get mapLayerSatelliteB12 => '히마와리 오존(B12)';

  @override
  String get typhoonLegendPast => '실황 경로';

  @override
  String get restroomCategoryOther => '기타';

  @override
  String homeForecastHighLow(String high, String low) {
    return '최고 $high° · 최저 $low°';
  }

  @override
  String get locationBannerFix => '설정 열기';

  @override
  String get mapLegendExpand => '범례';

  @override
  String get eewNone => '현재 지진 조기경보가 없습니다';

  @override
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String get notifyOptTsunamiAll => '지진해일 주의보 및 경보';

  @override
  String get meshtasticLayerOptions => 'Node options';

  @override
  String get onboardingAgreeContinue => '동의하고 계속';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get meshtasticNodeId => 'Node ID';

  @override
  String reportDetailNumbered(String number) {
    return '번호 $number 유의미 유감지진';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => 'With average circle';

  @override
  String get disasterMapOverlayRestroomTooltip => '공중화장실 표시';

  @override
  String get weatherRankingTitle => '관측 순위';

  @override
  String get homeRainTrendHeavySustained => '앞으로 1시간 동안 강한 비가 이어질 거예요';

  @override
  String get notifySectionTsunami => '지진해일';

  @override
  String get restroomCategoryPark => '공원';

  @override
  String get moreLinkOpenFailed => '링크를 열 수 없습니다';

  @override
  String get themeDark => '다크';

  @override
  String get sponsorRestore => '구매 복원';

  @override
  String get meshtasticChannelWorking => 'Setting up the DPIP channel…';

  @override
  String get meshtasticRegionSwitch => 'Switch to TW';

  @override
  String get meshtasticTraffic => 'Traffic';

  @override
  String get mapLayerStyleBdTooltip => 'Dvorak BD 커브——열대저기압 강도 분석용 계단 그레이스케일';

  @override
  String get disasterMapOverlayAedTooltip => 'AED 위치 표시';

  @override
  String get mapLayerHumidity => '습도';

  @override
  String get mapLayerSatelliteTransparentNight => '야간 = 투명,배경 지도 표시';

  @override
  String get meshtasticScanning => 'Scanning…';

  @override
  String regionSelectFull(int max) {
    return '최대 $max개 지역까지 저장할 수 있습니다';
  }

  @override
  String get meshtasticNewMessages => '새 메시지';

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => '더보기';

  @override
  String get meshtasticDpipChannel => 'DPIP channel';

  @override
  String get disasterMapOverlaySectionLayers => '레이어';

  @override
  String get mapLayerSatelliteB05 => '히마와리 근적외(B05)';

  @override
  String typhoonStormRadii(String ne, String se, String sw, String nw) {
    return 'NE $ne · SE $se · SW $sw · NW $nw km';
  }

  @override
  String get typhoonLabelNe => 'NE';

  @override
  String get meshtasticCopied => 'Message copied';

  @override
  String get reportListEmpty => '지진 보고서가 없습니다';

  @override
  String get reportListEnd => '마지막입니다';

  @override
  String get mapLayerSatelliteTruecolor => '히마와리 트루컬러';

  @override
  String get typhoonOverlaySectionExtra => 'Overlays';

  @override
  String get eewSWave => 'S파';

  @override
  String get meshtasticBusyTitle => 'Another app is using this radio';

  @override
  String get restroomCategoryCultural => '문화·여가 시설';

  @override
  String get typhoonLabelWind => 'Max. sustained wind near centre';

  @override
  String get radarGlobalOutlineHint => '각국 국경선';

  @override
  String get notifyEvacuation => '재난 정보';

  @override
  String get typhoonLegendCircle15 => '강풍권 (7급)';

  @override
  String get dataSectionAstronomy => 'Astronomy';

  @override
  String get homeRainTrendLightSustained => '앞으로 1시간 동안 약한 비가 이어질 거예요';

  @override
  String get commonError => '문제가 발생했습니다';

  @override
  String get moonPhaseWaningCrescent => 'Waning crescent';

  @override
  String get meshtasticPower => 'Power';

  @override
  String get mapTimelineNow => '현재';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportDetailOpenReport => '보고서 페이지';

  @override
  String get trendRange7d => '7일';

  @override
  String typhoonWarningAreas(String areas) {
    return '대상 지역: $areas';
  }

  @override
  String get rainIntervalSection => '집계 시간';

  @override
  String get notifyTitle => '알림';

  @override
  String get meshtasticTxPower => 'TX power';

  @override
  String get restroomCategoryLabel => '구분';

  @override
  String get sponsorRestoring => '구매를 복원하는 중…';

  @override
  String get sponsorIntro =>
      'DPIP는 실시간 재난 예방 정보를 제공하는 데 전념하며, 광고나 다른 수익 모델이 없습니다. 여러분의 후원은 서버 운영과 지속적인 개발에 도움이 됩니다.';

  @override
  String get shelterAddressLabel => '주소';

  @override
  String get typhoonLabelStormAvg => 'Avg. radius of Beaufort 10 winds';

  @override
  String get restroomCategoryCommercial => '상업·영업 시설';

  @override
  String get aedRegion => '지역';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return '$minutes분 후에 비가 그칠 것으로 예상돼요';
  }

  @override
  String get reportDetailInfo => '상세 정보';

  @override
  String get mapNavWind => '풍향';

  @override
  String get windForecastOverlayMenuTooltip => '바람 예보 레이어 옵션';

  @override
  String get dataWeatherRankingSubtitle => '실시간 관측 순위';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute분';
  }

  @override
  String get rainInterval6h => '6시간';

  @override
  String get restroomTypeUnspecified => '미설정';

  @override
  String get typhoonOverlayProbabilityHint => 'Hides the forecast cone';

  @override
  String get mapLayerSatelliteGlobalOutline => '국경선';

  @override
  String get mapNavTemperature => '온도';

  @override
  String get typhoonLegendForecastPoint => '예보 지점';

  @override
  String get reportListYesterday => '어제';

  @override
  String get moreSectionLinks => '링크';

  @override
  String get feedOffline => '연결이 끊어졌습니다';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get moreSectionDisplay => '표시';

  @override
  String get rainInterval3d => '3일';

  @override
  String get defaultMapLayerSubtitle =>
      '지도 탭을 열 때 표시할 레이어입니다. 하단 탐색 아이콘과 라벨도 함께 바뀝니다.';

  @override
  String get aedDescription => '비고';

  @override
  String get typhoonOverlayWeatherRadarTooltip =>
      'Radar echo closest to the typhoon bulletin time';

  @override
  String get onboardingPermLocationDesc => '현재 위치에 맞춰 경보를 전달합니다.';

  @override
  String get mapLayerSatelliteB16 => '히마와리 이산화탄소(B16)';

  @override
  String get homeActiveEventsEmpty => '발효 중인 이벤트가 없습니다';

  @override
  String get typhoonLabelPosition => 'Centre location';

  @override
  String get weatherRankingBy => '정렬';

  @override
  String get typhoonIntensityMild => 'Mild typhoon';

  @override
  String get windForecastGlobalOutlineHint => '각국 국경선';

  @override
  String get rainInterval1h => '1시간';

  @override
  String get eewLocalIntensity => '현재 위치 예상';

  @override
  String get mapLayerRadar => '레이더 합성 에코';

  @override
  String get restroomCategoryReligious => '종교·의례 시설';

  @override
  String get meshtasticRole => 'Role';

  @override
  String get mapLayerSatelliteCloudCloudy => '구름';

  @override
  String get skyTimeSunrise => '일출';

  @override
  String get meshtasticNoMessages => 'No messages yet';

  @override
  String get onboardingPermNotifyDesc => '지진, 날씨, 재해가 발생하는 즉시 경보를 전달합니다.';

  @override
  String get radarTownOutline => '읍·면·동 경계';

  @override
  String get mapLayerStyleSection => '색상 스타일';

  @override
  String get disasterMapOverlayMenuTooltip => '방재 지도 레이어';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get meshtasticOnline => 'Heard recently';

  @override
  String get typhoonLabelSw => 'SW';

  @override
  String typhoonForecastLead(String hours) {
    return 'Forecast +$hours h';
  }

  @override
  String get dpmDisasterTsunami => '쓰나미';

  @override
  String get changelogTypeStable => '정식';

  @override
  String get mapLayerSatelliteTransparentClear => '맑음 = 투명,배경 지도 표시';

  @override
  String get mapOverlaySectionReference => '참조 레이어';

  @override
  String get mapLayerSatelliteB02 => '히마와리 가시 녹색(B02)';

  @override
  String get reportListLocalFelt => '소규모 유감';

  @override
  String get weatherRankingEmpty => '정렬할 관측이 없습니다';

  @override
  String get notifySectionOther => '기타';

  @override
  String weatherRankingMeta(String time, int count) {
    return '자료 시각: $time\n관측점 $count';
  }

  @override
  String get onboardingTermsAgree => '서비스 약관을 읽었으며 이에 동의합니다';

  @override
  String get mapLayerSatelliteTransparentNoVegetation => '< 0.1 = 투명(식생 없음)';

  @override
  String get notifyOptLocalIntensity4 => '현재 위치 진도 4 이상';

  @override
  String get eewArrived => '도달';

  @override
  String get meshtasticNoDevices => 'No Meshtastic devices found';

  @override
  String get mapLayerCategoryLife => '생활';

  @override
  String get reportFilterSortIntensity => '진도';

  @override
  String get typhoonMotion => '이동';

  @override
  String get meshtasticStateDisconnected => 'Disconnected';

  @override
  String get typhoonIntensityIntense => 'Intense typhoon';

  @override
  String get mapLayerOrderTitle => '레이어 순서';

  @override
  String get dpmYes => '예';

  @override
  String get meshtasticNoHistory => 'Not enough history yet';

  @override
  String get reportDetailLocalIntensityUnavailable => '진도 정보 없음';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportListDepthUnit => 'km';

  @override
  String get reportFilterDepth => '깊이';

  @override
  String get onboardingScrollHint => '계속하려면 아래로 스크롤하세요';

  @override
  String get mapNavQpesums => '예보';

  @override
  String get navMap => '지도';

  @override
  String get notifyAdvisory => '기상 특보';

  @override
  String get reportFilterReset => '초기화';

  @override
  String get mapLayerSatelliteMndwi => '히마와리 MNDWI';

  @override
  String get typhoonOverlaySectionStorm => 'Storm wind';

  @override
  String get moonPhaseFull => 'Full moon';

  @override
  String get moonPhaseWaningGibbous => 'Waning gibbous';

  @override
  String get weatherDynamicStateSubtitle => '홈 배경 날씨를 재정의합니다';

  @override
  String get reportFilterIntensityInfoModernTitle => '신제(2020년 이후)';

  @override
  String typhoonDataTime(String time) {
    return 'Data time\n$time';
  }

  @override
  String get restroomTypeAccessible => '장애인 화장실';

  @override
  String get moreSectionAbout => '정보';

  @override
  String get meshtasticSelectDevice => 'Select a radio';

  @override
  String get onboardingIntroBody =>
      'DPIP는 여러분과 함께하는 방재 파트너입니다. 지진 조기경보, 지진 보고, 날씨, 각종 재해 정보를 통합하여 중요한 순간에 실시간으로 알려드립니다.\n\n• 지진: 지진 조기경보, 진도 속보, 상세 지진 보고\n• 날씨: 뇌우 실시간 메시지, 기상 특보\n• 지진해일 및 재난 정보\n\n다음으로, 서비스 약관을 확인하고 DPIP가 실시간으로 여러분을 보호할 수 있도록 몇 가지 권한을 허용해 주시기 바랍니다.';

  @override
  String get shelterCapacityLabel => '수용 인원';

  @override
  String get reportDetailImage => '지진 보고서 이미지';

  @override
  String get meshtasticStateConfiguring => 'Configuring…';

  @override
  String get typhoonLabelGaleAvg => 'Avg. radius of Beaufort 7 winds';

  @override
  String get onboardingPermNotify => '알림';

  @override
  String get meshtasticClearMessages => 'Clear messages';

  @override
  String get meshtasticNotifyMessages => 'Notify on new messages';

  @override
  String get defaultMapLayerSettings => '지도 기본 레이어';

  @override
  String get moreSectionNotify => '알림';

  @override
  String get notifyUnavailable => '푸시 알림이 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get mapLayerOrderReset => '기본 순서로 재설정';

  @override
  String get dpmAddress => '주소';

  @override
  String get weatherRankingMergeCounty => '현시';

  @override
  String get moreSectionApp => '앱 다운로드';

  @override
  String get reportFilterIntensityInfoLegacyBody =>
      '진도는 0–7만 있으며 5약/5강/6약/6강 구분이 없습니다.';

  @override
  String get mapLayerSatelliteSst => '히마와리 해수면 온도';

  @override
  String get qpesumsOverlayMenuTooltip => '정량 강수 예보 레이어 옵션';

  @override
  String get mapTimelineFuture => '미래';

  @override
  String get typhoonLegendCircleAvg => 'Average circle';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get typhoonLabelSe => 'SE';

  @override
  String get radarTownOutlineHint => '더 세밀한 구획';

  @override
  String eewCountdown(int seconds) {
    return '$seconds초';
  }

  @override
  String get typhoonLabelGust => 'Peak gust';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get sponsorTerms => '이용약관';

  @override
  String get restroomTypeGenderNeutral => '성중립 화장실';

  @override
  String get notifyThunderstorm => '뇌우 알림';

  @override
  String get skyTimeGolden => '골든아워';

  @override
  String get moonAge => 'Age';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return '현재 $value°C';
  }

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable => '지역을 선택하면 예보를 볼 수 있습니다';

  @override
  String get mapLayers => '레이어';

  @override
  String get meshtasticHardware => 'Hardware';

  @override
  String get languageSettings => '언어';

  @override
  String get dpmDisasterNuclear => '핵 사고';

  @override
  String get language => '언어';

  @override
  String homeForecastFeelsLike(String temp) {
    return '체감 $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => 'Aligned to bulletin time';

  @override
  String get skyTimeDawn => '여명';

  @override
  String get skyTimeAfternoon => '오후';

  @override
  String get meshtasticLastHeard => 'Last heard';

  @override
  String get typhoonWarningTitle => '태풍 경보';

  @override
  String get moreSourceCode => '소스 코드';

  @override
  String get mapLayerCategoryWeather => '기상 관측';

  @override
  String get mapLayerSatelliteB09 => '히마와리 중층 수증기(B09)';

  @override
  String get windForecastTownOutlineHint => '더 촘촘한 망';

  @override
  String get mapLayerSatelliteCloudmask => '히마와리 구름 마스크';

  @override
  String get mapAppCopyCoordinates => '좌표 복사';

  @override
  String get reportFilterIntensityInfoIntro =>
      '기상서는 2020년 1월 1일(타이베이 시간)부터 신제 진도를 사용합니다.';

  @override
  String get mapNavEarthquake => '지진';

  @override
  String get typhoonGust => '순간최대풍속';

  @override
  String get restroomGradeAverage => '보통';

  @override
  String get mapLayerSatelliteBtdCo2 => '히마와리 권운/운고';

  @override
  String get onboardingPermBackgroundDesc =>
      '“항상 허용”을 선택하면 앱이 종료된 상태에서도 위치 맞춤 경보를 받을 수 있습니다.';

  @override
  String get mapTimelineForecast => '예보';

  @override
  String get restroomTypeLabel => '유형';

  @override
  String get navEarthquake => '지진';

  @override
  String get typhoonOverlayStormL10Tooltip =>
      'Level-10 wind field + average circle (yellow)';

  @override
  String get moonPhaseWaxingGibbous => 'Waxing gibbous';

  @override
  String get reportDetailTitle => '지진 보고서';

  @override
  String get moreTremReport => 'TREM 탐지 보고';

  @override
  String weatherDataTime(String station, String time) {
    return '$station · 데이터 시간 $time';
  }

  @override
  String get meshtasticNoNodes => 'No nodes heard yet';

  @override
  String get meshtasticViaMqtt => 'Via MQTT (internet)';

  @override
  String get radarCountyOutline => '시·군 경계';

  @override
  String get onboardingGranted => '허용됨';

  @override
  String get commonClose => '닫기';

  @override
  String get restroomGradeLabel => '등급';

  @override
  String get rainIntervalNow => '오늘';

  @override
  String get changelogCurrentVersion => '현재';

  @override
  String get typhoonLabelPressure => 'Central pressure';

  @override
  String get typhoonOverlayForecastCalloutsTooltip =>
      'Show forecast-point detail cards when zoomed in';

  @override
  String get aedOpenRemark => '운영시간 비고';

  @override
  String get onboardingPermsBody =>
      '재해가 발생하는 즉시 알려드릴 수 있도록 다음 권한을 허용해 주세요. 시스템 설정에서 언제든지 변경할 수 있습니다.';

  @override
  String get typhoonOverlaySectionWeather => 'Weather underlay';

  @override
  String get notifyOptWeatherLocal => '현재 위치만';

  @override
  String get mapNavRain => '강우';

  @override
  String get moonDays => 'days';

  @override
  String mapLegendUnit(String unit) {
    return '단위: $unit';
  }

  @override
  String get weatherModeClear => '맑음';

  @override
  String get meshtasticRadio => 'Radio';

  @override
  String get commonEmpty => '표시할 내용이 없습니다';

  @override
  String get mapLayerSatelliteB01 => '히마와리 가시 청색(B01)';

  @override
  String get meshtasticExternalPower => 'External power';

  @override
  String get moonPhaseLastQuarter => 'Last quarter';

  @override
  String get reportFilterOrderAsc => '오름차순';

  @override
  String get reportFilterApply => '적용';

  @override
  String get reportDetailImageUnavailable => '보고서 이미지가 아직 없습니다';

  @override
  String get weatherRankingHighest => '최고';

  @override
  String get reportDetailReplay => '다시 보기';

  @override
  String get mapLayerRestroom => '공중화장실';

  @override
  String get restroomCategoryWelfare => '사회복지 기관·집회 시설';

  @override
  String get restroomGradeExcellent => '최우수';

  @override
  String get meshtasticLastSent => 'Last sent';

  @override
  String get meshtasticName => 'Name';

  @override
  String get meshtasticScan => 'Scan';

  @override
  String get mapLayerCategoryForecast => '수치 예보';

  @override
  String get meshtasticChannelFailed => 'Couldn\'t set up the DPIP channel';

  @override
  String get themeSystem => '시스템';

  @override
  String get mapLayerSatelliteNdvi => '히마와리 NDVI';

  @override
  String get typhoonLegendForecast => '예보 경로';

  @override
  String typhoonValueHpa(String n) {
    return '$n hPa';
  }

  @override
  String get weatherPrecipitation => '강수량';

  @override
  String get moonNextFullMoon => 'Next full moon';

  @override
  String get dpmSheetEmpty => '지도에서 마커를 눌러 상세 보기';

  @override
  String get onboardingSkipLeave => '그래도 건너뛰기';

  @override
  String get onboardingBack => '이전';

  @override
  String get aedPlaceDesc => '설치 위치';

  @override
  String get onboardingSkipTitle => '권한이 허용되지 않았습니다';

  @override
  String get restroomTypeFamily => '가족 화장실';

  @override
  String typhoonValueKm(String n) {
    return '$n km';
  }

  @override
  String get typhoonPressure => '기압';

  @override
  String get onboardingPermBattery => '배터리 최적화 제외';

  @override
  String get typhoonLabelNw => 'NW';

  @override
  String get dpmDisasterFlood => '홍수';

  @override
  String get moonPhaseWaxingCrescent => 'Waxing crescent';

  @override
  String get restroomCategoryLeisure => '휴양·오락 시설';

  @override
  String get mapLayerTemperature => '기온';

  @override
  String get aedCategory => '분류';

  @override
  String get meshtasticChannels => 'Channels';

  @override
  String get monitorWaiting => '데이터 대기 중…';

  @override
  String get typhoonOverlayForecastCallouts => 'Forecast tooltips';

  @override
  String get reportDetailEpicenter => '진앙 좌표';

  @override
  String get meshtasticVoltage => 'Voltage';

  @override
  String get mapLayerMeshtasticSubtitle =>
      'LoRa mesh nodes heard by your radio';

  @override
  String get mapLayerWind => '바람';

  @override
  String get reportDetailMagnitude => '지진 규모';

  @override
  String get reportDetailAreaIntensity => '지역별 진도';

  @override
  String get rainInterval12h => '12시간';

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get dpmDisasterLandslide => '산사태';

  @override
  String get notifyMonitor => '강진 감시기';

  @override
  String get onboardingStart => '시작하기';

  @override
  String sponsorPerMonth(String price) {
    return '$price / 월';
  }

  @override
  String get mapLayerPressure => '기압';

  @override
  String get mapLayerSatelliteB04 => '히마와리 근적외(B04)';

  @override
  String get mapLayerSatelliteTransparentZero => '차이 0 = 투명(신호 없음)';

  @override
  String get shelterIndoorLabel => '실내 수용';

  @override
  String get notifyOptOff => '끄기';

  @override
  String get reportFilterSortTime => '시간';

  @override
  String get mapLayerSatelliteCloudProbablyClear => '아마 맑음';

  @override
  String get weatherModeThunderstorm => '뇌우';

  @override
  String get homeViewOnMap => '지도에서 보기';

  @override
  String get reportFilterIntensityInfoLegacyTitle => '구제(2020년 이전)';

  @override
  String get typhoonLabelSpeed => 'Past movement speed';

  @override
  String mapAppOpenFailed(String app) {
    return '$app을(를) 열 수 없습니다';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB 합성(JMA 레시피)';

  @override
  String get meshtasticReceived => 'Received';

  @override
  String get weatherRankingExtremeLow => '오늘 최저';

  @override
  String get mapLayerSatelliteB10 => '히마와리 하층 수증기(B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => '아마 구름';

  @override
  String get mapLayerSatelliteTransparentNoWater => '≤ 0 = 투명(수역 없음)';

  @override
  String get shelterCategoryLabel => '적용 재해';

  @override
  String get meshtasticStateConnecting => 'Connecting…';

  @override
  String get moonTitle => 'Moon';

  @override
  String get weatherRankingGust => '돌풍';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get dpmFilterSectionShelter => '대피소 재해 유형';

  @override
  String get moreServerStatus => '서버 상태';

  @override
  String get notifySectionWeather => '날씨';

  @override
  String get meshtasticPreset => 'Modem preset';

  @override
  String get dataSectionSeismic => '지진';

  @override
  String get changelogBodyEmpty => '이 릴리스에 대한 설명이 없습니다.';

  @override
  String get radarGlobalOutline => '국경';

  @override
  String get notifyEew => '긴급 지진 경보';

  @override
  String get regionNationwide => '전국';

  @override
  String get moreNotifyLog => 'DPIP 알림 발송 기록';

  @override
  String get regionCurrent => '현재 위치';

  @override
  String get dpmFilterSectionRestroom => '시설 유형';

  @override
  String get meshtasticNotConnected => 'Not connected to a radio';

  @override
  String get weatherModeSnow => '눈';

  @override
  String get mapLayerMeshtastic => 'Meshtastic nodes';

  @override
  String get moreDeveloper => '디버그 정보';

  @override
  String get mapLayerSatelliteB14 => '히마와리 장파 적외(B14)';

  @override
  String get meshtasticChannelUse => 'Channel use';

  @override
  String get mapNavLightning => '번개';

  @override
  String get homeForecastEmpty => '예보 데이터가 없습니다';

  @override
  String get sponsorOneTime => '일회성 후원';

  @override
  String get mapLayerSatelliteBtdSplit => '히마와리 스플릿 윈도우';

  @override
  String get onboardingPermBackground => '백그라운드 위치';

  @override
  String get aedEmergencyPhone => '비상 연락처';

  @override
  String get dpmOpenInMaps => '지도에서 열기';

  @override
  String get meshtasticNotifyNodes => 'Notify on new nodes';

  @override
  String get onboardingPermCriticalDesc =>
      '생명을 위협하는 지진 경보가 무음 모드나 방해 금지 모드에서도 소리를 낼 수 있도록 합니다.';

  @override
  String get mapLayerSatelliteTransparentWarm => '맑음(고온부) = 투명,배경 지도 표시';

  @override
  String get meshtasticSent => 'Sent';

  @override
  String get homeForecastTitle => '24시간 예보';

  @override
  String get typhoonLegendWarningAreas => '경보 지역';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return '$count hidden';
  }

  @override
  String get notifyOptLocalIntensity1 => '현재 위치 진도 1 이상';

  @override
  String get mapTimelinePast => '과거';

  @override
  String get restroomTypeFemale => '여자 화장실';

  @override
  String get reportListToday => '오늘';

  @override
  String get meshtasticTapNode => 'Tap a node for details';

  @override
  String get commonLoading => '불러오는 중…';

  @override
  String get typhoonIntensityModerate => 'Moderate typhoon';

  @override
  String get typhoonWind => '풍속';

  @override
  String get mapLayerSatelliteAsh => '히마와리 화산재';

  @override
  String get rainInterval3h => '3시간';

  @override
  String get reportListSearch => '조회';

  @override
  String get mapLayerCategorySatellite => '위성';

  @override
  String get meshtasticChannelReady => 'DPIP channel ready';

  @override
  String get reportFilterLocation => '위치';

  @override
  String get mapLayerSatelliteNightmicrophysics => '히마와리 야간 미세물리';

  @override
  String get typhoonIntensityTd => 'Tropical depression';

  @override
  String get reportFilterDate => '날짜';

  @override
  String get sponsorRestoreUnavailable => '스토어에 연결할 수 없습니다. 나중에 다시 시도해 주세요.';

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String get regionEmpty => '저장된 지역이 없습니다';

  @override
  String get onboardingPermBatteryDesc =>
      'DPIP가 백그라운드에서 계속 실행되어 경보가 지연되거나 누락되지 않도록 허용합니다.';

  @override
  String get mapNavDisaster => '방재';

  @override
  String get radarScanRangeSubtitle => '레이더 4기가 실제로 관측하는 범위를 표시합니다.';

  @override
  String get aedHoursSunday => '일요일 운영시간';

  @override
  String get reportDetailOriginTime => '발생 시각';

  @override
  String get trendNoData => '추세 데이터 없음';

  @override
  String get onboardingPermLocation => '위치';

  @override
  String get sponsorCalloutBody => '광고 없이 운영됩니다. 후원이 서버를 지탱합니다.';

  @override
  String get moreDiscordCalloutBody => '커뮤니티에 참여해 개발팀과 이야기해 보세요.';

  @override
  String get moreDiscord => 'Discord 커뮤니티';

  @override
  String get mapNavPressure => '기압';

  @override
  String get mapLayerSatelliteB13 => '히마와리 적외(B13)';

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

  @override
  String get changelogEmpty => '아직 릴리스 노트가 없습니다';

  @override
  String get reportFilterDateStartNote => '시작일: 당일 00:00（타이베이）';

  @override
  String get eewTitle => '지진 조기경보';

  @override
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String regionSelectCount(int count, int max) {
    return '$count/$max 선택됨';
  }

  @override
  String get mapLayerSatelliteBtdSo2 => '히마와리 이산화황/구름상';

  @override
  String get meshtasticStateError => 'Error';

  @override
  String get weatherModeOvercast => '흐림';

  @override
  String get reportDetailDepth => '진원 깊이';

  @override
  String get typhoonOverlayWarningTooltip =>
      'Highlight counties under a typhoon warning';

  @override
  String get reportFilterDatePick => '날짜 선택';

  @override
  String get onboardingSkipStay => '돌아가기';

  @override
  String get commonFetchFailed => '데이터를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get shelterOutdoorLabel => '실외 수용';

  @override
  String get meshtasticStateConnected => 'Connected';

  @override
  String get mapNavRadar => '레이더';

  @override
  String get mapLayerSatelliteCloudClear => '맑음';

  @override
  String eewSummary(String magnitude, String depth) {
    return '규모 $magnitude · 깊이 $depth km';
  }

  @override
  String get locationBannerPermission => '위치 권한이 꺼져 있어 지역 맞춤 경보를 받을 수 없습니다.';

  @override
  String get typhoonOverlayWeatherNoneTooltip =>
      'No radar or infrared underlay';

  @override
  String get radarCountyOutlineHint => '에코 위에 표시';

  @override
  String get windForecastCountyOutlineHint => '바람장 위에 표시';

  @override
  String get homeRainTrendTitle => '향후 1시간 강수';

  @override
  String get moonPhaseFirstQuarter => 'First quarter';

  @override
  String get mapLayerCategoryTyphoon => '태풍';

  @override
  String get meshtasticUtilization => 'Airtime (24h)';

  @override
  String get restroomTypeMixed => '남녀 공용 화장실';

  @override
  String get restroomGradeGood => '우수';

  @override
  String get notifyTsunami => '지진해일 정보';

  @override
  String get navData => '자료';

  @override
  String get mapLayerSatelliteBtdWvirw => '히마와리 오버슈팅 탑';

  @override
  String get meshtasticReadingAge => 'Reading taken';

  @override
  String get mapAppCallFailed => '이 기기에서는 전화를 걸 수 없습니다';

  @override
  String get reportFilterAny => '전체';

  @override
  String get weatherRankingMergeTo => '병합';

  @override
  String get notifyIntensity => '진도 속보';

  @override
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get rainIntervalMenu => '누적 구간';

  @override
  String get reportDetailLocalFelt => '국지적 유감지진';

  @override
  String get meshtasticDevice => 'Device';

  @override
  String get onboardingGrant => '허용';

  @override
  String get weatherModeRain => '비';

  @override
  String get shelterVulnerableOkLabel => '취약계층 수용 가능';

  @override
  String get stationSheetEmpty => '관측소를 눌러 관측값 보기';

  @override
  String get typhoonLegendProbability => '내습 확률';

  @override
  String get reportFilterMagnitude => '규모';

  @override
  String get skyTimeMorning => '오전';

  @override
  String get experimentalFeatures => '실험적 기능';

  @override
  String get onboardingTermsBody =>
      'DPIP를 사용하기 전에 다음 유의 사항을 반드시 읽어 주세요:\n\n• 모든 정보는 중앙기상청(CWA)에서 발표한 내용을 기준으로 합니다.\n\n• 네트워크, 서버, 애플리케이션, 상위 데이터 출처의 상태에 따라 정보를 받지 못할 수 있습니다. 이러한 상황을 방지하기 위해 최선을 다하고 있으나, 절대 발생하지 않는다고 보장할 수는 없습니다.\n\n• 강한 흔들림이 알림보다 먼저 귀하의 위치에 도달할 수 있습니다.\n\n• 지진 조기경보는 빠르게 계산된 결과로 상당한 오차가 있을 수 있으므로, 이를 이해하고 신중하게 사용하시기 바랍니다.\n\n• 당국이 승인하지 않은 모든 행위는 법적 위험을 수반할 수 있으니, 관련 규정을 반드시 준수해 주세요.\n\n또한 지역 맞춤형 경보를 제공하기 위해, 본 서비스는 귀하에게 어떤 경보를 보낼지 결정하기 위한 목적으로만 포그라운드 및 백그라운드에서 귀하의 대략적인 위치와 푸시 식별자를 수집하여 업로드합니다.\n\n하단의 “동의하고 계속”을 누르면 위 사항을 읽고 이해했으며 이에 동의함을 확인하는 것입니다.';

  @override
  String get reportFilterTitle => '필터';

  @override
  String get onboardingPermCritical => '중요 알림';

  @override
  String trendCumulativeTotal(String total) {
    return '누적 $total mm';
  }

  @override
  String get languageName => '한국어';

  @override
  String get reportListEmptyFiltered => '조건에 맞는 지진 보고서가 없습니다';

  @override
  String get meshtasticExcludeMqtt => 'Hide MQTT nodes';

  @override
  String get mapNavTyphoon => '태풍';

  @override
  String get weatherModeSand => '황사';

  @override
  String get typhoonSatelliteTitle => '위성';

  @override
  String get notifyReport => '지진 보고';

  @override
  String get mapAppCoordinatesCopied => '좌표가 복사되었습니다';

  @override
  String get skyTimeNight => '밤';

  @override
  String get sponsorRecommended => '추천';

  @override
  String get mapLayerSatelliteB15 => '히마와리 장파 적외(B15)';

  @override
  String get weatherRankingWind => '풍속';

  @override
  String get feedStale => '데이터가 오래되었을 수 있습니다';

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · 풍력 $level';
  }

  @override
  String get navHome => '홈';

  @override
  String get meshtasticRegionLabel => 'Region';

  @override
  String get mapLayerSatelliteCloudtop => '히마와리 운정 온도';

  @override
  String get moonTimelineCaption => 'Phase';

  @override
  String reportListMeta(String magnitude, String depth) {
    return 'M$magnitude · $depth km';
  }

  @override
  String get openSourceLicenses => '오픈소스 라이선스';

  @override
  String get weatherRankingLowest => '최저';

  @override
  String get reportFilterSortDepth => '깊이';

  @override
  String mapTimelineDataTime(String time) {
    return '데이터 시간 $time';
  }

  @override
  String get radarScanRange => '스캔 범위 표시';

  @override
  String get meshtasticHopLimit => 'Hop limit';

  @override
  String weatherRankingAnalysisRange(String value) {
    return '일교차 $value°C';
  }

  @override
  String get weatherRankingExtremeHigh => '오늘 최고';

  @override
  String get changelogVersionDetails => '릴리스 상세';

  @override
  String get sponsorPrivacy => '개인정보 처리방침';

  @override
  String get reportDetailLocalIntensity => '내 위치의 진도';

  @override
  String get mapLayerSatelliteNaturalcolor => '히마와리 내추럴컬러';

  @override
  String get meshtasticAirtime => 'Air time (TX)';

  @override
  String shelterCapacityValue(int n) {
    return '$n 명';
  }

  @override
  String lightningLegendCc(int minutes) {
    return '구름 사이 · $minutes분 이내';
  }

  @override
  String get meshtasticSendHint => 'Message to broadcast';

  @override
  String monitorDelay(String value) {
    return '지연 $value s';
  }

  @override
  String get dpmNo => '아니요';

  @override
  String get mapLayerSatelliteB08 => '히마와리 상층 수증기(B08)';

  @override
  String get meshtasticReconnecting => 'Reconnecting…';

  @override
  String get radarTownOutlineSubtitle => '레이더 에코 아래에서도 읍·면·동 경계가 보이도록 합니다.';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip =>
      'Infrared closest to the typhoon bulletin time';

  @override
  String get radarScanRangeHint => '범위 밖 공백은 미관측';

  @override
  String typhoonPickerTd(String no) {
    return 'Tropical depression TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => '히마와리 수증기';

  @override
  String get regionAddButton => '지역 추가';

  @override
  String get displaySettings => '화면';

  @override
  String get restroomGradePoor => '불합격';

  @override
  String get restroomCategoryTourist => '관광 지역·경치 구역';

  @override
  String get locationBannerServiceOff => '위치 서비스가 꺼져 있어 지역 맞춤 경보를 받을 수 없습니다.';

  @override
  String get mapLayerStyleTooltip => '색상 스타일';

  @override
  String lightningLegendCg(int minutes) {
    return '대지로 · $minutes분 이내';
  }

  @override
  String get skyTimeAuto => '자동';

  @override
  String get appLogs => '앱 로그';

  @override
  String get feedConnecting => '연결 중…';

  @override
  String get notifyBannerDisabled => '알림이 꺼져 있어 재난 경보를 받을 수 없습니다.';

  @override
  String get weatherHumidity => '습도';

  @override
  String typhoonValueMs(String n) {
    return '$n m/s';
  }

  @override
  String homeForecastHumidity(String value) {
    return '습도 $value%';
  }

  @override
  String get meshtasticBusyBody =>
      'Disconnect it in the other Meshtastic app first. Two apps on one radio take each other\'s messages, so some will go missing.';

  @override
  String get meshtasticChannelNoSlot =>
      'No free channel slot — free one on the radio';

  @override
  String get restroomCategoryTransport => '교통';

  @override
  String get reportFilterLocationHint => '예: 화롄, 해역';

  @override
  String get moonSubtitle => 'Lunar phase and illumination — computed locally';

  @override
  String get meshtasticBattery => 'Battery';

  @override
  String get meshtasticDistance => '거리';

  @override
  String get meshtasticSnrTrend => '신호 추이 (SNR)';

  @override
  String get meshtasticBatteryTrend => '배터리 추이';

  @override
  String get typhoonOverlayMenuTooltip => 'Typhoon overlay options';

  @override
  String get mapLayerSatelliteBtdOzone => '히마와리 대류권계면';

  @override
  String meshtasticRegionMismatch(String region) {
    return 'Radio region is $region — DPIP needs TW';
  }

  @override
  String get notifySectionEarthquake => '지진';

  @override
  String get mapLayerDisasterMap => '방재 지도';

  @override
  String get weatherModeFog => '안개';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String get mapLayerStyleGrayTooltip => '기상청 적외 영상 관례：온도가 낮을수록 흰색';

  @override
  String get moreAnnouncements => '공지사항';

  @override
  String get mapLayerSatelliteTransparentNoData => '데이터 없음(육지) = 투명';

  @override
  String get restroomCategoryGovernment => '민원 업무 시설';

  @override
  String get typhoonLegendCurrent => '현재 중심';

  @override
  String get aedAddress => '주소';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get changelogTypePrerelease => '베타';

  @override
  String get reportFilterIntensityInfoModernBody =>
      '진도는 0–4, 5약, 5강, 6약, 6강, 7입니다. 필터는 신제를 따르며, 이전 지진은 목록에서 구제 표기로 표시됩니다.';

  @override
  String get typhoonOverlayWeatherNone => 'None';

  @override
  String get mapLayerStyleGray => '그레이스케일（JMA）';

  @override
  String get weatherModeAuto => '자동';

  @override
  String get typhoonLabelProbCircle => '70% probability circle';

  @override
  String get notifyOptAll => '전체 수신';

  @override
  String get displayTheme => '테마';

  @override
  String get mapLayerSatelliteB07 => '히마와리 단파 적외(B07)';

  @override
  String get typhoonLabelDirection => 'Past movement direction';

  @override
  String get regionManageTitle => '저장한 지역';

  @override
  String get typhoonLegendCone => '예보 원추';

  @override
  String get moreCwaEew => '중앙기상청(CWA) 지진 조기경보';

  @override
  String get onboardingPermsTitle => '권한 허용';

  @override
  String get mapLayerStyleJma => '운정 강조（JMA）';

  @override
  String get rainInterval10m => '10분';

  @override
  String weatherRankingAnalysisLow(String value) {
    return '최저 $value';
  }

  @override
  String get meshtasticConnectAnyway => 'Connect anyway';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get mapLayerSatelliteB06 => '히마와리 근적외(B06)';

  @override
  String get mapLayerSatelliteTransparentReflectance =>
      '낮은 반사율/야간 = 투명,배경 지도 표시';

  @override
  String chartHourLabel(int hour) {
    return '$hour시';
  }

  @override
  String get mapLayerShelter => '대피소';

  @override
  String get typhoonOverlayProbabilityTooltip =>
      'Show strike probability (hides the forecast cone)';

  @override
  String get mapLayerSatelliteNdwi => '히마와리 NDWI';

  @override
  String get disasterMapOverlayShelterTooltip => '대피소 표시';

  @override
  String get mapNavHumidity => '습도';

  @override
  String get reportDetailSortByIntensity => '진도순 정렬';

  @override
  String get homeRainTrendNoData => '데이터 없음';

  @override
  String get mapLayerCategoryRadar => '레이더';

  @override
  String get meshtasticShortName => 'Short name';

  @override
  String get mapLayerSatelliteAirmass => '히마와리 에어매스';

  @override
  String get typhoonTrackDetail => '경로 상세';

  @override
  String get dataSectionWeather => '기상';

  @override
  String get aedHoursWeekday => '평일 운영시간';

  @override
  String get homeActiveEventsTitle => '발효 중 이벤트';

  @override
  String weatherRankingAnalysisHigh(String value) {
    return '최고 $value';
  }

  @override
  String get faq => '자주 묻는 질문';

  @override
  String get typhoonHistoryLive => '실시간';

  @override
  String eewSerial(int serial) {
    return '제 $serial 보';
  }

  @override
  String get reportFilterSort => '정렬';

  @override
  String get meshtasticRegionConfirm =>
      'Switch this radio to the TW region? It restarts and disconnects for a moment, and every other channel on it moves too.';

  @override
  String get dataEarthquakeSubtitle => '지진 보고서';

  @override
  String get typhoonNoActive => '활성 태풍 없음';

  @override
  String get mapLayerSatelliteB11 => '히마와리 이산화황/구름상(B11)';

  @override
  String get navEvents => '이벤트';

  @override
  String get onboardingTermsTitle => '서비스 약관';

  @override
  String get mapTownLabels => '읍면동 이름';

  @override
  String get notifySetFailed => '설정을 저장하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get meshtasticDisconnect => 'Disconnect';

  @override
  String get meshtasticUndecoded => 'Not decrypted';

  @override
  String get notifyAnnouncement => '공지사항';

  @override
  String get onboardingIntroTitle => 'DPIP에 오신 것을 환영합니다';

  @override
  String get regionCurrentUnavailable => '현재 위치를 가져올 수 없습니다';

  @override
  String get languageSystem => '시스템 기본값';

  @override
  String get skyTimeSunset => '일몰';

  @override
  String get mapLayerSatelliteDust => '히마와리 황사';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String get regionEdit => '수정';

  @override
  String get weatherDynamicState => '날씨 애니메이션';

  @override
  String get mapPlaceholderDisabled => '지도 (일시 사용 중지)';

  @override
  String get moonNow => '지금';

  @override
  String get moonSectionAppearance => '겉모습';

  @override
  String get moonSectionRiseSet => '월출·월몰';

  @override
  String get moonSectionUpcoming => '다음 위상';

  @override
  String get moonSectionCalendar => '달력';

  @override
  String get moonDistance => '거리';

  @override
  String get moonKilometres => 'km';

  @override
  String get moonApparentSize => '시직경';

  @override
  String get moonRise => '월출';

  @override
  String get moonSet => '월몰';

  @override
  String get moonNextNewMoon => '다음 삭';

  @override
  String get moonAlwaysUp => '종일 지평선 위';

  @override
  String get moonNoEvent => '해당 없음';

  @override
  String get sunTitle => '태양';

  @override
  String get sunSubtitle => '일출·박명·절기';

  @override
  String get sunSectionDaylight => '일조';

  @override
  String get sunSectionTwilight => '박명';

  @override
  String get sunSectionLight => '빛';

  @override
  String get sunSectionSundial => '해시계';

  @override
  String get sunSectionTerms => '절기';

  @override
  String get sunRise => '일출';

  @override
  String get sunSet => '일몰';

  @override
  String get sunNoon => '남중';

  @override
  String get sunDayLength => '낮 길이';

  @override
  String get sunTwilightCivil => '시민';

  @override
  String get sunTwilightNautical => '항해';

  @override
  String get sunTwilightAstronomical => '천문';

  @override
  String get sunGoldenHourMorning => '아침 골든아워';

  @override
  String get sunGoldenHourEvening => '저녁 골든아워';

  @override
  String get sunBlueHour => '블루아워';

  @override
  String get sunEquationOfTime => '균시차';

  @override
  String get sunMinutes => '분';

  @override
  String get solarTermNext => '다음 절기';

  @override
  String get planetsTitle => '행성';

  @override
  String get planetsSubtitle => '오늘 밤 위치와 밝기';

  @override
  String get planetsSectionTonight => '현재';

  @override
  String get planetUp => '지평선 위';

  @override
  String get planetDown => '지평선 아래';

  @override
  String get planetInGlare => '태양에 근접';

  @override
  String get planetMagnitude => '등급';

  @override
  String get planetElongation => '이각';

  @override
  String get planetSky => '시간대';

  @override
  String get planetEvening => '초저녁';

  @override
  String get planetMorning => '새벽';

  @override
  String get planetDistance => '거리';

  @override
  String get planetAu => 'au';

  @override
  String get planetAltitude => '고도';

  @override
  String get planetMercury => '수성';

  @override
  String get planetVenus => '금성';

  @override
  String get planetMars => '화성';

  @override
  String get planetJupiter => '목성';

  @override
  String get planetSaturn => '토성';

  @override
  String get planetUranus => '천왕성';

  @override
  String get planetNeptune => '해왕성';

  @override
  String get solarTermVernalEquinox => '춘분';

  @override
  String get solarTermPureBrightness => '청명';

  @override
  String get solarTermGrainRain => '곡우';

  @override
  String get solarTermStartOfSummer => '입하';

  @override
  String get solarTermGrainFull => '소만';

  @override
  String get solarTermGrainInEar => '망종';

  @override
  String get solarTermSummerSolstice => '하지';

  @override
  String get solarTermMinorHeat => '소서';

  @override
  String get solarTermMajorHeat => '대서';

  @override
  String get solarTermStartOfAutumn => '입추';

  @override
  String get solarTermEndOfHeat => '처서';

  @override
  String get solarTermWhiteDew => '백로';

  @override
  String get solarTermAutumnalEquinox => '추분';

  @override
  String get solarTermColdDew => '한로';

  @override
  String get solarTermFrostDescent => '상강';

  @override
  String get solarTermStartOfWinter => '입동';

  @override
  String get solarTermMinorSnow => '소설';

  @override
  String get solarTermMajorSnow => '대설';

  @override
  String get solarTermWinterSolstice => '동지';

  @override
  String get solarTermMinorCold => '소한';

  @override
  String get solarTermMajorCold => '대한';

  @override
  String get solarTermStartOfSpring => '입춘';

  @override
  String get solarTermRainWater => '우수';

  @override
  String get solarTermAwakeningOfInsects => '경칩';

  @override
  String get tonightTitle => '오늘 밤';

  @override
  String get tonightSubtitle => '무엇을 언제 볼 수 있는가';

  @override
  String get tonightSectionDark => '관측 가능 시간';

  @override
  String get tonightAstronomicalNight => '천문박명 종료';

  @override
  String get tonightNeverDark => '완전히 어두워지지 않음';

  @override
  String get tonightDarkWindow => '암흑 시간대';

  @override
  String get tonightMoonAllNight => '달이 밤새 떠 있음';

  @override
  String get tonightDarkTotal => '총 암흑 시간';

  @override
  String get tonightMoonlight => '달빛';

  @override
  String get tonightSectionShowers => '유성우';

  @override
  String get tonightRadiantDown => '복사점이 뜨지 않음';

  @override
  String get tonightPerHour => '개/시';

  @override
  String get tonightSectionSatellites => '위성 통과';

  @override
  String get tonightSectionTargets => '지금 볼 수 있는 천체';

  @override
  String get showerQuadrantids => '사분의자리';

  @override
  String get showerLyrids => '거문고자리';

  @override
  String get showerEtaAquariids => '물병자리 에타';

  @override
  String get showerDeltaAquariids => '물병자리 델타';

  @override
  String get showerPerseids => '페르세우스자리';

  @override
  String get showerOrionids => '오리온자리';

  @override
  String get showerSouthernTaurids => '황소자리 남';

  @override
  String get showerLeonids => '사자자리';

  @override
  String get showerGeminids => '쌍둥이자리';

  @override
  String get showerUrsids => '작은곰자리';

  @override
  String get deepSkyOpenCluster => '산개성단';

  @override
  String get deepSkyGlobularCluster => '구상성단';

  @override
  String get deepSkySpiralGalaxy => '나선은하';

  @override
  String get deepSkyEllipticalGalaxy => '타원은하';

  @override
  String get deepSkyIrregularGalaxy => '불규칙은하';

  @override
  String get deepSkyPlanetaryNebula => '행성상성운';

  @override
  String get deepSkySupernovaRemnant => '초신성 잔해';

  @override
  String get deepSkyEmissionNebula => '발광성운';

  @override
  String get deepSkyReflectionNebula => '반사성운';

  @override
  String get deepSkyAsterism => '성군';

  @override
  String get almanacTitle => '역법';

  @override
  String get almanacSubtitle => '음력과 앞으로의 일식·월식';

  @override
  String get almanacSectionToday => '오늘';

  @override
  String get almanacGregorian => '양력';

  @override
  String get almanacLunar => '음력';

  @override
  String get almanacYear => '세차';

  @override
  String get almanacMonthLength => '월 대소';

  @override
  String get almanacLongMonth => '30일';

  @override
  String get almanacShortMonth => '29일';

  @override
  String get almanacLeapPrefix => '윤';

  @override
  String get almanacSectionLunarEclipses => '월식';

  @override
  String get almanacSectionSolarEclipses => '일식';

  @override
  String get almanacNoSolarEclipse => '범위 내 없음';

  @override
  String get eclipseTotal => '개기';

  @override
  String get eclipsePartial => '부분';

  @override
  String get eclipseAnnular => '금환';

  @override
  String get eclipsePenumbral => '반영';

  @override
  String get zodiacRat => '쥐';

  @override
  String get zodiacOx => '소';

  @override
  String get zodiacTiger => '호랑이';

  @override
  String get zodiacRabbit => '토끼';

  @override
  String get zodiacDragon => '용';

  @override
  String get zodiacSnake => '뱀';

  @override
  String get zodiacHorse => '말';

  @override
  String get zodiacGoat => '양';

  @override
  String get zodiacMonkey => '원숭이';

  @override
  String get zodiacRooster => '닭';

  @override
  String get zodiacDog => '개';

  @override
  String get zodiacPig => '돼지';

  @override
  String get tideTitle => '조석';

  @override
  String get tideSubtitle => '사리·조금과 달의 인력';

  @override
  String get tideDisclaimer => '천문 기조력만이며 항만 조석표가 아닙니다. 수위는 기상청 발표를 참고하세요.';

  @override
  String get tideSectionNow => '현재';

  @override
  String get tidePhase => '주기';

  @override
  String get tideSpring => '사리';

  @override
  String get tideNeap => '조금';

  @override
  String get tideMiddling => '중조';

  @override
  String get tideLunarDistanceFactor => '달의 인력';

  @override
  String get tideEquilibrium => '평형 조위';

  @override
  String get tideMetres => 'm';

  @override
  String get tidePerigeanSpring => '다음 근지점 사리';

  @override
  String get tideSectionTurningPoints => '전환점';

  @override
  String get tideHigh => '고';

  @override
  String get tideLow => '저';

  @override
  String get skyChartTitle => '성도';

  @override
  String get skyChartSubtitle => '머리 위 맨눈으로 보이는 하늘';

  @override
  String get skyChartNorth => '북';

  @override
  String get skyChartEast => '동';

  @override
  String get skyChartSouth => '남';

  @override
  String get skyChartWest => '서';

  @override
  String tonightElementAge(int days) {
    return '궤도 요소 $days일 전';
  }

  @override
  String almanacLunarDate(String leap, int month, int day) {
    return '$leap$month월 $day일';
  }

  @override
  String get tonightNoShowers => '진행 중인 유성우 없음';

  @override
  String get tonightNoPasses => '48시간 내 가시 통과 없음';

  @override
  String get tonightSatellitesUnavailable => '궤도 데이터를 읽을 수 없음';

  @override
  String get tonightNoTargets => '충분히 높은 천체 없음';

  @override
  String get skyChartUnavailable => '성표를 읽을 수 없음';

  @override
  String get permissionSettingsTitle => '설정에서 허용해 주세요';

  @override
  String get permissionSettingsHint => '앱으로 돌아오면 자동으로 다시 확인합니다.';

  @override
  String get permissionOpenSettings => '설정 열기';

  @override
  String permissionSettingsMessage(String what) {
    return '「$what」이(가) 거부되어 시스템이 다시 묻지 않습니다. 설정에서 허용해 주세요.';
  }

  @override
  String get displayTextSize => '글자 크기';

  @override
  String get displayTextSizeDesc => '앱 화면의 글자에만 적용되며 지도 라벨 크기는 바뀌지 않습니다.';

  @override
  String get displayTextWeight => '글자 굵기';

  @override
  String get displayTextWeightDesc => '글자를 굵게 하면 읽기가 더 쉬워질 수 있습니다.';

  @override
  String get displayContrast => '대비';

  @override
  String get displayContrastDesc => '대비를 높이면 글자와 배경이 더 뚜렷하게 구분됩니다.';

  @override
  String get displayColorVision => '색각 보정';

  @override
  String get displayColorVisionDesc => '지도 색상을 포함해 앱 전체의 색상이 조정됩니다.';

  @override
  String get displayColorVisionNone => '없음';

  @override
  String get displayColorVisionProtan => '적색약';

  @override
  String get displayColorVisionDeutan => '녹색약';

  @override
  String get displayColorVisionTritan => '청황색약';

  @override
  String get displayScaleSmall => '작게';

  @override
  String get displayScaleDefault => '기본';

  @override
  String get displayScaleLarge => '크게';

  @override
  String get displayScaleHuge => '아주 크게';

  @override
  String get displayWeightNormal => '보통';

  @override
  String get displayWeightMedium => '중간';

  @override
  String get displayWeightBold => '굵게';

  @override
  String get displayContrastStandard => '표준';

  @override
  String get displayContrastMedium => '중간';

  @override
  String get displayContrastHigh => '높음';
}
