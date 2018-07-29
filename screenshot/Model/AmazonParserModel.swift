//
//  AmazonParserModel.swift
//  Screenshop
//
//  Created by Gershon Kagan on 07/23/2018.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import SWXMLHash
import UIKit

struct AmazonImage: XMLIndexerDeserializable {
    let urlString: String//?
    let height: Float
    let width: Float
    
    static func deserialize(_ node: XMLIndexer) throws -> AmazonImage {
        return try AmazonImage(
            urlString: node["URL"].value(),
            height: node["Height"].value(),
            width: node["Width"].value()
        )
    }
}


struct AmazonVariant: XMLIndexerDeserializable {
    let swatchImage: AmazonImage//?
    let smallImage: AmazonImage//?
    let thumbnailImage: AmazonImage//?
    let tinyImage: AmazonImage//?
    let mediumImage: AmazonImage//?
    let largeImage: AmazonImage//?
    
    static func deserialize(_ node: XMLIndexer) throws -> AmazonVariant {
        return try AmazonVariant(
            swatchImage: node["SwatchImage"].value(),
            smallImage: node["SmallImage"].value(),
            thumbnailImage: node["ThumbnailImage"].value(),
            tinyImage: node["TinyImage"].value(),
            mediumImage: node["MediumImage"].value(),
            largeImage: node["LargeImage"].value()
        )
    }
}


struct AmazonPrice: XMLIndexerDeserializable {
    let amount: Float
    let currencyCode: String
    let formattedPrice: String
    
    static func deserialize(_ node: XMLIndexer) throws -> AmazonPrice {
        return try AmazonPrice(
            amount: node["Amount"].value(),
            currencyCode: node["CurrencyCode"].value(),
            formattedPrice: node["FormattedPrice"].value()
        )
    }
}


struct AmazonOfferSummary: XMLIndexerDeserializable {
    let lowestNewPrice: AmazonPrice
    let totalNew: Int
    let totalUsed: Int
    let totalCollectible: Int
    let totalRefurbished: Int
    
    static func deserialize(_ node: XMLIndexer) throws -> AmazonOfferSummary {
        return try AmazonOfferSummary(
            lowestNewPrice: node["LowestNewPrice"].value(),
            totalNew: node["TotalNew"].value(),
            totalUsed: node["TotalUsed"].value(),
            totalCollectible: node["TotalCollectible"].value(),
            totalRefurbished: node["TotalRefurbished"].value()
        )
    }
}


struct AmazonOfferListing: XMLIndexerDeserializable {
    let offerListingId: String
    let price: AmazonPrice
    let availability: String
//    let availabilityAttributes: AmazonAvailabilityAttributes
    let isEligibleForSuperSaverShipping: Bool
    let isEligibleForPrime: Bool

    static func deserialize(_ node: XMLIndexer) throws -> AmazonOfferListing {
        return try AmazonOfferListing(
            offerListingId: node["OfferListingId"].value(),
            price: node["Price"].value(),
            availability: node["Availability"].value(),
//            availabilityAttributes: node["AvailabilityAttributes"].value(),
            isEligibleForSuperSaverShipping: node["IsEligibleForSuperSaverShipping"].value(),
            isEligibleForPrime: node["IsEligibleForPrime"].value()
        )
    }
}


struct AmazonOffer: XMLIndexerDeserializable {
//    let offerAttributes: AmazonOfferAttributes
    let offerListing: AmazonOfferListing

    static func deserialize(_ node: XMLIndexer) throws -> AmazonOffer {
        return try AmazonOffer(
            offerListing: node["OfferListing"].value()
        )
    }
}


struct AmazonItem: XMLIndexerDeserializable {
    let asin: String//?
    let parentAsin: String//?
    let smallImage: AmazonImage//?
    let mediumImage: AmazonImage//?
    let largeImage: AmazonImage//?
    let variants: [AmazonVariant]
    let offerSummary: AmazonOfferSummary
    let offers: [AmazonOffer]

    static func deserialize(_ node: XMLIndexer) throws -> AmazonItem {
        return try AmazonItem(
            asin: node["ASIN"].value(),
            parentAsin: node["ParentASIN"].value(),
            smallImage: node["SmallImage"].value(),
            mediumImage: node["MediumImage"].value(),
            largeImage: node["LargeImage"].value(),
            variants: node["ImageSets"]["ImageSet"].value(),
            offerSummary: node["OfferSummary"].value(),
            offers: node["Offers"]["Offer"].value()
        )
    }
}


class AmazonParserModel {
    
    func xmlDataFromHardcodedFile() -> Data? {
        guard let hardcodedPath = Bundle.main.path(forResource: "amazonResponse", ofType:"txt"),
          let hardcodedData = try? Data(contentsOf: URL(fileURLWithPath: hardcodedPath)) else {
            return nil
        }
        return hardcodedData
    }
    
    func xmlString(from data: Data) -> String? {
        let xmlString = String(data: data, encoding: .utf8)
        return xmlString
    }

    func hardcodedParse() {
        guard let xmlData = xmlDataFromHardcodedFile() else {
            print("GMK no xmlData")
            return
        }
        let xml = SWXMLHash.parse(xmlData)
        if let items: [AmazonItem] = try? xml["ItemSearchResponse"]["Items"]["Item"].value() {
            print("GMK xml:\(xml)")
            print("GMK items:\(items)")
        } else {
            print("GMK extracting items array failed")
        }
    }
    
}
