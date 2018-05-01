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


enum InAppPurchaseProduct : Int  {
    case personalStylist
    //when more purchases are added updated the tracking code in buy() which only works for this one purchase
    
    func productIdentifier() -> String{
        switch self {
        case .personalStylist:
            #if DEV
                return "com.crazeapp.stylisthelp"
            #else
                return "com.crazeapp.nonconsumable.stylisthelp2"
            #endif
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
extension Notification.Name {
    
    static let InAppPurchaseManagerDidUpdate = Notification.Name("com.screenshopit.InAppPurchaseManagerDidUpdate")
}
class InAppPurchaseManager: NSObject, SKPaymentTransactionObserver {
    
    public static let sharedInstance:InAppPurchaseManager = InAppPurchaseManager.init()
    private var productRequest:Promise<SKProductsResponse>?
    private var buyRequest:Promise<SKPaymentTransaction>?
    private var restoreRequest:Promise<[String]>?
    private var productResponse:SKProductsResponse?
    

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
                NotificationCenter.default.post(name: Notification.Name.InAppPurchaseManagerDidUpdate, object: nil)

            }
        }
    }
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func isInProcessOfBuying() -> Bool {
        return self.buyRequest?.isPending ?? false
    }
    
    public func didPurchase(_inAppPurchaseProduct:InAppPurchaseProduct) -> Bool {
        let array = UserDefaults.standard.object(forKey: UserDefaultsKeys.purchasedProductIdentifier) as? Array<String>
        if let array = array {
            return array.contains(_inAppPurchaseProduct.productIdentifier())
        }
        return false
    }
    
    func loadProductInfoIfNeeded() {
        _ = loadProductInfo()
    }
    
    func productIfAvailable(product:InAppPurchaseProduct) -> SKProduct? {
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
            productRequest?.then { (response) -> Void in
                self.productResponse = response
            }
        }
        return productRequest!
    }
    
    func restoreInAppPurchases() -> Promise<[String]>{
        if let restoreRequest = self.restoreRequest, restoreRequest.isPending {
            return restoreRequest
        }
        let request = SKPaymentQueue.default().restorePromise()
        self.restoreRequest = request
        return request
    }
    
    func canPurchase()  -> Bool{
        return SKPaymentQueue.canMakePayments()
    }

    func buy ( product:SKProduct, success:@escaping (()->Void), failure:@escaping((Error)->Void)){
        let buyRequest = SKPayment.init(product: product).promise()
        self.buyRequest = buyRequest
        buyRequest.then(on:.main)  { (transaction) -> Promise<Bool> in
            success()
            NotificationCenter.default.post(name: Notification.Name.InAppPurchaseManagerDidUpdate, object: nil)
            
            Analytics.trackInAppPurchase(purchase: .stylists, type: .onetime, price: product.localizedPriceString())
            
            return Promise(value:true)
        }.catch(on: .main) { (error) in
            failure(error)
            NotificationCenter.default.post(name: Notification.Name.InAppPurchaseManagerDidUpdate, object: nil)

        }
        NotificationCenter.default.post(name: Notification.Name.InAppPurchaseManagerDidUpdate, object: nil)

    }
    
    func load(product:InAppPurchaseProduct, success:@escaping ((SKProduct)->Void), failure:@escaping((Error)->Void) ){
        self.loadProductInfo().then( on:.main) { (response) -> Promise<Bool> in
            if let product = response.products.first(where: { (p) -> Bool in p.productIdentifier == product.productIdentifier() }) {
               success(product)
            }else{
                let error = NSError.init(domain: "Craze", code: -2, userInfo: [NSLocalizedDescriptionKey: "In app purchase not found"]) // this shouldn't happen
                failure(error)
            }
            return Promise.init(value: true)
        }.catch(on:.main) { (error) in
            failure(error)
        }
    }
}


extension SKProduct {
    func localizedPriceString() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.formatterBehavior = .behavior10_4
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = self.priceLocale
        let priceString = numberFormatter.string(from: self.price)
        return priceString ?? ""
    }
}
