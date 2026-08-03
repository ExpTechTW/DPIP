// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get languageName => 'Bahasa Indonesia';

  @override
  String get navHome => 'Beranda';

  @override
  String get navEvents => 'Kejadian';

  @override
  String get navMap => 'Peta';

  @override
  String get navData => 'Data';

  @override
  String get navEarthquake => 'Gempa Bumi';

  @override
  String get dataSectionSeismic => 'Seismik';

  @override
  String get dataEarthquakeSubtitle => 'Laporan gempa';

  @override
  String get reportListEmpty => 'Tidak ada laporan gempa';

  @override
  String get reportListEmptyFiltered =>
      'Tidak ada laporan yang cocok dengan filter';

  @override
  String reportListMeta(String magnitude, String depth) {
    return 'M$magnitude · $depth km';
  }

  @override
  String get reportListEnd => 'Akhir daftar';

  @override
  String get reportFilterTitle => 'Filter';

  @override
  String get reportFilterIntensity => 'Intensitas';

  @override
  String get reportFilterMagnitude => 'Magnitudo';

  @override
  String get reportFilterDepth => 'Kedalaman';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get reportFilterDate => 'Tanggal';

  @override
  String get reportFilterDatePick => 'Pilih tanggal';

  @override
  String get reportFilterDateStartNote => 'Hari mulai: dari 00:00（Taipei）';

  @override
  String get reportFilterDateEndNote => 'Hari akhir: hingga 24:00（Taipei）';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportFilterLocation => 'Lokasi';

  @override
  String get reportFilterLocationHint => 'mis. Hualien, lepas pantai';

  @override
  String get reportFilterAny => 'Semua';

  @override
  String get reportFilterApply => 'Terapkan';

  @override
  String get reportFilterReset => 'Reset';

  @override
  String get reportListSearch => 'Cari';

  @override
  String get navMore => 'Lainnya';

  @override
  String get appLogs => 'Log aplikasi';

  @override
  String get mapPlaceholderDisabled => 'Peta (dinonaktifkan sementara)';

  @override
  String get moreSectionRegion => 'Wilayah';

  @override
  String get moreSectionNotify => 'Notifikasi';

  @override
  String get moreSectionDisplay => 'Tampilan';

  @override
  String get regionManageTitle => 'Wilayah tersimpan';

  @override
  String get regionAddButton => 'Tambah wilayah';

  @override
  String get regionEmpty => 'Belum ada wilayah tersimpan';

  @override
  String get regionSelectTitle => 'Pilih wilayah';

  @override
  String regionSelectCount(int count, int max) {
    return '$count/$max dipilih';
  }

  @override
  String regionSelectFull(int max) {
    return 'Anda dapat menyimpan hingga $max wilayah';
  }

  @override
  String get regionEdit => 'Ubah';

  @override
  String get moreSectionAdvanced => 'Lanjutan';

  @override
  String get moreDeveloper => 'Info debug';

  @override
  String get developerCopied => 'Disalin ke papan klip';

  @override
  String get developerCopyAll => 'Salin semua';

  @override
  String get experimentalFeatures => 'Fitur eksperimental';

  @override
  String get moreSectionLinks => 'Tautan';

  @override
  String get moreCwaEew => 'Peringatan dini gempa CWA';

  @override
  String get moreTremReport => 'Laporan deteksi TREM';

  @override
  String get moreServerStatus => 'Status server';

  @override
  String get moreAnnouncements => 'Pengumuman';

  @override
  String get moreDiscord => 'Komunitas Discord';

  @override
  String get moreNotifyLog => 'Log notifikasi DPIP';

  @override
  String get moreLinkOpenFailed => 'Tidak dapat membuka tautan';

  @override
  String get weatherDynamicState => 'Animasi cuaca';

  @override
  String get weatherDynamicStateSubtitle => 'Ganti cuaca latar beranda';

  @override
  String get weatherModeAuto => 'Otomatis';

  @override
  String get weatherModeClear => 'Cerah';

  @override
  String get weatherModeRain => 'Hujan';

  @override
  String get weatherModeFog => 'Kabut';

  @override
  String get weatherModeThunderstorm => 'Badai petir';

  @override
  String get commonLoading => 'Memuat…';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonError => 'Terjadi kesalahan';

  @override
  String get commonFetchFailed => 'Tidak dapat memuat data. Silakan coba lagi.';

  @override
  String get commonEmpty => 'Tidak ada yang ditampilkan';

  @override
  String get feedConnecting => 'Menghubungkan…';

  @override
  String get feedStale => 'Data mungkin sudah usang';

  @override
  String get feedOffline => 'Koneksi terputus';

  @override
  String get eewTitle => 'Peringatan dini gempa';

  @override
  String get eewNone => 'Tidak ada peringatan dini gempa aktif';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'M$magnitude · kedalaman $depth km';
  }

  @override
  String get regionNationwide => 'Seluruh negeri';

  @override
  String get regionCurrent => 'Lokasi saat ini';

  @override
  String get regionCurrentUnavailable =>
      'Tidak dapat memperoleh lokasi saat ini';

  @override
  String get weatherPrecipitation => 'Curah hujan';

  @override
  String get weatherHumidity => 'Kelembapan';

  @override
  String get mapLayers => 'Lapisan';

  @override
  String get mapLayerRadar => 'Radar Komposit';

  @override
  String get mapLayerSatellite => 'Himawari Inframerah';

  @override
  String get mapLayerLightning => 'Petir';

  @override
  String lightningLegendCg(int minutes) {
    return 'Awan–tanah · $minutes mnt';
  }

  @override
  String lightningLegendCc(int minutes) {
    return 'Awan–awan · $minutes mnt';
  }

  @override
  String get mapTimelineNow => 'Sekarang';

  @override
  String get mapTimelineObserved => 'Diamati';

  @override
  String get notifySettingsMenu => 'Pengaturan notifikasi';

  @override
  String get notifyTitle => 'Notifikasi';

  @override
  String get notifyUnavailable =>
      'Notifikasi push belum siap — coba lagi sebentar lagi.';

  @override
  String get notifySetFailed =>
      'Tidak dapat menyimpan pengaturan. Silakan coba lagi.';

  @override
  String get notifySectionEew => 'Peringatan dini gempa';

  @override
  String get notifySectionEarthquake => 'Gempa bumi';

  @override
  String get notifySectionWeather => 'Cuaca';

  @override
  String get notifySectionTsunami => 'Tsunami';

  @override
  String get notifySectionOther => 'Lainnya';

  @override
  String get notifyEew => 'Peringatan gempa darurat';

  @override
  String get notifyMonitor => 'Pemantau getaran kuat';

  @override
  String get notifyReport => 'Laporan gempa';

  @override
  String get notifyIntensity => 'Laporan intensitas';

  @override
  String get notifyThunderstorm => 'Peringatan badai petir';

  @override
  String get notifyAdvisory => 'Imbauan cuaca';

  @override
  String get notifyEvacuation => 'Informasi bencana';

  @override
  String get notifyTsunami => 'Informasi tsunami';

  @override
  String get notifyAnnouncement => 'Pengumuman';

  @override
  String get notifyOptOff => 'Nonaktif';

  @override
  String get notifyOptAll => 'Terima semua';

  @override
  String get notifyOptLocalIntensity4 => 'Intensitas lokal 4 atau lebih';

  @override
  String get notifyOptLocalIntensity1 => 'Intensitas lokal 1 atau lebih';

  @override
  String get notifyOptWeatherLocal => 'Hanya lokasi saat ini';

  @override
  String get notifyOptTsunamiWarning => 'Hanya peringatan tsunami';

  @override
  String get notifyOptTsunamiAll => 'Imbauan dan peringatan tsunami';

  @override
  String get onboardingNext => 'Berikutnya';

  @override
  String get onboardingBack => 'Kembali';

  @override
  String get onboardingScrollHint => 'Gulir ke bawah untuk melanjutkan';

  @override
  String get onboardingIntroTitle => 'Selamat datang di DPIP';

  @override
  String get onboardingIntroBody =>
      'DPIP adalah pendamping pencegahan bencana Anda. DPIP menyatukan peringatan dini gempa, laporan gempa, cuaca, dan informasi bahaya, serta memberi tahu Anda pada saat yang penting.\n\n• Gempa bumi: peringatan dini, laporan intensitas, dan laporan rinci\n• Cuaca: pesan badai petir waktu nyata dan imbauan cuaca\n• Tsunami dan informasi bencana\n\nSelanjutnya, kami akan meminta Anda meninjau Ketentuan Layanan dan memberikan beberapa izin agar DPIP dapat melindungi Anda secara waktu nyata.';

  @override
  String get onboardingTermsTitle => 'Ketentuan Layanan';

  @override
  String get onboardingTermsBody =>
      'Harap baca pemberitahuan berikut sebelum menggunakan DPIP:\n\n• Semua informasi harus mengacu pada konten yang diterbitkan oleh Central Weather Administration (CWA) Taiwan.\n\n• Bergantung pada kondisi jaringan, server, aplikasi, dan sumber data hulu, informasi mungkin tidak diterima; kami berupaya sebaik mungkin untuk menghindari hal ini tetapi tidak dapat menjamin bahwa hal itu tidak akan pernah terjadi.\n\n• Guncangan kuat dapat mencapai lokasi Anda sebelum notifikasi tiba.\n\n• Peringatan dini gempa adalah hasil perhitungan cepat yang mungkin mengandung kesalahan yang signifikan — pahami hal ini dan gunakan dengan hati-hati.\n\n• Setiap tindakan yang tidak disahkan oleh pihak berwenang dapat menimbulkan risiko hukum; harap patuhi semua peraturan yang berlaku.\n\nSelain itu, untuk menyediakan peringatan yang dilokalkan, layanan ini mengumpulkan dan mengunggah perkiraan lokasi Anda dan pengidentifikasi push — di latar depan maupun latar belakang — semata-mata untuk menentukan peringatan mana yang akan dikirimkan kepada Anda.\n\nDengan mengetuk \"Setuju dan lanjutkan\", Anda mengonfirmasi bahwa Anda telah membaca, memahami, dan menyetujui hal-hal di atas.';

  @override
  String get onboardingTermsAgree =>
      'Saya telah membaca dan menyetujui Ketentuan Layanan';

  @override
  String get onboardingAgreeContinue => 'Setuju dan lanjutkan';

  @override
  String get onboardingPermsTitle => 'Izin';

  @override
  String get onboardingPermsBody =>
      'Agar DPIP dapat memperingatkan Anda saat bencana terjadi, harap berikan izin berikut. Anda dapat mengubahnya kapan saja di pengaturan sistem.';

  @override
  String get onboardingPermNotify => 'Notifikasi';

  @override
  String get onboardingPermNotifyDesc =>
      'Menyampaikan peringatan gempa, cuaca, dan bencana pada saat terjadi.';

  @override
  String get onboardingPermCritical => 'Peringatan kritis';

  @override
  String get onboardingPermCriticalDesc =>
      'Memungkinkan peringatan gempa yang mengancam jiwa tetap berbunyi bahkan dalam mode senyap atau Jangan Ganggu.';

  @override
  String get onboardingPermLocation => 'Lokasi';

  @override
  String get onboardingPermLocationDesc =>
      'Menargetkan peringatan ke lokasi Anda.';

  @override
  String get onboardingPermBackground => 'Lokasi latar belakang';

  @override
  String get onboardingPermBackgroundDesc =>
      'Izinkan \"Selalu\" agar peringatan tetap menargetkan Anda saat aplikasi ditutup.';

  @override
  String get onboardingPermBattery => 'Pengecualian baterai';

  @override
  String get onboardingPermBatteryDesc =>
      'Izinkan DPIP terus berjalan di latar belakang agar peringatan tidak tertunda atau terlewat.';

  @override
  String get onboardingGrant => 'Berikan';

  @override
  String get onboardingGranted => 'Diberikan';

  @override
  String get onboardingStart => 'Mulai';

  @override
  String get language => 'Bahasa';

  @override
  String get languageSettings => 'Bahasa';

  @override
  String get languageSystem => 'Bawaan sistem';

  @override
  String get locationBannerServiceOff =>
      'Layanan lokasi mati — peringatan lokal tidak dapat menargetkan wilayah Anda.';

  @override
  String get locationBannerPermission =>
      'Izin lokasi mati — peringatan lokal tidak dapat menargetkan wilayah Anda.';

  @override
  String get locationBannerFix => 'Buka pengaturan';

  @override
  String get notifyBannerDisabled =>
      'Notifikasi mati — Anda tidak akan menerima peringatan bencana.';

  @override
  String get onboardingSkipTitle => 'Izin belum diberikan';

  @override
  String get onboardingSkipBody =>
      'Tanpa lokasi dan notifikasi, DPIP tidak dapat memperingatkan Anda tentang gempa dan bencana di sekitar Anda secara waktu nyata. Anda masih dapat memberikannya nanti di Pengaturan.';

  @override
  String get onboardingSkipStay => 'Kembali';

  @override
  String get onboardingSkipLeave => 'Tetap lewati';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get moreSourceCode => 'Kode sumber';

  @override
  String get moreSectionApp => 'Dapatkan aplikasi';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get displaySettings => 'Tampilan';

  @override
  String get displayTheme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get moreSectionAbout => 'Tentang';

  @override
  String get termsOfService => 'Ketentuan Layanan';

  @override
  String get faq => 'FAQ';

  @override
  String get openSourceLicenses => 'Lisensi sumber terbuka';

  @override
  String get sponsorTitle => 'Dukung DPIP';

  @override
  String get sponsorIntro =>
      'DPIP berdedikasi menyediakan informasi mitigasi bencana secara real-time, tanpa iklan atau model bisnis lainnya. Dukungan Anda membantu kami menjaga server tetap berjalan dan terus mengembangkan aplikasi.';

  @override
  String get sponsorSubscriptions => 'Langganan';

  @override
  String get sponsorRecommended => 'Direkomendasikan';

  @override
  String get sponsorOneTime => 'Sekali bayar';

  @override
  String sponsorPerMonth(String price) {
    return '$price / bulan';
  }

  @override
  String get sponsorRestore => 'Pulihkan pembelian';

  @override
  String get sponsorTerms => 'Ketentuan Penggunaan';

  @override
  String get sponsorPrivacy => 'Kebijakan Privasi';

  @override
  String get sponsorRestoring => 'Memulihkan pembelian…';

  @override
  String get sponsorRestoreUnavailable =>
      'Tidak dapat terhubung ke toko. Coba lagi nanti.';

  @override
  String get commonClose => 'Tutup';

  @override
  String get mapLayerTemperature => 'Suhu';

  @override
  String get trendRange24h => '24 jam';

  @override
  String get trendRange7d => '7 hari';

  @override
  String get trendNoData => 'Tidak ada data tren';

  @override
  String chartHourLabel(int hour) {
    return '${hour}j';
  }

  @override
  String get mapLayerHumidity => 'Kelembapan';

  @override
  String get mapLayerPressure => 'Tekanan';

  @override
  String get mapLayerWind => 'Angin';

  @override
  String get mapLayerRain => 'Curah hujan';

  @override
  String get rainIntervalMenu => 'Jendela akumulasi';

  @override
  String get rainIntervalNow => 'Hari ini';

  @override
  String get rainInterval10m => '10 mnt';

  @override
  String get rainInterval1h => '1 jam';

  @override
  String get rainInterval3h => '3 jam';

  @override
  String get rainInterval6h => '6 jam';

  @override
  String get rainInterval12h => '12 jam';

  @override
  String get rainInterval24h => '24 jam';

  @override
  String get rainInterval2d => '2 hr';

  @override
  String get rainInterval3d => '3 hr';

  @override
  String get mapLayerTyphoon => 'Topan';

  @override
  String get typhoonNoActive => 'Tidak ada topan aktif';

  @override
  String get typhoonWind => 'Angin';

  @override
  String get typhoonGust => 'Embusan';

  @override
  String get typhoonPressure => 'Tekanan';

  @override
  String get typhoonMotion => 'Bergerak';

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
  String get mapLayerMonitor => 'Monitor Seismik';

  @override
  String get mapLayerDisasterMap => 'Peta Bencana';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get disasterMapOverlayMenuTooltip => 'Lapisan peta bencana';

  @override
  String get disasterMapOverlaySectionLayers => 'Lapisan';

  @override
  String get disasterMapOverlayAedTooltip => 'Tampilkan lokasi AED';

  @override
  String get aedSheetEmpty => 'Ketuk penanda AED untuk detail';

  @override
  String get aedAddress => 'Alamat';

  @override
  String get aedRegion => 'Wilayah';

  @override
  String get aedCategory => 'Kategori';

  @override
  String get aedType => 'Jenis';

  @override
  String get aedPlaceDesc => 'Lokasi peletakan';

  @override
  String get aedDescription => 'Catatan';

  @override
  String get aedHoursWeekday => 'Jam hari kerja';

  @override
  String get aedHoursSaturday => 'Jam Sabtu';

  @override
  String get aedHoursSunday => 'Jam Minggu';

  @override
  String get aedOpenRemark => 'Catatan jam buka';

  @override
  String get aedEmergencyPhone => 'Telepon darurat';

  @override
  String get stationSheetEmpty => 'Ketuk stasiun untuk melihat bacaannya';

  @override
  String monitorDelay(String value) {
    return 'Latensi $value s';
  }

  @override
  String get monitorWaiting => 'Menunggu data…';

  @override
  String mapLegendUnit(String unit) {
    return 'Satuan: $unit';
  }

  @override
  String get typhoonLegendPast => 'Jalur aktual';

  @override
  String get typhoonIntensityTd => 'Tropical depression';

  @override
  String get typhoonIntensityMild => 'Mild typhoon';

  @override
  String get typhoonIntensityModerate => 'Moderate typhoon';

  @override
  String get typhoonIntensityIntense => 'Intense typhoon';

  @override
  String get typhoonLegendForecast => 'Jalur prakiraan';

  @override
  String get typhoonLegendForecastPoint => 'Titik prakiraan';

  @override
  String get typhoonLegendCurrent => 'Pusat saat ini';

  @override
  String get typhoonLegendCone => 'Kerucut prakiraan';

  @override
  String get mapLegendExpand => 'Legenda';

  @override
  String get mapLegendCollapse => 'Sembunyikan legenda';

  @override
  String get typhoonLegendCircle15 => 'Lingkar angin kencang';

  @override
  String get typhoonLegendCircleAvg => 'Average circle';

  @override
  String get typhoonLegendCircle25 => 'Lingkar badai';

  @override
  String typhoonStormRadii(String ne, String se, String sw, String nw) {
    return 'NE $ne · SE $se · SW $sw · NW $nw km';
  }

  @override
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get typhoonLegendProbability => 'Probabilitas serangan';

  @override
  String get typhoonLegendWarningAreas => 'Area peringatan';

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
  String get typhoonWarningTitle => 'Peringatan topan';

  @override
  String typhoonWarningAreas(String areas) {
    return 'Wilayah: $areas';
  }

  @override
  String get typhoonTrackDetail => 'Detail jalur';

  @override
  String get typhoonHistoryTitle => 'Waktu data';

  @override
  String get typhoonHistoryLive => 'Langsung';

  @override
  String get typhoonSatelliteTitle => 'Satelit';

  @override
  String get typhoonOverlayForecastCallouts => 'Forecast tooltips';

  @override
  String get typhoonOverlayForecastCalloutsTooltip =>
      'Show forecast-point detail cards when zoomed in';
}
