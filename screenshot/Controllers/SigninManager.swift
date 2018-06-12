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
import AWSFacebookSignIn

class SigninManager : NSObject {
    enum LoginOrCreateAccountResult {
        case login
        case createAccountUnconfirmed
        case createAccountConfirmed
    }
    enum SigninManagerError : Error {
        case error(NSError)
        case noInternet(NSError)
        case notSetup
    // Sign in error
        case authenticationFailed // wrong password or code
    // SignUpError
        case errorIllegalArgument //For creating an account the password must be at least x digits long etc
    }

    static let shared = SigninManager()

    var userAccountsCreatedByApp:[String] {
        get {
            if let array = UserDefaults.standard.object(forKey: UserDefaultsKeys.userAccountsCreatedByDevice) as? [String] {
                return array
            }
            return []
        }
        set {
            UserDefaults.standard.setValue(userAccountsCreatedByApp, forKey: UserDefaultsKeys.userAccountsCreatedByDevice)
        }
    }
    var user:AWSCognitoIdentityUser?
    var pool:AWSCognitoIdentityUserPool?
//    var anon:AWSAnonymousCredentialsProvider?
    var facebook = AWSFacebookSignInProvider.sharedInstance()
    private var userCredential:AWSCredentials?
    
    override init() {
        
        let credentialsProvider = AWSCognitoCredentialsProvider.init(regionType: .USEast1, identityPoolId: "us-east-1:dfdfa4f8-0991-4af5-9cc7-999eeb98a6b5")
        
        let serviseConfig = AWSServiceConfiguration.init(region: .USEast1, credentialsProvider: credentialsProvider)
        let cognitoIdentityUserPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration.init(clientId: "2g32lvnd3iui7nnul4k4qs8lh3", clientSecret: "of5kkq70mvo4f1i4k7j7b4n8k4imfseed83pd9ia8e6f5i7uuek", poolId: "us-east-1_AqZGFLzds", shouldProvideCognitoValidationData: true, pinpointAppId: "screenshop", migrationEnabled: true)
        AWSCognitoIdentityUserPool.register(with: serviseConfig, userPoolConfiguration: cognitoIdentityUserPoolConfiguration, forKey: "craze")
        self.pool = AWSCognitoIdentityUserPool.init(forKey: "craze")
        
        AWSSignInManager.sharedInstance().register(signInProvider: self.facebook)
        super.init()
        
//        self.pool?.delegate = self

    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.facebook.interceptApplication(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        var handled = false
        if !handled{
            let source = options[.sourceApplication] as? String
            let annotation = options[.annotation]
            handled = self.facebook.interceptApplication(app, open: url, sourceApplication: source, annotation: annotation ?? "")
        }
        return handled
    }
    
    public func nserrorToSigninManagerError(_ error:NSError) ->SigninManagerError {
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
    
    public func loginWithFacebook()  -> Promise<Void>{
        return Promise<Void>.init(resolvers: { (fulfil, reject) in
            AWSSignInManager.sharedInstance().login(signInProviderKey: self.facebook.identityProviderName, completionHandler: { (result, error) in
                if let error = error {
                    reject(error)
                }else if let result = result{
                    if let credentials = result as? AWSCredentials {
                        self.userCredential = credentials
                        fulfil(())
                    }else{
                        reject(SigninManagerError.notSetup)

                    }
                }else{
                    reject(SigninManagerError.notSetup)
                }
            })
        })
    }
//    func skipLogin() -> Promise<Void>{
//        let anon = AWSAnonymousCredentialsProvider.init()
//        AWSSignInManager.sharedInstance().login(signInProviderKey: <#T##String#>, completionHandler: <#T##(Any?, Error?) -> Void#>)
//    }
    
    public func loginOrCreatAccountAsNeeded(email:String, password:String) -> Promise<LoginOrCreateAccountResult> {
        
        return createAccount(email:email.lowercased(), password: password).recover(execute: { (error) -> Promise<SigninManager.LoginOrCreateAccountResult> in
            let nsError = error as NSError
            let usernameExistsException = 37
            if nsError.code == usernameExistsException && nsError.domain == AWSCognitoIdentityProviderErrorDomain {
                return self.login(email: email.lowercased(), password: password).recover(execute: { (error) -> Promise<SigninManager.LoginOrCreateAccountResult> in
                    let nsError = error as NSError
                    let userNotConfirmedException = 33
                    if nsError.code == userNotConfirmedException && nsError.domain == AWSCognitoIdentityProviderErrorDomain {
                        if self.userAccountsCreatedByApp.contains(email.lowercased()) {
                            return self.resendConfirmCode(email: email.lowercased()).then(execute: { () -> (Promise<LoginOrCreateAccountResult>) in
                                return Promise.init(value: .createAccountUnconfirmed)
                            })
                        }else{
                            return self.deleteUnconfirmedAccount(email: email.lowercased()).then(on: .main, execute: { () -> Promise<LoginOrCreateAccountResult> in
                                return self.createAccount(email: email.lowercased(), password: password)
                            })
                        }
                    }
                    return Promise.init(error: nsError)
                })
            }
            return Promise.init(error: nsError)
        })
        
    }
    private func deleteUnconfirmedAccount(email:String) -> Promise<Void>{
        return Promise.init(resolvers: { (fulfil, reject) in
            reject(SigninManagerError.notSetup)
        })
    }
    private func login(email:String, password:String) -> Promise<LoginOrCreateAccountResult>{
        return Promise<LoginOrCreateAccountResult>.init(resolvers: { (fulfil, reject) in
            
            if let pool = self.pool, let userName = email.sha1() {
                let emailAttribute = AWSCognitoIdentityUserAttributeType.init(name: "email", value: email)
                
                let user = pool.getUser(userName)
                self.user = user

                user.getSession(userName, password: password, validationData: [emailAttribute]).continueWith { (task) -> Any? in
                    if let error = task.error {
                        reject(error)
                    }else{
                        fulfil(LoginOrCreateAccountResult.login)
                    }
                    return task
                }
                
                
            }else{
                reject(SigninManagerError.notSetup)
            }
        })
    }
    
    private func createAccount(email:String, password:String) -> Promise<LoginOrCreateAccountResult>{
        return Promise<LoginOrCreateAccountResult>.init(resolvers: { (fulfil, reject) in
            let email = email.lowercased()
            let emailAttribute = AWSCognitoIdentityUserAttributeType.init(name: "email", value: email)
            if let pool = self.pool, let userName = email.sha1() {
                pool.signUp(userName, password: password, userAttributes: [emailAttribute], validationData: nil).continueWith(executor: AWSExecutor.mainThread(), block: { (task) -> Any? in
                    if let error = task.error  {
                        reject(error)
                    }else if let user = task.result?.user {
                        self.userAccountsCreatedByApp = self.userAccountsCreatedByApp + [email]
                        self.user = user
                        if user.confirmedStatus == .confirmed {
                            fulfil(LoginOrCreateAccountResult.createAccountConfirmed)
                        }else {
                            fulfil(LoginOrCreateAccountResult.createAccountUnconfirmed)
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
    
    
    private func registerUser() {
        // TODO: Gershon needs to deal with this
//        
//        let name = ""
//        let email = self.email
//        
//        UserDefaults.standard.set(name, forKey: UserDefaultsKeys.name)
//        UserDefaults.standard.set(email, forKey: UserDefaultsKeys.email)
//        
//        let user = AnalyticsUser(name: name, email: email)
//        user.sendToServers()
//        
//        Analytics.trackSubmittedEmail(email: email)
//        
//        UserDefaults.standard.set(user.identifier, forKey: UserDefaultsKeys.userID)
//        UserDefaults.standard.synchronize()
    }
    
    func confirmSignup(code:String) -> Promise<Void>{
        return Promise { fulfill, reject in
            if let user = self.user{
                user.confirmSignUp(code, forceAliasCreation: true).continueWith(executor: AWSExecutor.mainThread(), block: { (task) -> Any? in
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
    
    func resendConfirmCode(email:String) -> Promise<Void>{
       
        return Promise { fulfill, reject in
            if let userName = email.lowercased().sha1(), let pool = self.pool{
                
                let user = pool.getUser(userName)
                self.user = user
                user.resendConfirmationCode().continueWith(executor: AWSExecutor.mainThread(), block: { (task) -> Any? in
                    if let error = task.error  {
                        reject(error)
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
    public func validatePassword(_ password: String?) -> String? {
        if let password = password, !password.isEmpty, password.lengthOfBytes(using: .utf8) >= 8 {
            return password
        }
        return nil
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
                        reject(nserror)
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
                        reject(error)
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
            AWSSignInManager.sharedInstance().logout(completionHandler: { (result, error) in
                if let error = error {
                    let nserror = error as NSError
                    reject(nserror)

                }else{
                    fulfill(())
                }
            })
        }
    }
}
