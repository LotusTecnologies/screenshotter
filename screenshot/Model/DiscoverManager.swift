//
//  DiscoverManager.swift
//  screenshot
//
//  Created by Jonathan Rose on 6/27/18.
//  Copyright © 2018 crazeapp. All rights reserved.
//

import Foundation


class DiscoverManager {
    class DownloadItem {
        
    }
    func didAdd(_ item:DisplayingDiscoverItem){
        // 1)  DisplayingDiscoverItem -> GarbageDiscoverItem
        // create screenshot in other context...
        // 2) while DisplayingDiscoverItem.count < 3 { QueuedDiscoverItem(ordered by best recombee) -> DisplayingDiscoverItem }
        // 3) while QueuedDiscoverItem.count + downloadingItem.count < 50 { download more from reserves }
        // 4) send recombee rating = 0.5 completion { request more recombee }
    }
    func didSkip(_ item:DisplayingDiscoverItem) {
        // 1)  DisplayingDiscoverItem -> GarbageDiscoverItem
        // nothing to do with other context
        // 2) while DisplayingDiscoverItem.count < 3 { QueuedDiscoverItem(ordered by best recombee) -> DisplayingDiscoverItem }
        // 3) while QueuedDiscoverItem.count + downloadingItem.count < 50 { download more from reserves }
        // 4) send recombee rating = -0.5 completion { request more recombee }
    }
    func discoverViewDidAppear() {
        // while DisplayingDiscoverItem.count < 3 { QueuedDiscoverItem(ordered by best recombee) -> DisplayingDiscoverItem }
        // 3) while QueuedDiscoverItem.count + downloadingItem.count < 50 { download more from reserves }
    }
    
    private func recombeeRecommendation(_ recommendations:[String]){
        // for each recommendation {
        // if recomend is GarbageDiscoverItem { if can redisplay{ move to downloading }else{ request more recombee }
        // if recommend is displaying { request more combee }
        // if recommend is queued { mark as recombee recommneded }
        // if recommend is downloading { mark as recombee recommend }
        // else { start downloading AND mark as recombee recommened }
    }
    private func downloadFinished(_ item:DownloadItem){
        // downloadingItem -> QueuedDiscoverItem
        // (needed if previously didn't have internet) DisplayingDiscoverItem.count < 3 { QueuedDiscoverItem(ordered by best recombee) -> DisplayingDiscoverItem }
        // while QueuedDiscoverItem.count + downloadingItem.count < 50 { download more from reserves }

    }
    
    
}
