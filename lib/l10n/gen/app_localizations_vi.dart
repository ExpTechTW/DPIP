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
  String get navEarthquake => 'Động đất';

  @override
  String get navMore => 'Thêm';

  @override
  String get appLogs => 'Nhật ký ứng dụng';

  @override
  String get mapPlaceholderDisabled => 'Bản đồ (tạm thời vô hiệu hóa)';

  @override
  String get moreSectionGeneral => 'Chung';

  @override
  String get regionManageTitle => 'Khu vực đã lưu';

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
  String get moreSectionAdvanced => 'Nâng cao';

  @override
  String get moreDeveloper => 'Thông tin gỡ lỗi';

  @override
  String get developerCopied => 'Đã sao chép vào bảng nhớ tạm';

  @override
  String get developerCopyAll => 'Sao chép tất cả';

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
  String get mapLayers => 'Lớp bản đồ';

  @override
  String get mapLayerRadar => 'Radar';

  @override
  String get mapTimelineNow => 'Bây giờ';

  @override
  String get mapTimelineObserved => 'Quan trắc';

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
  String get moreRate => 'Đánh giá DPIP';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get moreSourceCode => 'Mã nguồn';
}
