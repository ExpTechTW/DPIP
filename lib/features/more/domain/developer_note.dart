/// The developer note card's copy, in every written language.
///
/// Kept in Dart (not ARB) on purpose: the note tracks live incidents and
/// changes faster than a release cycle — by the time an ARB change round-
/// trips through gen-l10n, translation review and a store build, the note is
/// already history. A raw Dart map can be edited and shipped in one commit.
/// It is also why this card lives outside the presentation layer: the l10n
/// gate scans [AppLocalizations]-routed files; a moving target here would
/// churn the generated delegates for nothing.
class DeveloperNote {
  const DeveloperNote({required this.title, required this.body});

  final String title;
  final String body;
}

/// The note per locale, keyed by `Locale.toString()` (`zh_TW`, `en`, …).
/// Home-locale copy first, so the fallback below is a direct lookup.
const Map<String, DeveloperNote> _developerNotes = {
  'zh_TW': DeveloperNote(
    title: '開發者的話',
    body:
        '我們注意到 Android 版本的 DPIP 還有不少問題，我們正在調查原因，'
        '將盡快修正並發布更新。若有其他問題可以至 Discord 社群回報，'
        '我們願意傾聽，但請不要直接至商店負評，直接負評的溝通效率很差，'
        '且對我們的打擊很大。',
  ),
  'zh': DeveloperNote(
    title: '開發者的話',
    body:
        '我們注意到 Android 版本的 DPIP 還有不少問題，我們正在調查原因，'
        '將盡快修正並發布更新。若有其他問題可以至 Discord 社群回報，'
        '我們願意傾聽，但請不要直接至商店負評，直接負評的溝通效率很差，'
        '且對我們的打擊很大。',
  ),
  'zh_Hant_HK': DeveloperNote(
    title: '開發者的話',
    body:
        '我們留意到 Android 版本的 DPIP 還有不少問題，我們正在調查原因，'
        '會盡快修正並發布更新。如有其他問題可以到 Discord 社群回報，'
        '我們願意傾聽，但請不要直接在商店留負評，直接負評的溝通效率很低，'
        '對我們的打擊也很大。',
  ),
  'zh_Hans': DeveloperNote(
    title: '开发者的话',
    body:
        '我们注意到 Android 版本的 DPIP 还有不少问题，我们正在调查原因，'
        '将尽快修复并发布更新。如有其他问题可以在 Discord 社区反馈，'
        '我们愿意倾听，但请不要直接在商店打差评，差评的沟通效率很低，'
        '对我们打击也很大。',
  ),
  'yue': DeveloperNote(
    title: '開發者嘅話',
    body:
        '我哋留意到 Android 版嘅 DPIP 仲有唔少問題，我哋而家正在調查原因，'
        '會盡快修正同發布更新。如果仲有其他問題，可以去 Discord 社群回報，'
        '我哋願意傾聽，但請唔好直接去商店留負評，負評嘅溝通效率好差，'
        '對我哋打擊好大。',
  ),
  'en': DeveloperNote(
    title: 'A word from the developers',
    body:
        'We know the Android version of DPIP still has a number of issues. '
        'We are investigating the causes and will fix them and ship an update '
        'as soon as possible. For anything else, please report it in our '
        'Discord community — we are listening — but please do not leave a '
        'negative review on the store: reviews are a poor channel for '
        'feedback, and they hurt us a lot.',
  ),
  'ja': DeveloperNote(
    title: '開発者からのお知らせ',
    body:
        'Android 版の DPIP にはまだ多くの問題があることを認識しています。'
        '原因を調査中で、できるだけ早く修正しアップデートをリリースします。'
        'その他の問題があれば Discord コミュニティまでご報告ください。'
        '拝聴いたしますが、ストアへの低評価だけはご遠慮ください。'
        '低評価はフィードバックの伝達効率が悪く、私たちにとって大きな'
        '打撃となります。',
  ),
  'ko': DeveloperNote(
    title: '개발자의 말',
    body:
        'Android 버전의 DPIP에 아직 적지 않은 문제가 있음을 알고 있습니다. '
        '원인을 조사 중이며, 최대한 빨리 수정하고 업데이트를 출시하겠습니다. '
        '다른 문제가 있으면 Discord 커뮤니티에 알려 주세요. 저희가 귀 '
        '기울여 듣겠습니다. 다만 스토어에 낮은 평점을 남기는 것은 삼가 '
        '주세요. 낮은 평점은 소통 효율이 매우 낮고, 저희에게 큰 타격이 됩니다.',
  ),
  'th': DeveloperNote(
    title: 'ข้อความจากทีมพัฒนา',
    body:
        'เราทราบว่าแอป DPIP เวอร์ชัน Android ยังมีปัญหาอีกหลายจุด '
        'เรากำลังหาสาเหตุและจะรีบแก้ไขพร้อมปล่อยอัปเดตโดยเร็วที่สุด '
        'หากมีปัญหาอื่น ๆ แจ้งได้ที่ชุมชน Discord เรายินดีรับฟัง '
        'แต่ขออย่าโพสต์รีวิวไม่ดีที่หน้าร้านแอป เพราะรีวิวไม่ดีสื่อสารได้ไม่ตรงจุด '
        'และกระทบเราอย่างหนัก',
  ),
  'vi': DeveloperNote(
    title: 'Lời từ đội ngũ phát triển',
    body:
        'Chúng tôi biết phiên bản DPIP trên Android vẫn còn khá nhiều vấn đề. '
        'Chúng tôi đang điều tra nguyên nhân và sẽ sớm khắc phục cùng phát '
        'hành bản cập nhật. Nếu gặp vấn đề khác, bạn có thể phản ánh tại cộng '
        'đồng Discord — chúng tôi sẵn sàng lắng nghe — nhưng mong bạn đừng để '
        'đánh giá tiêu cực trên cửa hàng ứng dụng, vì đánh giá tiêu cực không '
        'phải kênh trao đổi hiệu quả và ảnh hưởng rất lớn đến chúng tôi.',
  ),
  'id': DeveloperNote(
    title: 'Kata dari pengembang',
    body:
        'Kami menyadari DPIP versi Android masih memiliki cukup banyak '
        'masalah. Kami sedang menyelidiki penyebabnya dan akan segera '
        'memperbaikinya serta merilis pembaruan. Jika ada masalah lain, '
        'silakan laporkan ke komunitas Discord — kami siap mendengarkan — '
        'tetapi mohon jangan memberi ulasan buruk di toko aplikasi, karena '
        'ulasan buruk bukan sarana komunikasi yang efektif dan sangat '
        'berdampak bagi kami.',
  ),
  'fil': DeveloperNote(
    title: 'Mensahe mula sa mga developer',
    body:
        'Alam namin na may ilan pang problema ang bersyon ng DPIP sa Android. '
        'Iniimbestigahan namin ang dahilan at aayusin namin ito sa lalong '
        'madaling panahon, kasabay ng paglabas ng update. Kung may iba pang '
        'problema, maaari kayong mag-ulat sa Discord community — handa kaming '
        'makinig — ngunit mangyaring huwag mag-iwan ng negatibong review sa '
        'app store, dahil hindi epektibong paraan ng pakikipag-ugnayan ang '
        'negatibong review at malaki ang epekto nito sa amin.',
  ),
};

/// The note for [locale], keyed by `Locale.toString()` ('zh_TW', 'en', …) —
/// an exact match first, then the home locale's copy (zh_TW), the same
/// fallback [AppLocalizations] uses for anything it does not serve.
DeveloperNote developerNoteFor(String locale) =>
    _developerNotes[locale] ?? _developerNotes['zh_TW']!;
