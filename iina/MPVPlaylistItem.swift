//
//  MPVPlaylistItem.swift
//  iina
//
//  Created by lhc on 23/8/16.
//  Copyright © 2016 lhc. All rights reserved.
//

import Cocoa

fileprivate let genericFileIcon = NSWorkspace.shared.icon(forFileType: NSFileTypeForHFSTypeCode(OSType(kGenericDocumentIcon)))

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

    // initialize cover art with generic artwork image (QuickLook)
    self.artworkImage = #imageLiteral(resourceName: "generic-artwork")

    if (self.isNetworkResource != true) {
        // lookup document icon for file on disk
        let fileIcon = NSWorkspace.shared.icon(forFile: filename)

        // ensure document icon is not default / generic
        if (fileIcon.tiffRepresentation?.md5 != genericFileIcon.tiffRepresentation?.md5) {
            // replace generic artwork image with file type icon
            self.artworkImage = fileIcon
        }
    }
  }
}
