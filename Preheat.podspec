Pod::Spec.new do |s|
    s.name             = "Preheat"
    s.version          = "4.0"
    s.summary          = "Automates precaching of content in UITableView and UICollectionView"

    s.homepage         = "https://github.com/kean/Preheat"
    s.license          = "MIT"
    s.author           = "Alexander Grebenyuk"
    s.social_media_url = "https://twitter.com/a_grebenyuk"
    s.source           = { :git => "https://github.com/kean/Preheat.git", :tag => s.version.to_s }

    s.ios.deployment_target = "8.0"
    s.tvos.deployment_target = "9.0"

    s.source_files  = "Sources/**/*"
end
