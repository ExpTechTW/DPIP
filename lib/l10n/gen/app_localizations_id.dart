// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String typhoonValueLat(String lat) {
    return '$lat°N';
  }

  @override
  String get onboardingSkipBody =>
      'Tanpa lokasi dan notifikasi, DPIP tidak dapat memperingatkan Anda tentang gempa dan bencana di sekitar Anda secara waktu nyata. Anda masih dapat memberikannya nanti di Pengaturan.';

  @override
  String get rainInterval24h => '24 jam';

  @override
  String homeRainTrendHeavyStopping(int minutes) {
    return 'Hujan deras diperkirakan berhenti dalam $minutes menit';
  }

  @override
  String get mapTimelineObserved => 'Diamati';

  @override
  String get mapTimelineScrubPaused =>
      'Geseran terlalu cepat sehingga pembaruan bingkai dijeda. Perlambat untuk melanjutkan.';

  @override
  String get regionSelectTitle => 'Pilih wilayah';

  @override
  String get skyTimeNoon => 'Siang';

  @override
  String get radarCountyOutlineSubtitle =>
      'Menjaga batas wilayah tetap terbaca di bawah gema radar.';

  @override
  String get mapLayerSatelliteB03 => 'Himawari Red (B03)';

  @override
  String get reportFilterIntensity => 'Intensitas';

  @override
  String get mapLayerLightning => 'Petir';

  @override
  String get restroomTypeMale => 'Toilet pria';

  @override
  String get meshtasticLastReceived => 'Terakhir diterima';

  @override
  String get reportDetailSortByCounty => 'Urutkan menurut wilayah';

  @override
  String get onboardingPermUnusedApp => 'Jaga aplikasi tetap aktif';

  @override
  String get onboardingPermUnusedAppDesc =>
      'Android menjeda aplikasi yang lama tidak Anda buka dan mencabut izinnya, sehingga peringatan bencana tidak sampai ke wilayah Anda.';

  @override
  String get onboardingPermBackgroundExec => 'Aktivitas latar belakang';

  @override
  String get onboardingPermBackgroundExecDesc =>
      'Jika mati, aplikasi tidak dibangunkan untuk melaporkan lokasi Anda.';

  @override
  String get onboardingPermVendorPower => 'Pengaturan baterai produsen';

  @override
  String onboardingPermVendorPowerDesc(String brand) {
    return '$brand menghentikan kerja latar belakang aplikasi yang belum Anda buka baru-baru ini. Aplikasi tidak dapat mendeteksi atau mengubahnya — mohon izinkan secara manual.';
  }

  @override
  String get homeRainTrendScattered => 'Kemungkinan hujan ringan';

  @override
  String get meshtasticUptime => 'Waktu aktif';

  @override
  String get weatherRankingTempExtremes => 'Ekstrem suhu';

  @override
  String get themeLight => 'Terang';

  @override
  String get mapTerrainReliefHint => 'Tampilkan relief terrain di peta dasar';

  @override
  String get meshtasticEmptyMessage => '(pesan kosong)';

  @override
  String get moreSectionRegion => 'Wilayah';

  @override
  String get mapLayerSatellite => 'Himawari Infrared (B13)';

  @override
  String get aedHoursSaturday => 'Jam Sabtu';

  @override
  String get moonPhaseNew => 'Bulan baru';

  @override
  String get notifySectionEew => 'Peringatan dini gempa';

  @override
  String get mapResetNorth => 'Kembali ke utara';

  @override
  String get rainInterval2d => '2 hr';

  @override
  String get mapTownLabelsHint => 'Tampilkan nama kecamatan saat diperbesar';

  @override
  String get commonCancel => 'Batal';

  @override
  String get notifyOptTsunamiWarning => 'Hanya peringatan tsunami';

  @override
  String get mapLayerSatelliteBtdFog => 'Himawari Night Fog';

  @override
  String get moreSectionAdvanced => 'Lanjutan';

  @override
  String get moreSectionMesh => 'Jaringan mesh';

  @override
  String get weatherRankingExtremeRange => 'Rentang harian';

  @override
  String get permissionsTitle => 'Pemeriksaan izin';

  @override
  String get permissionsAttention => 'Izin perlu ditangani';

  @override
  String get permissionsBody =>
      'DPIP memerlukan izin ini untuk memberi peringatan tepat waktu. Peringatan yang tidak muncul biasanya karena salah satunya belum diberikan.';

  @override
  String get notifySettingsMenu => 'Pengaturan notifikasi';

  @override
  String mapAppDefault(String app) {
    return '$app (bawaan)';
  }

  @override
  String get trendRange24h => '24 jam';

  @override
  String get mapLayerStyleJmaTooltip =>
      'Basis grayscale, diwarnai di bawah −40 °C untuk menyorot tinggi puncak awan';

  @override
  String get mapLayerRain => 'Curah hujan';

  @override
  String get mapLayerQpesums => 'Prakiraan hujan 1 jam ke depan';

  @override
  String get mapOverlaySectionMap => 'Peta';

  @override
  String get mapTerrainRelief => 'Relief terrain';

  @override
  String get mapLegendCollapse => 'Sembunyikan legenda';

  @override
  String get updateAvailableTitle => 'Versi baru tersedia';

  @override
  String updateAvailableBody(String version) {
    return 'Versi $version sudah dirilis.';
  }

  @override
  String get updateSkip => 'Lewati kali ini';

  @override
  String get updateViewChangelog => 'Lihat perubahan';

  @override
  String get updateOpenAppStore => 'App Store';

  @override
  String get updateOpenTestFlight => 'TestFlight';

  @override
  String get updateOpenPlayStore => 'Play Store';

  @override
  String get updateDownload => 'Unduh';

  @override
  String get changelogShowSnapshots => 'Tampilkan snapshot';

  @override
  String get changelogTitle => 'Catatan pembaruan';

  @override
  String get reportFilterOrderDesc => 'Menurun';

  @override
  String get meshtasticExcludeMqttSubtitle =>
      'Node yang terhubung lewat internet, tidak terdengar lewat radio';

  @override
  String get reportFilterIntensityInfoTitle => 'Skala intensitas baru & lama';

  @override
  String get mapLayerTyphoon => 'Topan';

  @override
  String get radarOverlayMenuTooltip => 'Opsi lapisan radar';

  @override
  String get meshtasticNodes => 'Node';

  @override
  String get meshtasticSend => 'Kirim';

  @override
  String get typhoonOverlayStormL7Tooltip =>
      'Medan angin level 7 + lingkaran rata-rata (ungu)';

  @override
  String get aedType => 'Jenis';

  @override
  String get termsOfService => 'Ketentuan Layanan';

  @override
  String get typhoonLegendCircle25 => 'Lingkar badai';

  @override
  String get sponsorTitle => 'Dukung DPIP';

  @override
  String get mapNavSatellite => 'Satelit';

  @override
  String homeRainTrendUpdated(String time) {
    return 'Diperbarui $time';
  }

  @override
  String get onboardingNext => 'Berikutnya';

  @override
  String get weatherRankingMergeTown => 'Kecamatan';

  @override
  String get mapLayerMonitor => 'Monitor Seismik';

  @override
  String get moreYoutube => 'YouTube';

  @override
  String get sponsorSubscriptions => 'Langganan';

  @override
  String typhoonValueLon(String lon) {
    return '$lon°E';
  }

  @override
  String get skyTime => 'Waktu langit';

  @override
  String get weatherModeCloudy => 'Berawan';

  @override
  String get skyTimeDusk => 'Senja';

  @override
  String get meshtasticFirmware => 'Firmware';

  @override
  String get reportFilterDateEndNote => 'Hari akhir: hingga 24:00（Taipei）';

  @override
  String get reportFilterSortMagnitude => 'Magnitudo';

  @override
  String get meshtasticSilent => 'Senyap';

  @override
  String get mapLayerCategoryEarthquake => 'Gempa';

  @override
  String get mapLayerSatelliteB12 => 'Himawari Ozone (B12)';

  @override
  String get restroomCategoryOther => 'Lainnya';

  @override
  String homeForecastHighLow(String high, String low) {
    return 'T $high° · R $low°';
  }

  @override
  String get locationBannerFix => 'Buka pengaturan';

  @override
  String get mapLegendExpand => 'Legenda';

  @override
  String get eewNone => 'Tidak ada peringatan dini gempa aktif';

  @override
  String typhoonTyNo(String no) {
    return 'TY $no';
  }

  @override
  String get notifyOptTsunamiAll => 'Imbauan dan peringatan tsunami';

  @override
  String get meshtasticLayerOptions => 'Opsi node';

  @override
  String get onboardingAgreeContinue => 'Setuju dan lanjutkan';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get meshtasticNodeId => 'ID Node';

  @override
  String reportDetailNumbered(String number) {
    return 'Gempa Dirasakan Signifikan No. $number';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => 'Dengan lingkaran rata-rata';

  @override
  String get disasterMapOverlayRestroomTooltip => 'Tampilkan toilet umum';

  @override
  String get weatherRankingTitle => 'Peringkat observasi';

  @override
  String get homeRainTrendHeavySustained =>
      'Hujan deras berlanjut selama 1 jam ke depan';

  @override
  String get notifySectionTsunami => 'Tsunami';

  @override
  String get restroomCategoryPark => 'Taman';

  @override
  String get moreLinkOpenFailed => 'Tidak dapat membuka tautan';

  @override
  String get themeDark => 'Gelap';

  @override
  String get sponsorRestore => 'Pulihkan pembelian';

  @override
  String get meshtasticChannelWorking => 'Menyiapkan kanal DPIP…';

  @override
  String get meshtasticRegionSwitch => 'Beralih ke TW';

  @override
  String get meshtasticTraffic => 'Lalu lintas';

  @override
  String get mapLayerStyleBdTooltip =>
      'Dvorak BD curve — the stepped grayscale for tropical-cyclone intensity analysis';

  @override
  String get disasterMapOverlayAedTooltip => 'Tampilkan lokasi AED';

  @override
  String get mapLayerHumidity => 'Kelembapan';

  @override
  String get mapLayerSatelliteTransparentNight =>
      'Malam = transparan, peta dasar terlihat';

  @override
  String get meshtasticScanning => 'Memindai…';

  @override
  String regionSelectFull(int max) {
    return 'Anda dapat menyimpan hingga $max wilayah';
  }

  @override
  String get meshtasticNewMessages => 'BARU';

  @override
  String get meshtasticBatteryHistory => 'Riwayat baterai';

  @override
  String get meshtasticStatAvg => 'rata²';

  @override
  String get meshtasticStatPeak => 'puncak';

  @override
  String get meshtasticStatDrain => 'pengurasan';

  @override
  String get meshtasticStatEta => 'bertahan';

  @override
  String get meshtasticStatFull => 'penuh dalam';

  @override
  String get meshtasticStatTrend => 'tren';

  @override
  String get meshtasticStatCharging => 'mengisi daya';

  @override
  String get meshtasticStatStable => 'stabil';

  @override
  String get meshtasticNodesTotal => 'Dikenal';

  @override
  String get meshtasticNodesOnline => 'Daring';

  @override
  String get meshtasticRx => 'Diterima';

  @override
  String get meshtasticTx => 'Terkirim';

  @override
  String get meshtasticNodesHistory => 'Riwayat node';

  @override
  String get meshtasticTrafficHistory => 'Riwayat lalu lintas';

  @override
  String meshtasticEtaHours(int n) {
    return '~$n jam';
  }

  @override
  String meshtasticEtaDays(int n) {
    return '~$n hari';
  }

  @override
  String get meshtasticTitle => 'Meshtastic';

  @override
  String get navMore => 'Lainnya';

  @override
  String get meshtasticDpipChannel => 'Kanal DPIP';

  @override
  String get disasterMapOverlaySectionLayers => 'Lapisan';

  @override
  String get mapLayerSatelliteB05 => 'Himawari Near-Infrared (B05)';

  @override
  String get typhoonLabelNe => 'NE';

  @override
  String get meshtasticCopied => 'Pesan disalin';

  @override
  String get reportListEmpty => 'Tidak ada laporan gempa';

  @override
  String get reportListEnd => 'Akhir daftar';

  @override
  String get mapLayerSatelliteTruecolor => 'Himawari True Color';

  @override
  String get typhoonOverlaySectionExtra => 'Lapisan tambahan';

  @override
  String get eewSWave => 'Gelombang S';

  @override
  String get meshtasticBusyTitle =>
      'Aplikasi lain sedang menggunakan radio ini';

  @override
  String get restroomCategoryCultural => 'Tempat budaya';

  @override
  String get typhoonLabelWind => 'Angin bertahan maks. dekat pusat';

  @override
  String get radarGlobalOutlineHint => 'Bingkai luar setiap negara';

  @override
  String get notifyEvacuation => 'Informasi bencana';

  @override
  String get typhoonLegendCircle15 => 'Lingkar angin kencang';

  @override
  String get dataSectionAstronomy => 'Astronomi';

  @override
  String get homeRainTrendLightSustained =>
      'Hujan ringan berlanjut selama 1 jam ke depan';

  @override
  String get commonError => 'Terjadi kesalahan';

  @override
  String get moonPhaseWaningCrescent => 'Bulan sabit memudar';

  @override
  String get meshtasticPower => 'Daya';

  @override
  String get mapTimelineNow => 'Sekarang';

  @override
  String reportFilterRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get reportDetailOpenReport => 'Halaman laporan';

  @override
  String get trendRange7d => '7 hari';

  @override
  String typhoonWarningAreas(String areas) {
    return 'Wilayah: $areas';
  }

  @override
  String get rainIntervalSection => 'Jendela waktu';

  @override
  String get notifyTitle => 'Notifikasi';

  @override
  String get meshtasticTxPower => 'Daya TX';

  @override
  String get restroomCategoryLabel => 'Kategori';

  @override
  String get sponsorRestoring => 'Memulihkan pembelian…';

  @override
  String get sponsorIntro =>
      'DPIP berdedikasi menyediakan informasi mitigasi bencana secara real-time, tanpa iklan atau model bisnis lainnya. Dukungan Anda membantu kami menjaga server tetap berjalan dan terus mengembangkan aplikasi.';

  @override
  String get typhoonLabelStormAvg => 'Jari-jari rata-rata angin Beaufort 10';

  @override
  String get restroomCategoryCommercial => 'Tempat komersial';

  @override
  String get aedRegion => 'Wilayah';

  @override
  String homeRainTrendLightStopping(int minutes) {
    return 'Hujan ringan diperkirakan berhenti dalam $minutes menit';
  }

  @override
  String get reportDetailInfo => 'Detail';

  @override
  String get mapNavWind => 'Angin';

  @override
  String get windForecastOverlayMenuTooltip => 'Opsi lapisan prakiraan angin';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute mnt';
  }

  @override
  String get rainInterval6h => '6 jam';

  @override
  String get restroomTypeUnspecified => 'Tidak ditentukan';

  @override
  String get typhoonOverlayProbabilityHint =>
      'Menyembunyikan kerucut prakiraan';

  @override
  String get mapLayerSatelliteGlobalOutline => 'Batas negara';

  @override
  String get mapNavTemperature => 'Suhu';

  @override
  String get typhoonLegendForecastPoint => 'Titik prakiraan';

  @override
  String get reportListYesterday => 'Kemarin';

  @override
  String get moreSectionLinks => 'Tautan';

  @override
  String get feedOffline => 'Koneksi terputus';

  @override
  String get mapLayerStyleBd => 'Dvorak BD';

  @override
  String get moreSectionDisplay => 'Tampilan';

  @override
  String get rainInterval3d => '3 hr';

  @override
  String get defaultMapLayerSubtitle =>
      'Tab Peta membuka lapisan ini. Ikon dan label navigasi bawah ikut pilihan ini.';

  @override
  String get aedDescription => 'Catatan';

  @override
  String get typhoonOverlayWeatherRadarTooltip =>
      'Gema radar terdekat dengan waktu buletin topan';

  @override
  String get onboardingPermLocationDesc =>
      'Menargetkan peringatan ke lokasi Anda.';

  @override
  String get mapLayerSatelliteB16 => 'Himawari CO₂ (B16)';

  @override
  String get homeActiveEventsEmpty => 'Tidak ada peristiwa aktif';

  @override
  String get typhoonLabelPosition => 'Lokasi pusat';

  @override
  String get weatherRankingBy => 'Urut';

  @override
  String get typhoonIntensityMild => 'Topan lemah';

  @override
  String get windForecastGlobalOutlineHint => 'Bingkai luar setiap negara';

  @override
  String get rainInterval1h => '1 jam';

  @override
  String get eewLocalIntensity => 'Perkiraan di lokasi';

  @override
  String get mapLayerRadar => 'Radar Komposit';

  @override
  String get restroomCategoryReligious => 'Tempat ibadah';

  @override
  String get meshtasticRole => 'Peran';

  @override
  String get mapLayerSatelliteCloudCloudy => 'Cloudy';

  @override
  String get skyTimeSunrise => 'Matahari terbit';

  @override
  String get meshtasticJumpToLatest => 'Ke yang terbaru';

  @override
  String get meshtasticNoMessages => 'Belum ada pesan';

  @override
  String get onboardingPermNotifyDesc =>
      'Menyampaikan peringatan gempa, cuaca, dan bencana pada saat terjadi.';

  @override
  String get radarTownOutline => 'Batas kecamatan';

  @override
  String get mapLayerStyleSection => 'Gaya warna';

  @override
  String get disasterMapOverlayMenuTooltip => 'Lapisan peta bencana';

  @override
  String get moreGooglePlay => 'Google Play';

  @override
  String get meshtasticOnline => 'Baru terdengar';

  @override
  String get typhoonLabelSw => 'SW';

  @override
  String typhoonForecastLead(String hours) {
    return 'Prakiraan +$hours jam';
  }

  @override
  String get changelogTypeStable => 'Stabil';

  @override
  String get mapLayerSatelliteTransparentClear =>
      'Langit cerah = transparan, peta dasar terlihat';

  @override
  String get mapOverlaySectionReference => 'Lapisan referensi';

  @override
  String get mapLayerSatelliteB02 => 'Himawari Green (B02)';

  @override
  String get weatherRankingEmpty => 'Tidak ada observasi untuk diurutkan';

  @override
  String get notifySectionOther => 'Lainnya';

  @override
  String weatherRankingMeta(String time, int count) {
    return 'Waktu data: $time\n$count stasiun';
  }

  @override
  String get onboardingTermsAgree =>
      'Saya telah membaca dan menyetujui Ketentuan Layanan';

  @override
  String get mapLayerSatelliteTransparentNoVegetation =>
      'Below 0.1 = transparent (no vegetation)';

  @override
  String get notifyOptLocalIntensity4 => 'Intensitas lokal 4 atau lebih';

  @override
  String get eewArrived => 'Tiba';

  @override
  String get meshtasticNoDevices => 'Tidak menemukan perangkat Meshtastic';

  @override
  String get mapLayerCategoryLife => 'Kehidupan sehari-hari';

  @override
  String get reportFilterSortIntensity => 'Intensitas';

  @override
  String get meshtasticStateDisconnected => 'Terputus';

  @override
  String get typhoonIntensityIntense => 'Topan kuat';

  @override
  String get mapLayerOrderTitle => 'Urutkan lapisan';

  @override
  String get mapLayerShow => 'Tampilkan lapisan';

  @override
  String get mapLayerHide => 'Sembunyikan lapisan';

  @override
  String get mapLayerShowAll => 'Tampilkan semua';

  @override
  String get mapLayerHideAll => 'Sembunyikan semua';

  @override
  String get dpmYes => 'Ya';

  @override
  String get meshtasticNoHistory => 'Riwayat belum cukup';

  @override
  String get reportDetailLocalIntensityUnavailable =>
      'Tidak ada data intensitas';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportFilterDepth => 'Kedalaman';

  @override
  String get onboardingScrollHint => 'Gulir ke bawah untuk melanjutkan';

  @override
  String get mapNavQpesums => 'Prakiraan';

  @override
  String get notifyAdvisory => 'Imbauan cuaca';

  @override
  String get reportFilterReset => 'Atur ulang';

  @override
  String get mapLayerSatelliteMndwi => 'Himawari MNDWI';

  @override
  String get typhoonOverlaySectionStorm => 'Angin badai';

  @override
  String get moonPhaseFull => 'Bulan purnama';

  @override
  String meshtasticBinaryPayload(String size) {
    return 'Data biner · $size';
  }

  @override
  String get moonPhaseWaningGibbous => 'Bulan cembung memudar';

  @override
  String get reportFilterIntensityInfoModernTitle => 'Baru (sejak 2020)';

  @override
  String typhoonDataTime(String time) {
    return 'Waktu data';
  }

  @override
  String get restroomTypeAccessible => 'Toilet aksesibel';

  @override
  String get moreSectionAbout => 'Tentang';

  @override
  String get meshtasticSelectDevice => 'Pilih radio';

  @override
  String get onboardingIntroBody =>
      'DPIP adalah pendamping pencegahan bencana Anda. DPIP menyatukan peringatan dini gempa, laporan gempa, cuaca, dan informasi bahaya, serta memberi tahu Anda pada saat yang penting.\n\n• Gempa bumi: peringatan dini, laporan intensitas, dan laporan rinci\n• Cuaca: pesan badai petir waktu nyata dan imbauan cuaca\n• Tsunami dan informasi bencana\n\nSelanjutnya, kami akan meminta Anda meninjau Ketentuan Layanan dan memberikan beberapa izin agar DPIP dapat melindungi Anda secara waktu nyata.';

  @override
  String get shelterCapacityLabel => 'Kapasitas';

  @override
  String get reportDetailImage => 'Gambar laporan';

  @override
  String get meshtasticStateConfiguring => 'Mengonfigurasi…';

  @override
  String get typhoonLabelGaleAvg => 'Jari-jari rata-rata angin Beaufort 7';

  @override
  String get onboardingPermNotify => 'Notifikasi';

  @override
  String get meshtasticClearMessages => 'Hapus pesan';

  @override
  String get meshtasticNotifyMessages => 'Beri tahu saat pesan baru';

  @override
  String get defaultMapLayerSettings => 'Lapisan peta bawaan';

  @override
  String get eewSourceSettings => 'Sumber EEW';

  @override
  String get eewSourceSubtitle =>
      'Pilih badan penerbit peringatan dini gempa yang ingin ditampilkan.';

  @override
  String get eewSourceAll => 'Semua sumber';

  @override
  String get eewSourceAllDescription =>
      'Tampilkan peringatan dini gempa dari semua badan penerbit.';

  @override
  String get eewSourceCwaOnly => 'Hanya CWA';

  @override
  String get eewSourceCwaOnlyDescription =>
      'Hanya tampilkan peringatan dini gempa yang diterbitkan oleh Badan Meteorologi Pusat Taiwan (CWA).';

  @override
  String get moreSectionNotify => 'Notifikasi';

  @override
  String get notifyUnavailable =>
      'Notifikasi push belum siap — coba lagi sebentar lagi.';

  @override
  String get mapLayerOrderReset => 'Atur ulang urutan';

  @override
  String get weatherRankingMergeCounty => 'Kabupaten';

  @override
  String get moreSectionApp => 'Dapatkan aplikasi';

  @override
  String get moreSectionBeta => 'Versi uji';

  @override
  String get moreAndroidBeta => 'Versi uji Android';

  @override
  String get moreTestFlight => 'Versi uji iOS (TestFlight)';

  @override
  String get moreSectionPartners => 'Mitra';

  @override
  String get morePartnersNote =>
      'Urut sesuai waktu kemitraan. Terima kasih kepada para individu dan perusahaan yang berkontribusi pada penanggulangan bencana; kontribusi mereka membuat DPIP menjadi mungkin.';

  @override
  String get morePartnerGeoscience => 'Geoscience';

  @override
  String get morePartnerTwds => 'TWDS';

  @override
  String get reportFilterIntensityInfoLegacyBody =>
      'Hanya tingkat 0–7, tanpa pemisahan 5−/5+/6−/6+.';

  @override
  String get mapLayerSatelliteSst => 'Himawari Sea Surface Temperature';

  @override
  String get qpesumsOverlayMenuTooltip => 'Opsi lapisan prakiraan curah hujan';

  @override
  String get mapTimelineFuture => 'Mendatang';

  @override
  String get typhoonLegendCircleAvg => 'Lingkaran rata-rata';

  @override
  String reportFilterDepthKm(String depth) {
    return '$depth km';
  }

  @override
  String get typhoonLabelSe => 'SE';

  @override
  String get radarTownOutlineHint => 'Kisi yang lebih rapat';

  @override
  String eewCountdown(int seconds) {
    return '$seconds detik';
  }

  @override
  String get typhoonLabelGust => 'Embusan puncak';

  @override
  String get mapAppGoogleMaps => 'Google Maps';

  @override
  String get sponsorTerms => 'Ketentuan Penggunaan';

  @override
  String get restroomTypeGenderNeutral => 'Toilet netral gender';

  @override
  String get notifyThunderstorm => 'Peringatan badai petir';

  @override
  String get skyTimeGolden => 'Jam emas';

  @override
  String get moonAge => 'Umur bulan';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable => 'Pilih wilayah untuk melihat prakiraan';

  @override
  String get mapLayers => 'Lapisan';

  @override
  String get meshtasticHardware => 'Perangkat keras';

  @override
  String get languageSettings => 'Bahasa';

  @override
  String get language => 'Bahasa';

  @override
  String homeForecastFeelsLike(String temp) {
    return 'Terasa $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => 'Diselaraskan dengan waktu buletin';

  @override
  String get skyTimeDawn => 'Fajar';

  @override
  String get skyTimeAfternoon => 'Sore';

  @override
  String get meshtasticLastHeard => 'Terakhir terdengar';

  @override
  String get typhoonWarningTitle => 'Peringatan topan';

  @override
  String get moreSourceCode => 'Kode sumber';

  @override
  String get mapLayerCategoryWeather => 'Pengamatan cuaca';

  @override
  String get mapLayerSatelliteB09 => 'Himawari Mid Water Vapour (B09)';

  @override
  String get windForecastTownOutlineHint => 'Jaring yang lebih halus';

  @override
  String get mapLayerSatelliteCloudmask => 'Himawari Cloud Mask';

  @override
  String get mapAppCopyCoordinates => 'Salin koordinat';

  @override
  String get reportFilterIntensityInfoIntro =>
      'CWA mengganti skala intensitas pada 1 Jan 2020 (waktu Taipei).';

  @override
  String get mapNavEarthquake => 'Gempa';

  @override
  String get restroomGradeAverage => 'Sedang';

  @override
  String get mapLayerSatelliteBtdCo2 => 'Himawari Cirrus / Cloud Height';

  @override
  String get onboardingPermBackgroundDesc =>
      'Izinkan \"Selalu\" agar peringatan tetap menargetkan Anda saat aplikasi ditutup.';

  @override
  String get mapTimelineForecast => 'Prakiraan';

  @override
  String get restroomTypeLabel => 'Jenis';

  @override
  String get navEarthquake => 'Gempa Bumi';

  @override
  String get typhoonOverlayStormL10Tooltip =>
      'Medan angin level 10 + lingkaran rata-rata (kuning)';

  @override
  String get moonPhaseWaxingGibbous => 'Bulan cembung membesar';

  @override
  String get reportDetailTitle => 'Laporan Gempa';

  @override
  String get moreTremReport => 'Laporan deteksi TREM';

  @override
  String weatherDataTime(String station, String time) {
    return '$station · Waktu data $time';
  }

  @override
  String get meshtasticNoNodes => 'Belum ada node yang terdengar';

  @override
  String get meshtasticViaMqtt => 'Lewat MQTT (internet)';

  @override
  String get radarCountyOutline => 'Batas kabupaten/kota';

  @override
  String get commonClose => 'Tutup';

  @override
  String get restroomGradeLabel => 'Nilai';

  @override
  String get rainIntervalNow => 'Hari ini';

  @override
  String get changelogCurrentVersion => 'Saat ini';

  @override
  String get typhoonLabelPressure => 'Tekanan pusat';

  @override
  String get typhoonOverlayForecastCalloutsTooltip =>
      'Tampilkan kartu detail titik prakiraan saat diperbesar';

  @override
  String get aedOpenRemark => 'Catatan jam buka';

  @override
  String get onboardingPermsBody =>
      'Agar DPIP dapat memperingatkan Anda saat bencana terjadi, harap berikan izin berikut. Anda dapat mengubahnya kapan saja di pengaturan sistem.';

  @override
  String get typhoonOverlaySectionWeather => 'Lapisan bawah cuaca';

  @override
  String get notifyOptWeatherLocal => 'Hanya lokasi saat ini';

  @override
  String get mapNavRain => 'Hujan';

  @override
  String get moonDays => 'hari';

  @override
  String mapLegendUnit(String unit) {
    return 'Satuan: $unit';
  }

  @override
  String get weatherModeClear => 'Cerah';

  @override
  String get meshtasticRadio => 'Radio';

  @override
  String get commonEmpty => 'Tidak ada yang ditampilkan';

  @override
  String get mapLayerSatelliteB01 => 'Himawari Blue (B01)';

  @override
  String get meshtasticExternalPower => 'Daya eksternal';

  @override
  String get moonPhaseLastQuarter => 'Kuartal akhir';

  @override
  String get reportFilterOrderAsc => 'Menaik';

  @override
  String get reportFilterApply => 'Terapkan';

  @override
  String get reportDetailImageUnavailable => 'Gambar laporan belum tersedia';

  @override
  String get weatherRankingHighest => 'Tertinggi';

  @override
  String get reportDetailReplay => 'Putar ulang';

  @override
  String get mapLayerRestroom => 'Toilet Umum';

  @override
  String get restroomCategoryWelfare => 'Lembaga kesejahteraan';

  @override
  String get restroomGradeExcellent => 'Sangat baik';

  @override
  String get meshtasticLastSent => 'Terakhir dikirim';

  @override
  String get meshtasticName => 'Nama';

  @override
  String get meshtasticScan => 'Pindai';

  @override
  String get mapLayerCategoryForecast => 'Prakiraan numerik';

  @override
  String get meshtasticChannelFailed => 'Gagal menyiapkan kanal DPIP';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get mapLayerSatelliteNdvi => 'Himawari NDVI';

  @override
  String get typhoonLegendForecast => 'Jalur prakiraan';

  @override
  String typhoonValueHpa(String n) {
    return '$n hPa';
  }

  @override
  String get weatherPrecipitation => 'Curah hujan';

  @override
  String get moonNextFullMoon => 'Purnama berikutnya';

  @override
  String get dpmSheetEmpty => 'Ketuk penanda di peta untuk detail';

  @override
  String get onboardingSkipLeave => 'Tetap lewati';

  @override
  String get aedPlaceDesc => 'Lokasi peletakan';

  @override
  String get onboardingSkipTitle => 'Izin belum diberikan';

  @override
  String get restroomTypeFamily => 'Toilet keluarga';

  @override
  String typhoonValueKm(String n) {
    return '$n km';
  }

  @override
  String get onboardingPermBattery => 'Pengecualian baterai';

  @override
  String get typhoonLabelNw => 'NW';

  @override
  String get moonPhaseWaxingCrescent => 'Bulan sabit membesar';

  @override
  String get restroomCategoryLeisure => 'Tempat rekreasi';

  @override
  String get mapLayerTemperature => 'Suhu';

  @override
  String get aedCategory => 'Kategori';

  @override
  String get meshtasticChannels => 'Kanal';

  @override
  String get monitorWaiting => 'Menunggu data…';

  @override
  String get typhoonOverlayForecastCallouts => 'Tooltip prakiraan';

  @override
  String get reportDetailEpicenter => 'Koordinat episentrum';

  @override
  String get meshtasticVoltage => 'Tegangan';

  @override
  String get mapLayerMeshtasticSubtitle =>
      'Node mesh LoRa yang terdengar radio Anda';

  @override
  String get mapLayerWind => 'Angin';

  @override
  String get reportDetailMagnitude => 'Magnitudo';

  @override
  String get reportDetailAreaIntensity => 'Intensitas per wilayah';

  @override
  String get rainInterval12h => '12 jam';

  @override
  String reportListMagnitude(String magnitude) {
    return 'M$magnitude';
  }

  @override
  String get notifyMonitor => 'Pemantau getaran kuat';

  @override
  String get onboardingStart => 'Mulai';

  @override
  String sponsorPerMonth(String price) {
    return '$price / bulan';
  }

  @override
  String get mapLayerPressure => 'Tekanan';

  @override
  String get mapLayerSatelliteB04 => 'Himawari Near-Infrared (B04)';

  @override
  String get mapLayerSatelliteTransparentZero =>
      'Selisih nol = transparan (tanpa sinyal)';

  @override
  String get shelterIndoorLabel => 'Penampungan dalam ruangan';

  @override
  String get notifyOptOff => 'Nonaktif';

  @override
  String get reportFilterSortTime => 'Waktu';

  @override
  String get mapLayerSatelliteCloudProbablyClear => 'Mungkin cerah';

  @override
  String get weatherModeThunderstorm => 'Badai petir';

  @override
  String get homeViewOnMap => 'Lihat di peta';

  @override
  String get reportFilterIntensityInfoLegacyTitle => 'Lama (sebelum 2020)';

  @override
  String get typhoonLabelSpeed => 'Kecepatan gerak';

  @override
  String mapAppOpenFailed(String app) {
    return 'Tidak dapat membuka $app';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'Komposit RGB (resep JMA)';

  @override
  String get meshtasticReceived => 'Diterima';

  @override
  String get weatherRankingExtremeLow => 'Minimum hari ini';

  @override
  String get mapLayerSatelliteB10 => 'Himawari Lower Water Vapour (B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => 'Mungkin berawan';

  @override
  String get mapLayerSatelliteTransparentNoWater =>
      '≤ 0 = transparent (no water)';

  @override
  String get shelterCategoryLabel => 'Jenis bencana';

  @override
  String get meshtasticStateConnecting => 'Menghubungkan…';

  @override
  String get moonTitle => 'Bulan';

  @override
  String get weatherRankingGust => 'Hembusan';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get moreServerStatus => 'Status server';

  @override
  String get notifySectionWeather => 'Cuaca';

  @override
  String get meshtasticPreset => 'Preset modem';

  @override
  String get dataSectionSeismic => 'Seismik';

  @override
  String get changelogBodyEmpty => 'Tidak ada catatan untuk rilis ini.';

  @override
  String get changelogOpenOnGitHub => 'Lihat di GitHub';

  @override
  String get radarGlobalOutline => 'Batas negara';

  @override
  String get notifyEew => 'Peringatan gempa darurat';

  @override
  String get regionNationwide => 'Seluruh negeri';

  @override
  String get moreNotifyLog => 'Log notifikasi DPIP';

  @override
  String get regionCurrent => 'Lokasi saat ini';

  @override
  String get meshtasticNotConnected => 'Belum terhubung ke radio';

  @override
  String get weatherModeSnow => 'Salju';

  @override
  String get mapLayerMeshtastic => 'Node Meshtastic';

  @override
  String get moreDeveloper => 'Info debug';

  @override
  String get mapLayerSatelliteB14 => 'Himawari Longwave Infrared (B14)';

  @override
  String get meshtasticChannelUse => 'Penggunaan kanal';

  @override
  String get mapNavLightning => 'Petir';

  @override
  String get homeForecastEmpty => 'Tidak ada data prakiraan';

  @override
  String get sponsorOneTime => 'Sekali bayar';

  @override
  String get mapLayerSatelliteBtdSplit => 'Himawari Split Window';

  @override
  String get onboardingPermBackground => 'Lokasi latar belakang';

  @override
  String get aedEmergencyPhone => 'Telepon darurat';

  @override
  String get dpmOpenInMaps => 'Buka di peta';

  @override
  String get meshtasticNotifyNodes => 'Beri tahu saat node baru';

  @override
  String get onboardingPermCriticalDesc =>
      'Memungkinkan peringatan gempa yang mengancam jiwa tetap berbunyi bahkan dalam mode senyap atau Jangan Ganggu.';

  @override
  String get mapLayerSatelliteTransparentWarm =>
      'Langit cerah (ujung hangat) = transparan, peta dasar terlihat';

  @override
  String get meshtasticSent => 'Terkirim';

  @override
  String get homeForecastTitle => 'Prakiraan 24 jam';

  @override
  String get typhoonLegendWarningAreas => 'Area peringatan';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return '$count disembunyikan';
  }

  @override
  String get notifyOptLocalIntensity1 => 'Intensitas lokal 1 atau lebih';

  @override
  String get mapTimelinePast => 'Lampau';

  @override
  String get restroomTypeFemale => 'Toilet wanita';

  @override
  String get reportListToday => 'Hari ini';

  @override
  String get meshtasticTapNode => 'Ketuk node untuk detail';

  @override
  String get commonLoading => 'Memuat…';

  @override
  String get typhoonIntensityModerate => 'Topan sedang';

  @override
  String get mapLayerSatelliteAsh => 'Himawari Ash';

  @override
  String get rainInterval3h => '3 jam';

  @override
  String get mapLayerCategorySatellite => 'Satelit';

  @override
  String get meshtasticChannelReady => 'Kanal DPIP siap';

  @override
  String get mapLayerSatelliteNightmicrophysics =>
      'Himawari Night Microphysics';

  @override
  String get typhoonIntensityTd => 'Depresi tropis';

  @override
  String get reportFilterDate => 'Tanggal';

  @override
  String get sponsorRestoreUnavailable =>
      'Tidak dapat terhubung ke toko. Coba lagi nanti.';

  @override
  String homeForecastPop(String pop) {
    return '$pop%';
  }

  @override
  String get regionEmpty => 'Belum ada wilayah tersimpan';

  @override
  String get onboardingPermBatteryDesc =>
      'Izinkan DPIP terus berjalan di latar belakang agar peringatan tidak tertunda atau terlewat.';

  @override
  String get mapNavDisaster => 'Bencana';

  @override
  String get radarScanRangeSubtitle =>
      'Menandai area yang benar-benar dipantau keempat radar.';

  @override
  String get aedHoursSunday => 'Jam Minggu';

  @override
  String get reportDetailOriginTime => 'Waktu kejadian';

  @override
  String get trendNoData => 'Tidak ada data tren';

  @override
  String get onboardingPermLocation => 'Lokasi';

  @override
  String get moreDiscord => 'Komunitas Discord';

  @override
  String get mapNavPressure => 'Tekanan';

  @override
  String get mapLayerSatelliteB13 => 'Himawari Infrared (B13)';

  @override
  String typhoonTdNo(String no) {
    return 'TD $no';
  }

  @override
  String get changelogEmpty => 'Belum ada catatan rilis';

  @override
  String get reportFilterDateStartNote => 'Hari mulai: dari 00:00（Taipei）';

  @override
  String get eewTitle => 'Peringatan dini gempa';

  @override
  String get mapLayerWindForecastEcmwf => 'ECMWF';

  @override
  String regionSelectCount(int count, int max) {
    return '$count/$max dipilih';
  }

  @override
  String get mapLayerSatelliteBtdSo2 => 'Himawari SO₂ / Cloud Phase';

  @override
  String get meshtasticStateError => 'Kesalahan';

  @override
  String get weatherModeOvercast => 'Mendung';

  @override
  String get reportDetailDepth => 'Kedalaman hiposenter';

  @override
  String get typhoonOverlayWarningTooltip =>
      'Sorot kabupaten dalam peringatan topan';

  @override
  String get reportFilterDatePick => 'Pilih tanggal';

  @override
  String get onboardingSkipStay => 'Kembali';

  @override
  String get commonFetchFailed => 'Tidak dapat memuat data. Silakan coba lagi.';

  @override
  String get shelterOutdoorLabel => 'Penampungan luar ruangan';

  @override
  String get meshtasticStateConnected => 'Terhubung';

  @override
  String get mapNavRadar => 'Radar';

  @override
  String get mapLayerSatelliteCloudClear => 'Clear';

  @override
  String eewSummary(String magnitude, String depth) {
    return 'M$magnitude · kedalaman $depth km';
  }

  @override
  String get locationBannerPermission =>
      'Izin lokasi mati — peringatan lokal tidak dapat menargetkan wilayah Anda.';

  @override
  String get typhoonOverlayWeatherNoneTooltip =>
      'Tanpa lapisan bawah radar atau inframerah';

  @override
  String get radarCountyOutlineHint => 'Digambar di atas gema';

  @override
  String get windForecastCountyOutlineHint => 'Digambar di atas bidang angin';

  @override
  String get homeRainTrendTitle => 'Hujan 1 jam ke depan';

  @override
  String get moonPhaseFirstQuarter => 'Kuartal pertama';

  @override
  String get mapLayerCategoryTyphoon => 'Topan';

  @override
  String get meshtasticUtilization => 'Waktu udara (24 jam)';

  @override
  String get restroomTypeMixed => 'Toilet campuran';

  @override
  String get restroomGradeGood => 'Baik';

  @override
  String get notifyTsunami => 'Informasi tsunami';

  @override
  String get navData => 'Data';

  @override
  String get mapLayerSatelliteBtdWvirw => 'Himawari Overshooting Top';

  @override
  String get meshtasticReadingAge => 'Waktu pengukuran';

  @override
  String get mapAppCallFailed =>
      'Perangkat ini tidak dapat melakukan panggilan telepon';

  @override
  String get reportFilterAny => 'Semua';

  @override
  String get weatherRankingMergeTo => 'Gabung';

  @override
  String get notifyIntensity => 'Laporan intensitas';

  @override
  String get rainIntervalMenu => 'Jendela akumulasi';

  @override
  String get reportDetailLocalFelt => 'Gempa Dirasakan Lokal';

  @override
  String get meshtasticDevice => 'Perangkat';

  @override
  String get onboardingGrant => 'Berikan';

  @override
  String get weatherModeRain => 'Hujan';

  @override
  String get shelterVulnerableOkLabel => 'Ramah kelompok rentan';

  @override
  String get stationSheetEmpty => 'Ketuk stasiun untuk melihat bacaannya';

  @override
  String get typhoonLegendProbability => 'Probabilitas serangan';

  @override
  String get reportFilterMagnitude => 'Magnitudo';

  @override
  String get skyTimeMorning => 'Pagi';

  @override
  String get experimentalFeatures => 'Fitur eksperimental';

  @override
  String get onboardingTermsBody =>
      'Harap baca pemberitahuan berikut sebelum menggunakan DPIP:\n\n• Semua informasi harus mengacu pada konten yang diterbitkan oleh Central Weather Administration (CWA) Taiwan.\n\n• Bergantung pada kondisi jaringan, server, aplikasi, dan sumber data hulu, informasi mungkin tidak diterima; kami berupaya sebaik mungkin untuk menghindari hal ini tetapi tidak dapat menjamin bahwa hal itu tidak akan pernah terjadi.\n\n• Guncangan kuat dapat mencapai lokasi Anda sebelum notifikasi tiba.\n\n• Peringatan dini gempa adalah hasil perhitungan cepat yang mungkin mengandung kesalahan yang signifikan — pahami hal ini dan gunakan dengan hati-hati.\n\n• Setiap tindakan yang tidak disahkan oleh pihak berwenang dapat menimbulkan risiko hukum; harap patuhi semua peraturan yang berlaku.\n\nSelain itu, untuk menyediakan peringatan yang dilokalkan, layanan ini mengumpulkan dan mengunggah perkiraan lokasi Anda dan pengidentifikasi push — di latar depan maupun latar belakang — semata-mata untuk menentukan peringatan mana yang akan dikirimkan kepada Anda.\n\nDengan mengetuk \"Setuju dan lanjutkan\", Anda mengonfirmasi bahwa Anda telah membaca, memahami, dan menyetujui hal-hal di atas.';

  @override
  String get reportFilterTitle => 'Filter';

  @override
  String get onboardingPermCritical => 'Peringatan kritis';

  @override
  String trendCumulativeTotal(String total) {
    return 'Total $total mm';
  }

  @override
  String get languageName => 'Bahasa Indonesia';

  @override
  String get reportListEmptyFiltered =>
      'Tidak ada laporan yang cocok dengan filter';

  @override
  String get meshtasticExcludeMqtt => 'Sembunyikan node MQTT';

  @override
  String get mapNavTyphoon => 'Topan';

  @override
  String get weatherModeSand => 'Debu';

  @override
  String get notifyReport => 'Laporan gempa';

  @override
  String get mapAppCoordinatesCopied => 'Koordinat disalin';

  @override
  String get skyTimeNight => 'Malam';

  @override
  String get sponsorRecommended => 'Direkomendasikan';

  @override
  String get mapLayerSatelliteB15 => 'Himawari Longwave Infrared (B15)';

  @override
  String get weatherRankingWind => 'Kecepatan angin';

  @override
  String get feedStale => 'Data mungkin sudah usang';

  @override
  String homeForecastWind(String direction, String level) {
    return '$direction · Skala $level';
  }

  @override
  String get navHome => 'Beranda';

  @override
  String get meshtasticRegionLabel => 'Wilayah';

  @override
  String get mapLayerSatelliteCloudtop => 'Himawari Cloud Top Temperature';

  @override
  String get moonTimelineCaption => 'Fase';

  @override
  String get openSourceLicenses => 'Lisensi sumber terbuka';

  @override
  String get weatherRankingLowest => 'Terendah';

  @override
  String get reportFilterSortDepth => 'Kedalaman';

  @override
  String mapTimelineDataTime(String time) {
    return 'Waktu data $time';
  }

  @override
  String get radarScanRange => 'Tampilkan jangkauan pindai';

  @override
  String get meshtasticHopLimit => 'Batas lompatan';

  @override
  String get weatherRankingExtremeHigh => 'Maksimum hari ini';

  @override
  String get sponsorPrivacy => 'Kebijakan Privasi';

  @override
  String get reportDetailLocalIntensity => 'Intensitas di lokasi Anda';

  @override
  String get mapLayerSatelliteNaturalcolor => 'Himawari Natural Color';

  @override
  String get meshtasticAirtime => 'Waktu udara (TX)';

  @override
  String shelterCapacityValue(int n) {
    return '$n orang';
  }

  @override
  String lightningLegendCc(int minutes) {
    return 'Awan–awan · $minutes mnt';
  }

  @override
  String get meshtasticSendHint => 'Pesan untuk disiarkan';

  @override
  String monitorDelay(String value) {
    return 'Latensi $value s';
  }

  @override
  String get dpmNo => 'Tidak';

  @override
  String get mapLayerSatelliteB08 => 'Himawari Upper Water Vapour (B08)';

  @override
  String get meshtasticReconnecting => 'Menghubungkan ulang…';

  @override
  String get radarTownOutlineSubtitle =>
      'Menjaga batas kecamatan tetap terbaca di bawah gema radar.';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip =>
      'Inframerah terdekat dengan waktu buletin topan';

  @override
  String get radarScanRangeHint => 'Di luar kotak berarti tak terpantau';

  @override
  String typhoonPickerTd(String no) {
    return 'Depresi tropis TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => 'Himawari Water Vapour';

  @override
  String get regionAddButton => 'Tambah wilayah';

  @override
  String get regionSearchHint => 'Cari kabupaten dan kota';

  @override
  String get regionSearchEmpty => 'Tidak ada kabupaten/kota yang cocok';

  @override
  String get regionSearchTownHint => 'Cari kecamatan';

  @override
  String get regionSearchTownEmpty => 'Tidak ada kecamatan yang cocok';

  @override
  String get displaySettings => 'Tampilan';

  @override
  String get restroomGradePoor => 'Di bawah standar';

  @override
  String get restroomCategoryTourist => 'Kawasan wisata';

  @override
  String get locationBannerServiceOff =>
      'Layanan lokasi mati — peringatan lokal tidak dapat menargetkan wilayah Anda.';

  @override
  String get mapLayerStyleTooltip => 'Gaya warna';

  @override
  String lightningLegendCg(int minutes) {
    return 'Awan–tanah · $minutes mnt';
  }

  @override
  String get skyTimeAuto => 'Otomatis';

  @override
  String get appLogs => 'Log aplikasi';

  @override
  String get serverStatusLocal => 'Status perangkat';

  @override
  String get serverStatusLocalBody =>
      'Metrik server berasal dari dasbor. Di bawah ini adalah penilaian koneksi aktual perangkat ini ke endpoint multi-aktif (LB / Core tiap wilayah): aplikasi hanya mencatat lalu lintas yang benar-benar dikirim, jika endpoint belum pernah disentuh perangkat ini akan ditampilkan \'Belum diperiksa\'.';

  @override
  String get serverStatusAllUp => 'Semua layanan normal';

  @override
  String get serverStatusDegraded => 'Kinerja menurun';

  @override
  String get serverStatusDown => 'Layanan bermasalah';

  @override
  String get serverStatusErrorRate => 'Tingkat error 5xx';

  @override
  String get serverStatusLatency => 'Latensi rata-rata';

  @override
  String get serverStatusUpdated => 'Diperbarui';

  @override
  String get serverStatusWeb => 'Status server';

  @override
  String get serverStatusWebUrl => 'status.exptech.dev';

  @override
  String get serverStatusExpTech => 'Status ExpTech';

  @override
  String get serverStatusCloudflare => 'Status Cloudflare';

  @override
  String get serverStatusCloudflareAllOperational => 'Semua wilayah normal';

  @override
  String get serverStatusCloudflareOutage =>
      'Cloudflare beberapa wilayah bermasalah';

  @override
  String get serverStatusCloudflareNone =>
      'Tidak ada wilayah untuk ditampilkan.';

  @override
  String get serverStatusCloudflareOperational => 'Normal';

  @override
  String get serverStatusCloudflareDegraded => 'Kinerja menurun';

  @override
  String get serverStatusCloudflarePartial => 'Gangguan sebagian';

  @override
  String get serverStatusCloudflareMajor => 'Gangguan besar';

  @override
  String get serverStatusCloudflareUnknown => 'Tidak diketahui';

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
      'Core eksklusif API (radar / cuaca / angin)';

  @override
  String get endpointTierCoreStaticExclusive => 'Core eksklusif statis';

  @override
  String get endpointTierLegacyApi => 'API lama (api-1)';

  @override
  String get endpointHealthOk => 'Koneksi normal';

  @override
  String get endpointHealthDegraded => 'Ada endpoint tidak stabil';

  @override
  String get endpointHealthDown => 'Koneksi bermasalah';

  @override
  String get endpointHealthUnknown => 'Belum ada data';

  @override
  String get endpointStateOk => 'Normal';

  @override
  String get endpointStateDegraded => 'Tidak stabil';

  @override
  String get endpointStateDown => 'Bermasalah';

  @override
  String get endpointStateUnknown => 'Tidak diketahui';

  @override
  String get endpointServiceEew => 'EEW';

  @override
  String get endpointServiceRts => 'RTS';

  @override
  String get endpointServiceRadar => 'Radar';

  @override
  String get endpointServiceSatellite => 'Satellite';

  @override
  String get endpointServiceQpesums => 'QPE';

  @override
  String get endpointServiceWind => 'Wind';

  @override
  String get endpointServiceDpm => 'Titik bencana';

  @override
  String get endpointServiceWeather => 'Weather';

  @override
  String get endpointServiceRain => 'Rain';

  @override
  String get endpointServiceLightning => 'Lightning';

  @override
  String get endpointServiceTyphoon => 'Typhoon';

  @override
  String get endpointServiceReport => 'EQ reports';

  @override
  String get endpointServiceTremStation => 'Stasiun getaran';

  @override
  String get endpointServiceEvent => 'Events';

  @override
  String get endpointServiceLocation => 'Location';

  @override
  String get endpointServiceNotify => 'Notifications';

  @override
  String get endpointServiceOther => 'Other';

  @override
  String get feedConnecting => 'Menghubungkan…';

  @override
  String get notifyBannerDisabled =>
      'Notifikasi mati — Anda tidak akan menerima peringatan bencana.';

  @override
  String get weatherHumidity => 'Kelembapan';

  @override
  String typhoonValueMs(String n) {
    return '$n m/s';
  }

  @override
  String homeForecastHumidity(String value) {
    return 'Kelembapan $value%';
  }

  @override
  String get meshtasticBusyBody =>
      'Putuskan koneksinya dulu di aplikasi Meshtastic lain. Dua aplikasi pada satu radio saling mengambil pesan, jadi sebagian akan hilang.';

  @override
  String get meshtasticChannelNoSlot =>
      'Tidak ada slot kanal kosong — kosongkan satu di radio';

  @override
  String get restroomCategoryTransport => 'Transportasi';

  @override
  String get meshtasticBattery => 'Baterai';

  @override
  String get meshtasticDistance => 'Jarak';

  @override
  String get meshtasticSnrTrend => 'Tren sinyal (SNR)';

  @override
  String get meshtasticBatteryTrend => 'Tren baterai';

  @override
  String get typhoonOverlayMenuTooltip => 'Opsi lapisan topan';

  @override
  String get mapLayerSatelliteBtdOzone => 'Himawari Tropopause';

  @override
  String meshtasticRegionMismatch(String region) {
    return 'Wilayah radio adalah $region — DPIP membutuhkan TW';
  }

  @override
  String get notifySectionEarthquake => 'Gempa bumi';

  @override
  String get mapLayerDisasterMap => 'Peta Bencana';

  @override
  String get weatherModeFog => 'Kabut';

  @override
  String typhoonPickerNamed(String no, String name) {
    return '$name TY $no';
  }

  @override
  String get mapLayerStyleGrayTooltip => 'JMA grayscale — colder is whiter';

  @override
  String get moreAnnouncements => 'Pengumuman';

  @override
  String get moreTagline => 'Platform Integrasi Informasi Bencana';

  @override
  String get moreVersionStable => 'Versi resmi';

  @override
  String get moreVersionNotes => 'Pembaruan ini';

  @override
  String get moreVersionNotesHighlightsSubtitle =>
      'Apa yang berubah di versi ini';

  @override
  String releaseHighlightsTitle(Object train) {
    return '$train rangkuman';
  }

  @override
  String get releaseHighlightsTabNormal => 'Untuk pengguna';

  @override
  String get releaseHighlightsTabAdvanced => 'Mendalam';

  @override
  String get releaseHighlightsEmpty => 'Belum ada konten.';

  @override
  String get releaseHighlightsSeeNotes => 'Catatan rilis lengkap';

  @override
  String get moreVersionNotesEmpty => 'Tidak ada changelog untuk build ini';

  @override
  String get reportNotFound => 'Laporan gempa ini tidak ditemukan';

  @override
  String get moreVersionSnapshot => 'Versi uji';

  @override
  String get mapLayerSatelliteTransparentNoData =>
      'No data (land) = transparent';

  @override
  String get restroomCategoryGovernment => 'Kantor pelayanan publik';

  @override
  String get typhoonLegendCurrent => 'Pusat saat ini';

  @override
  String get aedAddress => 'Alamat';

  @override
  String get mapLayerAed => 'AED';

  @override
  String get changelogTypePrerelease => 'Beta';

  @override
  String get reportFilterIntensityInfoModernBody =>
      'Tingkat 0–4, 5−, 5+, 6−, 6+, 7. Slider filter memakai skala baru; peristiwa lama tetap memakai label lama di daftar.';

  @override
  String get typhoonOverlayWeatherNone => 'None';

  @override
  String get mapLayerStyleGray => 'Grayscale (JMA)';

  @override
  String get weatherModeAuto => 'Otomatis';

  @override
  String get typhoonLabelProbCircle => 'Lingkaran probabilitas 70%';

  @override
  String get notifyOptAll => 'Terima semua';

  @override
  String get displayTheme => 'Tema';

  @override
  String get mapLayerSatelliteB07 => 'Himawari Shortwave Infrared (B07)';

  @override
  String get typhoonLabelDirection => 'Arah gerak';

  @override
  String get regionManageTitle => 'Wilayah tersimpan';

  @override
  String get regionSaveNote =>
      'Notifikasi dikirim berdasarkan lokasi GPS Anda. Menyimpan wilayah sering dipakai tidak mengubah tempat pengiriman peringatan — wilayah sering dipakai hanya agar status tiap wilayah terlihat cepat di beranda. Izinkan akses lokasi, jika tidak notifikasi tidak berfunosm.';

  @override
  String get typhoonLegendCone => 'Kerucut prakiraan';

  @override
  String get moreCwaEew => 'Peringatan dini gempa CWA';

  @override
  String get onboardingPermsTitle => 'Izin';

  @override
  String get mapLayerStyleJma => 'Peningkatan puncak awan (JMA)';

  @override
  String get rainInterval10m => '10 mnt';

  @override
  String get meshtasticConnectAnyway => 'Tetap hubungkan';

  @override
  String reportListDayCount(int count) {
    return '$count';
  }

  @override
  String get mapLayerSatelliteB06 => 'Himawari Near-Infrared (B06)';

  @override
  String get mapLayerSatelliteTransparentReflectance =>
      'Reflektansi rendah / malam = transparan, peta dasar terlihat';

  @override
  String chartHourLabel(int hour) {
    return '${hour}j';
  }

  @override
  String get mapLayerShelter => 'Tempat Evakuasi';

  @override
  String get typhoonOverlayProbabilityTooltip =>
      'Tampilkan probabilitas hantaman (menyembunyikan kerucut prakiraan)';

  @override
  String get mapLayerSatelliteNdwi => 'Himawari NDWI';

  @override
  String get disasterMapOverlayShelterTooltip => 'Tampilkan tempat evakuasi';

  @override
  String get mapNavHumidity => 'Kelembapan';

  @override
  String get reportDetailSortByIntensity => 'Urutkan menurut intensitas';

  @override
  String get homeRainTrendNoData => 'Tidak ada data';

  @override
  String get mapLayerCategoryRadar => 'Radar';

  @override
  String get meshtasticShortName => 'Nama pendek';

  @override
  String get mapLayerSatelliteAirmass => 'Himawari Airmass';

  @override
  String get dataSectionWeather => 'Cuaca';

  @override
  String get aedHoursWeekday => 'Jam hari kerja';

  @override
  String get homeActiveEventsTitle => 'Peristiwa aktif';

  @override
  String get faq => 'FAQ';

  @override
  String eewSerial(int serial) {
    return 'Laporan $serial';
  }

  @override
  String get reportFilterSort => 'Urutan';

  @override
  String get meshtasticRegionConfirm =>
      'Beralihkan radio ini ke wilayah TW? Radio akan mulai ulang dan terputus sesaat, dan semua kanal lain ikut pindah.';

  @override
  String get dataEarthquakeSubtitle => 'Laporan gempa';

  @override
  String get typhoonNoActive => 'Tidak ada topan aktif';

  @override
  String get mapLayerSatelliteB11 => 'Himawari SO₂ / Cloud Phase (B11)';

  @override
  String get navEvents => 'Kejadian';

  @override
  String get onboardingTermsTitle => 'Ketentuan Layanan';

  @override
  String get mapOsmOverlay => 'Peta detail';

  @override
  String get mapOsmOverlayHint =>
      'Tampilkan jalan, bangunan, dan nama tempat yang lebih lengkap';

  @override
  String get mapOsmDetails => 'Detail lapisan';

  @override
  String get moreDataSources => 'Sumber data';

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
    return '$enabled dari $total lapisan aktif';
  }

  @override
  String get mapOsmSurface => 'Permukaan';

  @override
  String get mapOsmParks => 'Taman';

  @override
  String get mapOsmLandUse => 'Penggunaan lahan';

  @override
  String get mapOsmAirportAreas => 'Area bandara';

  @override
  String get mapOsmWater => 'Perairan';

  @override
  String get mapOsmRivers => 'Sungai';

  @override
  String get mapOsmBoundaries => 'Batas';

  @override
  String get mapOsmBuildings => 'Bangunan';

  @override
  String get mapOsmRoads => 'Jalan';

  @override
  String get mapOsmRoadNames => 'Nama jalan';

  @override
  String get mapOsmWaterNames => 'Nama perairan';

  @override
  String get mapOsmPeaks => 'Puncak';

  @override
  String get mapOsmAirportNames => 'Nama bandara';

  @override
  String get mapOsmPlaceNames => 'Nama tempat';

  @override
  String get mapOsmPoi => 'Tempat menarik';

  @override
  String get mapOsmHouseNumbers => 'Nomor rumah';

  @override
  String get mapOsmRestoreAll => 'Pulihkan semua';

  @override
  String get mapOsmSectionNatural => 'Fitur alam';

  @override
  String get mapOsmSectionRoadsAndBuildings => 'Jalan & bangunan';

  @override
  String get mapOsmSectionLabelsAndPlaces => 'Label & tempat';

  @override
  String get mapTownLabels => 'Nama kecamatan';

  @override
  String get notifySetFailed =>
      'Tidak dapat menyimpan pengaturan. Silakan coba lagi.';

  @override
  String get meshtasticDisconnect => 'Putuskan';

  @override
  String get meshtasticUndecoded => 'Belum didekripsi';

  @override
  String get notifyAnnouncement => 'Pengumuman';

  @override
  String get onboardingIntroTitle => 'Selamat datang di DPIP';

  @override
  String get regionCurrentUnavailable =>
      'Tidak dapat memperoleh lokasi saat ini';

  @override
  String get languageSystem => 'Bawaan sistem';

  @override
  String get skyTimeSunset => 'Matahari terbenam';

  @override
  String get mapLayerSatelliteDust => 'Himawari Dust';

  @override
  String get mapAppAppleMaps => 'Apple Maps';

  @override
  String get regionEdit => 'Ubah';

  @override
  String get weatherDynamicState => 'Animasi cuaca';

  @override
  String get moonNow => 'Sekarang';

  @override
  String get moonSectionAppearance => 'Penampakan';

  @override
  String get moonSectionRiseSet => 'Terbit dan terbenam';

  @override
  String get moonSectionUpcoming => 'Mendatang';

  @override
  String get moonSectionCalendar => 'Kalender';

  @override
  String get moonDistance => 'Jarak';

  @override
  String get moonKilometres => 'km';

  @override
  String get moonApparentSize => 'Ukuran tampak';

  @override
  String get moonRise => 'Bulan terbit';

  @override
  String get moonSet => 'Bulan terbenam';

  @override
  String get moonNextNewMoon => 'Bulan baru berikutnya';

  @override
  String get moonAlwaysUp => 'Di atas ufuk sepanjang hari';

  @override
  String get moonNoEvent => 'Tidak ada hari ini';

  @override
  String get sunTitle => 'Matahari';

  @override
  String get sunSectionDaylight => 'Cahaya siang';

  @override
  String get sunSectionTwilight => 'Senja';

  @override
  String get sunSectionLight => 'Cahaya';

  @override
  String get sunSectionSundial => 'Jam matahari';

  @override
  String get sunSectionTerms => 'Istilah surya';

  @override
  String get sunRise => 'Matahari terbit';

  @override
  String get sunSet => 'Matahari terbenam';

  @override
  String get sunNoon => 'Tengah hari surya';

  @override
  String get sunDayLength => 'Panjang hari';

  @override
  String get sunTwilightCivil => 'Sipil';

  @override
  String get sunTwilightNautical => 'Nautika';

  @override
  String get sunTwilightAstronomical => 'Astronomi';

  @override
  String get sunGoldenHourMorning => 'Golden hour pagi';

  @override
  String get sunGoldenHourEvening => 'Golden hour sore';

  @override
  String get sunBlueHour => 'Jam biru';

  @override
  String get sunEquationOfTime => 'Persamaan waktu';

  @override
  String get sunMinutes => 'mnt';

  @override
  String get solarTermNext => 'Istilah berikutnya';

  @override
  String get planetsTitle => 'Planet';

  @override
  String get planetsSectionTonight => 'Saat ini';

  @override
  String get planetUp => 'Di atas ufuk';

  @override
  String get planetDown => 'Di bawah ufuk';

  @override
  String get planetInGlare => 'Terlalu dekat Matahari';

  @override
  String get planetMagnitude => 'Magnitudo';

  @override
  String get planetElongation => 'Elongasi';

  @override
  String get planetSky => 'Waktu';

  @override
  String get planetEvening => 'Petang';

  @override
  String get planetMorning => 'Pagi';

  @override
  String get planetDistance => 'Jarak';

  @override
  String get planetAu => 'au';

  @override
  String get planetAltitude => 'Ketinggian';

  @override
  String get planetMercury => 'Merkurius';

  @override
  String get planetVenus => 'Venus';

  @override
  String get planetMars => 'Mars';

  @override
  String get planetJupiter => 'Jupiter';

  @override
  String get planetSaturn => 'Saturnus';

  @override
  String get planetUranus => 'Uranus';

  @override
  String get planetNeptune => 'Neptunus';

  @override
  String get solarTermVernalEquinox => 'Ekuinoks Musim Semi';

  @override
  String get solarTermPureBrightness => 'Pure Brightness';

  @override
  String get solarTermGrainRain => 'Grain Rain';

  @override
  String get solarTermStartOfSummer => 'Awal Musim Panas';

  @override
  String get solarTermGrainFull => 'Grain Full';

  @override
  String get solarTermGrainInEar => 'Grain in Ear';

  @override
  String get solarTermSummerSolstice => 'Solstis Musim Panas';

  @override
  String get solarTermMinorHeat => 'Minor Heat';

  @override
  String get solarTermMajorHeat => 'Major Heat';

  @override
  String get solarTermStartOfAutumn => 'Awal Musim Gugur';

  @override
  String get solarTermEndOfHeat => 'End of Heat';

  @override
  String get solarTermWhiteDew => 'White Dew';

  @override
  String get solarTermAutumnalEquinox => 'Ekuinoks Musim Gugur';

  @override
  String get solarTermColdDew => 'Cold Dew';

  @override
  String get solarTermFrostDescent => 'Frost Descent';

  @override
  String get solarTermStartOfWinter => 'Awal Musim Dingin';

  @override
  String get solarTermMinorSnow => 'Minor Snow';

  @override
  String get solarTermMajorSnow => 'Major Snow';

  @override
  String get solarTermWinterSolstice => 'Solstis Musim Dingin';

  @override
  String get solarTermMinorCold => 'Minor Cold';

  @override
  String get solarTermMajorCold => 'Major Cold';

  @override
  String get solarTermStartOfSpring => 'Awal Musim Semi';

  @override
  String get solarTermRainWater => 'Rain Water';

  @override
  String get solarTermAwakeningOfInsects => 'Awakening of Insects';

  @override
  String get tonightTitle => 'Malam ini';

  @override
  String get tonightSectionDark => 'Jendela pengamatan';

  @override
  String get tonightAstronomicalNight => 'Malam astronomis';

  @override
  String get tonightNeverDark => 'Tak pernah gelap total';

  @override
  String get tonightDarkWindow => 'Jendela gelap';

  @override
  String get tonightMoonAllNight => 'Bulan terbit sepanjang malam';

  @override
  String get tonightDarkTotal => 'Total gelap';

  @override
  String get tonightMoonlight => 'Cahaya bulan';

  @override
  String get tonightSectionShowers => 'Hujan meteor';

  @override
  String get tonightRadiantDown => 'Radian tidak terbit';

  @override
  String get tonightPerHour => '/jam';

  @override
  String get tonightSectionSatellites => 'Lintasan satelit';

  @override
  String get tonightSectionTargets => 'Sasaran yang terlihat';

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
  String get showerSouthernTaurids => 'Taurids Selatan';

  @override
  String get showerLeonids => 'Leonids';

  @override
  String get showerGeminids => 'Geminids';

  @override
  String get showerUrsids => 'Ursids';

  @override
  String get deepSkyOpenCluster => 'Gugus terbuka';

  @override
  String get deepSkyGlobularCluster => 'Gugus bola';

  @override
  String get deepSkySpiralGalaxy => 'Galaksi spiral';

  @override
  String get deepSkyEllipticalGalaxy => 'Galaksi elips';

  @override
  String get deepSkyIrregularGalaxy => 'Galaksi tak beraturan';

  @override
  String get deepSkyPlanetaryNebula => 'Nebula planeter';

  @override
  String get deepSkySupernovaRemnant => 'Sisa supernova';

  @override
  String get deepSkyEmissionNebula => 'Nebula emisi';

  @override
  String get deepSkyReflectionNebula => 'Nebula refleksi';

  @override
  String get deepSkyAsterism => 'Asterisme';

  @override
  String get almanacTitle => 'Almanak';

  @override
  String get almanacSectionToday => 'Hari ini';

  @override
  String get almanacGregorian => 'Masehi';

  @override
  String get almanacLunar => 'Lunisolar';

  @override
  String get almanacYear => 'Tahun';

  @override
  String get almanacMonthLength => 'Panjang bulan';

  @override
  String get almanacLongMonth => '30 hari';

  @override
  String get almanacShortMonth => '29 hari';

  @override
  String get almanacLeapPrefix => 'Kabisat ';

  @override
  String get almanacSectionLunarEclipses => 'Gerhana bulan';

  @override
  String get almanacSectionSolarEclipses => 'Gerhana matahari';

  @override
  String get almanacNoSolarEclipse => 'Tidak ada';

  @override
  String get eclipseTotal => 'Total';

  @override
  String get eclipsePartial => 'Sebagian';

  @override
  String get eclipseAnnular => 'Cincin';

  @override
  String get eclipsePenumbral => 'Penumbra';

  @override
  String get zodiacRat => 'Tikus';

  @override
  String get zodiacOx => 'Kerbau';

  @override
  String get zodiacTiger => 'Macan';

  @override
  String get zodiacRabbit => 'Kelinci';

  @override
  String get zodiacDragon => 'Naga';

  @override
  String get zodiacSnake => 'Ular';

  @override
  String get zodiacHorse => 'Kuda';

  @override
  String get zodiacGoat => 'Kambing';

  @override
  String get zodiacMonkey => 'Monyet';

  @override
  String get zodiacRooster => 'Ayam';

  @override
  String get zodiacDog => 'Anjing';

  @override
  String get zodiacPig => 'Babi';

  @override
  String get tideTitle => 'Pasang surut';

  @override
  String get tideDisclaimer =>
      'Hanya gaya astronomis — bukan tabel pasang surut pelabuhan. Untuk tinggi muka air gunakan tabel CWA.';

  @override
  String get tideSectionNow => 'Saat ini';

  @override
  String get tidePhase => 'Siklus';

  @override
  String get tideSpring => 'Purnama';

  @override
  String get tideNeap => 'Perbani';

  @override
  String get tideMiddling => 'Sedang';

  @override
  String get tideLunarDistanceFactor => 'Tarikan Bulan';

  @override
  String get tideEquilibrium => 'Pasang setimbang';

  @override
  String get tideMetres => 'm';

  @override
  String get tidePerigeanSpring => 'Purnama perigee berikutnya';

  @override
  String get tideSectionTurningPoints => 'Titik balik';

  @override
  String get tideHigh => 'Tinggi';

  @override
  String get tideLow => 'Rendah';

  @override
  String get skyChartTitle => 'Peta langit';

  @override
  String get skyChartNorth => 'U';

  @override
  String get skyChartEast => 'T';

  @override
  String get skyChartSouth => 'S';

  @override
  String get skyChartWest => 'B';

  @override
  String tonightElementAge(int days) {
    return 'elemen orbit $days hari lalu';
  }

  @override
  String almanacLunarDate(String leap, int month, int day) {
    return '${leap}bulan $month, hari $day';
  }

  @override
  String get tonightNoShowers => 'Tidak ada hujan meteor';

  @override
  String get tonightNoPasses => 'Tidak ada lintasan terlihat dalam 48 jam';

  @override
  String get tonightSatellitesUnavailable => 'Data orbit tidak terbaca';

  @override
  String get tonightNoTargets => 'Tidak ada sasaran cukup tinggi';

  @override
  String get skyChartUnavailable => 'Katalog bintang tidak terbaca';

  @override
  String get permissionSettingsTitle => 'Izinkan lewat Pengaturan';

  @override
  String get permissionSettingsHint =>
      'Aplikasi memeriksa lagi saat Anda kembali.';

  @override
  String get permissionOpenSettings => 'Buka Pengaturan';

  @override
  String permissionSettingsMessage(String what) {
    return '“$what” ditolak dan sistem tidak akan bertanya lagi. Aktifkan di Pengaturan.';
  }

  @override
  String get permissionGuideNotification =>
      'Buka Pengaturan Sistem untuk mengizinkan notifikasi.';

  @override
  String get permissionGuideForegroundLocation =>
      'Buka Pengaturan Sistem untuk mengizinkan lokasi presisi.';

  @override
  String permissionGuideBackgroundLocation(Object option) {
    return 'Di “$option”, pilih “Izinkan sepanjang waktu”.';
  }

  @override
  String get permissionGuideBackgroundExecution =>
      'Izinkan eksekusi latar belakang di Pengaturan Sistem agar notifikasi tidak dijeda.';

  @override
  String get permissionGuideUnusedPause =>
      'Jika aplikasi ditandai “tidak digunakan”, pilih “Izinkan” di Pengaturan Sistem.';

  @override
  String get permissionGuideUnusedFreeSpace =>
      'Jika aplikasi dijeda karena penyimpanan, bersihkan cache dan buka kembali.';

  @override
  String get permissionGuideUnusedRevoke =>
      'Jika izin aplikasi dicabut, berikan lagi di Pengaturan Sistem.';

  @override
  String get permissionGuideUnusedPlayProtect =>
      'Jika Play Protect menjeda aplikasi, periksa statusnya di Google Play.';

  @override
  String permissionGuideVendorPower(Object vendor) {
    return 'Di pengaturan hemat daya “$vendor”, atur aplikasi ini ke “Tanpa batas”.';
  }

  @override
  String get permissionStillRequired =>
      'Masih diperlukan — buka Pengaturan untuk mengaktifkannya.';

  @override
  String get permissionVerifyManually =>
      'Periksa secara manual bahwa izin ini diaktifkan di Pengaturan Sistem.';

  @override
  String get permissionBackgroundLocationOption => '“Izinkan sepanjang waktu”';

  @override
  String get displayTextSize => 'Ukuran teks';

  @override
  String get displayTextSizeDesc =>
      'Berlaku untuk antarmuka aplikasi, bukan label peta.';

  @override
  String get displayTextWeight => 'Ketebalan teks';

  @override
  String get displayTextWeightDesc =>
      'Teks yang lebih tebal dapat lebih mudah dibaca.';

  @override
  String get displayContrast => 'Kontras';

  @override
  String get displayContrastDesc =>
      'Kontras yang lebih tinggi memisahkan teks dari latarnya.';

  @override
  String get displayColorVision => 'Penglihatan warna';

  @override
  String get displayColorVisionDesc =>
      'Seluruh aplikasi diwarnai ulang, termasuk warna peta.';

  @override
  String get displayColorVisionNone => 'Warna standar';

  @override
  String get displayColorVisionProtan => 'Lemah merah (protanopia)';

  @override
  String get displayColorVisionDeutan => 'Lemah hijau (deuteranopia)';

  @override
  String get displayColorVisionTritan => 'Lemah biru-kuning (tritanopia)';

  @override
  String get displayPreviewSample => 'Contoh laporan gempa';

  @override
  String get displayScaleSmall => 'Kecil';

  @override
  String get displayScaleDefault => 'Bawaan';

  @override
  String get displayScaleLarge => 'Besar';

  @override
  String get displayScaleHuge => 'Sangat besar';

  @override
  String get displayWeightNormal => 'Normal';

  @override
  String get displayWeightMedium => 'Sedang';

  @override
  String get displayWeightBold => 'Tebal';

  @override
  String get displayContrastStandard => 'Standar';

  @override
  String get displayContrastMedium => 'Sedang';

  @override
  String get displayContrastHigh => 'Tinggi';

  @override
  String get meshtasticDirect => 'Langsung';

  @override
  String meshtasticHopsAway(int n) {
    return '$n lompatan';
  }

  @override
  String get meshtasticStatRelayShare => 'Diteruskan untuk lain';

  @override
  String get meshtasticStatRelayShareHint => 'Porsi dari yang dikirim';

  @override
  String get meshtasticStatRelayValue => 'Relai selesai';

  @override
  String get meshtasticStatRelaySolePath =>
      'Sering satu-satunya jalur — mesh bergantung padanya';

  @override
  String get meshtasticStatRelayRedundant =>
      'Node lain menutup jalur yang sama';

  @override
  String get meshtasticStatRedundancy => 'Penerimaan ganda';

  @override
  String get meshtasticStatThinEdge =>
      'Sedikit jalur cadangan — satu relai gagal bisa memutus';

  @override
  String get meshtasticStatWellCovered => 'Beberapa jalur mencapai sini';

  @override
  String get meshtasticStatErrorRate => 'Penerimaan rusak';

  @override
  String get meshtasticStatErrorRateHint =>
      'Naik saat airtime datar = interferensi';

  @override
  String get meshtasticTraceRoute => 'Telusuri rute';

  @override
  String get meshtasticTracing => 'Menelusuri…';

  @override
  String get meshtasticTraceUnreadable => 'Balasan tak terbaca';

  @override
  String get meshtasticTraceOffline => 'Radio belum terhubung';

  @override
  String get meshtasticTraceCooldown => 'Radio membatasi sekali per 30 detik';

  @override
  String get meshtasticTraceNoReply =>
      'Tidak ada balasan — di luar jangkauan atau kunci berbeda';

  @override
  String get meshtasticTraceDirect => 'Langsung — tanpa relai';

  @override
  String meshtasticTraceHops(int n) {
    return '$n lompatan';
  }

  @override
  String get moreDumpDiagnostics => 'Unggah info debug dan log';

  @override
  String get moreDumpDiagnosticsHint =>
      'Mengunggah lalu menyalin tautan untuk dilampirkan ke laporan';

  @override
  String get dumpIncludeSensitive => 'Sertakan lokasi presisi';

  @override
  String get dumpIncludeSensitiveHint =>
      'Menyertakan koordinat dari log dan lokasi latar belakang; jika tidak dipilih, diganti dengan null';

  @override
  String get dumpUpload => 'Unggah';

  @override
  String get dumpUploaded => 'Terunggah';

  @override
  String get dumpLinkCopied => 'Tautan disalin ke papan klip';

  @override
  String get dumpCopyAgain => 'Salin lagi';

  @override
  String get dumpUploadFailed => 'Gagal mengunggah';

  @override
  String get statusLegendUnprobed => 'Belum diperiksa';

  @override
  String get statusLegendUnsupported => 'Tidak tersedia';

  @override
  String get rainScaleSection => 'Skala warna';

  @override
  String get rainScaleFine => 'Halus';

  @override
  String get rainScaleCoarse => 'Kasar';

  @override
  String get notifyTestTitle => 'Uji notifikasi';

  @override
  String get notifyTestIntro =>
      'Mengetuk baris akan benar-benar mengirim peringatan itu. Peringatan penting berbunyi pada volume penuh dan menembus mode senyap serta Jangan Ganggu.';

  @override
  String get notifyTestCriticalDenied =>
      'Perangkat ini belum mengizinkan peringatan kritis, jadi peringatan penting tetap senyap saat ponsel disenyapkan.';

  @override
  String get notifyTestPermissionOff =>
      'Notifikasi dimatikan, jadi pengujian tidak akan menampilkan apa pun.';

  @override
  String get notifyTestBehaviourOverrides =>
      'Menembus mode senyap dan Jangan Ganggu';

  @override
  String get notifyTestBehaviourAlerts =>
      'Suara dan banner, kecuali ponsel sedang disenyapkan';

  @override
  String get notifyTestBehaviourSounds =>
      'Suara tanpa banner, kecuali ponsel sedang disenyapkan';

  @override
  String get notifyTestBehaviourSilent => 'Senyap — hanya di daftar notifikasi';

  @override
  String get notifyTestFailed => 'Tidak dapat mengirim notifikasi uji.';

  @override
  String get moreBugReports => 'Bug yang dilaporkan';

  @override
  String get bugTrackerEmpty => 'Belum ada bug yang dilaporkan';

  @override
  String get bugTrackerReplies => 'Balasan';

  @override
  String get bugTrackerGoToDiscord =>
      'Tidak menemukan masalahmu? Laporkan di Discord!';

  @override
  String get bugTrackerNoMatch =>
      'Tidak ada bug yang cocok dengan tag terpilih';

  @override
  String get bugTrackerDeveloper => 'Pengembang';

  @override
  String get bugTrackerCannotDisplay =>
      'Konten ini tidak dapat ditampilkan — lihat di Discord';

  @override
  String get bugTrackerJoinDiscussion => 'Ikuti diskusi di Discord';

  @override
  String get bugTrackerSortLast => 'Aktivitas terbaru';

  @override
  String get bugTrackerSortMostDiscussed => 'Paling banyak dibahas';

  @override
  String get bugTrackerStaff => 'Staf';

  @override
  String eewSpokenLocalIntensity(String intensity) {
    return 'Perkiraan intensitas di lokasi Anda: $intensity.';
  }

  @override
  String eewSpokenMaxIntensity(String intensity) {
    return 'Perkiraan intensitas maksimum: $intensity.';
  }
}
