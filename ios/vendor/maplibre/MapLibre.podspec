Pod::Spec.new do |s|
  s.name             = 'MapLibre'
  s.version          = '6.19.1'
  s.summary          = 'MapLibre Native iOS SDK — vendored xcframework.'
  s.description      = <<-DESC
    Vendored copy of the MapLibre Native iOS dynamic xcframework (v6.19.1),
    committed to the repo so `pod install` never downloads it. The upstream
    GitHub release CDN stalls unreliably here; this keeps the iOS build
    deterministic and offline-capable. Satisfies maplibre_gl's `MapLibre`
    dependency. Refresh by re-downloading the matching release zip.
  DESC
  s.homepage         = 'https://maplibre.org'
  s.license          = { :type => 'BSD-2-Clause', :file => 'LICENSE.md' }
  s.author           = { 'MapLibre' => 'info@maplibre.org' }
  s.platform         = :ios, '12.0'
  s.source           = { :path => '.' }
  s.vendored_frameworks = 'MapLibre.xcframework'
end
