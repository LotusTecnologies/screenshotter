# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'
inhibit_all_warnings!

target 'screenshot' do
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    pod 'KochavaTrackeriOS'
    pod 'Clarifai-Apple-SDK', '3.0.0-beta14'
    pod 'PromiseKit/Foundation', '4.5.2'
    pod 'PromiseKit/StoreKit', '~> 4.0'
    pod 'SDWebImage', '~> 4.0'
    pod 'Analytics', '~> 3.0'
    pod 'Appsee'
    pod 'FacebookCore'
    pod 'FacebookLogin'
    pod 'FacebookShare'
    pod 'Branch'
    pod 'EggRating'
    pod 'Intercom'
    pod 'lottie-ios'
    pod 'Segment-Amplitude'
    pod 'SwiftKeychainWrapper'
    pod 'CreditCardValidator'
    pod 'Whisper'
    pod 'PhoneNumberKit'
    pod 'CardIO'
    pod 'PushwooshInboxUI', '~> 5.5'
    pod 'Pushwoosh', '~> 5.5'
end

post_install do |installer|
    Dir.chdir("Pods") do
        system("chmod u+w Branch/Branch-SDK/Branch-SDK/Branch.m && sed -i bak '/dispatch_sync.dispatch_get_main_queue/ s/dispatch_sync/dispatch_async/' Branch/Branch-SDK/Branch-SDK/Branch.m")
    end
end
