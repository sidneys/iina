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

// MARK: PlaylistWindow (NSWindow subclass)
class PlaylistWindow: NSWindow, NSWindowDelegate {

  weak private var playerCore: PlayerCore!
  // private var wrapperView: NSVisualEffectView?

  init(playerCore: PlayerCore, playlistView: NSView) {
    // Store player reference
    self.playerCore = playerCore

    // Lookup main window containing the player
    let playerWindow = self.playerCore.mainWindow.window

    // Get relative window position/size, then calculate absolute window position/size
    let positionRelative = playerWindow?.convertFromScreen(playlistView.frame)
    let x = ((positionRelative?.origin.x)! * -1) + (playerWindow?.frame.size.width)! - playlistView.frame.size.width
    let y = (positionRelative?.origin.y)! * -1
    let width = playlistView.bounds.width
    let height = playlistView.bounds.height
    let positionAbsolute = NSRect(x: x, y:y, width: width, height: height)

    // Init window
    super.init(contentRect:positionAbsolute, styleMask: [.fullSizeContentView, .titled, .resizable], backing: .buffered, defer: false)

    // Set delegate
    self.delegate = self

    // Configure window options
    self.title = WindowTitle
    self.styleMask = [.fullSizeContentView, .titled, .resizable, .closable]
    self.initialFirstResponder = nil
    self.level = (playerWindow?.level)!
    self.isMovableByWindowBackground = true
    self.appearance = playerWindow?.appearance
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .visible
    self.isOpaque = true
    self.makeKeyAndOrderFront(nil)

    // Create translucent wrapper view and set as contentView
    let wrapperView = NSVisualEffectView(frame: positionAbsolute)
    wrapperView.material = playerCore.mainWindow.sideBarView.material
    wrapperView.appearance = playerCore.mainWindow.sideBarView.appearance
    wrapperView.blendingMode = .behindWindow
    wrapperView.state = .active
    self.contentView = wrapperView

    // Restore window position/size, if previously saved
    restorePosition()

    // Handle Event: .iinaMainWindowClosed
    NotificationCenter.default.addObserver(forName: .iinaMainWindowClosed, object: playerCore, queue: .main) { _ in
      self.performClose(nil)
    }
  }

  // MARK: Private methods

  // Store window position, size
  private func storePosition() {
    let data = NSKeyedArchiver.archivedData(withRootObject: self.frame)
    UserDefaults.standard.set(data, forKey: WindowFrameAutosaveName)
  }

  // Restore window position, size
  private func restorePosition() {
    guard let data = UserDefaults.standard.data(forKey: WindowFrameAutosaveName),
      let frame = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSRect else { return }

    self.setFrame(frame, display: true)
  }

  // MARK: Public methods

  // Set window, contentView appearance and material
  public func setAppearance(appearance: NSAppearance?, material: NSVisualEffectView.Material) {
    self.appearance = appearance

    (self.contentView as! NSVisualEffectView).material = material
    (self.contentView as! NSVisualEffectView).appearance = appearance
  }

  // MARK: Delegate methods

  // windowWillMiniaturize
  func windowWillMiniaturize(_ notification: Notification) {
    storePosition()
  }

  // windowWillClose
  func windowWillClose(_ notification: Notification) {
    storePosition()
  }
}

// MARK: PlaylistWindowController (NSWindowController subclass)
class PlaylistWindowController: NSWindowController {

  convenience init(playerCore: PlayerCore, playlistView: NSView) {
    // Remove playlist view from its parent view
    playlistView.removeFromSuperview()

    // Create playlist window
    let playlistWindow = PlaylistWindow(playerCore: playerCore, playlistView: playlistView)

    // Add playlist view to new parent view inside new window
    playlistWindow.contentView?.addSubview(playlistView)

    // Init window controller
    self.init(window: playlistWindow)

    // Configure window controller options
    self.shouldCascadeWindows = false

    // update playlist view constraints
    Utility.quickConstraints(["H:|[v]|", "V:|[v]|"], ["v": playlistView])
  }
}
