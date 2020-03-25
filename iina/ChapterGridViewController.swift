//
//  ChapterGridViewController.swift
//  iina
//
//  Created by sidneys on 24.03.20.
//  Copyright © 2020 lhc. All rights reserved.
//

import Cocoa

fileprivate let itemSize = NSSize(width: 220, height: 150)
fileprivate let thumbnailSize = NSSize(width: 220, height: 125)
fileprivate let labelSize = NSSize(width: 220, height: 20)


// MARK: - NSViewController Subclass

class ChapterGridViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout, ChapterViewDelegate {
  var player: PlayerCore!

  // Init: NSViewController

  required init?(coder: NSCoder) {
    fatalError()
  }

  init(player: PlayerCore) {
    // retain player reference
    self.player = player

    // Call Super
    super.init(nibName: nil, bundle: nil)
  }

  override func loadView() {
    // Create WrapperView (background blurred)
    let wrapperView = NSVisualEffectView(frame: self.player.mainWindow.videoView.frame)
    if #available(OSX 10.14, *) {
      wrapperView.material = .hudWindow
    } else {
      wrapperView.material = .dark
    }
    wrapperView.blendingMode = .withinWindow
    wrapperView.state = .active

    // Set WrapperView as root View
    self.view = wrapperView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Create CollectionView
    let layout = NSCollectionViewFlowLayout()
    layout.itemSize = itemSize
    layout.sectionInset = NSEdgeInsets(top: 48, left: 32, bottom: 64, right: 32)
    layout.minimumInteritemSpacing = 4
    layout.minimumLineSpacing = 16

    let collectionView = ChapterCollectionView()
    collectionView.player = self.player
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.collectionViewLayout = layout
    collectionView.allowsMultipleSelection = false
    collectionView.backgroundColors = [.clear]
    collectionView.isSelectable = true
    collectionView.register(
      ChapterItem.self,
      forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChapterItem")
    )

    // Create ScrollView
    let scrollView = NSScrollView()
    scrollView.frame = self.view.bounds
    scrollView.documentView = collectionView

    // Enable ScrollView auto-resize
    scrollView.autoresizingMask = [.width, .height]

    // Add ScrollView to root View
    self.view.addSubview(scrollView)

    // Lookup contentView of main video player window
    guard let contentView = self.player.mainWindow.window?.contentView else { return }

    // Add Root View to contentView
    contentView.addSubview(self.view, positioned: .above, relativeTo: self.player.mainWindow.videoView)

    // Enable Root View autoresize
    self.view.translatesAutoresizingMaskIntoConstraints = false
    self.view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
    self.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
    self.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    self.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

    // Add to responde chain
    self.player.mainWindow.window?.makeFirstResponder(self.view)

    // Status
    Logger.log("Chapter Grid created")
  }

  // Init: NSCollectionViewDataSource

  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.player.info.chapters.count
  }

  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
    let cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChapterItem"), for: indexPath) as! ChapterItem

    cell.chapter = self.player.info.chapters[indexPath.item]
    (cell.view as! ChapterView).delegate = self

    return cell
  }

  // Convenience Method: Show
  public func showView() {
    // Unhide
    self.view.isHidden = false

    // Fade-In
    if #available(OSX 10.12, *) {
      self.view.alphaValue = 0
      NSAnimationContext.runAnimationGroup({ (context) in
        context.duration = 1.0
        self.view.animator().alphaValue = 1
      })
    }

    // Status
    Logger.log("Chapter Grid shown")
  }

  // Convenience Method: Hide
  public func hideView() {
    // Fade-Out, Hide
    if #available(OSX 10.12, *) {
      NSAnimationContext.runAnimationGroup({ (context) in
        context.duration = 1.5
        self.view.animator().alphaValue = 0
      }, completionHandler: { () -> Void in
        self.view.isHidden = true
      })
    } else {
      self.view.isHidden = true
    }

    // Status
    Logger.log("Chapter Grid hidden")
  }

  // Convenience Method: Toggle
  public func toggleView() {
    if !self.isViewLoaded || self.view.isHidden {
       showView()
     } else {
       hideView()
     }
  }

  // Protocol: Click
  func didClickChapter(_ chapterIndex: Int) {
    guard self.player != nil else { return }

    // Jump to Chapter
    self.player.playChapter(chapterIndex)

    // Hide View
    self.hideView()

    // Status
    Logger.log("Chapter Grid index selected: \(String(chapterIndex)))")
  }
}


// MARK: - NSCollectionView Subclass

private class ChapterCollectionView: NSCollectionView {
  var player: PlayerCore!

  override func draw(_ dirtyRect: NSRect) {
      super.draw(dirtyRect)
  }
}


// MARK: - NSCollectionViewItem Subclass

private class ChapterItem: NSCollectionViewItem {
  private var chapterLabel: String = ""
  private var chapterThumbnail: NSImage? = nil

  var chapter: MPVChapter? {
    didSet {
      guard isViewLoaded else { return }

      // Set Cell Label
      if let chapter = chapter {
        if !chapter.title.isEmpty {
          chapterLabel = chapter.title
        }

        // Set Cell Image
        if let player = (self.collectionView as! ChapterCollectionView).player, player.info.thumbnailsReady, let tb = player.info.getThumbnail(forSecond: chapter.time.second) {
          chapterThumbnail = tb.image
        }
      }

      (self.view as! ChapterView).label?.stringValue = chapterLabel
      (self.view as! ChapterView).thumbnail?.image = chapterThumbnail
    }
  }

  override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName:nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    // Instance NSView Subclass
    self.view = ChapterView(frame: NSZeroRect)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.wantsLayer = true
  }
}


// MARK: - NSView Protocol

protocol ChapterViewDelegate: class {
  func didClickChapter(_ chapterIndex: Int)
}


// MARK: - NSView Subclass

private class ChapterView: NSView {
  var label: NSTextField?
  var thumbnail: ChapterImageView?

  weak var delegate: ChapterViewDelegate?

  override init(frame frameRect: NSRect) {
    super.init(frame: NSRect(origin: frameRect.origin, size: itemSize))

    let textField = NSTextField(frame: NSRect(origin: .zero, size: labelSize))
    textField.backgroundColor = NSColor(white: 0, alpha: 0.10)
    textField.isEditable = false
    textField.isBordered = false
    textField.isBezeled = false
    textField.alignment = .center
    textField.usesSingleLineMode = false
    textField.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .thin)
    self.addSubview(textField)
    self.label = textField

    let imageView = ChapterImageView(frame: NSRect(origin: NSPoint(x: 0, y: itemSize.height - thumbnailSize.height), size: thumbnailSize))
    imageView.imageScaling = .scaleProportionallyDown
    imageView.imageAlignment = .alignTopLeft
    self.addSubview(imageView)
    self.thumbnail = imageView
  }

  override func mouseDown(with event: NSEvent) {
    // Lookup Collection View
    let collectionView = self.superview as! NSCollectionView

    // Lookup clicked item index
    guard let index = collectionView.subviews.firstIndex(of: self) else { return }

    // Forward clicked item index
    if let delegate = self.delegate {
      delegate.didClickChapter(index)
    }
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
}


// MARK: - NSImageView

private class ChapterImageView: NSImageView {
  override var image: NSImage? {
    set {
      self.layer = CALayer()
      self.layer?.contentsGravity = CALayerContentsGravity.resizeAspectFill
      self.layer?.contents = newValue
      self.wantsLayer = true
      super.image = newValue
    }

    get {
      return super.image
    }
  }
}
