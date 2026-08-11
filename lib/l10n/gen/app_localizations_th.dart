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
  String get dataSectionWeather => 'อากาศ';

  @override
  String get dataWeatherRankingSubtitle => 'อันดับสถานีแบบเรียลไทม์';

  @override
  String get weatherRankingTitle => 'อันดับการสังเกต';

  @override
  String weatherRankingMeta(String time, int count) {
    return 'เวลาข้อมูล: $time\n$count สถานี';
  }

  @override
  String get weatherRankingEmpty => 'ไม่มีข้อมูลให้จัดอันดับ';

  @override
  String get weatherRankingBy => 'เรียง';

  @override
  String get weatherRankingHighest => 'สูงสุด';

  @override
  String get weatherRankingLowest => 'ต่ำสุด';

  @override
  String get weatherRankingMergeTo => 'รวม';

  @override
  String get weatherRankingMergeTown => 'ตำบล';

  @override
  String get weatherRankingMergeCounty => 'อำเภอ/เมือง';

  @override
  String get weatherRankingWind => 'ความเร็วลม';

  @override
  String get weatherRankingGust => 'ลมกระโชก';

  @override
  String get weatherRankingTempExtremes => 'ค่าสุดขั้วอุณหภูมิ';

  @override
  String get weatherRankingExtremeHigh => 'สูงสุดวันนี้';

  @override
  String get weatherRankingExtremeLow => 'ต่ำสุดวันนี้';

  @override
  String get weatherRankingExtremeRange => 'ช่วงวัน';

  @override
  String weatherRankingRecordedAt(String time) {
    return 'บันทึกเมื่อ $time';
  }

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return 'ปัจจุบัน $value°C';
  }

  @override
  String weatherRankingAnalysisHigh(String value) {
    return 'สูง $value';
  }

  @override
  String weatherRankingAnalysisLow(String value) {
    return 'ต่ำ $value';
  }

  @override
  String weatherRankingAnalysisRange(String value) {
    return 'ช่วง $value°C';
  }

  @override
  String get reportListEmpty => 'ไม่มีรายงานแผ่นดินไหว';

  @override
  String get reportListEmptyFiltered => 'ไม่มีรายงานที่ตรงกับเงื่อนไข';

  @override
  String reportListMeta(String magnitude, String depth) {
    return 'M$magnitude · $depth km';
  }

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get reportListDepthUnit => 'km';

  @override
  String get reportListLocalFelt => 'รู้สึกในพื้นที่';

  @override
  String get reportListToday => 'วันนี้';

  @override
  String get reportListYesterday => 'เมื่อวาน';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get reportListEnd => 'สิ้นสุดรายการ';

  @override
  String get reportFilterTitle => 'ตัวกรอง';

  @override
  String get reportFilterSort => 'เรียงลำดับ';

  @override
  String get reportFilterSortTime => 'เวลา';

  @override
  String get reportFilterSortIntensity => 'ความเข้ม';

  @override
  String get reportFilterSortMagnitude => 'ขนาด';

  @override
  String get reportFilterSortDepth => 'ความลึก';

  @override
  String get reportFilterOrderDesc => 'มาก→น้อย';

  @override
  String get reportFilterOrderAsc => 'น้อย→มาก';

  @override
  String get reportFilterIntensity => 'ความเข้ม';

  @override
  String get reportFilterIntensityInfoTitle => 'มาตรวัดความรุนแรงแบบใหม่/เก่า';

  @override
  String get reportFilterIntensityInfoIntro =>
      'CWA เปลี่ยนมาตรวัดเมื่อ 1 ม.ค. 2020 (เวลาไทเป)';

  @override
  String get reportFilterIntensityInfoLegacyTitle => 'แบบเก่า (ก่อน 2020)';

  @override
  String get reportFilterIntensityInfoLegacyBody =>
      'มีระดับ 0–7 เท่านั้น ไม่แยก 5−/5+/6−/6+';

  @override
  String get reportFilterIntensityInfoModernTitle => 'แบบใหม่ (ตั้งแต่ 2020)';

  @override
  String get reportFilterIntensityInfoModernBody =>
      'ระดับ 0–4, 5−, 5+, 6−, 6+, 7 แถบตัวกรองใช้แบบใหม่ เหตุการณ์เก่าในรายการยังแสดงป้ายแบบเก่า';

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
  String get reportListSearch => 'ค้นหา';

  @override
  String get reportDetailTitle => 'รายงานแผ่นดินไหว';

  @override
  String reportDetailNumbered(String number) {
    return 'แผ่นดินไหวรู้สึกได้อย่างมีนัยสำคัญ หมายเลข $number';
  }

  @override
  String get reportDetailLocalFelt => 'แผ่นดินไหวรู้สึกได้เฉพาะพื้นที่';

  @override
  String get reportDetailInfo => 'รายละเอียด';

  @override
  String get reportDetailOriginTime => 'เวลาเกิดเหตุ';

  @override
  String get reportDetailEpicenter => 'พิกัดศูนย์กลาง';

  @override
  String get reportDetailMagnitude => 'ขนาดแผ่นดินไหว';

  @override
  String get reportDetailDepth => 'ความลึกจุดศูนย์กลาง';

  @override
  String get reportDetailAreaIntensity => 'ความเข้มแยกตามพื้นที่';

  @override
  String get reportDetailLocalIntensity => 'ความเข้มที่ตำแหน่งของคุณ';

  @override
  String get reportDetailLocalIntensityUnavailable => 'ไม่มีข้อมูลความเข้ม';

  @override
  String get reportDetailSortByIntensity => 'เรียงตามความเข้ม';

  @override
  String get reportDetailSortByCounty => 'เรียงตามพื้นที่';

  @override
  String get reportDetailImage => 'ภาพรายงานแผ่นดินไหว';

  @override
  String get reportDetailImageUnavailable => 'ยังไม่มีภาพรายงาน';

  @override
  String get reportDetailOpenReport => 'หน้ารายงาน';

  @override
  String get reportDetailReplay => 'เล่นย้อนหลัง';

  @override
  String get navMore => 'เพิ่มเติม';

  @override
  String get appLogs => 'บันทึกแอป';

  @override
  String get changelogTitle => 'บันทึกการอัปเดต';

  @override
  String get changelogEmpty => 'ยังไม่มีบันทึกการเผยแพร่';

  @override
  String get changelogTypePrerelease => 'เบต้า';

  @override
  String get changelogTypeStable => 'ทางการ';

  @override
  String get changelogCurrentVersion => 'ปัจจุบัน';

  @override
  String get changelogVersionDetails => 'รายละเอียดเวอร์ชัน';

  @override
  String get changelogBodyEmpty => 'ไม่มีคำอธิบายสำหรับรุ่นนี้';

  @override
  String get mapPlaceholderDisabled => 'แผนที่ (ปิดใช้งานชั่วคราว)';

  @override
  String get moreSectionRegion => 'พื้นที่';

  @override
  String get moreSectionNotify => 'การแจ้งเตือน';

  @override
  String get moreSectionDisplay => 'การแสดงผล';

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
  String get regionEdit => 'แก้ไข';

  @override
  String get moreSectionAdvanced => 'ขั้นสูง';

  @override
  String get moreDeveloper => 'ข้อมูลดีบัก';

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
  String get homeForecastTitle => 'พยากรณ์ 24 ชั่วโมง';

  @override
  String homeForecastHighLow(String high, String low) {
    return 'สูง $high° · ต่ำ $low°';
  }

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String homeForecastFeelsLike(String temp) {
    return 'รู้สึกเหมือน $temp°';
  }

  @override
  String homeForecastHumidity(String value) {
    return 'ความชื้น $value%';
  }

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · แรง $level';
  }

  @override
  String get homeForecastUnavailable => 'เลือกพื้นที่เพื่อดูพยากรณ์';

  @override
  String get homeForecastEmpty => 'ไม่มีข้อมูลพยากรณ์';

  @override
  String get homeActiveEventsTitle => 'เหตุการณ์ที่ยังมีผล';

  @override
  String get homeActiveEventsEmpty => 'ไม่มีเหตุการณ์ที่ยังมีผล';

  @override
  String get homeRainTrendTitle => 'ฝนชั่วโมงถัดไป';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute นาที';
  }

  @override
  String homeRainTrendUpdated(String time) {
    return 'อัปเดต $time';
  }

  @override
  String get homeRainTrendNoData => 'ไม่มีข้อมูล';

  @override
  String get homeRainTrendScattered => 'อาจมีฝนตกประปราย';

  @override
  String get homeRainTrendLightSustained =>
      'ฝนตกเล็กน้อยต่อเนื่องตลอดชั่วโมงหน้า';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return 'คาดว่าฝนจะหยุดในอีก $minutes นาที';
  }

  @override
  String get homeRainTrendHeavySustained => 'ฝนตกหนักต่อเนื่องตลอดชั่วโมงหน้า';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return 'คาดว่าฝนตกหนักจะหยุดในอีก $minutes นาที';
  }

  @override
  String get mapLayers => 'ชั้นข้อมูล';

  @override
  String get mapLayerOrderTitle => 'จัดเรียงเลเยอร์';

  @override
  String get mapLayerOrderReset => 'รีเซ็ตลำดับ';

  @override
  String get mapLayerRadar => 'เรดาร์สะท้อนสังเคราะห์';

  @override
  String get mapLayerSatellite => 'Himawari Infrared (B13)';

  @override
  String get mapLayerSatelliteB01 => 'Himawari Blue (B01)';

  @override
  String get mapLayerSatelliteB02 => 'Himawari Green (B02)';

  @override
  String get mapLayerSatelliteB03 => 'Himawari Red (B03)';

  @override
  String get mapLayerSatelliteB04 => 'Himawari Near-Infrared (B04)';

  @override
  String get mapLayerSatelliteB05 => 'Himawari Near-Infrared (B05)';

  @override
  String get mapLayerSatelliteB06 => 'Himawari Near-Infrared (B06)';

  @override
  String get mapLayerSatelliteB07 => 'Himawari Shortwave Infrared (B07)';

  @override
  String get mapLayerSatelliteB08 => 'Himawari Upper Water Vapour (B08)';

  @override
  String get mapLayerSatelliteB09 => 'Himawari Mid Water Vapour (B09)';

  @override
  String get mapLayerSatelliteB10 => 'Himawari Lower Water Vapour (B10)';

  @override
  String get mapLayerSatelliteB11 => 'Himawari SO₂ / Cloud Phase (B11)';

  @override
  String get mapLayerSatelliteB12 => 'Himawari Ozone (B12)';

  @override
  String get mapLayerSatelliteB13 => 'Himawari Infrared (B13)';

  @override
  String get mapLayerSatelliteB14 => 'Himawari Longwave Infrared (B14)';

  @override
  String get mapLayerSatelliteB15 => 'Himawari Longwave Infrared (B15)';

  @override
  String get mapLayerSatelliteB16 => 'Himawari CO₂ (B16)';

  @override
  String get mapLayerSatelliteTruecolor => 'Himawari True Color';

  @override
  String get mapLayerSatelliteNaturalcolor => 'Himawari Natural Color';

  @override
  String get mapLayerSatelliteAsh => 'Himawari Ash';

  @override
  String get mapLayerSatelliteDust => 'Himawari Dust';

  @override
  String get mapLayerSatelliteAirmass => 'Himawari Airmass';

  @override
  String get mapLayerSatelliteNightmicrophysics =>
      'Himawari Night Microphysics';

  @override
  String get mapLayerSatelliteWatervapor => 'Himawari Water Vapour';

  @override
  String get mapLayerSatelliteBtdSplit => 'Himawari Split Window';

  @override
  String get mapLayerSatelliteBtdFog => 'Himawari Night Fog';

  @override
  String get mapLayerSatelliteBtdWvirw => 'Himawari Overshooting Top';

  @override
  String get mapLayerSatelliteBtdSo2 => 'Himawari SO₂ / Cloud Phase';

  @override
  String get mapLayerSatelliteBtdCo2 => 'Himawari Cirrus / Cloud Height';

  @override
  String get mapLayerSatelliteBtdOzone => 'Himawari Tropopause';

  @override
  String get mapLayerSatelliteCloudtop => 'Himawari Cloud Top Temperature';

  @override
  String get mapLayerSatelliteCloudmask => 'Himawari Cloud Mask';

  @override
  String get mapLayerSatelliteSst => 'Himawari Sea Surface Temperature';

  @override
  String get mapLayerSatelliteNdvi => 'Himawari NDVI';

  @override
  String get mapLayerSatelliteNdwi => 'Himawari NDWI';

  @override
  String get mapLayerSatelliteMndwi => 'Himawari MNDWI';

  @override
  String get mapLayerSatelliteGlobalOutline => 'Country border';

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB composite (JMA recipe)';

  @override
  String get mapLayerSatelliteCloudClear => 'Clear';

  @override
  String get mapLayerSatelliteCloudProbablyClear => 'Probably clear';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => 'Probably cloudy';

  @override
  String get mapLayerSatelliteCloudCloudy => 'Cloudy';

  @override
  String get mapLayerSatelliteTransparentWarm =>
      'Clear sky (warm end) = transparent, the basemap shows';

  @override
  String get mapLayerSatelliteTransparentReflectance =>
      'Low reflectance / night = transparent, the basemap shows';

  @override
  String get mapLayerSatelliteTransparentZero =>
      'Zero difference = transparent (no signal)';

  @override
  String get mapLayerSatelliteTransparentNight =>
      'Night = transparent, the basemap shows';

  @override
  String get mapLayerSatelliteTransparentNoData =>
      'No data (land) = transparent';

  @override
  String get mapLayerSatelliteTransparentNoVegetation =>
      'Below 0.1 = transparent (no vegetation)';

  @override
  String get mapLayerSatelliteTransparentNoWater =>
      '≤ 0 = transparent (no water)';

  @override
  String get mapLayerSatelliteTransparentClear =>
      'Clear sky = transparent, the basemap shows';

  @override
  String get mapLayerStyleSection => 'Colour style';

  @override
  String get mapLayerStyleTooltip => 'Colour style';

  @override
  String get mapLayerStyleGray => 'Grayscale (JMA)';

  @override
  String get mapLayerStyleGrayTooltip => 'JMA grayscale — colder is whiter';

  @override
  String get mapLayerStyleJma => 'Cloud-top enhancement (JMA)';

  @override
  String get mapLayerStyleJmaTooltip =>
      'Grayscale base, tinted below −40 °C to highlight cloud-top height';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get mapLayerStyleBdTooltip =>
      'Dvorak BD curve — the stepped grayscale for tropical-cyclone intensity analysis';

  @override
  String get mapLayerQpesums => 'พยากรณ์ฝน 1 ชั่วโมงข้างหน้า';

  @override
  String get mapLayerLightning => 'ฟ้าผ่า';

  @override
  String lightningLegendCg(int minutes) {
    return 'เมฆสู่พื้น · $minutes นาที';
  }

  @override
  String lightningLegendCc(int minutes) {
    return 'เมฆสู่เมฆ · $minutes นาที';
  }

  @override
  String get mapTimelineNow => 'ตอนนี้';

  @override
  String get mapTimelinePast => 'อดีต';

  @override
  String get mapTimelineFuture => 'อนาคต';

  @override
  String get mapTimelineObserved => 'เวลาตรวจวัด';

  @override
  String get mapTimelineForecast => 'พยากรณ์';

  @override
  String mapTimelineDataTime(String time) {
    return 'เวลาข้อมูล $time';
  }

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
  String get defaultMapLayerSettings => 'ชั้นแผนที่เริ่มต้น';

  @override
  String get defaultMapLayerSubtitle =>
      'แท็บแผนที่จะเปิดชั้นนี้ ไอคอนและป้ายนำทางด้านล่างจะเปลี่ยนตาม';

  @override
  String get mapNavRadar => 'เรดาร์';

  @override
  String get mapNavQpesums => 'พยากรณ์';

  @override
  String get mapNavSatellite => 'ดาวเทียม';

  @override
  String get mapNavLightning => 'ฟ้าผ่า';

  @override
  String get mapNavTyphoon => 'ไต้ฝุ่น';

  @override
  String get mapNavEarthquake => 'แผ่นดินไหว';

  @override
  String get mapNavTemperature => 'อุณหภูมิ';

  @override
  String get mapNavHumidity => 'ความชื้น';

  @override
  String get mapNavPressure => 'ความกดอากาศ';

  @override
  String get mapNavWind => 'ทิศลม';

  @override
  String get mapNavRain => 'ฝน';

  @override
  String get mapNavDisaster => 'ป้องกันภัย';

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
  String trendCumulativeTotal(String total) {
    return 'สะสม $total มม.';
  }

  @override
  String chartHourLabel(int hour) {
    return '$hourน.';
  }

  @override
  String get mapLayerHumidity => 'ความชื้น';

  @override
  String get mapLayerPressure => 'ความกดอากาศ';

  @override
  String get mapLayerWind => 'ลม';

  @override
  String get mapLayerRain => 'ปริมาณฝน';

  @override
  String get rainIntervalMenu => 'ช่วงสะสม';

  @override
  String get rainIntervalNow => 'วันนี้';

  @override
  String get rainInterval10m => '10 นาที';

  @override
  String get rainInterval1h => '1 ชม.';

  @override
  String get rainInterval3h => '3 ชม.';

  @override
  String get rainInterval6h => '6 ชม.';

  @override
  String get rainInterval12h => '12 ชม.';

  @override
  String get rainInterval24h => '24 ชม.';

  @override
  String get rainInterval2d => '2 วัน';

  @override
  String get rainInterval3d => '3 วัน';

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
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get mapLayerMonitor => 'เครื่องตรวจแผ่นดินไหว';

  @override
  String get mapLayerDisasterMap => 'แผนที่ป้องกันภัย';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get disasterMapOverlayMenuTooltip => 'ชั้นแผนที่ป้องกันภัย';

  @override
  String get disasterMapOverlaySectionLayers => 'ชั้น';

  @override
  String get disasterMapOverlayAedTooltip => 'แสดงตำแหน่ง AED';

  @override
  String get aedAddress => 'ที่อยู่';

  @override
  String get aedRegion => 'พื้นที่';

  @override
  String get aedCategory => 'หมวดหมู่';

  @override
  String get aedType => 'ประเภท';

  @override
  String get aedPlaceDesc => 'ตำแหน่งติดตั้ง';

  @override
  String get aedDescription => 'หมายเหตุ';

  @override
  String get aedHoursWeekday => 'เวลาวันธรรมดา';

  @override
  String get aedHoursSaturday => 'เวลาวันเสาร์';

  @override
  String get aedHoursSunday => 'เวลาวันอาทิตย์';

  @override
  String get aedOpenRemark => 'หมายเหตุเวลาเปิด';

  @override
  String get aedEmergencyPhone => 'โทรศัพท์ฉุกเฉิน';

  @override
  String get mapLayerRestroom => 'ห้องน้ำสาธารณะ';

  @override
  String get mapLayerShelter => 'ศูนย์อพยพ';

  @override
  String get disasterMapOverlayRestroomTooltip => 'แสดงห้องน้ำสาธารณะ';

  @override
  String get disasterMapOverlayShelterTooltip => 'แสดงศูนย์อพยพ';

  @override
  String get dpmOpenInMaps => 'เปิดในแผนที่';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String mapAppDefault(String app) {
    return '$app (ค่าเริ่มต้น)';
  }

  @override
  String get mapAppCopyCoordinates => 'คัดลอกพิกัด';

  @override
  String get mapAppCoordinatesCopied => 'คัดลอกพิกัดแล้ว';

  @override
  String mapAppOpenFailed(String app) {
    return 'ไม่สามารถเปิด $app ได้';
  }

  @override
  String get mapAppCallFailed => 'อุปกรณ์นี้ไม่สามารถโทรออกได้';

  @override
  String get mapOverlaySectionReference => 'เลเยอร์อ้างอิง';

  @override
  String get mapLayerCategoryEarthquake => 'แผ่นดินไหว';

  @override
  String get mapLayerCategoryTyphoon => 'พายุไต้ฝุ่น';

  @override
  String get mapLayerCategoryWeather => 'การสังเกตสภาพอากาศ';

  @override
  String get mapLayerCategorySatellite => 'ดาวเทียม';

  @override
  String get mapLayerCategoryRadar => 'เรดาร์';

  @override
  String get mapLayerCategoryLife => 'ชีวิตประจำวัน';

  @override
  String get mapLayerCategoryForecast => 'การพยากรณ์เชิงตัวเลข';

  @override
  String get mapOverlaySectionMap => 'แผนที่';

  @override
  String get rainIntervalSection => 'ช่วงเวลา';

  @override
  String get mapTownLabels => 'ชื่อตำบล';

  @override
  String get mapTownLabelsHint => 'แสดงชื่อตำบลเมื่อขยายแผนที่';

  @override
  String get dpmSheetEmpty => 'แตะเครื่องหมายบนแผนที่เพื่อดูรายละเอียด';

  @override
  String get dpmAddress => 'ที่อยู่';

  @override
  String get restroomTypeLabel => 'ประเภท';

  @override
  String get restroomCategoryLabel => 'หมวดหมู่';

  @override
  String get restroomGradeLabel => 'ระดับ';

  @override
  String get restroomTypeFemale => 'ห้องน้ำหญิง';

  @override
  String get restroomTypeMale => 'ห้องน้ำชาย';

  @override
  String get restroomTypeMixed => 'ห้องน้ำรวม';

  @override
  String get restroomTypeAccessible => 'ห้องน้ำคนพิการ';

  @override
  String get restroomTypeGenderNeutral => 'ห้องน้ำเป็นกลางทางเพศ';

  @override
  String get restroomTypeFamily => 'ห้องน้ำครอบครัว';

  @override
  String get restroomTypeUnspecified => 'ไม่ระบุ';

  @override
  String get restroomCategoryTransport => 'การคมนาคม';

  @override
  String get restroomCategoryPark => 'สวนสาธารณะ';

  @override
  String get restroomCategoryCommercial => 'สถานประกอบการพาณิชย์';

  @override
  String get restroomCategoryReligious => 'สถานที่ทางศาสนา';

  @override
  String get restroomCategoryCultural => 'สถานที่ทางวัฒนธรรม';

  @override
  String get restroomCategoryGovernment => 'สำนักงานราชการ';

  @override
  String get restroomCategoryWelfare => 'สถานสงเคราะห์';

  @override
  String get restroomCategoryTourist => 'แหล่งท่องเที่ยว';

  @override
  String get restroomCategoryLeisure => 'สถานที่พักผ่อนหย่อนใจ';

  @override
  String get restroomCategoryOther => 'อื่น ๆ';

  @override
  String get restroomGradeExcellent => 'ดีเยี่ยม';

  @override
  String get restroomGradeGood => 'ดี';

  @override
  String get restroomGradeAverage => 'ปานกลาง';

  @override
  String get restroomGradePoor => 'ต่ำกว่ามาตรฐาน';

  @override
  String get shelterAddressLabel => 'ที่อยู่';

  @override
  String get shelterCapacityLabel => 'ความจุ';

  @override
  String shelterCapacityValue(int n) {
    return '$n คน';
  }

  @override
  String get shelterCategoryLabel => 'ประเภทภัยพิบัติ';

  @override
  String get shelterIndoorLabel => 'การอพยพในอาคาร';

  @override
  String get shelterOutdoorLabel => 'การอพยพกลางแจ้ง';

  @override
  String get shelterVulnerableOkLabel => 'เหมาะกับผู้เปราะบาง';

  @override
  String get dpmYes => 'ใช่';

  @override
  String get dpmNo => 'ไม่ใช่';

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
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String typhoonPickerTd(String no) {
    return 'Tropical depression TD $no';
  }

  @override
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

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
  String get mapMyLocation => 'ตำแหน่งของฉัน';

  @override
  String get mapResetNorth => 'กลับไปทางเหนือ';

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

  @override
  String get dpmFilterSectionRestroom => 'ประเภทสถานที่';

  @override
  String get dpmFilterSectionRestroomType => 'ประเภทห้องน้ำ';

  @override
  String get dpmFilterSectionShelter => 'ประเภทภัยพิบัติของศูนย์อพยพ';

  @override
  String get dpmDisasterFlood => 'น้ำท่วม';

  @override
  String get dpmDisasterEarthquake => 'แผ่นดินไหว';

  @override
  String get dpmDisasterLandslide => 'ดินถล่ม';

  @override
  String get dpmDisasterTsunami => 'สึนามิ';

  @override
  String get dpmDisasterSlope => 'ภัยพิบัติลาดชัน';

  @override
  String get dpmDisasterNuclear => 'อุบัติเหตุนิวเคลียร์';

  @override
  String get skyTime => 'เวลาท้องฟ้า';

  @override
  String get skyTimeAuto => 'อัตโนมัติ';

  @override
  String get skyTimeDawn => 'รุ่งอรุณ';

  @override
  String get skyTimeSunrise => 'พระอาทิตย์ขึ้น';

  @override
  String get skyTimeMorning => 'ตอนเช้า';

  @override
  String get skyTimeNoon => 'เที่ยงวัน';

  @override
  String get skyTimeAfternoon => 'ตอนบ่าย';

  @override
  String get skyTimeGolden => 'ช่วงเวลาทอง';

  @override
  String get skyTimeSunset => 'พระอาทิตย์ตก';

  @override
  String get skyTimeDusk => 'สนธยา';

  @override
  String get skyTimeNight => 'กลางคืน';

  @override
  String get weatherModeCloudy => 'มีเมฆมาก';

  @override
  String get weatherModeOvercast => 'ฟ้าปิด';

  @override
  String get weatherModeSnow => 'หิมะตก';

  @override
  String get weatherModeSand => 'ฝุ่นทราย';

  @override
  String get radarScanRange => 'แสดงขอบเขตการสแกน';

  @override
  String get radarScanRangeSubtitle =>
      'แสดงพื้นที่ที่เรดาร์ทั้งสี่ตรวจวัดได้จริง';

  @override
  String get radarScanRangeHint => 'นอกกรอบคือไม่ได้ตรวจวัด';

  @override
  String get radarOverlayMenuTooltip => 'ตัวเลือกชั้นเรดาร์';

  @override
  String get radarCountyOutline => 'เส้นแบ่งเขตจังหวัด';

  @override
  String get radarGlobalOutline => 'เส้นแบ่งเขตประเทศ';

  @override
  String get radarGlobalOutlineHint => 'กรอบนอกของทุกประเทศ';

  @override
  String get radarCountyOutlineHint => 'วาดทับภาพเอคโค';

  @override
  String get radarCountyOutlineSubtitle =>
      'ทำให้เส้นแบ่งเขตยังอ่านออกใต้ภาพเอคโคเรดาร์';

  @override
  String get radarTownOutline => 'เส้นแบ่งเขตอำเภอ';

  @override
  String get radarTownOutlineHint => 'เส้นแบ่งย่อยกว่า';

  @override
  String get radarTownOutlineSubtitle =>
      'ทำให้เส้นแบ่งเขตอำเภอยังอ่านออกใต้ภาพเอคโคเรดาร์';

  @override
  String get qpesumsOverlayMenuTooltip => 'ตัวเลือกชั้นพยากรณ์น้ำฝน';

  @override
  String get windForecastOverlayMenuTooltip => 'ตัวเลือกชั้นพยากรณ์ลม';

  @override
  String get windForecastCountyOutlineHint => 'วาดทับบนสนามลม';

  @override
  String get windForecastGlobalOutlineHint => 'กรอบนอกของทุกประเทศ';

  @override
  String get windForecastTownOutlineHint => 'ตาข่ายที่ละเอียดกว่า';
}
