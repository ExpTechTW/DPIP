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
  String get mapTimelineScrubPaused =>
      'Bạn kéo quá nhanh nên khung hình đã tạm dừng cập nhật. Kéo chậm lại để tiếp tục.';

  @override
  String get regionSelectTitle => 'Chọn khu vực';

  @override
  String get skyTimeNoon => 'Buổi trưa';

  @override
  String get radarCountyOutlineSubtitle =>
      'Giữ ranh giới rõ ràng dưới lớp phản hồi radar.';

  @override
  String get mapLayerSatelliteB03 => 'Himawari Red (B03)';

  @override
  String get reportFilterIntensity => 'Cường độ';

  @override
  String get mapLayerLightning => 'Sét';

  @override
  String get restroomTypeMale => 'Nhà vệ sinh nam';

  @override
  String get meshtasticLastReceived => 'Nhận lần cuối';

  @override
  String get reportDetailSortByCounty => 'Sắp xếp theo khu vực';

  @override
  String get onboardingPermUnusedApp => 'Giữ ứng dụng hoạt động';

  @override
  String get onboardingPermUnusedAppDesc =>
      'Android tạm dừng các ứng dụng bạn lâu không mở và thu hồi quyền của chúng, khiến cảnh báo thảm họa không đến được khu vực của bạn.';

  @override
  String get onboardingPermBackgroundExec => 'Hoạt động nền';

  @override
  String get onboardingPermBackgroundExecDesc =>
      'Nếu tắt, ứng dụng sẽ không được đánh thức để báo vị trí của bạn.';

  @override
  String get onboardingPermVendorPower => 'Cài đặt pin của nhà sản xuất';

  @override
  String onboardingPermVendorPowerDesc(String brand) {
    return '$brand dừng hoạt động nền của các ứng dụng bạn chưa mở gần đây. Ứng dụng không thể phát hiện hay thay đổi điều này — vui lòng cho phép thủ công.';
  }

  @override
  String get homeRainTrendScattered => 'Có thể có mưa rào nhẹ';

  @override
  String get meshtasticUptime => 'Thời gian hoạt động';

  @override
  String get weatherRankingTempExtremes => 'Cực trị nhiệt độ';

  @override
  String get themeLight => 'Sáng';

  @override
  String get mapTerrainReliefHint => 'Hiển thị địa hình nổi trên bản đồ nền';

  @override
  String get meshtasticEmptyMessage => '(tin nhắn trống)';

  @override
  String get moreSectionRegion => 'Khu vực';

  @override
  String get mapLayerSatellite => 'Himawari Infrared (B13)';

  @override
  String get aedHoursSaturday => 'Giờ thứ Bảy';

  @override
  String get moonPhaseNew => 'Trăng mới';

  @override
  String get notifySectionEew => 'Cảnh báo sớm động đất';

  @override
  String get mapResetNorth => 'Về hướng bắc';

  @override
  String get rainInterval2d => '2 ngày';

  @override
  String get mapTownLabelsHint => 'Hiển thị tên hương trấn khi phóng to';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get notifyOptTsunamiWarning => 'Chỉ cảnh báo sóng thần';

  @override
  String get mapLayerSatelliteBtdFog => 'Himawari Night Fog';

  @override
  String get moreSectionAdvanced => 'Nâng cao';

  @override
  String get moreSectionMesh => 'Mạng lưới Mesh';

  @override
  String get weatherRankingExtremeRange => 'Biên độ ngày';

  @override
  String get permissionsTitle => 'Kiểm tra quyền';

  @override
  String get permissionsAttention => 'Cần xử lý quyền truy cập';

  @override
  String get permissionsBody =>
      'DPIP cần các quyền này để cảnh báo bạn kịp thời. Không nhận được cảnh báo thường là do thiếu một trong số đó.';

  @override
  String get notifySettingsMenu => 'Cài đặt thông báo';

  @override
  String mapAppDefault(String app) {
    return '$app (mặc định)';
  }

  @override
  String get trendRange24h => '24 giờ';

  @override
  String get mapLayerStyleJmaTooltip =>
      'Nền grayscale, tô màu dưới −40 °C để làm nổi bật độ cao đỉnh mây';

  @override
  String get mapLayerRain => 'Lượng mưa';

  @override
  String get mapLayerQpesums => 'Dự báo mưa 1 giờ tới';

  @override
  String get mapOverlaySectionMap => 'Bản đồ';

  @override
  String get mapTerrainRelief => 'Độ nổi địa hình';

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
  String get changelogShowSnapshots => 'Hiện bản thử nghiệm';

  @override
  String get changelogTitle => 'Nhật ký cập nhật';

  @override
  String get reportFilterOrderDesc => 'Giảm dần';

  @override
  String get meshtasticExcludeMqttSubtitle =>
      'Các nút kết nối qua Internet, không nghe qua sóng radio';

  @override
  String get reportFilterIntensityInfoTitle => 'Thang cường độ mới và cũ';

  @override
  String get mapLayerTyphoon => 'Bão';

  @override
  String get radarOverlayMenuTooltip => 'Tùy chọn lớp radar';

  @override
  String get meshtasticNodes => 'Nút';

  @override
  String get meshtasticSend => 'Gửi';

  @override
  String get typhoonOverlayStormL7Tooltip =>
      'Trường gió cấp 7 + bán kính trung bình (tím)';

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
  String get meshtasticFirmware => 'Phần mềm cơ sở';

  @override
  String get reportFilterDateEndNote => 'Ngày kết thúc: đến 24:00（Đài Bắc）';

  @override
  String get reportFilterSortMagnitude => 'Độ lớn';

  @override
  String get meshtasticSilent => 'Im lặng';

  @override
  String get mapLayerCategoryEarthquake => 'Động đất';

  @override
  String get mapLayerSatelliteB12 => 'Himawari Ozone (B12)';

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
  String get meshtasticLayerOptions => 'Tùy chọn nút';

  @override
  String get onboardingAgreeContinue => 'Đồng ý và tiếp tục';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get meshtasticNodeId => 'ID nút';

  @override
  String reportDetailNumbered(String number) {
    return 'Động đất có cảm nhận đáng kể số $number';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => 'Kèm bán kính trung bình';

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
  String get meshtasticChannelWorking => 'Đang thiết lập kênh DPIP…';

  @override
  String get meshtasticRegionSwitch => 'Chuyển sang vùng TW';

  @override
  String get meshtasticTraffic => 'Lưu lượng';

  @override
  String get mapLayerStyleBdTooltip =>
      'Dvorak BD curve — the stepped grayscale for tropical-cyclone intensity analysis';

  @override
  String get disasterMapOverlayAedTooltip => 'Hiện vị trí AED';

  @override
  String get mapLayerHumidity => 'Độ ẩm';

  @override
  String get mapLayerSatelliteTransparentNight =>
      'Ban đêm = trong suốt, thấy bản đồ nền';

  @override
  String get meshtasticScanning => 'Đang quét…';

  @override
  String regionSelectFull(int max) {
    return 'Bạn chỉ có thể lưu tối đa $max khu vực';
  }

  @override
  String get meshtasticNewMessages => 'MỚI';

  @override
  String get meshtasticBatteryHistory => 'Lịch sử pin';

  @override
  String get meshtasticStatAvg => 'TB';

  @override
  String get meshtasticStatPeak => 'đỉnh';

  @override
  String get meshtasticStatDrain => 'tiêu hao';

  @override
  String get meshtasticStatEta => 'còn dùng';

  @override
  String get meshtasticStatFull => 'đầy sau';

  @override
  String get meshtasticStatTrend => 'xu hướng';

  @override
  String get meshtasticStatCharging => 'đang sạc';

  @override
  String get meshtasticStatStable => 'ổn định';

  @override
  String get meshtasticNodesTotal => 'Đã biết';

  @override
  String get meshtasticNodesOnline => 'Trực tuyến';

  @override
  String get meshtasticRx => 'Nhận';

  @override
  String get meshtasticTx => 'Gửi';

  @override
  String get meshtasticNodesHistory => 'Lịch sử nút';

  @override
  String get meshtasticTrafficHistory => 'Lịch sử lưu lượng';

  @override
  String meshtasticEtaHours(int n) {
    return '~$n giờ';
  }

  @override
  String meshtasticEtaDays(int n) {
    return '~$n ngày';
  }

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => 'Thêm';

  @override
  String get meshtasticDpipChannel => 'Kênh DPIP';

  @override
  String get disasterMapOverlaySectionLayers => 'Lớp';

  @override
  String get mapLayerSatelliteB05 => 'Himawari Near-Infrared (B05)';

  @override
  String get typhoonLabelNe => 'NE';

  @override
  String get meshtasticCopied => 'Đã sao chép tin nhắn';

  @override
  String get reportListEmpty => 'Không có báo cáo động đất';

  @override
  String get reportListEnd => 'Hết danh sách';

  @override
  String get mapLayerSatelliteTruecolor => 'Himawari True Color';

  @override
  String get typhoonOverlaySectionExtra => 'Lớp phủ';

  @override
  String get eewSWave => 'Sóng S';

  @override
  String get meshtasticBusyTitle => 'Ứng dụng khác đang dùng radio này';

  @override
  String get restroomCategoryCultural => 'Địa điểm văn hóa giải trí';

  @override
  String get typhoonLabelWind => 'Gió duy trì tối đa gần tâm';

  @override
  String get radarGlobalOutlineHint => 'Khung ngoài của mỗi quốc gia';

  @override
  String get notifyEvacuation => 'Thông tin thảm họa';

  @override
  String get typhoonLegendCircle15 => 'Vòng gió mạnh';

  @override
  String get dataSectionAstronomy => 'Thiên văn';

  @override
  String get homeRainTrendLightSustained => 'Mưa nhỏ tiếp diễn trong 1 giờ tới';

  @override
  String get commonError => 'Đã xảy ra lỗi';

  @override
  String get moonPhaseWaningCrescent => 'Trăng lưỡi liềm khuyết';

  @override
  String get meshtasticPower => 'Nguồn';

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
  String get meshtasticTxPower => 'Công suất TX';

  @override
  String get restroomCategoryLabel => 'Hạng mục';

  @override
  String get sponsorRestoring => 'Đang khôi phục giao dịch…';

  @override
  String get sponsorIntro =>
      'DPIP cam kết cung cấp thông tin phòng chống thiên tai theo thời gian thực, không có quảng cáo hay mô hình lợi nhuận nào khác. Sự ủng hộ của bạn giúp chúng tôi duy trì máy chủ và tiếp tục phát triển.';

  @override
  String get typhoonLabelStormAvg => 'Bán kính trung bình gió Beaufort 10';

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
  String homeRainTrendMinute(int minute) {
    return '$minute phút';
  }

  @override
  String get rainInterval6h => '6 giờ';

  @override
  String get restroomTypeUnspecified => 'Không xác định';

  @override
  String get typhoonOverlayProbabilityHint => 'Ẩn vùng dự kiến';

  @override
  String get mapLayerSatelliteGlobalOutline => 'Đường biên giới';

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
      'Ảnh radar gần thời điểm bản tin bão nhất';

  @override
  String get onboardingPermLocationDesc =>
      'Gửi cảnh báo phù hợp với nơi bạn đang ở.';

  @override
  String get mapLayerSatelliteB16 => 'Himawari CO₂ (B16)';

  @override
  String get homeActiveEventsEmpty => 'Không có sự kiện đang hiệu lực';

  @override
  String get typhoonLabelPosition => 'Vị trí tâm';

  @override
  String get weatherRankingBy => 'Theo';

  @override
  String get typhoonIntensityMild => 'Bão yếu';

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
  String get meshtasticRole => 'Vai trò';

  @override
  String get mapLayerSatelliteCloudCloudy => 'Nhiều mây';

  @override
  String get skyTimeSunrise => 'Bình minh';

  @override
  String get meshtasticJumpToLatest => 'Tới mới nhất';

  @override
  String get meshtasticNoMessages => 'Chưa có tin nhắn';

  @override
  String get onboardingPermNotifyDesc =>
      'Gửi cảnh báo động đất, thời tiết và thảm họa ngay khi chúng xảy ra.';

  @override
  String get radarTownOutline => 'Ranh giới xã phường';

  @override
  String get mapLayerStyleSection => 'Kiểu màu';

  @override
  String get disasterMapOverlayMenuTooltip => 'Lớp bản đồ phòng chống';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get meshtasticOnline => 'Nghe thấy gần đây';

  @override
  String get typhoonLabelSw => 'SW';

  @override
  String typhoonForecastLead(String hours) {
    return 'Forecast +$hours h';
  }

  @override
  String get changelogTypeStable => 'Chính thức';

  @override
  String get mapLayerSatelliteTransparentClear =>
      'Trời quang = trong suốt, thấy bản đồ nền';

  @override
  String get mapOverlaySectionReference => 'Lớp tham chiếu';

  @override
  String get mapLayerSatelliteB02 => 'Himawari Green (B02)';

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
  String get meshtasticNoDevices => 'Không tìm thấy thiết bị Meshtastic';

  @override
  String get mapLayerCategoryLife => 'Đời sống';

  @override
  String get reportFilterSortIntensity => 'Cường độ';

  @override
  String get meshtasticStateDisconnected => 'Đã ngắt kết nối';

  @override
  String get typhoonIntensityIntense => 'Bão mạnh';

  @override
  String get mapLayerOrderTitle => 'Sắp xếp thứ tự lớp';

  @override
  String get mapLayerShow => 'Hiện lớp bản đồ';

  @override
  String get mapLayerHide => 'Ẩn lớp bản đồ';

  @override
  String get mapLayerShowAll => 'Hiện tất cả';

  @override
  String get mapLayerHideAll => 'Ẩn tất cả';

  @override
  String get dpmYes => 'Có';

  @override
  String get meshtasticNoHistory => 'Lịch sử chưa đủ';

  @override
  String get reportDetailLocalIntensityUnavailable =>
      'Không có dữ liệu cường độ';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportFilterDepth => 'Độ sâu';

  @override
  String get onboardingScrollHint => 'Cuộn xuống để tiếp tục';

  @override
  String get mapNavQpesums => 'Dự báo';

  @override
  String get notifyAdvisory => 'Tin cảnh báo thời tiết';

  @override
  String get reportFilterReset => 'Đặt lại';

  @override
  String get mapLayerSatelliteMndwi => 'Himawari MNDWI';

  @override
  String get typhoonOverlaySectionStorm => 'Gió bão';

  @override
  String get moonPhaseFull => 'Trăng tròn';

  @override
  String meshtasticBinaryPayload(String size) {
    return 'Dữ liệu nhị phân · $size';
  }

  @override
  String get moonPhaseWaningGibbous => 'Trăng khuyết lồi';

  @override
  String get reportFilterIntensityInfoModernTitle => 'Mới (từ 2020)';

  @override
  String typhoonDataTime(String time) {
    return 'Giờ dữ liệu\n$time';
  }

  @override
  String get restroomTypeAccessible => 'Nhà vệ sinh tiếp cận được';

  @override
  String get moreSectionAbout => 'Giới thiệu';

  @override
  String get meshtasticSelectDevice => 'Chọn radio';

  @override
  String get onboardingIntroBody =>
      'DPIP là người bạn đồng hành phòng chống thiên tai của bạn. Ứng dụng tích hợp cảnh báo sớm động đất, báo cáo động đất, thời tiết và thông tin về hiểm họa, đồng thời cảnh báo bạn ngay tại thời điểm quan trọng.\n\n• Động đất: cảnh báo sớm, báo cáo cường độ và báo cáo chi tiết\n• Thời tiết: tin nhắn mưa dông theo thời gian thực và cảnh báo thời tiết\n• Thông tin sóng thần và thảm họa\n\nTiếp theo, chúng tôi sẽ mời bạn xem lại Điều khoản Dịch vụ và cấp một vài quyền để DPIP có thể bảo vệ bạn theo thời gian thực.';

  @override
  String get shelterCapacityLabel => 'Sức chứa';

  @override
  String get reportDetailImage => 'Hình ảnh báo cáo';

  @override
  String get meshtasticStateConfiguring => 'Đang cấu hình…';

  @override
  String get typhoonLabelGaleAvg => 'Bán kính trung bình gió Beaufort 7';

  @override
  String get onboardingPermNotify => 'Thông báo';

  @override
  String get meshtasticClearMessages => 'Xóa tin nhắn';

  @override
  String get meshtasticNotifyMessages => 'Thông báo tin nhắn mới';

  @override
  String get defaultMapLayerSettings => 'Lớp bản đồ mặc định';

  @override
  String get eewSourceSettings => 'Nguồn cảnh báo sớm động đất';

  @override
  String get eewSourceSubtitle =>
      'Chọn cơ quan phát hành cảnh báo sớm động đất muốn hiển thị.';

  @override
  String get eewSourceAll => 'Tất cả nguồn';

  @override
  String get eewSourceAllDescription =>
      'Hiển thị cảnh báo sớm động đất từ mọi cơ quan phát hành.';

  @override
  String get eewSourceCwaOnly => 'Chỉ CWA';

  @override
  String get eewSourceCwaOnlyDescription =>
      'Chỉ hiển thị cảnh báo sớm động đất do Cục Khí tượng Trung ương Đài Loan (CWA) phát hành.';

  @override
  String get moreSectionNotify => 'Thông báo';

  @override
  String get notifyUnavailable =>
      'Thông báo đẩy chưa sẵn sàng — vui lòng thử lại sau giây lát.';

  @override
  String get mapLayerOrderReset => 'Đặt lại thứ tự mặc định';

  @override
  String get weatherRankingMergeCounty => 'Huyện/thành';

  @override
  String get moreSectionApp => 'Tải ứng dụng';

  @override
  String get moreSectionBeta => 'Bản thử nghiệm';

  @override
  String get moreAndroidBeta => 'Bản thử nghiệm Android';

  @override
  String get moreTestFlight => 'Bản thử nghiệm iOS (TestFlight)';

  @override
  String get moreSectionPartners => 'Đối tác';

  @override
  String get morePartnersNote =>
      'Theo thứ tự hợp tác. Xin cảm ơn các cá nhân và công ty đã đóng góp cho công tác phòng chống thiên tai, nhờ đó DPIP mới có thể ra đời.';

  @override
  String get morePartnerGeoscience => 'Geoscience';

  @override
  String get morePartnerTwds => 'TWDS';

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
  String get typhoonLegendCircleAvg => 'Bán kính trung bình';

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
  String get typhoonLabelGust => 'Gió giật đỉnh';

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
  String get moonAge => 'Tuổi trăng';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable => 'Chọn khu vực để xem dự báo';

  @override
  String get mapLayers => 'Lớp bản đồ';

  @override
  String get meshtasticHardware => 'Phần cứng';

  @override
  String get languageSettings => 'Ngôn ngữ';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String homeForecastFeelsLike(String temp) {
    return 'Cảm giác $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => 'Khớp với thời điểm bản tin';

  @override
  String get skyTimeDawn => 'Rạng đông';

  @override
  String get skyTimeAfternoon => 'Buổi chiều';

  @override
  String get meshtasticLastHeard => 'Nghe thấy lần cuối';

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
      'Trường gió cấp 10 + bán kính trung bình (vàng)';

  @override
  String get moonPhaseWaxingGibbous => 'Trăng khuyết lồi đầu tháng';

  @override
  String get reportDetailTitle => 'Báo cáo động đất';

  @override
  String get moreTremReport => 'Báo cáo phát hiện TREM';

  @override
  String weatherDataTime(String station, String time) {
    return '$station · Thời gian dữ liệu $time';
  }

  @override
  String get meshtasticNoNodes => 'Chưa phát hiện nút nào';

  @override
  String get meshtasticViaMqtt => 'Qua MQTT (Internet)';

  @override
  String get radarCountyOutline => 'Ranh giới huyện thị';

  @override
  String get commonClose => 'Đóng';

  @override
  String get restroomGradeLabel => 'Hạng';

  @override
  String get rainIntervalNow => 'Hôm nay';

  @override
  String get changelogCurrentVersion => 'Hiện tại';

  @override
  String get typhoonLabelPressure => 'Áp suất trung tâm';

  @override
  String get typhoonOverlayForecastCalloutsTooltip =>
      'Hiển thị thẻ chi tiết điểm dự báo khi phóng to';

  @override
  String get aedOpenRemark => 'Ghi chú giờ mở';

  @override
  String get onboardingPermsBody =>
      'Để DPIP có thể cảnh báo bạn ngay khi thảm họa xảy ra, vui lòng cấp các quyền sau. Bạn có thể thay đổi chúng bất cứ lúc nào trong cài đặt hệ thống.';

  @override
  String get typhoonOverlaySectionWeather => 'Lớp nền thời tiết';

  @override
  String get notifyOptWeatherLocal => 'Chỉ vị trí hiện tại';

  @override
  String get mapNavRain => 'Mưa';

  @override
  String get moonDays => 'ngày';

  @override
  String mapLegendUnit(String unit) {
    return 'Đơn vị: $unit';
  }

  @override
  String get weatherModeClear => 'Trời quang';

  @override
  String get meshtasticRadio => 'Bộ đàm';

  @override
  String get commonEmpty => 'Không có dữ liệu';

  @override
  String get mapLayerSatelliteB01 => 'Himawari Blue (B01)';

  @override
  String get meshtasticExternalPower => 'Nguồn ngoài';

  @override
  String get moonPhaseLastQuarter => 'Trăng bán nguyệt cuối tháng';

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
  String get meshtasticLastSent => 'Gửi lần cuối';

  @override
  String get meshtasticName => 'Tên';

  @override
  String get meshtasticScan => 'Quét';

  @override
  String get mapLayerCategoryForecast => 'Dự báo số';

  @override
  String get meshtasticChannelFailed => 'Không thiết lập được kênh DPIP';

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
  String get moonNextFullMoon => 'Trăng tròn kế tiếp';

  @override
  String get dpmSheetEmpty =>
      'Chạm vào điểm đánh dấu trên bản đồ để xem chi tiết';

  @override
  String get onboardingSkipLeave => 'Vẫn bỏ qua';

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
  String get onboardingPermBattery => 'Miễn trừ tối ưu hóa pin';

  @override
  String get typhoonLabelNw => 'NW';

  @override
  String get moonPhaseWaxingCrescent => 'Trăng lưỡi liềm đầu tháng';

  @override
  String get restroomCategoryLeisure => 'Địa điểm vui chơi giải trí';

  @override
  String get mapLayerTemperature => 'Nhiệt độ';

  @override
  String get aedCategory => 'Phân loại';

  @override
  String get meshtasticChannels => 'Kênh';

  @override
  String get monitorWaiting => 'Đang chờ dữ liệu…';

  @override
  String get typhoonOverlayForecastCallouts => 'Chú thích điểm dự báo';

  @override
  String get reportDetailEpicenter => 'Tọa độ tâm chấn';

  @override
  String get meshtasticVoltage => 'Điện áp';

  @override
  String get mapLayerMeshtasticSubtitle =>
      'Nút lưới LoRa radio của bạn nghe thấy';

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
      'Chênh lệch bằng 0 = trong suốt (không có tín hiệu)';

  @override
  String get shelterIndoorLabel => 'Trú ẩn trong nhà';

  @override
  String get notifyOptOff => 'Tắt';

  @override
  String get reportFilterSortTime => 'Thời gian';

  @override
  String get mapLayerSatelliteCloudProbablyClear => 'Có thể quang mây';

  @override
  String get weatherModeThunderstorm => 'Mưa dông';

  @override
  String get homeViewOnMap => 'Xem trên bản đồ';

  @override
  String get reportFilterIntensityInfoLegacyTitle => 'Cũ (trước 2020)';

  @override
  String get typhoonLabelSpeed => 'Tốc độ di chuyển';

  @override
  String mapAppOpenFailed(String app) {
    return 'Không thể mở $app';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB tổng hợp (công thức JMA)';

  @override
  String get meshtasticReceived => 'Đã nhận';

  @override
  String get weatherRankingExtremeLow => 'Thấp nhất ngày';

  @override
  String get mapLayerSatelliteB10 => 'Himawari Lower Water Vapour (B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => 'Có thể nhiều mây';

  @override
  String get mapLayerSatelliteTransparentNoWater =>
      '≤ 0 = transparent (no water)';

  @override
  String get shelterCategoryLabel => 'Loại thảm họa';

  @override
  String get meshtasticStateConnecting => 'Đang kết nối…';

  @override
  String get moonTitle => 'Mặt Trăng';

  @override
  String get weatherRankingGust => 'Gió giật';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get moreServerStatus => 'Trạng thái máy chủ';

  @override
  String get notifySectionWeather => 'Thời tiết';

  @override
  String get meshtasticPreset => 'Cấu hình modem';

  @override
  String get dataSectionSeismic => 'Địa chấn';

  @override
  String get changelogBodyEmpty => 'Không có ghi chú cho bản phát hành này.';

  @override
  String get changelogOpenOnGitHub => 'Xem trên GitHub';

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
  String get meshtasticNotConnected => 'Chưa kết nối radio';

  @override
  String get weatherModeSnow => 'Tuyết rơi';

  @override
  String get mapLayerMeshtastic => 'Nút Meshtastic';

  @override
  String get moreDeveloper => 'Thông tin gỡ lỗi';

  @override
  String get mapLayerSatelliteB14 => 'Himawari Longwave Infrared (B14)';

  @override
  String get meshtasticChannelUse => 'Mức dùng kênh';

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
  String get meshtasticNotifyNodes => 'Thông báo nút mới';

  @override
  String get onboardingPermCriticalDesc =>
      'Cho phép các cảnh báo động đất nguy hiểm đến tính mạng phát âm thanh ngay cả khi ở chế độ im lặng hoặc Không làm phiền.';

  @override
  String get mapLayerSatelliteTransparentWarm =>
      'Trời quang (đầu ấm) = trong suốt, thấy bản đồ nền';

  @override
  String get meshtasticSent => 'Đã gửi';

  @override
  String get homeForecastTitle => 'Dự báo 24 giờ';

  @override
  String get typhoonLegendWarningAreas => 'Vùng cảnh báo';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return 'Ẩn $count mục';
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
  String get meshtasticTapNode => 'Chạm vào nút để xem chi tiết';

  @override
  String get commonLoading => 'Đang tải…';

  @override
  String get typhoonIntensityModerate => 'Bão trung bình';

  @override
  String get mapLayerSatelliteAsh => 'Himawari Ash';

  @override
  String get rainInterval3h => '3 giờ';

  @override
  String get mapLayerCategorySatellite => 'Vệ tinh';

  @override
  String get meshtasticChannelReady => 'Kênh DPIP đã sẵn sàng';

  @override
  String get mapLayerSatelliteNightmicrophysics =>
      'Himawari Night Microphysics';

  @override
  String get typhoonIntensityTd => 'Áp thấp nhiệt đới';

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
  String get meshtasticStateError => 'Lỗi';

  @override
  String get weatherModeOvercast => 'Trời âm u';

  @override
  String get reportDetailDepth => 'Độ sâu chấn tiêu';

  @override
  String get typhoonOverlayWarningTooltip =>
      'Làm nổi bật các huyện đang có cảnh báo bão';

  @override
  String get reportFilterDatePick => 'Chọn ngày';

  @override
  String get onboardingSkipStay => 'Quay lại';

  @override
  String get commonFetchFailed => 'Không thể tải dữ liệu. Vui lòng thử lại.';

  @override
  String get shelterOutdoorLabel => 'Trú ẩn ngoài trời';

  @override
  String get meshtasticStateConnected => 'Đã kết nối';

  @override
  String get mapNavRadar => 'Ra đa';

  @override
  String get mapLayerSatelliteCloudClear => 'Quang mây';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'M$magnitude · độ sâu $depth km';
  }

  @override
  String get locationBannerPermission =>
      'Chưa cấp quyền vị trí — cảnh báo khu vực không thể nhắm đúng vùng của bạn.';

  @override
  String get typhoonOverlayWeatherNoneTooltip =>
      'Không có lớp nền radar hoặc hồng ngoại';

  @override
  String get radarCountyOutlineHint => 'Vẽ đè lên tiếng vọng';

  @override
  String get windForecastCountyOutlineHint => 'Vẽ trên trường gió';

  @override
  String get homeRainTrendTitle => 'Mưa 1 giờ tới';

  @override
  String get moonPhaseFirstQuarter => 'Trăng bán nguyệt đầu tháng';

  @override
  String get mapLayerCategoryTyphoon => 'Bão';

  @override
  String get meshtasticUtilization => 'Thời gian phát sóng (24 giờ)';

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
  String get meshtasticReadingAge => 'Thời điểm đo';

  @override
  String get mapAppCallFailed => 'Thiết bị này không thể thực hiện cuộc gọi';

  @override
  String get reportFilterAny => 'Tất cả';

  @override
  String get weatherRankingMergeTo => 'Gộp';

  @override
  String get notifyIntensity => 'Báo cáo cường độ chấn động';

  @override
  String get rainIntervalMenu => 'Khung tích lũy';

  @override
  String get reportDetailLocalFelt => 'Động đất cảm nhận cục bộ';

  @override
  String get meshtasticDevice => 'Thiết bị';

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
  String get meshtasticExcludeMqtt => 'Ẩn nút MQTT';

  @override
  String get mapNavTyphoon => 'Bão';

  @override
  String get weatherModeSand => 'Bụi cát';

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
  String get meshtasticRegionLabel => 'Vùng';

  @override
  String get mapLayerSatelliteCloudtop => 'Himawari Cloud Top Temperature';

  @override
  String get moonTimelineCaption => 'Pha';

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
  String get meshtasticHopLimit => 'Giới hạn hop';

  @override
  String get weatherRankingExtremeHigh => 'Cao nhất ngày';

  @override
  String get sponsorPrivacy => 'Chính sách quyền riêng tư';

  @override
  String get reportDetailLocalIntensity => 'Cường độ tại vị trí của bạn';

  @override
  String get mapLayerSatelliteNaturalcolor => 'Himawari Natural Color';

  @override
  String get meshtasticAirtime => 'Thời gian phát sóng (TX)';

  @override
  String shelterCapacityValue(int n) {
    return '$n người';
  }

  @override
  String lightningLegendCc(int minutes) {
    return 'Mây–mây · $minutes phút';
  }

  @override
  String get meshtasticSendHint => 'Tin nhắn để phát';

  @override
  String monitorDelay(String value) {
    return 'Độ trễ $value s';
  }

  @override
  String get dpmNo => 'Không';

  @override
  String get mapLayerSatelliteB08 => 'Himawari Upper Water Vapour (B08)';

  @override
  String get meshtasticReconnecting => 'Đang kết nối lại…';

  @override
  String get radarTownOutlineSubtitle =>
      'Giữ ranh giới xã phường rõ ràng dưới lớp phản hồi radar.';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip =>
      'Ảnh hồng ngoại gần thời điểm bản tin bão nhất';

  @override
  String get radarScanRangeHint => 'Ngoài khung là chưa quan trắc';

  @override
  String typhoonPickerTd(String no) {
    return 'Áp thấp nhiệt đới TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => 'Himawari Water Vapour';

  @override
  String get regionAddButton => 'Thêm khu vực';

  @override
  String get regionSearchHint => 'Tìm kiếm tỉnh và thành phố';

  @override
  String get regionSearchEmpty => 'Không tìm thấy tỉnh/thành phố phù hợp';

  @override
  String get regionSearchTownHint => 'Tìm kiếm xã';

  @override
  String get regionSearchTownEmpty => 'Không tìm thấy xã phù hợp';

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
  String get mapLayerStyleTooltip => 'Kiểu màu';

  @override
  String lightningLegendCg(int minutes) {
    return 'Mây–đất · $minutes phút';
  }

  @override
  String get skyTimeAuto => 'Tự động';

  @override
  String get appLogs => 'Nhật ký ứng dụng';

  @override
  String get serverStatusLocal => 'Trạng thái thiết bị';

  @override
  String get serverStatusLocalBody =>
      'Chỉ số máy chủ đến từ bảng điều khiển. Dưới đây là đánh giá kết nối thực tế của máy này với các endpoint đa hoạt động (LB / Core từng khu vực): ứng dụng chỉ ghi nhận thụ động lưu lượng thực tế, nếu endpoint chưa từng được máy này truy cập sẽ hiển thị \'Chưa dò\'.';

  @override
  String get serverStatusAllUp => 'Tất cả dịch vụ hoạt động';

  @override
  String get serverStatusDegraded => 'Hiệu suất giảm';

  @override
  String get serverStatusDown => 'Dịch vụ lỗi';

  @override
  String get serverStatusErrorRate => 'Tỷ lệ lỗi 5xx';

  @override
  String get serverStatusLatency => 'Độ trễ trung bình';

  @override
  String get serverStatusUpdated => 'Cập nhật';

  @override
  String get serverStatusWeb => 'Trạng thái máy chủ';

  @override
  String get serverStatusWebUrl => 'status.exptech.dev';

  @override
  String get serverStatusExpTech => 'Trạng thái ExpTech';

  @override
  String get serverStatusCloudflare => 'Trạng thái Cloudflare';

  @override
  String get serverStatusCloudflareAllOperational => 'Tất cả khu vực hoạt động';

  @override
  String get serverStatusCloudflareOutage => 'Cloudflare có khu vực bất thường';

  @override
  String get serverStatusCloudflareNone => 'Không có khu vực nào để hiển thị.';

  @override
  String get serverStatusCloudflareOperational => 'Hoạt động';

  @override
  String get serverStatusCloudflareDegraded => 'Hiệu suất giảm';

  @override
  String get serverStatusCloudflarePartial => 'Gián đoạn một phần';

  @override
  String get serverStatusCloudflareMajor => 'Gián đoạn lớn';

  @override
  String get serverStatusCloudflareUnknown => 'Không rõ';

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
      'Core độc quyền API (radar / thời tiết / gió)';

  @override
  String get endpointTierCoreStaticExclusive => 'Core độc quyền tĩnh';

  @override
  String get endpointTierLegacyApi => 'API kế thừa (api-1)';

  @override
  String get endpointHealthOk => 'Kết nối bình thường';

  @override
  String get endpointHealthDegraded => 'Có máy chủ không ổn định';

  @override
  String get endpointHealthDown => 'Kết nối bất thường';

  @override
  String get endpointHealthUnknown => 'Chưa có dữ liệu';

  @override
  String get endpointStateOk => 'Bình thường';

  @override
  String get endpointStateDegraded => 'Không ổn định';

  @override
  String get endpointStateDown => 'Bất thường';

  @override
  String get endpointStateUnknown => 'Không rõ';

  @override
  String get endpointServiceEew => 'EEW';

  @override
  String get endpointServiceRts => 'RTS';

  @override
  String get endpointServiceRadar => 'Ra đa';

  @override
  String get endpointServiceSatellite => 'Vệ tinh';

  @override
  String get endpointServiceQpesums => 'QPE';

  @override
  String get endpointServiceWind => 'Gió';

  @override
  String get endpointServiceDpm => 'Điểm thiên tai';

  @override
  String get endpointServiceWeather => 'Thời tiết';

  @override
  String get endpointServiceRain => 'Mưa';

  @override
  String get endpointServiceLightning => 'Sét';

  @override
  String get endpointServiceTyphoon => 'Bão';

  @override
  String get endpointServiceReport => 'Báo cáo động đất';

  @override
  String get endpointServiceTremStation => 'Trạm đo chấn động';

  @override
  String get endpointServiceEvent => 'Sự kiện';

  @override
  String get endpointServiceLocation => 'Vị trí';

  @override
  String get endpointServiceNotify => 'Thông báo';

  @override
  String get endpointServiceOther => 'Khác';

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
      'Hãy ngắt kết nối radio trong ứng dụng Meshtastic khác trước. Hai ứng dụng dùng chung một radio sẽ giành tin nhắn của nhau, một số tin sẽ bị mất.';

  @override
  String get meshtasticChannelNoSlot =>
      'Không có kênh trống — hãy giải phóng một kênh trên radio';

  @override
  String get restroomCategoryTransport => 'Giao thông';

  @override
  String get meshtasticBattery => 'Pin';

  @override
  String get meshtasticDistance => 'Khoảng cách';

  @override
  String get meshtasticSnrTrend => 'Xu hướng tín hiệu (SNR)';

  @override
  String get meshtasticBatteryTrend => 'Xu hướng pin';

  @override
  String get typhoonOverlayMenuTooltip => 'Tùy chọn lớp phủ bão';

  @override
  String get mapLayerSatelliteBtdOzone => 'Himawari Tropopause';

  @override
  String meshtasticRegionMismatch(String region) {
    return 'Vùng radio là $region — DPIP cần TW';
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
  String get mapLayerStyleGrayTooltip => 'JMA grayscale — càng lạnh càng trắng';

  @override
  String get moreAnnouncements => 'Thông báo';

  @override
  String get moreTagline => 'Nền tảng tích hợp thông tin phòng chống thiên tai';

  @override
  String get moreVersionStable => 'Bản chính thức';

  @override
  String get moreVersionNotes => 'Bản cập nhật này';

  @override
  String get moreVersionNotesHighlightsSubtitle =>
      'Những thay đổi trong phiên bản này';

  @override
  String releaseHighlightsTitle(Object train) {
    return '$train tóm tắt chính';
  }

  @override
  String get releaseHighlightsTabNormal => 'Cho người dùng';

  @override
  String get releaseHighlightsTabAdvanced => 'Đi sâu';

  @override
  String get releaseHighlightsEmpty => 'Chưa có nội dung.';

  @override
  String get releaseHighlightsSeeNotes => 'Xem ghi chú đầy đủ';

  @override
  String get moreVersionNotesEmpty =>
      'Không tìm thấy nhật ký cập nhật cho bản này';

  @override
  String get reportNotFound => 'Không tìm thấy báo cáo động đất này';

  @override
  String get moreVersionSnapshot => 'Bản thử nghiệm';

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
  String get typhoonOverlayWeatherNone => 'Không có';

  @override
  String get mapLayerStyleGray => 'Thang xám (JMA)';

  @override
  String get weatherModeAuto => 'Tự động';

  @override
  String get typhoonLabelProbCircle => 'Vòng tròn xác suất 70%';

  @override
  String get notifyOptAll => 'Nhận tất cả';

  @override
  String get displayTheme => 'Giao diện';

  @override
  String get mapLayerSatelliteB07 => 'Himawari Shortwave Infrared (B07)';

  @override
  String get typhoonLabelDirection => 'Hướng di chuyển';

  @override
  String get regionManageTitle => 'Khu vực đã lưu';

  @override
  String get regionSaveNote =>
      'Thông báo được gửi dựa trên vị trí GPS của bạn. Việc đặt khu vực thường dùng không thay đổi nơi nhận cảnh báo — khu vực thường dùng chỉ giúp xem nhanh trạng thái từng khu vực trên trang chủ. Hãy cấp quyền vị trí, nếu không thông báo sẽ không hoạt động.';

  @override
  String get typhoonLegendCone => 'Nón dự báo';

  @override
  String get moreCwaEew => 'Cảnh báo sớm động đất của CWA';

  @override
  String get onboardingPermsTitle => 'Quyền truy cập';

  @override
  String get mapLayerStyleJma => 'Tăng tương phản mây (JMA)';

  @override
  String get rainInterval10m => '10 phút';

  @override
  String get meshtasticConnectAnyway => 'Vẫn kết nối';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get mapLayerSatelliteB06 => 'Himawari Near-Infrared (B06)';

  @override
  String get mapLayerSatelliteTransparentReflectance =>
      'Phản xạ thấp / ban đêm = trong suốt, thấy bản đồ nền';

  @override
  String chartHourLabel(int hour) {
    return '${hour}h';
  }

  @override
  String get mapLayerShelter => 'Nơi trú ẩn';

  @override
  String get typhoonOverlayProbabilityTooltip =>
      'Hiển thị xác suất trúng bão (ẩn vùng dự kiến)';

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
  String get meshtasticShortName => 'Tên ngắn';

  @override
  String get mapLayerSatelliteAirmass => 'Himawari Airmass';

  @override
  String get dataSectionWeather => 'Thời tiết';

  @override
  String get aedHoursWeekday => 'Giờ ngày thường';

  @override
  String get homeActiveEventsTitle => 'Sự kiện đang hiệu lực';

  @override
  String get faq => 'Câu hỏi thường gặp';

  @override
  String eewSerial(int serial) {
    return 'Bản tin $serial';
  }

  @override
  String get reportFilterSort => 'Sắp xếp';

  @override
  String get meshtasticRegionConfirm =>
      'Chuyển radio này sang vùng TW? Nó sẽ khởi động lại và ngắt kết nối một lúc, mọi kênh khác cũng được chuyển theo.';

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
  String get mapOsmOverlay => 'Bản đồ chi tiết';

  @override
  String get mapOsmOverlayHint =>
      'Hiện đường, tòa nhà và địa danh chi tiết hơn';

  @override
  String get mapOsmDetails => 'Chi tiết lớp';

  @override
  String get moreDataSources => 'Nguồn dữ liệu';

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
    return 'Đã bật $enabled / $total lớp';
  }

  @override
  String get mapOsmSurface => 'Bề mặt';

  @override
  String get mapOsmParks => 'Công viên';

  @override
  String get mapOsmLandUse => 'Sử dụng đất';

  @override
  String get mapOsmAirportAreas => 'Khu vực sân bay';

  @override
  String get mapOsmWater => 'Vùng nước';

  @override
  String get mapOsmRivers => 'Sông ngòi';

  @override
  String get mapOsmBoundaries => 'Ranh giới';

  @override
  String get mapOsmBuildings => 'Tòa nhà';

  @override
  String get mapOsmRoads => 'Đường bộ';

  @override
  String get mapOsmRoadNames => 'Tên đường';

  @override
  String get mapOsmWaterNames => 'Tên vùng nước';

  @override
  String get mapOsmPeaks => 'Đỉnh núi';

  @override
  String get mapOsmAirportNames => 'Tên sân bay';

  @override
  String get mapOsmPlaceNames => 'Tên địa danh';

  @override
  String get mapOsmPoi => 'Địa điểm quan tâm';

  @override
  String get mapOsmHouseNumbers => 'Số nhà';

  @override
  String get mapOsmRestoreAll => 'Khôi phục tất cả';

  @override
  String get mapOsmSectionNatural => 'Đặc điểm tự nhiên';

  @override
  String get mapOsmSectionRoadsAndBuildings => 'Đường & tòa nhà';

  @override
  String get mapOsmSectionLabelsAndPlaces => 'Nhãn & địa điểm';

  @override
  String get mapTownLabels => 'Tên hương trấn';

  @override
  String get notifySetFailed => 'Không thể lưu cài đặt. Vui lòng thử lại.';

  @override
  String get meshtasticDisconnect => 'Ngắt kết nối';

  @override
  String get meshtasticUndecoded => 'Chưa giải mã';

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

  @override
  String get permissionGuideNotification =>
      'Mở Cài đặt Hệ thống để cho phép thông báo.';

  @override
  String get permissionGuideForegroundLocation =>
      'Mở Cài đặt Hệ thống để cho phép vị trí chính xác.';

  @override
  String permissionGuideBackgroundLocation(Object option) {
    return 'Trong “$option”, chọn “Cho phép mọi lúc”.';
  }

  @override
  String get permissionGuideBackgroundExecution =>
      'Cho phép chạy nền trong Cài đặt Hệ thống để thông báo không bị tạm dừng.';

  @override
  String get permissionGuideUnusedPause =>
      'Nếu ứng dụng bị đánh dấu “không sử dụng”, hãy chọn “Cho phép” trong Cài đặt Hệ thống.';

  @override
  String get permissionGuideUnusedFreeSpace =>
      'Nếu ứng dụng bị tạm dừng vì bộ nhớ, hãy xóa bộ nhớ đệm và mở lại.';

  @override
  String get permissionGuideUnusedRevoke =>
      'Nếu quyền của ứng dụng bị thu hồi, hãy cấp lại trong Cài đặt Hệ thống.';

  @override
  String get permissionGuideUnusedPlayProtect =>
      'Nếu Play Protect tạm dừng ứng dụng, hãy kiểm tra trạng thái trong Google Play.';

  @override
  String permissionGuideVendorPower(Object vendor) {
    return 'Trong cài đặt tiết kiệm pin của “$vendor”, đặt ứng dụng này thành “Không giới hạn”.';
  }

  @override
  String get permissionStillRequired => 'Vẫn cần thiết — mở Cài đặt để bật.';

  @override
  String get permissionVerifyManually =>
      'Vui lòng xác minh thủ công rằng quyền này đã được bật trong Cài đặt Hệ thống.';

  @override
  String get permissionBackgroundLocationOption => '“Cho phép mọi lúc”';

  @override
  String get displayTextSize => 'Cỡ chữ';

  @override
  String get displayTextSizeDesc =>
      'Chỉ áp dụng cho giao diện ứng dụng, không đổi nhãn trên bản đồ.';

  @override
  String get displayTextWeight => 'Độ đậm chữ';

  @override
  String get displayTextWeightDesc => 'Chữ đậm hơn có thể dễ đọc hơn.';

  @override
  String get displayContrast => 'Độ tương phản';

  @override
  String get displayContrastDesc =>
      'Tương phản cao hơn giúp chữ tách rõ khỏi nền.';

  @override
  String get displayColorVision => 'Thị giác màu';

  @override
  String get displayColorVisionDesc =>
      'Đổi màu toàn bộ ứng dụng, kể cả màu trên bản đồ.';

  @override
  String get displayColorVisionNone => 'Màu chuẩn';

  @override
  String get displayColorVisionProtan => 'Yếu màu đỏ (protanopia)';

  @override
  String get displayColorVisionDeutan => 'Yếu màu xanh lá (deuteranopia)';

  @override
  String get displayColorVisionTritan => 'Yếu màu xanh dương/vàng (tritanopia)';

  @override
  String get displayPreviewSample => 'Báo cáo động đất mẫu';

  @override
  String get displayScaleSmall => 'Nhỏ';

  @override
  String get displayScaleDefault => 'Mặc định';

  @override
  String get displayScaleLarge => 'Lớn';

  @override
  String get displayScaleHuge => 'Rất lớn';

  @override
  String get displayWeightNormal => 'Thường';

  @override
  String get displayWeightMedium => 'Đậm vừa';

  @override
  String get displayWeightBold => 'Đậm';

  @override
  String get displayContrastStandard => 'Chuẩn';

  @override
  String get displayContrastMedium => 'Vừa';

  @override
  String get displayContrastHigh => 'Cao';

  @override
  String get meshtasticDirect => 'Trực tiếp';

  @override
  String meshtasticHopsAway(int n) {
    return '$n bước';
  }

  @override
  String get meshtasticStatRelayShare => 'Chuyển tiếp hộ';

  @override
  String get meshtasticStatRelayShareHint => 'Tỷ lệ trong lượng gửi';

  @override
  String get meshtasticStatRelayValue => 'Tỷ lệ chuyển tiếp xong';

  @override
  String get meshtasticStatRelaySolePath =>
      'Thường là đường duy nhất — mesh dựa vào nút này';

  @override
  String get meshtasticStatRelayRedundant => 'Nút khác cũng phủ chặng này';

  @override
  String get meshtasticStatRedundancy => 'Nhận trùng';

  @override
  String get meshtasticStatThinEdge =>
      'Ít đường dự phòng — một trạm hỏng có thể mất kết nối';

  @override
  String get meshtasticStatWellCovered => 'Nhiều đường tới được đây';

  @override
  String get meshtasticStatErrorRate => 'Tỷ lệ nhận lỗi';

  @override
  String get meshtasticStatErrorRateHint =>
      'Tăng khi airtime không đổi = nhiễu';

  @override
  String get meshtasticTraceRoute => 'Truy vết đường đi';

  @override
  String get meshtasticTracing => 'Đang truy vết…';

  @override
  String get meshtasticTraceUnreadable => 'Phản hồi không đọc được';

  @override
  String get meshtasticTraceOffline => 'Chưa kết nối bộ đàm';

  @override
  String get meshtasticTraceCooldown => 'Bộ đàm giới hạn 30 giây một lần';

  @override
  String get meshtasticTraceNoReply =>
      'Không phản hồi — ngoài phạm vi hoặc khác khóa';

  @override
  String get meshtasticTraceDirect => 'Trực tiếp — không qua trung chuyển';

  @override
  String meshtasticTraceHops(int n) {
    return '$n chặng';
  }

  @override
  String get moreDumpDiagnostics => 'Tải lên thông tin gỡ lỗi và nhật ký';

  @override
  String get moreDumpDiagnosticsHint =>
      'Tải lên rồi sao chép liên kết để đính kèm vào báo cáo';

  @override
  String get dumpIncludeSensitive => 'Bao gồm vị trí chính xác';

  @override
  String get dumpIncludeSensitiveHint =>
      'Bao gồm tọa độ trong nhật ký và vị trí nền; nếu không chọn, chúng được thay bằng null';

  @override
  String get dumpUpload => 'Tải lên';

  @override
  String get dumpUploaded => 'Đã tải lên';

  @override
  String get dumpLinkCopied => 'Đã sao chép liên kết vào bảng nhớ tạm';

  @override
  String get dumpCopyAgain => 'Sao chép lại';

  @override
  String get dumpUploadFailed => 'Tải lên thất bại';

  @override
  String get statusLegendUnprobed => 'Chưa dò';

  @override
  String get statusLegendUnsupported => 'Không có';

  @override
  String get rainScaleSection => 'Thang màu';

  @override
  String get rainScaleFine => 'Mịn';

  @override
  String get rainScaleCoarse => 'Thô';

  @override
  String get notifyTestTitle => 'Thử thông báo';

  @override
  String get notifyTestIntro =>
      'Chạm vào một mục sẽ gửi cảnh báo đó thật sự. Cảnh báo nghiêm trọng phát ở âm lượng tối đa và vang lên bất chấp chế độ im lặng và Không làm phiền.';

  @override
  String get notifyTestCriticalDenied =>
      'Thiết bị này chưa cho phép cảnh báo khẩn cấp, nên cảnh báo nghiêm trọng vẫn im lặng khi máy đang tắt tiếng.';

  @override
  String get notifyTestPermissionOff =>
      'Thông báo đang tắt nên thử nghiệm sẽ không hiện gì cả.';

  @override
  String get notifyTestBehaviourOverrides =>
      'Vang lên qua chế độ im lặng và Không làm phiền';

  @override
  String get notifyTestBehaviourAlerts =>
      'Có âm thanh và biểu ngữ, trừ khi máy đang tắt tiếng';

  @override
  String get notifyTestBehaviourSounds =>
      'Có âm thanh, không biểu ngữ, trừ khi máy đang tắt tiếng';

  @override
  String get notifyTestBehaviourSilent =>
      'Im lặng — chỉ hiện trong danh sách thông báo';

  @override
  String get notifyTestFailed => 'Không gửi được thông báo thử.';

  @override
  String get moreBugReports => 'Lỗi đã báo cáo';

  @override
  String get bugTrackerEmpty => 'Chưa có lỗi nào được báo cáo';

  @override
  String get bugTrackerReplies => 'Phản hồi';

  @override
  String get bugTrackerGoToDiscord =>
      'Không tìm thấy vấn đề của bạn? Hãy báo cáo trên Discord!';

  @override
  String get bugTrackerNoMatch => 'Không có lỗi nào khớp với thẻ đã chọn';

  @override
  String get bugTrackerDeveloper => 'Nhà phát triển';

  @override
  String get bugTrackerCannotDisplay =>
      'Không thể hiển thị nội dung này — xem trên Discord';

  @override
  String get bugTrackerJoinDiscussion => 'Tham gia thảo luận trên Discord';

  @override
  String get bugTrackerSortLast => 'Hoạt động mới nhất';

  @override
  String get bugTrackerSortMostDiscussed => 'Nhiều thảo luận nhất';

  @override
  String get bugTrackerStaff => 'Nhân sự';

  @override
  String eewSpokenLocalIntensity(String intensity) {
    return 'Cường độ dự kiến tại vị trí của bạn: $intensity.';
  }

  @override
  String eewSpokenMaxIntensity(String intensity) {
    return 'Cường độ tối đa dự kiến: $intensity.';
  }
}
