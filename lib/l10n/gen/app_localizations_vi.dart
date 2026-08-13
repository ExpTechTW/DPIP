// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get languageName => 'Tiếng Việt';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navEvents => 'Sự kiện';

  @override
  String get navMap => 'Bản đồ';

  @override
  String get navData => 'Dữ liệu';

  @override
  String get navEarthquake => 'Động đất';

  @override
  String get dataSectionSeismic => 'Địa chấn';

  @override
  String get dataEarthquakeSubtitle => 'Báo cáo động đất';

  @override
  String get dataSectionWeather => 'Thời tiết';

  @override
  String get dataWeatherRankingSubtitle => 'Xếp hạng trạm trực tiếp';

  @override
  String get weatherRankingTitle => 'Xếp hạng quan trắc';

  @override
  String weatherRankingMeta(String time, int count) {
    return 'Thời gian: $time\n$count trạm';
  }

  @override
  String get weatherRankingEmpty => 'Không có quan trắc để xếp hạng';

  @override
  String get weatherRankingBy => 'Theo';

  @override
  String get weatherRankingHighest => 'Cao nhất';

  @override
  String get weatherRankingLowest => 'Thấp nhất';

  @override
  String get weatherRankingMergeTo => 'Gộp';

  @override
  String get weatherRankingMergeTown => 'Xã/trấn';

  @override
  String get weatherRankingMergeCounty => 'Huyện/thành';

  @override
  String get weatherRankingWind => 'Tốc độ gió';

  @override
  String get weatherRankingGust => 'Gió giật';

  @override
  String get weatherRankingTempExtremes => 'Cực trị nhiệt độ';

  @override
  String get weatherRankingExtremeHigh => 'Cao nhất ngày';

  @override
  String get weatherRankingExtremeLow => 'Thấp nhất ngày';

  @override
  String get weatherRankingExtremeRange => 'Biên độ ngày';

  @override
  String weatherRankingRecordedAt(String time) {
    return 'Ghi nhận lúc $time';
  }

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return 'Hiện tại $value°C';
  }

  @override
  String weatherRankingAnalysisHigh(String value) {
    return 'Cao $value';
  }

  @override
  String weatherRankingAnalysisLow(String value) {
    return 'Thấp $value';
  }

  @override
  String weatherRankingAnalysisRange(String value) {
    return 'Biên độ $value°C';
  }

  @override
  String get reportListEmpty => 'Không có báo cáo động đất';

  @override
  String get reportListEmptyFiltered => 'Không có báo cáo khớp bộ lọc';

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
  String get reportListLocalFelt => 'Cảm nhận cục bộ';

  @override
  String get reportListToday => 'Hôm nay';

  @override
  String get reportListYesterday => 'Hôm qua';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get reportListEnd => 'Hết danh sách';

  @override
  String get reportFilterTitle => 'Bộ lọc';

  @override
  String get reportFilterSort => 'Sắp xếp';

  @override
  String get reportFilterSortTime => 'Thời gian';

  @override
  String get reportFilterSortIntensity => 'Cường độ';

  @override
  String get reportFilterSortMagnitude => 'Độ lớn';

  @override
  String get reportFilterSortDepth => 'Độ sâu';

  @override
  String get reportFilterOrderDesc => 'Giảm dần';

  @override
  String get reportFilterOrderAsc => 'Tăng dần';

  @override
  String get reportFilterIntensity => 'Cường độ';

  @override
  String get reportFilterIntensityInfoTitle => 'Thang cường độ mới và cũ';

  @override
  String get reportFilterIntensityInfoIntro =>
      'CWA đổi thang cường độ từ 1/1/2020 (giờ Đài Bắc).';

  @override
  String get reportFilterIntensityInfoLegacyTitle => 'Cũ (trước 2020)';

  @override
  String get reportFilterIntensityInfoLegacyBody =>
      'Chỉ có mức 0–7, không tách 5−/5+/6−/6+.';

  @override
  String get reportFilterIntensityInfoModernTitle => 'Mới (từ 2020)';

  @override
  String get reportFilterIntensityInfoModernBody =>
      'Các mức 0–4, 5−, 5+, 6−, 6+, 7. Thanh lọc dùng thang mới; sự kiện cũ vẫn hiện nhãn cũ trong danh sách.';

  @override
  String get reportFilterMagnitude => 'Độ lớn';

  @override
  String get reportFilterDepth => 'Độ sâu';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get reportFilterDate => 'Ngày';

  @override
  String get reportFilterDatePick => 'Chọn ngày';

  @override
  String get reportFilterDateStartNote => 'Ngày bắt đầu: từ 00:00（Đài Bắc）';

  @override
  String get reportFilterDateEndNote => 'Ngày kết thúc: đến 24:00（Đài Bắc）';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportFilterLocation => 'Địa điểm';

  @override
  String get reportFilterLocationHint => 'vd: Hoa Liên, ngoài khơi';

  @override
  String get reportFilterAny => 'Tất cả';

  @override
  String get reportFilterApply => 'Áp dụng';

  @override
  String get reportFilterReset => 'Đặt lại';

  @override
  String get reportListSearch => 'Tìm';

  @override
  String get reportDetailTitle => 'Báo cáo động đất';

  @override
  String reportDetailNumbered(String number) {
    return 'Động đất có cảm nhận đáng kể số $number';
  }

  @override
  String get reportDetailLocalFelt => 'Động đất cảm nhận cục bộ';

  @override
  String get reportDetailInfo => 'Chi tiết';

  @override
  String get reportDetailOriginTime => 'Thời gian xảy ra';

  @override
  String get reportDetailEpicenter => 'Tọa độ tâm chấn';

  @override
  String get reportDetailMagnitude => 'Độ lớn';

  @override
  String get reportDetailDepth => 'Độ sâu chấn tiêu';

  @override
  String get reportDetailAreaIntensity => 'Cường độ theo khu vực';

  @override
  String get reportDetailLocalIntensity => 'Cường độ tại vị trí của bạn';

  @override
  String get reportDetailLocalIntensityUnavailable =>
      'Không có dữ liệu cường độ';

  @override
  String get reportDetailSortByIntensity => 'Sắp xếp theo cường độ';

  @override
  String get reportDetailSortByCounty => 'Sắp xếp theo khu vực';

  @override
  String get reportDetailImage => 'Hình ảnh báo cáo';

  @override
  String get reportDetailImageUnavailable => 'Hình ảnh báo cáo chưa có sẵn';

  @override
  String get reportDetailOpenReport => 'Trang báo cáo';

  @override
  String get reportDetailReplay => 'Phát lại';

  @override
  String get navMore => 'Thêm';

  @override
  String get appLogs => 'Nhật ký ứng dụng';

  @override
  String get changelogTitle => 'Nhật ký cập nhật';

  @override
  String get changelogEmpty => 'Chưa có ghi chú phát hành';

  @override
  String get changelogTypePrerelease => 'Thử nghiệm';

  @override
  String get changelogTypeStable => 'Chính thức';

  @override
  String get changelogCurrentVersion => 'Hiện tại';

  @override
  String get changelogVersionDetails => 'Chi tiết phiên bản';

  @override
  String get changelogBodyEmpty => 'Không có ghi chú cho bản phát hành này.';

  @override
  String get mapPlaceholderDisabled => 'Bản đồ (tạm thời vô hiệu hóa)';

  @override
  String get moreSectionRegion => 'Khu vực';

  @override
  String get moreSectionNotify => 'Thông báo';

  @override
  String get moreSectionDisplay => 'Hiển thị';

  @override
  String get regionManageTitle => 'Khu vực đã lưu';

  @override
  String get regionAddButton => 'Thêm khu vực';

  @override
  String get regionEmpty => 'Chưa có khu vực nào được lưu';

  @override
  String get regionSelectTitle => 'Chọn khu vực';

  @override
  String regionSelectCount(int count, int max) {
    return 'Đã chọn $count/$max';
  }

  @override
  String regionSelectFull(int max) {
    return 'Bạn chỉ có thể lưu tối đa $max khu vực';
  }

  @override
  String get regionEdit => 'Sửa';

  @override
  String get moreSectionAdvanced => 'Nâng cao';

  @override
  String get moreDeveloper => 'Thông tin gỡ lỗi';

  @override
  String get experimentalFeatures => 'Tính năng thử nghiệm';

  @override
  String get moreSectionLinks => 'Liên kết';

  @override
  String get moreCwaEew => 'Cảnh báo sớm động đất của CWA';

  @override
  String get moreTremReport => 'Báo cáo phát hiện TREM';

  @override
  String get moreServerStatus => 'Trạng thái máy chủ';

  @override
  String get moreAnnouncements => 'Thông báo';

  @override
  String get moreDiscord => 'Cộng đồng Discord';

  @override
  String get moreNotifyLog => 'Nhật ký thông báo DPIP';

  @override
  String get moreLinkOpenFailed => 'Không thể mở liên kết';

  @override
  String get weatherDynamicState => 'Hoạt ảnh thời tiết';

  @override
  String get weatherDynamicStateSubtitle =>
      'Ghi đè thời tiết nền của trang chủ';

  @override
  String get weatherModeAuto => 'Tự động';

  @override
  String get weatherModeClear => 'Trời quang';

  @override
  String get weatherModeRain => 'Mưa';

  @override
  String get weatherModeFog => 'Sương mù';

  @override
  String get weatherModeThunderstorm => 'Mưa dông';

  @override
  String get commonLoading => 'Đang tải…';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonError => 'Đã xảy ra lỗi';

  @override
  String get commonFetchFailed => 'Không thể tải dữ liệu. Vui lòng thử lại.';

  @override
  String get commonEmpty => 'Không có dữ liệu';

  @override
  String get feedConnecting => 'Đang kết nối…';

  @override
  String get feedStale => 'Dữ liệu có thể đã lỗi thời';

  @override
  String get feedOffline => 'Mất kết nối';

  @override
  String get eewTitle => 'Cảnh báo sớm động đất';

  @override
  String get eewNone => 'Hiện không có cảnh báo sớm động đất';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'M$magnitude · độ sâu $depth km';
  }

  @override
  String get regionNationwide => 'Toàn quốc';

  @override
  String get regionCurrent => 'Vị trí hiện tại';

  @override
  String get regionCurrentUnavailable => 'Không thể lấy vị trí hiện tại';

  @override
  String get weatherPrecipitation => 'Lượng mưa';

  @override
  String get weatherHumidity => 'Độ ẩm';

  @override
  String weatherDataTime(String station, String time) {
    return '$station · Thời gian dữ liệu $time';
  }

  @override
  String get homeViewOnMap => 'Xem trên bản đồ';

  @override
  String get homeForecastTitle => 'Dự báo 24 giờ';

  @override
  String homeForecastHighLow(String high, String low) {
    return 'Cao $high° · Thấp $low°';
  }

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String homeForecastFeelsLike(String temp) {
    return 'Cảm giác $temp°';
  }

  @override
  String homeForecastHumidity(String value) {
    return 'Độ ẩm $value%';
  }

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · Cấp $level';
  }

  @override
  String get homeForecastUnavailable => 'Chọn khu vực để xem dự báo';

  @override
  String get homeForecastEmpty => 'Không có dữ liệu dự báo';

  @override
  String get homeActiveEventsTitle => 'Sự kiện đang hiệu lực';

  @override
  String get homeActiveEventsEmpty => 'Không có sự kiện đang hiệu lực';

  @override
  String get homeRainTrendTitle => 'Mưa 1 giờ tới';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute phút';
  }

  @override
  String homeRainTrendUpdated(String time) {
    return 'Cập nhật $time';
  }

  @override
  String get homeRainTrendNoData => 'Không có dữ liệu';

  @override
  String get homeRainTrendScattered => 'Có thể có mưa rào nhẹ';

  @override
  String get homeRainTrendLightSustained => 'Mưa nhỏ tiếp diễn trong 1 giờ tới';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return 'Mưa nhỏ có thể tạnh trong $minutes phút nữa';
  }

  @override
  String get homeRainTrendHeavySustained => 'Mưa lớn tiếp diễn trong 1 giờ tới';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return 'Mưa lớn có thể tạnh trong $minutes phút nữa';
  }

  @override
  String get mapLayers => 'Lớp bản đồ';

  @override
  String get mapLayerOrderTitle => 'Sắp xếp thứ tự lớp';

  @override
  String get mapLayerOrderReset => 'Đặt lại thứ tự mặc định';

  @override
  String get mapLayerRadar => 'Radar phản xạ tổng hợp';

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
  String get mapLayerQpesums => 'Dự báo mưa 1 giờ tới';

  @override
  String get mapLayerLightning => 'Sét';

  @override
  String lightningLegendCg(int minutes) {
    return 'Mây–đất · $minutes phút';
  }

  @override
  String lightningLegendCc(int minutes) {
    return 'Mây–mây · $minutes phút';
  }

  @override
  String get mapTimelineNow => 'Bây giờ';

  @override
  String get mapTimelinePast => 'Quá khứ';

  @override
  String get mapTimelineFuture => 'Tương lai';

  @override
  String get mapTimelineObserved => 'Quan trắc';

  @override
  String get mapTimelineForecast => 'Dự báo';

  @override
  String mapTimelineDataTime(String time) {
    return 'Thời gian dữ liệu $time';
  }

  @override
  String get notifySettingsMenu => 'Cài đặt thông báo';

  @override
  String get notifyTitle => 'Thông báo';

  @override
  String get notifyUnavailable =>
      'Thông báo đẩy chưa sẵn sàng — vui lòng thử lại sau giây lát.';

  @override
  String get notifySetFailed => 'Không thể lưu cài đặt. Vui lòng thử lại.';

  @override
  String get notifySectionEew => 'Cảnh báo sớm động đất';

  @override
  String get notifySectionEarthquake => 'Động đất';

  @override
  String get notifySectionWeather => 'Thời tiết';

  @override
  String get notifySectionTsunami => 'Sóng thần';

  @override
  String get notifySectionOther => 'Khác';

  @override
  String get notifyEew => 'Cảnh báo động đất khẩn cấp';

  @override
  String get notifyMonitor => 'Giám sát rung chấn mạnh';

  @override
  String get notifyReport => 'Báo cáo động đất';

  @override
  String get notifyIntensity => 'Báo cáo cường độ chấn động';

  @override
  String get notifyThunderstorm => 'Cảnh báo mưa dông';

  @override
  String get notifyAdvisory => 'Tin cảnh báo thời tiết';

  @override
  String get notifyEvacuation => 'Thông tin thảm họa';

  @override
  String get notifyTsunami => 'Thông tin sóng thần';

  @override
  String get notifyAnnouncement => 'Thông báo';

  @override
  String get notifyOptOff => 'Tắt';

  @override
  String get notifyOptAll => 'Nhận tất cả';

  @override
  String get notifyOptLocalIntensity4 => 'Cường độ tại chỗ từ 4 trở lên';

  @override
  String get notifyOptLocalIntensity1 => 'Cường độ tại chỗ từ 1 trở lên';

  @override
  String get notifyOptWeatherLocal => 'Chỉ vị trí hiện tại';

  @override
  String get notifyOptTsunamiWarning => 'Chỉ cảnh báo sóng thần';

  @override
  String get notifyOptTsunamiAll => 'Tin và cảnh báo sóng thần';

  @override
  String get onboardingNext => 'Tiếp theo';

  @override
  String get onboardingBack => 'Quay lại';

  @override
  String get onboardingScrollHint => 'Cuộn xuống để tiếp tục';

  @override
  String get onboardingIntroTitle => 'Chào mừng đến với DPIP';

  @override
  String get onboardingIntroBody =>
      'DPIP là người bạn đồng hành phòng chống thiên tai của bạn. Ứng dụng tích hợp cảnh báo sớm động đất, báo cáo động đất, thời tiết và thông tin về hiểm họa, đồng thời cảnh báo bạn ngay tại thời điểm quan trọng.\n\n• Động đất: cảnh báo sớm, báo cáo cường độ và báo cáo chi tiết\n• Thời tiết: tin nhắn mưa dông theo thời gian thực và cảnh báo thời tiết\n• Thông tin sóng thần và thảm họa\n\nTiếp theo, chúng tôi sẽ mời bạn xem lại Điều khoản Dịch vụ và cấp một vài quyền để DPIP có thể bảo vệ bạn theo thời gian thực.';

  @override
  String get onboardingTermsTitle => 'Điều khoản Dịch vụ';

  @override
  String get onboardingTermsBody =>
      'Vui lòng đọc kỹ các lưu ý sau đây trước khi sử dụng DPIP:\n\n• Mọi thông tin phải căn cứ theo nội dung do Cục Khí tượng Trung ương Đài Loan (CWA) công bố.\n\n• Tùy thuộc vào tình trạng mạng, máy chủ, ứng dụng và nguồn dữ liệu đầu nguồn, có khả năng không nhận được thông tin; chúng tôi nỗ lực hết sức để tránh điều này nhưng không thể bảo đảm rằng nó không bao giờ xảy ra.\n\n• Rung lắc mạnh có thể lan đến vị trí của bạn trước khi thông báo được gửi tới.\n\n• Cảnh báo sớm động đất là kết quả được tính toán nhanh nên có thể chứa sai số đáng kể — hãy hiểu rõ điều này và sử dụng một cách thận trọng.\n\n• Bất kỳ hành vi nào không được cơ quan chức năng cho phép đều có thể mang rủi ro pháp lý; vui lòng tuân thủ mọi quy định hiện hành.\n\nNgoài ra, để cung cấp cảnh báo theo khu vực, dịch vụ này thu thập và tải lên vị trí gần đúng cùng mã định danh thông báo đẩy của bạn — cả ở nền trước lẫn nền sau — chỉ nhằm quyết định những cảnh báo nào sẽ gửi cho bạn.\n\nBằng việc nhấn \"Đồng ý và tiếp tục\", bạn xác nhận rằng đã đọc, hiểu và đồng ý với những điều trên.';

  @override
  String get onboardingTermsAgree =>
      'Tôi đã đọc và đồng ý với Điều khoản Dịch vụ';

  @override
  String get onboardingAgreeContinue => 'Đồng ý và tiếp tục';

  @override
  String get onboardingPermsTitle => 'Quyền truy cập';

  @override
  String get onboardingPermsBody =>
      'Để DPIP có thể cảnh báo bạn ngay khi thảm họa xảy ra, vui lòng cấp các quyền sau. Bạn có thể thay đổi chúng bất cứ lúc nào trong cài đặt hệ thống.';

  @override
  String get onboardingPermNotify => 'Thông báo';

  @override
  String get onboardingPermNotifyDesc =>
      'Gửi cảnh báo động đất, thời tiết và thảm họa ngay khi chúng xảy ra.';

  @override
  String get onboardingPermCritical => 'Cảnh báo quan trọng';

  @override
  String get onboardingPermCriticalDesc =>
      'Cho phép các cảnh báo động đất nguy hiểm đến tính mạng phát âm thanh ngay cả khi ở chế độ im lặng hoặc Không làm phiền.';

  @override
  String get onboardingPermLocation => 'Vị trí';

  @override
  String get onboardingPermLocationDesc =>
      'Gửi cảnh báo phù hợp với nơi bạn đang ở.';

  @override
  String get onboardingPermBackground => 'Vị trí chạy nền';

  @override
  String get onboardingPermBackgroundDesc =>
      'Cho phép \"Luôn luôn\" để cảnh báo vẫn nhắm đúng vị trí của bạn ngay cả khi đã đóng ứng dụng.';

  @override
  String get onboardingPermBattery => 'Miễn trừ tối ưu hóa pin';

  @override
  String get onboardingPermBatteryDesc =>
      'Cho phép DPIP tiếp tục chạy ở chế độ nền để cảnh báo không bị trì hoãn hay bỏ lỡ.';

  @override
  String get onboardingGrant => 'Cấp quyền';

  @override
  String get onboardingGranted => 'Đã cấp';

  @override
  String get onboardingStart => 'Bắt đầu';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageSettings => 'Ngôn ngữ';

  @override
  String get languageSystem => 'Mặc định hệ thống';

  @override
  String get locationBannerServiceOff =>
      'Dịch vụ vị trí đang tắt — cảnh báo khu vực không thể nhắm đúng vùng của bạn.';

  @override
  String get locationBannerPermission =>
      'Chưa cấp quyền vị trí — cảnh báo khu vực không thể nhắm đúng vùng của bạn.';

  @override
  String get locationBannerFix => 'Mở cài đặt';

  @override
  String get notifyBannerDisabled =>
      'Thông báo đã tắt — bạn sẽ không nhận được cảnh báo thiên tai.';

  @override
  String get onboardingSkipTitle => 'Chưa cấp quyền';

  @override
  String get onboardingSkipBody =>
      'Nếu không có quyền vị trí và thông báo, DPIP không thể cảnh báo tức thời về động đất và thiên tai gần bạn. Bạn vẫn có thể cấp quyền sau trong Cài đặt.';

  @override
  String get onboardingSkipStay => 'Quay lại';

  @override
  String get onboardingSkipLeave => 'Vẫn bỏ qua';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get moreSourceCode => 'Mã nguồn';

  @override
  String get moreSectionApp => 'Tải ứng dụng';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get displaySettings => 'Hiển thị';

  @override
  String get defaultMapLayerSettings => 'Lớp bản đồ mặc định';

  @override
  String get defaultMapLayerSubtitle =>
      'Tab Bản đồ mở lớp này. Biểu tượng và nhãn thanh điều hướng dưới cũng theo lựa chọn.';

  @override
  String get mapNavRadar => 'Radar';

  @override
  String get mapNavQpesums => 'Dự báo';

  @override
  String get mapNavSatellite => 'Vệ tinh';

  @override
  String get mapNavLightning => 'Sét';

  @override
  String get mapNavTyphoon => 'Bão';

  @override
  String get mapNavEarthquake => 'Động đất';

  @override
  String get mapNavTemperature => 'Nhiệt độ';

  @override
  String get mapNavHumidity => 'Độ ẩm';

  @override
  String get mapNavPressure => 'Khí áp';

  @override
  String get mapNavWind => 'Gió';

  @override
  String get mapNavRain => 'Mưa';

  @override
  String get mapNavDisaster => 'Phòng thảm';

  @override
  String get displayTheme => 'Giao diện';

  @override
  String get themeSystem => 'Hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get moreSectionAbout => 'Giới thiệu';

  @override
  String get termsOfService => 'Điều khoản dịch vụ';

  @override
  String get faq => 'Câu hỏi thường gặp';

  @override
  String get openSourceLicenses => 'Giấy phép mã nguồn mở';

  @override
  String get sponsorTitle => 'Ủng hộ DPIP';

  @override
  String get sponsorIntro =>
      'DPIP cam kết cung cấp thông tin phòng chống thiên tai theo thời gian thực, không có quảng cáo hay mô hình lợi nhuận nào khác. Sự ủng hộ của bạn giúp chúng tôi duy trì máy chủ và tiếp tục phát triển.';

  @override
  String get sponsorSubscriptions => 'Gói đăng ký';

  @override
  String get sponsorRecommended => 'Đề xuất';

  @override
  String get sponsorOneTime => 'Ủng hộ một lần';

  @override
  String sponsorPerMonth(String price) {
    return '$price / tháng';
  }

  @override
  String get sponsorRestore => 'Khôi phục giao dịch';

  @override
  String get sponsorTerms => 'Điều khoản sử dụng';

  @override
  String get sponsorPrivacy => 'Chính sách quyền riêng tư';

  @override
  String get sponsorRestoring => 'Đang khôi phục giao dịch…';

  @override
  String get sponsorRestoreUnavailable =>
      'Không thể kết nối tới cửa hàng. Vui lòng thử lại sau.';

  @override
  String get commonClose => 'Đóng';

  @override
  String get mapLayerTemperature => 'Nhiệt độ';

  @override
  String get trendRange24h => '24 giờ';

  @override
  String get trendRange7d => '7 ngày';

  @override
  String get trendNoData => 'Không có dữ liệu xu hướng';

  @override
  String trendCumulativeTotal(String total) {
    return 'Tổng cộng $total mm';
  }

  @override
  String chartHourLabel(int hour) {
    return '${hour}h';
  }

  @override
  String get mapLayerHumidity => 'Độ ẩm';

  @override
  String get mapLayerPressure => 'Áp suất';

  @override
  String get mapLayerWind => 'Gió';

  @override
  String get mapLayerRain => 'Lượng mưa';

  @override
  String get rainIntervalMenu => 'Khung tích lũy';

  @override
  String get rainIntervalNow => 'Hôm nay';

  @override
  String get rainInterval10m => '10 phút';

  @override
  String get rainInterval1h => '1 giờ';

  @override
  String get rainInterval3h => '3 giờ';

  @override
  String get rainInterval6h => '6 giờ';

  @override
  String get rainInterval12h => '12 giờ';

  @override
  String get rainInterval24h => '24 giờ';

  @override
  String get rainInterval2d => '2 ngày';

  @override
  String get rainInterval3d => '3 ngày';

  @override
  String get mapLayerTyphoon => 'Bão';

  @override
  String get typhoonNoActive => 'Không có bão';

  @override
  String get typhoonWind => 'Sức gió';

  @override
  String get typhoonGust => 'Gió giật';

  @override
  String get typhoonPressure => 'Áp suất';

  @override
  String get typhoonMotion => 'Di chuyển';

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
  String get mapLayerMonitor => 'Giám sát địa chấn';

  @override
  String get mapLayerDisasterMap => 'Bản đồ phòng chống';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get disasterMapOverlayMenuTooltip => 'Lớp bản đồ phòng chống';

  @override
  String get disasterMapOverlaySectionLayers => 'Lớp';

  @override
  String get disasterMapOverlayAedTooltip => 'Hiện vị trí AED';

  @override
  String get aedAddress => 'Địa chỉ';

  @override
  String get aedRegion => 'Khu vực';

  @override
  String get aedCategory => 'Phân loại';

  @override
  String get aedType => 'Loại';

  @override
  String get aedPlaceDesc => 'Vị trí đặt';

  @override
  String get aedDescription => 'Ghi chú';

  @override
  String get aedHoursWeekday => 'Giờ ngày thường';

  @override
  String get aedHoursSaturday => 'Giờ thứ Bảy';

  @override
  String get aedHoursSunday => 'Giờ Chủ nhật';

  @override
  String get aedOpenRemark => 'Ghi chú giờ mở';

  @override
  String get aedEmergencyPhone => 'Điện thoại khẩn cấp';

  @override
  String get mapLayerRestroom => 'Nhà vệ sinh công cộng';

  @override
  String get mapLayerShelter => 'Nơi trú ẩn';

  @override
  String get disasterMapOverlayRestroomTooltip =>
      'Hiển thị nhà vệ sinh công cộng';

  @override
  String get disasterMapOverlayShelterTooltip => 'Hiển thị nơi trú ẩn';

  @override
  String get dpmOpenInMaps => 'Mở trong bản đồ';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String mapAppDefault(String app) {
    return '$app (mặc định)';
  }

  @override
  String get mapAppCopyCoordinates => 'Sao chép tọa độ';

  @override
  String get mapAppCoordinatesCopied => 'Đã sao chép tọa độ';

  @override
  String mapAppOpenFailed(String app) {
    return 'Không thể mở $app';
  }

  @override
  String get mapAppCallFailed => 'Thiết bị này không thể thực hiện cuộc gọi';

  @override
  String get mapOverlaySectionReference => 'Lớp tham chiếu';

  @override
  String get mapLayerCategoryEarthquake => 'Động đất';

  @override
  String get mapLayerCategoryTyphoon => 'Bão';

  @override
  String get mapLayerCategoryWeather => 'Quan sát thời tiết';

  @override
  String get mapLayerCategorySatellite => 'Vệ tinh';

  @override
  String get mapLayerCategoryRadar => 'Ra đa';

  @override
  String get mapLayerCategoryLife => 'Đời sống';

  @override
  String get mapLayerCategoryForecast => 'Dự báo số';

  @override
  String get mapOverlaySectionMap => 'Bản đồ';

  @override
  String get rainIntervalSection => 'Khoảng thời gian';

  @override
  String get mapTownLabels => 'Tên hương trấn';

  @override
  String get mapTownLabelsHint => 'Hiển thị tên hương trấn khi phóng to';

  @override
  String get mapTerrainRelief => 'Độ nổi địa hình';

  @override
  String get mapTerrainReliefHint => 'Hiển thị địa hình nổi trên bản đồ nền';

  @override
  String get dpmSheetEmpty =>
      'Chạm vào điểm đánh dấu trên bản đồ để xem chi tiết';

  @override
  String get dpmAddress => 'Địa chỉ';

  @override
  String get restroomTypeLabel => 'Loại';

  @override
  String get restroomCategoryLabel => 'Hạng mục';

  @override
  String get restroomGradeLabel => 'Hạng';

  @override
  String get restroomTypeFemale => 'Nhà vệ sinh nữ';

  @override
  String get restroomTypeMale => 'Nhà vệ sinh nam';

  @override
  String get restroomTypeMixed => 'Nhà vệ sinh chung';

  @override
  String get restroomTypeAccessible => 'Nhà vệ sinh tiếp cận được';

  @override
  String get restroomTypeGenderNeutral => 'Nhà vệ sinh trung tính giới';

  @override
  String get restroomTypeFamily => 'Nhà vệ sinh gia đình';

  @override
  String get restroomTypeUnspecified => 'Không xác định';

  @override
  String get restroomCategoryTransport => 'Giao thông';

  @override
  String get restroomCategoryPark => 'Công viên';

  @override
  String get restroomCategoryCommercial => 'Cơ sở thương mại';

  @override
  String get restroomCategoryReligious => 'Nơi tôn giáo';

  @override
  String get restroomCategoryCultural => 'Địa điểm văn hóa giải trí';

  @override
  String get restroomCategoryGovernment => 'Cơ quan công quyền';

  @override
  String get restroomCategoryWelfare => 'Cơ sở phúc lợi';

  @override
  String get restroomCategoryTourist => 'Khu du lịch thắng cảnh';

  @override
  String get restroomCategoryLeisure => 'Địa điểm vui chơi giải trí';

  @override
  String get restroomCategoryOther => 'Khác';

  @override
  String get restroomGradeExcellent => 'Xuất sắc';

  @override
  String get restroomGradeGood => 'Tốt';

  @override
  String get restroomGradeAverage => 'Trung bình';

  @override
  String get restroomGradePoor => 'Dưới chuẩn';

  @override
  String get shelterAddressLabel => 'Địa chỉ';

  @override
  String get shelterCapacityLabel => 'Sức chứa';

  @override
  String shelterCapacityValue(int n) {
    return '$n người';
  }

  @override
  String get shelterCategoryLabel => 'Loại thảm họa';

  @override
  String get shelterIndoorLabel => 'Trú ẩn trong nhà';

  @override
  String get shelterOutdoorLabel => 'Trú ẩn ngoài trời';

  @override
  String get shelterVulnerableOkLabel => 'Phù hợp người yếu thế';

  @override
  String get dpmYes => 'Có';

  @override
  String get dpmNo => 'Không';

  @override
  String get stationSheetEmpty => 'Chạm vào một trạm để xem số liệu';

  @override
  String monitorDelay(String value) {
    return 'Độ trễ $value s';
  }

  @override
  String get monitorWaiting => 'Đang chờ dữ liệu…';

  @override
  String mapLegendUnit(String unit) {
    return 'Đơn vị: $unit';
  }

  @override
  String get typhoonLegendPast => 'Quỹ đạo thực tế';

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
  String get typhoonLegendForecast => 'Quỹ đạo dự báo';

  @override
  String get typhoonLegendForecastPoint => 'Điểm dự báo';

  @override
  String get typhoonLegendCurrent => 'Tâm hiện tại';

  @override
  String get typhoonLegendCone => 'Nón dự báo';

  @override
  String get mapLegendExpand => 'Chú giải';

  @override
  String get mapLegendCollapse => 'Ẩn chú giải';

  @override
  String get mapMyLocation => 'Vị trí của tôi';

  @override
  String get mapResetNorth => 'Về hướng bắc';

  @override
  String get typhoonLegendCircle15 => 'Vòng gió mạnh';

  @override
  String get typhoonLegendCircleAvg => 'Average circle';

  @override
  String get typhoonLegendCircle25 => 'Vòng bão';

  @override
  String typhoonStormRadii(String ne, String se, String sw, String nw) {
    return 'NE $ne · SE $se · SW $sw · NW $nw km';
  }

  @override
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get typhoonLegendProbability => 'Xác suất đổ bộ';

  @override
  String get typhoonLegendWarningAreas => 'Vùng cảnh báo';

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
  String get typhoonWarningTitle => 'Cảnh báo bão';

  @override
  String typhoonWarningAreas(String areas) {
    return 'Khu vực: $areas';
  }

  @override
  String get typhoonTrackDetail => 'Chi tiết quỹ đạo';

  @override
  String get typhoonHistoryTitle => 'Thời điểm dữ liệu';

  @override
  String get typhoonHistoryLive => 'Trực tiếp';

  @override
  String get typhoonSatelliteTitle => 'Vệ tinh';

  @override
  String get typhoonOverlayForecastCallouts => 'Forecast tooltips';

  @override
  String get typhoonOverlayForecastCalloutsTooltip =>
      'Show forecast-point detail cards when zoomed in';

  @override
  String get dpmFilterSectionRestroom => 'Loại địa điểm';

  @override
  String get dpmFilterSectionRestroomType => 'Loại nhà vệ sinh';

  @override
  String get dpmFilterSectionShelter => 'Loại thiên tai nơi trú ẩn';

  @override
  String get dpmDisasterFlood => 'Lũ lụt';

  @override
  String get dpmDisasterEarthquake => 'Động đất';

  @override
  String get dpmDisasterLandslide => 'Sạt lở đất';

  @override
  String get dpmDisasterTsunami => 'Sóng thần';

  @override
  String get dpmDisasterSlope => 'Thiên tai sườn dốc';

  @override
  String get dpmDisasterNuclear => 'Sự cố hạt nhân';

  @override
  String get skyTime => 'Thời gian bầu trời';

  @override
  String get skyTimeAuto => 'Tự động';

  @override
  String get skyTimeDawn => 'Rạng đông';

  @override
  String get skyTimeSunrise => 'Bình minh';

  @override
  String get skyTimeMorning => 'Buổi sáng';

  @override
  String get skyTimeNoon => 'Buổi trưa';

  @override
  String get skyTimeAfternoon => 'Buổi chiều';

  @override
  String get skyTimeGolden => 'Giờ vàng';

  @override
  String get skyTimeSunset => 'Hoàng hôn';

  @override
  String get skyTimeDusk => 'Chạng vạng';

  @override
  String get skyTimeNight => 'Ban đêm';

  @override
  String get weatherModeCloudy => 'Nhiều mây';

  @override
  String get weatherModeOvercast => 'Trời âm u';

  @override
  String get weatherModeSnow => 'Tuyết rơi';

  @override
  String get weatherModeSand => 'Bụi cát';

  @override
  String get radarScanRange => 'Hiện phạm vi quét';

  @override
  String get radarScanRangeSubtitle =>
      'Đánh dấu vùng bốn radar thực sự quan trắc.';

  @override
  String get radarScanRangeHint => 'Ngoài khung là chưa quan trắc';

  @override
  String get radarOverlayMenuTooltip => 'Tùy chọn lớp radar';

  @override
  String get radarCountyOutline => 'Ranh giới huyện thị';

  @override
  String get radarGlobalOutline => 'Biên giới quốc gia';

  @override
  String get radarGlobalOutlineHint => 'Khung ngoài của mỗi quốc gia';

  @override
  String get radarCountyOutlineHint => 'Vẽ đè lên tiếng vọng';

  @override
  String get radarCountyOutlineSubtitle =>
      'Giữ ranh giới rõ ràng dưới lớp phản hồi radar.';

  @override
  String get radarTownOutline => 'Ranh giới xã phường';

  @override
  String get radarTownOutlineHint => 'Lưới chi tiết hơn';

  @override
  String get radarTownOutlineSubtitle =>
      'Giữ ranh giới xã phường rõ ràng dưới lớp phản hồi radar.';

  @override
  String get qpesumsOverlayMenuTooltip => 'Tùy chọn lớp dự báo mưa định lượng';

  @override
  String get windForecastOverlayMenuTooltip => 'Tùy chọn lớp dự báo gió';

  @override
  String get windForecastCountyOutlineHint => 'Vẽ trên trường gió';

  @override
  String get windForecastGlobalOutlineHint => 'Khung ngoài của mỗi quốc gia';

  @override
  String get windForecastTownOutlineHint => 'Lưới mịn hơn';
}
