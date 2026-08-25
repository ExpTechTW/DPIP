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
  const DeveloperNote({
    required this.title,
    required this.body,
    required this.date,
  });

  final String title;
  final String body;

  /// When the note was written, shown as a caption beside the title —
  /// a note about live incidents reads differently as it ages.
  final String date;
}

/// The note per locale, keyed by `Locale.toString()` (`zh_TW`, `en`, …).
/// Home-locale copy first, so the fallback below is a direct lookup.
const Map<String, DeveloperNote> _developerNotes = {
  'zh_TW': DeveloperNote(
    title: '開發者的話',
    date: '2026-08-26',
    body:
        '錯誤回報的速度，一直比修復的速度快——我們正以最快的步調趕工，'
        '懇請大家多多體諒。更新內容與各項處理進度，'
        '都能在本頁下方的「更新日誌」與「已回報的錯誤」追蹤。'
        '若有余力，也歡迎透過「支援 DPIP」給我們鼓勵與支持。',
  ),
  'zh': DeveloperNote(
    title: '开发者的话',
    date: '2026-08-26',
    body:
        '错误回报的速度，一直比修复的速度快——我们正以最快的步伐赶工，'
        '恳请大家多多体谅。更新内容与各项处理进度，'
        '都能在本页下方的“更新日志”与“已回报的错误”追踪。'
        '若有余力，也欢迎通过“支援 DPIP”给我们鼓励与支持。',
  ),
  'zh_Hant_HK': DeveloperNote(
    title: '開發者的話',
    date: '2026-08-26',
    body:
        '錯誤回報的速度，一直比修復的速度快——我們正以最快的步伐趕工，'
        '懇請大家多多體諒。更新內容與各項處理進度，'
        '都能在本頁下方的「更新日誌」與「已回報的錯誤」追蹤。'
        '若有餘力，也歡迎透過「支援 DPIP」給我們鼓勵與支持。',
  ),
  'zh_Hans': DeveloperNote(
    title: '开发者的话',
    date: '2026-08-26',
    body:
        '错误回报的速度，一直比修复的速度快——我们正以最快的步伐赶工，'
        '恳请大家多多体谅。更新内容与各项处理进度，'
        '都能在本页下方的“更新日志”与“已回报的错误”追踪。'
        '若有余力，也欢迎通过“支援 DPIP”给我们鼓励与支持。',
  ),
  'yue': DeveloperNote(
    title: '開發者嘅話',
    date: '2026-08-26',
    body:
        '問題回報嘅速度，一直比修復嘅速度快——我哋正以最快嘅步伐趕工，'
        '希望大家多多體諒。更新內容同各項處理進度，'
        '都可以喺本頁下方嘅「更新日誌」同「已回報嘅錯誤」查看。'
        '如果有力，歡迎透過「支援 DPIP」畀我哋鼓勵同支持。',
  ),
  'en': DeveloperNote(
    title: 'A word from the developers',
    date: '2026-08-26',
    body:
        'Bug reports keep arriving faster than we can fix them — the team is '
        'working flat out, and we ask for your patience. Every fix and its '
        'progress can be tracked under “Changelog” and “Reported bugs” at '
        'the bottom of this page. If you are able to, a little support '
        'through “Support DPIP” goes a long way.',
  ),
  'ja': DeveloperNote(
    title: '開発者からのお知らせ',
    date: '2026-08-26',
    body:
        'バグ報告のペースは修正のペースを常に上回っており、'
        'チームは全力で対応を進めています。今しばらくお待ちください。'
        '修正内容と進捗は、このページ下部の「更新履歴」と'
        '「報告済みのバグ」からご確認いただけます。'
        '余裕のある方は「DPIP を支援」から応援していただけると嬉しいです。',
  ),
  'ko': DeveloperNote(
    title: '개발자의 말',
    date: '2026-08-26',
    body:
        '버그 리포트가 수정 속도보다 빠르게 쌓이고 있습니다. '
        '팀은 전력을 다해 대응 중이오니 너른 양해 부탁드립니다. '
        '수정 내역과 진행 상황은 이 페이지 하단의 “업데이트 기록”과 '
        '“보고된 버그”에서 확인하실 수 있습니다. '
        '여유가 되신다면 “DPIP 지원”을 통해 응원해 주시면 큰 힘이 됩니다.',
  ),
  'th': DeveloperNote(
    title: 'ข้อความจากทีมพัฒนา',
    date: '2026-08-26',
    body:
        'รายงานบั๊กเข้ามาเร็วกว่าที่เราแก้ไขทัน '
        'ทีมงานกำลังเร่งดำเนินการเต็มที่ ขอความอดทนจากทุกคนด้วย '
        'ติดตามความคืบหน้าและเนื้อหาการอัปเดตได้ที่ '
        '"Update log" และ "Reported bugs" ด้านล่างของหน้านี้ '
        'หากพอมีกำลัง ช่วยสนับสนุนเราผ่าน "Support DPIP"',
  ),
  'vi': DeveloperNote(
    title: 'Lời từ đội ngũ phát triển',
    date: '2026-08-26',
    body:
        'Tốc độ nhận báo cáo lỗi luôn nhanh hơn tốc độ khắc phục — '
        'đội ngũ đang làm việc hết công suất, mong mọi người thông cảm. '
        'Nội dung cập nhật và tiến trình xử lý có thể theo dõi tại '
        '"Nhật ký cập nhật" và "Lỗi đã báo cáo" ở phần dưới trang này. '
        'Nếu dư sức, hãy ủng hộ chúng tôi qua "Hỗ trợ DPIP".',
  ),
  'id': DeveloperNote(
    title: 'Kata dari pengembang',
    date: '2026-08-26',
    body:
        'Laporan bug selalu masuk lebih cepat daripada perbaikannya — '
        'tim sedang bekerja sekuat mungkin dan mohon pengertian Anda. '
        'Setiap perbaikan dan progresnya bisa dipantau di bagian bawah '
        'halaman ini, pada "Log pembaruan" dan "Bug yang dilaporkan". '
        'Jika ada kemampuan, dukung kami melalui "Support DPIP".',
  ),
  'fil': DeveloperNote(
    title: 'Mensahe mula sa mga developer',
    date: '2026-08-26',
    body:
        'Mas mabilis ang pagdating ng mga bug report kaysa sa pag-aayos '
        'namin — pinupuno namin ang lahat ng aming makakaya, hiling namin '
        'ang inyong pang-unawa. Makikita ang bawat ayos at progreso sa '
        'ilalim ng pahinang ito: sa "Changelog" at "Mga naulat na bug". '
        'Kung may kakayahan kayo, suportahan kami sa pamamagitan ng '
        '"Support DPIP".',
  ),
};

/// The note for [locale], keyed by `Locale.toString()` ('zh_TW', 'en', …) —
/// an exact match first, then the home locale's copy (zh_TW), the same
/// fallback [AppLocalizations] uses for anything it does not serve.
DeveloperNote developerNoteFor(String locale) =>
    _developerNotes[locale] ?? _developerNotes['zh_TW']!;
