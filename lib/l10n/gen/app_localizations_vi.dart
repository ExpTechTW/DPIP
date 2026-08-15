// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String typhoonValueLat(String lat) {
    return '$lat°N';
  }

  @override
  String get onboardingSkipBody =>
      'Nếu không có quyền vị trí và thông báo, DPIP không thể cảnh báo tức thời về động đất và thiên tai gần bạn. Bạn vẫn có thể cấp quyền sau trong Cài đặt.';

  @override
  String get rainInterval24h => '24 giờ';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return 'Mưa lớn có thể tạnh trong $minutes phút nữa';
  }

  @override
  String get mapTimelineObserved => 'Quan trắc';

  @override
  String get regionSelectTitle => 'Chọn khu vực';

  @override
  String get skyTimeNoon => 'Buổi trưa';

  @override
  String get radarCountyOutlineSubtitle =>
      'Giữ ranh giới rõ ràng dưới lớp phản hồi radar.';

  @override
  String get dpmFilterSectionRestroomType => 'Loại nhà vệ sinh';

  @override
  String get mapLayerSatelliteB03 => 'Himawari Red (B03)';

  @override
  String get reportFilterIntensity => 'Cường độ';

  @override
  String get mapLayerLightning => 'Sét';

  @override
  String get restroomTypeMale => 'Nhà vệ sinh nam';

  @override
  String get meshtasticLastReceived => 'Last received';

  @override
  String get reportDetailSortByCounty => 'Sắp xếp theo khu vực';

  @override
  String get homeRainTrendScattered => 'Có thể có mưa rào nhẹ';

  @override
  String get meshtasticUptime => 'Uptime';

  @override
  String get weatherRankingTempExtremes => 'Cực trị nhiệt độ';

  @override
  String get themeLight => 'Sáng';

  @override
  String get mapTerrainReliefHint => 'Hiển thị địa hình nổi trên bản đồ nền';

  @override
  String get meshtasticEmptyMessage => '(empty message)';

  @override
  String get moreSectionRegion => 'Khu vực';

  @override
  String get dpmDisasterEarthquake => 'Động đất';

  @override
  String get mapLayerSatellite => 'Himawari Infrared (B13)';

  @override
  String get aedHoursSaturday => 'Giờ thứ Bảy';

  @override
  String get dpmDisasterSlope => 'Thiên tai sườn dốc';

  @override
  String get moonPhaseNew => 'New moon';

  @override
  String get notifySectionEew => 'Cảnh báo sớm động đất';

  @override
  String get mapResetNorth => 'Về hướng bắc';

  @override
  String get rainInterval2d => '2 ngày';

  @override
  String get mapTownLabelsHint => 'Hiển thị tên hương trấn khi phóng to';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get notifyOptTsunamiWarning => 'Chỉ cảnh báo sóng thần';

  @override
  String get mapLayerSatelliteBtdFog => 'Himawari Night Fog';

  @override
  String get moreSectionAdvanced => 'Nâng cao';

  @override
  String get weatherRankingExtremeRange => 'Biên độ ngày';

  @override
  String get permissionsTitle => 'Kiểm tra quyền';

  @override
  String get permissionsBody =>
      'DPIP cần các quyền này để cảnh báo bạn kịp thời. Không nhận được cảnh báo thường là do thiếu một trong số đó.';

  @override
  String get notifySettingsMenu => 'Cài đặt thông báo';

  @override
  String get typhoonHistoryTitle => 'Thời điểm dữ liệu';

  @override
  String mapAppDefault(String app) {
    return '$app (mặc định)';
  }

  @override
  String get trendRange24h => '24 giờ';

  @override
  String get mapLayerStyleJmaTooltip =>
      'Grayscale base, tinted below −40 °C to highlight cloud-top height';

  @override
  String weatherRankingRecordedAt(String time) {
    return 'Ghi nhận lúc $time';
  }

  @override
  String get mapLayerRain => 'Lượng mưa';

  @override
  String get mapLayerQpesums => 'Dự báo mưa 1 giờ tới';

  @override
  String get mapOverlaySectionMap => 'Bản đồ';

  @override
  String get mapTerrainRelief => 'Độ nổi địa hình';

  @override
  String get eewMaxIntensity => 'Cường độ tối đa';

  @override
  String get mapLegendCollapse => 'Ẩn chú giải';

  @override
  String get updateAvailableTitle => 'Đã có bản mới';

  @override
  String updateAvailableBody(String version) {
    return 'Phiên bản $version đã phát hành.';
  }

  @override
  String get updateSkip => 'Bỏ qua lần này';

  @override
  String get updateViewChangelog => 'Xem thay đổi';

  @override
  String get updateOpenAppStore => 'App Store';

  @override
  String get updateOpenTestFlight => 'TestFlight';

  @override
  String get updateOpenPlayStore => 'Play Store';

  @override
  String get updateDownload => 'Tải xuống';

  @override
  String get changelogTitle => 'Nhật ký cập nhật';

  @override
  String get reportFilterOrderDesc => 'Giảm dần';

  @override
  String get meshtasticExcludeMqttSubtitle =>
      'Nodes bridged over the internet, not heard by radio';

  @override
  String get reportFilterIntensityInfoTitle => 'Thang cường độ mới và cũ';

  @override
  String get mapLayerTyphoon => 'Bão';

  @override
  String get radarOverlayMenuTooltip => 'Tùy chọn lớp radar';

  @override
  String get mapMyLocation => 'Vị trí của tôi';

  @override
  String get meshtasticNodes => 'Nodes';

  @override
  String get meshtasticSend => 'Send';

  @override
  String get typhoonOverlayStormL7Tooltip =>
      'Level-7 wind field + average circle (purple)';

  @override
  String get aedType => 'Loại';

  @override
  String get termsOfService => 'Điều khoản dịch vụ';

  @override
  String get typhoonLegendCircle25 => 'Vòng bão';

  @override
  String get sponsorTitle => 'Ủng hộ DPIP';

  @override
  String get mapNavSatellite => 'Vệ tinh';

  @override
  String homeRainTrendUpdated(String time) {
    return 'Cập nhật $time';
  }

  @override
  String get onboardingNext => 'Tiếp theo';

  @override
  String get weatherRankingMergeTown => 'Xã/trấn';

  @override
  String get mapLayerMonitor => 'Giám sát địa chấn';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get sponsorSubscriptions => 'Gói đăng ký';

  @override
  String typhoonValueLon(String lon) {
    return '$lon°E';
  }

  @override
  String get skyTime => 'Thời gian bầu trời';

  @override
  String get weatherModeCloudy => 'Nhiều mây';

  @override
  String get skyTimeDusk => 'Chạng vạng';

  @override
  String get meshtasticFirmware => 'Firmware';

  @override
  String get reportFilterDateEndNote => 'Ngày kết thúc: đến 24:00（Đài Bắc）';

  @override
  String get reportFilterSortMagnitude => 'Độ lớn';

  @override
  String get meshtasticSilent => 'Silent';

  @override
  String get mapLayerCategoryEarthquake => 'Động đất';

  @override
  String get mapLayerSatelliteB12 => 'Himawari Ozone (B12)';

  @override
  String get typhoonLegendPast => 'Quỹ đạo thực tế';

  @override
  String get restroomCategoryOther => 'Khác';

  @override
  String homeForecastHighLow(String high, String low) {
    return 'Cao $high° · Thấp $low°';
  }

  @override
  String get locationBannerFix => 'Mở cài đặt';

  @override
  String get mapLegendExpand => 'Chú giải';

  @override
  String get eewNone => 'Hiện không có cảnh báo sớm động đất';

  @override
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String get notifyOptTsunamiAll => 'Tin và cảnh báo sóng thần';

  @override
  String get meshtasticLayerOptions => 'Node options';

  @override
  String get onboardingAgreeContinue => 'Đồng ý và tiếp tục';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get meshtasticNodeId => 'Node ID';

  @override
  String reportDetailNumbered(String number) {
    return 'Động đất có cảm nhận đáng kể số $number';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => 'With average circle';

  @override
  String get disasterMapOverlayRestroomTooltip =>
      'Hiển thị nhà vệ sinh công cộng';

  @override
  String get weatherRankingTitle => 'Xếp hạng quan trắc';

  @override
  String get homeRainTrendHeavySustained => 'Mưa lớn tiếp diễn trong 1 giờ tới';

  @override
  String get notifySectionTsunami => 'Sóng thần';

  @override
  String get restroomCategoryPark => 'Công viên';

  @override
  String get moreLinkOpenFailed => 'Không thể mở liên kết';

  @override
  String get themeDark => 'Tối';

  @override
  String get sponsorRestore => 'Khôi phục giao dịch';

  @override
  String get meshtasticChannelWorking => 'Setting up the DPIP channel…';

  @override
  String get meshtasticRegionSwitch => 'Switch to TW';

  @override
  String get meshtasticTraffic => 'Traffic';

  @override
  String get mapLayerStyleBdTooltip =>
      'Dvorak BD curve — the stepped grayscale for tropical-cyclone intensity analysis';

  @override
  String get disasterMapOverlayAedTooltip => 'Hiện vị trí AED';

  @override
  String get mapLayerHumidity => 'Độ ẩm';

  @override
  String get mapLayerSatelliteTransparentNight =>
      'Night = transparent, the basemap shows';

  @override
  String get meshtasticScanning => 'Scanning…';

  @override
  String regionSelectFull(int max) {
    return 'Bạn chỉ có thể lưu tối đa $max khu vực';
  }

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => 'Thêm';

  @override
  String get meshtasticDpipChannel => 'DPIP channel';

  @override
  String get disasterMapOverlaySectionLayers => 'Lớp';

  @override
  String get mapLayerSatelliteB05 => 'Himawari Near-Infrared (B05)';

  @override
  String typhoonStormRadii(String ne, String se, String sw, String nw) {
    return 'NE $ne · SE $se · SW $sw · NW $nw km';
  }

  @override
  String get typhoonLabelNe => 'NE';

  @override
  String get meshtasticCopied => 'Message copied';

  @override
  String get reportListEmpty => 'Không có báo cáo động đất';

  @override
  String get reportListEnd => 'Hết danh sách';

  @override
  String get mapLayerSatelliteTruecolor => 'Himawari True Color';

  @override
  String get typhoonOverlaySectionExtra => 'Overlays';

  @override
  String get eewSWave => 'Sóng S';

  @override
  String get meshtasticBusyTitle => 'Another app is using this radio';

  @override
  String get restroomCategoryCultural => 'Địa điểm văn hóa giải trí';

  @override
  String get typhoonLabelWind => 'Max. sustained wind near centre';

  @override
  String get radarGlobalOutlineHint => 'Khung ngoài của mỗi quốc gia';

  @override
  String get notifyEvacuation => 'Thông tin thảm họa';

  @override
  String get typhoonLegendCircle15 => 'Vòng gió mạnh';

  @override
  String get dataSectionAstronomy => 'Astronomy';

  @override
  String get homeRainTrendLightSustained => 'Mưa nhỏ tiếp diễn trong 1 giờ tới';

  @override
  String get commonError => 'Đã xảy ra lỗi';

  @override
  String get moonPhaseWaningCrescent => 'Waning crescent';

  @override
  String get meshtasticPower => 'Power';

  @override
  String get mapTimelineNow => 'Bây giờ';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportDetailOpenReport => 'Trang báo cáo';

  @override
  String get trendRange7d => '7 ngày';

  @override
  String typhoonWarningAreas(String areas) {
    return 'Khu vực: $areas';
  }

  @override
  String get rainIntervalSection => 'Khoảng thời gian';

  @override
  String get notifyTitle => 'Thông báo';

  @override
  String get meshtasticTxPower => 'TX power';

  @override
  String get restroomCategoryLabel => 'Hạng mục';

  @override
  String get sponsorRestoring => 'Đang khôi phục giao dịch…';

  @override
  String get sponsorIntro =>
      'DPIP cam kết cung cấp thông tin phòng chống thiên tai theo thời gian thực, không có quảng cáo hay mô hình lợi nhuận nào khác. Sự ủng hộ của bạn giúp chúng tôi duy trì máy chủ và tiếp tục phát triển.';

  @override
  String get shelterAddressLabel => 'Địa chỉ';

  @override
  String get typhoonLabelStormAvg => 'Avg. radius of Beaufort 10 winds';

  @override
  String get restroomCategoryCommercial => 'Cơ sở thương mại';

  @override
  String get aedRegion => 'Khu vực';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return 'Mưa nhỏ có thể tạnh trong $minutes phút nữa';
  }

  @override
  String get reportDetailInfo => 'Chi tiết';

  @override
  String get mapNavWind => 'Gió';

  @override
  String get windForecastOverlayMenuTooltip => 'Tùy chọn lớp dự báo gió';

  @override
  String get dataWeatherRankingSubtitle => 'Xếp hạng trạm trực tiếp';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute phút';
  }

  @override
  String get rainInterval6h => '6 giờ';

  @override
  String get restroomTypeUnspecified => 'Không xác định';

  @override
  String get typhoonOverlayProbabilityHint => 'Hides the forecast cone';

  @override
  String get mapLayerSatelliteGlobalOutline => 'Country border';

  @override
  String get mapNavTemperature => 'Nhiệt độ';

  @override
  String get typhoonLegendForecastPoint => 'Điểm dự báo';

  @override
  String get reportListYesterday => 'Hôm qua';

  @override
  String get moreSectionLinks => 'Liên kết';

  @override
  String get feedOffline => 'Mất kết nối';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get moreSectionDisplay => 'Hiển thị';

  @override
  String get rainInterval3d => '3 ngày';

  @override
  String get defaultMapLayerSubtitle =>
      'Tab Bản đồ mở lớp này. Biểu tượng và nhãn thanh điều hướng dưới cũng theo lựa chọn.';

  @override
  String get aedDescription => 'Ghi chú';

  @override
  String get typhoonOverlayWeatherRadarTooltip =>
      'Radar echo closest to the typhoon bulletin time';

  @override
  String get onboardingPermLocationDesc =>
      'Gửi cảnh báo phù hợp với nơi bạn đang ở.';

  @override
  String get mapLayerSatelliteB16 => 'Himawari CO₂ (B16)';

  @override
  String get homeActiveEventsEmpty => 'Không có sự kiện đang hiệu lực';

  @override
  String get typhoonLabelPosition => 'Centre location';

  @override
  String get weatherRankingBy => 'Theo';

  @override
  String get typhoonIntensityMild => 'Mild typhoon';

  @override
  String get windForecastGlobalOutlineHint => 'Khung ngoài của mỗi quốc gia';

  @override
  String get rainInterval1h => '1 giờ';

  @override
  String get eewLocalIntensity => 'Ước tính tại vị trí';

  @override
  String get mapLayerRadar => 'Radar phản xạ tổng hợp';

  @override
  String get restroomCategoryReligious => 'Nơi tôn giáo';

  @override
  String get meshtasticRole => 'Role';

  @override
  String get mapLayerSatelliteCloudCloudy => 'Cloudy';

  @override
  String get skyTimeSunrise => 'Bình minh';

  @override
  String get meshtasticNoMessages => 'No messages yet';

  @override
  String get onboardingPermNotifyDesc =>
      'Gửi cảnh báo động đất, thời tiết và thảm họa ngay khi chúng xảy ra.';

  @override
  String get radarTownOutline => 'Ranh giới xã phường';

  @override
  String get mapLayerStyleSection => 'Colour style';

  @override
  String get disasterMapOverlayMenuTooltip => 'Lớp bản đồ phòng chống';

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
  String get dpmDisasterTsunami => 'Sóng thần';

  @override
  String get changelogTypeStable => 'Chính thức';

  @override
  String get mapLayerSatelliteTransparentClear =>
      'Clear sky = transparent, the basemap shows';

  @override
  String get mapOverlaySectionReference => 'Lớp tham chiếu';

  @override
  String get mapLayerSatelliteB02 => 'Himawari Green (B02)';

  @override
  String get reportListLocalFelt => 'Cảm nhận cục bộ';

  @override
  String get weatherRankingEmpty => 'Không có quan trắc để xếp hạng';

  @override
  String get notifySectionOther => 'Khác';

  @override
  String weatherRankingMeta(String time, int count) {
    return 'Thời gian: $time\n$count trạm';
  }

  @override
  String get onboardingTermsAgree =>
      'Tôi đã đọc và đồng ý với Điều khoản Dịch vụ';

  @override
  String get mapLayerSatelliteTransparentNoVegetation =>
      'Below 0.1 = transparent (no vegetation)';

  @override
  String get notifyOptLocalIntensity4 => 'Cường độ tại chỗ từ 4 trở lên';

  @override
  String get eewArrived => 'Đã đến';

  @override
  String get meshtasticNoDevices => 'No Meshtastic devices found';

  @override
  String get mapLayerCategoryLife => 'Đời sống';

  @override
  String get reportFilterSortIntensity => 'Cường độ';

  @override
  String get typhoonMotion => 'Di chuyển';

  @override
  String get meshtasticStateDisconnected => 'Disconnected';

  @override
  String get typhoonIntensityIntense => 'Intense typhoon';

  @override
  String get mapLayerOrderTitle => 'Sắp xếp thứ tự lớp';

  @override
  String get dpmYes => 'Có';

  @override
  String get meshtasticNoHistory => 'Not enough history yet';

  @override
  String get reportDetailLocalIntensityUnavailable =>
      'Không có dữ liệu cường độ';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportListDepthUnit => 'km';

  @override
  String get reportFilterDepth => 'Độ sâu';

  @override
  String get onboardingScrollHint => 'Cuộn xuống để tiếp tục';

  @override
  String get mapNavQpesums => 'Dự báo';

  @override
  String get navMap => 'Bản đồ';

  @override
  String get notifyAdvisory => 'Tin cảnh báo thời tiết';

  @override
  String get reportFilterReset => 'Đặt lại';

  @override
  String get mapLayerSatelliteMndwi => 'Himawari MNDWI';

  @override
  String get typhoonOverlaySectionStorm => 'Storm wind';

  @override
  String get moonPhaseFull => 'Full moon';

  @override
  String get moonPhaseWaningGibbous => 'Waning gibbous';

  @override
  String get weatherDynamicStateSubtitle =>
      'Ghi đè thời tiết nền của trang chủ';

  @override
  String get reportFilterIntensityInfoModernTitle => 'Mới (từ 2020)';

  @override
  String typhoonDataTime(String time) {
    return 'Data time\n$time';
  }

  @override
  String get restroomTypeAccessible => 'Nhà vệ sinh tiếp cận được';

  @override
  String get moreSectionAbout => 'Giới thiệu';

  @override
  String get meshtasticSelectDevice => 'Select a radio';

  @override
  String get onboardingIntroBody =>
      'DPIP là người bạn đồng hành phòng chống thiên tai của bạn. Ứng dụng tích hợp cảnh báo sớm động đất, báo cáo động đất, thời tiết và thông tin về hiểm họa, đồng thời cảnh báo bạn ngay tại thời điểm quan trọng.\n\n• Động đất: cảnh báo sớm, báo cáo cường độ và báo cáo chi tiết\n• Thời tiết: tin nhắn mưa dông theo thời gian thực và cảnh báo thời tiết\n• Thông tin sóng thần và thảm họa\n\nTiếp theo, chúng tôi sẽ mời bạn xem lại Điều khoản Dịch vụ và cấp một vài quyền để DPIP có thể bảo vệ bạn theo thời gian thực.';

  @override
  String get shelterCapacityLabel => 'Sức chứa';

  @override
  String get reportDetailImage => 'Hình ảnh báo cáo';

  @override
  String get meshtasticStateConfiguring => 'Configuring…';

  @override
  String get typhoonLabelGaleAvg => 'Avg. radius of Beaufort 7 winds';

  @override
  String get onboardingPermNotify => 'Thông báo';

  @override
  String get meshtasticClearMessages => 'Clear messages';

  @override
  String get meshtasticNotifyMessages => 'Notify on new messages';

  @override
  String get defaultMapLayerSettings => 'Lớp bản đồ mặc định';

  @override
  String get moreSectionNotify => 'Thông báo';

  @override
  String get notifyUnavailable =>
      'Thông báo đẩy chưa sẵn sàng — vui lòng thử lại sau giây lát.';

  @override
  String get mapLayerOrderReset => 'Đặt lại thứ tự mặc định';

  @override
  String get dpmAddress => 'Địa chỉ';

  @override
  String get weatherRankingMergeCounty => 'Huyện/thành';

  @override
  String get moreSectionApp => 'Tải ứng dụng';

  @override
  String get reportFilterIntensityInfoLegacyBody =>
      'Chỉ có mức 0–7, không tách 5−/5+/6−/6+.';

  @override
  String get mapLayerSatelliteSst => 'Himawari Sea Surface Temperature';

  @override
  String get qpesumsOverlayMenuTooltip => 'Tùy chọn lớp dự báo mưa định lượng';

  @override
  String get mapTimelineFuture => 'Tương lai';

  @override
  String get typhoonLegendCircleAvg => 'Average circle';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get typhoonLabelSe => 'SE';

  @override
  String get radarTownOutlineHint => 'Lưới chi tiết hơn';

  @override
  String eewCountdown(int seconds) {
    return '$seconds giây';
  }

  @override
  String get typhoonLabelGust => 'Peak gust';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get sponsorTerms => 'Điều khoản sử dụng';

  @override
  String get restroomTypeGenderNeutral => 'Nhà vệ sinh trung tính giới';

  @override
  String get notifyThunderstorm => 'Cảnh báo mưa dông';

  @override
  String get skyTimeGolden => 'Giờ vàng';

  @override
  String get moonAge => 'Age';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return 'Hiện tại $value°C';
  }

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable => 'Chọn khu vực để xem dự báo';

  @override
  String get mapLayers => 'Lớp bản đồ';

  @override
  String get meshtasticHardware => 'Hardware';

  @override
  String get languageSettings => 'Ngôn ngữ';

  @override
  String get dpmDisasterNuclear => 'Sự cố hạt nhân';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String homeForecastFeelsLike(String temp) {
    return 'Cảm giác $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => 'Aligned to bulletin time';

  @override
  String get skyTimeDawn => 'Rạng đông';

  @override
  String get skyTimeAfternoon => 'Buổi chiều';

  @override
  String get meshtasticLastHeard => 'Last heard';

  @override
  String get typhoonWarningTitle => 'Cảnh báo bão';

  @override
  String get moreSourceCode => 'Mã nguồn';

  @override
  String get mapLayerCategoryWeather => 'Quan sát thời tiết';

  @override
  String get mapLayerSatelliteB09 => 'Himawari Mid Water Vapour (B09)';

  @override
  String get windForecastTownOutlineHint => 'Lưới mịn hơn';

  @override
  String get mapLayerSatelliteCloudmask => 'Himawari Cloud Mask';

  @override
  String get mapAppCopyCoordinates => 'Sao chép tọa độ';

  @override
  String get reportFilterIntensityInfoIntro =>
      'CWA đổi thang cường độ từ 1/1/2020 (giờ Đài Bắc).';

  @override
  String get mapNavEarthquake => 'Động đất';

  @override
  String get typhoonGust => 'Gió giật';

  @override
  String get restroomGradeAverage => 'Trung bình';

  @override
  String get mapLayerSatelliteBtdCo2 => 'Himawari Cirrus / Cloud Height';

  @override
  String get onboardingPermBackgroundDesc =>
      'Cho phép \"Luôn luôn\" để cảnh báo vẫn nhắm đúng vị trí của bạn ngay cả khi đã đóng ứng dụng.';

  @override
  String get mapTimelineForecast => 'Dự báo';

  @override
  String get restroomTypeLabel => 'Loại';

  @override
  String get navEarthquake => 'Động đất';

  @override
  String get typhoonOverlayStormL10Tooltip =>
      'Level-10 wind field + average circle (yellow)';

  @override
  String get moonPhaseWaxingGibbous => 'Waxing gibbous';

  @override
  String get reportDetailTitle => 'Báo cáo động đất';

  @override
  String get moreTremReport => 'Báo cáo phát hiện TREM';

  @override
  String weatherDataTime(String station, String time) {
    return '$station · Thời gian dữ liệu $time';
  }

  @override
  String get meshtasticNoNodes => 'No nodes heard yet';

  @override
  String get meshtasticViaMqtt => 'Via MQTT (internet)';

  @override
  String get radarCountyOutline => 'Ranh giới huyện thị';

  @override
  String get onboardingGranted => 'Đã cấp';

  @override
  String get commonClose => 'Đóng';

  @override
  String get restroomGradeLabel => 'Hạng';

  @override
  String get rainIntervalNow => 'Hôm nay';

  @override
  String get changelogCurrentVersion => 'Hiện tại';

  @override
  String get typhoonLabelPressure => 'Central pressure';

  @override
  String get typhoonOverlayForecastCalloutsTooltip =>
      'Show forecast-point detail cards when zoomed in';

  @override
  String get aedOpenRemark => 'Ghi chú giờ mở';

  @override
  String get onboardingPermsBody =>
      'Để DPIP có thể cảnh báo bạn ngay khi thảm họa xảy ra, vui lòng cấp các quyền sau. Bạn có thể thay đổi chúng bất cứ lúc nào trong cài đặt hệ thống.';

  @override
  String get typhoonOverlaySectionWeather => 'Weather underlay';

  @override
  String get notifyOptWeatherLocal => 'Chỉ vị trí hiện tại';

  @override
  String get mapNavRain => 'Mưa';

  @override
  String get moonDays => 'days';

  @override
  String mapLegendUnit(String unit) {
    return 'Đơn vị: $unit';
  }

  @override
  String get weatherModeClear => 'Trời quang';

  @override
  String get meshtasticRadio => 'Radio';

  @override
  String get commonEmpty => 'Không có dữ liệu';

  @override
  String get mapLayerSatelliteB01 => 'Himawari Blue (B01)';

  @override
  String get meshtasticExternalPower => 'External power';

  @override
  String get moonPhaseLastQuarter => 'Last quarter';

  @override
  String get reportFilterOrderAsc => 'Tăng dần';

  @override
  String get reportFilterApply => 'Áp dụng';

  @override
  String get reportDetailImageUnavailable => 'Hình ảnh báo cáo chưa có sẵn';

  @override
  String get weatherRankingHighest => 'Cao nhất';

  @override
  String get reportDetailReplay => 'Phát lại';

  @override
  String get mapLayerRestroom => 'Nhà vệ sinh công cộng';

  @override
  String get restroomCategoryWelfare => 'Cơ sở phúc lợi';

  @override
  String get restroomGradeExcellent => 'Xuất sắc';

  @override
  String get meshtasticLastSent => 'Last sent';

  @override
  String get meshtasticName => 'Name';

  @override
  String get meshtasticScan => 'Scan';

  @override
  String get mapLayerCategoryForecast => 'Dự báo số';

  @override
  String get meshtasticChannelFailed => 'Couldn\'t set up the DPIP channel';

  @override
  String get themeSystem => 'Hệ thống';

  @override
  String get mapLayerSatelliteNdvi => 'Himawari NDVI';

  @override
  String get typhoonLegendForecast => 'Quỹ đạo dự báo';

  @override
  String typhoonValueHpa(String n) {
    return '$n hPa';
  }

  @override
  String get weatherPrecipitation => 'Lượng mưa';

  @override
  String get moonNextFullMoon => 'Next full moon';

  @override
  String get dpmSheetEmpty =>
      'Chạm vào điểm đánh dấu trên bản đồ để xem chi tiết';

  @override
  String get onboardingSkipLeave => 'Vẫn bỏ qua';

  @override
  String get onboardingBack => 'Quay lại';

  @override
  String get aedPlaceDesc => 'Vị trí đặt';

  @override
  String get onboardingSkipTitle => 'Chưa cấp quyền';

  @override
  String get restroomTypeFamily => 'Nhà vệ sinh gia đình';

  @override
  String typhoonValueKm(String n) {
    return '$n km';
  }

  @override
  String get typhoonPressure => 'Áp suất';

  @override
  String get onboardingPermBattery => 'Miễn trừ tối ưu hóa pin';

  @override
  String get typhoonLabelNw => 'NW';

  @override
  String get dpmDisasterFlood => 'Lũ lụt';

  @override
  String get moonPhaseWaxingCrescent => 'Waxing crescent';

  @override
  String get restroomCategoryLeisure => 'Địa điểm vui chơi giải trí';

  @override
  String get mapLayerTemperature => 'Nhiệt độ';

  @override
  String get aedCategory => 'Phân loại';

  @override
  String get meshtasticChannels => 'Channels';

  @override
  String get monitorWaiting => 'Đang chờ dữ liệu…';

  @override
  String get typhoonOverlayForecastCallouts => 'Forecast tooltips';

  @override
  String get reportDetailEpicenter => 'Tọa độ tâm chấn';

  @override
  String get meshtasticVoltage => 'Voltage';

  @override
  String get mapLayerMeshtasticSubtitle =>
      'LoRa mesh nodes heard by your radio';

  @override
  String get mapLayerWind => 'Gió';

  @override
  String get reportDetailMagnitude => 'Độ lớn';

  @override
  String get reportDetailAreaIntensity => 'Cường độ theo khu vực';

  @override
  String get rainInterval12h => '12 giờ';

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get dpmDisasterLandslide => 'Sạt lở đất';

  @override
  String get notifyMonitor => 'Giám sát rung chấn mạnh';

  @override
  String get onboardingStart => 'Bắt đầu';

  @override
  String sponsorPerMonth(String price) {
    return '$price / tháng';
  }

  @override
  String get mapLayerPressure => 'Áp suất';

  @override
  String get mapLayerSatelliteB04 => 'Himawari Near-Infrared (B04)';

  @override
  String get mapLayerSatelliteTransparentZero =>
      'Zero difference = transparent (no signal)';

  @override
  String get shelterIndoorLabel => 'Trú ẩn trong nhà';

  @override
  String get notifyOptOff => 'Tắt';

  @override
  String get reportFilterSortTime => 'Thời gian';

  @override
  String get mapLayerSatelliteCloudProbablyClear => 'Probably clear';

  @override
  String get weatherModeThunderstorm => 'Mưa dông';

  @override
  String get homeViewOnMap => 'Xem trên bản đồ';

  @override
  String get reportFilterIntensityInfoLegacyTitle => 'Cũ (trước 2020)';

  @override
  String get typhoonLabelSpeed => 'Past movement speed';

  @override
  String mapAppOpenFailed(String app) {
    return 'Không thể mở $app';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB composite (JMA recipe)';

  @override
  String get meshtasticReceived => 'Received';

  @override
  String get weatherRankingExtremeLow => 'Thấp nhất ngày';

  @override
  String get mapLayerSatelliteB10 => 'Himawari Lower Water Vapour (B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => 'Probably cloudy';

  @override
  String get mapLayerSatelliteTransparentNoWater =>
      '≤ 0 = transparent (no water)';

  @override
  String get shelterCategoryLabel => 'Loại thảm họa';

  @override
  String get meshtasticStateConnecting => 'Connecting…';

  @override
  String get moonTitle => 'Moon';

  @override
  String get weatherRankingGust => 'Gió giật';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get dpmFilterSectionShelter => 'Loại thiên tai nơi trú ẩn';

  @override
  String get moreServerStatus => 'Trạng thái máy chủ';

  @override
  String get notifySectionWeather => 'Thời tiết';

  @override
  String get meshtasticPreset => 'Modem preset';

  @override
  String get dataSectionSeismic => 'Địa chấn';

  @override
  String get changelogBodyEmpty => 'Không có ghi chú cho bản phát hành này.';

  @override
  String get radarGlobalOutline => 'Biên giới quốc gia';

  @override
  String get notifyEew => 'Cảnh báo động đất khẩn cấp';

  @override
  String get regionNationwide => 'Toàn quốc';

  @override
  String get moreNotifyLog => 'Nhật ký thông báo DPIP';

  @override
  String get regionCurrent => 'Vị trí hiện tại';

  @override
  String get dpmFilterSectionRestroom => 'Loại địa điểm';

  @override
  String get meshtasticNotConnected => 'Not connected to a radio';

  @override
  String get weatherModeSnow => 'Tuyết rơi';

  @override
  String get mapLayerMeshtastic => 'Meshtastic nodes';

  @override
  String get moreDeveloper => 'Thông tin gỡ lỗi';

  @override
  String get mapLayerSatelliteB14 => 'Himawari Longwave Infrared (B14)';

  @override
  String get meshtasticChannelUse => 'Channel use';

  @override
  String get mapNavLightning => 'Sét';

  @override
  String get homeForecastEmpty => 'Không có dữ liệu dự báo';

  @override
  String get sponsorOneTime => 'Ủng hộ một lần';

  @override
  String get mapLayerSatelliteBtdSplit => 'Himawari Split Window';

  @override
  String get onboardingPermBackground => 'Vị trí chạy nền';

  @override
  String get aedEmergencyPhone => 'Điện thoại khẩn cấp';

  @override
  String get dpmOpenInMaps => 'Mở trong bản đồ';

  @override
  String get meshtasticNotifyNodes => 'Notify on new nodes';

  @override
  String get onboardingPermCriticalDesc =>
      'Cho phép các cảnh báo động đất nguy hiểm đến tính mạng phát âm thanh ngay cả khi ở chế độ im lặng hoặc Không làm phiền.';

  @override
  String get mapLayerSatelliteTransparentWarm =>
      'Clear sky (warm end) = transparent, the basemap shows';

  @override
  String get meshtasticSent => 'Sent';

  @override
  String get homeForecastTitle => 'Dự báo 24 giờ';

  @override
  String get typhoonLegendWarningAreas => 'Vùng cảnh báo';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return '$count hidden';
  }

  @override
  String get notifyOptLocalIntensity1 => 'Cường độ tại chỗ từ 1 trở lên';

  @override
  String get mapTimelinePast => 'Quá khứ';

  @override
  String get restroomTypeFemale => 'Nhà vệ sinh nữ';

  @override
  String get reportListToday => 'Hôm nay';

  @override
  String get meshtasticTapNode => 'Tap a node for details';

  @override
  String get commonLoading => 'Đang tải…';

  @override
  String get typhoonIntensityModerate => 'Moderate typhoon';

  @override
  String get typhoonWind => 'Sức gió';

  @override
  String get mapLayerSatelliteAsh => 'Himawari Ash';

  @override
  String get rainInterval3h => '3 giờ';

  @override
  String get reportListSearch => 'Tìm';

  @override
  String get mapLayerCategorySatellite => 'Vệ tinh';

  @override
  String get meshtasticChannelReady => 'DPIP channel ready';

  @override
  String get reportFilterLocation => 'Địa điểm';

  @override
  String get mapLayerSatelliteNightmicrophysics =>
      'Himawari Night Microphysics';

  @override
  String get typhoonIntensityTd => 'Tropical depression';

  @override
  String get reportFilterDate => 'Ngày';

  @override
  String get sponsorRestoreUnavailable =>
      'Không thể kết nối tới cửa hàng. Vui lòng thử lại sau.';

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String get regionEmpty => 'Chưa có khu vực nào được lưu';

  @override
  String get onboardingPermBatteryDesc =>
      'Cho phép DPIP tiếp tục chạy ở chế độ nền để cảnh báo không bị trì hoãn hay bỏ lỡ.';

  @override
  String get mapNavDisaster => 'Phòng thảm';

  @override
  String get radarScanRangeSubtitle =>
      'Đánh dấu vùng bốn radar thực sự quan trắc.';

  @override
  String get aedHoursSunday => 'Giờ Chủ nhật';

  @override
  String get reportDetailOriginTime => 'Thời gian xảy ra';

  @override
  String get trendNoData => 'Không có dữ liệu xu hướng';

  @override
  String get onboardingPermLocation => 'Vị trí';

  @override
  String get moreDiscord => 'Cộng đồng Discord';

  @override
  String get mapNavPressure => 'Khí áp';

  @override
  String get mapLayerSatelliteB13 => 'Himawari Infrared (B13)';

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

  @override
  String get changelogEmpty => 'Chưa có ghi chú phát hành';

  @override
  String get reportFilterDateStartNote => 'Ngày bắt đầu: từ 00:00（Đài Bắc）';

  @override
  String get eewTitle => 'Cảnh báo sớm động đất';

  @override
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String regionSelectCount(int count, int max) {
    return 'Đã chọn $count/$max';
  }

  @override
  String get mapLayerSatelliteBtdSo2 => 'Himawari SO₂ / Cloud Phase';

  @override
  String get meshtasticStateError => 'Error';

  @override
  String get weatherModeOvercast => 'Trời âm u';

  @override
  String get reportDetailDepth => 'Độ sâu chấn tiêu';

  @override
  String get typhoonOverlayWarningTooltip =>
      'Highlight counties under a typhoon warning';

  @override
  String get reportFilterDatePick => 'Chọn ngày';

  @override
  String get onboardingSkipStay => 'Quay lại';

  @override
  String get commonFetchFailed => 'Không thể tải dữ liệu. Vui lòng thử lại.';

  @override
  String get shelterOutdoorLabel => 'Trú ẩn ngoài trời';

  @override
  String get meshtasticStateConnected => 'Connected';

  @override
  String get mapNavRadar => 'Radar';

  @override
  String get mapLayerSatelliteCloudClear => 'Clear';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'M$magnitude · độ sâu $depth km';
  }

  @override
  String get locationBannerPermission =>
      'Chưa cấp quyền vị trí — cảnh báo khu vực không thể nhắm đúng vùng của bạn.';

  @override
  String get typhoonOverlayWeatherNoneTooltip =>
      'No radar or infrared underlay';

  @override
  String get radarCountyOutlineHint => 'Vẽ đè lên tiếng vọng';

  @override
  String get windForecastCountyOutlineHint => 'Vẽ trên trường gió';

  @override
  String get homeRainTrendTitle => 'Mưa 1 giờ tới';

  @override
  String get moonPhaseFirstQuarter => 'First quarter';

  @override
  String get mapLayerCategoryTyphoon => 'Bão';

  @override
  String get meshtasticUtilization => 'Airtime (24h)';

  @override
  String get restroomTypeMixed => 'Nhà vệ sinh chung';

  @override
  String get restroomGradeGood => 'Tốt';

  @override
  String get notifyTsunami => 'Thông tin sóng thần';

  @override
  String get navData => 'Dữ liệu';

  @override
  String get mapLayerSatelliteBtdWvirw => 'Himawari Overshooting Top';

  @override
  String get meshtasticReadingAge => 'Reading taken';

  @override
  String get mapAppCallFailed => 'Thiết bị này không thể thực hiện cuộc gọi';

  @override
  String get reportFilterAny => 'Tất cả';

  @override
  String get weatherRankingMergeTo => 'Gộp';

  @override
  String get notifyIntensity => 'Báo cáo cường độ chấn động';

  @override
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get rainIntervalMenu => 'Khung tích lũy';

  @override
  String get reportDetailLocalFelt => 'Động đất cảm nhận cục bộ';

  @override
  String get meshtasticDevice => 'Device';

  @override
  String get onboardingGrant => 'Cấp quyền';

  @override
  String get weatherModeRain => 'Mưa';

  @override
  String get shelterVulnerableOkLabel => 'Phù hợp người yếu thế';

  @override
  String get stationSheetEmpty => 'Chạm vào một trạm để xem số liệu';

  @override
  String get typhoonLegendProbability => 'Xác suất đổ bộ';

  @override
  String get reportFilterMagnitude => 'Độ lớn';

  @override
  String get skyTimeMorning => 'Buổi sáng';

  @override
  String get experimentalFeatures => 'Tính năng thử nghiệm';

  @override
  String get onboardingTermsBody =>
      'Vui lòng đọc kỹ các lưu ý sau đây trước khi sử dụng DPIP:\n\n• Mọi thông tin phải căn cứ theo nội dung do Cục Khí tượng Trung ương Đài Loan (CWA) công bố.\n\n• Tùy thuộc vào tình trạng mạng, máy chủ, ứng dụng và nguồn dữ liệu đầu nguồn, có khả năng không nhận được thông tin; chúng tôi nỗ lực hết sức để tránh điều này nhưng không thể bảo đảm rằng nó không bao giờ xảy ra.\n\n• Rung lắc mạnh có thể lan đến vị trí của bạn trước khi thông báo được gửi tới.\n\n• Cảnh báo sớm động đất là kết quả được tính toán nhanh nên có thể chứa sai số đáng kể — hãy hiểu rõ điều này và sử dụng một cách thận trọng.\n\n• Bất kỳ hành vi nào không được cơ quan chức năng cho phép đều có thể mang rủi ro pháp lý; vui lòng tuân thủ mọi quy định hiện hành.\n\nNgoài ra, để cung cấp cảnh báo theo khu vực, dịch vụ này thu thập và tải lên vị trí gần đúng cùng mã định danh thông báo đẩy của bạn — cả ở nền trước lẫn nền sau — chỉ nhằm quyết định những cảnh báo nào sẽ gửi cho bạn.\n\nBằng việc nhấn \"Đồng ý và tiếp tục\", bạn xác nhận rằng đã đọc, hiểu và đồng ý với những điều trên.';

  @override
  String get reportFilterTitle => 'Bộ lọc';

  @override
  String get onboardingPermCritical => 'Cảnh báo quan trọng';

  @override
  String trendCumulativeTotal(String total) {
    return 'Tổng cộng $total mm';
  }

  @override
  String get languageName => 'Tiếng Việt';

  @override
  String get reportListEmptyFiltered => 'Không có báo cáo khớp bộ lọc';

  @override
  String get meshtasticExcludeMqtt => 'Hide MQTT nodes';

  @override
  String get mapNavTyphoon => 'Bão';

  @override
  String get weatherModeSand => 'Bụi cát';

  @override
  String get typhoonSatelliteTitle => 'Vệ tinh';

  @override
  String get notifyReport => 'Báo cáo động đất';

  @override
  String get mapAppCoordinatesCopied => 'Đã sao chép tọa độ';

  @override
  String get skyTimeNight => 'Ban đêm';

  @override
  String get sponsorRecommended => 'Đề xuất';

  @override
  String get mapLayerSatelliteB15 => 'Himawari Longwave Infrared (B15)';

  @override
  String get weatherRankingWind => 'Tốc độ gió';

  @override
  String get feedStale => 'Dữ liệu có thể đã lỗi thời';

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · Cấp $level';
  }

  @override
  String get navHome => 'Trang chủ';

  @override
  String get meshtasticRegionLabel => 'Region';

  @override
  String get mapLayerSatelliteCloudtop => 'Himawari Cloud Top Temperature';

  @override
  String get moonTimelineCaption => 'Phase';

  @override
  String reportListMeta(String magnitude, String depth) {
    return 'M$magnitude · $depth km';
  }

  @override
  String get openSourceLicenses => 'Giấy phép mã nguồn mở';

  @override
  String get weatherRankingLowest => 'Thấp nhất';

  @override
  String get reportFilterSortDepth => 'Độ sâu';

  @override
  String mapTimelineDataTime(String time) {
    return 'Thời gian dữ liệu $time';
  }

  @override
  String get radarScanRange => 'Hiện phạm vi quét';

  @override
  String get meshtasticHopLimit => 'Hop limit';

  @override
  String weatherRankingAnalysisRange(String value) {
    return 'Biên độ $value°C';
  }

  @override
  String get weatherRankingExtremeHigh => 'Cao nhất ngày';

  @override
  String get changelogVersionDetails => 'Chi tiết phiên bản';

  @override
  String get sponsorPrivacy => 'Chính sách quyền riêng tư';

  @override
  String get reportDetailLocalIntensity => 'Cường độ tại vị trí của bạn';

  @override
  String get mapLayerSatelliteNaturalcolor => 'Himawari Natural Color';

  @override
  String get meshtasticAirtime => 'Air time (TX)';

  @override
  String shelterCapacityValue(int n) {
    return '$n người';
  }

  @override
  String lightningLegendCc(int minutes) {
    return 'Mây–mây · $minutes phút';
  }

  @override
  String get meshtasticSendHint => 'Message to broadcast';

  @override
  String monitorDelay(String value) {
    return 'Độ trễ $value s';
  }

  @override
  String get dpmNo => 'Không';

  @override
  String get mapLayerSatelliteB08 => 'Himawari Upper Water Vapour (B08)';

  @override
  String get meshtasticReconnecting => 'Reconnecting…';

  @override
  String get radarTownOutlineSubtitle =>
      'Giữ ranh giới xã phường rõ ràng dưới lớp phản hồi radar.';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip =>
      'Infrared closest to the typhoon bulletin time';

  @override
  String get radarScanRangeHint => 'Ngoài khung là chưa quan trắc';

  @override
  String typhoonPickerTd(String no) {
    return 'Tropical depression TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => 'Himawari Water Vapour';

  @override
  String get regionAddButton => 'Thêm khu vực';

  @override
  String get displaySettings => 'Hiển thị';

  @override
  String get restroomGradePoor => 'Dưới chuẩn';

  @override
  String get restroomCategoryTourist => 'Khu du lịch thắng cảnh';

  @override
  String get locationBannerServiceOff =>
      'Dịch vụ vị trí đang tắt — cảnh báo khu vực không thể nhắm đúng vùng của bạn.';

  @override
  String get mapLayerStyleTooltip => 'Colour style';

  @override
  String lightningLegendCg(int minutes) {
    return 'Mây–đất · $minutes phút';
  }

  @override
  String get skyTimeAuto => 'Tự động';

  @override
  String get appLogs => 'Nhật ký ứng dụng';

  @override
  String get feedConnecting => 'Đang kết nối…';

  @override
  String get notifyBannerDisabled =>
      'Thông báo đã tắt — bạn sẽ không nhận được cảnh báo thiên tai.';

  @override
  String get weatherHumidity => 'Độ ẩm';

  @override
  String typhoonValueMs(String n) {
    return '$n m/s';
  }

  @override
  String homeForecastHumidity(String value) {
    return 'Độ ẩm $value%';
  }

  @override
  String get meshtasticBusyBody =>
      'Disconnect it in the other Meshtastic app first. Two apps on one radio take each other\'s messages, so some will go missing.';

  @override
  String get meshtasticChannelNoSlot =>
      'No free channel slot — free one on the radio';

  @override
  String get restroomCategoryTransport => 'Giao thông';

  @override
  String get reportFilterLocationHint => 'vd: Hoa Liên, ngoài khơi';

  @override
  String get moonSubtitle => 'Lunar phase and illumination — computed locally';

  @override
  String get meshtasticBattery => 'Battery';

  @override
  String get meshtasticDistance => 'Khoảng cách';

  @override
  String get meshtasticSnrTrend => 'Xu hướng tín hiệu (SNR)';

  @override
  String get meshtasticBatteryTrend => 'Xu hướng pin';

  @override
  String get typhoonOverlayMenuTooltip => 'Typhoon overlay options';

  @override
  String get mapLayerSatelliteBtdOzone => 'Himawari Tropopause';

  @override
  String meshtasticRegionMismatch(String region) {
    return 'Radio region is $region — DPIP needs TW';
  }

  @override
  String get notifySectionEarthquake => 'Động đất';

  @override
  String get mapLayerDisasterMap => 'Bản đồ phòng chống';

  @override
  String get weatherModeFog => 'Sương mù';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String get mapLayerStyleGrayTooltip => 'JMA grayscale — colder is whiter';

  @override
  String get moreAnnouncements => 'Thông báo';

  @override
  String get mapLayerSatelliteTransparentNoData =>
      'No data (land) = transparent';

  @override
  String get restroomCategoryGovernment => 'Cơ quan công quyền';

  @override
  String get typhoonLegendCurrent => 'Tâm hiện tại';

  @override
  String get aedAddress => 'Địa chỉ';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get changelogTypePrerelease => 'Thử nghiệm';

  @override
  String get reportFilterIntensityInfoModernBody =>
      'Các mức 0–4, 5−, 5+, 6−, 6+, 7. Thanh lọc dùng thang mới; sự kiện cũ vẫn hiện nhãn cũ trong danh sách.';

  @override
  String get typhoonOverlayWeatherNone => 'None';

  @override
  String get mapLayerStyleGray => 'Grayscale (JMA)';

  @override
  String get weatherModeAuto => 'Tự động';

  @override
  String get typhoonLabelProbCircle => '70% probability circle';

  @override
  String get notifyOptAll => 'Nhận tất cả';

  @override
  String get displayTheme => 'Giao diện';

  @override
  String get mapLayerSatelliteB07 => 'Himawari Shortwave Infrared (B07)';

  @override
  String get typhoonLabelDirection => 'Past movement direction';

  @override
  String get regionManageTitle => 'Khu vực đã lưu';

  @override
  String get typhoonLegendCone => 'Nón dự báo';

  @override
  String get moreCwaEew => 'Cảnh báo sớm động đất của CWA';

  @override
  String get onboardingPermsTitle => 'Quyền truy cập';

  @override
  String get mapLayerStyleJma => 'Cloud-top enhancement (JMA)';

  @override
  String get rainInterval10m => '10 phút';

  @override
  String weatherRankingAnalysisLow(String value) {
    return 'Thấp $value';
  }

  @override
  String get meshtasticConnectAnyway => 'Connect anyway';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get mapLayerSatelliteB06 => 'Himawari Near-Infrared (B06)';

  @override
  String get mapLayerSatelliteTransparentReflectance =>
      'Low reflectance / night = transparent, the basemap shows';

  @override
  String chartHourLabel(int hour) {
    return '${hour}h';
  }

  @override
  String get mapLayerShelter => 'Nơi trú ẩn';

  @override
  String get typhoonOverlayProbabilityTooltip =>
      'Show strike probability (hides the forecast cone)';

  @override
  String get mapLayerSatelliteNdwi => 'Himawari NDWI';

  @override
  String get disasterMapOverlayShelterTooltip => 'Hiển thị nơi trú ẩn';

  @override
  String get mapNavHumidity => 'Độ ẩm';

  @override
  String get reportDetailSortByIntensity => 'Sắp xếp theo cường độ';

  @override
  String get homeRainTrendNoData => 'Không có dữ liệu';

  @override
  String get mapLayerCategoryRadar => 'Ra đa';

  @override
  String get meshtasticShortName => 'Short name';

  @override
  String get mapLayerSatelliteAirmass => 'Himawari Airmass';

  @override
  String get typhoonTrackDetail => 'Chi tiết quỹ đạo';

  @override
  String get dataSectionWeather => 'Thời tiết';

  @override
  String get aedHoursWeekday => 'Giờ ngày thường';

  @override
  String get homeActiveEventsTitle => 'Sự kiện đang hiệu lực';

  @override
  String weatherRankingAnalysisHigh(String value) {
    return 'Cao $value';
  }

  @override
  String get faq => 'Câu hỏi thường gặp';

  @override
  String get typhoonHistoryLive => 'Trực tiếp';

  @override
  String eewSerial(int serial) {
    return 'Bản tin $serial';
  }

  @override
  String get reportFilterSort => 'Sắp xếp';

  @override
  String get meshtasticRegionConfirm =>
      'Switch this radio to the TW region? It restarts and disconnects for a moment, and every other channel on it moves too.';

  @override
  String get dataEarthquakeSubtitle => 'Báo cáo động đất';

  @override
  String get typhoonNoActive => 'Không có bão';

  @override
  String get mapLayerSatelliteB11 => 'Himawari SO₂ / Cloud Phase (B11)';

  @override
  String get navEvents => 'Sự kiện';

  @override
  String get onboardingTermsTitle => 'Điều khoản Dịch vụ';

  @override
  String get mapTownLabels => 'Tên hương trấn';

  @override
  String get notifySetFailed => 'Không thể lưu cài đặt. Vui lòng thử lại.';

  @override
  String get meshtasticDisconnect => 'Disconnect';

  @override
  String get meshtasticUndecoded => 'Not decrypted';

  @override
  String get notifyAnnouncement => 'Thông báo';

  @override
  String get onboardingIntroTitle => 'Chào mừng đến với DPIP';

  @override
  String get regionCurrentUnavailable => 'Không thể lấy vị trí hiện tại';

  @override
  String get languageSystem => 'Mặc định hệ thống';

  @override
  String get skyTimeSunset => 'Hoàng hôn';

  @override
  String get mapLayerSatelliteDust => 'Himawari Dust';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String get regionEdit => 'Sửa';

  @override
  String get weatherDynamicState => 'Hoạt ảnh thời tiết';

  @override
  String get mapPlaceholderDisabled => 'Bản đồ (tạm thời vô hiệu hóa)';

  @override
  String get moonNow => 'Bây giờ';

  @override
  String get moonSectionAppearance => 'Diện mạo';

  @override
  String get moonSectionRiseSet => 'Mọc và lặn';

  @override
  String get moonSectionUpcoming => 'Sắp tới';

  @override
  String get moonSectionCalendar => 'Lịch';

  @override
  String get moonDistance => 'Khoảng cách';

  @override
  String get moonKilometres => 'km';

  @override
  String get moonApparentSize => 'Đường kính biểu kiến';

  @override
  String get moonRise => 'Trăng mọc';

  @override
  String get moonSet => 'Trăng lặn';

  @override
  String get moonNextNewMoon => 'Trăng non tiếp theo';

  @override
  String get moonAlwaysUp => 'Trên chân trời cả ngày';

  @override
  String get moonNoEvent => 'Không có hôm nay';

  @override
  String get sunTitle => 'Mặt Trời';

  @override
  String get sunSubtitle => 'Bình minh, hoàng hôn và tiết khí';

  @override
  String get sunSectionDaylight => 'Ánh sáng ban ngày';

  @override
  String get sunSectionTwilight => 'Hoàng hôn';

  @override
  String get sunSectionLight => 'Ánh sáng';

  @override
  String get sunSectionSundial => 'Đồng hồ mặt trời';

  @override
  String get sunSectionTerms => 'Tiết khí';

  @override
  String get sunRise => 'Mặt Trời mọc';

  @override
  String get sunSet => 'Mặt Trời lặn';

  @override
  String get sunNoon => 'Chính ngọ';

  @override
  String get sunDayLength => 'Độ dài ngày';

  @override
  String get sunTwilightCivil => 'Dân dụng';

  @override
  String get sunTwilightNautical => 'Hàng hải';

  @override
  String get sunTwilightAstronomical => 'Thiên văn';

  @override
  String get sunGoldenHourMorning => 'Giờ vàng buổi sáng';

  @override
  String get sunGoldenHourEvening => 'Giờ vàng buổi chiều';

  @override
  String get sunBlueHour => 'Giờ xanh';

  @override
  String get sunEquationOfTime => 'Phương trình thời gian';

  @override
  String get sunMinutes => 'phút';

  @override
  String get solarTermNext => 'Tiết khí tiếp theo';

  @override
  String get planetsTitle => 'Hành tinh';

  @override
  String get planetsSubtitle => 'Đêm nay ở đâu, sáng bao nhiêu';

  @override
  String get planetsSectionTonight => 'Hiện tại';

  @override
  String get planetUp => 'Trên chân trời';

  @override
  String get planetDown => 'Dưới chân trời';

  @override
  String get planetInGlare => 'Quá gần Mặt Trời';

  @override
  String get planetMagnitude => 'Cấp sao';

  @override
  String get planetElongation => 'Ly giác';

  @override
  String get planetSky => 'Thời điểm';

  @override
  String get planetEvening => 'Sao Hôm';

  @override
  String get planetMorning => 'Sao Mai';

  @override
  String get planetDistance => 'Khoảng cách';

  @override
  String get planetAu => 'au';

  @override
  String get planetAltitude => 'Độ cao';

  @override
  String get planetMercury => 'Sao Thủy';

  @override
  String get planetVenus => 'Sao Kim';

  @override
  String get planetMars => 'Sao Hỏa';

  @override
  String get planetJupiter => 'Sao Mộc';

  @override
  String get planetSaturn => 'Sao Thổ';

  @override
  String get planetUranus => 'Sao Thiên Vương';

  @override
  String get planetNeptune => 'Sao Hải Vương';

  @override
  String get solarTermVernalEquinox => 'Xuân phân';

  @override
  String get solarTermPureBrightness => 'Thanh minh';

  @override
  String get solarTermGrainRain => 'Cốc vũ';

  @override
  String get solarTermStartOfSummer => 'Lập hạ';

  @override
  String get solarTermGrainFull => 'Tiểu mãn';

  @override
  String get solarTermGrainInEar => 'Mang chủng';

  @override
  String get solarTermSummerSolstice => 'Hạ chí';

  @override
  String get solarTermMinorHeat => 'Tiểu thử';

  @override
  String get solarTermMajorHeat => 'Đại thử';

  @override
  String get solarTermStartOfAutumn => 'Lập thu';

  @override
  String get solarTermEndOfHeat => 'Xử thử';

  @override
  String get solarTermWhiteDew => 'Bạch lộ';

  @override
  String get solarTermAutumnalEquinox => 'Thu phân';

  @override
  String get solarTermColdDew => 'Hàn lộ';

  @override
  String get solarTermFrostDescent => 'Sương giáng';

  @override
  String get solarTermStartOfWinter => 'Lập đông';

  @override
  String get solarTermMinorSnow => 'Tiểu tuyết';

  @override
  String get solarTermMajorSnow => 'Đại tuyết';

  @override
  String get solarTermWinterSolstice => 'Đông chí';

  @override
  String get solarTermMinorCold => 'Tiểu hàn';

  @override
  String get solarTermMajorCold => 'Đại hàn';

  @override
  String get solarTermStartOfSpring => 'Lập xuân';

  @override
  String get solarTermRainWater => 'Vũ thủy';

  @override
  String get solarTermAwakeningOfInsects => 'Kinh trập';

  @override
  String get tonightTitle => 'Đêm nay';

  @override
  String get tonightSubtitle => 'Có thể quan sát gì, và khi nào';

  @override
  String get tonightSectionDark => 'Cửa sổ quan sát';

  @override
  String get tonightAstronomicalNight => 'Đêm thiên văn';

  @override
  String get tonightNeverDark => 'Không bao giờ tối hẳn';

  @override
  String get tonightDarkWindow => 'Cửa sổ tối';

  @override
  String get tonightMoonAllNight => 'Trăng lên suốt đêm';

  @override
  String get tonightDarkTotal => 'Tổng thời gian tối';

  @override
  String get tonightMoonlight => 'Ánh trăng';

  @override
  String get tonightSectionShowers => 'Mưa sao băng';

  @override
  String get tonightRadiantDown => 'Tâm điểm không mọc';

  @override
  String get tonightPerHour => 'sao/giờ';

  @override
  String get tonightSectionSatellites => 'Vệ tinh bay qua';

  @override
  String get tonightSectionTargets => 'Mục tiêu đang lên';

  @override
  String get showerQuadrantids => 'Quadrantids';

  @override
  String get showerLyrids => 'Lyrids';

  @override
  String get showerEtaAquariids => 'Eta Aquariids';

  @override
  String get showerDeltaAquariids => 'Delta Aquariids';

  @override
  String get showerPerseids => 'Perseids';

  @override
  String get showerOrionids => 'Orionids';

  @override
  String get showerSouthernTaurids => 'Nam Taurids';

  @override
  String get showerLeonids => 'Leonids';

  @override
  String get showerGeminids => 'Geminids';

  @override
  String get showerUrsids => 'Ursids';

  @override
  String get deepSkyOpenCluster => 'Cụm sao mở';

  @override
  String get deepSkyGlobularCluster => 'Cụm sao cầu';

  @override
  String get deepSkySpiralGalaxy => 'Thiên hà xoắn ốc';

  @override
  String get deepSkyEllipticalGalaxy => 'Thiên hà elip';

  @override
  String get deepSkyIrregularGalaxy => 'Thiên hà vô định hình';

  @override
  String get deepSkyPlanetaryNebula => 'Tinh vân hành tinh';

  @override
  String get deepSkySupernovaRemnant => 'Tàn dư siêu tân tinh';

  @override
  String get deepSkyEmissionNebula => 'Tinh vân phát xạ';

  @override
  String get deepSkyReflectionNebula => 'Tinh vân phản xạ';

  @override
  String get deepSkyAsterism => 'Chòm sao nhỏ';

  @override
  String get almanacTitle => 'Lịch pháp';

  @override
  String get almanacSubtitle =>
      'Ngày âm lịch và nhật thực, nguyệt thực sắp tới';

  @override
  String get almanacSectionToday => 'Hôm nay';

  @override
  String get almanacGregorian => 'Dương lịch';

  @override
  String get almanacLunar => 'Âm lịch';

  @override
  String get almanacYear => 'Can chi';

  @override
  String get almanacMonthLength => 'Độ dài tháng';

  @override
  String get almanacLongMonth => '30 ngày';

  @override
  String get almanacShortMonth => '29 ngày';

  @override
  String get almanacLeapPrefix => 'Nhuận ';

  @override
  String get almanacSectionLunarEclipses => 'Nguyệt thực';

  @override
  String get almanacSectionSolarEclipses => 'Nhật thực';

  @override
  String get almanacNoSolarEclipse => 'Không có trong phạm vi';

  @override
  String get eclipseTotal => 'Toàn phần';

  @override
  String get eclipsePartial => 'Một phần';

  @override
  String get eclipseAnnular => 'Hình khuyên';

  @override
  String get eclipsePenumbral => 'Nửa tối';

  @override
  String get zodiacRat => 'Tý';

  @override
  String get zodiacOx => 'Sửu';

  @override
  String get zodiacTiger => 'Dần';

  @override
  String get zodiacRabbit => 'Mão';

  @override
  String get zodiacDragon => 'Thìn';

  @override
  String get zodiacSnake => 'Tỵ';

  @override
  String get zodiacHorse => 'Ngọ';

  @override
  String get zodiacGoat => 'Mùi';

  @override
  String get zodiacMonkey => 'Thân';

  @override
  String get zodiacRooster => 'Dậu';

  @override
  String get zodiacDog => 'Tuất';

  @override
  String get zodiacPig => 'Hợi';

  @override
  String get tideTitle => 'Thủy triều';

  @override
  String get tideSubtitle => 'Triều cường, triều kém và lực hút của Mặt Trăng';

  @override
  String get tideDisclaimer =>
      'Chỉ là lực triều thiên văn, không phải bảng thủy triều cảng. Mực nước xin xem bảng do CWA công bố.';

  @override
  String get tideSectionNow => 'Hiện tại';

  @override
  String get tidePhase => 'Chu kỳ';

  @override
  String get tideSpring => 'Triều cường';

  @override
  String get tideNeap => 'Triều kém';

  @override
  String get tideMiddling => 'Trung bình';

  @override
  String get tideLunarDistanceFactor => 'Lực hút Mặt Trăng';

  @override
  String get tideEquilibrium => 'Triều cân bằng';

  @override
  String get tideMetres => 'm';

  @override
  String get tidePerigeanSpring => 'Triều cường cận điểm tới';

  @override
  String get tideSectionTurningPoints => 'Điểm ngoặt';

  @override
  String get tideHigh => 'Cao';

  @override
  String get tideLow => 'Thấp';

  @override
  String get skyChartTitle => 'Bản đồ sao';

  @override
  String get skyChartSubtitle => 'Bầu trời nhìn bằng mắt thường';

  @override
  String get skyChartNorth => 'B';

  @override
  String get skyChartEast => 'Đ';

  @override
  String get skyChartSouth => 'N';

  @override
  String get skyChartWest => 'T';

  @override
  String tonightElementAge(int days) {
    return 'dữ liệu quỹ đạo $days ngày trước';
  }

  @override
  String almanacLunarDate(String leap, int month, int day) {
    return '${leap}tháng $month ngày $day';
  }

  @override
  String get tonightNoShowers => 'Không có mưa sao băng';

  @override
  String get tonightNoPasses => 'Không có lượt bay qua nhìn thấy trong 48 giờ';

  @override
  String get tonightSatellitesUnavailable => 'Không đọc được dữ liệu quỹ đạo';

  @override
  String get tonightNoTargets => 'Không có mục tiêu đủ cao';

  @override
  String get skyChartUnavailable => 'Không đọc được danh mục sao';

  @override
  String get permissionSettingsTitle => 'Hãy cấp quyền trong Cài đặt';

  @override
  String get permissionSettingsHint =>
      'Ứng dụng sẽ kiểm tra lại khi bạn quay lại.';

  @override
  String get permissionOpenSettings => 'Mở Cài đặt';

  @override
  String permissionSettingsMessage(String what) {
    return '“$what” đã bị từ chối và hệ thống sẽ không hỏi lại. Hãy bật trong Cài đặt.';
  }
}
