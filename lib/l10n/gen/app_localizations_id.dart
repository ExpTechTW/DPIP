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
  String get navEarthquake => 'Gempa Bumi';

  @override
  String get navMore => 'Lainnya';

  @override
  String get appLogs => 'Log aplikasi';

  @override
  String get mapPlaceholderDisabled => 'Peta (dinonaktifkan sementara)';

  @override
  String get moreSectionGeneral => 'Umum';

  @override
  String get regionManageTitle => 'Wilayah tersimpan';

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
  String get moreSectionAdvanced => 'Lanjutan';

  @override
  String get moreDeveloper => 'Pengaturan pengembang';

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
  String get mapLayerRadar => 'Radar';

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
}
