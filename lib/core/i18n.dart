import 'package:i18n_extension/i18n_extension.dart';

Translations<dynamic, Map<String, String>, Map<dynamic, String>, dynamic> get _t =>
    Translations.byText('zh-TW') +
    {'en': 'Settings', 'ja': '設定', 'ko': '설정', 'ru': 'Настройки', 'vi': 'Cài đặt', 'zh-CN': '设置', 'zh-TW': '設定'} +
    {'en': 'Location', 'ja': '位置', 'ko': '위치', 'ru': 'Местоположение', 'vi': 'Vị trí', 'zh-CN': '位置', 'zh-TW': '位置'} +
    {
      'en': 'Current Location',
      'ja': '現在地',
      'ko': '현재 위치',
      'ru': 'Текущее местоположение',
      'vi': 'Vị Trí Hiện Tại',
      'zh-CN': '所在地',
      'zh-TW': '所在地',
    } +
    {
      'en': 'Set your location to receive updates about your area',
      'ja': '現在地を設定して地域のリアルタイム情報を受け取る',
      'ko': '현재 위치를 설정하여 지역 실시간 정보를 받으세요',
      'ru': 'Укажите местоположение для получения местной информации в реальном времени',
      'vi': 'Thiết lập vị trí để nhận thông tin địa phương theo thời gian thực',
      'zh-CN': '设置所在地来接收当地的即时资讯',
      'zh-TW': '設定你的所在地來接收當地的即時資訊',
    } +
    {
      'en': 'Update Automatically',
      'ja': '自動更新',
      'ko': '자동 업데이트',
      'ru': 'Автоматическое обновление',
      'vi': 'Cập nhật tự động',
      'zh-CN': '自动更新',
      'zh-TW': '自動更新',
    } +
    {
      'en': 'Update your current location periodically',
      'ja': '定期的に現在地を更新する',
      'ko': '주기적으로 현재 위치 업데이트',
      'ru': 'Периодически обновлять текущее местоположение',
      'vi': 'Cập nhật vị trí hiện tại định kỳ',
      'zh-CN': '定期更新当前所在地',
      'zh-TW': '定期更新目前的所在地',
    } +
    {
      'en':
          'The automatic location update feature will use the GPS on your device to update your location based on your geographical position periodically, providing real-time weather and earthquake information, so you can stay up-to-date with the latest local conditions.',
      'ja': 'この機能には、デバイスのGPSを利用して、地理的な位置情報に基づいて所在地を更新します。リアルタイムの天気情報や地震情報を提供し、最新の地域状況を取得します。',
      'ko': '자동 위치 지정 기능은 장치의 GPS를 사용하여 지리적 위치를 기반으로 위치를 자동으로 업데이트하고, 실시간 날씨 및 지진 정보를 제공하여 항상 최신 현지 상황을 파악할 수 있도록 합니다.',
      'ru':
          'Функция автоматического обновления местоположения будет использовать GPS на вашем устройстве для периодического обновления вашего местоположения на основе вашего географического положения, предоставляя информацию о погоде и землетрясениях в реальном времени, чтобы вы всегда оставались в курсе последних местных условий.',
      'vi':
          'Tính năng định vị tự động sẽ sử dụng GPS trên thiết bị của bạn để tự động cập nhật vị trí của bạn dựa trên vị trí địa lý, cung cấp thông tin thời tiết và động đất theo thời gian thực, giúp bạn luôn nắm bắt được tình hình mới nhất tại địa phương.',
      'zh-CN': '自动定位功能将使用您的装置上的定位功能 ，根据您的地理位置，自动更新您的所在地，提供实时的天气和地震资讯，让您随时掌握当地最新状况。',
      'zh-TW': '自動定位功能將使用您的裝置上的 GPS，即使 DPIP 關閉或未在使用時，也會根據您的地理位置，自動更新您的所在地，提供即時的天氣和地震資訊，讓您隨時掌握當地最新狀況。',
    } +
    {
      'en': 'City',
      'ja': '直轄市/県市',
      'ko': '광역시/시도',
      'ru': 'Специальный муниципалитет/Город',
      'vi': 'Thành phố trực thuộc trung ương/Tỉnh thành',
      'zh-CN': '直辖市/县市',
      'zh-TW': '直轄市/縣市',
    } +
    {
      'en': 'Town',
      'ja': '区町村',
      'ko': '구읍면동',
      'ru': 'Район/Город/Посёлок',
      'vi': 'Quận/Phường/Xã',
      'zh-CN': '区镇市乡',
      'zh-TW': '鄉鎮市區',
    } +
    {
      'en': 'Not Set',
      'ja': '未設定',
      'ko': '설정되지 않음',
      'ru': 'Не установлено',
      'vi': 'Chưa đặt',
      'zh-CN': '未设置',
      'zh-TW': '尚未設定',
    } +
    {'en': 'Language', 'ja': '言語', 'ko': '언어', 'ru': 'Язык', 'vi': 'Ngôn ngữ', 'zh-CN': '语言', 'zh-TW': '語言'} +
    {
      'en': 'Adjust the display language of DPIP',
      'ja': 'DPIPの表示言語を調整',
      'ko': 'DPIP 표시 언어 조정',
      'ru': 'Настройка языка отображения DPIP',
      'vi': 'Điều chỉnh ngôn ngữ hiển thị DPIP',
      'zh-CN': '调整 DPIP 的显示语言',
      'zh-TW': '調整 DPIP 的顯示語言',
    } +
    {
      'en': 'Display Language',
      'ja': '表示言語',
      'ko': '표시 언어',
      'ru': 'Язык отображения',
      'vi': 'Ngôn ngữ hiển thị',
      'zh-CN': '显示语言',
      'zh-TW': '顯示語言',
    } +
    {
      'en': 'System Language',
      'ja': 'システム言語',
      'ko': '시스템 언어',
      'ru': 'Язык системы',
      'vi': 'Ngôn ngữ hệ thống',
      'zh-CN': '系统语言',
      'zh-TW': '系統語言',
    } +
    {
      'en': 'Help us translate!',
      'ja': '翻訳を協力',
      'ko': '번역 돕기',
      'ru': 'Помогите перевести',
      'vi': 'Hỗ trợ biên dịch',
      'zh-CN': '协助翻译',
      'zh-TW': '協助翻譯',
    } +
    {
      'en': 'Click here to help us improve the translation of DPIP',
      'ja': 'DPIPの翻訳にご協力をお願いします！',
      'ko': '여기를 눌러 DPIP 번역 개선을 도와주세요',
      'ru': 'Помогите нам улучшить перевод DPIP',
      'vi': 'Nhấp vào đây để giúp chúng tôi cải thiện bản dịch DPIP',
      'zh-CN': '点击这里来帮助我们改进 DPIP 的翻译',
      'zh-TW': '點擊這裡來幫助我們改進 DPIP 的翻譯',
    } +
    {
      'en': 'Select Language',
      'ja': '言語を選択',
      'ko': '언어 선택',
      'ru': 'Выберите язык',
      'vi': 'Chọn ngôn ngữ',
      'zh-CN': '选择语言',
      'zh-TW': '選擇語言',
    } +
    {
      'en': 'Translated {translated}・Approved {approved}',
      'ja': '{translated} 翻訳済み・{approved} 校正済み',
      'ko': '번역됨 {translated}・승인됨 {approved}',
      'ru': 'Переведено {translated}・Утверждено {approved}',
      'vi': 'Đã dịch {translated}・Đã hiệu đính {approved}',
      'zh-CN': '已翻译 {translated}・已校对 {approved}',
      'zh-TW': '已翻譯 {translated}・已校對 {approved}',
    } +
    {
      'en': 'Source Language',
      'ja': '元言語',
      'ko': '출처 언어',
      'ru': '來源語言',
      'vi': 'Ngôn ngữ nguồn',
      'zh-CN': '来源语言',
      'zh-TW': '來源語言',
    } +
    {
      'en': '已更新至 v{version}',
      'ja': '已更新至 v{version}',
      'ko': '已更新至 v{version}',
      'ru': '已更新至 v{version}',
      'vi': '已更新至 v{version}',
      'zh-CN': '已更新至 v{version}',
      'zh-TW': '已更新至 v{version}',
    } +
    {
      'en': 'Change log',
      'ja': '更新履歴',
      'ko': '업데이트 로그',
      'ru': '更新日誌',
      'vi': 'Nhật ký thay đổi',
      'zh-CN': '更新日志',
      'zh-TW': '更新日誌',
    } +
    {
      'en': 'Error in retrieving weather data',
      'ja': '天気の取得に失敗しました',
      'ko': '날씨 이상징후 확인',
      'ru': '取得天氣異常',
      'vi': '取得天氣異常',
      'zh-CN': '取得天气异常',
      'zh-TW': '取得天氣異常',
    } +
    {
      'en': 'Location not set',
      'ja': '現在地が設定されていません',
      'ko': '위치가 설정되지 않았습니다',
      'ru': '尚未設定所在地',
      'vi': 'Bạn chưa thiết lập vị trí của mình',
      'zh-CN': '尚未设定所在地',
      'zh-TW': '尚未設定所在地',
    } +
    {
      'en': 'Outside the service area, only available in Taiwan',
      'ja': '台湾以外ではご利用いただけません',
      'ko': '서비스 불가 지역, 대만 국내에서만 이용 가능합니다.',
      'ru': '服務區域外，僅在臺灣各地可用',
      'vi': 'Ngoài khu vực dịch vụ, chỉ có sẵn ở các địa điểm khác nhau trên khắp Đài Loan.',
      'zh-CN': '服务区域外，仅在台湾各地可用',
      'zh-TW': '服務區域外，僅在臺灣各地可用',
    } +
    {
      'en': 'Radar',
      'ja': 'レーダー',
      'ko': '레이더',
      'ru': '雷達回波',
      'vi': 'Hình ảnh radar',
      'zh-CN': '雷达拼图',
      'zh-TW': '雷達回波',
    } +
    {
      'en': 'Heavy Rain Advisory',
      'ja': 'リアルタイムの雷雨情報',
      'ko': '뇌우 재난 문자',
      'ru': '雷雨即時訊息',
      'vi': '雷雨即時訊息',
      'zh-CN': '雷雨即时信息',
      'zh-TW': '雷雨即時訊息',
    } +
    {
      'en': '您所在區域附近有劇烈雷雨或降雨發生，請注意防範，持續至 ',
      'ja': '您所在區域附近有劇烈雷雨或降雨發生，請注意防範，持續至 ',
      'ko': '您所在區域附近有劇烈雷雨或降雨發生，請注意防範，持續至 ',
      'ru': '您所在區域附近有劇烈雷雨或降雨發生，請注意防範，持續至 ',
      'vi': '您所在區域附近有劇烈雷雨或降雨發生，請注意防範，持續至 ',
      'zh-CN': '您所在區域附近有劇烈雷雨或降雨發生，請注意防範，持續至 ',
      'zh-TW': '您所在區域附近有劇烈雷雨或降雨發生，請注意防範，持續至 ',
    } +
    {
      'en': '體感約 {useFahrenheit}°',
      'ja': '體感約 {useFahrenheit}°',
      'ko': '體感約 {useFahrenheit}°',
      'ru': '體感約 {useFahrenheit}°',
      'vi': '體感約 {useFahrenheit}°',
      'zh-CN': '體感約 {useFahrenheit}°',
      'zh-TW': '體感約 {useFahrenheit}°',
    } +
    {
      'en': 'App Log',
      'ja': 'アプリログ',
      'ko': '앱 로그',
      'ru': 'App 日誌',
      'vi': 'Nhật ký ứng dụng',
      'zh-CN': 'App 日志',
      'zh-TW': 'App 日誌',
    } +
    {
      'en': 'Unable to load the Change Log, Please Retry Later.',
      'ja': '変更履歴を読み込めませんでした。',
      'ko': '업데이트 로그를 불러올 수 없습니다. 나중에 다시 시도해 주세요.',
      'ru': '無法載入更新日誌，請稍後再試。',
      'vi': 'Không thể tải nhật ký thay đổi, vui lòng thử lại sau.',
      'zh-CN': '无法载入更新日志，请稍后再试。',
      'zh-TW': '無法載入更新日誌，請稍後再試。',
    } +
    {
      'en': 'Retry',
      'ja': '再試行',
      'ko': '다시 시도',
      'ru': '重試',
      'vi': 'Thử lại',
      'zh-CN': '重试',
      'zh-TW': '重試',
    } +
    {
      'en': 'Heavy Rain Advisory',
      'ja': 'リアルタイムの雷雨情報',
      'ko': '뇌우 재난 문자',
      'ru': '雷雨即時訊息',
      'vi': '雷雨即時訊息',
      'zh-CN': '雷雨即时信息',
      'zh-TW': '雷雨即時訊息',
    } +
    {
      'en': 'Precipitation',
      'ja': '降水量',
      'ko': '강우',
      'ru': '降水',
      'vi': 'Lượng mưa',
      'zh-CN': '降水',
      'zh-TW': '降水',
    } +
    {
      'en': 'Today',
      'ja': '今日',
      'ko': '오늘',
      'ru': '今日',
      'vi': 'Hôm nay',
      'zh-CN': '今天',
      'zh-TW': '今日',
    } +
    {
      'en': '10 Minutes',
      'ja': '10分間',
      'ko': '10분',
      'ru': '10 分鐘',
      'vi': '10 phút',
      'zh-CN': '10 分钟',
      'zh-TW': '10 分鐘',
    } +
    {
      'en': '1 Hours',
      'ja': '1時間',
      'ko': '1시간',
      'ru': '1 小時',
      'vi': '1 giờ',
      'zh-CN': '1 小时',
      'zh-TW': '1 小時',
    } +
    {
      'en': '3 Hours',
      'ja': '3時間',
      'ko': '3시간',
      'ru': '3 小時',
      'vi': '3 giờ',
      'zh-CN': '3 小时',
      'zh-TW': '3 小時',
    } +
    {
      'en': '6 Hours',
      'ja': '6時間',
      'ko': '6시간',
      'ru': '6 小時',
      'vi': '6 giờ',
      'zh-CN': '6 小时',
      'zh-TW': '6 小時',
    } +
    {
      'en': '12 Hours',
      'ja': '12時間',
      'ko': '12시간',
      'ru': '12 小時',
      'vi': '12 giờ',
      'zh-CN': '12 小时',
      'zh-TW': '12 小時',
    } +
    {
      'en': '24 Hours',
      'ja': '24時間',
      'ko': '24시간',
      'ru': '24 小時',
      'vi': '24 giờ',
      'zh-CN': '24 小时',
      'zh-TW': '24 小時',
    } +
    {
      'en': '2 Days',
      'ja': '2日間',
      'ko': '2일',
      'ru': '2 天',
      'vi': '2 ngày',
      'zh-CN': '2 天',
      'zh-TW': '2 天',
    } +
    {
      'en': '3 Days',
      'ja': '3日間',
      'ko': '3일',
      'ru': '3 天',
      'vi': '3 ngày',
      'zh-CN': '3 天',
      'zh-TW': '3 天',
    };

extension Localization on String {
  String get i18n => localize(this, _t);
}
