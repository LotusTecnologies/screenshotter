# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'
inhibit_all_warnings!

target 'Screenshop' do
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    pod 'KochavaTrackeriOS'
    pod 'Amplitude-iOS', '~> 4.2.1'
    pod 'PromiseKit/Foundation', '4.5.2'
    pod 'SDWebImage', '~> 4.0'
    pod 'Analytics', '~> 3.0'
    pod 'Appsee'
    pod 'Branch'
    pod 'lottie-ios'
    pod 'Whisper'
    pod 'PushwooshInboxUI'
    pod 'Hero'
    pod 'Firebase/Core'
    pod 'Firebase/Auth'
    pod 'Firebase/Database'
    pod 'Firebase/Storage'
    pod 'FBSDKLoginKit'
    pod 'SwiftLog', '~> 1.0.0'
    pod 'SWXMLHash'
    pod 'Cache'
    pod 'ActiveLabel'
end

post_install do |installer|
    Dir.chdir("Pods") do
        system("chmod u+w Branch/Branch-SDK/Branch-SDK/Branch.m && sed -i bak '/dispatch_sync.dispatch_get_main_queue/ s/dispatch_sync/dispatch_async/' Branch/Branch-SDK/Branch-SDK/Branch.m")
    end
end
