//
//  MPVPlaylistItem.swift
//  iina
//
//  Created by lhc on 23/8/16.
//  Copyright © 2016 lhc. All rights reserved.
//

import Cocoa

fileprivate let DefaultArtworkImage = #imageLiteral(resourceName: "generic-artwork") as NSImage
fileprivate let QuicklookThumbnailResolution = 512

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
   Fetches Cover Art images for playlist item.
   Loads images for local files via AVFoundation,
   Downloads YouTube thumbnails via the public API. Falls back to generic icon.

   - parameters:
     - callback: Completion handler with `NSImage` object providing the fetched data.
   */
  func fetchArtwork(callback: @escaping (NSImage) -> Void) {
    let subsystem = Logger.Subsystem(rawValue: "Artwork Fetcher")

    let fetchTask = FetcherTask(filename: self.filename)

    // Check if Artwork already set
    guard (self.artworkImage == nil) else {
      // Callback
      callback(self.artworkImage!)

      return
    }

    // Set artwork image default
    self.artworkImage = DefaultArtworkImage

//    let fileUrl = URL(fileURLWithPath: self.filename)
//
//    /** Resource Type: Filesystem  */
//      let quicklookImageSize = NSSize(width: QuicklookThumbnailResolution, height: QuicklookThumbnailResolution)
//      DispatchQueue.global(qos: .background).async {
//        if let quicklookImageRef = QLThumbnailImageCreate(nil,
//                                                          fileUrl as CFURL, quicklookImageSize as CGSize, [kQLThumbnailOptionIconModeKey: false] as CFDictionary) {
//          // Get QuickLook thumbnail
//          let quicklookImage = quicklookImageRef.takeUnretainedValue()
//          let image = NSImage(cgImage: quicklookImage, size: .zero)
//          // Set artwork image
//          self.artworkImage = image
//
//          Logger.log("QuickLook Thumbnail fetched", level: .verbose, subsystem: subsystem)
//        }
//        callback(self.artworkImage!)
//      }

//      if (!self.isNetworkResource) {
//      /** Resource Type: Filesystem  */
//      let asset = AVAsset(url: URL.init(fileURLWithPath: self.filename))
//
//      // Load metadata asynchronously
//      asset.loadValuesAsynchronously(forKeys: ["commonMetadata"], completionHandler: {
//        var error: NSError? = nil
//        let status = asset.statusOfValue(forKey: "commonMetadata", error: &error)
//
//        // Query file metadata
//        switch status {
//          case .loaded:
//            let metadataItemList = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common)
//
//            // Query artwork metadata
//            if let metadataItem = metadataItemList.first, metadataItem.keySpace == .id3 || metadataItem.keySpace == .iTunes {
//              // Get from metadata artwork image
//              let metadataImage = metadataItem.dataValue!
//              let image = NSImage(data: metadataImage)
//              // Set artwork
//              self.artworkImage = image
//
//              Logger.log("Metadata: \(metadataItem.description)", level: .verbose, subsystem: subsystem)
//            }
//
//            Logger.log("Metadata Artwork fetched", level: .debug, subsystem: subsystem)
//          default:
//            Logger.log("Metadata Artwork error (\(error?.description ?? "Reason Unknown"))", level: .error, subsystem: subsystem)
//        }
//
//        // Callback
//        callback(self.artworkImage!)
//      })
//
//      return
//    }

    // YouTube
    if (self.isYoutubeResource) {
      fetchTask.provider = .youtube
    }

    /** Resource Type: YouTube URL  */
    guard (!self.isYoutubeResource) else {
      // Parse YouTube video id from URL
      if let id = Regex.youtube.captures(in: filename)[at: 1] {
        Logger.log("YouTube Video Id: \(id)", level: .debug, subsystem: subsystem)
        // Query youtube.com for thumbnails
        let image = NSImage(byReferencing: URL(string: "https://img.youtube.com/vi/\(id)/maxresdefault.jpg")!)
        // Set Artwork (from Thumbnail)
    // QuickLook
    if (!self.isNetworkResource) {
      fetchTask.provider = .quicklook
    }

    // Execute
    fetchTask.execute() { result in
      switch result {
      case .error(let error):
        Logger.log("Error (\(error.debugDescription))", level: .error, subsystem: subsystem)
      case .success(let image):
        self.artworkImage = image
      }

      // Callback
      callback(self.artworkImage!)
    }
  }
}
