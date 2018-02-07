//
//  InAppPurchaseManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 2/6/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit
import StoreKit
import PromiseKit

enum InAppPurchaseProduct : String {
    case personalStylist = "com.crazeapp.nonconsumable.stylisthelp"
    
    func productIdentifier() -> String{
        return self.rawValue
    }
    static let allProductIdentifiers:Set = [personalStylist.productIdentifier()]
    
}

class InAppPurchaseInfoProxy : NSObject, SKProductsRequestDelegate  {
    var dateRetrived:Date?
    private let (privatePromise, fulfill, reject) = Promise<[SKProduct]>.pending()
    private var productsRequest:SKProductsRequest?
    
    var promise:Promise<[SKProduct]>  {
        get{
            return privatePromise
        }
    }
    
     func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        dateRetrived = Date.init()
        print ("found SKProducts \(response.products) invalid:\(response.invalidProductIdentifiers)")
        fulfill( response.products )
    }
     func request(_ request: SKRequest, didFailWithError error: Error) {
        dateRetrived = Date.init()
        reject( error )
    }
    
    
    override init() {
        super.init()
        let productsRequest = SKProductsRequest(productIdentifiers: InAppPurchaseProduct.allProductIdentifiers )
        self.productsRequest = productsRequest
        productsRequest.delegate = self
        productsRequest.start()
        
    }
    deinit {
        productsRequest?.delegate = nil
        productsRequest?.cancel()
        if promise.isPending {
            let error = NSError.init(domain: "Craze", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request was canceled"]) // this shouldn't happen
            reject(  error )
        }
    }
}


class InAppPurchaseBuyingProxy : NSObject, SKPaymentTransactionObserver  {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            if transaction.payment == self.payment {
                if transaction.transactionState == .purchased || transaction.transactionState == .restored {
                    fulfill()
                }else if transaction.transactionState == .failed{
                    let error = NSError.init(domain: "Craze", code: -3, userInfo: [NSLocalizedDescriptionKey:"Failed to Purchase"])
                    reject(error)
                }
            }
        }
    }
    
    
    private let (privatePromise, fulfill, reject) = Promise<Void>.pending()
    private var payment:SKPayment?
    init(product:SKProduct) {
        super.init()
        SKPaymentQueue.default().add(self)
        let payment = SKPayment.init(product:product)
        self.payment = payment
        SKPaymentQueue.default().add(payment)
    }
    var promise:Promise<Void>  {
        get{
            return privatePromise
        }
    }
    
    
    deinit {
        SKPaymentQueue.default().remove(self)
        if promise.isPending {
            let error = NSError.init(domain: "Craze", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request was canceled"]) // this shouldn't happen

            reject( error )  // canceled
        }
    }
}

class InAppPurchaseManager: NSObject {
    
    public static let sharedInstance:InAppPurchaseManager = InAppPurchaseManager.init()

    private var infoProxy:InAppPurchaseInfoProxy?
    private var buyProxy:[SKProduct: InAppPurchaseBuyingProxy?] = [:]

    func didPurchase(_inAppPurchaseProduct:InAppPurchaseProduct) -> Bool {
        return true
//        let array = UserDefaults.standard.object(forKey: UserDefaultsKeys.purchasedProductIdentifier) as? Array<String>
//        if let array = array {
//            return array.contains(_inAppPurchaseProduct.productIdentifier())
//        }
//        
//        return false
    }
     func loadProductInfo() -> (){
        if infoProxy == nil {
            infoProxy = InAppPurchaseInfoProxy.init()
        }
    }
    public func buyProduct(_ inAppPurchaseProduct:InAppPurchaseProduct) ->Promise<Void>{
        let (promise, fulfill, reject) = Promise<Void>.pending()

        
        if didPurchase(_inAppPurchaseProduct: inAppPurchaseProduct) {
            fulfill()
        }else{
            if SKPaymentQueue.canMakePayments() {
                
                if infoProxy == nil {
                    infoProxy = InAppPurchaseInfoProxy.init()
                }else if let info = infoProxy {
                    if info.promise.isRejected {
                        infoProxy = InAppPurchaseInfoProxy.init()
                    }else if info.promise.isFulfilled {
                        if let date = info.dateRetrived {
                            if date.timeIntervalSinceNow > 60*60*24{
                                infoProxy = InAppPurchaseInfoProxy.init()
                            }
                        }
                    }
                }
                infoProxy?.promise.then(execute: { (products) -> () in

                    var productFound = false
                    for p in products {
                        if p.productIdentifier == inAppPurchaseProduct.productIdentifier() {
                            productFound = true
                            var buyProxy = self.buyProxy[p]
                            if  buyProxy == nil {
                                buyProxy = InAppPurchaseBuyingProxy.init(product: p)
                            }
                            buyProxy!?.promise.then( execute:{
                                fulfill()
                            }).catch ( execute:{
                                reject($0)
                            })
                            
                            

                        }
                    }
                    if productFound == false{
                        let error = NSError.init(domain: "Craze", code: -2, userInfo: [NSLocalizedDescriptionKey: "In app purchase not found"]) // this shouldn't happen

                        reject(error)
                    }
                    
                }).catch(execute: { (error) in
                    reject( error )
                })
            }else{
                let error = NSError.init(domain: "Craze", code: -2, userInfo: [NSLocalizedDescriptionKey:"You are not authorized for in app purchases on this device"])
                reject( error )
            }
           
        }
        return promise
    }
    
}
