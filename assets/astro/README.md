# Lunar surface maps

Source: **NASA/Goddard Scientific Visualization Studio — CGI Moon Kit**
<https://svs.gsfc.nasa.gov/4720>

| File | What | Origin |
|---|---|---|
| `moon_color_2k.jpg` | Colour / albedo, equirectangular 2048×1024, centred on 0° longitude | `lroc_color_2k.jpg` — Hapke-normalised mosaic of >100,000 LRO Wide Angle Camera images, poles filled from the LOLA albedo map |
| `moon_height_1k.png` | Elevation, equirectangular 1024×512, 8-bit greyscale | `ldem_4_uint.tif` (LOLA laser altimeter, 4 px/°) downsampled and converted |

Both are derived from Lunar Reconnaissance Orbiter data. NASA imagery is
generally **not copyrighted** and may be used for any purpose; NASA requests
attribution and does not endorse any product. Kept as PNG for the elevation
map on purpose: the shader takes finite differences of it to build surface
normals, and JPEG block artefacts would show up as banding in the relief.
