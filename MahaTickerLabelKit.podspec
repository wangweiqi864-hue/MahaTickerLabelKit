Pod::Spec.new do |s|
  s.name             = 'MahaTickerLabelKit'
  s.version          = '0.1.1'
  s.summary          = 'A private ticker label component used by the app.'

  s.description      = <<-DESC
MahaTickerLabelKit provides the app's private ticker-style numeric label
with app-specific public APIs for animated value rendering.
  DESC

  s.homepage         = 'https://github.com/wangweiqi864-hue/MahaTickerLabelKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wangweiqi864-hue' => 'wangweiqi864-hue@users.noreply.github.com' }
  s.source           = { :git => 'ssh://git@github.com/wangweiqi864-hue/MahaTickerLabelKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.source_files = 'MahaTickerLabelKit/Classes/**/*.{h,m}'
  s.frameworks = 'UIKit', 'QuartzCore'
  s.requires_arc = true
end
