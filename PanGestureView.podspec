Pod::Spec.new do |s|
  s.name         = "PanGestureView"
  s.version      = "0.3"
  s.summary      = "UIView subclass that allows you to trigger actions based on Pan Gestures."
  s.description  = "PanGestureView allows you to attach custom actions that will be triggered when the user pans the view. Think of it as a swipeable UITableViewCell, but as a generic UIView."

  s.homepage     = "https://github.com/arvindhsukumar/PanGestureView"
  s.screenshots  = "http://i.imgur.com/P2E8ANB.gif"
  s.license      = "MIT"
  s.author             = { "Arvindh Sukumar" => "arvindh.sukumar@gmail.com" }
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/arvindhsukumar/PanGestureView.git", :tag => "0.2" }

  s.source_files  = "Classes", "Classes/**/*.{h,m}"
  s.exclude_files = "Classes/Exclude"
  s.swift_version = '5.0'
end
