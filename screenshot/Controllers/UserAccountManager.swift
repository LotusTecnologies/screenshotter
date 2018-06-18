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


class FacebookProxy : NSObject, FBSDKLoginButtonDelegate {
    let (promise, fulfill, reject) = Promise<FBSDKLoginManagerLoginResult>.pending()
    var facebookButton = FBSDKLoginButton()

    override init() {
        super.init()
        facebookButton.delegate = self
        facebookButton.sendActions(for: .touchUpInside)

    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            reject(error)
        }else if let result = result {
            fulfill(result)
        }else{
            reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
        }
        facebookButton.delegate = nil
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }
}


class UserAccountManager : NSObject {
    enum LoginOrCreateAccountResult {
        case confirmed
        case unconfirmed
    }
    
    
    
    var email:String?
    static let shared = UserAccountManager()

    var facebookProxy:FacebookProxy?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

//        self.facebookLogin.interceptApplication(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        var handled = false
//        let source = options[.sourceApplication] as? String
//        let annotation = options[.annotation]


        let queryParams = URLComponents.init(string: url.absoluteString)
        let mode = queryParams?.queryItems?.first(where: {$0.name == "mode"})
        let code = queryParams?.queryItems?.first(where: {$0.name == "oobCode"})
        if let _ = mode?.value, let code = code?.value{
            
            if let confirmVC = AppDelegate.shared.window?.rootViewController?.childViewControllers.last as? ConfirmCodeViewController {
                confirmVC._view.codeTextField.text = code
                confirmVC.continueAction()
            }
            if let resetVC = AppDelegate.shared.window?.rootViewController?.childViewControllers.last as? ResetPasswordViewController {
                resetVC._view.codeTextField.text = code
            }
            
            handled = true
        }
        return handled
    }
    
//    func downloadUserFiles() -> Promise<Void> {
//
//    }
    
    public func loginWithFacebook()  -> Promise<Void>{

        return Promise<Void>.init(resolvers: { (fulfil, reject) in
            let proxy = FacebookProxy.init()
            self.facebookProxy = proxy
            proxy.promise.then(execute: { (result) -> Void in
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                Auth.auth().signInAndRetrieveData(with: credential, completion: { (result, error) in
                    if let error = error{
                        reject(error)
                    }else {
                        fulfil(())
                    }
                })
            }).catch(execute: { (error) in
                reject(error)
            })
        })
    }
    
    
    public func loginOrCreatAccountAsNeeded(email:String, password:String, sendMeEmails:Bool) -> Promise<LoginOrCreateAccountResult> {
        
        return createAccount(email:email.lowercased(), password: password, sendMeEmails:sendMeEmails).recover(execute: { (error) -> Promise<UserAccountManager.LoginOrCreateAccountResult> in
            let nsError = error as NSError
            if nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue && nsError.domain == AuthErrorDomain {
                return self.login(email: email.lowercased(), password: password)
            }
            return Promise.init(error: error)
        })
        
    }
    
    
    private func login(email:String, password:String) -> Promise<LoginOrCreateAccountResult>{
        return Promise<LoginOrCreateAccountResult>.init(resolvers: { (fulfil, reject) in
            
            Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
                
                if let error = error {
                    reject(error)
                }else{
                    if let authResult = authResult {
                        if authResult.user.isEmailVerified {
                            fulfil(LoginOrCreateAccountResult.confirmed)
                        }else{
                            authResult.user.sendEmailVerification(completion: { (error) in
                                if let error = error {
                                    reject(error)
                                }else{
                                    fulfil(LoginOrCreateAccountResult.unconfirmed)
                                }
                            })
                        }
                    }else{
                        reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
                    }
                }
            }
        })
    }
    
    @discardableResult func makeAnonAccount(sendMeEmails:Bool) -> Promise<Void> {
        return Promise<Void>.init(resolvers: { (fulfil, reject) in
            Auth.auth().signInAnonymously() { (authResult, error) in
                if let error = error {
                    reject(error)
                }else{
                    fulfil(())
                }
            }

        })
    }
    private func createAccount(email:String, password:String, sendMeEmails:Bool) -> Promise<LoginOrCreateAccountResult>{
        return Promise<LoginOrCreateAccountResult>.init(resolvers: { (fulfil, reject) in
            Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                if let error = error {
                    reject(error)
                }else{
                    if let authResult = authResult {
                        if authResult.user.isEmailVerified {
                            fulfil(LoginOrCreateAccountResult.confirmed)
                        }else{
                            authResult.user.sendEmailVerification(completion: { (error) in
                                if let error = error {
                                    reject(error)
                                }else{
                                    fulfil(LoginOrCreateAccountResult.unconfirmed)
                                }
                            })
                        }
                    }else{
                        reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
                    }
                }
            }
        })
    }
    
    func confirmSignup(code:String) -> Promise<Void>{
        return Promise { fulfill, reject in
            Auth.auth().verifyPasswordResetCode(code) { (string, error) in
                
            }
            reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))

            
        }
    }
    
    func resendConfirmCode(email:String) -> Promise<Void>{
       
        return Promise { fulfill, reject in
            reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))

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
            Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
                if let error = error {
                    reject(error)
                }else{
                    fulfill(())
                }
            })

        }
    }
    
    func confirmForgotPassword(code:String, password:String) ->Promise<Void> {
        return Promise { fulfill, reject in
            Auth.auth().confirmPasswordReset(withCode: code, newPassword: password, completion: { (error) in
                if let error = error {
                    reject(error)
                }else{
                    fulfill(())
                }
            })
            reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))

        }
    }
    
    func signOut() -> Promise<Void>{
        return Promise { fulfill, reject in
            reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))

        }
    }
    
    
}
extension UserAccountManager {
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
        let alert = UIAlertController.init(title: "generic.error".localized, message: "authorize.error.undefined".localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "authorize.error.undefined.contactSupport".localized, style: .default, handler: { (a) in
            let recipient = "support@screenshopit.com"
            let subject = "unable to login"
            let userInfoJson:String = {
                if let userinfoJsonData = try? JSONSerialization.data(withJSONObject: error.userInfo, options: []), let s = String.init(data: userinfoJsonData, encoding: .utf8) {
                    return s
                }
                return "{}"
            }()

            let body = "Please help me. I’m getting this weirdo error: \(String.init(describing: viewController)) Domain: \(error.domain) Code: \(error.code) \(userInfoJson). I don’t know what this means, because I am not a programmer. But ya’ll should be able to help me."
            let gmailMessage = body
            viewController.presentMail(recipient: recipient, gmailMessage: gmailMessage, subject: subject, message: body)
        }))
        alert.addAction(UIAlertAction.init(title: "generic.ok".localized, style: .cancel, handler: nil))
        return alert
    }
    public func isBadCodeError( error:NSError) ->Bool {
        
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

