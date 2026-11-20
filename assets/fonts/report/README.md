# Report-image fonts

The three TTFs here are the fonts the native report-image renderer
(`ExpTechTW/eq-report-pic`, called over FFI) lays text out with. They are the
same files cwa-eq-map uses, so both draw the same image, and they are copied
from that library's `assets/fonts/` rather than sourced separately: the
renderer's fallback order is part of how an image looks, and a different cut of
the same family would move the text.

| File | Family | Licence |
|---|---|---|
| `mplus-2p-bold.ttf` | M+ 2p Bold — Copyright (c) 2019 M+ FONTS PROJECT | Free software; unlimited permission to use, copy and distribute, with or without modification |
| `GenShinGothic-Bold.ttf` | Gen Shin Gothic Bold — based on Source Han Sans, Copyright © 2014, 2015 Adobe Systems Incorporated | SIL Open Font License 1.1 |
| `NotoSansTC-Black.ttf` | Noto Sans TC Black — Copyright (c) 2014–2021 Adobe | SIL Open Font License 1.1 |

The full licence text is in each font's own `name` table (name IDs 13 and 14),
which is where the licence requires it to stay.

They are **not** embedded in the Rust library: doing that would add 13.8 MB to
every Android ABI. `ReportPicture` loads them from `rootBundle` and hands the
bytes over once, in the order listed above, when the renderer is created.

When updating them, update `fontAssets` in
`lib/shared/seismic/report_picture/report_picture.dart` and the asset list in
`pubspec.yaml` together — the renderer's fallback order is the list order.
