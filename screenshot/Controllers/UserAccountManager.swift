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

    override init() {
        super.init()
        facebookButton.delegate = self
        facebookButton.sendActions(for: .touchUpInside)

    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            reject(error)
        }else if let result = result {
            if result.isCancelled  || result.token == nil{
                reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
            }else{
                fulfill(result)
            }
        }else{
            reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
        }
        facebookButton.delegate = nil
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
    }
}


class UserAccountManager : NSObject {
    enum LoginOrCreateAccountResult {
        case facebookNew
        case facebookOld
        case confirmed
        case unconfirmed
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
        var handled = false
//        let source = options[.sourceApplication] as? String
//        let annotation = options[.annotation]


        let queryParams = URLComponents.init(string: url.absoluteString)
        let mode = queryParams?.queryItems?.first(where: {$0.name == "mode"})
        let code = queryParams?.queryItems?.first(where: {$0.name == "oobCode"})
        if let _ = mode?.value, let code = code?.value{
            if let confirmVC = AppDelegate.shared.window?.rootViewController?.childViewControllers.last as? ConfirmCodeViewController {
                confirmVC.applyCode(code: code)
            }
            if let resetVC = AppDelegate.shared.window?.rootViewController?.childViewControllers.last as? ResetPasswordViewController {
                resetVC.code = code
            }
            if let confirmVC = AppDelegate.shared.window?.rootViewController?.childViewControllers.last?.childViewControllers.first?.presentedViewController?.childViewControllers.last as? ConfirmCodeViewController{
                confirmVC.applyCode(code: code)
            }
            if let resetVC = AppDelegate.shared.window?.rootViewController?.childViewControllers.last?.childViewControllers.first?.presentedViewController?.childViewControllers.last as? ResetPasswordViewController {
                resetVC.code = code
            }
            
            handled = true
        }
        return handled
    }
    
    public func loginWithFacebook()  -> Promise<LoginOrCreateAccountResult>{

        return Promise<LoginOrCreateAccountResult>.init(resolvers: { (fulfil, reject) in
            let proxy = FacebookProxy.init()
            self.facebookProxy = proxy
            proxy.promise.then(execute: { (result) -> Void in
                let completion:AuthDataResultCallback =  { (result, error) in
                    if let error = error{
                        let e = error as NSError
                        if   e.domain == AuthErrorDomain && e.code == 17025 {
                            //This credential is already associated with a different user account.
                            reject(error)
                        }
                    }else if let user = result?.user {
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
                            UserDefaults.standard.set(URL(string: photoURLString), forKey: UserDefaultsKeys.avatarURL)
                        }
                        
                        self.userFromLogin = user
                        self.downloadAndReplaceUserData()
                        self.databaseRef.child("users").child(user.uid).child("createdAt").observeSingleEvent(of: .value) { (snapshot) in
                            if let _ = snapshot.value as? NSNumber {
                                fulfil(.facebookOld)
                            }else{
                                let now = NSNumber.init(value: (Date().timeIntervalSince1970 as Double) )
                                self.databaseRef.child("users").child(user.uid).child("createdAt").setValue(now)
                                fulfil(.facebookNew)
                            }
                        }
                        
                    }else {
                        reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
                        
                    }
                }
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                if let user = self.user {
                    user.linkAndRetrieveData(with: credential, completion: { (result, error) in
                        if let e = error,  (e as NSError).domain == AuthErrorDomain, (e as NSError).code == 17025 {
//                            "This credential is already associated with a different user account."
                            Auth.auth().signInAndRetrieveData(with: credential, completion:completion)
                        }else{
                            completion(result, error)
                        }
                    })
                }else{
                    Auth.auth().signInAndRetrieveData(with: credential, completion:completion)
                }
            }).catch(execute: { (error) in
                reject(error)
            })
        })
    }
    
    
    
    
    public func loginOrCreatAccountAsNeeded(email:String, password:String) -> Promise<LoginOrCreateAccountResult> {
        
        return createAccount(email:email.lowercased(), password: password).recover(execute: { (error) -> Promise<UserAccountManager.LoginOrCreateAccountResult> in
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
                }else if let authResult = authResult {
                    let user = authResult.user
                    self.userFromLogin = user
                    self.downloadAndReplaceUserData()
                    if user.isEmailVerified {
                        self.databaseRef.child("users").child(user.uid).child("email").setValue(email.lowercased())
                        UserDefaults.standard.set(email.lowercased(), forKey: UserDefaultsKeys.email)
                        fulfil(LoginOrCreateAccountResult.confirmed)
                    }else{
                        user.sendEmailVerification(completion: { (error) in
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
        })
    }
    var makeAnonAccountPromise: Promise<Void>?
    @discardableResult func makeAnonAccount() -> Promise<Void>{
        if let promise = self.makeAnonAccountPromise {
            return promise
        }else{
            let promise = Promise<Void>.init(resolvers: { (fulfil, reject) in
                Auth.auth().signInAnonymously() { (authResult, error) in
                    if let error = error {
                         ///automatic retry?
                        reject(error)
                    }else  if let authResult = authResult {
                        let user = authResult.user
                        self.userFromLogin = user
                        self.downloadAndReplaceUserData()
                        fulfil(())
                    }else{
                        reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
                    }
                    
                }
            })
            return promise
        }
    }
    private func createAccount(email:String, password:String) -> Promise<LoginOrCreateAccountResult>{
        return Promise<LoginOrCreateAccountResult>.init(resolvers: { (fulfil, reject) in
            Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                if let error = error {
                    reject(error)
                }else  if let authResult = authResult {
                    let user = authResult.user
                    self.userFromLogin = user
                    self.downloadAndReplaceUserData()
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
        })
    }
    
    func confirmSignup(code:String) -> Promise<Void>{
        return Promise { fulfill, reject in
            Auth.auth().applyActionCode(code, completion: { (error) in
                if let error = error {
                    reject(error)
                }else{
                    if let user = self.user, let email = self.email {
                        self.databaseRef.child("users").child(user.uid).child("email").setValue(email.lowercased())
                        UserDefaults.standard.set(email.lowercased(), forKey: UserDefaultsKeys.email)
                    }
                    fulfill(())
                }
            })
        }
    }
    
    func resendConfirmCode() -> Promise<Void>{
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
                reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
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
        }
    }
    
    @discardableResult func setGDPR(agreedToEmail:Bool, agreedToImageDetection:Bool) -> Promise<Void>{
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
                    fulfill(())
                }else{
                    reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
                }
            }).catch(execute: { (error) in
                reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
            })
        }
    }
    
    @discardableResult func setProfile(displayName:String?, gender:String?, size:String?, unverifiedEmail:String?) -> Promise<Void>{
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
                    fulfill(())
                }else{
                    reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
                }
            }).catch(execute: { (error) in
                reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
            })
        }
    }

    func logout() -> Promise<Void>{
        return Promise { fulfill, reject in
            do {
                FBSDKLoginManager().logOut()
                if self.user?.isAnonymous == false || self.user?.providerData.first(where: {$0.providerID == "facebook.com"}) != nil {
                    try Auth.auth().signOut()
                    makeAnonAccountPromise = nil
                    makeAnonAccount().then(execute: { () -> () in
                        fulfill(())
                    }).catch(execute: { (e) in
                        fulfill(()) // not a bug.  you did logout - even if a new accout was not created.
                    })
                    
                }else{
                    fulfill(())
                }
                
            }catch let error {
                reject(error)
            }
            
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
        Analytics.trackOnboardingUnsupportedError(domain: error.domain, code: error.code, localizedDescription: error.localizedDescription)
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

            let body = "Please help me. I’m getting this weirdo error: \(String.init(describing: viewController)) Domain: \(error.domain) Code: \(error.code) \(userInfoJson) -  \(Bundle.displayVersionBuild). I don’t know what this means, because I am not a programmer. But ya’ll should be able to help me."
            let gmailMessage = body
            viewController.presentMail(recipient: recipient, gmailMessage: gmailMessage, subject: subject, message: body)
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
    
    
    func downloadAndReplaceUserData(){
        if let user = self.user{
            self.databaseRef.child("users").child(user.uid).child("GDRP-agreedToEmail").observeSingleEvent(of: .value) { (snapshot) in
                if let agreedToEmailNumber = snapshot.value as? NSNumber  {
                    let agreedToEmail = agreedToEmailNumber.boolValue
                    UserDefaults.standard.setValue(agreedToEmail, forKey: UserDefaultsKeys.gdpr_agreedToEmail)
                }
            }
            self.databaseRef.child("users").child(user.uid).child("GDRP-agreedToImageDetection").observeSingleEvent(of: .value) { (snapshot) in
                if let agreedToImageDetectionNumber = snapshot.value as? NSNumber  {
                    let agreedToImageDetection = agreedToImageDetectionNumber.boolValue
                    UserDefaults.standard.setValue(agreedToImageDetection, forKey: UserDefaultsKeys.gdpr_agreedToImageDetection)
                }
            }
            
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
                                    let s = DataModel.sharedInstance.saveScreenshot(managedObjectContext: context,
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
            
            self.databaseRef.child("users").child(user.uid).child("favorite").observeSingleEvent(of: .value) { (snapshot) in
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
                                                                               color:  color,
                                                                               sku: sku,
                                                                               fallbackPrice: fallbackPrice,
                                                                               optionsMask: Int32(optionsMask))
                            
                            
                            context.saveIfNeeded()
                            DataModel.sharedInstance.favorite(toFavorited: true, productOIDs: [product.objectID])
                        })
                    }
                }
            }
        }
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
                                     "floatPrice":floatPrice,
                                     "floatOriginalPrice":floatOriginalPrice,
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
            
            if let color = product.color {
                dict["color"] = color
                
            }
            if let sku = product.sku {
                dict["sku"] = sku
                
            }
            dict["optionsMask"] = product.optionsMask
            dict["fallbackPrice"] = NSNumber.init(value: product.fallbackPrice)
            self.databaseRef.child("users").child(user.uid).child("favorites").child(offer).setValue(dict)
        }
    }
    
    func deleteFavorite(product:Product){
        if let user = self.user {
            if let offer = product.offer {
                self.databaseRef.child("users").child(user.uid).child("favorites").child(offer).removeValue()
            }
        }
    }
    
    func deleteScreenshot(screenshot:Screenshot) {
        if let assetId = screenshot.assetId, let user = self.user {
            self.databaseRef.child("users").child(user.uid).child("screenshots").child(assetId).removeValue()
        }
    }
    
    func uploadScreenshots(screenshot:Screenshot){
        
        if let user = self.user,
            let assetId = screenshot.assetId,
            let createdAtNumber = screenshot.createdAt?.timeIntervalSince1970,
            let uploadedImageURL = screenshot.uploadedImageURL {
            let trackingInfo = screenshot.trackingInfo ?? ""
            let source = screenshot.source.rawValue
            let dict:[String:Any] = [
                "assetId":assetId,
                "createdAt":NSNumber.init(value: createdAtNumber as Double),
                "source":source,
                "uploadedImageURL":uploadedImageURL,
                "trackingInfo" :trackingInfo
                        ]
            
            self.databaseRef.child("users").child(user.uid).child("screenshots").child(assetId).setValue(dict)
        }

    }
}

extension UserAccountManager {
    public func uploadImage(data:Data) -> Promise<URL> {
        return Promise { fulfill, reject in
            if let user = self.user {
                let name = UUID().uuidString
                let uploadRef = storageRef.child("user").child(user.uid).child("images").child("\(name).jpg")
                
                let uploadTask = uploadRef.putData(data, metadata: nil) { (metadata, error) in
                    if let error = error {
                        reject(error)
                    }else{
                        uploadRef.downloadURL { url, error in
                            if let error = error {
                                reject(error)
                            } else if let url = url{
                                fulfill(url)
                            }else{
                                reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
                            }
                        }
                    }
                }
            }else{
                reject(NSError.init(domain: "SigninManager", code: #line, userInfo: [:]))
            }
        }
    }
}

