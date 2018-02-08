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


@objc enum InAppPurchaseProduct : Int  {
    case personalStylist
    
    func productIdentifier() -> String{
        switch self {
        case .personalStylist:
            return "com.crazeapp.nonconsumable.stylisthelp"
        }
    }
    static let allProductIdentifiers:Set = [personalStylist.productIdentifier()]
    
}

extension SKPaymentQueue {
    public func restorePromise() -> Promise<[String]> {
        return RestoreObserver.init(queue:self).promise
    }

}

fileprivate class RestoreObserver: NSObject, SKPaymentTransactionObserver {
    let (promise, fulfill, reject) = Promise<[String]>.pending()
    var retainCycle: RestoreObserver?
    var array:[String] = []
    init(queue:SKPaymentQueue) {
        super.init()
        queue.add(self)
        queue.restoreCompletedTransactions()
        retainCycle = self
    }
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        queue.remove(self)
        fulfill(array)
        retainCycle = nil
    }
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        queue.remove(self)
        reject(error)
        retainCycle = nil
    }
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for t in transactions {
            if t.transactionState == .restored {
                self.array.append(t.payment.productIdentifier)
            }
        }
    }
    
}

class InAppPurchaseManager: NSObject, SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for t in transactions {
            let productIdentifier = t.payment.productIdentifier
            if t.transactionState == .purchased || t.transactionState == .restored {
                if var array = UserDefaults.standard.object(forKey: UserDefaultsKeys.purchasedProductIdentifier) as? Array<String> {
                    if !array.contains(productIdentifier) {
                        array.append(productIdentifier)
                        UserDefaults.standard.setValue(array, forKey: UserDefaultsKeys.purchasedProductIdentifier)
                    }
                }else{
                    UserDefaults.standard.setValue([productIdentifier], forKey: UserDefaultsKeys.purchasedProductIdentifier)
                }
            }
        }
    }
    
    private var productRequest:Promise<SKProductsResponse>?
    private var buyRequest:Promise<SKProductsResponse>?
    private var restoreRequest:Promise<[String]>?
    private var productResponse:SKProductsResponse?
    public static let sharedInstance:InAppPurchaseManager = InAppPurchaseManager.init()

    
    
    @objc public func didPurchase(_inAppPurchaseProduct:InAppPurchaseProduct) -> Bool {
        let array = UserDefaults.standard.object(forKey: UserDefaultsKeys.purchasedProductIdentifier) as? Array<String>
        if let array = array {
            return array.contains(_inAppPurchaseProduct.productIdentifier())
        }
        return false
    }
    @objc func loadProductInfoIfNeeded() {
        _ = loadProductInfo()
    }
    @objc func productIfAvailable(product:InAppPurchaseProduct) -> SKProduct? {
        if let response  = self.productResponse {
            if let product = response.products.first(where: { (p) -> Bool in p.productIdentifier == product.productIdentifier() }) {
                return product
            }
        }
        return nil
    }
    
    func loadProductInfo() -> Promise<SKProductsResponse>{
        if productRequest == nil || productRequest!.isRejected { // once you get one successful request no need to do it again
            productRequest = SKProductsRequest.init(productIdentifiers: InAppPurchaseProduct.allProductIdentifiers).promise()
            productRequest?.then(execute: { (response) ->Promise<Void> in
                self.productResponse = response
                print("products: \(response.products) inavlid:\(response.invalidProductIdentifiers)")
                return Promise(value:true).asVoid()
            })
        }
        return productRequest!
        
    }
    func restoreInAppPurchases() -> Promise<[String]>{
        if let restoreRequest = self.restoreRequest, restoreRequest.isPending {
            return restoreRequest
        }
        let reqeust =  SKPaymentQueue.default().restorePromise()
        self.restoreRequest = reqeust
        return reqeust
    }
    @objc func canPurchase()  -> Bool{
        return SKPaymentQueue.canMakePayments()
    }

    @objc func buy ( product:SKProduct, success:@escaping (()->Void), failure:@escaping((Error)->Void)){
        SKPayment.init(product: product).promise().then(on:.main, execute: { (transaction) -> Promise<Bool> in
            success()
            return Promise(value:true)
        }).catch(on: .main, execute:{ (error) in
            failure(error)
        })
    }
    @objc func load(product:InAppPurchaseProduct, success:@escaping ((SKProduct)->Void), failure:@escaping((Error)->Void) ){
        self.loadProductInfo().then( on:.main, execute: { (response) -> Promise<Bool> in
            if let product = response.products.first(where: { (p) -> Bool in p.productIdentifier == product.productIdentifier() }) {
               success(product)
            }else{
                let error = NSError.init(domain: "Craze", code: -2, userInfo: [NSLocalizedDescriptionKey: "In app purchase not found"]) // this shouldn't happen
                failure(error)
            }
            return Promise.init(value: true)
        }).catch(on:.main, execute: { (error) in
            failure(error)
        })
    }
    
    public func buyProduct(_ inAppPurchaseProduct:InAppPurchaseProduct) -> Promise<Bool>{
        if didPurchase(_inAppPurchaseProduct: inAppPurchaseProduct) {
            return Promise(value: true)
        }else{
            if SKPaymentQueue.canMakePayments() {
                return self.loadProductInfo().then(execute: { (response) -> Promise<Bool> in
                    if let product = response.products.first(where: { (p) -> Bool in p.productIdentifier == inAppPurchaseProduct.productIdentifier() }) {
                        return SKPayment.init(product: product).promise().then(execute: { (transaction) -> Promise<Bool> in
                            return Promise(value: true)
                        })
                    }else{
                        let error = NSError.init(domain: "Craze", code: -2, userInfo: [NSLocalizedDescriptionKey: "In app purchase not found"]) // this shouldn't happen
                        return Promise.init(error: error)
                    }
                })
            }else{
                let error = NSError.init(domain: "Craze", code: -2, userInfo: [NSLocalizedDescriptionKey:"You are not authorized for in app purchases on this device"])
                return Promise.init(error: error)
            }
        }
    }    
}
