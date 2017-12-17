//
//  ScreenshotHelper.swift
//  screenshot
//
//  Created by Jacob Relkin on 12/14/17.
//  Copyright © 2017 crazeapp. All rights reserved.
//

fileprivate let S3BaseURL = "https://s3.amazonaws.com/s3-file-store/generated"
fileprivate let ShortenedBaseURL = "https://img.screenshopit.com"

extension Screenshot {
    var shortenedUploadedImageURL: String? {
        return uploadedImageURL?.replacingOccurrences(of: S3BaseURL, with: ShortenedBaseURL)
    }
}
