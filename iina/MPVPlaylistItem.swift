//
//  MPVPlaylistItem.swift
//  iina
//
//  Created by lhc on 23/8/16.
//  Copyright © 2016 lhc. All rights reserved.
//

import Cocoa
import AVFoundation

fileprivate let genericArtwork = #imageLiteral(resourceName: "generic-artwork") as NSImage

class MPVPlaylistItem: NSObject {

  /** Actually this is the path. Use `filename` to conform mpv API's naming. */
  var filename: String

  /** Title or the real filename */
  var filenameForDisplay: String {
    return title ?? (isNetworkResource ? filename : NSString(string: filename).lastPathComponent)
  }

  var isCurrent: Bool
  var isPlaying: Bool
  var isNetworkResource: Bool
  var isYoutubeResource: Bool

  var title: String?

  var artworkImage: NSImage?

  init(filename: String, isCurrent: Bool, isPlaying: Bool, title: String?) {
    self.filename = filename
    self.isCurrent = isCurrent
    self.isPlaying = isPlaying
    self.title = title
    self.isNetworkResource = Regex.url.matches(filename)
    self.isYoutubeResource = Regex.youtube.matches(filename)
  }



  /**
   Fetches Cover Artwork metadata images for playlist item. Loads images for local files via AVFoundation API.
   Downloads YouTube thumbnails via the public API. Falls back to generic icon.

   - parameters:
     - callback: Completion handler with `NSImage` object providing the fetched data.
   */
  func fetchArtwork(callback: @escaping (NSImage) -> Void) {
    let subsystem = Logger.Subsystem(rawValue: "Artwork Fetcher")

    // Check if Artwork already set
    guard (self.artworkImage == nil) else {
      // Callback
      callback(self.artworkImage!)

      return
    }

    // Set Artwork Fallback
    self.artworkImage = genericArtwork

    /** Resource Type: Local Filesystem  */
    guard (self.isNetworkResource) else {
      let asset = AVAsset(url: URL.init(fileURLWithPath: self.filename))

      // Loading Metadata (Async)
      asset.loadValuesAsynchronously(forKeys: ["commonMetadata"], completionHandler: {
        var error: NSError? = nil
        let status = asset.statusOfValue(forKey: "commonMetadata", error: &error)

        // Result (Async)
        switch status {
          case .loaded:
            Logger.log("Loaded", level: .debug, subsystem: subsystem)
            let metadataItemList = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common)

            // Query for iTunes, ID3 Artworks
            if let metadataItem = metadataItemList.first, metadataItem.keySpace == .id3 || metadataItem.keySpace == .iTunes {
              if let imageData = metadataItem.dataValue, let image = NSImage(data: imageData) {
                // Set Artwork (from Metadata)
                self.artworkImage = image
              }

              Logger.log("Metadata: \(metadataItem.description)", level: .verbose, subsystem: subsystem)
            }
          case .failed:
            Logger.log("Failed (\(error?.description ?? "Reason Unknown"))", level: .error, subsystem: subsystem)
          case .cancelled:
            Logger.log("Cancelled", level: .debug, subsystem: subsystem)
          default:
            Logger.log("Status: \(status.rawValue)", level: .debug, subsystem: subsystem)
        }

        // Callback
        callback(self.artworkImage!)
      })

      return
    }

    /** Resource Type: YouTube URL  */
    guard (!self.isYoutubeResource) else {
      // Parse YouTube video id from URL
      if let id = Regex.youtube.captures(in: filename)[at: 1] {
        Logger.log("YouTube Video Id: \(id)", level: .debug, subsystem: subsystem)
        // Query youtube.com for thumbnails
        let image = NSImage(byReferencing: URL(string: "https://img.youtube.com/vi/\(id)/maxresdefault.jpg")!)
        // Set Artwork (from Thumbnail)
        self.artworkImage = image
      }

      // Callback
      callback(self.artworkImage!)

      return
    }

    /** Resource Type: Other */
    callback(self.artworkImage!)
  }
}
