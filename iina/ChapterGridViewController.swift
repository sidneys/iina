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


// MARK: - NSViewController

class ChapterGridViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {

  weak var player: PlayerCore!

  init(player: PlayerCore) {
    // retain player reference
    self.player = player

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  // Init: NSViewController

  override func loadView() {
    // Create WrapperView (blurred)
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
    layout.sectionInset = NSEdgeInsets(top: 32, left: 32, bottom: 64, right: 64)
    layout.minimumInteritemSpacing = 4
    layout.minimumLineSpacing = 16

    let collectionView = NSCollectionView()
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
    scrollView.documentView = collectionView
    scrollView.frame = self.view.frame

    // Add ScrollView to root View
    self.view.addSubview(scrollView)

    // Add root View to VideoView
    self.player.mainWindow.videoView.addSubview(self.view, positioned: .above, relativeTo: nil)
  }

  // Init: NSCollectionViewDataSource

  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.player.info.chapters.count
  }

  func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

    let cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ChapterItem"), for: indexPath) as! ChapterItem

    cell.player = self.player
    cell.chapter = self.player.info.chapters[indexPath.item]

    return cell
  }
}


// MARK: - NSCollectionViewItem

private class ChapterItem: NSCollectionViewItem {

  weak var player: PlayerCore!

  private var chapterLabel: String = ""
  private var chapterThumbnail: NSImage? = nil

  var chapter: MPVChapter? {
      didSet {
          guard isViewLoaded else { return }
          if let chapter = chapter {
            if !chapter.title.isEmpty {
              chapterLabel = chapter.title
            }

            if self.player.info.thumbnailsReady, let tb = self.player.info.getThumbnail(forSecond: chapter.time.second) {
              chapterThumbnail = tb.image
            }
          }

          (self.view as! ChapterView).label?.stringValue = chapterLabel
          (self.view as! ChapterView).thumbnail?.image = chapterThumbnail
      }
  }

  override func loadView() {
    self.view = ChapterView(frame: NSZeroRect)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.wantsLayer = true
  }
}


// MARK: - NSView

private class ChapterView: NSView {
  var label: NSTextField?
  var thumbnail: ChapterImageView?

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
