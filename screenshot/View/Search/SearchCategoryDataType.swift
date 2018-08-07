//
//  SearchCategoryDataType.swift
//  Screenshop
//
//  Created by Corey Werner on 8/6/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

enum SearchClass: Int {
    case men
    case women
    
    var possessiveTitle: String {
        switch self {
        case .men:
            return "search.category.gender.men".localized
        case .women:
            return "search.category.gender.women".localized
        }
    }
}

enum SearchCategory: String {
    case accessories
    case active
    case bottoms
    case dresses
    case jackets
    case shoes
    case sleepwear
    case swimwear
    case tops
}

enum SearchSubcategory: String {
    case belts
    case bikinis
    case blazers
    case blockHeels
    case blousesAndButtonUps
    case bodySuits
    case bombers
    case booties
    case boots
    case bottoms
    case casual
    case coats
    case cocktail
    case coverUps
    case cropTops
    case denim
    case dress
    case dusterCoats
    case flats
    case gowns
    case graphicTees
    case hats
    case highHeels
    case hoodiesAndSweatshirts
    case jackets
    case jeans
    case jewelry
    case leather
    case leggings
    case lightweight
    case loafers
    case longSleeves
    case lowHeels
    case maxis
    case midis
    case minis
    case offTheShoulder
    case onePieces
    case onesies
    case overalls
    case pants
    case parkas
    case polos
    case puffers
    case sandals
    case scarves
    case sets
    case shorts
    case skirts
    case slippers
    case sneakers
    case sportsBras
    case strapless
    case suits
    case sundresses
    case sunglasses
    case sweaters
    case sweatpants
    case sweats
    case tankTops
    case teesAndTanks
    case tops
    case trackSuits
    case watches
    case wedges
}

extension SearchClass {
    var dataSource: DataSource<SearchCategory, SearchSubcategory> {
        switch self {
        case .men:
            return SearchClass.menDataSource
        case .women:
            return SearchClass.womenDataSource
        }
    }
    
    static private let menDataSource = DataSource<SearchCategory, SearchSubcategory>(data: [
        (.tops, [
            .dress,
            .casual,
            .polos,
            .teesAndTanks,
            .graphicTees,
            .hoodiesAndSweatshirts,
            .sweaters
            ]
        ),
        (.bottoms, [
            .jeans,
            .pants,
            .shorts,
            .sweatpants
            ]
        ),
        (.jackets, [
            .bombers,
            .denim,
            .leather,
            .suits,
            .coats,
            .lightweight
            ]
        ),
        (.shoes, [
            .dress,
            .sneakers,
            .boots,
            .sandals
            ]
        ),
        (.swimwear, []),
        (.accessories, [
            .sunglasses,
            .watches,
            .hats,
            .belts,
            .jewelry,
            .scarves
            ]
        ),
        (.active, [
            .jackets,
            .tops,
            .bottoms
            ]
        ),
        (.sleepwear, [])
        ])
    
    static private let womenDataSource = DataSource<SearchCategory, SearchSubcategory>(data: [
        (.tops, [
            .blousesAndButtonUps,
            .cropTops,
            .bodySuits,
            .graphicTees,
            .strapless,
            .offTheShoulder,
            .longSleeves,
            .tankTops,
            .hoodiesAndSweatshirts,
            .sweaters
            ]
        ),
        (.swimwear, [
            .bikinis,
            .onePieces,
            .coverUps
            ]
        ),
        (.dresses, [
            .casual,
            .cocktail,
            .midis,
            .maxis,
            .minis,
            .sundresses,
            .gowns
            ]
        ),
        (.jackets, [
            .blazers,
            .bombers,
            .denim,
            .puffers,
            .leather,
            .parkas,
            .dusterCoats
            ]
        ),
        (.bottoms, [
            .jeans,
            .skirts,
            .shorts,
            .leggings,
            .sweatpants,
            .overalls,
            .pants
            ]
        ),
        (.shoes, [
            .booties,
            .boots,
            .highHeels,
            .lowHeels,
            .blockHeels,
            .wedges,
            .flats,
            .sneakers,
            .sandals,
            .slippers,
            .loafers
            ]
        ),
        (.active, [
            .sportsBras,
            .leggings,
            .shorts,
            .tops,
            .trackSuits,
            .sweats
            ]
        ),
        (.accessories, [
            .belts,
            .scarves,
            .sunglasses,
            .hats,
            .jewelry,
            .watches
            ]
        ),
        (.sleepwear, [
            .sets,
            .tops,
            .bottoms,
            .slippers,
            .onesies
            ]
        )
        ])
}
