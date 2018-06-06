//
//  SigninManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/4/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation
import PromiseKit
import AWSCognito
import AWSCognitoIdentityProviderASF
import AWSCore
import AWSCognitoIdentityProvider

class SigninManager : NSObject {
   
    enum UserConfirmedStatus {
        case confirmed
        case unconfirmed
    }
    enum SigninManagerError : Error {
        case error(NSError)
        case noInternet(NSError)
        case notSetup
    // Sign in error
        case authenticationFailed // wrong password or code
    // SignUpError
        case userAccountAlreadyExists
        case errorIllegalArgument //For creating an account the password must be at least x digits long etc
    }
    
    static let shared = SigninManager()

    var user:AWSCognitoIdentityUser?
    var pool:AWSCognitoIdentityUserPool?
    
    override init() {
        let credentialsProvider = AWSCognitoCredentialsProvider.init(regionType: .USEast1, identityPoolId: "us-east-1:dfdfa4f8-0991-4af5-9cc7-999eeb98a6b5")
        let serviseConfig = AWSServiceConfiguration.init(region: .USEast1, credentialsProvider: credentialsProvider)
        let cognitoIdentityUserPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration.init(clientId: "2g32lvnd3iui7nnul4k4qs8lh3", clientSecret: "of5kkq70mvo4f1i4k7j7b4n8k4imfseed83pd9ia8e6f5i7uuek", poolId: "us-east-1_AqZGFLzds", shouldProvideCognitoValidationData: true, pinpointAppId: "screenshop", migrationEnabled: true)
        AWSCognitoIdentityUserPool.register(with: serviseConfig, userPoolConfiguration: cognitoIdentityUserPoolConfiguration, forKey: "craze")
        self.pool = AWSCognitoIdentityUserPool.init(forKey: "craze")
        super.init()
//        self.pool?.delegate = self

    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return false
    }
    
    private func nserrorToSigninManagerError(_ error:NSError) ->SigninManagerError {
        // check if problem is no internet. etc
        if error.domain == AWSCognitoErrorDomain{
            if let code = AWSCognitoErrorType.init(rawValue: error.code) {
                if code == .errorTimedOutWaitingForInFlightSync || code == .errorWiFiNotAvailable {
                    return SigninManagerError.noInternet(error)
                }else if code == .errorIllegalArgument {
                    return SigninManagerError.errorIllegalArgument
                }else if code == .authenticationFailed {
                    return SigninManagerError.authenticationFailed
                }
            }
        }else if error.domain == NSURLErrorDomain {
            return SigninManagerError.noInternet(error)
        }
        return SigninManagerError.error(error)
    }
    
    //If unconfirmed, user must get a confirm code to finialize login
    func signUp(email:String, password:String) -> Promise<UserConfirmedStatus>{
        return Promise<UserConfirmedStatus>.init(resolvers: { (fulfil, reject) in
            let emailAttribute = AWSCognitoIdentityUserAttributeType.init(name: "email", value: email)
            if let pool = self.pool {
                pool.signUp(email, password: password, userAttributes: [emailAttribute], validationData: nil).continueWith(executor: AWSExecutor.mainThread(), block: { (task) -> Any? in
                    if let error = task.error  {
                        let nserror = error as NSError
                        reject(self.nserrorToSigninManagerError(nserror))
                    }else if let user = task.result?.user {
                        self.user = user
                        if user.confirmedStatus == .confirmed {
                            fulfil(UserConfirmedStatus.confirmed)
                        }else {
                            fulfil(UserConfirmedStatus.unconfirmed)
                        }
                    }else{
                        //shouldn't happen
                        reject(SigninManagerError.notSetup)
                    }
                    return nil
                })
            }else{
                reject(SigninManagerError.notSetup)
            }
            
        })
    }
    
    func confirmSignup(code:String) -> Promise<Void>{
        return Promise { fulfill, reject in
            if let user = self.user{
                user.confirmSignUp(code).continueWith(executor: AWSExecutor.mainThread(), block: { (task) -> Any? in
                    if let error = task.error  {
                        let nserror = error as NSError
                        reject(self.nserrorToSigninManagerError(nserror))
                    }else{
                        fulfill(())
                    }
                    return nil
                })
            }else{
                reject(SigninManagerError.notSetup)
            }
            
        }
    }
    
    func resendConfirmCode() -> Promise<Void>{
        return Promise { fulfill, reject in
            if let user = self.user{
                user.resendConfirmationCode().continueWith(executor: AWSExecutor.mainThread(), block: { (task) -> Any? in
                    if let error = task.error  {
                        let nserror = error as NSError
                        reject(self.nserrorToSigninManagerError(nserror))
                    }else{
                        fulfill(())
                    }
                    return nil
                })
            }else{
                reject(SigninManagerError.notSetup)
            }
        }
    }
    
    func forgotPassword(email:String) ->Promise<Void> {
        return Promise { fulfill, reject in
            if self.user == nil {
                self.user = self.pool?.getUser(email)
            }
            if let user = self.user  {
                user.forgotPassword().continueWith(executor: AWSExecutor.mainThread(), block: { (task) -> Any? in
                    if let error = task.error {
                        let nserror = error as NSError
                        reject(self.nserrorToSigninManagerError(nserror))
                    }else{
                        fulfill(())
                    }
                    return nil
                })
            }else{
                reject(SigninManagerError.errorIllegalArgument)
            }
            
            fulfill(())
        }
    }
    
    func confirmForgotPassword(code:String, password:String) ->Promise<Void> {
        return Promise { fulfill, reject in
            if let user = self.user {
                user.confirmForgotPassword(code, password: password).continueWith(executor: AWSExecutor.mainThread(), block: { (task) -> Any? in
                    if let error = task.error {
                        let nserror = error as NSError
                        reject(self.nserrorToSigninManagerError(nserror))
                    }else{
                        fulfill(())
                    }
                    return nil
                })
            }else{
                reject(SigninManagerError.notSetup)
            }
        }
    }
    
    func signOut() -> Promise<Void>{
        return Promise { fulfill, reject in
            if let user = self.user {
                if user.isSignedIn {
                    user.signOut()
                }
            }
            fulfill(())
        }
    }
    
    
    
}
//extension SigninManager : AWSCognitoIdentityInteractiveAuthenticationDelegate {
//    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
//
//    }
//
//    func startMultiFactorAuthentication() -> AWSCognitoIdentityMultiFactorAuthentication {
//
//    }
//
//    func startRememberDevice() -> AWSCognitoIdentityRememberDevice {
//
//    }
//
//    func startNewPasswordRequired() -> AWSCognitoIdentityNewPasswordRequired {
//
//    }
//
//    func startCustomAuthentication() -> AWSCognitoIdentityCustomAuthentication {
//
//    }
//
//    func startSoftwareMfaSetupRequired() -> AWSCognitoIdentitySoftwareMfaSetupRequired {
//
//    }
//
//    func startSelectMfa() -> AWSCognitoIdentitySelectMfa {
//
//    }
//}
