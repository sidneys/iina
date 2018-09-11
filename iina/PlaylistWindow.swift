//
//  PlaylistWindow.swift
//  iina
//
//  Created by sidneys on 14.03.18.
//  Copyright © 2018 lhc. All rights reserved.
//

import Cocoa


fileprivate let WindowTitle = "Playlist"
fileprivate let WindowFrameAutosaveName = "IINAPlaylist"

class PlaylistWindow: NSWindow, NSWindowDelegate {
  
  weak private var player: PlayerCore!

  var wrapperView: NSVisualEffectView?

  init(player: PlayerCore, view: NSView) {
    // set player reference
    self.player = player

    // MARK: Initial Position & Size
    // get playlist views' container window
    let window = self.player.mainWindow.window

    // get views' relative coordinates and derive its absolute coordinates
    let relativeRectangle = window?.convertFromScreen(view.frame)

    // calculate target coordinates on top of old window
    let x = ((relativeRectangle?.origin.x)! * -1) + (window?.frame.size.width)! - view.frame.size.width
    let y = (relativeRectangle?.origin.y)! * -1
    let width = view.bounds.width
    let height = view.bounds.height

    // generate target coordinates
    let targetRectangle = NSRect(x: x, y:y, width: width, height: height)

    // MARK: Super
    super.init(contentRect:targetRectangle, styleMask: [.fullSizeContentView, .titled, .resizable], backing: .buffered, defer: false)

    // set delegate
    self.delegate = self

    // MARK: windowController
    self.windowController?.shouldCascadeWindows = false

    // MARK: Appearance
    self.title = WindowTitle
    self.styleMask = [.fullSizeContentView, .titled, .resizable, .closable]
    self.initialFirstResponder = nil
    self.level = (window?.level)!
    self.isMovableByWindowBackground = true
    self.appearance = window?.appearance
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .visible
    self.isOpaque = true
    self.makeKeyAndOrderFront(nil)

    // MARK: Restore Position & Size
    restoreFrame()

    // MARK: contentView / Wrapper
    wrapperView = NSVisualEffectView(frame: targetRectangle)
    wrapperView?.material = player.mainWindow.sideBarView.material
    wrapperView?.appearance = player.mainWindow.sideBarView.appearance
    wrapperView?.blendingMode = .behindWindow
    wrapperView?.state = .active
    self.contentView = wrapperView

    // MARK: Notifications / Events
    // detect when mainWindow closes
    NotificationCenter.default.addObserver(forName: .iinaMainWindowClosed, object: player, queue: .main) { _ in
      self.performClose(nil)
    }
  }

  func storeFrame() {
    let data = NSKeyedArchiver.archivedData(withRootObject: self.frame)
    UserDefaults.standard.set(data, forKey: WindowFrameAutosaveName)
  }

  func restoreFrame() {
    guard let data = UserDefaults.standard.data(forKey: WindowFrameAutosaveName),
      let frame = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSRect else { return }

    self.setFrame(frame, display: true)
  }

  func windowWillMiniaturize(_ notification: Notification) {
    storeFrame()
  }

  func windowWillClose(_ notification: Notification) {
    storeFrame()
  }
}
