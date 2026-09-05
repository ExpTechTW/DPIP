// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String typhoonValueLat(String lat) {
    return '$lat°N';
  }

  @override
  String get onboardingSkipBody =>
      'หากไม่อนุญาตตำแหน่งและการแจ้งเตือน DPIP จะไม่สามารถแจ้งเตือนแผ่นดินไหวและภัยพิบัติใกล้คุณแบบเรียลไทม์ได้ คุณยังสามารถเปิดใช้ภายหลังได้ในการตั้งค่า';

  @override
  String get rainInterval24h => '24 ชม.';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return 'คาดว่าฝนตกหนักจะหยุดในอีก $minutes นาที';
  }

  @override
  String get mapTimelineObserved => 'เวลาตรวจวัด';

  @override
  String get mapTimelineScrubPaused =>
      'ลากเร็วเกินไป การอัปเดตเฟรมจึงหยุดชั่วคราว ลดความเร็วเพื่อทำงานต่อ';

  @override
  String get regionSelectTitle => 'เลือกพื้นที่';

  @override
  String get skyTimeNoon => 'เที่ยงวัน';

  @override
  String get radarCountyOutlineSubtitle =>
      'ทำให้เส้นแบ่งเขตยังอ่านออกใต้ภาพเอคโคเรดาร์';

  @override
  String get mapLayerSatelliteB03 => 'Himawari Red (B03)';

  @override
  String get reportFilterIntensity => 'ความเข้ม';

  @override
  String get mapLayerLightning => 'ฟ้าผ่า';

  @override
  String get restroomTypeMale => 'ห้องน้ำชาย';

  @override
  String get meshtasticLastReceived => 'รับล่าสุด';

  @override
  String get reportDetailSortByCounty => 'เรียงตามพื้นที่';

  @override
  String get onboardingPermUnusedApp => 'ให้แอปทำงานต่อเนื่อง';

  @override
  String get onboardingPermUnusedAppDesc =>
      'Android จะหยุดแอปที่คุณไม่ได้เปิดมาระยะหนึ่งและเพิกถอนสิทธิ์ ทำให้การแจ้งเตือนภัยพิบัติส่งไปยังพื้นที่ของคุณไม่ได้';

  @override
  String get onboardingPermBackgroundExec => 'การทำงานเบื้องหลัง';

  @override
  String get onboardingPermBackgroundExecDesc =>
      'หากปิดอยู่ แอปจะไม่ถูกปลุกให้รายงานตำแหน่งของคุณ';

  @override
  String get onboardingPermVendorPower => 'การตั้งค่าแบตเตอรี่ของผู้ผลิต';

  @override
  String onboardingPermVendorPowerDesc(String brand) {
    return '$brand จะหยุดการทำงานเบื้องหลังของแอปที่คุณไม่ได้เปิดเมื่อเร็ว ๆ นี้ แอปตรวจสอบหรือเปลี่ยนเองไม่ได้ กรุณาอนุญาตด้วยตนเอง';
  }

  @override
  String get homeRainTrendScattered => 'อาจมีฝนตกประปราย';

  @override
  String get meshtasticUptime => 'เวลาทำงาน';

  @override
  String get weatherRankingTempExtremes => 'ค่าสุดขั้วอุณหภูมิ';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get mapTerrainReliefHint => 'แสดงความนูนของภูมิประเทศบนแผนที่ฐาน';

  @override
  String get meshtasticEmptyMessage => '(ข้อความว่าง)';

  @override
  String get moreSectionRegion => 'พื้นที่';

  @override
  String get mapLayerSatellite => 'Himawari Infrared (B13)';

  @override
  String get aedHoursSaturday => 'เวลาวันเสาร์';

  @override
  String get moonPhaseNew => 'พระจันทร์ใหม่';

  @override
  String get notifySectionEew => 'การเตือนแผ่นดินไหวล่วงหน้า';

  @override
  String get mapResetNorth => 'กลับไปทางเหนือ';

  @override
  String get rainInterval2d => '2 วัน';

  @override
  String get mapTownLabelsHint => 'แสดงชื่อตำบลเมื่อขยายแผนที่';

  @override
  String get commonCancel => 'ยกเลิก';

  @override
  String get notifyOptTsunamiWarning => 'เฉพาะการเตือนภัยสึนามิ';

  @override
  String get mapLayerSatelliteBtdFog => 'Himawari Night Fog';

  @override
  String get moreSectionAdvanced => 'ขั้นสูง';

  @override
  String get moreSectionMesh => 'เครือข่าย Mesh';

  @override
  String get weatherRankingExtremeRange => 'ช่วงวัน';

  @override
  String get permissionsTitle => 'ตรวจสอบสิทธิ์';

  @override
  String get permissionsAttention => 'สิทธิ์ต้องได้รับการแก้ไข';

  @override
  String get permissionsBody =>
      'DPIP ต้องใช้สิทธิ์เหล่านี้เพื่อแจ้งเตือนคุณได้ทันเวลา หากไม่ได้รับการแจ้งเตือน มักเป็นเพราะยังไม่ได้เปิดสิทธิ์ข้อใดข้อหนึ่ง';

  @override
  String get notifySettingsMenu => 'การตั้งค่าการแจ้งเตือน';

  @override
  String mapAppDefault(String app) {
    return '$app (ค่าเริ่มต้น)';
  }

  @override
  String get trendRange24h => '24 ชม.';

  @override
  String get mapLayerStyleJmaTooltip =>
      'ฐานเป็น grayscale แต่งสีต่ำกว่า −40 °C เพื่อเน้นความสูงยอดเมฆ';

  @override
  String get mapLayerRain => 'ปริมาณฝน';

  @override
  String get mapLayerQpesums => 'พยากรณ์ฝน 1 ชั่วโมงข้างหน้า';

  @override
  String get mapOverlaySectionMap => 'แผนที่';

  @override
  String get mapTerrainRelief => 'ความนูนของภูมิประเทศ';

  @override
  String get mapLegendCollapse => 'ซ่อนคำอธิบาย';

  @override
  String get updateAvailableTitle => 'มีเวอร์ชันใหม่';

  @override
  String updateAvailableBody(String version) {
    return 'เวอร์ชัน $version พร้อมใช้งานแล้ว';
  }

  @override
  String get updateSkip => 'ข้ามครั้งนี้';

  @override
  String get updateViewChangelog => 'ดูรายละเอียด';

  @override
  String get updateOpenAppStore => 'App Store';

  @override
  String get updateOpenTestFlight => 'TestFlight';

  @override
  String get updateOpenPlayStore => 'Play Store';

  @override
  String get updateDownload => 'ดาวน์โหลด';

  @override
  String get changelogShowSnapshots => 'แสดงรุ่นทดสอบ';

  @override
  String get changelogTitle => 'บันทึกการอัปเดต';

  @override
  String get reportFilterOrderDesc => 'มาก→น้อย';

  @override
  String get meshtasticExcludeMqttSubtitle =>
      'โหนดที่เชื่อมผ่านอินเทอร์เน็ต ไม่ได้ยินผ่านวิทยุ';

  @override
  String get reportFilterIntensityInfoTitle => 'มาตรวัดความรุนแรงแบบใหม่/เก่า';

  @override
  String get mapLayerTyphoon => 'ไต้ฝุ่น';

  @override
  String get radarOverlayMenuTooltip => 'ตัวเลือกชั้นเรดาร์';

  @override
  String get meshtasticNodes => 'โหนด';

  @override
  String get meshtasticSend => 'ส่ง';

  @override
  String get typhoonOverlayStormL7Tooltip =>
      'สนามลมระดับ 7 + รัศมีเฉลี่ย (ม่วง)';

  @override
  String get aedType => 'ประเภท';

  @override
  String get termsOfService => 'ข้อกำหนดในการให้บริการ';

  @override
  String get typhoonLegendCircle25 => 'วงพายุ (รุนแรง)';

  @override
  String get sponsorTitle => 'สนับสนุน DPIP';

  @override
  String get mapNavSatellite => 'ดาวเทียม';

  @override
  String homeRainTrendUpdated(String time) {
    return 'อัปเดต $time';
  }

  @override
  String get onboardingNext => 'ถัดไป';

  @override
  String get weatherRankingMergeTown => 'ตำบล';

  @override
  String get mapLayerMonitor => 'เครื่องตรวจแผ่นดินไหว';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get sponsorSubscriptions => 'แบบสมัครสมาชิก';

  @override
  String typhoonValueLon(String lon) {
    return '$lon°E';
  }

  @override
  String get skyTime => 'เวลาท้องฟ้า';

  @override
  String get weatherModeCloudy => 'มีเมฆมาก';

  @override
  String get skyTimeDusk => 'สนธยา';

  @override
  String get meshtasticFirmware => 'เฟิร์มแวร์';

  @override
  String get reportFilterDateEndNote => 'วันสิ้นสุด: 24:00 ของวันนั้น（ไทเป）';

  @override
  String get reportFilterSortMagnitude => 'ขนาด';

  @override
  String get meshtasticSilent => 'เงียบ';

  @override
  String get mapLayerCategoryEarthquake => 'แผ่นดินไหว';

  @override
  String get mapLayerSatelliteB12 => 'Himawari Ozone (B12)';

  @override
  String get restroomCategoryOther => 'อื่น ๆ';

  @override
  String homeForecastHighLow(String high, String low) {
    return 'สูง $high° · ต่ำ $low°';
  }

  @override
  String get locationBannerFix => 'เปิดการตั้งค่า';

  @override
  String get mapLegendExpand => 'คำอธิบาย';

  @override
  String get eewNone => 'ขณะนี้ไม่มีการเตือนแผ่นดินไหวล่วงหน้า';

  @override
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String get notifyOptTsunamiAll => 'ข่าวสารและการเตือนภัยสึนามิ';

  @override
  String get meshtasticLayerOptions => 'ตัวเลือกโหนด';

  @override
  String get onboardingAgreeContinue => 'ยอมรับและดำเนินการต่อ';

  @override
  String get commonRetry => 'ลองอีกครั้ง';

  @override
  String get meshtasticNodeId => 'รหัสโหนด';

  @override
  String reportDetailNumbered(String number) {
    return 'แผ่นดินไหวรู้สึกได้อย่างมีนัยสำคัญ หมายเลข $number';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => 'พร้อมรัศมีเฉลี่ย';

  @override
  String get disasterMapOverlayRestroomTooltip => 'แสดงห้องน้ำสาธารณะ';

  @override
  String get weatherRankingTitle => 'อันดับการสังเกต';

  @override
  String get homeRainTrendHeavySustained => 'ฝนตกหนักต่อเนื่องตลอดชั่วโมงหน้า';

  @override
  String get notifySectionTsunami => 'สึนามิ';

  @override
  String get restroomCategoryPark => 'สวนสาธารณะ';

  @override
  String get moreLinkOpenFailed => 'ไม่สามารถเปิดลิงก์ได้';

  @override
  String get themeDark => 'มืด';

  @override
  String get sponsorRestore => 'กู้คืนการซื้อ';

  @override
  String get meshtasticChannelWorking => 'กำลังตั้งค่าช่อง DPIP…';

  @override
  String get meshtasticRegionSwitch => 'สลับเป็นภูมิภาค TW';

  @override
  String get meshtasticTraffic => 'ปริมาณข้อมูล';

  @override
  String get mapLayerStyleBdTooltip =>
      'Dvorak BD curve — the stepped grayscale for tropical-cyclone intensity analysis';

  @override
  String get disasterMapOverlayAedTooltip => 'แสดงตำแหน่ง AED';

  @override
  String get mapLayerHumidity => 'ความชื้น';

  @override
  String get mapLayerSatelliteTransparentNight =>
      'กลางคืน = โปร่งใส เห็นแผนที่ฐาน';

  @override
  String get meshtasticScanning => 'กำลังสแกน…';

  @override
  String regionSelectFull(int max) {
    return 'บันทึกได้สูงสุด $max พื้นที่';
  }

  @override
  String get meshtasticNewMessages => 'ใหม่';

  @override
  String get meshtasticBatteryHistory => 'ประวัติแบตเตอรี่';

  @override
  String get meshtasticStatAvg => 'เฉลี่ย';

  @override
  String get meshtasticStatPeak => 'สูงสุด';

  @override
  String get meshtasticStatDrain => 'อัตราลด';

  @override
  String get meshtasticStatEta => 'คงเหลือ';

  @override
  String get meshtasticStatFull => 'เต็มใน';

  @override
  String get meshtasticStatTrend => 'แนวโน้ม';

  @override
  String get meshtasticStatCharging => 'กำลังชาร์จ';

  @override
  String get meshtasticStatStable => 'คงที่';

  @override
  String get meshtasticNodesTotal => 'ทั้งหมด';

  @override
  String get meshtasticNodesOnline => 'ออนไลน์';

  @override
  String get meshtasticRx => 'รับ';

  @override
  String get meshtasticTx => 'ส่ง';

  @override
  String get meshtasticNodesHistory => 'ประวัติจำนวนโหนด';

  @override
  String get meshtasticTrafficHistory => 'ประวัติทราฟฟิก';

  @override
  String meshtasticEtaHours(int n) {
    return '~$n ชม.';
  }

  @override
  String meshtasticEtaDays(int n) {
    return '~$n วัน';
  }

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => 'เพิ่มเติม';

  @override
  String get meshtasticDpipChannel => 'ช่อง DPIP';

  @override
  String get disasterMapOverlaySectionLayers => 'ชั้น';

  @override
  String get mapLayerSatelliteB05 => 'Himawari Near-Infrared (B05)';

  @override
  String get typhoonLabelNe => 'NE';

  @override
  String get meshtasticCopied => 'คัดลอกข้อความแล้ว';

  @override
  String get reportListEmpty => 'ไม่มีรายงานแผ่นดินไหว';

  @override
  String get reportListEnd => 'สิ้นสุดรายการ';

  @override
  String get mapLayerSatelliteTruecolor => 'Himawari True Color';

  @override
  String get typhoonOverlaySectionExtra => 'เลเยอร์เสริม';

  @override
  String get eewSWave => 'คลื่น S';

  @override
  String get meshtasticBusyTitle => 'แอปอื่นกำลังใช้วิทยุเครื่องนี้อยู่';

  @override
  String get restroomCategoryCultural => 'สถานที่ทางวัฒนธรรม';

  @override
  String get typhoonLabelWind => 'ลมแรงสุดต่อเนื่องใกล้ศูนย์กลาง';

  @override
  String get radarGlobalOutlineHint => 'กรอบนอกของทุกประเทศ';

  @override
  String get notifyEvacuation => 'ข้อมูลภัยพิบัติ';

  @override
  String get typhoonLegendCircle15 => 'วงพายุ (แรง)';

  @override
  String get dataSectionAstronomy => 'ดาราศาสตร์';

  @override
  String get homeRainTrendLightSustained =>
      'ฝนตกเล็กน้อยต่อเนื่องตลอดชั่วโมงหน้า';

  @override
  String get commonError => 'เกิดข้อผิดพลาด';

  @override
  String get moonPhaseWaningCrescent => 'จันทร์เสี้ยวข้างแรม';

  @override
  String get meshtasticPower => 'พลังงาน';

  @override
  String get mapTimelineNow => 'ตอนนี้';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportDetailOpenReport => 'หน้ารายงาน';

  @override
  String get trendRange7d => '7 วัน';

  @override
  String typhoonWarningAreas(String areas) {
    return 'พื้นที่: $areas';
  }

  @override
  String get rainIntervalSection => 'ช่วงเวลา';

  @override
  String get notifyTitle => 'การแจ้งเตือน';

  @override
  String get meshtasticTxPower => 'กำลัง TX';

  @override
  String get restroomCategoryLabel => 'หมวดหมู่';

  @override
  String get sponsorRestoring => 'กำลังกู้คืนการซื้อ…';

  @override
  String get sponsorIntro =>
      'DPIP มุ่งมั่นให้ข้อมูลการป้องกันภัยพิบัติแบบเรียลไทม์ โดยไม่มีโฆษณาหรือรูปแบบหารายได้อื่น การสนับสนุนของคุณช่วยให้เรารักษาเซิร์ฟเวอร์และพัฒนาต่อไปได้';

  @override
  String get typhoonLabelStormAvg => 'รัศมีเฉลี่ยลมโบฟอร์ต 10';

  @override
  String get restroomCategoryCommercial => 'สถานประกอบการพาณิชย์';

  @override
  String get aedRegion => 'พื้นที่';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return 'คาดว่าฝนจะหยุดในอีก $minutes นาที';
  }

  @override
  String get reportDetailInfo => 'รายละเอียด';

  @override
  String get mapNavWind => 'ทิศลม';

  @override
  String get windForecastOverlayMenuTooltip => 'ตัวเลือกชั้นพยากรณ์ลม';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute นาที';
  }

  @override
  String get rainInterval6h => '6 ชม.';

  @override
  String get restroomTypeUnspecified => 'ไม่ระบุ';

  @override
  String get typhoonOverlayProbabilityHint => 'ซ่อนกรวยคาดการณ์';

  @override
  String get mapLayerSatelliteGlobalOutline => 'เส้นขอบประเทศ';

  @override
  String get mapNavTemperature => 'อุณหภูมิ';

  @override
  String get typhoonLegendForecastPoint => 'จุดพยากรณ์';

  @override
  String get reportListYesterday => 'เมื่อวาน';

  @override
  String get moreSectionLinks => 'ลิงก์ที่เกี่ยวข้อง';

  @override
  String get feedOffline => 'การเชื่อมต่อขาดหาย';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get moreSectionDisplay => 'การแสดงผล';

  @override
  String get rainInterval3d => '3 วัน';

  @override
  String get defaultMapLayerSubtitle =>
      'แท็บแผนที่จะเปิดชั้นนี้ ไอคอนและป้ายนำทางด้านล่างจะเปลี่ยนตาม';

  @override
  String get aedDescription => 'หมายเหตุ';

  @override
  String get typhoonOverlayWeatherRadarTooltip =>
      'เรดาร์สะท้อนที่ใกล้เวลารายงานพายุไต้ฝุ่นที่สุด';

  @override
  String get onboardingPermLocationDesc => 'ส่งการเตือนภัยตามตำแหน่งที่คุณอยู่';

  @override
  String get mapLayerSatelliteB16 => 'Himawari CO₂ (B16)';

  @override
  String get homeActiveEventsEmpty => 'ไม่มีเหตุการณ์ที่ยังมีผล';

  @override
  String get typhoonLabelPosition => 'ตำแหน่งศูนย์กลาง';

  @override
  String get weatherRankingBy => 'เรียง';

  @override
  String get typhoonIntensityMild => 'พายุไต้ฝุ่นอ่อน';

  @override
  String get windForecastGlobalOutlineHint => 'กรอบนอกของทุกประเทศ';

  @override
  String get rainInterval1h => '1 ชม.';

  @override
  String get eewLocalIntensity => 'ประมาณ ณ ตำแหน่ง';

  @override
  String get mapLayerRadar => 'เรดาร์สะท้อนสังเคราะห์';

  @override
  String get restroomCategoryReligious => 'สถานที่ทางศาสนา';

  @override
  String get meshtasticRole => 'บทบาท';

  @override
  String get mapLayerSatelliteCloudCloudy => 'มีเมฆ';

  @override
  String get skyTimeSunrise => 'พระอาทิตย์ขึ้น';

  @override
  String get meshtasticJumpToLatest => 'ไปที่ล่าสุด';

  @override
  String get meshtasticNoMessages => 'ยังไม่มีข้อความ';

  @override
  String get onboardingPermNotifyDesc =>
      'ส่งการเตือนแผ่นดินไหว สภาพอากาศ และภัยพิบัติทันทีที่เกิดขึ้น';

  @override
  String get radarTownOutline => 'เส้นแบ่งเขตอำเภอ';

  @override
  String get mapLayerStyleSection => 'สไตล์สี';

  @override
  String get disasterMapOverlayMenuTooltip => 'ชั้นแผนที่ป้องกันภัย';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get meshtasticOnline => 'เพิ่งได้ยิน';

  @override
  String get typhoonLabelSw => 'SW';

  @override
  String typhoonForecastLead(String hours) {
    return 'Forecast +$hours h';
  }

  @override
  String get changelogTypeStable => 'ทางการ';

  @override
  String get mapLayerSatelliteTransparentClear =>
      'ท้องฟ้าใส = โปร่งใส เห็นแผนที่ฐาน';

  @override
  String get mapOverlaySectionReference => 'เลเยอร์อ้างอิง';

  @override
  String get mapLayerSatelliteB02 => 'Himawari Green (B02)';

  @override
  String get weatherRankingEmpty => 'ไม่มีข้อมูลให้จัดอันดับ';

  @override
  String get notifySectionOther => 'อื่น ๆ';

  @override
  String weatherRankingMeta(String time, int count) {
    return 'เวลาข้อมูล: $time\n$count สถานี';
  }

  @override
  String get onboardingTermsAgree =>
      'ฉันได้อ่านและยอมรับข้อกำหนดการให้บริการแล้ว';

  @override
  String get mapLayerSatelliteTransparentNoVegetation =>
      'Below 0.1 = transparent (no vegetation)';

  @override
  String get notifyOptLocalIntensity4 => 'ความรุนแรงในพื้นที่ระดับ 4 ขึ้นไป';

  @override
  String get eewArrived => 'มาถึงแล้ว';

  @override
  String get meshtasticNoDevices => 'ไม่พบอุปกรณ์ Meshtastic';

  @override
  String get mapLayerCategoryLife => 'ชีวิตประจำวัน';

  @override
  String get reportFilterSortIntensity => 'ความเข้ม';

  @override
  String get meshtasticStateDisconnected => 'ตัดการเชื่อมต่อแล้ว';

  @override
  String get typhoonIntensityIntense => 'พายุไต้ฝุ่นรุนแรง';

  @override
  String get mapLayerOrderTitle => 'จัดเรียงเลเยอร์';

  @override
  String get mapLayerShow => 'แสดงเลเยอร์';

  @override
  String get mapLayerHide => 'ซ่อนเลเยอร์';

  @override
  String get mapLayerShowAll => 'แสดงทั้งหมด';

  @override
  String get mapLayerHideAll => 'ซ่อนทั้งหมด';

  @override
  String get dpmYes => 'ใช่';

  @override
  String get meshtasticNoHistory => 'ประวัติยังไม่พอ';

  @override
  String get reportDetailLocalIntensityUnavailable => 'ไม่มีข้อมูลความเข้ม';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportFilterDepth => 'ความลึก';

  @override
  String get onboardingScrollHint => 'เลื่อนลงเพื่อดำเนินการต่อ';

  @override
  String get mapNavQpesums => 'พยากรณ์';

  @override
  String get notifyAdvisory => 'การแจ้งเตือนและประกาศสภาพอากาศ';

  @override
  String get reportFilterReset => 'รีเซ็ต';

  @override
  String get mapLayerSatelliteMndwi => 'Himawari MNDWI';

  @override
  String get typhoonOverlaySectionStorm => 'ลมพายุ';

  @override
  String get moonPhaseFull => 'พระจันทร์เต็มดวง';

  @override
  String meshtasticBinaryPayload(String size) {
    return 'ข้อมูลไบนารี · $size';
  }

  @override
  String get moonPhaseWaningGibbous => 'จันทร์นูนข้างแรม';

  @override
  String get reportFilterIntensityInfoModernTitle => 'แบบใหม่ (ตั้งแต่ 2020)';

  @override
  String typhoonDataTime(String time) {
    return 'เวลาข้อมูล\n$time';
  }

  @override
  String get restroomTypeAccessible => 'ห้องน้ำคนพิการ';

  @override
  String get moreSectionAbout => 'เกี่ยวกับ';

  @override
  String get meshtasticSelectDevice => 'เลือกวิทยุ';

  @override
  String get onboardingIntroBody =>
      'DPIP คือเพื่อนคู่ใจด้านการป้องกันภัยพิบัติของคุณ รวมการเตือนแผ่นดินไหวล่วงหน้า รายงานแผ่นดินไหว สภาพอากาศ และข้อมูลภัยพิบัติต่าง ๆ ไว้ในที่เดียว และแจ้งเตือนคุณในช่วงเวลาสำคัญ\n\n• แผ่นดินไหว: การเตือนล่วงหน้า รายงานความรุนแรง และรายงานฉบับสมบูรณ์\n• สภาพอากาศ: ข้อความพายุฝนฟ้าคะนองแบบเรียลไทม์ และการแจ้งเตือนสภาพอากาศ\n• ข้อมูลสึนามิและภัยพิบัติ\n\nต่อไป เราจะขอให้คุณอ่านข้อกำหนดการให้บริการ และอนุญาตสิทธิ์บางอย่างเพื่อให้ DPIP สามารถปกป้องคุณได้แบบเรียลไทม์';

  @override
  String get shelterCapacityLabel => 'ความจุ';

  @override
  String get reportDetailImage => 'ภาพรายงานแผ่นดินไหว';

  @override
  String get meshtasticStateConfiguring => 'กำลังกำหนดค่า…';

  @override
  String get typhoonLabelGaleAvg => 'รัศมีเฉลี่ยลมโบฟอร์ต 7';

  @override
  String get onboardingPermNotify => 'การแจ้งเตือน';

  @override
  String get meshtasticClearMessages => 'ล้างข้อความ';

  @override
  String get meshtasticNotifyMessages => 'แจ้งเตือนข้อความใหม่';

  @override
  String get defaultMapLayerSettings => 'ชั้นแผนที่เริ่มต้น';

  @override
  String get eewSourceSettings => 'แหล่งที่มาของ EEW';

  @override
  String get eewSourceSubtitle =>
      'เลือกหน่วยงานที่ต้องการแสดงการแจ้งเตือนแผ่นดินไหวล่วงหน้า';

  @override
  String get eewSourceAll => 'ทุกแหล่งที่มา';

  @override
  String get eewSourceAllDescription =>
      'แสดงการแจ้งเตือนแผ่นดินไหวล่วงหน้าจากทุกหน่วยงานที่เผยแพร่';

  @override
  String get eewSourceCwaOnly => 'เฉพาะ CWA เท่านั้น';

  @override
  String get eewSourceCwaOnlyDescription =>
      'แสดงเฉพาะการแจ้งเตือนที่เผยแพร่โดยสำนักงานอุตุนิยมวิทยากลางไต้หวัน (CWA) เท่านั้น';

  @override
  String get moreSectionNotify => 'การแจ้งเตือน';

  @override
  String get notifyUnavailable =>
      'การแจ้งเตือนแบบพุชยังไม่พร้อม — โปรดลองอีกครั้งในภายหลัง';

  @override
  String get mapLayerOrderReset => 'รีเซ็ตลำดับ';

  @override
  String get weatherRankingMergeCounty => 'อำเภอ/เมือง';

  @override
  String get moreSectionApp => 'ดาวน์โหลดแอป';

  @override
  String get moreSectionBeta => 'เวอร์ชันทดสอบ';

  @override
  String get moreAndroidBeta => 'เวอร์ชันทดอบ Android';

  @override
  String get moreTestFlight => 'เวอร์ชันทดอบ iOS (TestFlight)';

  @override
  String get moreSectionPartners => 'พันธมิตร';

  @override
  String get morePartnersNote =>
      'เรียงตามลำดับคู่ความร่วมมือ ขอบคุณบุคคลและบริษัทที่มีส่วนร่วมในการป้องกันภัยพิบัติ การสนับสนุนของพวกเขาทำให้ DPIP เกิดขึ้นได้';

  @override
  String get morePartnerGeoscience => 'Geoscience';

  @override
  String get morePartnerTwds => 'TWDS';

  @override
  String get reportFilterIntensityInfoLegacyBody =>
      'มีระดับ 0–7 เท่านั้น ไม่แยก 5−/5+/6−/6+';

  @override
  String get mapLayerSatelliteSst => 'Himawari Sea Surface Temperature';

  @override
  String get qpesumsOverlayMenuTooltip => 'ตัวเลือกชั้นพยากรณ์น้ำฝน';

  @override
  String get mapTimelineFuture => 'อนาคต';

  @override
  String get typhoonLegendCircleAvg => 'รัศมีเฉลี่ย';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get typhoonLabelSe => 'SE';

  @override
  String get radarTownOutlineHint => 'เส้นแบ่งย่อยกว่า';

  @override
  String eewCountdown(int seconds) {
    return '$seconds วินาที';
  }

  @override
  String get typhoonLabelGust => 'ลมกระโชกสูงสุด';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get sponsorTerms => 'ข้อกำหนดการใช้งาน';

  @override
  String get restroomTypeGenderNeutral => 'ห้องน้ำเป็นกลางทางเพศ';

  @override
  String get notifyThunderstorm => 'การแจ้งเตือนพายุฝนฟ้าคะนอง';

  @override
  String get skyTimeGolden => 'ช่วงเวลาทอง';

  @override
  String get moonAge => 'อายุจันทร์';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable => 'เลือกพื้นที่เพื่อดูพยากรณ์';

  @override
  String get mapLayers => 'ชั้นข้อมูล';

  @override
  String get meshtasticHardware => 'ฮาร์ดแวร์';

  @override
  String get languageSettings => 'ภาษา';

  @override
  String get language => 'ภาษา';

  @override
  String homeForecastFeelsLike(String temp) {
    return 'รู้สึกเหมือน $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => 'จัดให้ตรงเวลารายงาน';

  @override
  String get skyTimeDawn => 'รุ่งอรุณ';

  @override
  String get skyTimeAfternoon => 'ตอนบ่าย';

  @override
  String get meshtasticLastHeard => 'ได้ยินล่าสุด';

  @override
  String get typhoonWarningTitle => 'ประกาศเตือนไต้ฝุ่น';

  @override
  String get moreSourceCode => 'ซอร์สโค้ด';

  @override
  String get mapLayerCategoryWeather => 'การสังเกตสภาพอากาศ';

  @override
  String get mapLayerSatelliteB09 => 'Himawari Mid Water Vapour (B09)';

  @override
  String get windForecastTownOutlineHint => 'ตาข่ายที่ละเอียดกว่า';

  @override
  String get mapLayerSatelliteCloudmask => 'Himawari Cloud Mask';

  @override
  String get mapAppCopyCoordinates => 'คัดลอกพิกัด';

  @override
  String get reportFilterIntensityInfoIntro =>
      'CWA เปลี่ยนมาตรวัดเมื่อ 1 ม.ค. 2020 (เวลาไทเป)';

  @override
  String get mapNavEarthquake => 'แผ่นดินไหว';

  @override
  String get restroomGradeAverage => 'ปานกลาง';

  @override
  String get mapLayerSatelliteBtdCo2 => 'Himawari Cirrus / Cloud Height';

  @override
  String get onboardingPermBackgroundDesc =>
      'อนุญาต \"ทุกครั้ง\" เพื่อให้การเตือนภัยยังส่งถึงคุณได้แม้ปิดแอป';

  @override
  String get mapTimelineForecast => 'พยากรณ์';

  @override
  String get restroomTypeLabel => 'ประเภท';

  @override
  String get navEarthquake => 'แผ่นดินไหว';

  @override
  String get typhoonOverlayStormL10Tooltip =>
      'สนามลมระดับ 10 + รัศมีเฉลี่ย (เหลือง)';

  @override
  String get moonPhaseWaxingGibbous => 'จันทร์นูนข้างขึ้น';

  @override
  String get reportDetailTitle => 'รายงานแผ่นดินไหว';

  @override
  String get moreTremReport => 'รายงานการตรวจจับ TREM';

  @override
  String weatherDataTime(String station, String time) {
    return '$station · เวลาข้อมูล $time';
  }

  @override
  String get meshtasticNoNodes => 'ยังไม่พบโหนด';

  @override
  String get meshtasticViaMqtt => 'ผ่าน MQTT (อินเทอร์เน็ต)';

  @override
  String get radarCountyOutline => 'เส้นแบ่งเขตจังหวัด';

  @override
  String get commonClose => 'ปิด';

  @override
  String get restroomGradeLabel => 'ระดับ';

  @override
  String get rainIntervalNow => 'วันนี้';

  @override
  String get changelogCurrentVersion => 'ปัจจุบัน';

  @override
  String get typhoonLabelPressure => 'ความกดอากาศศูนย์กลาง';

  @override
  String get typhoonOverlayForecastCalloutsTooltip =>
      'แสดงการ์ดรายละเอียดจุดคาดการณ์เมื่อซูมเข้า';

  @override
  String get aedOpenRemark => 'หมายเหตุเวลาเปิด';

  @override
  String get onboardingPermsBody =>
      'เพื่อให้ DPIP แจ้งเตือนคุณได้ในทันทีที่เกิดภัยพิบัติ โปรดอนุญาตสิทธิ์ต่อไปนี้ คุณสามารถเปลี่ยนแปลงได้ทุกเมื่อในการตั้งค่าระบบ';

  @override
  String get typhoonOverlaySectionWeather => 'พื้นหลังสภาพอากาศ';

  @override
  String get notifyOptWeatherLocal => 'เฉพาะตำแหน่งปัจจุบัน';

  @override
  String get mapNavRain => 'ฝน';

  @override
  String get moonDays => 'วัน';

  @override
  String mapLegendUnit(String unit) {
    return 'หน่วย: $unit';
  }

  @override
  String get weatherModeClear => 'ท้องฟ้าแจ่มใส';

  @override
  String get meshtasticRadio => 'วิทยุ';

  @override
  String get commonEmpty => 'ไม่มีข้อมูล';

  @override
  String get mapLayerSatelliteB01 => 'Himawari Blue (B01)';

  @override
  String get meshtasticExternalPower => 'พลังงานภายนอก';

  @override
  String get moonPhaseLastQuarter => 'จันทร์กึ่งดวงข้างแรม';

  @override
  String get reportFilterOrderAsc => 'น้อย→มาก';

  @override
  String get reportFilterApply => 'ใช้';

  @override
  String get reportDetailImageUnavailable => 'ยังไม่มีภาพรายงาน';

  @override
  String get weatherRankingHighest => 'สูงสุด';

  @override
  String get reportDetailReplay => 'เล่นย้อนหลัง';

  @override
  String get mapLayerRestroom => 'ห้องน้ำสาธารณะ';

  @override
  String get restroomCategoryWelfare => 'สถานสงเคราะห์';

  @override
  String get restroomGradeExcellent => 'ดีเยี่ยม';

  @override
  String get meshtasticLastSent => 'ส่งล่าสุด';

  @override
  String get meshtasticName => 'ชื่อ';

  @override
  String get meshtasticScan => 'สแกน';

  @override
  String get mapLayerCategoryForecast => 'การพยากรณ์เชิงตัวเลข';

  @override
  String get meshtasticChannelFailed => 'ตั้งค่าช่อง DPIP ไม่สำเร็จ';

  @override
  String get themeSystem => 'ระบบ';

  @override
  String get mapLayerSatelliteNdvi => 'Himawari NDVI';

  @override
  String get typhoonLegendForecast => 'เส้นทางพยากรณ์';

  @override
  String typhoonValueHpa(String n) {
    return '$n hPa';
  }

  @override
  String get weatherPrecipitation => 'ปริมาณน้ำฝน';

  @override
  String get moonNextFullMoon => 'พระจันทร์เต็มดวงครั้งถัดไป';

  @override
  String get dpmSheetEmpty => 'แตะเครื่องหมายบนแผนที่เพื่อดูรายละเอียด';

  @override
  String get onboardingSkipLeave => 'ข้ามไปก่อน';

  @override
  String get aedPlaceDesc => 'ตำแหน่งติดตั้ง';

  @override
  String get onboardingSkipTitle => 'ยังไม่ได้ให้สิทธิ์';

  @override
  String get restroomTypeFamily => 'ห้องน้ำครอบครัว';

  @override
  String typhoonValueKm(String n) {
    return '$n km';
  }

  @override
  String get onboardingPermBattery => 'ยกเว้นการประหยัดแบตเตอรี่';

  @override
  String get typhoonLabelNw => 'NW';

  @override
  String get moonPhaseWaxingCrescent => 'จันทร์เสี้ยวข้างขึ้น';

  @override
  String get restroomCategoryLeisure => 'สถานที่พักผ่อนหย่อนใจ';

  @override
  String get mapLayerTemperature => 'อุณหภูมิ';

  @override
  String get aedCategory => 'หมวดหมู่';

  @override
  String get meshtasticChannels => 'ช่อง';

  @override
  String get monitorWaiting => 'กำลังรอข้อมูล…';

  @override
  String get typhoonOverlayForecastCallouts => 'คำอธิบายจุดคาดการณ์';

  @override
  String get reportDetailEpicenter => 'พิกัดศูนย์กลาง';

  @override
  String get meshtasticVoltage => 'แรงดันไฟฟ้า';

  @override
  String get mapLayerMeshtasticSubtitle => 'โหนดเมช LoRa ที่วิทยุได้ยิน';

  @override
  String get mapLayerWind => 'ลม';

  @override
  String get reportDetailMagnitude => 'ขนาดแผ่นดินไหว';

  @override
  String get reportDetailAreaIntensity => 'ความเข้มแยกตามพื้นที่';

  @override
  String get rainInterval12h => '12 ชม.';

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get notifyMonitor => 'เครื่องเฝ้าระวังการสั่นสะเทือนรุนแรง';

  @override
  String get onboardingStart => 'เริ่มใช้งาน';

  @override
  String sponsorPerMonth(String price) {
    return '$price / เดือน';
  }

  @override
  String get mapLayerPressure => 'ความกดอากาศ';

  @override
  String get mapLayerSatelliteB04 => 'Himawari Near-Infrared (B04)';

  @override
  String get mapLayerSatelliteTransparentZero =>
      'ค่าต่างเป็นศูนย์ = โปร่งใส (ไม่มีสัญญาณ)';

  @override
  String get shelterIndoorLabel => 'การอพยพในอาคาร';

  @override
  String get notifyOptOff => 'ปิด';

  @override
  String get reportFilterSortTime => 'เวลา';

  @override
  String get mapLayerSatelliteCloudProbablyClear => 'น่าจะปลอดโปร่ง';

  @override
  String get weatherModeThunderstorm => 'พายุฝนฟ้าคะนอง';

  @override
  String get homeViewOnMap => 'ดูบนแผนที่';

  @override
  String get reportFilterIntensityInfoLegacyTitle => 'แบบเก่า (ก่อน 2020)';

  @override
  String get typhoonLabelSpeed => 'ความเร็วเคลื่อนที่';

  @override
  String mapAppOpenFailed(String app) {
    return 'ไม่สามารถเปิด $app ได้';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB composite (สูตร JMA)';

  @override
  String get meshtasticReceived => 'รับแล้ว';

  @override
  String get weatherRankingExtremeLow => 'ต่ำสุดวันนี้';

  @override
  String get mapLayerSatelliteB10 => 'Himawari Lower Water Vapour (B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => 'น่าจะมีเมฆ';

  @override
  String get mapLayerSatelliteTransparentNoWater =>
      '≤ 0 = transparent (no water)';

  @override
  String get shelterCategoryLabel => 'ประเภทภัยพิบัติ';

  @override
  String get meshtasticStateConnecting => 'กำลังเชื่อมต่อ…';

  @override
  String get moonTitle => 'ดวงจันทร์';

  @override
  String get weatherRankingGust => 'ลมกระโชก';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get moreServerStatus => 'สถานะเซิร์ฟเวอร์';

  @override
  String get notifySectionWeather => 'สภาพอากาศ';

  @override
  String get meshtasticPreset => 'โหมดโมเด็ม';

  @override
  String get dataSectionSeismic => 'แผ่นดินไหว';

  @override
  String get changelogBodyEmpty => 'ไม่มีคำอธิบายสำหรับรุ่นนี้';

  @override
  String get changelogOpenOnGitHub => 'ดูบน GitHub';

  @override
  String get radarGlobalOutline => 'เส้นแบ่งเขตประเทศ';

  @override
  String get notifyEew => 'การเตือนแผ่นดินไหวฉุกเฉิน';

  @override
  String get regionNationwide => 'ทั่วประเทศ';

  @override
  String get moreNotifyLog => 'บันทึกการส่งการแจ้งเตือนของ DPIP';

  @override
  String get regionCurrent => 'ตำแหน่งปัจจุบัน';

  @override
  String get meshtasticNotConnected => 'ยังไม่ได้เชื่อมต่อกับวิทยุ';

  @override
  String get weatherModeSnow => 'หิมะตก';

  @override
  String get mapLayerMeshtastic => 'โหนด Meshtastic';

  @override
  String get moreDeveloper => 'ข้อมูลดีบัก';

  @override
  String get mapLayerSatelliteB14 => 'Himawari Longwave Infrared (B14)';

  @override
  String get meshtasticChannelUse => 'การใช้ช่อง';

  @override
  String get mapNavLightning => 'ฟ้าผ่า';

  @override
  String get homeForecastEmpty => 'ไม่มีข้อมูลพยากรณ์';

  @override
  String get sponsorOneTime => 'สนับสนุนครั้งเดียว';

  @override
  String get mapLayerSatelliteBtdSplit => 'Himawari Split Window';

  @override
  String get onboardingPermBackground => 'ตำแหน่งที่ตั้งเบื้องหลัง';

  @override
  String get aedEmergencyPhone => 'โทรศัพท์ฉุกเฉิน';

  @override
  String get dpmOpenInMaps => 'เปิดในแผนที่';

  @override
  String get meshtasticNotifyNodes => 'แจ้งเตือนโหนดใหม่';

  @override
  String get onboardingPermCriticalDesc =>
      'ให้การเตือนแผ่นดินไหวที่เป็นอันตรายถึงชีวิตส่งเสียงได้ แม้อยู่ในโหมดเงียบหรือโหมดห้ามรบกวน';

  @override
  String get mapLayerSatelliteTransparentWarm =>
      'ท้องฟ้าใส (ปลายอุ่น) = โปร่งใส เห็นแผนที่ฐาน';

  @override
  String get meshtasticSent => 'ส่งแล้ว';

  @override
  String get homeForecastTitle => 'พยากรณ์ 24 ชั่วโมง';

  @override
  String get typhoonLegendWarningAreas => 'พื้นที่เตือนภัย';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return 'ซ่อน $count รายการ';
  }

  @override
  String get notifyOptLocalIntensity1 => 'ความรุนแรงในพื้นที่ระดับ 1 ขึ้นไป';

  @override
  String get mapTimelinePast => 'อดีต';

  @override
  String get restroomTypeFemale => 'ห้องน้ำหญิง';

  @override
  String get reportListToday => 'วันนี้';

  @override
  String get meshtasticTapNode => 'แตะโหนดเพื่อดูรายละเอียด';

  @override
  String get commonLoading => 'กำลังโหลด…';

  @override
  String get typhoonIntensityModerate => 'พายุไต้ฝุ่นปานกลาง';

  @override
  String get mapLayerSatelliteAsh => 'Himawari Ash';

  @override
  String get rainInterval3h => '3 ชม.';

  @override
  String get mapLayerCategorySatellite => 'ดาวเทียม';

  @override
  String get meshtasticChannelReady => 'ช่อง DPIP พร้อมแล้ว';

  @override
  String get mapLayerSatelliteNightmicrophysics =>
      'Himawari Night Microphysics';

  @override
  String get typhoonIntensityTd => 'ดีเปรสชันเขตร้อน';

  @override
  String get reportFilterDate => 'วันที่';

  @override
  String get sponsorRestoreUnavailable =>
      'ไม่สามารถเชื่อมต่อร้านค้าได้ โปรดลองอีกครั้งภายหลัง';

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String get regionEmpty => 'ยังไม่มีพื้นที่ที่บันทึกไว้';

  @override
  String get onboardingPermBatteryDesc =>
      'อนุญาตให้ DPIP ทำงานเบื้องหลังอย่างต่อเนื่อง เพื่อไม่ให้การเตือนภัยล่าช้าหรือพลาดไป';

  @override
  String get mapNavDisaster => 'ป้องกันภัย';

  @override
  String get radarScanRangeSubtitle =>
      'แสดงพื้นที่ที่เรดาร์ทั้งสี่ตรวจวัดได้จริง';

  @override
  String get aedHoursSunday => 'เวลาวันอาทิตย์';

  @override
  String get reportDetailOriginTime => 'เวลาเกิดเหตุ';

  @override
  String get trendNoData => 'ไม่มีข้อมูลแนวโน้ม';

  @override
  String get onboardingPermLocation => 'ตำแหน่งที่ตั้ง';

  @override
  String get moreDiscord => 'ชุมชน Discord';

  @override
  String get mapNavPressure => 'ความกดอากาศ';

  @override
  String get mapLayerSatelliteB13 => 'Himawari Infrared (B13)';

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

  @override
  String get changelogEmpty => 'ยังไม่มีบันทึกการเผยแพร่';

  @override
  String get reportFilterDateStartNote => 'วันเริ่ม: 00:00 ของวันนั้น（ไทเป）';

  @override
  String get eewTitle => 'การเตือนแผ่นดินไหวล่วงหน้า';

  @override
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String regionSelectCount(int count, int max) {
    return 'เลือกแล้ว $count/$max';
  }

  @override
  String get mapLayerSatelliteBtdSo2 => 'Himawari SO₂ / Cloud Phase';

  @override
  String get meshtasticStateError => 'ข้อผิดพลาด';

  @override
  String get weatherModeOvercast => 'ฟ้าปิด';

  @override
  String get reportDetailDepth => 'ความลึกจุดศูนย์กลาง';

  @override
  String get typhoonOverlayWarningTooltip =>
      'ไฮไลต์จังหวัดที่อยู่ใต้คำเตือนพายุไต้ฝุ่น';

  @override
  String get reportFilterDatePick => 'เลือกวันที่';

  @override
  String get onboardingSkipStay => 'กลับไปให้สิทธิ์';

  @override
  String get commonFetchFailed => 'ไม่สามารถโหลดข้อมูลได้ โปรดลองอีกครั้ง';

  @override
  String get shelterOutdoorLabel => 'การอพยพกลางแจ้ง';

  @override
  String get meshtasticStateConnected => 'เชื่อมต่อแล้ว';

  @override
  String get mapNavRadar => 'เรดาร์';

  @override
  String get mapLayerSatelliteCloudClear => 'ปลอดโปร่ง';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'ขนาด $magnitude · ความลึก $depth กม.';
  }

  @override
  String get locationBannerPermission =>
      'ยังไม่ได้อนุญาตสิทธิ์ตำแหน่งที่ตั้ง — ไม่สามารถส่งการเตือนภัยเฉพาะพื้นที่ของคุณได้';

  @override
  String get typhoonOverlayWeatherNoneTooltip =>
      'ไม่มีพื้นหลังเรดาร์หรืออินฟราเรด';

  @override
  String get radarCountyOutlineHint => 'วาดทับภาพเอคโค';

  @override
  String get windForecastCountyOutlineHint => 'วาดทับบนสนามลม';

  @override
  String get homeRainTrendTitle => 'ฝนชั่วโมงถัดไป';

  @override
  String get moonPhaseFirstQuarter => 'จันทร์กึ่งดวงข้างขึ้น';

  @override
  String get mapLayerCategoryTyphoon => 'พายุไต้ฝุ่น';

  @override
  String get meshtasticUtilization => 'เวลาออกอากาศ (24 ชม.)';

  @override
  String get restroomTypeMixed => 'ห้องน้ำรวม';

  @override
  String get restroomGradeGood => 'ดี';

  @override
  String get notifyTsunami => 'ข้อมูลสึนามิ';

  @override
  String get navData => 'ข้อมูล';

  @override
  String get mapLayerSatelliteBtdWvirw => 'Himawari Overshooting Top';

  @override
  String get meshtasticReadingAge => 'เวลาวัดค่า';

  @override
  String get mapAppCallFailed => 'อุปกรณ์นี้ไม่สามารถโทรออกได้';

  @override
  String get reportFilterAny => 'ทั้งหมด';

  @override
  String get weatherRankingMergeTo => 'รวม';

  @override
  String get notifyIntensity => 'รายงานความรุนแรงแผ่นดินไหว';

  @override
  String get rainIntervalMenu => 'ช่วงสะสม';

  @override
  String get reportDetailLocalFelt => 'แผ่นดินไหวรู้สึกได้เฉพาะพื้นที่';

  @override
  String get meshtasticDevice => 'อุปกรณ์';

  @override
  String get onboardingGrant => 'อนุญาต';

  @override
  String get weatherModeRain => 'ฝนตก';

  @override
  String get shelterVulnerableOkLabel => 'เหมาะกับผู้เปราะบาง';

  @override
  String get stationSheetEmpty => 'แตะสถานีเพื่อดูค่าที่วัดได้';

  @override
  String get typhoonLegendProbability => 'โอกาสกระทบ';

  @override
  String get reportFilterMagnitude => 'ขนาด';

  @override
  String get skyTimeMorning => 'ตอนเช้า';

  @override
  String get experimentalFeatures => 'ฟีเจอร์ทดลอง';

  @override
  String get onboardingTermsBody =>
      'โปรดอ่านข้อควรทราบต่อไปนี้ก่อนใช้งาน DPIP:\n\n• ข้อมูลทั้งหมดควรยึดตามเนื้อหาที่เผยแพร่โดยกรมอุตุนิยมวิทยากลาง (CWA) เป็นหลัก\n\n• ขึ้นอยู่กับสภาพเครือข่าย เซิร์ฟเวอร์ แอปพลิเคชัน และแหล่งข้อมูลต้นทาง อาจมีความเป็นไปได้ที่จะไม่ได้รับข้อมูล เราพยายามอย่างเต็มที่เพื่อหลีกเลี่ยงกรณีเช่นนี้ แต่ไม่สามารถรับประกันได้ว่าจะไม่เกิดขึ้น\n\n• การสั่นสะเทือนอย่างรุนแรงอาจมาถึงตำแหน่งของคุณก่อนการแจ้งเตือน\n\n• การเตือนแผ่นดินไหวล่วงหน้าเป็นผลจากการคำนวณอย่างรวดเร็ว ซึ่งอาจมีความคลาดเคลื่อนสูง โปรดทำความเข้าใจและใช้งานด้วยความระมัดระวัง\n\n• พฤติกรรมใด ๆ ที่ไม่ได้รับการรับรองจากหน่วยงานราชการอาจมีความเสี่ยงทางกฎหมาย โปรดปฏิบัติตามระเบียบที่เกี่ยวข้องทั้งหมด\n\nนอกจากนี้ เพื่อให้บริการการเตือนภัยเฉพาะพื้นที่ บริการนี้จะเก็บรวบรวมและอัปโหลดตำแหน่งโดยประมาณและตัวระบุการแจ้งเตือนแบบพุชของคุณ — ทั้งขณะทำงานเบื้องหน้าและเบื้องหลัง — เพื่อใช้ตัดสินว่าจะส่งการเตือนใดให้คุณเท่านั้น\n\nการแตะ \"ยอมรับและดำเนินการต่อ\" ถือว่าคุณได้อ่าน เข้าใจ และยอมรับข้อความข้างต้นแล้ว';

  @override
  String get reportFilterTitle => 'ตัวกรอง';

  @override
  String get onboardingPermCritical => 'การแจ้งเตือนสำคัญ';

  @override
  String trendCumulativeTotal(String total) {
    return 'สะสม $total มม.';
  }

  @override
  String get languageName => 'ไทย';

  @override
  String get reportListEmptyFiltered => 'ไม่มีรายงานที่ตรงกับเงื่อนไข';

  @override
  String get meshtasticExcludeMqtt => 'ซ่อนโหนด MQTT';

  @override
  String get mapNavTyphoon => 'ไต้ฝุ่น';

  @override
  String get weatherModeSand => 'ฝุ่นทราย';

  @override
  String get notifyReport => 'รายงานแผ่นดินไหว';

  @override
  String get mapAppCoordinatesCopied => 'คัดลอกพิกัดแล้ว';

  @override
  String get skyTimeNight => 'กลางคืน';

  @override
  String get sponsorRecommended => 'แนะนำ';

  @override
  String get mapLayerSatelliteB15 => 'Himawari Longwave Infrared (B15)';

  @override
  String get weatherRankingWind => 'ความเร็วลม';

  @override
  String get feedStale => 'ข้อมูลอาจล้าสมัย';

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · แรง $level';
  }

  @override
  String get navHome => 'หน้าแรก';

  @override
  String get meshtasticRegionLabel => 'ภูมิภาค';

  @override
  String get mapLayerSatelliteCloudtop => 'Himawari Cloud Top Temperature';

  @override
  String get moonTimelineCaption => 'ข้างขึ้นข้างแรม';

  @override
  String get openSourceLicenses => 'ใบอนุญาตโอเพนซอร์ส';

  @override
  String get weatherRankingLowest => 'ต่ำสุด';

  @override
  String get reportFilterSortDepth => 'ความลึก';

  @override
  String mapTimelineDataTime(String time) {
    return 'เวลาข้อมูล $time';
  }

  @override
  String get radarScanRange => 'แสดงขอบเขตการสแกน';

  @override
  String get meshtasticHopLimit => 'จำนวนฮอปสูงสุด';

  @override
  String get weatherRankingExtremeHigh => 'สูงสุดวันนี้';

  @override
  String get sponsorPrivacy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get reportDetailLocalIntensity => 'ความเข้มที่ตำแหน่งของคุณ';

  @override
  String get mapLayerSatelliteNaturalcolor => 'Himawari Natural Color';

  @override
  String get meshtasticAirtime => 'เวลาออกอากาศ (TX)';

  @override
  String shelterCapacityValue(int n) {
    return '$n คน';
  }

  @override
  String lightningLegendCc(int minutes) {
    return 'เมฆสู่เมฆ · $minutes นาที';
  }

  @override
  String get meshtasticSendHint => 'ข้อความที่จะส่ง';

  @override
  String monitorDelay(String value) {
    return 'หน่วงเวลา $value s';
  }

  @override
  String get dpmNo => 'ไม่ใช่';

  @override
  String get mapLayerSatelliteB08 => 'Himawari Upper Water Vapour (B08)';

  @override
  String get meshtasticReconnecting => 'กำลังเชื่อมต่อใหม่…';

  @override
  String get radarTownOutlineSubtitle =>
      'ทำให้เส้นแบ่งเขตอำเภอยังอ่านออกใต้ภาพเอคโคเรดาร์';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip =>
      'อินฟราเรดที่ใกล้เวลารายงานพายุไต้ฝุ่นที่สุด';

  @override
  String get radarScanRangeHint => 'นอกกรอบคือไม่ได้ตรวจวัด';

  @override
  String typhoonPickerTd(String no) {
    return 'ดีเปรสชันเขตร้อน TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => 'Himawari Water Vapour';

  @override
  String get regionAddButton => 'เพิ่มพื้นที่';

  @override
  String get regionSearchHint => 'ค้นหาจังหวัดและเมือง';

  @override
  String get regionSearchEmpty => 'ไม่พบจังหวัดหรือเมืองที่ตรงกัน';

  @override
  String get regionSearchTownHint => 'ค้นหาตำบล';

  @override
  String get regionSearchTownEmpty => 'ไม่พบตำบลที่ตรงกัน';

  @override
  String get displaySettings => 'การแสดงผล';

  @override
  String get restroomGradePoor => 'ต่ำกว่ามาตรฐาน';

  @override
  String get restroomCategoryTourist => 'แหล่งท่องเที่ยว';

  @override
  String get locationBannerServiceOff =>
      'บริการระบุตำแหน่งถูกปิด — ไม่สามารถส่งการเตือนภัยเฉพาะพื้นที่ของคุณได้';

  @override
  String get mapLayerStyleTooltip => 'สไตล์สี';

  @override
  String lightningLegendCg(int minutes) {
    return 'เมฆสู่พื้น · $minutes นาที';
  }

  @override
  String get skyTimeAuto => 'อัตโนมัติ';

  @override
  String get appLogs => 'บันทึกแอป';

  @override
  String get serverStatusLocal => 'สถานะอุปกรณ์';

  @override
  String get serverStatusLocalBody =>
      'ตัวชี้วัดเซิร์ฟเวอร์มาจากแดชบอร์ด ด้านล่างคือการตัดสินการเชื่อมต่อจริงของเครื่องนี้ต่อเอนด์พอยต์แบบ multi-active (LB / Core แต่ละภูมิภาค): แอปบันทึกเฉพาะทราฟฟิกที่เครื่องนี้รับส่งจริงโดยไม่รบกวน ถ้ายังไม่เคยแตะเอนด์พอยต์นั้นจะแสดง \'ยังไม่ตรวจ\'';

  @override
  String get serverStatusAllUp => 'บริการทั้งหมดปกติ';

  @override
  String get serverStatusDegraded => 'ประสิทธิภาพลดลง';

  @override
  String get serverStatusDown => 'บริการผิดปกติ';

  @override
  String get serverStatusErrorRate => 'อัตราข้อผิดพลาด 5xx';

  @override
  String get serverStatusLatency => 'ความหน่วงเฉลี่ย';

  @override
  String get serverStatusUpdated => 'อัปเดต';

  @override
  String get serverStatusWeb => 'สถานะเซิร์ฟเวอร์';

  @override
  String get serverStatusWebUrl => 'status.exptech.dev';

  @override
  String get serverStatusExpTech => 'สถานะ ExpTech';

  @override
  String get serverStatusCloudflare => 'สถานะ Cloudflare';

  @override
  String get serverStatusCloudflareAllOperational => 'ทุกภูมิภาคปกติ';

  @override
  String get serverStatusCloudflareOutage => 'Cloudflare บางภูมิภาคผิดปกติ';

  @override
  String get serverStatusCloudflareNone => 'ไม่มีภูมิภาคให้แสดง';

  @override
  String get serverStatusCloudflareOperational => 'ปกติ';

  @override
  String get serverStatusCloudflareDegraded => 'ประสิทธิภาพลดลง';

  @override
  String get serverStatusCloudflarePartial => 'หยุดบางส่วน';

  @override
  String get serverStatusCloudflareMajor => 'หยุดบริการขนาดใหญ่';

  @override
  String get serverStatusCloudflareUnknown => 'ไม่ทราบ';

  @override
  String get endpointTierLbApi => 'LB API';

  @override
  String get endpointTierLbStatic => 'LB Static';

  @override
  String get endpointTierCoreApi => 'Core API';

  @override
  String get endpointTierCoreStatic => 'Core Static';

  @override
  String get endpointTierCoreExclusiveApi =>
      'Core เฉพาะ API (เรดาร์ / อากาศ / ลม)';

  @override
  String get endpointTierCoreStaticExclusive => 'Core เฉพาะทรัพยากรคงที่';

  @override
  String get endpointTierLegacyApi => 'API เดิม (api-1)';

  @override
  String get endpointHealthOk => 'การเชื่อมต่อปกติ';

  @override
  String get endpointHealthDegraded => 'มีจุดเชื่อมต่อไม่เสถียร';

  @override
  String get endpointHealthDown => 'การเชื่อมต่อผิดปกติ';

  @override
  String get endpointHealthUnknown => 'ยังไม่มีข้อมูล';

  @override
  String get endpointStateOk => 'ปกติ';

  @override
  String get endpointStateDegraded => 'ไม่เสถียร';

  @override
  String get endpointStateDown => 'ผิดปกติ';

  @override
  String get endpointStateUnknown => 'ไม่ทราบ';

  @override
  String get endpointServiceEew => 'EEW';

  @override
  String get endpointServiceRts => 'RTS';

  @override
  String get endpointServiceRadar => 'เรดาร์';

  @override
  String get endpointServiceSatellite => 'ดาวเทียม';

  @override
  String get endpointServiceQpesums => 'QPE';

  @override
  String get endpointServiceWind => 'ลม';

  @override
  String get endpointServiceDpm => 'จุดภัยพิบัติ';

  @override
  String get endpointServiceWeather => 'สภาพอากาศ';

  @override
  String get endpointServiceRain => 'ฝน';

  @override
  String get endpointServiceLightning => 'ฟ้าผ่า';

  @override
  String get endpointServiceTyphoon => 'พายุไต้ฝุ่น';

  @override
  String get endpointServiceReport => 'รายงานแผ่นดินไหว';

  @override
  String get endpointServiceTremStation => 'สถานีวัดแรงสั่นสะเทือน';

  @override
  String get endpointServiceEvent => 'เหตุการณ์';

  @override
  String get endpointServiceLocation => 'ตำแหน่ง';

  @override
  String get endpointServiceNotify => 'การแจ้งเตือน';

  @override
  String get endpointServiceOther => 'อื่น ๆ';

  @override
  String get feedConnecting => 'กำลังเชื่อมต่อ…';

  @override
  String get notifyBannerDisabled =>
      'ปิดการแจ้งเตือนอยู่ — คุณจะไม่ได้รับการเตือนภัยพิบัติ';

  @override
  String get weatherHumidity => 'ความชื้น';

  @override
  String typhoonValueMs(String n) {
    return '$n m/s';
  }

  @override
  String homeForecastHumidity(String value) {
    return 'ความชื้น $value%';
  }

  @override
  String get meshtasticBusyBody =>
      'ตัดการเชื่อมต่อวิทยุในแอป Meshtastic อื่นก่อน วิทยุเครื่องเดียวที่ใช้สองแอปจะแย่งข้อความกัน บางข้อความอาจหายไป';

  @override
  String get meshtasticChannelNoSlot => 'ไม่มีช่องว่าง — ปล่อยช่องหนึ่งบนวิทยุ';

  @override
  String get restroomCategoryTransport => 'การคมนาคม';

  @override
  String get meshtasticBattery => 'แบตเตอรี่';

  @override
  String get meshtasticDistance => 'ระยะทาง';

  @override
  String get meshtasticSnrTrend => 'แนวโน้มสัญญาณ (SNR)';

  @override
  String get meshtasticBatteryTrend => 'แนวโน้มแบตเตอรี่';

  @override
  String get typhoonOverlayMenuTooltip => 'ตัวเลือกเลเยอร์พายุไต้ฝุ่น';

  @override
  String get mapLayerSatelliteBtdOzone => 'Himawari Tropopause';

  @override
  String meshtasticRegionMismatch(String region) {
    return 'ภูมิภาคของวิทยุคือ $region — DPIP ต้องการ TW';
  }

  @override
  String get notifySectionEarthquake => 'แผ่นดินไหว';

  @override
  String get mapLayerDisasterMap => 'แผนที่ป้องกันภัย';

  @override
  String get weatherModeFog => 'หมอกหนา';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String get mapLayerStyleGrayTooltip => 'JMA grayscale — ยิ่งเย็นยิ่งขาว';

  @override
  String get moreAnnouncements => 'ประกาศ';

  @override
  String get moreTagline => 'แพลตฟอร์มรวมข้อมูลป้องกันภัยพิบัติ';

  @override
  String get moreVersionStable => 'เวอร์ชันเต็ม';

  @override
  String get moreVersionNotes => 'อัปเดตนี้';

  @override
  String get moreVersionNotesHighlightsSubtitle =>
      'สิ่งที่เปลี่ยนไปในเวอร์ชันนี้';

  @override
  String releaseHighlightsTitle(Object train) {
    return '$train สรุปสำคัญ';
  }

  @override
  String get releaseHighlightsTabNormal => 'สำหรับผู้ใช้';

  @override
  String get releaseHighlightsTabAdvanced => 'เจาะลึก';

  @override
  String get releaseHighlightsEmpty => 'ยังไม่มีเนื้อหา';

  @override
  String get releaseHighlightsSeeNotes => 'ดูบันทึกทั้งหมด';

  @override
  String get moreVersionNotesEmpty => 'ไม่พบประวัติการอัปเดตสำหรับบิลด์นี้';

  @override
  String get reportNotFound => 'ไม่พบรายงานแผ่นดินไหวนี้';

  @override
  String get moreVersionSnapshot => 'เวอร์ชันทดสอบ';

  @override
  String get mapLayerSatelliteTransparentNoData =>
      'No data (land) = transparent';

  @override
  String get restroomCategoryGovernment => 'สำนักงานราชการ';

  @override
  String get typhoonLegendCurrent => 'ศูนย์กลางปัจจุบัน';

  @override
  String get aedAddress => 'ที่อยู่';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get changelogTypePrerelease => 'เบต้า';

  @override
  String get reportFilterIntensityInfoModernBody =>
      'ระดับ 0–4, 5−, 5+, 6−, 6+, 7 แถบตัวกรองใช้แบบใหม่ เหตุการณ์เก่าในรายการยังแสดงป้ายแบบเก่า';

  @override
  String get typhoonOverlayWeatherNone => 'ไม่มี';

  @override
  String get mapLayerStyleGray => 'ระดับสีเทา (JMA)';

  @override
  String get weatherModeAuto => 'อัตโนมัติ';

  @override
  String get typhoonLabelProbCircle => 'วงกลมความน่าจะเป็น 70%';

  @override
  String get notifyOptAll => 'รับทั้งหมด';

  @override
  String get displayTheme => 'ธีม';

  @override
  String get mapLayerSatelliteB07 => 'Himawari Shortwave Infrared (B07)';

  @override
  String get typhoonLabelDirection => 'ทิศทางการเคลื่อนที่';

  @override
  String get regionManageTitle => 'พื้นที่ที่ใช้บ่อย';

  @override
  String get regionSaveNote =>
      'การแจ้งเตือนจะส่งตามตำแหน่ง GPS ของคุณ การตั้งพื้นที่โปรดไม่ได้เปลี่ยนตำแหน่งที่ส่งการแจ้งเตือน — พื้นที่โปรดใช้เพียงเพื่อดูสถานะแต่ละพื้นที่อย่างรวดเร็วบนหน้าหลัก กรุณาอนุญาตสิทธิ์ตำแหน่ง ไม่เช่นนั้นการแจ้งเตือนจะไม่ทำงาน';

  @override
  String get typhoonLegendCone => 'กรวยพยากรณ์';

  @override
  String get moreCwaEew =>
      'การเตือนแผ่นดินไหวล่วงหน้าของกรมอุตุนิยมวิทยากลาง (CWA)';

  @override
  String get onboardingPermsTitle => 'การอนุญาตสิทธิ์';

  @override
  String get mapLayerStyleJma => 'การเพิ่มคอนทราสต์กลุ่มเมฆ (JMA)';

  @override
  String get rainInterval10m => '10 นาที';

  @override
  String get meshtasticConnectAnyway => 'เชื่อมต่อต่อไป';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get mapLayerSatelliteB06 => 'Himawari Near-Infrared (B06)';

  @override
  String get mapLayerSatelliteTransparentReflectance =>
      'สะท้อนต่ำ / กลางคืน = โปร่งใส เห็นแผนที่ฐาน';

  @override
  String chartHourLabel(int hour) {
    return '$hourน.';
  }

  @override
  String get mapLayerShelter => 'ศูนย์อพยพ';

  @override
  String get typhoonOverlayProbabilityTooltip =>
      'แสดงความน่าจะเป็นถูกพายุโจมตี (ซ่อนกรวยคาดการณ์)';

  @override
  String get mapLayerSatelliteNdwi => 'Himawari NDWI';

  @override
  String get disasterMapOverlayShelterTooltip => 'แสดงศูนย์อพยพ';

  @override
  String get mapNavHumidity => 'ความชื้น';

  @override
  String get reportDetailSortByIntensity => 'เรียงตามความเข้ม';

  @override
  String get homeRainTrendNoData => 'ไม่มีข้อมูล';

  @override
  String get mapLayerCategoryRadar => 'เรดาร์';

  @override
  String get meshtasticShortName => 'ชื่อสั้น';

  @override
  String get mapLayerSatelliteAirmass => 'Himawari Airmass';

  @override
  String get dataSectionWeather => 'อากาศ';

  @override
  String get aedHoursWeekday => 'เวลาวันธรรมดา';

  @override
  String get homeActiveEventsTitle => 'เหตุการณ์ที่ยังมีผล';

  @override
  String get faq => 'คำถามที่พบบ่อย';

  @override
  String eewSerial(int serial) {
    return 'รายงาน $serial';
  }

  @override
  String get reportFilterSort => 'เรียงลำดับ';

  @override
  String get meshtasticRegionConfirm =>
      'สลับวิทยุนี้เป็นภูมิภาค TW หรือไม่ วิทยุจะรีสตาร์ทและตัดการเชื่อมต่อชั่วครู่ และทุกช่องอื่นจะย้ายไปด้วย';

  @override
  String get dataEarthquakeSubtitle => 'รายงานแผ่นดินไหว';

  @override
  String get typhoonNoActive => 'ไม่มีไต้ฝุ่น';

  @override
  String get mapLayerSatelliteB11 => 'Himawari SO₂ / Cloud Phase (B11)';

  @override
  String get navEvents => 'เหตุการณ์';

  @override
  String get onboardingTermsTitle => 'ข้อกำหนดการให้บริการ';

  @override
  String get mapOsmOverlay => 'แผนที่แบบละเอียด';

  @override
  String get mapOsmOverlayHint => 'แสดงถนน อาคาร และชื่อสถานที่อย่างละเอียด';

  @override
  String get mapOsmDetails => 'รายละเอียดเลเยอร์';

  @override
  String get moreDataSources => 'แหล่งข้อมูล';

  @override
  String get dataSourceTremNet => '探索智慧科技有限公司 — TREM-Net';

  @override
  String get dataSourceCwa => '交通部中央氣象署 (CWA)';

  @override
  String get dataSourceJma => '気象庁 (JMA)';

  @override
  String get dataSourceNcdr => '國家災害防救科技中心 (NCDR)';

  @override
  String get dataSourceEcmwf =>
      'European Centre for Medium-Range Weather Forecasts (ECMWF)';

  @override
  String get dataSourceNoaaGfs =>
      'National Oceanic and Atmospheric Administration / National Centers for Environmental Prediction — Global Forecast System (NOAA/NCEP GFS)';

  @override
  String get dataSourceGovernmentOpenData => '政府資料開放平臺';

  @override
  String get dataSourceOpenStreetMap => '© OpenStreetMap contributors';

  @override
  String get dataSourceNasaMoon =>
      'National Aeronautics and Space Administration / Goddard Space Flight Center Scientific Visualization Studio — CGI Moon Kit (NASA/GSFC SVS)';

  @override
  String mapOsmDetailsHint(int enabled, int total) {
    return 'เปิดใช้งาน $enabled จากทั้งหมด $total เลเยอร์';
  }

  @override
  String get mapOsmSurface => 'พื้นผิว';

  @override
  String get mapOsmParks => 'สวนสาธารณะ';

  @override
  String get mapOsmLandUse => 'การใช้ที่ดิน';

  @override
  String get mapOsmAirportAreas => 'พื้นที่สนามบิน';

  @override
  String get mapOsmWater => 'พื้นที่น้ำ';

  @override
  String get mapOsmRivers => 'แม่น้ำ';

  @override
  String get mapOsmBoundaries => 'ขอบเขต';

  @override
  String get mapOsmBuildings => 'อาคาร';

  @override
  String get mapOsmRoads => 'ถนน';

  @override
  String get mapOsmRoadNames => 'ชื่อถนน';

  @override
  String get mapOsmWaterNames => 'ชื่อพื้นที่น้ำ';

  @override
  String get mapOsmPeaks => 'ยอดเขา';

  @override
  String get mapOsmAirportNames => 'ชื่อสนามบิน';

  @override
  String get mapOsmPlaceNames => 'ชื่อสถานที่';

  @override
  String get mapOsmPoi => 'จุดน่าสนใจ';

  @override
  String get mapOsmHouseNumbers => 'เลขที่บ้าน';

  @override
  String get mapOsmRestoreAll => 'คืนค่าทั้งหมด';

  @override
  String get mapOsmSectionNatural => 'ลักษณะธรรมชาติ';

  @override
  String get mapOsmSectionRoadsAndBuildings => 'ถนนและอาคาร';

  @override
  String get mapOsmSectionLabelsAndPlaces => 'ป้ายชื่อและสถานที่';

  @override
  String get mapTownLabels => 'ชื่อตำบล';

  @override
  String get notifySetFailed => 'ไม่สามารถบันทึกการตั้งค่าได้ โปรดลองอีกครั้ง';

  @override
  String get meshtasticDisconnect => 'ตัดการเชื่อมต่อ';

  @override
  String get meshtasticUndecoded => 'ไม่ได้ถอดรหัส';

  @override
  String get notifyAnnouncement => 'ประกาศ';

  @override
  String get onboardingIntroTitle => 'ยินดีต้อนรับสู่ DPIP';

  @override
  String get regionCurrentUnavailable => 'ไม่สามารถระบุตำแหน่งปัจจุบันได้';

  @override
  String get languageSystem => 'ค่าเริ่มต้นของระบบ';

  @override
  String get skyTimeSunset => 'พระอาทิตย์ตก';

  @override
  String get mapLayerSatelliteDust => 'Himawari Dust';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String get regionEdit => 'แก้ไข';

  @override
  String get weatherDynamicState => 'แอนิเมชันสภาพอากาศ';

  @override
  String get moonNow => 'ตอนนี้';

  @override
  String get moonSectionAppearance => 'ลักษณะ';

  @override
  String get moonSectionRiseSet => 'จันทร์ขึ้นและตก';

  @override
  String get moonSectionUpcoming => 'ถัดไป';

  @override
  String get moonSectionCalendar => 'ปฏิทิน';

  @override
  String get moonDistance => 'ระยะทาง';

  @override
  String get moonKilometres => 'กม.';

  @override
  String get moonApparentSize => 'ขนาดปรากฏ';

  @override
  String get moonRise => 'จันทร์ขึ้น';

  @override
  String get moonSet => 'จันทร์ตก';

  @override
  String get moonNextNewMoon => 'นิวมูนครั้งถัดไป';

  @override
  String get moonAlwaysUp => 'อยู่เหนือขอบฟ้าทั้งวัน';

  @override
  String get moonNoEvent => 'ไม่มีในวันนี้';

  @override
  String get sunTitle => 'ดวงอาทิตย์';

  @override
  String get sunSectionDaylight => 'แสงกลางวัน';

  @override
  String get sunSectionTwilight => 'สนธยา';

  @override
  String get sunSectionLight => 'แสง';

  @override
  String get sunSectionSundial => 'นาฬิกาแดด';

  @override
  String get sunSectionTerms => 'ปักษ์';

  @override
  String get sunRise => 'พระอาทิตย์ขึ้น';

  @override
  String get sunSet => 'พระอาทิตย์ตก';

  @override
  String get sunNoon => 'เที่ยงสุริยะ';

  @override
  String get sunDayLength => 'ความยาววัน';

  @override
  String get sunTwilightCivil => 'พลเรือน';

  @override
  String get sunTwilightNautical => 'เดินเรือ';

  @override
  String get sunTwilightAstronomical => 'ดาราศาสตร์';

  @override
  String get sunGoldenHourMorning => 'โกลเดนอาวร์เช้า';

  @override
  String get sunGoldenHourEvening => 'โกลเดนอาวร์เย็น';

  @override
  String get sunBlueHour => 'บลูอาวร์';

  @override
  String get sunEquationOfTime => 'สมการเวลา';

  @override
  String get sunMinutes => 'นาที';

  @override
  String get solarTermNext => 'ปักษ์ถัดไป';

  @override
  String get planetsTitle => 'ดาวเคราะห์';

  @override
  String get planetsSectionTonight => 'ขณะนี้';

  @override
  String get planetUp => 'เหนือขอบฟ้า';

  @override
  String get planetDown => 'ใต้ขอบฟ้า';

  @override
  String get planetInGlare => 'ใกล้ดวงอาทิตย์';

  @override
  String get planetMagnitude => 'โชติมาตร';

  @override
  String get planetElongation => 'มุมห่าง';

  @override
  String get planetSky => 'ช่วงเวลา';

  @override
  String get planetEvening => 'หัวค่ำ';

  @override
  String get planetMorning => 'ก่อนรุ่ง';

  @override
  String get planetDistance => 'ระยะทาง';

  @override
  String get planetAu => 'au';

  @override
  String get planetAltitude => 'มุมเงย';

  @override
  String get planetMercury => 'พุธ';

  @override
  String get planetVenus => 'ศุกร์';

  @override
  String get planetMars => 'อังคาร';

  @override
  String get planetJupiter => 'พฤหัสบดี';

  @override
  String get planetSaturn => 'เสาร์';

  @override
  String get planetUranus => 'ยูเรนัส';

  @override
  String get planetNeptune => 'เนปจูน';

  @override
  String get solarTermVernalEquinox => 'วสันตวิษุวัต';

  @override
  String get solarTermPureBrightness => 'เช็งเม้ง';

  @override
  String get solarTermGrainRain => 'ฝนธัญพืช';

  @override
  String get solarTermStartOfSummer => 'เริ่มฤดูร้อน';

  @override
  String get solarTermGrainFull => 'ธัญพืชเต็ม';

  @override
  String get solarTermGrainInEar => 'ธัญพืชออกรวง';

  @override
  String get solarTermSummerSolstice => 'ครีษมายัน';

  @override
  String get solarTermMinorHeat => 'ร้อนน้อย';

  @override
  String get solarTermMajorHeat => 'ร้อนมาก';

  @override
  String get solarTermStartOfAutumn => 'เริ่มฤดูใบไม้ร่วง';

  @override
  String get solarTermEndOfHeat => 'สิ้นสุดความร้อน';

  @override
  String get solarTermWhiteDew => 'น้ำค้างขาว';

  @override
  String get solarTermAutumnalEquinox => 'ศารทวิษุวัต';

  @override
  String get solarTermColdDew => 'น้ำค้างเย็น';

  @override
  String get solarTermFrostDescent => 'น้ำค้างแข็ง';

  @override
  String get solarTermStartOfWinter => 'เริ่มฤดูหนาว';

  @override
  String get solarTermMinorSnow => 'หิมะน้อย';

  @override
  String get solarTermMajorSnow => 'หิมะมาก';

  @override
  String get solarTermWinterSolstice => 'เหมายัน';

  @override
  String get solarTermMinorCold => 'หนาวน้อย';

  @override
  String get solarTermMajorCold => 'หนาวมาก';

  @override
  String get solarTermStartOfSpring => 'เริ่มฤดูใบไม้ผลิ';

  @override
  String get solarTermRainWater => 'ฝนน้ำ';

  @override
  String get solarTermAwakeningOfInsects => 'แมลงตื่น';

  @override
  String get tonightTitle => 'คืนนี้';

  @override
  String get tonightSectionDark => 'ช่วงสังเกตการณ์';

  @override
  String get tonightAstronomicalNight => 'กลางคืนทางดาราศาสตร์';

  @override
  String get tonightNeverDark => 'ไม่มืดสนิท';

  @override
  String get tonightDarkWindow => 'ช่วงมืด';

  @override
  String get tonightMoonAllNight => 'ดวงจันทร์อยู่ทั้งคืน';

  @override
  String get tonightDarkTotal => 'เวลามืดรวม';

  @override
  String get tonightMoonlight => 'แสงจันทร์';

  @override
  String get tonightSectionShowers => 'ฝนดาวตก';

  @override
  String get tonightRadiantDown => 'จุดกระจายไม่ขึ้น';

  @override
  String get tonightPerHour => 'ดวง/ชม.';

  @override
  String get tonightSectionSatellites => 'การผ่านของดาวเทียม';

  @override
  String get tonightSectionTargets => 'เป้าหมายที่เห็นได้ตอนนี้';

  @override
  String get showerQuadrantids => 'ควอดรานติดส์';

  @override
  String get showerLyrids => 'ไลริดส์';

  @override
  String get showerEtaAquariids => 'อีตาอควาริดส์';

  @override
  String get showerDeltaAquariids => 'เดลตาอควาริดส์';

  @override
  String get showerPerseids => 'เพอร์เซอิดส์';

  @override
  String get showerOrionids => 'โอไรออนิดส์';

  @override
  String get showerSouthernTaurids => 'เทาริดส์ใต้';

  @override
  String get showerLeonids => 'ลีโอนิดส์';

  @override
  String get showerGeminids => 'เจมินิดส์';

  @override
  String get showerUrsids => 'เออร์ซิดส์';

  @override
  String get deepSkyOpenCluster => 'กระจุกดาวเปิด';

  @override
  String get deepSkyGlobularCluster => 'กระจุกดาวทรงกลม';

  @override
  String get deepSkySpiralGalaxy => 'ดาราจักรกังหัน';

  @override
  String get deepSkyEllipticalGalaxy => 'ดาราจักรรี';

  @override
  String get deepSkyIrregularGalaxy => 'ดาราจักรไร้รูปแบบ';

  @override
  String get deepSkyPlanetaryNebula => 'เนบิวลาดาวเคราะห์';

  @override
  String get deepSkySupernovaRemnant => 'ซากซูเปอร์โนวา';

  @override
  String get deepSkyEmissionNebula => 'เนบิวลาเปล่งแสง';

  @override
  String get deepSkyReflectionNebula => 'เนบิวลาสะท้อนแสง';

  @override
  String get deepSkyAsterism => 'กลุ่มดาวย่อย';

  @override
  String get almanacTitle => 'ปฏิทิน';

  @override
  String get almanacSectionToday => 'วันนี้';

  @override
  String get almanacGregorian => 'สุริยคติ';

  @override
  String get almanacLunar => 'จันทรคติ';

  @override
  String get almanacYear => 'ปีนักษัตร';

  @override
  String get almanacMonthLength => 'ความยาวเดือน';

  @override
  String get almanacLongMonth => '30 วัน';

  @override
  String get almanacShortMonth => '29 วัน';

  @override
  String get almanacLeapPrefix => 'อธิกมาส ';

  @override
  String get almanacSectionLunarEclipses => 'จันทรุปราคา';

  @override
  String get almanacSectionSolarEclipses => 'สุริยุปราคา';

  @override
  String get almanacNoSolarEclipse => 'ไม่มีในช่วงนี้';

  @override
  String get eclipseTotal => 'เต็มดวง';

  @override
  String get eclipsePartial => 'บางส่วน';

  @override
  String get eclipseAnnular => 'วงแหวน';

  @override
  String get eclipsePenumbral => 'เงามัว';

  @override
  String get zodiacRat => 'ชวด';

  @override
  String get zodiacOx => 'ฉลู';

  @override
  String get zodiacTiger => 'ขาล';

  @override
  String get zodiacRabbit => 'เถาะ';

  @override
  String get zodiacDragon => 'มะโรง';

  @override
  String get zodiacSnake => 'มะเส็ง';

  @override
  String get zodiacHorse => 'มะเมีย';

  @override
  String get zodiacGoat => 'มะแม';

  @override
  String get zodiacMonkey => 'วอก';

  @override
  String get zodiacRooster => 'ระกา';

  @override
  String get zodiacDog => 'จอ';

  @override
  String get zodiacPig => 'กุน';

  @override
  String get tideTitle => 'น้ำขึ้นน้ำลง';

  @override
  String get tideDisclaimer =>
      'แรงดาราศาสตร์เท่านั้น ไม่ใช่ตารางน้ำท่า ระดับน้ำโปรดดูตารางที่กรมอุตุนิยมวิทยาเผยแพร่';

  @override
  String get tideSectionNow => 'ขณะนี้';

  @override
  String get tidePhase => 'วัฏจักร';

  @override
  String get tideSpring => 'น้ำเกิด';

  @override
  String get tideNeap => 'น้ำตาย';

  @override
  String get tideMiddling => 'ปานกลาง';

  @override
  String get tideLunarDistanceFactor => 'แรงดึงดวงจันทร์';

  @override
  String get tideEquilibrium => 'ระดับสมดุล';

  @override
  String get tideMetres => 'ม.';

  @override
  String get tidePerigeanSpring => 'น้ำเกิดใกล้โลกครั้งถัดไป';

  @override
  String get tideSectionTurningPoints => 'จุดเปลี่ยน';

  @override
  String get tideHigh => 'สูง';

  @override
  String get tideLow => 'ต่ำ';

  @override
  String get skyChartTitle => 'แผนที่ดาว';

  @override
  String get skyChartNorth => 'N';

  @override
  String get skyChartEast => 'E';

  @override
  String get skyChartSouth => 'S';

  @override
  String get skyChartWest => 'W';

  @override
  String tonightElementAge(int days) {
    return 'ข้อมูลวงโคจร $days วันก่อน';
  }

  @override
  String almanacLunarDate(String leap, int month, int day) {
    return '$leapเดือน $month วันที่ $day';
  }

  @override
  String get tonightNoShowers => 'ไม่มีฝนดาวตก';

  @override
  String get tonightNoPasses => 'ไม่มีการผ่านที่มองเห็นใน 48 ชม.';

  @override
  String get tonightSatellitesUnavailable => 'อ่านข้อมูลวงโคจรไม่ได้';

  @override
  String get tonightNoTargets => 'ไม่มีเป้าหมายที่สูงพอ';

  @override
  String get skyChartUnavailable => 'อ่านแคตตาล็อกดาวไม่ได้';

  @override
  String get permissionSettingsTitle => 'โปรดอนุญาตในการตั้งค่า';

  @override
  String get permissionSettingsHint => 'เมื่อกลับมาแอปจะตรวจสอบใหม่อัตโนมัติ';

  @override
  String get permissionOpenSettings => 'เปิดการตั้งค่า';

  @override
  String permissionSettingsMessage(String what) {
    return '“$what” ถูกปฏิเสธไว้ และระบบจะไม่ถามอีก โปรดเปิดในการตั้งค่า';
  }

  @override
  String get permissionGuideNotification =>
      'เปิดการตั้งค่าระบบเพื่ออนุญาตการแจ้งเตือน';

  @override
  String get permissionGuideForegroundLocation =>
      'เปิดการตั้งค่าระบบเพื่ออนุญาตตำแหน่งที่แม่นยำ';

  @override
  String permissionGuideBackgroundLocation(Object option) {
    return 'ใน “$option” ให้เลือก “อนุญาตตลอดเวลา”';
  }

  @override
  String get permissionGuideBackgroundExecution =>
      'อนุญาตการทำงานเบื้องหลังในการตั้งค่าระบบเพื่อไม่ให้หยุดการแจ้งเตือน';

  @override
  String get permissionGuideUnusedPause =>
      'หากแอปถูกทำเครื่องหมายเป็น “ไม่ได้ใช้” ให้เลือก “อนุญาต” ในการตั้งค่าระบบ';

  @override
  String get permissionGuideUnusedFreeSpace =>
      'หากแอปถูกหยุดชั่วคราวเพราะพื้นที่จัดเก็บ ให้ล้างแคชแล้วเปิดใหม่';

  @override
  String get permissionGuideUnusedRevoke =>
      'หากสิทธิ์ของแอปถูกเพิกถอน ให้อนุญาตอีกครั้งในการตั้งค่าระบบ';

  @override
  String get permissionGuideUnusedPlayProtect =>
      'หาก Play Protect หยุดแอปชั่วคราว ให้ตรวจสอบสถานะใน Google Play';

  @override
  String permissionGuideVendorPower(Object vendor) {
    return 'ในการตั้งค่าประหยัดพลังงานของ “$vendor” ให้ตั้งค่าแอปนี้เป็น “ไม่จำกัด”';
  }

  @override
  String get permissionStillRequired =>
      'ยังจำเป็น — เปิดการตั้งค่าเพื่อเปิดใช้งาน';

  @override
  String get permissionVerifyManually =>
      'โปรดตรวจสอบด้วยตนเองว่าสิทธิ์นี้เปิดใช้งานในการตั้งค่าระบบ';

  @override
  String get permissionBackgroundLocationOption => '“อนุญาตตลอดเวลา”';

  @override
  String get displayTextSize => 'ขนาดตัวอักษร';

  @override
  String get displayTextSizeDesc =>
      'มีผลกับข้อความในแอป ป้ายชื่อบนแผนที่ยังคงขนาดเดิม';

  @override
  String get displayTextWeight => 'น้ำหนักตัวอักษร';

  @override
  String get displayTextWeightDesc => 'ตัวอักษรหนาขึ้นอาจอ่านง่ายกว่า';

  @override
  String get displayContrast => 'คอนทราสต์';

  @override
  String get displayContrastDesc =>
      'คอนทราสต์สูงขึ้นช่วยให้ข้อความแยกจากพื้นหลังได้ชัดขึ้น';

  @override
  String get displayColorVision => 'การมองเห็นสี';

  @override
  String get displayColorVisionDesc => 'ปรับสีทั้งแอป รวมถึงสีบนแผนที่';

  @override
  String get displayColorVisionNone => 'สีมาตรฐาน';

  @override
  String get displayColorVisionProtan => 'ตาบอดสีแดง (Protan)';

  @override
  String get displayColorVisionDeutan => 'ตาบอดสีเขียว (Deutan)';

  @override
  String get displayColorVisionTritan => 'ตาบอดสีน้ำเงิน–เหลือง (Tritan)';

  @override
  String get displayPreviewSample => 'ตัวอย่างรายงานแผ่นดินไหว';

  @override
  String get displayScaleSmall => 'เล็ก';

  @override
  String get displayScaleDefault => 'ปกติ';

  @override
  String get displayScaleLarge => 'ใหญ่';

  @override
  String get displayScaleHuge => 'ใหญ่มาก';

  @override
  String get displayWeightNormal => 'ปกติ';

  @override
  String get displayWeightMedium => 'ปานกลาง';

  @override
  String get displayWeightBold => 'หนา';

  @override
  String get displayContrastStandard => 'มาตรฐาน';

  @override
  String get displayContrastMedium => 'ปานกลาง';

  @override
  String get displayContrastHigh => 'สูง';

  @override
  String get meshtasticDirect => 'เชื่อมตรง';

  @override
  String meshtasticHopsAway(int n) {
    return '$n ฮอป';
  }

  @override
  String get meshtasticStatRelayShare => 'ส่งต่อให้ผู้อื่น';

  @override
  String get meshtasticStatRelayShareHint => 'สัดส่วนของที่วิทยุนี้ส่ง';

  @override
  String get meshtasticStatRelayValue => 'อัตราส่งต่อสำเร็จ';

  @override
  String get meshtasticStatRelaySolePath =>
      'มักเป็นเส้นทางเดียว — เมชพึ่งโหนดนี้';

  @override
  String get meshtasticStatRelayRedundant => 'โหนดอื่นครอบคลุมเส้นทางเดียวกัน';

  @override
  String get meshtasticStatRedundancy => 'รับซ้ำ';

  @override
  String get meshtasticStatThinEdge =>
      'เส้นทางสำรองน้อย — รีเลย์เดียวล่มอาจตัดขาด';

  @override
  String get meshtasticStatWellCovered => 'มีหลายเส้นทางมาถึง';

  @override
  String get meshtasticStatErrorRate => 'อัตรารับผิดพลาด';

  @override
  String get meshtasticStatErrorRateHint =>
      'เพิ่มขึ้นขณะ airtime คงที่ = สัญญาณรบกวน';

  @override
  String get meshtasticTraceRoute => 'ติดตามเส้นทาง';

  @override
  String get meshtasticTracing => 'กำลังติดตาม…';

  @override
  String get meshtasticTraceUnreadable => 'อ่านการตอบกลับไม่ได้';

  @override
  String get meshtasticTraceOffline => 'ยังไม่ได้เชื่อมต่อวิทยุ';

  @override
  String get meshtasticTraceCooldown => 'วิทยุจำกัด 30 วินาทีต่อครั้ง';

  @override
  String get meshtasticTraceNoReply =>
      'ไม่มีการตอบกลับ — อยู่นอกระยะหรือคีย์ต่างกัน';

  @override
  String get meshtasticTraceDirect => 'ตรงถึง — ไม่มีรีเลย์';

  @override
  String meshtasticTraceHops(int n) {
    return '$n ฮอป';
  }

  @override
  String get moreDumpDiagnostics => 'อัปโหลดข้อมูลดีบักและบันทึก';

  @override
  String get moreDumpDiagnosticsHint =>
      'อัปโหลดแล้วคัดลอกลิงก์เพื่อแนบในรายงาน';

  @override
  String get dumpIncludeSensitive => 'รวมตำแหน่งที่แม่นยำ';

  @override
  String get dumpIncludeSensitiveHint =>
      'รวมพิกัดจากบันทึกและตำแหน่งเบื้องหลัง หากไม่เลือกจะแทนค่าด้วย null';

  @override
  String get dumpUpload => 'อัปโหลด';

  @override
  String get dumpUploaded => 'อัปโหลดแล้ว';

  @override
  String get dumpLinkCopied => 'คัดลอกลิงก์ไปยังคลิปบอร์ดแล้ว';

  @override
  String get dumpCopyAgain => 'คัดลอกอีกครั้ง';

  @override
  String get dumpUploadFailed => 'อัปโหลดไม่สำเร็จ';

  @override
  String get statusLegendUnprobed => 'ยังไม่ตรวจ';

  @override
  String get statusLegendUnsupported => 'ไม่รองรับ';

  @override
  String get rainScaleSection => 'ช่วงระดับสี';

  @override
  String get rainScaleFine => 'ละเอียด';

  @override
  String get rainScaleCoarse => 'หยาบ';

  @override
  String get notifyTestTitle => 'ทดสอบการแจ้งเตือน';

  @override
  String get notifyTestIntro =>
      'แตะที่รายการเพื่อส่งการแจ้งเตือนนั้นจริง ๆ การแจ้งเตือนสำคัญจะดังด้วยระดับเสียงสูงสุด และดังทะลุโหมดปิดเสียงและห้ามรบกวน';

  @override
  String get notifyTestCriticalDenied =>
      'อุปกรณ์นี้ไม่ได้อนุญาตการแจ้งเตือนฉุกเฉิน การแจ้งเตือนสำคัญจึงเงียบเมื่อปิดเสียงเครื่อง';

  @override
  String get notifyTestPermissionOff =>
      'การแจ้งเตือนถูกปิดอยู่ การทดสอบจะไม่แสดงอะไรเลย';

  @override
  String get notifyTestBehaviourOverrides => 'ดังทะลุโหมดปิดเสียงและห้ามรบกวน';

  @override
  String get notifyTestBehaviourAlerts =>
      'มีเสียงและแบนเนอร์ แต่จะเงียบเมื่อปิดเสียงเครื่อง';

  @override
  String get notifyTestBehaviourSounds =>
      'มีเสียง ไม่มีแบนเนอร์ และจะเงียบเมื่อปิดเสียงเครื่อง';

  @override
  String get notifyTestBehaviourSilent =>
      'เงียบ — แสดงในรายการแจ้งเตือนเท่านั้น';

  @override
  String get notifyTestFailed => 'ส่งการแจ้งเตือนทดสอบไม่สำเร็จ';

  @override
  String get moreBugReports => 'บั๊กที่รายงานแล้ว';

  @override
  String get bugTrackerEmpty => 'ยังไม่มีบั๊กที่รายงาน';

  @override
  String get bugTrackerReplies => 'การตอบกลับ';

  @override
  String get bugTrackerGoToDiscord =>
      'ไม่พบปัญหาของคุณ? ไปแจ้งบั๊กที่ Discord!';

  @override
  String get bugTrackerNoMatch => 'ไม่มีบั๊กที่ตรงกับแท็กที่เลือก';

  @override
  String get bugTrackerDeveloper => 'นักพัฒนา';

  @override
  String get bugTrackerCannotDisplay =>
      'ไม่สามารถแสดงเนื้อหานี้ได้ — ดูได้ที่ Discord';

  @override
  String get bugTrackerJoinDiscussion => 'ร่วมพูดคุยที่ Discord';

  @override
  String get bugTrackerSortLast => 'ล่าสุด';

  @override
  String get bugTrackerSortMostDiscussed => 'พูดคุยมากที่สุด';

  @override
  String get bugTrackerStaff => 'ทีมงาน';

  @override
  String eewSpokenLocalIntensity(String intensity) {
    return 'คาดการณ์ความรุนแรง ณ ตำแหน่งของคุณ: $intensity';
  }

  @override
  String eewSpokenMaxIntensity(String intensity) {
    return 'คาดการณ์ความรุนแรงสูงสุด: $intensity';
  }
}
