//
//  ProductStructures.swift
//  screenshot
//
//  Created by Corey Werner on 5/16/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import UIKit

class StructuredProduct: NSObject {
    let product: Product
    private(set) var structuredColorVariants: [StructuredColorVariant]?
    private(set) var colors: [String]?
    private(set) var sizes: [String]?
    private(set) var isAvailable = false
    
    init(_ product: Product) {
        self.product = product
        super.init()
        
        guard let variants = product.availableVariants?.allObjects as? [Variant], !variants.isEmpty else {
            return
        }
        
        isAvailable = true
        
        var structuredColorVariantsDict: [String : StructuredColorVariant] = [:]
        var colors: Set<String> = Set()
        var sizes: Set<String> = Set()
        var imageURLDict: [String: URL] = [:]
        
        for variant in variants {
            guard let color = variant.color,
                !hasDuplicateVariantAsNA(variants: variants, currentVariant: variant)
                else {
                    continue
            }
            
            colors.insert(color)
            let structuredColorVariant = structuredColorVariantsDict[color] ?? StructuredColorVariant(color: color)
            
            structuredColorVariant.variantSet.insert(variant)
            
            if let size = variant.size {
                sizes.insert(size)
                structuredColorVariant.sizeSet.insert(size)
            }
            
            structuredColorVariantsDict[color] = structuredColorVariant
            
            if imageURLDict[color] == nil, let imageURL = variant.parsedImageURLs().first {
                imageURLDict[color] = imageURL
            }
        }
        
        if !structuredColorVariantsDict.isEmpty {
            structuredColorVariants = Array(structuredColorVariantsDict.values)
        }
        
        if !colors.isEmpty {
            self.colors = colors.sorted()
        }
        
        if !sizes.isEmpty {
            let sortedSizes = ["X-Small", "Small", "Medium", "Large", "X-Large"]
            
            self.sizes = sizes.sorted(by: { (a, b) -> Bool in
                let aIndex = (sortedSizes.index(of: a) ?? Int.max)
                let bIndex = (sortedSizes.index(of: b) ?? Int.max)
                
                if aIndex == Int.max && bIndex == Int.max {
                    return a.localizedStandardCompare(b) == .orderedAscending
                }
                
                return aIndex < bIndex
            })
        }
        
        if !imageURLDict.isEmpty {
            self.imageURLDict = imageURLDict
        }
    }
    
    // MARK: Variant
    
    /// If a variant color is NA, check if it's image exists in another variant
    private func hasDuplicateVariantAsNA(variants: [Variant], currentVariant: Variant) -> Bool {
        guard let currentColor = currentVariant.color else {
            return false
        }
        
        var hasDuplicateVariantAsNA = false
        
        func isColorNA(_ color: String) -> Bool {
            return ["N/A", "NA"].contains(color.uppercased())
        }
        
        if isColorNA(currentColor), let imageURL = currentVariant.parsedImageURLs().first {
            for variant in variants {
                guard let color2 = variant.color, !isColorNA(color2) else {
                    continue
                }
                
                if variant.parsedImageURLs().first == imageURL {
                    hasDuplicateVariantAsNA = true
                    break
                }
            }
        }
        
        return hasDuplicateVariantAsNA
    }
    
    func structuredColorVariant(forColor color: String?) -> StructuredColorVariant? {
        return structuredColorVariants?.first { structuredColorVariant -> Bool in
            return structuredColorVariant.color == color
        }
    }
    
    func variant(forColor color: String?, size: String?) -> Variant? {
        return structuredColorVariant(forColor: color)?.variant(forSize: size)
    }
    
    func subtractingSizes(of structuredColorVariant: StructuredColorVariant) -> [String] {
        return Array(Set(sizes ?? []).subtracting(structuredColorVariant.sizes))
    }
    
    // MARK: Image
    
    private var imageURLDict: [String: URL]?
    
    func imageURL(forColor color: String?) -> URL? {
        return imageURLDict?[color ?? ""]
    }
    
    var imageURLs: [URL]? {
        return imageURLDict?.sorted { $0.key < $1.key }.map { $0.value }
    }
}

class StructuredColorVariant: NSObject {
    let color: String?
    
    fileprivate var sizeSet: Set<String> = Set()
    var sizes: [String] {
        return Array(sizeSet)
    }
    
    fileprivate var variantSet: Set<Variant> = Set()
    var variants: [Variant] {
        return Array(variantSet)
    }
    
    init(color: String?) {
        self.color = color
        super.init()
    }
    
    func variant(forSize size: String?) -> Variant? {
        return variants.first { variant -> Bool in
            return variant.size == size
        }
    }
}
