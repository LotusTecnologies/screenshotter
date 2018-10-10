//
//  String+Format.swift
//  Screenshop
//
//  Created by Corey Werner on 8/12/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

extension String {
    var nonEmptyValue: String? {
        return isEmpty ? nil : self
    }
    func singularSyteCategory() -> String {
        var singulizeThis = [
            "Backpacks":"backpack",
            "Bags":"bag",
            "Belts":"belt",
            "Bracelets":"bracelet",
            "Coats":"coat",
            "Dresses":"dress",
            "Hats":"hat",
            "Jackets":"jacket",
            "Jewelry":"jewelry",
            "Jumpsuits":"jumpsuit",
            "Makeup":"makeup",
            "Neclesses":"necklace",
            "PouchBag":"bag",
            "Rings":"ring",
            "Scarfs":"scarve",
            "Shirts":"shirt",
            "Shorts":"short",
            "Skirts":"skirt",
            "Swimwear":"swimwear",
            "Ties":"tie",
            "Wallets":"wallet",
            "Watches":"watch"]
        var singularizeThese = [
            "Jeans":"jeans",
            "Sunglasses":"sunglasses",
            "SocksAndTights":"socks",
            "Boots":"boots",
            "Gloves":"gloves",
            "Mittens":"mittens",
            "Trousers":"trousers",
            "Underwear":"underwear",
            "Shoes":"shoes",
            "Earrings":"earrings"
]
        if let value = singulizeThis[self]{
            return "this \(value)"
        }else if let value = singularizeThese[self]{
            return "these \(value)"
        }else{
            return "this \(self)"
        }

       

    }
    func normalizedSyteCategory() -> String? {
        var validCategories = ["Shoes":"Shoes",
                               "Shirts":"Shirts",
                               "Trousers":"Trousers",
                               "Dresses":"Dresses",
                               "Bags":"Bags",
                               "Boots":"Boots",
                               "Sunglasses":"Sunglasses",
                               "Jackets":"Jackets",
                               "Neclesses":"Necklaces",
                               "necklaces":"Necklaces",
                               "Skirts":"Skirts",
                               "Bracelets":"Bracelets",
                               "Coats":"Coats",
                               "Earrings":"Earrings",
                               "Shorts":"Shorts",
                               "Shirts_HiddenUnderJacket":"Shirts",
                               "Hats":"Hats",
                               "Swimwear":"Swimwear",
                               "Belts":"Belts",
                               "Jumpsuits":"Jumpsuits",
                               "Watches":"Watches",
                               "SocksAndTights":"Socks",
                               "Underwear":"Underwear",
                               "Rings":"Rings",
                               "Ties":"Ties",
                               "Backpacks":"Backpacks",
                               "Scarfs":"Scarves",
                               "WalletsPurses":"Purses",
                               "GlovesAndMitten":"Gloves",
                               "PouchBag":"Bags",
                               "Makeup":"Makeup"]
        var transforms = ["Footwear":"Shoes",
                          "Jewellery":"Jewelry",  //Jewellery is british
                          "Pants":"Pants",
                          "Shoe":"Shoes",
                          "Shirt":"Shirts",
                          "Trouser":"Trousers",
                          "Dress":"Dresses",
                          "Bag":"Bags",
                          "Boot":"Boots",
                          "Jacket":"Jackets",
                          "necklace":"Necklaces",
                          "Skirt":"Skirts",
                          "Bracelet":"Bracelets",
                          "Coat":"Coats",
                          "Earring":"Earrings",
                          "Hat":"Hats",
                          "Swimwear":"Swimwear",
                          "bikini":"Swimwear",
                          "Belt":"Belts",
                          "Jumpsuit":"Jumpsuits",
                          "Watch":"Watches",
                          "Socks":"Socks",
                          "Tights":"Tights",
                          "Ring":"Rings",
                          "Tie":"Ties",
                          "Backpack":"Backpacks",
                          "Scarf":"Scarves",
                          "Wallet":"Wallets",
                          "Wallets":"Wallets",
                          "Purses":"Purses",
                          "Purse":"Purses",
                          "Gloves":"Gloves",
                          "Glove":"Gloves",
                          "Mitten":"Mittens",
                          "Mittens":"Mittens",
                          "Jewelery":"Jewelry",
                          "Jeans":"Jeans"]

        
        if let lookup = validCategories[self] {
            return lookup
        }
        for validValue in validCategories.values {
            if self.lowercased().contains(validValue.lowercased()) {
                return validValue
            }
        }
        for transform in transforms.keys {
            if self.lowercased().contains(transform.lowercased()) {
                return transforms[transform]
            }
        }
        
        return nil
    }
    
}
