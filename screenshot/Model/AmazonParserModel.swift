//
//  AmazonParserModel.swift
//  Screenshop
//
//  Created by Gershon Kagan on 07/23/2018.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import SWXMLHash
import UIKit

// See wsdl: http://webservices.amazon.com/AWSECommerceService/2013-08-01/AWSECommerceService.wsdl

struct AmazonImage: XMLIndexerDeserializable {
    let urlString: String // required
    let height: Float // required
    let width: Float // required
//    let isVerified: String?
    
    static func deserialize(_ node: XMLIndexer) throws -> AmazonImage {
        return try AmazonImage(
            urlString: node["URL"].value(),
            height: node["Height"].value(),
            width: node["Width"].value()
//            isVerified: node["IsVerified"].value()
        )
    }
}


struct AmazonImageSet: XMLIndexerDeserializable {
    let swatchImage: AmazonImage?
    let smallImage: AmazonImage?
    let thumbnailImage: AmazonImage?
    let tinyImage: AmazonImage?
    let mediumImage: AmazonImage?
    let largeImage: AmazonImage?
    let hiResImage: AmazonImage?

    static func deserialize(_ node: XMLIndexer) throws -> AmazonImageSet {
        return try AmazonImageSet(
            swatchImage: node["SwatchImage"].value(),
            smallImage: node["SmallImage"].value(),
            thumbnailImage: node["ThumbnailImage"].value(),
            tinyImage: node["TinyImage"].value(),
            mediumImage: node["MediumImage"].value(),
            largeImage: node["LargeImage"].value(),
            hiResImage: node["HiResImage"].value()
        )
    }
}


struct AmazonPrice: XMLIndexerDeserializable {
    let amount: Float?
    let currencyCode: String?
    let formattedPrice: String // required
    
    static func deserialize(_ node: XMLIndexer) throws -> AmazonPrice {
        let amountInt: Int? = try node["Amount"].value()
        let curr: String? = try node["CurrencyCode"].value()
        var amountFloat: Float?
        if let amountInt = amountInt {
            // See: https://en.wikipedia.org/wiki/ISO_4217
            switch curr ?? "USD" {
            case "BIF", "CLP", "CVE", "DJF", "GNF", "ISK", "JPY", "KMF", "KRW", "PYG", "RWF", "UGX", "UYI", "VND", "VUV", "XAF", "XOF", "XPF":
                amountFloat = Float(amountInt)
            case "MGA ", "MRU":
                amountFloat = Float(amountInt) / 10.0
            case "BHD", "IQD", "JOD", "KWD", "LYD", "OMR", "TND":
                amountFloat = Float(amountInt) / 1_000.0
            case "CLF":
                amountFloat = Float(amountInt) / 10_000.0
            default:
                amountFloat = Float(amountInt) / 100.0
            }
        }
        return try AmazonPrice(
            amount: amountFloat,
            currencyCode: curr,
            formattedPrice: node["FormattedPrice"].value()
        )
    }
}


struct AmazonOfferSummary: XMLIndexerDeserializable {
    let lowestNewPrice: AmazonPrice?
    let lowestUsedPrice: AmazonPrice?
    let lowestCollectiblePrice: AmazonPrice?
    let lowestRefurbishedPrice: AmazonPrice?
    let totalNew: Int?
    let totalUsed: Int?
    let totalCollectible: Int?
    let totalRefurbished: Int?
    
    static func deserialize(_ node: XMLIndexer) throws -> AmazonOfferSummary {
        return try AmazonOfferSummary(
            lowestNewPrice: node["LowestNewPrice"].value(),
            lowestUsedPrice: node["LowestUsedPrice"].value(),
            lowestCollectiblePrice: node["LowestCollectiblePrice"].value(),
            lowestRefurbishedPrice: node["LowestRefurbishedPrice"].value(),
            totalNew: node["TotalNew"].value(),
            totalUsed: node["TotalUsed"].value(),
            totalCollectible: node["TotalCollectible"].value(),
            totalRefurbished: node["TotalRefurbished"].value()
        )
    }
}


struct AmazonOfferListing: XMLIndexerDeserializable {
    let offerListingId: String?
    let pricePerUnit: String?
    let price: AmazonPrice?
    let salePrice: AmazonPrice?
    let amountSaved: AmazonPrice?
//    let percentageSaved: nonNegativeInteger?
    let availability: String?
//    let availabilityAttributes: AmazonAvailabilityAttributes?
    let isEligibleForSuperSaverShipping: Bool?
    let IsEligibleForPrimeFreeDigitalVideo: Bool?
    let isEligibleForPrime: Bool?

    static func deserialize(_ node: XMLIndexer) throws -> AmazonOfferListing {
        return try AmazonOfferListing(
            offerListingId: node["OfferListingId"].value(),
            pricePerUnit: node["PricePerUnit"].value(),
            price: node["Price"].value(),
            salePrice: node["SalePrice"].value(),
            amountSaved: node["AmountSaved"].value(),
//            percentageSaved: node["PercentageSaved"].value(),
            availability: node["Availability"].value(),
//            availabilityAttributes: node["AvailabilityAttributes"].value(),
            isEligibleForSuperSaverShipping: node["IsEligibleForSuperSaverShipping"].value(),
            IsEligibleForPrimeFreeDigitalVideo: node["IsEligibleForPrimeFreeDigitalVideo"].value(),
            isEligibleForPrime: node["IsEligibleForPrime"].value()
        )
    }
}


struct AmazonOffer: XMLIndexerDeserializable {
//    let merchant: AmazonMerchant?
//    let offerAttributes: AmazonOfferAttributes?
    let offerListing: [AmazonOfferListing]?
//    let loyaltyPoints: AmazonLoyaltyPoints?
//    let promotions: AmazonPromotions?

    static func deserialize(_ node: XMLIndexer) throws -> AmazonOffer {
        return try AmazonOffer(
//            merchant: node["Merchant"].value(),
//            offerAttributes: node["OfferAttributes"].value(),
            offerListing: node["OfferListing"].value()
//            loyaltyPoints: node["LoyaltyPoints"].value(),
//            promotions: node["Promotions"].value(),
        )
    }
}

struct AmazonItemAttributes: XMLIndexerDeserializable {
    let binding: String?
    let brand: String?
    let clothingSize: String?
    let color: String?
    let department: String?
    let feature: [String]?
    let isAdultProduct: Int?
    let listPrice: AmazonPrice?
    let model: String?
    let productGroup: String?
    let productTypeName: String?
    let size: String?
    let title: String?
    
    static func deserialize(_ node: XMLIndexer) throws -> AmazonItemAttributes {
        return try AmazonItemAttributes(
            binding: node["Binding"].value(),
            brand: node["Brand"].value(),
            clothingSize: node["ClothingSize"].value(),
            color: node["Color"].value(),
            department: node["Department"].value(),
            feature: node["Feature"].value(),
            isAdultProduct: node["IsAdultProduct"].value(),
            listPrice: node["ListPrice"].value(),
            model: node["Model"].value(),
            productGroup: node["ProductGroup"].value(),
            productTypeName: node["ProductTypeName"].value(),
            size: node["Size"].value(),
            title: node["Title"].value()
        )
    }
}


struct AmazonItem: XMLIndexerDeserializable {
    let asin: String // required
    let parentAsin: String?
//    let errors: AmazonErrors?
    let detailPageURL: String?
//    let itemLinks: AmazonItemLinks?
    let salesRank: String?
    let smallImage: AmazonImage?
//    let mediumImage: AmazonImage?
    let largeImage: AmazonImage?
//    let imageSets: [AmazonImageSet]?
    let itemAttributes: AmazonItemAttributes?
//    let variationAttributes: [AmazonVariationAttribute] // maxOccurs=1
//    let relatedItems: AmazonRelatedItems?
//    let collections: AmazonCollections?
//    let subjects: [String] // maxOccurs=1
    let offerSummary: AmazonOfferSummary?
    let offers: [AmazonOffer]?
//    let rentalOffers: [AmazonRentalOffer]
//    let variationSummary: AmazonVariationSummary?
//    let variations: [AmazonVariation]
//    let customerReviews: AmazonCustomerReviews?
//    let editorialReviews: [AmazonEditorialReview]
//    let similarProducts: [AmazonSimilarProduct]
//    let accessories: [AmazonAccessory]
//    let tracks: [AmazonTrack]
//    let browseNodes: AmazonBrowseNodes?
//    let alternateVersions: [AmazonAlternateVersion] // maxOccurs=1

    static func deserialize(_ node: XMLIndexer) throws -> AmazonItem {
        return try AmazonItem(
            asin: node["ASIN"].value(),
            parentAsin: node["ParentASIN"].value(),
//            errors: node["Errors"].value(),
            detailPageURL: node["DetailPageURL"].value(),
//            itemLinks: node["ItemLinks"].value(),
            salesRank: node["SalesRank"].value(),
            smallImage: node["SmallImage"].value(),
//            mediumImage: node["MediumImage"].value(),
            largeImage: node["LargeImage"].value(),
//            imageSets: node["ImageSets"]["ImageSet"].value(),
            itemAttributes: node["ItemAttributes"].value(),
//            variationAttributes: node["VariationAttributes"]["VariationAttribute"].value(),
//            relatedItems: node["RelatedItems"].value(),
//            collections: node["Collections"].value(),
//            subjects: node["Subjects"]["Subject"].value(),
            offerSummary: node["OfferSummary"].value(),
            offers: node["Offers"]["Offer"].value()
//            rentalOffers: node["RentalOffers"]["RentalOffer"].value(),
//            variationSummary: node["VariationSummary"].value(),
//            variations: node["Variations"]["Variation"].value()
//            customerReviews: node["CustomerReviews"].value(),
//            editorialReviews: node["EditorialReviews"]["EditorialReview"].value(),
//            similarProducts: node["SimilarProducts"]["SimilarProduct"].value(),
//            accessories: node["Accessories"]["Accessory"].value(),
//            tracks: node["Tracks"]["Disc"]["Track"].value(),
//            browseNodes: node["BrowseNodes"].value(),
//            alternateVersions: node["AlternateVersions"]["AlternateVersion"].value()
        )
    }
}

struct AmazonResponse: XMLIndexerDeserializable {
    let items: [AmazonItem]?
    let itemPage: Int?
//    let keywords: String?
    let totalPages: Int?
    
    static func deserialize(_ node: XMLIndexer) throws -> AmazonResponse {
        return try AmazonResponse(
            items: node["Item"].value(),
            itemPage: node["Request"]["ItemSearchRequest"]["ItemPage"].value(),
//            keywords: node["Request"]["ItemSearchRequest"]["Keywords"].value(),
            totalPages: node["TotalPages"].value()
        )
    }
}


struct AmazonErrorResponse: XMLIndexerDeserializable {
    let code: String
    let message: String
    
    static func deserialize(_ node: XMLIndexer) throws -> AmazonErrorResponse {
        return try AmazonErrorResponse(
            code: node["Code"].value(),
            message: node["Message"].value()
        )
    }
}


class AmazonParserModel {
    let xmlIndexer: XMLIndexer
    
    init(xmlData: Data) {
        xmlIndexer = SWXMLHash.parse(xmlData)
    }
    
    var error: AmazonErrorResponse? {
        if let error: AmazonErrorResponse = try? xmlIndexer["ItemSearchErrorResponse"]["Error"].value() {
            return error
        }
        else if let error: AmazonErrorResponse = try? xmlIndexer["ItemSearchResponse"]["Items"]["Request"]["Errors"]["Error"].value() {
            return error
        }
        return nil
    }
    
    var items: [AmazonItem]? {
        if let items: [AmazonItem] = try? xmlIndexer["ItemSearchResponse"]["Items"]["Item"].value() {
            return items
        }
        return nil
    }
    
    var response: AmazonResponse? {
        if let response: AmazonResponse = try? xmlIndexer["ItemSearchResponse"]["Items"].value() {
            return response
        }
        return nil
    }
}
