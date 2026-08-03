// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get languageName => 'ไทย';

  @override
  String get navHome => 'หน้าแรก';

  @override
  String get navEvents => 'เหตุการณ์';

  @override
  String get navMap => 'แผนที่';

  @override
  String get navData => 'ข้อมูล';

  @override
  String get navEarthquake => 'แผ่นดินไหว';

  @override
  String get dataSectionSeismic => 'แผ่นดินไหว';

  @override
  String get dataEarthquakeSubtitle => 'รายงานแผ่นดินไหว';

  @override
  String get reportListEmpty => 'ไม่มีรายงานแผ่นดินไหว';

  @override
  String reportListMeta(String magnitude, String depth) {
    return 'M$magnitude · $depth km';
  }

  @override
  String get reportListEnd => 'สิ้นสุดรายการ';

  @override
  String get reportFilterTitle => 'ตัวกรอง';

  @override
  String get reportFilterIntensity => 'ความเข้ม';

  @override
  String get reportFilterMagnitude => 'ขนาด';

  @override
  String get reportFilterDepth => 'ความลึก';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get reportFilterDate => 'วันที่';

  @override
  String get reportFilterDatePick => 'เลือกวันที่';

  @override
  String get reportFilterDateStartNote => 'วันเริ่ม: 00:00 ของวันนั้น（ไทเป）';

  @override
  String get reportFilterDateEndNote => 'วันสิ้นสุด: 24:00 ของวันนั้น（ไทเป）';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportFilterLocation => 'สถานที่';

  @override
  String get reportFilterLocationHint => 'เช่น ฮวาเหลียน';

  @override
  String get reportFilterAny => 'ทั้งหมด';

  @override
  String get reportFilterApply => 'ใช้';

  @override
  String get reportFilterReset => 'รีเซ็ต';

  @override
  String get navMore => 'เพิ่มเติม';

  @override
  String get appLogs => 'บันทึกแอป';

  @override
  String get mapPlaceholderDisabled => 'แผนที่ (ปิดใช้งานชั่วคราว)';

  @override
  String get moreSectionGeneral => 'ทั่วไป';

  @override
  String get regionManageTitle => 'พื้นที่ที่ใช้บ่อย';

  @override
  String get regionAddButton => 'เพิ่มพื้นที่';

  @override
  String get regionEmpty => 'ยังไม่มีพื้นที่ที่บันทึกไว้';

  @override
  String get regionSelectTitle => 'เลือกพื้นที่';

  @override
  String regionSelectCount(int count, int max) {
    return 'เลือกแล้ว $count/$max';
  }

  @override
  String regionSelectFull(int max) {
    return 'บันทึกได้สูงสุด $max พื้นที่';
  }

  @override
  String get moreSectionAdvanced => 'ขั้นสูง';

  @override
  String get moreDeveloper => 'ข้อมูลดีบัก';

  @override
  String get developerCopied => 'คัดลอกไปยังคลิปบอร์ดแล้ว';

  @override
  String get developerCopyAll => 'คัดลอกทั้งหมด';

  @override
  String get experimentalFeatures => 'ฟีเจอร์ทดลอง';

  @override
  String get moreSectionLinks => 'ลิงก์ที่เกี่ยวข้อง';

  @override
  String get moreCwaEew =>
      'การเตือนแผ่นดินไหวล่วงหน้าของกรมอุตุนิยมวิทยากลาง (CWA)';

  @override
  String get moreTremReport => 'รายงานการตรวจจับ TREM';

  @override
  String get moreServerStatus => 'สถานะเซิร์ฟเวอร์';

  @override
  String get moreAnnouncements => 'ประกาศ';

  @override
  String get moreDiscord => 'ชุมชน Discord';

  @override
  String get moreNotifyLog => 'บันทึกการส่งการแจ้งเตือนของ DPIP';

  @override
  String get moreLinkOpenFailed => 'ไม่สามารถเปิดลิงก์ได้';

  @override
  String get weatherDynamicState => 'แอนิเมชันสภาพอากาศ';

  @override
  String get weatherDynamicStateSubtitle => 'แทนที่สภาพอากาศพื้นหลังหน้าแรก';

  @override
  String get weatherModeAuto => 'อัตโนมัติ';

  @override
  String get weatherModeClear => 'ท้องฟ้าแจ่มใส';

  @override
  String get weatherModeRain => 'ฝนตก';

  @override
  String get weatherModeFog => 'หมอกหนา';

  @override
  String get weatherModeThunderstorm => 'พายุฝนฟ้าคะนอง';

  @override
  String get commonLoading => 'กำลังโหลด…';

  @override
  String get commonRetry => 'ลองอีกครั้ง';

  @override
  String get commonError => 'เกิดข้อผิดพลาด';

  @override
  String get commonFetchFailed => 'ไม่สามารถโหลดข้อมูลได้ โปรดลองอีกครั้ง';

  @override
  String get commonEmpty => 'ไม่มีข้อมูล';

  @override
  String get feedConnecting => 'กำลังเชื่อมต่อ…';

  @override
  String get feedStale => 'ข้อมูลอาจล้าสมัย';

  @override
  String get feedOffline => 'การเชื่อมต่อขาดหาย';

  @override
  String get eewTitle => 'การเตือนแผ่นดินไหวล่วงหน้า';

  @override
  String get eewNone => 'ขณะนี้ไม่มีการเตือนแผ่นดินไหวล่วงหน้า';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'ขนาด $magnitude · ความลึก $depth กม.';
  }

  @override
  String get regionNationwide => 'ทั่วประเทศ';

  @override
  String get regionCurrent => 'ตำแหน่งปัจจุบัน';

  @override
  String get regionCurrentUnavailable => 'ไม่สามารถระบุตำแหน่งปัจจุบันได้';

  @override
  String get weatherPrecipitation => 'ปริมาณน้ำฝน';

  @override
  String get weatherHumidity => 'ความชื้น';

  @override
  String get mapLayers => 'ชั้นข้อมูล';

  @override
  String get mapLayerRadar => 'เรดาร์สะท้อนสังเคราะห์';

  @override
  String get mapLayerSatellite => 'ฮิมาวาริ อินฟราเรด';

  @override
  String get mapTimelineNow => 'ตอนนี้';

  @override
  String get mapTimelineObserved => 'เวลาตรวจวัด';

  @override
  String get notifySettingsMenu => 'การตั้งค่าการแจ้งเตือน';

  @override
  String get notifyTitle => 'การแจ้งเตือน';

  @override
  String get notifyUnavailable =>
      'การแจ้งเตือนแบบพุชยังไม่พร้อม — โปรดลองอีกครั้งในภายหลัง';

  @override
  String get notifySetFailed => 'ไม่สามารถบันทึกการตั้งค่าได้ โปรดลองอีกครั้ง';

  @override
  String get notifySectionEew => 'การเตือนแผ่นดินไหวล่วงหน้า';

  @override
  String get notifySectionEarthquake => 'แผ่นดินไหว';

  @override
  String get notifySectionWeather => 'สภาพอากาศ';

  @override
  String get notifySectionTsunami => 'สึนามิ';

  @override
  String get notifySectionOther => 'อื่น ๆ';

  @override
  String get notifyEew => 'การเตือนแผ่นดินไหวฉุกเฉิน';

  @override
  String get notifyMonitor => 'เครื่องเฝ้าระวังการสั่นสะเทือนรุนแรง';

  @override
  String get notifyReport => 'รายงานแผ่นดินไหว';

  @override
  String get notifyIntensity => 'รายงานความรุนแรงแผ่นดินไหว';

  @override
  String get notifyThunderstorm => 'การแจ้งเตือนพายุฝนฟ้าคะนอง';

  @override
  String get notifyAdvisory => 'การแจ้งเตือนและประกาศสภาพอากาศ';

  @override
  String get notifyEvacuation => 'ข้อมูลภัยพิบัติ';

  @override
  String get notifyTsunami => 'ข้อมูลสึนามิ';

  @override
  String get notifyAnnouncement => 'ประกาศ';

  @override
  String get notifyOptOff => 'ปิด';

  @override
  String get notifyOptAll => 'รับทั้งหมด';

  @override
  String get notifyOptLocalIntensity4 => 'ความรุนแรงในพื้นที่ระดับ 4 ขึ้นไป';

  @override
  String get notifyOptLocalIntensity1 => 'ความรุนแรงในพื้นที่ระดับ 1 ขึ้นไป';

  @override
  String get notifyOptWeatherLocal => 'เฉพาะตำแหน่งปัจจุบัน';

  @override
  String get notifyOptTsunamiWarning => 'เฉพาะการเตือนภัยสึนามิ';

  @override
  String get notifyOptTsunamiAll => 'ข่าวสารและการเตือนภัยสึนามิ';

  @override
  String get onboardingNext => 'ถัดไป';

  @override
  String get onboardingBack => 'ย้อนกลับ';

  @override
  String get onboardingScrollHint => 'เลื่อนลงเพื่อดำเนินการต่อ';

  @override
  String get onboardingIntroTitle => 'ยินดีต้อนรับสู่ DPIP';

  @override
  String get onboardingIntroBody =>
      'DPIP คือเพื่อนคู่ใจด้านการป้องกันภัยพิบัติของคุณ รวมการเตือนแผ่นดินไหวล่วงหน้า รายงานแผ่นดินไหว สภาพอากาศ และข้อมูลภัยพิบัติต่าง ๆ ไว้ในที่เดียว และแจ้งเตือนคุณในช่วงเวลาสำคัญ\n\n• แผ่นดินไหว: การเตือนล่วงหน้า รายงานความรุนแรง และรายงานฉบับสมบูรณ์\n• สภาพอากาศ: ข้อความพายุฝนฟ้าคะนองแบบเรียลไทม์ และการแจ้งเตือนสภาพอากาศ\n• ข้อมูลสึนามิและภัยพิบัติ\n\nต่อไป เราจะขอให้คุณอ่านข้อกำหนดการให้บริการ และอนุญาตสิทธิ์บางอย่างเพื่อให้ DPIP สามารถปกป้องคุณได้แบบเรียลไทม์';

  @override
  String get onboardingTermsTitle => 'ข้อกำหนดการให้บริการ';

  @override
  String get onboardingTermsBody =>
      'โปรดอ่านข้อควรทราบต่อไปนี้ก่อนใช้งาน DPIP:\n\n• ข้อมูลทั้งหมดควรยึดตามเนื้อหาที่เผยแพร่โดยกรมอุตุนิยมวิทยากลาง (CWA) เป็นหลัก\n\n• ขึ้นอยู่กับสภาพเครือข่าย เซิร์ฟเวอร์ แอปพลิเคชัน และแหล่งข้อมูลต้นทาง อาจมีความเป็นไปได้ที่จะไม่ได้รับข้อมูล เราพยายามอย่างเต็มที่เพื่อหลีกเลี่ยงกรณีเช่นนี้ แต่ไม่สามารถรับประกันได้ว่าจะไม่เกิดขึ้น\n\n• การสั่นสะเทือนอย่างรุนแรงอาจมาถึงตำแหน่งของคุณก่อนการแจ้งเตือน\n\n• การเตือนแผ่นดินไหวล่วงหน้าเป็นผลจากการคำนวณอย่างรวดเร็ว ซึ่งอาจมีความคลาดเคลื่อนสูง โปรดทำความเข้าใจและใช้งานด้วยความระมัดระวัง\n\n• พฤติกรรมใด ๆ ที่ไม่ได้รับการรับรองจากหน่วยงานราชการอาจมีความเสี่ยงทางกฎหมาย โปรดปฏิบัติตามระเบียบที่เกี่ยวข้องทั้งหมด\n\nนอกจากนี้ เพื่อให้บริการการเตือนภัยเฉพาะพื้นที่ บริการนี้จะเก็บรวบรวมและอัปโหลดตำแหน่งโดยประมาณและตัวระบุการแจ้งเตือนแบบพุชของคุณ — ทั้งขณะทำงานเบื้องหน้าและเบื้องหลัง — เพื่อใช้ตัดสินว่าจะส่งการเตือนใดให้คุณเท่านั้น\n\nการแตะ \"ยอมรับและดำเนินการต่อ\" ถือว่าคุณได้อ่าน เข้าใจ และยอมรับข้อความข้างต้นแล้ว';

  @override
  String get onboardingTermsAgree =>
      'ฉันได้อ่านและยอมรับข้อกำหนดการให้บริการแล้ว';

  @override
  String get onboardingAgreeContinue => 'ยอมรับและดำเนินการต่อ';

  @override
  String get onboardingPermsTitle => 'การอนุญาตสิทธิ์';

  @override
  String get onboardingPermsBody =>
      'เพื่อให้ DPIP แจ้งเตือนคุณได้ในทันทีที่เกิดภัยพิบัติ โปรดอนุญาตสิทธิ์ต่อไปนี้ คุณสามารถเปลี่ยนแปลงได้ทุกเมื่อในการตั้งค่าระบบ';

  @override
  String get onboardingPermNotify => 'การแจ้งเตือน';

  @override
  String get onboardingPermNotifyDesc =>
      'ส่งการเตือนแผ่นดินไหว สภาพอากาศ และภัยพิบัติทันทีที่เกิดขึ้น';

  @override
  String get onboardingPermCritical => 'การแจ้งเตือนสำคัญ';

  @override
  String get onboardingPermCriticalDesc =>
      'ให้การเตือนแผ่นดินไหวที่เป็นอันตรายถึงชีวิตส่งเสียงได้ แม้อยู่ในโหมดเงียบหรือโหมดห้ามรบกวน';

  @override
  String get onboardingPermLocation => 'ตำแหน่งที่ตั้ง';

  @override
  String get onboardingPermLocationDesc => 'ส่งการเตือนภัยตามตำแหน่งที่คุณอยู่';

  @override
  String get onboardingPermBackground => 'ตำแหน่งที่ตั้งเบื้องหลัง';

  @override
  String get onboardingPermBackgroundDesc =>
      'อนุญาต \"ทุกครั้ง\" เพื่อให้การเตือนภัยยังส่งถึงคุณได้แม้ปิดแอป';

  @override
  String get onboardingPermBattery => 'ยกเว้นการประหยัดแบตเตอรี่';

  @override
  String get onboardingPermBatteryDesc =>
      'อนุญาตให้ DPIP ทำงานเบื้องหลังอย่างต่อเนื่อง เพื่อไม่ให้การเตือนภัยล่าช้าหรือพลาดไป';

  @override
  String get onboardingGrant => 'อนุญาต';

  @override
  String get onboardingGranted => 'อนุญาตแล้ว';

  @override
  String get onboardingStart => 'เริ่มใช้งาน';

  @override
  String get language => 'ภาษา';

  @override
  String get languageSettings => 'ภาษา';

  @override
  String get languageSystem => 'ค่าเริ่มต้นของระบบ';

  @override
  String get locationBannerServiceOff =>
      'บริการระบุตำแหน่งถูกปิด — ไม่สามารถส่งการเตือนภัยเฉพาะพื้นที่ของคุณได้';

  @override
  String get locationBannerPermission =>
      'ยังไม่ได้อนุญาตสิทธิ์ตำแหน่งที่ตั้ง — ไม่สามารถส่งการเตือนภัยเฉพาะพื้นที่ของคุณได้';

  @override
  String get locationBannerFix => 'เปิดการตั้งค่า';

  @override
  String get notifyBannerDisabled =>
      'ปิดการแจ้งเตือนอยู่ — คุณจะไม่ได้รับการเตือนภัยพิบัติ';

  @override
  String get onboardingSkipTitle => 'ยังไม่ได้ให้สิทธิ์';

  @override
  String get onboardingSkipBody =>
      'หากไม่อนุญาตตำแหน่งและการแจ้งเตือน DPIP จะไม่สามารถแจ้งเตือนแผ่นดินไหวและภัยพิบัติใกล้คุณแบบเรียลไทม์ได้ คุณยังสามารถเปิดใช้ภายหลังได้ในการตั้งค่า';

  @override
  String get onboardingSkipStay => 'กลับไปให้สิทธิ์';

  @override
  String get onboardingSkipLeave => 'ข้ามไปก่อน';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get moreSourceCode => 'ซอร์สโค้ด';

  @override
  String get moreSectionApp => 'ดาวน์โหลดแอป';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get displaySettings => 'การแสดงผล';

  @override
  String get displayTheme => 'ธีม';

  @override
  String get themeSystem => 'ระบบ';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get themeDark => 'มืด';

  @override
  String get moreSectionAbout => 'เกี่ยวกับ';

  @override
  String get termsOfService => 'ข้อกำหนดในการให้บริการ';

  @override
  String get faq => 'คำถามที่พบบ่อย';

  @override
  String get openSourceLicenses => 'ใบอนุญาตโอเพนซอร์ส';

  @override
  String get sponsorTitle => 'สนับสนุน DPIP';

  @override
  String get sponsorIntro =>
      'DPIP มุ่งมั่นให้ข้อมูลการป้องกันภัยพิบัติแบบเรียลไทม์ โดยไม่มีโฆษณาหรือรูปแบบหารายได้อื่น การสนับสนุนของคุณช่วยให้เรารักษาเซิร์ฟเวอร์และพัฒนาต่อไปได้';

  @override
  String get sponsorSubscriptions => 'แบบสมัครสมาชิก';

  @override
  String get sponsorRecommended => 'แนะนำ';

  @override
  String get sponsorOneTime => 'สนับสนุนครั้งเดียว';

  @override
  String sponsorPerMonth(String price) {
    return '$price / เดือน';
  }

  @override
  String get sponsorRestore => 'กู้คืนการซื้อ';

  @override
  String get sponsorTerms => 'ข้อกำหนดการใช้งาน';

  @override
  String get sponsorPrivacy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get sponsorRestoring => 'กำลังกู้คืนการซื้อ…';

  @override
  String get sponsorRestoreUnavailable =>
      'ไม่สามารถเชื่อมต่อร้านค้าได้ โปรดลองอีกครั้งภายหลัง';

  @override
  String get commonClose => 'ปิด';

  @override
  String get mapLayerTemperature => 'อุณหภูมิ';

  @override
  String get trendRange24h => '24 ชม.';

  @override
  String get trendRange7d => '7 วัน';

  @override
  String get trendNoData => 'ไม่มีข้อมูลแนวโน้ม';

  @override
  String get mapLayerHumidity => 'ความชื้น';

  @override
  String get mapLayerPressure => 'ความกดอากาศ';

  @override
  String get mapLayerWind => 'ลม';

  @override
  String get mapLayerTyphoon => 'ไต้ฝุ่น';

  @override
  String get typhoonNoActive => 'ไม่มีไต้ฝุ่น';

  @override
  String get typhoonWind => 'ความเร็วลม';

  @override
  String get typhoonGust => 'ลมกระโชก';

  @override
  String get typhoonPressure => 'ความกดอากาศ';

  @override
  String get typhoonMotion => 'เคลื่อนที่';

  @override
  String get typhoonLabelPosition => 'Centre location';

  @override
  String get typhoonLabelDirection => 'Past movement direction';

  @override
  String get typhoonLabelSpeed => 'Past movement speed';

  @override
  String get typhoonLabelPressure => 'Central pressure';

  @override
  String get typhoonLabelWind => 'Max. sustained wind near centre';

  @override
  String get typhoonLabelGust => 'Peak gust';

  @override
  String get typhoonLabelGaleAvg => 'Avg. radius of Beaufort 7 winds';

  @override
  String get typhoonLabelStormAvg => 'Avg. radius of Beaufort 10 winds';

  @override
  String get typhoonLabelProbCircle => '70% probability circle';

  @override
  String typhoonForecastLead(String hours) {
    return 'Forecast +$hours h';
  }

  @override
  String get typhoonLabelNw => 'NW';

  @override
  String get typhoonLabelNe => 'NE';

  @override
  String get typhoonLabelSw => 'SW';

  @override
  String get typhoonLabelSe => 'SE';

  @override
  String typhoonValueLat(String lat) {
    return '$lat°N';
  }

  @override
  String typhoonValueLon(String lon) {
    return '$lon°E';
  }

  @override
  String typhoonValueKm(String n) {
    return '$n km';
  }

  @override
  String typhoonValueHpa(String n) {
    return '$n hPa';
  }

  @override
  String typhoonValueMs(String n) {
    return '$n m/s';
  }

  @override
  String typhoonDataTime(String time) {
    return 'Data time\n$time';
  }

  @override
  String get mapLayerMonitor => 'เครื่องตรวจแผ่นดินไหว';

  @override
  String get stationSheetEmpty => 'แตะสถานีเพื่อดูค่าที่วัดได้';

  @override
  String monitorDelay(String value) {
    return 'หน่วงเวลา $value s';
  }

  @override
  String get monitorWaiting => 'กำลังรอข้อมูล…';

  @override
  String mapLegendUnit(String unit) {
    return 'หน่วย: $unit';
  }

  @override
  String get typhoonLegendPast => 'เส้นทางจริง';

  @override
  String get typhoonIntensityTd => 'Tropical depression';

  @override
  String get typhoonIntensityMild => 'Mild typhoon';

  @override
  String get typhoonIntensityModerate => 'Moderate typhoon';

  @override
  String get typhoonIntensityIntense => 'Intense typhoon';

  @override
  String get typhoonLegendForecast => 'เส้นทางพยากรณ์';

  @override
  String get typhoonLegendForecastPoint => 'จุดพยากรณ์';

  @override
  String get typhoonLegendCurrent => 'ศูนย์กลางปัจจุบัน';

  @override
  String get typhoonLegendCone => 'กรวยพยากรณ์';

  @override
  String get mapLegendExpand => 'คำอธิบาย';

  @override
  String get mapLegendCollapse => 'ซ่อนคำอธิบาย';

  @override
  String get typhoonLegendCircle15 => 'วงพายุ (แรง)';

  @override
  String get typhoonLegendCircleAvg => 'Average circle';

  @override
  String get typhoonLegendCircle25 => 'วงพายุ (รุนแรง)';

  @override
  String typhoonStormRadii(String ne, String se, String sw, String nw) {
    return 'NE $ne · SE $se · SW $sw · NW $nw km';
  }

  @override
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get typhoonLegendProbability => 'โอกาสกระทบ';

  @override
  String get typhoonLegendWarningAreas => 'พื้นที่เตือนภัย';

  @override
  String get typhoonOverlayMenuTooltip => 'Typhoon overlay options';

  @override
  String get typhoonOverlaySectionStorm => 'Storm wind';

  @override
  String get typhoonOverlaySectionExtra => 'Overlays';

  @override
  String get typhoonOverlayStormBandSubtitle => 'With average circle';

  @override
  String get typhoonOverlayProbabilityHint => 'Hides the forecast cone';

  @override
  String get typhoonOverlayProbabilityTooltip =>
      'Show strike probability (hides the forecast cone)';

  @override
  String get typhoonOverlayWarningTooltip =>
      'Highlight counties under a typhoon warning';

  @override
  String get typhoonOverlayStormL7Tooltip =>
      'Level-7 wind field + average circle (purple)';

  @override
  String get typhoonOverlayStormL10Tooltip =>
      'Level-10 wind field + average circle (yellow)';

  @override
  String get typhoonOverlaySectionWeather => 'Weather underlay';

  @override
  String get typhoonOverlayWeatherNone => 'None';

  @override
  String get typhoonOverlayWeatherHint => 'Aligned to bulletin time';

  @override
  String get typhoonOverlayWeatherNoneTooltip =>
      'No radar or infrared underlay';

  @override
  String get typhoonOverlayWeatherRadarTooltip =>
      'Radar echo closest to the typhoon bulletin time';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip =>
      'Infrared closest to the typhoon bulletin time';

  @override
  String get typhoonWarningTitle => 'ประกาศเตือนไต้ฝุ่น';

  @override
  String typhoonWarningAreas(String areas) {
    return 'พื้นที่: $areas';
  }

  @override
  String get typhoonTrackDetail => 'รายละเอียดเส้นทาง';

  @override
  String get typhoonHistoryTitle => 'เวลาข้อมูล';

  @override
  String get typhoonHistoryLive => 'สด';

  @override
  String get typhoonSatelliteTitle => 'ดาวเทียม';

  @override
  String get typhoonOverlayForecastCallouts => 'Forecast tooltips';

  @override
  String get typhoonOverlayForecastCalloutsTooltip =>
      'Show forecast-point detail cards when zoomed in';
}
