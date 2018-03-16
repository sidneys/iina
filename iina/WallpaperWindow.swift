//
//  WallpaperWindow.swift
//  iina
//
//  Created by sidneys on 14.03.18.
//  Copyright © 2018 lhc. All rights reserved.
//

import Cocoa

class WallpaperWindow: NSWindow {

    weak private var player: PlayerCore!

    init(player: PlayerCore) {
      // retain player reference
      self.player = player

      let mainWindow = player.mainWindow!

      // MARK: Position & Size
      // lookup NSScreen containing video window, use its rectangle as wallpaper-size target frame
      let windowRectangle = mainWindow.window?.frame
      let screenContainingWindow = (NSScreen.screens.filter{$0.frame.contains(windowRectangle!)})[0]
      let targetRectangle = screenContainingWindow.frame

      // MARK: Super
      super.init(contentRect: targetRectangle, styleMask: [.fullSizeContentView], backing: .buffered, defer: false)

      // MARK: Appearance
      self.level = NSWindow.Level(Int(CGWindowLevelForKey(CGWindowLevelKey.desktopWindow)))
      self.initialFirstResponder = nil
      self.titlebarAppearsTransparent = true
      self.titleVisibility = .hidden
      self.isOpaque = true
      self.makeKeyAndOrderFront(nil)

      // MARK: Setup Content View
      // move videoView from mainWindow to wallpaper window
      mainWindow.videoView.removeFromSuperview()
      self.contentView?.addSubview(mainWindow.videoView, positioned: .below, relativeTo: nil)

      // update videoView constraints
      Utility.quickConstraints(["H:|[v]|", "V:|[v]|"], ["v": mainWindow.videoView])
  
      // update window aspect ratio
      let (dw, dh) = player.videoSizeForDisplay
      if self.aspectRatio == .zero {
        let size = NSSize(width: dw, height: dh)
        self.aspectRatio = size
      }

      // MARK: Notifications
      // close window when mainWindow closes
      NotificationCenter.default.addObserver(forName: .iinaMainWindowClosed, object: player, queue: .main) { _ in
          self.orderOut(self)
      }
    }

  override func orderOut(_ sender: Any?) {
    let mainWindow = player.mainWindow!

    // MARK: Setup Content View
    // move videoView from wallpaper window back to mainWindow
    let mainWindowContentView = mainWindow.window!.contentView
    mainWindow.videoView.removeFromSuperview()
    mainWindowContentView?.addSubview(mainWindow.videoView, positioned: .below, relativeTo: nil)

    // update videoView constraints
    ([.top, .bottom, .left, .right] as [NSLayoutConstraint.Attribute]).forEach { attr in
      mainWindow.videoViewConstraints[attr] = NSLayoutConstraint(item: mainWindow.videoView, attribute: attr, relatedBy: .equal,
                                                                 toItem: mainWindowContentView, attribute: attr, multiplier: 1, constant: 0)
      mainWindow.videoViewConstraints[attr]!.isActive = true
    }

    // MARK: Super
    super.orderOut(sender)
  }
}

