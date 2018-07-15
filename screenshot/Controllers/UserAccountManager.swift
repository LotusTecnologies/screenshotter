//
//  SigninManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/4/18.
//  Copyright (c) 2018 crazeapp. All rights reserved.
//

import Foundation
import PromiseKit
import Firebase
import FBSDKLoginKit
import FirebaseStorage
import SDWebImage

class FacebookProxy : NSObject, FBSDKLoginButtonDelegate {
    let (promise, fulfill, reject) = Promise<FBSDKLoginManagerLoginResult>.pending()
    var facebookButton = FBSDKLoginButton()
    enum FacebookError : Int {
        case canceled = 1
        case wasLogout = 2
    }
    static let FacebookProxyErrorDomain = "com.screenshopit.facebookProxy.errorDomain"
    
    override init() {
        super.init()

        facebookButton.delegate = self
        facebookButton.sendActions(for: .touchUpInside)

    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        print("delegate is \(self)")
        Analytics.trackDevLog(file: #file, line: #line, message: "loginButton didCompleteWith")

        if let error = error {
            Analytics.trackDevLog(file: #file, line: #line, message: "loginButton didCompleteWith error \(error)")

            reject(error)
        }else if let result = result {
            if result.isCancelled {
                Analytics.trackDevLog(file: #file, line: #line, message: "loginButton didCompleteWith cancel")
                reject(NSError.init(domain: FacebookProxy.FacebookProxyErrorDomain, code: FacebookError.canceled.rawValue, userInfo: [:]))
            }else if result.token == nil {
                Analytics.trackDevLog(file: #file, line: #line, message: "loginButton didCompleteWith token is nil")
                reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
            }else{
                Analytics.trackDevLog(file: #file, line: #line, message: "loginButton didCompleteWith ")
                fulfill(result)
            }
        }else{
            Analytics.trackDevLog(file: #file, line: #line, message: "loginButton didCompleteWith no error, no result")
            reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
        }
        facebookButton.delegate = nil
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("delegate is \(self)")
        Analytics.trackDevLog(file: #file, line: #line, message: "loginButtonDidLogOut")

        reject(NSError.init(domain: FacebookProxy.FacebookProxyErrorDomain, code: FacebookError.wasLogout.rawValue, userInfo: [:]))
    }
    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        return true
    }
}


class UserAccountManager : NSObject {
    enum LoginOrCreateAccountResult {
        case facebookNew
        case facebookOld
        case login
        case createAccount
    }
    
    var isFacebookConnected: Bool {
        guard let user = user else {
            return false
        }
        return user.providerData.contains { userInfo -> Bool in
            return userInfo.providerID == "facebook.com"
        }
    }
    
    var userFromLogin:User?
    var user:User? {
        get {
            if let user = userFromLogin {
                return user
            }
            return Auth.auth().currentUser
            
        }
    }
    var email:String?
    lazy var databaseRef:DatabaseReference = Database.database().reference()
    lazy var storageRef:StorageReference = Storage.storage().reference()

    static let shared = UserAccountManager()

    var facebookProxy:FacebookProxy?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

//        self.facebookLogin.interceptApplication(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        Analytics.trackDevLog(file: #file, line: #line, message: "application didFinishLaunchingWithOptions with mode \(url)")

        let queryParams = URLComponents.init(string: url.absoluteString)
        if let mode = queryParams?.queryItems?.first(where: {$0.name == "mode"})?.value, let code = queryParams?.queryItems?.first(where: {$0.name == "oobCode"})?.value {
            return applicationOpenLinkedWith(mode: mode, code: code)
        }
        return false
    }
    func applicationOpenLinkedWith( mode:String, code:String) -> Bool {
    
        var handled = false
//        let source = options[.sourceApplication] as? String
//        let annotation = options[.annotation]

        func find(_ t:AnyClass, viewController:UIViewController? ) -> UIViewController?{
            if let viewController = viewController {
                if viewController.isKind(of: t) {
                    return viewController
                }
                for vc in viewController.childViewControllers {
                    if let found = find(t, viewController: vc) {
                        return found
                    }
                }
                
                if let presented = viewController.presentedViewController{
                    if let found = find(t, viewController: presented) {
                        return found
                    }
                }
            }
            
            return nil
        }
        
        // there are 6 here: 3 for confirm, 3 for reset. each one has one for onboarding and one for inapp, and one fallback to try to find VC anywhere it can.
        if let confirmVC = AppDelegate.shared.window?.rootViewController?.childViewControllers.last as? ConfirmCodeViewController {
            confirmVC.applyCode(code: code)
        }else if let resetVC = AppDelegate.shared.window?.rootViewController?.childViewControllers.last as? ResetPasswordViewController {
            resetVC.code = code
        }else if let confirmVC = AppDelegate.shared.window?.rootViewController?.childViewControllers.last?.childViewControllers.first?.presentedViewController?.childViewControllers.last as? ConfirmCodeViewController{
            confirmVC.applyCode(code: code)
        }else if let resetVC = AppDelegate.shared.window?.rootViewController?.childViewControllers.last?.childViewControllers.first?.presentedViewController?.childViewControllers.last as? ResetPasswordViewController {
            resetVC.code = code
        }else if let confirmVC = find(ConfirmCodeViewController.self, viewController:AppDelegate.shared.window?.rootViewController) as? ConfirmCodeViewController {
            confirmVC.applyCode(code: code)
        }else if let resetVC =  find(ResetPasswordViewController.self, viewController:AppDelegate.shared.window?.rootViewController) as? ResetPasswordViewController {
            resetVC.code = code
        }else{
            let debugInfo =  UIApplication.shared.keyWindow?.rootViewController?.value(forKey: "_printHierarchy") as? String
            Analytics.trackDevLog(file: #file, line: #line, message: "could not find VC \(debugInfo ?? "?")")
            
            Analytics.trackOnboardingError(domain: "code pressed VC not found", code: #line, localizedDescription: "link pressed but cannot find view controller \(String(describing: debugInfo))")
        }
        
        handled = true
        return handled
    }
    
    private func linkFirebaseStuffForFacebookFor(user:User ) {
        if let name = user.providerData.first?.displayName {
            self.databaseRef.child("users").child(user.uid).child("facebook-displayName").setValue(name)
            self.databaseRef.child("users").child(user.uid).child("displayName").setValue(name)
            UserDefaults.standard.set(name, forKey: UserDefaultsKeys.name)
        }
        if let email = user.providerData.first?.email {
            self.databaseRef.child("users").child(user.uid).child("facebook-email").setValue(email)
            self.databaseRef.child("users").child(user.uid).child("email").setValue(email)
            UserDefaults.standard.set(email, forKey: UserDefaultsKeys.email)
        }
        if let phone = user.providerData.first?.phoneNumber{
            self.databaseRef.child("users").child(user.uid).child("facebook-phone").setValue(phone)
        }
        if let photoURLString = user.providerData.first?.photoURL?.absoluteString {
            self.databaseRef.child("users").child(user.uid).child("facebook-photoURL").setValue(photoURLString)
            UserDefaults.standard.set( photoURLString, forKey: UserDefaultsKeys.avatarURL)
        }
        
        self.userFromLogin = user
        self.databaseRef.child("users").child(user.uid).child("identifier").setValue(AnalyticsUser.current.identifier)
        let _ = self.downloadAndReplaceUserData()
    }
    var loginWithFacebookPromise: Promise<LoginOrCreateAccountResult>?
    public func loginWithFacebook()  -> Promise<LoginOrCreateAccountResult>{
        Analytics.trackDevLog(file: #file, line: #line, message: "loginWithFacebook")

        let completion =  { (result:AuthDataResult?, error:Error?,  fulfil: @escaping (LoginOrCreateAccountResult) -> Void, reject:@escaping (Error) -> Void) in
            if let error = error{
                let e = error as NSError
                if e.domain == AuthErrorDomain && e.code == 17015{
                    //Already linked
                    if let user = self.user {
                        self.linkFirebaseStuffForFacebookFor(user: user)
                    }
                    self.downloadAndReplaceUserData().always {
                        fulfil(.facebookOld)
                    }
                    
                }else{
                    reject(error)
                }
            }else if let user = result?.user {
               self.linkFirebaseStuffForFacebookFor(user: user)
                let downloadAndReplaceUserDataTask = self.downloadAndReplaceUserData()
                self.databaseRef.child("users").child(user.uid).child("createdAt").observeSingleEvent(of: .value) { (snapshot) in
                    downloadAndReplaceUserDataTask.always {
                        if let _ = snapshot.value as? NSNumber {
                            fulfil(.facebookOld)
                        }else{
                            let now = NSNumber.init(value: (Date().timeIntervalSince1970 as Double) )
                            self.databaseRef.child("users").child(user.uid).child("createdAt").setValue(now)
                            fulfil(.facebookNew)
                        }
                    }
                }
            }else {
                reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
                
            }
        }
        let promise = Promise<LoginOrCreateAccountResult>.init(resolvers: { (fulfil, reject) in
            let proxy = FacebookProxy.init()
            self.facebookProxy = proxy
            Analytics.trackDevLog(file: #file, line: #line, message: "loginWithFacebook")

            proxy.promise.then(execute: { (result) -> Void in
                Analytics.trackDevLog(file: #file, line: #line, message: "loginWithFacebook success")

                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                if let user = self.user {
                    Analytics.trackDevLog(file: #file, line: #line, message: "loginWithFacebook success link current user")
                    user.linkAndRetrieveData(with: credential, completion: { (result, error) in
                        if let e = error,  (e as NSError).domain == AuthErrorDomain, (e as NSError).code == 17025 {
                            //"This credential is already associated with a different user account."
                            Analytics.trackDevLog(file: #file, line: #line, message: "loginWithFacebook success link current user already associated")
                            Auth.auth().signInAndRetrieveData(with: credential, completion: { (result, error) in
                                completion(result, error, fulfil, reject)
                            })
                        }else{
                            completion(result, error, fulfil, reject)
                        }
                    })
                }else{
                    Analytics.trackDevLog(file: #file, line: #line, message: "loginWithFacebook success no user")
                    Auth.auth().signInAndRetrieveData(with: credential, completion:{ (result, error) in
                        completion(result, error, fulfil, reject)
                    })
                }
            }).catch(execute: { (error) in
                Analytics.trackDevLog(file: #file, line: #line, message: "loginWithFacebook error \(error)")

                reject(error)
            })
        })
        self.loginWithFacebookPromise = promise
        return promise
    }
    
    
    
    
    public func loginOrCreatAccountAsNeeded(email:String, password:String) -> Promise<LoginOrCreateAccountResult> {
        Analytics.trackDevLog(file: #file, line: #line, message: "loginOrCreatAccountAsNeeded")

        if let user = self.user, user.isAnonymous{
            Analytics.trackDevLog(file: #file, line: #line, message: "loginOrCreatAccountAsNeeded already user")
            return Promise.init(resolvers: { (fulfil, reject) in
                user.updateEmail(to: email, completion: { (error) in
                    if let error = error {
                        Analytics.trackDevLog(file: #file, line: #line, message: "loginOrCreatAccountAsNeeded updateEmail error \(error)")
                        reject(error)
                    }else{
                        self.email = email
                        user.updatePassword(to: password, completion: { (error) in
                            if let error = error {
                                Analytics.trackDevLog(file: #file, line: #line, message: "loginOrCreatAccountAsNeeded updatePassword error \(error)")
                                
                                reject(error)
                            }else{
                                self.email = email
                                
                                Analytics.trackDevLog(file: #file, line: #line, message: "loginOrCreatAccountAsNeeded from anon -> real \(String(describing: self.user?.isAnonymous))")
                                self.databaseRef.child("users").child(user.uid).child("email").setValue(email.lowercased())
                                UserDefaults.standard.set(email.lowercased(), forKey: UserDefaultsKeys.email)

                                fulfil(LoginOrCreateAccountResult.createAccount)
                            }
                        })
                    
                    }
                })
            }).recover(execute: { (error) -> Promise<UserAccountManager.LoginOrCreateAccountResult> in
                let nsError = error as NSError
                if nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue && nsError.domain == AuthErrorDomain {
                    Analytics.trackDevLog(file: #file, line: #line, message: "loginOrCreatAccountAsNeeded anon -> login")
                    return self.login(email: email.lowercased(), password: password)
                }
                return Promise.init(error: error)
            })
            
        }
        return createAccount(email:email.lowercased(), password: password).recover(execute: { (error) -> Promise<UserAccountManager.LoginOrCreateAccountResult> in
            let nsError = error as NSError
            if nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue && nsError.domain == AuthErrorDomain {
                Analytics.trackDevLog(file: #file, line: #line, message: "createAccount fail -> login")
                return self.login(email: email.lowercased(), password: password)
            }
            return Promise.init(error: error)
        })
        
        
    }
    
    
    private func login(email:String, password:String) -> Promise<LoginOrCreateAccountResult>{
        Analytics.trackDevLog(file: #file, line: #line, message: "login")

        return Promise<LoginOrCreateAccountResult>.init(resolvers: { (fulfil, reject) in
            
            Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
                
                if let error = error {
                    Analytics.trackDevLog(file: #file, line: #line, message: " login error \(error)")

                    reject(error)
                }else if let authResult = authResult {
                    let user = authResult.user
                    self.userFromLogin = user
                    self.databaseRef.child("users").child(user.uid).child("identifier").setValue(AnalyticsUser.current.identifier)
                    self.downloadAndReplaceUserData().always {
                        self.email = email
                        
                        self.databaseRef.child("users").child(user.uid).child("email").setValue(email.lowercased())
                        UserDefaults.standard.set(email.lowercased(), forKey: UserDefaultsKeys.email)
                        Analytics.trackDevLog(file: #file, line: #line, message: " login user email verified")
                        fulfil(LoginOrCreateAccountResult.login)
                        
                        
                    }
                }else{
                    Analytics.trackDevLog(file: #file, line: #line, message: "unexpected")
                    reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
                }
                
            }
        })
    }
    var makeAnonAccountPromise: Promise<Void>?
    @discardableResult func makeAnonAccount() -> Promise<Void>{
        Analytics.trackDevLog(file: #file, line: #line, message: "makeAnonAccount")

        if let promise = self.makeAnonAccountPromise, !promise.isRejected {
            Analytics.trackDevLog(file: "UserAccountManager", line: #line, message: "already making/made anon account")
            return promise
        }else{
            self.makeAnonAccountPromise = nil
            let promise = Promise<Void>.init(resolvers: { (fulfil, reject) in
                Auth.auth().signInAnonymously() { (authResult, error) in
                    if let error = error {
                         ///automatic retry?
                        Analytics.trackDevLog(file: #file, line: #line, message: "eror making anon account \(error)")
                        reject(error)
                    }else  if let authResult = authResult {
                        Analytics.trackDevLog(file: #file, line: #line, message: "made anon account")
                        let user = authResult.user
                        self.userFromLogin = user
                        self.databaseRef.child("users").child(user.uid).child("identifier").setValue(AnalyticsUser.current.identifier)
                        fulfil(())
                    }else{
                        Analytics.trackDevLog(file: #file, line: #line, message: "unexpected")
                        reject(NSError.init(domain: "UserAccountManager", code: #line, userInfo: [:]))
                    }
                    
                }
            })
            
            self.makeAnonAccountPromise = promise
            return promise
        }
    }
    private func createAccount(email:String, password:String) -> Promise<LoginOrCreateAccountResult>{
        Analytics.trackDevLog(file: #file, line: #line, message: "createAccount")

        return Promise<LoginOrCreateAccountResult>.init(resolvers: { (fulfil, reject) in
            Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                if let error = error {
                    Analytics.trackDevLog(file: #file, line: #line, message: "createAccount error  \(error)")

                    reject(error)
                }else  if let authResult = authResult {
                    let user = authResult.user
                    self.userFromLogin = user
                    self.databaseRef.child("users").child(user.uid).child("identifier").setValue(AnalyticsUser.current.identifier)
                    let downloadPromise = self.downloadAndReplaceUserData()

                    downloadPromise.always {
                        Analytics.trackDevLog(file: #file, line: #line, message: "created email verified")
                        self.databaseRef.child("users").child(user.uid).child("email").setValue(email.lowercased())
                        UserDefaults.standard.set(email.lowercased(), forKey: UserDefaultsKeys.email)
                        fulfil(LoginOrCreateAccountResult.createAccount)
                    }
                    
                }else{
                    Analytics.trackDevLog(file: #file, line: #line, message: "unexpected")

                    reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
                }
                
            }
        })
    }
    
    func confirmSignup(code:String) -> Promise<Void>{
        Analytics.trackDevLog(file: #file, line: #line, message: "confirmSignup")

        return Promise { fulfill, reject in
            Auth.auth().applyActionCode(code, completion: { (error) in
                if let error = error {
                    Analytics.trackDevLog(file: #file, line: #line, message: "confirmSignup error \(error)")
                    reject(error)
                }else{
                    Analytics.trackDevLog(file: #file, line: #line, message: "confirmSignup success")
                    if let user = self.user, let email = self.email {
                        self.databaseRef.child("users").child(user.uid).child("email").setValue(email.lowercased())
                        UserDefaults.standard.set(email.lowercased(), forKey: UserDefaultsKeys.email)
                    }else{
                        Analytics.trackDevLog(file: #file, line: #line, message: "unexpected")
                    }
                    
                    fulfill(())
                }
            })
        }
    }
    
    func resendConfirmCode() -> Promise<Void>{
        Analytics.trackDevLog(file: #file, line: #line, message: "resendConfirmCode")

        return Promise { fulfill, reject in
            if let user = self.user {
                user.sendEmailVerification(completion: { (error) in
                    if let error = error {
                        reject(error)
                    }else{
                        fulfill(())
                    }
                })
            }else{
                Analytics.trackDevLog(file: #file, line: #line, message: "unexpected")
                reject(NSError.init(domain: "UserAccountManager", code: #line, userInfo: [:]))
            }
            
        }
    }
    
    public func validatePassword(_ password: String?) -> String? {
        if let password = password, !password.isEmpty, password.lengthOfBytes(using: .utf8) >= 8, password != "password" {
            return password
        }
        return nil
    }
    
    func forgotPassword(email:String) ->Promise<Void> {
        Analytics.trackDevLog(file: #file, line: #line, message: "forgotPassword")

        return Promise { fulfill, reject in
            self.email = email

            Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
                if let error = error {
                    Analytics.trackDevLog(file: #file, line: #line, message: "forgotPassword erro \(error)")

                    reject(error)
                }else{
                    Analytics.trackDevLog(file: #file, line: #line, message: "forgotPassword sucess")
                    fulfill(())
                }
            })

        }
    }
    
    func confirmForgotPassword(code:String, password:String) ->Promise<Void> {
        Analytics.trackDevLog(file: #file, line: #line, message: "confirmForgotPassword")

        return Promise { fulfill, reject in
            Auth.auth().confirmPasswordReset(withCode: code, newPassword: password, completion: { (error) in
                if let error = error {
                    Analytics.trackDevLog(file: #file, line: #line, message: "reset password error - \(error)")
                    reject(error)
                }else{
                    if let email = self.email {
                        Analytics.trackDevLog(file: #file, line: #line, message: "reset password success - now login")

                        self.login(email: email, password: password).then(execute: { (result) -> Void in
                            fulfill(())
                        }).catch(execute: { (error) in
                            reject(error)
                        })
                    }else{
                        Analytics.trackDevLog(file: #file, line: #line, message: "unexpected")

                        reject(NSError.init(domain: "UserAccountManager", code: #line, userInfo: [:]))
                    }
                }
            })
        }
    }
    
    @discardableResult func setGDPR(agreedToEmail:Bool, agreedToImageDetection:Bool) -> Promise<Void>{
        Analytics.trackDevLog(file: #file, line: #line, message: "setGDPR")

        return Promise { fulfill, reject in
            UserDefaults.standard.setValue(agreedToEmail, forKey: UserDefaultsKeys.gdpr_agreedToEmail)
            UserDefaults.standard.setValue(agreedToImageDetection, forKey: UserDefaultsKeys.gdpr_agreedToImageDetection)
            
            if agreedToImageDetection {
                SilentPushSubscriptionManager.sharedInstance.updateSubscriptionsIfNeeded()
            }
            
            let promise = makeAnonAccountPromise ?? Promise.init(value:())
            promise.then(execute: { () -> Void in
                if let user = self.user {
                    self.databaseRef.child("users").child(user.uid).child("GDRP-agreedToEmail").setValue(NSNumber.init(value: agreedToEmail))
                    self.databaseRef.child("users").child(user.uid).child("GDRP-agreedToImageDetection").setValue(NSNumber.init(value: agreedToImageDetection))
                    Analytics.trackDevLog(file: #file, line: #line, message: "setGDPR sucess")

                    fulfill(())
                }else{
                    Analytics.trackDevLog(file: #file, line: #line, message: "unexpected")
                    reject(NSError.init(domain: "UserAccountManager", code: #line, userInfo: [:]))
                }
            }).catch(execute: { (error) in
                Analytics.trackDevLog(file: #file, line: #line, message: "unexpected")

                reject(NSError.init(domain: "UserAccountManager", code: #line, userInfo: [:]))
            })
        }
    }
    
    @discardableResult func setProfile(displayName:String?, gender:String?, size:String?, unverifiedEmail:String?, avatarURL:String? = nil) -> Promise<Void>{
        Analytics.trackDevLog(file: #file, line: #line, message: "setProfile")
        
        return Promise { fulfill, reject in
            let promise = makeAnonAccountPromise ?? Promise.init(value:())
            promise.then(execute: { () -> Void in
                if let user = self.user {
                    if let displayName = displayName {
                        UserDefaults.standard.set(displayName, forKey: UserDefaultsKeys.name)
                        self.databaseRef.child("users").child(user.uid).child("displayName").setValue(displayName)
                    }
                    if let gender = gender {
                        self.databaseRef.child("users").child(user.uid).child("gender").setValue(gender)
                    }
                    if let size = size {
                        self.databaseRef.child("users").child(user.uid).child("size").setValue(size)
                    }
                    if let unverifiedEmail = unverifiedEmail {
                        if UserDefaults.standard.value(forKey: UserDefaultsKeys.email) == nil {
                            UserDefaults.standard.set(unverifiedEmail, forKey: UserDefaultsKeys.email)
                        }
                        self.databaseRef.child("users").child(user.uid).child("unverifiedEmail").setValue(unverifiedEmail)
                    }
                    if let avatarUrl = avatarURL {
                        self.databaseRef.child("users").child(user.uid).child("avatarURL").setValue(avatarUrl)
                    }
                    fulfill(())
                }else{
                    Analytics.trackDevLog(file: #file, line: #line, message: "unexpected")
                    reject(NSError.init(domain: "UserAccountManager", code: #line, userInfo: [:]))
                }
            }).catch(execute: { (error) in
                Analytics.trackDevLog(file: #file, line: #line, message: "unexpected")

                reject(NSError.init(domain: "UserAccountManager", code: #line, userInfo: [:]))
            })
        }
    }

    func logout() -> Promise<Void>{
                        Analytics.trackDevLog(file: #file, line: #line, message: "logout")
        return Promise { fulfill, reject in
            do {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.name)
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.email)
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.avatarURL)
                FBSDKLoginManager().logOut()
                if self.user?.isAnonymous == false || self.user?.providerData.first(where: {$0.providerID == "facebook.com"}) != nil {
                    try Auth.auth().signOut()
                    makeAnonAccountPromise = nil
                    makeAnonAccount().then(execute: { () -> () in
                        Analytics.trackDevLog(file: #file, line: #line, message: "logout sucess")
                        fulfill(())
                    }).catch(execute: { (e) in
                        Analytics.trackDevLog(file: #file, line: #line, message: "logout error \(e)")

                        fulfill(()) // not a bug.  you did logout - even if a new accout was not created.
                    })
                    
                }else{
                    Analytics.trackDevLog(file: #file, line: #line, message: "unexpected")
                    fulfill(())
                }
                
            }catch let error {
                Analytics.trackDevLog(file: #file, line: #line, message: "unexpected")
                reject(error)
            }
            
        }
    }
    
}
extension UserAccountManager {
    
    public func isIgnorableFacebookError( error:NSError) ->Bool {
        if error.domain == FacebookProxy.FacebookProxyErrorDomain && error.code == FacebookProxy.FacebookError.canceled.rawValue {
            return true
        }
        if error.domain == FacebookProxy.FacebookProxyErrorDomain && error.code == FacebookProxy.FacebookError.wasLogout.rawValue {
            return true
        }
        return  false
    }
    public func isNoInternetError( error:NSError) ->Bool {
        if error.domain == NSURLErrorDomain {
            return true
        }
        if error.domain == AuthErrorDomain && error.code == AuthErrorCode.networkError.rawValue {
            return true
        }
        
        return  false
    }
    func alertViewForNoInternet() -> UIAlertController{
        let alert = UIAlertController.init(title: nil, message: "authorize.error.noInternet".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .default, handler: nil))
        return alert
    }
    func alertViewForUndefinedError(error:NSError, viewController:UIViewController) -> UIAlertController {
        Analytics.trackOnboardingUnsupportedError(domain: error.domain, code: error.code, localizedDescription: error.localizedDescription)
        let alert = UIAlertController.init(title: "generic.error".localized, message: "authorize.error.undefined".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "authorize.error.undefined.contactSupport".localized, style: .default, handler: { (a) in
            let recipient = "support@screenshopit.com"
            let subject = "unable to login"
            let userInfoString = String.init(describing: error.userInfo)

            let body = "Please help me. I’m getting this weirdo error: \(String.init(describing: viewController)) Domain: \(error.domain) Code: \(error.code) \(userInfoString) -  \(Bundle.displayVersionBuild). I don’t know what this means, because I am not a programmer. But ya’ll should be able to help me."
            let gmailMessage = body
            viewController.presentMail(recipient: recipient, gmailMessage: gmailMessage, subject: subject, message: body, isHTML: false, delegate:nil, noEmailErrorMessage: "email.setup.message.bug".localized, attachLogs:true)
        }))
        alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .cancel, handler: nil))
        return alert
    }
    public func isBadCodeError( error:NSError) ->Bool {
        if error.domain == AuthErrorDomain && error.code == AuthErrorCode.invalidActionCode.rawValue {
            return true
        }
        return  false
    }
    func alertViewForBadCode()  -> UIAlertController {
        let alert = UIAlertController.init(title: nil, message: "authorize.error.badCode".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .cancel, handler: nil))
        return alert
    }
    
    public func isNoAccountWithEmailError( error:NSError) ->Bool {
        if error.domain == AuthErrorDomain && error.code == AuthErrorCode.userNotFound.rawValue {
            return true
        }
        return  false
    }
    
    func alertViewForNoAccountWithEmail() -> UIAlertController  {
        let alert = UIAlertController.init(title: nil, message: "authorize.error.NoAccountWithEmail".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .cancel, handler: nil))

        return alert
    }
    
    public func isCantSendEmailError( error:NSError) ->Bool {
       
        if error.domain == AuthErrorDomain && error.code == AuthErrorCode.invalidEmail.rawValue {
            return true
        }
        if error.domain == AuthErrorDomain && error.code == AuthErrorCode.invalidMessagePayload.rawValue {
            return true
        }
        if error.domain == AuthErrorDomain && error.code == AuthErrorCode.invalidSender.rawValue {
            return true
        }
        if error.domain == AuthErrorDomain && error.code == AuthErrorCode.invalidRecipientEmail.rawValue {
            return true
        }

        return  false
    }
    
    public func isWeakPasswordError( error:NSError) -> Bool {
        if error.domain == AuthErrorDomain && error.code == AuthErrorCode.weakPassword.rawValue {
            return true
        }
        return  false
    }
    
    func alertViewForCantSendEmail(email:String) -> UIAlertController  {
        let alert = UIAlertController.init(title: nil, message: "authorize.error.cantSendMail".localized(withFormat: email), preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .cancel, handler: nil))
        
        return alert
    }
    
    public func isWrongPasswordError( error:NSError) ->Bool {
        if error.domain == AuthErrorDomain && error.code == AuthErrorCode.wrongPassword.rawValue {
            return true
        }
        return  false
    }
    
    func alertViewForWrongPassword() -> UIAlertController  {
        let alert = UIAlertController.init(title: nil, message: "authorize.error.wrongPassword".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .cancel, handler: nil))
        
        return alert
    }
}



extension UserAccountManager {
    
    
    func downloadAndReplaceUserData()->Promise<Void>{
        var promiseArray:[Promise<Void>] = []
        if let user = self.user{
            
            promiseArray.append(Promise<Void>.init(resolvers: { (fulfil, reject) in
                self.databaseRef.child("users").child(user.uid).child("avatarURL").observeSingleEvent(of: .value) { (snapshot) in
                    if let url = snapshot.value as? String  {
                        UserDefaults.standard.setValue(url, forKey: UserDefaultsKeys.avatarURL)
                    }
                    fulfil(())
                }
            }))
            
            if UserDefaults.standard.string(forKey: UserDefaultsKeys.name) == nil {
                promiseArray.append(Promise<Void>.init(resolvers: { (fulfil, reject) in

                    self.databaseRef.child("users").child(user.uid).child("displayName").observeSingleEvent(of: .value) { (snapshot) in
                        if let displayName = snapshot.value as? String  {
                            UserDefaults.standard.setValue(displayName, forKey: UserDefaultsKeys.name)
                        }
                        fulfil(())
                    }
                }))
            }
            promiseArray.append(Promise<Void>.init(resolvers: { (fulfil, reject) in
                self.databaseRef.child("users").child(user.uid).child("GDRP-agreedToEmail").observeSingleEvent(of: .value) { (snapshot) in
                    if let agreedToEmailNumber = snapshot.value as? NSNumber  {
                        let agreedToEmail = agreedToEmailNumber.boolValue
                        UserDefaults.standard.setValue(agreedToEmail, forKey: UserDefaultsKeys.gdpr_agreedToEmail)
                    }
                    fulfil(())
                    
                }
            }))
            promiseArray.append(Promise<Void>.init(resolvers: { (fulfil, reject) in
                self.databaseRef.child("users").child(user.uid).child("GDRP-agreedToImageDetection").observeSingleEvent(of: .value) { (snapshot) in
                    if let agreedToImageDetectionNumber = snapshot.value as? NSNumber  {
                        let agreedToImageDetection = agreedToImageDetectionNumber.boolValue
                        UserDefaults.standard.setValue(agreedToImageDetection, forKey: UserDefaultsKeys.gdpr_agreedToImageDetection)
                    }
                    fulfil(())
                }
            }))

            self.databaseRef.child("users").child(user.uid).child("screenshots").observeSingleEvent(of: .value) { (snapshot) in
                for child in snapshot.children {
                    if let child = child as? DataSnapshot,
                        let dict = child.value as? NSDictionary,
                        let assetId = dict["assetId"] as? String,
                        let createdAtNumber = dict["createdAt"] as? NSNumber,
                        let sourceString = dict["source"] as? String,
                        let source = ScreenshotSource.init(rawValue: sourceString),
                        let uploadedImageURL = dict["uploadedImageURL"] as? String
                    {
                        SDWebImageManager.shared().loadImage(with: URL.init(string: uploadedImageURL), options: [], progress: nil, completed: { (image, data, error, cache, bool, url) in
                            DataModel.sharedInstance.performBackgroundTask({ (context) in
                                let imageData:Data? =  {
                                    if let data = data {
                                        return data
                                    }else if let i = image {
                                        return AssetSyncModel.sharedInstance.data(for: i)
                                    }
                                    return nil
                                }()
                                if imageData != nil {
                                    let createdAt = Date.init(timeIntervalSince1970: createdAtNumber.doubleValue)
                                    let s = DataModel.sharedInstance.saveScreenshot(upsert:true,
                                                                                    managedObjectContext: context,
                                                                                    assetId: assetId,
                                                                                    createdAt: createdAt,
                                                                                    isRecognized: true,
                                                                                    source:source ,
                                                                                    isHidden: false,
                                                                                    imageData: imageData,
                                                                                    uploadedImageURL: uploadedImageURL,
                                                                                    syteJsonString: nil)
                                    if let trackingInfo = dict["trackingInfo"] as? String, trackingInfo.lengthOfBytes(using: .utf8) > 0 {
                                        s.trackingInfo = trackingInfo
                                    }
                                    
                                    AssetSyncModel.sharedInstance.processingQ.async {
                                        AssetSyncModel.sharedInstance.syteProcessing(imageData: nil, orImageUrlString: uploadedImageURL, assetId: assetId, optionsMask: ProductsOptionsMask.global)
                                        
                                    }
                                    context.saveIfNeeded()
                                }
                            })
                        })
                    }
                }
            }
            
            self.databaseRef.child("users").child(user.uid).child("favorites").observeSingleEvent(of: .value) { (snapshot) in
                for child in snapshot.children {
                    if let child = child as? DataSnapshot,
                        let dict = child.value as? NSDictionary,
                        let price = dict["price"] as? String,
                        let imageURL = dict["imageURL"] as? String,
                        let productDescription = dict["productDescription"] as? String,
                        let offer = dict["offer"] as? String,
                        let floatPriceNumber = dict["floatPrice"] as? NSNumber
                        
                    {
                        let floatPrice = floatPriceNumber.floatValue
                        let originalPrice = dict["originalPrice"] as? String
                        var floatOriginalPrice:Float =  0
                        if let p =  dict["floatOriginalPrice"] as? NSNumber {
                            floatOriginalPrice = p.floatValue
                        }
                        let categories = dict["categories"] as? String
                        let brand = dict["brand"] as? String
                        let merchant = dict["merchant"] as? String
                        let partNumber = dict["partNumber"] as? String
                        let id = dict["id"] as? String
                        let color = dict["color"] as? String
                        let sku = dict["sku"] as? String
                        let fallbackPriceNumber =  dict["fallbackPrice"] as? NSNumber
                        let fallbackPrice = fallbackPriceNumber?.floatValue ?? 0.0
                        var optionsMask = ProductsOptionsMask.global.rawValue
                        if let option = dict["optionsMask"] as? NSNumber {
                            optionsMask = option.intValue
                        }
                        DataModel.sharedInstance.performBackgroundTask({ (context) in
                            let product = DataModel.sharedInstance.saveProduct(managedObjectContext: context,
                                                                               shoppable: nil, order: 0,
                                                                               productDescription: productDescription,
                                                                               price: price,
                                                                               originalPrice: originalPrice,
                                                                               floatPrice: floatPrice,
                                                                               floatOriginalPrice: floatOriginalPrice,
                                                                               categories: categories,
                                                                               brand: brand,
                                                                               offer: offer,
                                                                               imageURL: imageURL,
                                                                               merchant: merchant,
                                                                               partNumber:  partNumber,
                                                                               id: id,
                                                                               color:  color,
                                                                               sku: sku,
                                                                               fallbackPrice: fallbackPrice,
                                                                               optionsMask: Int32(optionsMask))
                            
                            
                            context.saveIfNeeded()
                            DataModel.sharedInstance.favorite(toFavorited: true, productOIDs: [product.objectID])
                            LocalNotificationModel.shared.registerCrazeFavoritedPriceAlert(id: product.id, merchant: product.merchant, lastPrice: product.floatPrice)
                        })
                    }
                }
            }
        }
        
        return when(fulfilled: promiseArray)
    }
    
    
    func uploadFavorites(product:Product){
        if let user = self.user,
        let price = product.price,
           let imageURL = product.imageURL,
            let offer = product.offer,
            let productDescription = product.productDescription
        {
            let floatPrice = product.floatPrice
            let floatOriginalPrice = product.floatOriginalPrice
            var dict:[String:Any] = ["price":price,
                                     "imageURL":imageURL,
                                     "floatPrice":NSNumber.init(value: floatPrice),
                                     "floatOriginalPrice":NSNumber.init(value: floatOriginalPrice),
                                     "offer":offer,
                                     "productDescription":productDescription]
            
            if let merchant = product.merchant {
                dict["merchant"] = merchant
            }
            if let categories = product.categories {
                dict["categories"] = categories
            }
            if let originalPrice = product.originalPrice {
                dict["originalPrice"] = originalPrice
            }

            if let brand = product.brand {
                dict["brand"] = brand
            }
            
            if let partNumber = product.partNumber {
                dict["partNumber"] = partNumber
            }
            
            if let id = product.id {
                dict["id"] = id
            }
            
            if let color = product.color {
                dict["color"] = color
                
            }
            if let sku = product.sku {
                dict["sku"] = sku
                
            }
            dict["optionsMask"] = product.optionsMask
            dict["fallbackPrice"] = NSNumber.init(value: product.fallbackPrice)

            if let escapedoffer = offer.firebaseSafe() {
                self.databaseRef.child("users").child(user.uid).child("favorites").child(escapedoffer).setValue(dict)
            }
        }
    }
    
    func deleteFavorite(product:Product){
        if let user = self.user {
            if let offer = product.offer {

                if let escapedoffer = offer.firebaseSafe() {
                    self.databaseRef.child("users").child(user.uid).child("favorites").child(escapedoffer).removeValue()
                }
            }
        }
    }
    
    func deleteScreenshot(screenshot:Screenshot) {
        if let assetId = screenshot.assetId, let user = self.user {

            if let escapedAssetId = assetId.firebaseSafe() {
                self.databaseRef.child("users").child(user.uid).child("screenshots").child(escapedAssetId).removeValue()
            }
        }
    }
    
    func uploadScreenshots(screenshot:Screenshot){
        
        if let user = self.user,
            let assetId = screenshot.assetId,
            let createdAtNumber = screenshot.createdAt?.timeIntervalSince1970,
            let uploadedImageURL = screenshot.uploadedImageURL {
            let trackingInfo = screenshot.trackingInfo ?? ""
            let source = screenshot.source.rawValue
            if let escapedAssetId = assetId.firebaseSafe() {
                
                let dict:[String:Any] = [
                    "assetId":assetId,
                    "createdAt":NSNumber.init(value: createdAtNumber as Double),
                    "source":source,
                    "uploadedImageURL":uploadedImageURL,
                    "trackingInfo" :trackingInfo
                ]
                self.databaseRef.child("users").child(user.uid).child("screenshots").child(escapedAssetId).setValue(dict)
            }
        }

    }
}
extension String {
    fileprivate func firebaseSafe() ->  String?{
        let forbiddenChacters = CharacterSet.init(charactersIn: "\\#$[]./")
        let toReturn =  self.components(separatedBy:forbiddenChacters).joined()
        if toReturn.count == 0 {
            return nil
        }
        return toReturn
    }
}

extension UserAccountManager {
    public func uploadImage(data:Data) -> Promise<URL> {
        func getUser() -> Promise<User> {
            return Promise { fulfill, reject in
                if let user = self.user {
                    fulfill(user)
                }else {
                    self.makeAnonAccount().then(execute: { () -> () in
                        if let user = self.user{
                            fulfill(user)
                        }else{
                            reject(NSError.init(domain: "UserAccountManager", code: #line, userInfo: [:]))
                        }
                    }).catch(execute: { (error) in
                        reject(error)
                    })
                }
            }
        }
        return Promise { fulfill, reject in
            getUser().then(execute: { (user) -> (Void) in
                let name = UUID().uuidString
                let uploadRef = self.storageRef.child("user").child(user.uid).child("images").child("\(name).jpg")
                
                let _ = uploadRef.putData(data, metadata: nil) { (metadata, error) in
                    if let error = error {
                        reject(error)
                    }else{
                        uploadRef.downloadURL { url, error in
                            if let error = error {
                                reject(error)
                            } else if let url = url{
                                fulfill(url)
                            }else{
                                reject(NSError.init(domain: #file, code: #line, userInfo: [:]))
                            }
                        }
                    }
                }
            }).catch(execute: { (error) in
                reject(error)
            })
        }
    }
}

