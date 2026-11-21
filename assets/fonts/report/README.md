# Report-image fonts

`tool/dev/build_report_picture.sh` stages the fonts below from the pinned
eq-report-pic source. They are loaded from Flutter assets in fallback order
so the app carries one copy across all architectures.

| File | Family | Licence |
|---|---|---|
| `mplus-2p-bold.ttf` | M+ 2p Bold, Copyright (c) 2019 M+ FONTS PROJECT | Free software, unlimited permission to use, copy and distribute, with or without modification |
| `GenShinGothic-Bold.ttf` | Gen Shin Gothic Bold, based on Source Han Sans, Copyright © 2014, 2015 Adobe Systems Incorporated | SIL Open Font License 1.1 |
| `NotoSansTC-Black.ttf` | Noto Sans TC Black, Copyright (c) 2014–2021 Adobe | SIL Open Font License 1.1 |

The original notices remain in the TTF name tables. See `OFL.txt` for the
full text that accompanies the Gen Shin Gothic and Noto Sans TC fonts.

### M+ 2p Bold

> Copyright(c) 2019 M+ FONTS PROJECT
>
> This font is free software. Unlimited permission is granted to use, copy,
> and distribute it, with or without modification, either commercially or
> noncommercially. THIS FONT IS PROVIDED "AS IS" WITHOUT WARRANTY.

The build also stages `third-party-notices.txt` for the Rust crates and
`rust-library-copyright.html` for the Rust standard library.
