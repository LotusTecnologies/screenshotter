//
//  SearchCategoryDataType.swift
//  Screenshop
//
//  Created by Corey Werner on 8/6/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation

struct SearchRoot: Encodable {
    let men: [SearchBranch]
    let women: [SearchBranch]
}

struct SearchBranch: Encodable {
    let category: SearchCategory
    let image: String?
    let subcategories: [SearchBranch]?
    
    init(category: SearchCategory, image: String?, subcategories: [SearchBranch]?) {
        self.category = category
        self.image = image
        self.subcategories = subcategories
    }
    
    init(_ category: SearchCategory) {
        self.init(category: category, image: nil, subcategories: nil)
    }
}

enum SearchClass: String {
    case men
    case women
    
    init?(intValue: Int) {
        switch intValue {
        case 0:  self = .men
        case 1:  self = .women
        default: return nil
        }
    }
    
    var intValue: Int {
        switch self {
        case .men:   return 0
        case .women: return 1
        }
    }
    
    var possessiveTitle: String {
        switch self {
        case .men:   return "search.class.men".localized
        case .women: return "search.class.women".localized
        }
    }
}

enum SearchCategory: String, Encodable {
    case accessories
    case active
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
    case dresses
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
    case shoes
    case shorts
    case skirts
    case sleepwear
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
    case swimwear
    case tankTops
    case teesAndTanks
    case tops
    case trackSuits
    case watches
    case wedges
    
    var title: String {
        switch self {
        case .accessories: return "search.category.accessories".localized
        case .active: return "search.category.active".localized
        case .belts: return "search.category.belts".localized
        case .bikinis: return "search.category.bikinis".localized
        case .blazers: return "search.category.blazers".localized
        case .blockHeels: return "search.category.blockHeels".localized
        case .blousesAndButtonUps: return "search.category.blousesAndButtonUps".localized
        case .bodySuits: return "search.category.bodySuits".localized
        case .bombers: return "search.category.bombers".localized
        case .booties: return "search.category.booties".localized
        case .boots: return "search.category.boots".localized
        case .bottoms: return "search.category.bottoms".localized
        case .casual: return "search.category.casual".localized
        case .coats: return "search.category.coats".localized
        case .cocktail: return "search.category.cocktail".localized
        case .coverUps: return "search.category.coverUps".localized
        case .cropTops: return "search.category.cropTops".localized
        case .denim: return "search.category.denim".localized
        case .dress: return "search.category.dress".localized
        case .dresses: return "search.category.dresses".localized
        case .dusterCoats: return "search.category.dusterCoats".localized
        case .flats: return "search.category.flats".localized
        case .gowns: return "search.category.gowns".localized
        case .graphicTees: return "search.category.graphicTees".localized
        case .hats: return "search.category.hats".localized
        case .highHeels: return "search.category.highHeels".localized
        case .hoodiesAndSweatshirts: return "search.category.hoodiesAndSweatshirts".localized
        case .jackets: return "search.category.jackets".localized
        case .jeans: return "search.category.jeans".localized
        case .jewelry: return "search.category.jewelry".localized
        case .leather: return "search.category.leather".localized
        case .leggings: return "search.category.leggings".localized
        case .lightweight: return "search.category.lightweight".localized
        case .loafers: return "search.category.loafers".localized
        case .longSleeves: return "search.category.longSleeves".localized
        case .lowHeels: return "search.category.lowHeels".localized
        case .maxis: return "search.category.maxis".localized
        case .midis: return "search.category.midis".localized
        case .minis: return "search.category.minis".localized
        case .offTheShoulder: return "search.category.offTheShoulder".localized
        case .onePieces: return "search.category.onePieces".localized
        case .onesies: return "search.category.onesies".localized
        case .overalls: return "search.category.overalls".localized
        case .pants: return "search.category.pants".localized
        case .parkas: return "search.category.parkas".localized
        case .polos: return "search.category.polos".localized
        case .puffers: return "search.category.puffers".localized
        case .sandals: return "search.category.sandals".localized
        case .scarves: return "search.category.scarves".localized
        case .sets: return "search.category.sets".localized
        case .shoes: return "search.category.shoes".localized
        case .shorts: return "search.category.shorts".localized
        case .skirts: return "search.category.skirts".localized
        case .sleepwear: return "search.category.sleepwear".localized
        case .slippers: return "search.category.slippers".localized
        case .sneakers: return "search.category.sneakers".localized
        case .sportsBras: return "search.category.sportsBras".localized
        case .strapless: return "search.category.strapless".localized
        case .suits: return "search.category.suits".localized
        case .sundresses: return "search.category.sundresses".localized
        case .sunglasses: return "search.category.sunglasses".localized
        case .sweaters: return "search.category.sweaters".localized
        case .sweatpants: return "search.category.sweatpants".localized
        case .sweats: return "search.category.sweats".localized
        case .swimwear: return "search.category.swimwear".localized
        case .tankTops: return "search.category.tankTops".localized
        case .teesAndTanks: return "search.category.teesAndTanks".localized
        case .tops: return "search.category.tops".localized
        case .trackSuits: return "search.category.trackSuits".localized
        case .watches: return "search.category.watches".localized
        case .wedges: return "search.category.wedges".localized
        }
    }
}

extension SearchClass {
    var dataSource: [SearchBranch] {
        switch self {
        case .men:
            return SearchClass.menDataSource
        case .women:
            return SearchClass.womenDataSource
        }
    }
    
    static private let menDataSource = [
        SearchBranch(category: .tops, image: nil, subcategories: [
            SearchBranch(.dress),
            SearchBranch(.casual),
            SearchBranch(.polos),
            SearchBranch(.teesAndTanks)
            ]),
        SearchBranch(category: .bottoms, image: nil, subcategories: [
            SearchBranch(.jeans),
            SearchBranch(.pants),
            SearchBranch(.shorts),
            SearchBranch(.sweatpants)
            ])
    ]
    
    static private let _menDataSource = DataSource<SearchCategory, SearchCategory>(data: [
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
    
    static private let womenDataSource = [
        SearchBranch(category: .tops, image: nil, subcategories: [
            SearchBranch(.blousesAndButtonUps),
            SearchBranch(.cropTops),
            SearchBranch(.bodySuits),
            SearchBranch(.graphicTees)
            ]),
        SearchBranch(category: .swimwear, image: nil, subcategories: [
            SearchBranch(.bikinis),
            SearchBranch(.onePieces),
            SearchBranch(.coverUps)
            ])
    ]
    
    static private let _womenDataSource = DataSource<SearchCategory, SearchCategory>(data: [
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
