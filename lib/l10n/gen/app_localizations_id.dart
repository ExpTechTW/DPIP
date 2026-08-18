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
  String get regionSelectTitle => 'Pilih wilayah';

  @override
  String get skyTimeNoon => 'Siang';

  @override
  String get radarCountyOutlineSubtitle =>
      'Menjaga batas wilayah tetap terbaca di bawah gema radar.';

  @override
  String get dpmFilterSectionRestroomType => 'Jenis toilet';

  @override
  String get mapLayerSatelliteB03 => 'Himawari Red (B03)';

  @override
  String get reportFilterIntensity => 'Intensitas';

  @override
  String get mapLayerLightning => 'Petir';

  @override
  String get restroomTypeMale => 'Toilet pria';

  @override
  String get meshtasticLastReceived => 'Last received';

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
  String get meshtasticUptime => 'Uptime';

  @override
  String get weatherRankingTempExtremes => 'Ekstrem suhu';

  @override
  String get themeLight => 'Terang';

  @override
  String get mapTerrainReliefHint => 'Tampilkan relief terrain di peta dasar';

  @override
  String get meshtasticEmptyMessage => '(empty message)';

  @override
  String get moreSectionRegion => 'Wilayah';

  @override
  String get dpmDisasterEarthquake => 'Gempa';

  @override
  String get mapLayerSatellite => 'Himawari Infrared (B13)';

  @override
  String get aedHoursSaturday => 'Jam Sabtu';

  @override
  String get dpmDisasterSlope => 'Bencana lereng';

  @override
  String get moonPhaseNew => 'New moon';

  @override
  String get notifySectionEew => 'Peringatan dini gempa';

  @override
  String get mapResetNorth => 'Kembali ke utara';

  @override
  String get rainInterval2d => '2 hr';

  @override
  String get mapTownLabelsHint => 'Tampilkan nama kecamatan saat diperbesar';

  @override
  String get commonCancel => 'Cancel';

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
  String get typhoonHistoryTitle => 'Waktu data';

  @override
  String mapAppDefault(String app) {
    return '$app (bawaan)';
  }

  @override
  String get trendRange24h => '24 jam';

  @override
  String get mapLayerStyleJmaTooltip =>
      'Grayscale base, tinted below −40 °C to highlight cloud-top height';

  @override
  String weatherRankingRecordedAt(String time) {
    return 'Tercatat pukul $time';
  }

  @override
  String get mapLayerRain => 'Curah hujan';

  @override
  String get mapLayerQpesums => 'Prakiraan hujan 1 jam ke depan';

  @override
  String get mapOverlaySectionMap => 'Peta';

  @override
  String get mapTerrainRelief => 'Relief terrain';

  @override
  String get eewMaxIntensity => 'Intensitas maks';

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
      'Nodes bridged over the internet, not heard by radio';

  @override
  String get reportFilterIntensityInfoTitle => 'Skala intensitas baru & lama';

  @override
  String get mapLayerTyphoon => 'Topan';

  @override
  String get radarOverlayMenuTooltip => 'Opsi lapisan radar';

  @override
  String get mapMyLocation => 'Lokasi saya';

  @override
  String get meshtasticNodes => 'Nodes';

  @override
  String get meshtasticSend => 'Send';

  @override
  String get typhoonOverlayStormL7Tooltip =>
      'Level-7 wind field + average circle (purple)';

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
  String get meshtasticSilent => 'Silent';

  @override
  String get mapLayerCategoryEarthquake => 'Gempa';

  @override
  String get mapLayerSatelliteB12 => 'Himawari Ozone (B12)';

  @override
  String get typhoonLegendPast => 'Jalur aktual';

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
  String get meshtasticLayerOptions => 'Node options';

  @override
  String get onboardingAgreeContinue => 'Setuju dan lanjutkan';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get meshtasticNodeId => 'Node ID';

  @override
  String reportDetailNumbered(String number) {
    return 'Gempa Dirasakan Signifikan No. $number';
  }

  @override
  String get typhoonOverlayStormBandSubtitle => 'With average circle';

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
  String get meshtasticChannelWorking => 'Setting up the DPIP channel…';

  @override
  String get meshtasticRegionSwitch => 'Switch to TW';

  @override
  String get meshtasticTraffic => 'Traffic';

  @override
  String get mapLayerStyleBdTooltip =>
      'Dvorak BD curve — the stepped grayscale for tropical-cyclone intensity analysis';

  @override
  String get disasterMapOverlayAedTooltip => 'Tampilkan lokasi AED';

  @override
  String get mapLayerHumidity => 'Kelembapan';

  @override
  String get mapLayerSatelliteTransparentNight =>
      'Night = transparent, the basemap shows';

  @override
  String get meshtasticScanning => 'Scanning…';

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
  String get meshtasticDpipChannel => 'DPIP channel';

  @override
  String get disasterMapOverlaySectionLayers => 'Lapisan';

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
  String get reportListEmpty => 'Tidak ada laporan gempa';

  @override
  String get reportListEnd => 'Akhir daftar';

  @override
  String get mapLayerSatelliteTruecolor => 'Himawari True Color';

  @override
  String get typhoonOverlaySectionExtra => 'Overlays';

  @override
  String get eewSWave => 'Gelombang S';

  @override
  String get meshtasticBusyTitle => 'Another app is using this radio';

  @override
  String get restroomCategoryCultural => 'Tempat budaya';

  @override
  String get typhoonLabelWind => 'Max. sustained wind near centre';

  @override
  String get radarGlobalOutlineHint => 'Bingkai luar setiap negara';

  @override
  String get notifyEvacuation => 'Informasi bencana';

  @override
  String get typhoonLegendCircle15 => 'Lingkar angin kencang';

  @override
  String get dataSectionAstronomy => 'Astronomy';

  @override
  String get homeRainTrendLightSustained =>
      'Hujan ringan berlanjut selama 1 jam ke depan';

  @override
  String get commonError => 'Terjadi kesalahan';

  @override
  String get moonPhaseWaningCrescent => 'Waning crescent';

  @override
  String get meshtasticPower => 'Power';

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
  String get meshtasticTxPower => 'TX power';

  @override
  String get restroomCategoryLabel => 'Kategori';

  @override
  String get sponsorRestoring => 'Memulihkan pembelian…';

  @override
  String get sponsorIntro =>
      'DPIP berdedikasi menyediakan informasi mitigasi bencana secara real-time, tanpa iklan atau model bisnis lainnya. Dukungan Anda membantu kami menjaga server tetap berjalan dan terus mengembangkan aplikasi.';

  @override
  String get shelterAddressLabel => 'Alamat';

  @override
  String get typhoonLabelStormAvg => 'Avg. radius of Beaufort 10 winds';

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
  String get dataWeatherRankingSubtitle => 'Peringkat stasiun langsung';

  @override
  String homeRainTrendMinute(int minute) {
    return '$minute mnt';
  }

  @override
  String get rainInterval6h => '6 jam';

  @override
  String get restroomTypeUnspecified => 'Tidak ditentukan';

  @override
  String get typhoonOverlayProbabilityHint => 'Hides the forecast cone';

  @override
  String get mapLayerSatelliteGlobalOutline => 'Country border';

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
      'Radar echo closest to the typhoon bulletin time';

  @override
  String get onboardingPermLocationDesc =>
      'Menargetkan peringatan ke lokasi Anda.';

  @override
  String get mapLayerSatelliteB16 => 'Himawari CO₂ (B16)';

  @override
  String get homeActiveEventsEmpty => 'Tidak ada peristiwa aktif';

  @override
  String get typhoonLabelPosition => 'Centre location';

  @override
  String get weatherRankingBy => 'Urut';

  @override
  String get typhoonIntensityMild => 'Mild typhoon';

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
  String get meshtasticRole => 'Role';

  @override
  String get mapLayerSatelliteCloudCloudy => 'Cloudy';

  @override
  String get skyTimeSunrise => 'Matahari terbit';

  @override
  String get meshtasticJumpToLatest => 'Ke yang terbaru';

  @override
  String get meshtasticNoMessages => 'No messages yet';

  @override
  String get onboardingPermNotifyDesc =>
      'Menyampaikan peringatan gempa, cuaca, dan bencana pada saat terjadi.';

  @override
  String get radarTownOutline => 'Batas kecamatan';

  @override
  String get mapLayerStyleSection => 'Colour style';

  @override
  String get disasterMapOverlayMenuTooltip => 'Lapisan peta bencana';

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
  String get dpmDisasterTsunami => 'Tsunami';

  @override
  String get changelogTypeStable => 'Stabil';

  @override
  String get mapLayerSatelliteTransparentClear =>
      'Clear sky = transparent, the basemap shows';

  @override
  String get mapOverlaySectionReference => 'Lapisan referensi';

  @override
  String get mapLayerSatelliteB02 => 'Himawari Green (B02)';

  @override
  String get reportListLocalFelt => 'Terasa lokal';

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
  String get meshtasticNoDevices => 'No Meshtastic devices found';

  @override
  String get mapLayerCategoryLife => 'Kehidupan sehari-hari';

  @override
  String get reportFilterSortIntensity => 'Intensitas';

  @override
  String get typhoonMotion => 'Bergerak';

  @override
  String get meshtasticStateDisconnected => 'Disconnected';

  @override
  String get typhoonIntensityIntense => 'Intense typhoon';

  @override
  String get mapLayerOrderTitle => 'Urutkan lapisan';

  @override
  String get dpmYes => 'Ya';

  @override
  String get meshtasticNoHistory => 'Not enough history yet';

  @override
  String get reportDetailLocalIntensityUnavailable =>
      'Tidak ada data intensitas';

  @override
  String get mapLayerWindForecastGfs => 'GFS';

  @override
  String get reportListDepthUnit => 'km';

  @override
  String get reportFilterDepth => 'Kedalaman';

  @override
  String get onboardingScrollHint => 'Gulir ke bawah untuk melanjutkan';

  @override
  String get mapNavQpesums => 'Prakiraan';

  @override
  String get navMap => 'Peta';

  @override
  String get notifyAdvisory => 'Imbauan cuaca';

  @override
  String get reportFilterReset => 'Reset';

  @override
  String get mapLayerSatelliteMndwi => 'Himawari MNDWI';

  @override
  String get typhoonOverlaySectionStorm => 'Storm wind';

  @override
  String get moonPhaseFull => 'Full moon';

  @override
  String get moonPhaseWaningGibbous => 'Waning gibbous';

  @override
  String get weatherDynamicStateSubtitle => 'Ganti cuaca latar beranda';

  @override
  String get reportFilterIntensityInfoModernTitle => 'Baru (sejak 2020)';

  @override
  String typhoonDataTime(String time) {
    return 'Data time\n$time';
  }

  @override
  String get restroomTypeAccessible => 'Toilet aksesibel';

  @override
  String get moreSectionAbout => 'Tentang';

  @override
  String get meshtasticSelectDevice => 'Select a radio';

  @override
  String get onboardingIntroBody =>
      'DPIP adalah pendamping pencegahan bencana Anda. DPIP menyatukan peringatan dini gempa, laporan gempa, cuaca, dan informasi bahaya, serta memberi tahu Anda pada saat yang penting.\n\n• Gempa bumi: peringatan dini, laporan intensitas, dan laporan rinci\n• Cuaca: pesan badai petir waktu nyata dan imbauan cuaca\n• Tsunami dan informasi bencana\n\nSelanjutnya, kami akan meminta Anda meninjau Ketentuan Layanan dan memberikan beberapa izin agar DPIP dapat melindungi Anda secara waktu nyata.';

  @override
  String get shelterCapacityLabel => 'Kapasitas';

  @override
  String get reportDetailImage => 'Gambar laporan';

  @override
  String get meshtasticStateConfiguring => 'Configuring…';

  @override
  String get typhoonLabelGaleAvg => 'Avg. radius of Beaufort 7 winds';

  @override
  String get onboardingPermNotify => 'Notifikasi';

  @override
  String get meshtasticClearMessages => 'Clear messages';

  @override
  String get meshtasticNotifyMessages => 'Notify on new messages';

  @override
  String get defaultMapLayerSettings => 'Lapisan peta bawaan';

  @override
  String get moreSectionNotify => 'Notifikasi';

  @override
  String get notifyUnavailable =>
      'Notifikasi push belum siap — coba lagi sebentar lagi.';

  @override
  String get mapLayerOrderReset => 'Atur ulang urutan';

  @override
  String get dpmAddress => 'Alamat';

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
  String get typhoonLegendCircleAvg => 'Average circle';

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
  String get typhoonLabelGust => 'Peak gust';

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
  String get moonAge => 'Age';

  @override
  String get meshtasticRadioSettings => 'LoRa';

  @override
  String weatherRankingAnalysisCurrent(String value) {
    return 'Sekarang $value°C';
  }

  @override
  String get moreGithub => 'ExpTech GitHub';

  @override
  String get homeForecastUnavailable => 'Pilih wilayah untuk melihat prakiraan';

  @override
  String get mapLayers => 'Lapisan';

  @override
  String get meshtasticHardware => 'Hardware';

  @override
  String get languageSettings => 'Bahasa';

  @override
  String get dpmDisasterNuclear => 'Kecelakaan nuklir';

  @override
  String get language => 'Bahasa';

  @override
  String homeForecastFeelsLike(String temp) {
    return 'Terasa $temp°';
  }

  @override
  String get typhoonOverlayWeatherHint => 'Aligned to bulletin time';

  @override
  String get skyTimeDawn => 'Fajar';

  @override
  String get skyTimeAfternoon => 'Sore';

  @override
  String get meshtasticLastHeard => 'Last heard';

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
  String get typhoonGust => 'Embusan';

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
      'Level-10 wind field + average circle (yellow)';

  @override
  String get moonPhaseWaxingGibbous => 'Waxing gibbous';

  @override
  String get reportDetailTitle => 'Laporan Gempa';

  @override
  String get moreTremReport => 'Laporan deteksi TREM';

  @override
  String weatherDataTime(String station, String time) {
    return '$station · Waktu data $time';
  }

  @override
  String get meshtasticNoNodes => 'No nodes heard yet';

  @override
  String get meshtasticViaMqtt => 'Via MQTT (internet)';

  @override
  String get radarCountyOutline => 'Batas kabupaten/kota';

  @override
  String get onboardingGranted => 'Diberikan';

  @override
  String get commonClose => 'Tutup';

  @override
  String get restroomGradeLabel => 'Nilai';

  @override
  String get rainIntervalNow => 'Hari ini';

  @override
  String get changelogCurrentVersion => 'Saat ini';

  @override
  String get typhoonLabelPressure => 'Central pressure';

  @override
  String get typhoonOverlayForecastCalloutsTooltip =>
      'Show forecast-point detail cards when zoomed in';

  @override
  String get aedOpenRemark => 'Catatan jam buka';

  @override
  String get onboardingPermsBody =>
      'Agar DPIP dapat memperingatkan Anda saat bencana terjadi, harap berikan izin berikut. Anda dapat mengubahnya kapan saja di pengaturan sistem.';

  @override
  String get typhoonOverlaySectionWeather => 'Weather underlay';

  @override
  String get notifyOptWeatherLocal => 'Hanya lokasi saat ini';

  @override
  String get mapNavRain => 'Hujan';

  @override
  String get moonDays => 'days';

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
  String get meshtasticExternalPower => 'External power';

  @override
  String get moonPhaseLastQuarter => 'Last quarter';

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
  String get meshtasticLastSent => 'Last sent';

  @override
  String get meshtasticName => 'Name';

  @override
  String get meshtasticScan => 'Scan';

  @override
  String get mapLayerCategoryForecast => 'Prakiraan numerik';

  @override
  String get meshtasticChannelFailed => 'Couldn\'t set up the DPIP channel';

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
  String get moonNextFullMoon => 'Next full moon';

  @override
  String get dpmSheetEmpty => 'Ketuk penanda di peta untuk detail';

  @override
  String get onboardingSkipLeave => 'Tetap lewati';

  @override
  String get onboardingBack => 'Kembali';

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
  String get typhoonPressure => 'Tekanan';

  @override
  String get onboardingPermBattery => 'Pengecualian baterai';

  @override
  String get typhoonLabelNw => 'NW';

  @override
  String get dpmDisasterFlood => 'Banjir';

  @override
  String get moonPhaseWaxingCrescent => 'Waxing crescent';

  @override
  String get restroomCategoryLeisure => 'Tempat rekreasi';

  @override
  String get mapLayerTemperature => 'Suhu';

  @override
  String get aedCategory => 'Kategori';

  @override
  String get meshtasticChannels => 'Channels';

  @override
  String get monitorWaiting => 'Menunggu data…';

  @override
  String get typhoonOverlayForecastCallouts => 'Forecast tooltips';

  @override
  String get reportDetailEpicenter => 'Koordinat episentrum';

  @override
  String get meshtasticVoltage => 'Voltage';

  @override
  String get mapLayerMeshtasticSubtitle =>
      'LoRa mesh nodes heard by your radio';

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
  String get dpmDisasterLandslide => 'Tanah longsor';

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
      'Zero difference = transparent (no signal)';

  @override
  String get shelterIndoorLabel => 'Penampungan dalam ruangan';

  @override
  String get notifyOptOff => 'Nonaktif';

  @override
  String get reportFilterSortTime => 'Waktu';

  @override
  String get mapLayerSatelliteCloudProbablyClear => 'Probably clear';

  @override
  String get weatherModeThunderstorm => 'Badai petir';

  @override
  String get homeViewOnMap => 'Lihat di peta';

  @override
  String get reportFilterIntensityInfoLegacyTitle => 'Lama (sebelum 2020)';

  @override
  String get typhoonLabelSpeed => 'Past movement speed';

  @override
  String mapAppOpenFailed(String app) {
    return 'Tidak dapat membuka $app';
  }

  @override
  String get mapLayerSatelliteRgbComposite => 'RGB composite (JMA recipe)';

  @override
  String get meshtasticReceived => 'Received';

  @override
  String get weatherRankingExtremeLow => 'Minimum hari ini';

  @override
  String get mapLayerSatelliteB10 => 'Himawari Lower Water Vapour (B10)';

  @override
  String get mapLayerSatelliteCloudProbablyCloudy => 'Probably cloudy';

  @override
  String get mapLayerSatelliteTransparentNoWater =>
      '≤ 0 = transparent (no water)';

  @override
  String get shelterCategoryLabel => 'Jenis bencana';

  @override
  String get meshtasticStateConnecting => 'Connecting…';

  @override
  String get moonTitle => 'Moon';

  @override
  String get weatherRankingGust => 'Hembusan';

  @override
  String get moreAppStore => 'App Store';

  @override
  String get dpmFilterSectionShelter => 'Jenis bencana tempat berlindung';

  @override
  String get moreServerStatus => 'Status server';

  @override
  String get notifySectionWeather => 'Cuaca';

  @override
  String get meshtasticPreset => 'Modem preset';

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
  String get dpmFilterSectionRestroom => 'Jenis tempat';

  @override
  String get meshtasticNotConnected => 'Not connected to a radio';

  @override
  String get weatherModeSnow => 'Salju';

  @override
  String get mapLayerMeshtastic => 'Meshtastic nodes';

  @override
  String get moreDeveloper => 'Info debug';

  @override
  String get mapLayerSatelliteB14 => 'Himawari Longwave Infrared (B14)';

  @override
  String get meshtasticChannelUse => 'Channel use';

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
  String get meshtasticNotifyNodes => 'Notify on new nodes';

  @override
  String get onboardingPermCriticalDesc =>
      'Memungkinkan peringatan gempa yang mengancam jiwa tetap berbunyi bahkan dalam mode senyap atau Jangan Ganggu.';

  @override
  String get mapLayerSatelliteTransparentWarm =>
      'Clear sky (warm end) = transparent, the basemap shows';

  @override
  String get meshtasticSent => 'Sent';

  @override
  String get homeForecastTitle => 'Prakiraan 24 jam';

  @override
  String get typhoonLegendWarningAreas => 'Area peringatan';

  @override
  String meshtasticExcludeMqttHidden(int count) {
    return '$count hidden';
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
  String get meshtasticTapNode => 'Tap a node for details';

  @override
  String get commonLoading => 'Memuat…';

  @override
  String get typhoonIntensityModerate => 'Moderate typhoon';

  @override
  String get typhoonWind => 'Angin';

  @override
  String get mapLayerSatelliteAsh => 'Himawari Ash';

  @override
  String get rainInterval3h => '3 jam';

  @override
  String get reportListSearch => 'Cari';

  @override
  String get mapLayerCategorySatellite => 'Satelit';

  @override
  String get meshtasticChannelReady => 'DPIP channel ready';

  @override
  String get reportFilterLocation => 'Lokasi';

  @override
  String get mapLayerSatelliteNightmicrophysics =>
      'Himawari Night Microphysics';

  @override
  String get typhoonIntensityTd => 'Tropical depression';

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
  String get sponsorCalloutBody =>
      'Tanpa iklan — dukunganmu menjaga server tetap berjalan.';

  @override
  String get moreDiscordCalloutBody =>
      'Gabung komunitas dan mengobrol dengan tim.';

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
  String get meshtasticStateError => 'Error';

  @override
  String get weatherModeOvercast => 'Mendung';

  @override
  String get reportDetailDepth => 'Kedalaman hiposenter';

  @override
  String get typhoonOverlayWarningTooltip =>
      'Highlight counties under a typhoon warning';

  @override
  String get reportFilterDatePick => 'Pilih tanggal';

  @override
  String get onboardingSkipStay => 'Kembali';

  @override
  String get commonFetchFailed => 'Tidak dapat memuat data. Silakan coba lagi.';

  @override
  String get shelterOutdoorLabel => 'Penampungan luar ruangan';

  @override
  String get meshtasticStateConnected => 'Connected';

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
      'No radar or infrared underlay';

  @override
  String get radarCountyOutlineHint => 'Digambar di atas gema';

  @override
  String get windForecastCountyOutlineHint => 'Digambar di atas bidang angin';

  @override
  String get homeRainTrendTitle => 'Hujan 1 jam ke depan';

  @override
  String get moonPhaseFirstQuarter => 'First quarter';

  @override
  String get mapLayerCategoryTyphoon => 'Topan';

  @override
  String get meshtasticUtilization => 'Airtime (24h)';

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
  String get meshtasticReadingAge => 'Reading taken';

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
  String typhoonTimeChip(String day, String hour) {
    return '$day日$hour時';
  }

  @override
  String get rainIntervalMenu => 'Jendela akumulasi';

  @override
  String get reportDetailLocalFelt => 'Gempa Dirasakan Lokal';

  @override
  String get meshtasticDevice => 'Device';

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
  String get meshtasticExcludeMqtt => 'Hide MQTT nodes';

  @override
  String get mapNavTyphoon => 'Topan';

  @override
  String get weatherModeSand => 'Debu';

  @override
  String get typhoonSatelliteTitle => 'Satelit';

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
  String get meshtasticHopLimit => 'Hop limit';

  @override
  String weatherRankingAnalysisRange(String value) {
    return 'Rentang $value°C';
  }

  @override
  String get weatherRankingExtremeHigh => 'Maksimum hari ini';

  @override
  String get changelogVersionDetails => 'Detail rilis';

  @override
  String get sponsorPrivacy => 'Kebijakan Privasi';

  @override
  String get reportDetailLocalIntensity => 'Intensitas di lokasi Anda';

  @override
  String get mapLayerSatelliteNaturalcolor => 'Himawari Natural Color';

  @override
  String get meshtasticAirtime => 'Air time (TX)';

  @override
  String shelterCapacityValue(int n) {
    return '$n orang';
  }

  @override
  String lightningLegendCc(int minutes) {
    return 'Awan–awan · $minutes mnt';
  }

  @override
  String get meshtasticSendHint => 'Message to broadcast';

  @override
  String monitorDelay(String value) {
    return 'Latensi $value s';
  }

  @override
  String get dpmNo => 'Tidak';

  @override
  String get mapLayerSatelliteB08 => 'Himawari Upper Water Vapour (B08)';

  @override
  String get meshtasticReconnecting => 'Reconnecting…';

  @override
  String get radarTownOutlineSubtitle =>
      'Menjaga batas kecamatan tetap terbaca di bawah gema radar.';

  @override
  String get typhoonOverlayWeatherSatelliteTooltip =>
      'Infrared closest to the typhoon bulletin time';

  @override
  String get radarScanRangeHint => 'Di luar kotak berarti tak terpantau';

  @override
  String typhoonPickerTd(String no) {
    return 'Tropical depression TD $no';
  }

  @override
  String get mapLayerSatelliteWatervapor => 'Himawari Water Vapour';

  @override
  String get regionAddButton => 'Tambah wilayah';

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
  String get mapLayerStyleTooltip => 'Colour style';

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
  String get endpointLastSuccessNever => 'belum berhasil';

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
  String get endpointServiceDpm => 'Disaster points';

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
  String get endpointServiceTremStation => 'Tremor station';

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
      'Disconnect it in the other Meshtastic app first. Two apps on one radio take each other\'s messages, so some will go missing.';

  @override
  String get meshtasticChannelNoSlot =>
      'No free channel slot — free one on the radio';

  @override
  String get restroomCategoryTransport => 'Transportasi';

  @override
  String get reportFilterLocationHint => 'mis. Hualien, lepas pantai';

  @override
  String get moonSubtitle => 'Lunar phase and illumination — computed locally';

  @override
  String get meshtasticBattery => 'Battery';

  @override
  String get meshtasticDistance => 'Jarak';

  @override
  String get meshtasticSnrTrend => 'Tren sinyal (SNR)';

  @override
  String get meshtasticBatteryTrend => 'Tren baterai';

  @override
  String get typhoonOverlayMenuTooltip => 'Typhoon overlay options';

  @override
  String get mapLayerSatelliteBtdOzone => 'Himawari Tropopause';

  @override
  String meshtasticRegionMismatch(String region) {
    return 'Radio region is $region — DPIP needs TW';
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
  String get moreVersionNotes => 'Versi saat ini';

  @override
  String get moreVersionNotesEmpty => 'Tidak ada changelog untuk build ini';

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
  String get typhoonLabelProbCircle => '70% probability circle';

  @override
  String get notifyOptAll => 'Terima semua';

  @override
  String get displayTheme => 'Tema';

  @override
  String get mapLayerSatelliteB07 => 'Himawari Shortwave Infrared (B07)';

  @override
  String get typhoonLabelDirection => 'Past movement direction';

  @override
  String get regionManageTitle => 'Wilayah tersimpan';

  @override
  String get regionSaveNote =>
      'Notifikasi dikirim berdasarkan lokasi GPS Anda. Menyimpan wilayah sering dipakai tidak mengubah tempat pengiriman peringatan — wilayah sering dipakai hanya agar status tiap wilayah terlihat cepat di beranda. Izinkan akses lokasi, jika tidak notifikasi tidak berfungsi.';

  @override
  String get typhoonLegendCone => 'Kerucut prakiraan';

  @override
  String get moreCwaEew => 'Peringatan dini gempa CWA';

  @override
  String get onboardingPermsTitle => 'Izin';

  @override
  String get mapLayerStyleJma => 'Cloud-top enhancement (JMA)';

  @override
  String get rainInterval10m => '10 mnt';

  @override
  String weatherRankingAnalysisLow(String value) {
    return 'Min $value';
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
    return '${hour}j';
  }

  @override
  String get mapLayerShelter => 'Tempat Evakuasi';

  @override
  String get typhoonOverlayProbabilityTooltip =>
      'Show strike probability (hides the forecast cone)';

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
  String get meshtasticShortName => 'Short name';

  @override
  String get mapLayerSatelliteAirmass => 'Himawari Airmass';

  @override
  String get typhoonTrackDetail => 'Detail jalur';

  @override
  String get dataSectionWeather => 'Cuaca';

  @override
  String get aedHoursWeekday => 'Jam hari kerja';

  @override
  String get homeActiveEventsTitle => 'Peristiwa aktif';

  @override
  String weatherRankingAnalysisHigh(String value) {
    return 'Maks $value';
  }

  @override
  String get faq => 'FAQ';

  @override
  String get typhoonHistoryLive => 'Langsung';

  @override
  String eewSerial(int serial) {
    return 'Laporan $serial';
  }

  @override
  String get reportFilterSort => 'Urutan';

  @override
  String get meshtasticRegionConfirm =>
      'Switch this radio to the TW region? It restarts and disconnects for a moment, and every other channel on it moves too.';

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
  String get mapTownLabels => 'Nama kecamatan';

  @override
  String get notifySetFailed =>
      'Tidak dapat menyimpan pengaturan. Silakan coba lagi.';

  @override
  String get meshtasticDisconnect => 'Disconnect';

  @override
  String get meshtasticUndecoded => 'Not decrypted';

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
  String get mapPlaceholderDisabled => 'Peta (dinonaktifkan sementara)';

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
  String get sunSubtitle => 'Matahari terbit, senja, dan istilah surya';

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
  String get sunBlueHour => 'Blue hour';

  @override
  String get sunEquationOfTime => 'Persamaan waktu';

  @override
  String get sunMinutes => 'mnt';

  @override
  String get solarTermNext => 'Istilah berikutnya';

  @override
  String get planetsTitle => 'Planet';

  @override
  String get planetsSubtitle => 'Di mana malam ini, dan seberapa terang';

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
  String get tonightSubtitle => 'Apa yang terlihat, dan kapan';

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
  String get almanacSubtitle => 'Tanggal lunisolar dan gerhana mendatang';

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
  String get tideSubtitle => 'Purnama, perbani, dan tarikan Bulan';

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
  String get skyChartSubtitle => 'Langit yang terlihat mata telanjang';

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
}
