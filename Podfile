# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

def shared_pods
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    pod 'Clarifai-Apple-SDK', '3.0.0-beta11'
    pod 'PromiseKit/Foundation'
    pod 'AFNetworking'
    pod 'SDWebImage', '~> 4.0'
    pod 'Analytics', '~> 3.0'
    pod 'Appsee'
    pod 'FBSDKCoreKit'
    pod 'FBSDKShareKit'
    pod 'FBSDKLoginKit'
    pod 'Branch'
    pod 'EggRating', :git => 'https://github.com/jacobrelkin/EGGRating.git', :branch => 'jacobrelkin/ios-11-support'
    pod 'Intercom'
    pod 'Firebase/Invites'
    pod 'Firebase/Auth'
    pod 'GoogleSignIn'
end

target 'screenshot' do
    shared_pods
end
