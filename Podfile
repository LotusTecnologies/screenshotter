# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

def shared_pods
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    pod 'Clarifai-Apple-SDK', '3.0.0-beta4'
    pod 'PromiseKit/Foundation'
    pod 'AFNetworking'
    pod 'SDWebImage', '~> 4.0'
    pod 'Analytics', '~> 3.0'
    pod 'Appsee'
    pod 'FBSDKCoreKit'
    pod 'FBSDKShareKit'
    pod 'FBSDKLoginKit'
    pod 'ImageEffects'
    pod 'EggRating', :git => 'git@github.com:jacobrelkin/EGGRating.git', :branch => 'jacobrelkin/add-disadvantaged-flow-customization'
end

#target 'dev_influencer' do
#    shared_pods
#end
#
#target 'stg_influencer' do
#    shared_pods
#end

target 'screenshot' do
    shared_pods
end
