Pod::Spec.new do |s|
  s.name             = 'InteractiveImageView'
  s.version          = '1.0.28'
  s.summary          = 'Simple UIView to interact with UIImageView like scroll, zoom, rotate, pinch and crop.'
  s.homepage         = 'https://github.com/egzonpllana/InteractiveImageView'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Egzon Pllana' => 'docpllana@gmail.com' }
  s.source           = { :git => 'https://github.com/egzonpllana/InteractiveImageView.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/InteractiveImageView/**/*'
end
