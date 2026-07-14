// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get languageName => '한국어';

  @override
  String get navHome => '홈';

  @override
  String get navEvents => '이벤트';

  @override
  String get navMap => '지도';

  @override
  String get navEarthquake => '지진';

  @override
  String get navMore => '더보기';

  @override
  String get appLogs => '앱 로그';

  @override
  String get mapPlaceholderDisabled => '지도 (일시 사용 중지)';

  @override
  String get moreSectionGeneral => '일반';

  @override
  String get regionManageTitle => '저장한 지역';

  @override
  String get regionSelectTitle => '지역 선택';

  @override
  String regionSelectCount(int count, int max) {
    return '$count/$max 선택됨';
  }

  @override
  String regionSelectFull(int max) {
    return '최대 $max개 지역까지 저장할 수 있습니다';
  }

  @override
  String get moreSectionAdvanced => '고급';

  @override
  String get moreDeveloper => '디버그 정보';

  @override
  String get developerCopied => '클립보드에 복사되었습니다';

  @override
  String get developerCopyAll => '모두 복사';

  @override
  String get experimentalFeatures => '실험적 기능';

  @override
  String get moreSectionLinks => '링크';

  @override
  String get moreCwaEew => '중앙기상청(CWA) 지진 조기경보';

  @override
  String get moreTremReport => 'TREM 탐지 보고';

  @override
  String get moreServerStatus => '서버 상태';

  @override
  String get moreAnnouncements => '공지사항';

  @override
  String get moreDiscord => 'Discord 커뮤니티';

  @override
  String get moreNotifyLog => 'DPIP 알림 발송 기록';

  @override
  String get moreLinkOpenFailed => '링크를 열 수 없습니다';

  @override
  String get weatherDynamicState => '날씨 애니메이션';

  @override
  String get weatherDynamicStateSubtitle => '홈 배경 날씨를 재정의합니다';

  @override
  String get weatherModeAuto => '자동';

  @override
  String get weatherModeClear => '맑음';

  @override
  String get weatherModeRain => '비';

  @override
  String get weatherModeFog => '안개';

  @override
  String get weatherModeThunderstorm => '뇌우';

  @override
  String get commonLoading => '불러오는 중…';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonError => '문제가 발생했습니다';

  @override
  String get commonFetchFailed => '데이터를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get commonEmpty => '표시할 내용이 없습니다';

  @override
  String get feedConnecting => '연결 중…';

  @override
  String get feedStale => '데이터가 오래되었을 수 있습니다';

  @override
  String get feedOffline => '연결이 끊어졌습니다';

  @override
  String get eewTitle => '지진 조기경보';

  @override
  String get eewNone => '현재 지진 조기경보가 없습니다';

  @override
  String eewSummary(String magnitude, String depth) {
    return '규모 $magnitude · 깊이 $depth km';
  }

  @override
  String get regionNationwide => '전국';

  @override
  String get regionCurrent => '현재 위치';

  @override
  String get regionCurrentUnavailable => '현재 위치를 가져올 수 없습니다';

  @override
  String get weatherPrecipitation => '강수량';

  @override
  String get weatherHumidity => '습도';

  @override
  String get mapLayers => '레이어';

  @override
  String get mapLayerRadar => '레이더';

  @override
  String get mapTimelineNow => '현재';

  @override
  String get mapTimelineObserved => '관측';

  @override
  String get notifySettingsMenu => '알림 설정';

  @override
  String get notifyTitle => '알림';

  @override
  String get notifyUnavailable => '푸시 알림이 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get notifySetFailed => '설정을 저장하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get notifySectionEew => '지진 조기경보';

  @override
  String get notifySectionEarthquake => '지진';

  @override
  String get notifySectionWeather => '날씨';

  @override
  String get notifySectionTsunami => '지진해일';

  @override
  String get notifySectionOther => '기타';

  @override
  String get notifyEew => '긴급 지진 경보';

  @override
  String get notifyMonitor => '강진 감시기';

  @override
  String get notifyReport => '지진 보고';

  @override
  String get notifyIntensity => '진도 속보';

  @override
  String get notifyThunderstorm => '뇌우 알림';

  @override
  String get notifyAdvisory => '기상 특보';

  @override
  String get notifyEvacuation => '재난 정보';

  @override
  String get notifyTsunami => '지진해일 정보';

  @override
  String get notifyAnnouncement => '공지사항';

  @override
  String get notifyOptOff => '끄기';

  @override
  String get notifyOptAll => '전체 수신';

  @override
  String get notifyOptLocalIntensity4 => '현재 위치 진도 4 이상';

  @override
  String get notifyOptLocalIntensity1 => '현재 위치 진도 1 이상';

  @override
  String get notifyOptWeatherLocal => '현재 위치만';

  @override
  String get notifyOptTsunamiWarning => '지진해일 경보만';

  @override
  String get notifyOptTsunamiAll => '지진해일 주의보 및 경보';

  @override
  String get onboardingNext => '다음';

  @override
  String get onboardingBack => '이전';

  @override
  String get onboardingScrollHint => '계속하려면 아래로 스크롤하세요';

  @override
  String get onboardingIntroTitle => 'DPIP에 오신 것을 환영합니다';

  @override
  String get onboardingIntroBody =>
      'DPIP는 여러분과 함께하는 방재 파트너입니다. 지진 조기경보, 지진 보고, 날씨, 각종 재해 정보를 통합하여 중요한 순간에 실시간으로 알려드립니다.\n\n• 지진: 지진 조기경보, 진도 속보, 상세 지진 보고\n• 날씨: 뇌우 실시간 메시지, 기상 특보\n• 지진해일 및 재난 정보\n\n다음으로, 서비스 약관을 확인하고 DPIP가 실시간으로 여러분을 보호할 수 있도록 몇 가지 권한을 허용해 주시기 바랍니다.';

  @override
  String get onboardingTermsTitle => '서비스 약관';

  @override
  String get onboardingTermsBody =>
      'DPIP를 사용하기 전에 다음 유의 사항을 반드시 읽어 주세요:\n\n• 모든 정보는 중앙기상청(CWA)에서 발표한 내용을 기준으로 합니다.\n\n• 네트워크, 서버, 애플리케이션, 상위 데이터 출처의 상태에 따라 정보를 받지 못할 수 있습니다. 이러한 상황을 방지하기 위해 최선을 다하고 있으나, 절대 발생하지 않는다고 보장할 수는 없습니다.\n\n• 강한 흔들림이 알림보다 먼저 귀하의 위치에 도달할 수 있습니다.\n\n• 지진 조기경보는 빠르게 계산된 결과로 상당한 오차가 있을 수 있으므로, 이를 이해하고 신중하게 사용하시기 바랍니다.\n\n• 당국이 승인하지 않은 모든 행위는 법적 위험을 수반할 수 있으니, 관련 규정을 반드시 준수해 주세요.\n\n또한 지역 맞춤형 경보를 제공하기 위해, 본 서비스는 귀하에게 어떤 경보를 보낼지 결정하기 위한 목적으로만 포그라운드 및 백그라운드에서 귀하의 대략적인 위치와 푸시 식별자를 수집하여 업로드합니다.\n\n하단의 “동의하고 계속”을 누르면 위 사항을 읽고 이해했으며 이에 동의함을 확인하는 것입니다.';

  @override
  String get onboardingTermsAgree => '서비스 약관을 읽었으며 이에 동의합니다';

  @override
  String get onboardingAgreeContinue => '동의하고 계속';

  @override
  String get onboardingPermsTitle => '권한 허용';

  @override
  String get onboardingPermsBody =>
      '재해가 발생하는 즉시 알려드릴 수 있도록 다음 권한을 허용해 주세요. 시스템 설정에서 언제든지 변경할 수 있습니다.';

  @override
  String get onboardingPermNotify => '알림';

  @override
  String get onboardingPermNotifyDesc => '지진, 날씨, 재해가 발생하는 즉시 경보를 전달합니다.';

  @override
  String get onboardingPermCritical => '중요 알림';

  @override
  String get onboardingPermCriticalDesc =>
      '생명을 위협하는 지진 경보가 무음 모드나 방해 금지 모드에서도 소리를 낼 수 있도록 합니다.';

  @override
  String get onboardingPermLocation => '위치';

  @override
  String get onboardingPermLocationDesc => '현재 위치에 맞춰 경보를 전달합니다.';

  @override
  String get onboardingPermBackground => '백그라운드 위치';

  @override
  String get onboardingPermBackgroundDesc =>
      '“항상 허용”을 선택하면 앱이 종료된 상태에서도 위치 맞춤 경보를 받을 수 있습니다.';

  @override
  String get onboardingPermBattery => '배터리 최적화 제외';

  @override
  String get onboardingPermBatteryDesc =>
      'DPIP가 백그라운드에서 계속 실행되어 경보가 지연되거나 누락되지 않도록 허용합니다.';

  @override
  String get onboardingGrant => '허용';

  @override
  String get onboardingGranted => '허용됨';

  @override
  String get onboardingStart => '시작하기';

  @override
  String get language => '언어';

  @override
  String get languageSettings => '언어';

  @override
  String get languageSystem => '시스템 기본값';

  @override
  String get locationBannerServiceOff => '위치 서비스가 꺼져 있어 지역 맞춤 경보를 받을 수 없습니다.';

  @override
  String get locationBannerPermission => '위치 권한이 꺼져 있어 지역 맞춤 경보를 받을 수 없습니다.';

  @override
  String get locationBannerFix => '설정 열기';

  @override
  String get notifyBannerDisabled => '알림이 꺼져 있어 재난 경보를 받을 수 없습니다.';

  @override
  String get onboardingSkipTitle => '권한이 허용되지 않았습니다';

  @override
  String get onboardingSkipBody =>
      '위치 및 알림 권한이 없으면 DPIP가 주변의 지진과 재난을 실시간으로 알려드릴 수 없습니다. 나중에 설정에서 권한을 허용할 수 있습니다.';

  @override
  String get onboardingSkipStay => '돌아가기';

  @override
  String get onboardingSkipLeave => '그래도 건너뛰기';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get moreSourceCode => '소스 코드';

  @override
  String get moreSectionApp => '앱 다운로드';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get moreAppStore => 'App Store';
}
