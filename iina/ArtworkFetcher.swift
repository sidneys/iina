//
//  ArtworkFetcher.swift
//  iina
//
//  Created by sidneys on 06.05.19.
//  Copyright © 2019 lhc. All rights reserved.
//

import Cocoa
import AVFoundation

fileprivate let subsystem = Logger.Subsystem(rawValue: "ArtworkFetcher")

class ArtworkFetcher: NSObject {
  /**
   Fetch Cover Artwork for playlist items via AVFoundation.
   Load Metadata provided to macOS via AVFoundation.
   - parameters:
   - callback: (Optional) Completion handler with number of fetched items.
   */
  static func fetchArtwork(playerCore: PlayerCore, callback: @escaping () -> Void) {
    // Iterate playlist items
    for (index,item) in playerCore.info.playlist.enumerated() {

      // Local Resource

      if (item.isNetworkResource != true) {
        // Artwork
        let asset = AVAsset(url: URL.init(fileURLWithPath: item.filename))

        // Start loading metadata (async)
        asset.loadValuesAsynchronously(forKeys: ["commonMetadata"], completionHandler: {
          var error: NSError? = nil
          let status = asset.statusOfValue(forKey: "commonMetadata", error: &error)

          // Result of loading metadata (async)
          switch status {
          // unknown
          case .unknown:
            Logger.log("Unknown", level: .debug, subsystem: subsystem)
          // failed
          case .failed:
            Logger.log("Failed (\([error?.localizedDescription]))", level: .error, subsystem: subsystem)
          // cancelled
          case .cancelled:
            Logger.log("Cancelled", level: .debug, subsystem: subsystem)
          // loading
          case .loading:
            Logger.log("Loading", level: .debug, subsystem: subsystem)
          // loaded
          case .loaded:
            Logger.log("Loaded", level: .debug, subsystem: subsystem)
            let metadataItemList = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common)

            if let metadataItem = metadataItemList.first {
              // Query for iTunes, ID3 artwork types
              if (metadataItem.keySpace == AVMetadataKeySpace.id3) || (metadataItem.keySpace == AVMetadataKeySpace.iTunes) {
                if let imageData = metadataItem.dataValue, let image = NSImage(data: imageData) {
                  // Update artworkImage
                  item.artworkImage = image
                }
              }
            }

            // DEBUG
            Logger.log("Metadata: \(metadataItemList.description)", level: .verbose, subsystem: subsystem)
          }
          // Last Playlist Item
          if index == playerCore.info.playlist.endIndex-1 {
            DispatchQueue.main.async {
              callback()
            }
          }
        })
      } else {
        // Network Resource

        // YouTube
        if (item.isYoutubeResource) {
          if let videoUrl = URL(string: item.filename), let videoId = videoUrl.pathComponents.last {
            let thumbnailUrl = "https://img.youtube.com/vi/\(videoId)/0.jpg"
            item.artworkImage = NSImage(byReferencing: URL(string: thumbnailUrl)!)
          }
        }

        // Last Playlist Item
        if index == playerCore.info.playlist.endIndex-1 {
          DispatchQueue.main.async {
            callback()
          }
        }
      }
    }
  }
}
