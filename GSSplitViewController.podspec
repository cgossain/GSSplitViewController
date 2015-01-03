Pod::Spec.new do |s|
  s.name          = "GSSplitViewController"
  s.version       = "1.0.0"
  s.summary       = "A replacement for Apple's UISplitViewController with the ability to change the width of the master pane. http://gossainsoftware.com"
  s.description   = <<-DESC
		    GSSplitViewController is for the most part a drop in replacement of UISplitViewController with extra features such as the ability to
		    set the width of the master pane (i.e. the left pane), the ability to show/hide the master pane programatically, and a few other goodies.
		    The API attempts to mimic that of the UISplitViewController, but there are some differences. There are slight differences in the
		    GSSplitViewControllerDelegate compared to the UISplitViewControllerDelegate. There are also additional properties and methods in
		    GSSplitViewController compared to UISplitViewController.
                    DESC
  s.homepage      = "https://github.com/cgossain/GSSplitViewController"
  s.license       = "MIT"
  s.author             = { "cgossain" => "cgossain@gmail.com" }
  s.social_media_url   = "http://twitter.com/ChrisGossain"
  s.platform      = :ios, "7.0"
  s.source        = { :git => "https://github.com/cgossain/GSSplitViewController.git", :tag => "1.0.0" }
  s.source_files  = "GSSplitViewController"
  s.frameworks    = "Foundation", "UIKit"
  s.requires_arc  = true
end
