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
        return try AmazonPrice(
            amount: node["Amount"].value(),
            currencyCode: node["CurrencyCode"].value(),
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
    let offerListing: [AmazonOfferListing]
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


struct AmazonItem: XMLIndexerDeserializable {
    let asin: String // required
    let parentAsin: String?
//    let errors: AmazonErrors?
    let detailPageURL: String?
//    let itemLinks: AmazonItemLinks?
    let salesRank: String?
    let smallImage: AmazonImage?
    let mediumImage: AmazonImage?
    let largeImage: AmazonImage?
    let imageSets: [AmazonImageSet]
//    let itemAttributes: AmazonItemAttributes?
//    let variationAttributes: [AmazonVariationAttribute] // maxOccurs=1
//    let relatedItems: AmazonRelatedItems?
//    let collections: AmazonCollections?
//    let subjects: [String] // maxOccurs=1
    let offerSummary: AmazonOfferSummary?
    let offers: [AmazonOffer]
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
            mediumImage: node["MediumImage"].value(),
            largeImage: node["LargeImage"].value(),
            imageSets: node["ImageSets"]["ImageSet"].value(),
//            itemAttributes: node["ItemAttributes"].value(),
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


struct AmazonErrorResponse: XMLIndexerDeserializable {
    let code: String?
    let message: String?
    
    static func deserialize(_ node: XMLIndexer) throws -> AmazonErrorResponse {
        return try AmazonErrorResponse(
            code: node["Code"].value(),
            message: node["Message"].value()
        )
    }
}

/*
<ItemSearchErrorResponse xmlns="http://ecs.amazonaws.com/doc/2005-10-05/">
    <Error>
        <Code>SignatureDoesNotMatch</Code>
        <Message>The request signature we calculated does not match the signature you provided. Check your AWS Secret Access Key and signing method. Consult the service documentation for details.</Message>
    </Error>
    <RequestID>f82a5f66-8ba9-4bfb-831c-b2fdc3b7ea64</RequestID>
 </ItemSearchErrorResponse>
*/

class AmazonParserModel {
    let xmlIndexer: XMLIndexer
    
    init(xmlData: Data) {
        xmlIndexer = SWXMLHash.parse(xmlData)
    }
    
    var error: AmazonErrorResponse? {
        if let error: AmazonErrorResponse = try? xmlIndexer["ItemSearchErrorResponse"]["Error"].value() {
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
