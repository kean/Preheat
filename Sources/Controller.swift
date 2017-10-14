// The MIT License (MIT)
//
// Copyright (c) 2017 Alexander Grebenyuk (github.com/kean).

import UIKit

/// Automates prefetching of content in a scroll views. After creating a preheat controller you should enable it by setting `enabled` property to `true`.
public class Controller<V> : NSObject where V: UIScrollView, V: Preheated {
    /// Gets called when the preheat window changes. Provides an array of index paths that were added and that were removed from the previous preheat window. Index paths are ordered by the distance to the viewport.
    public var handler: ((_ added: [IndexPath], _ removed: [IndexPath]) -> Void)?
    
    /// The view that the receiver was initialized with.
    public let view: V
    
    /// Currently preheated index paths.
    public private(set) var indexPaths = [IndexPath]()
    
    /// The proportion of the scroll view's width (or height for views with vertical orientation) used as a preheating window width (or height respectively).
    public var preheatRectSizeRatio: CGFloat = 1.0
    
    /// Determines how far the user needs to scroll from the current preheat window.
    public var updateRatio: CGFloat = 0.25
    
    /// Default value is false. When enabled the controller updates preheat index paths and starts reacting to scroll events. When disabled the controller removes all current preheating index paths and signals its delegate.
    public var enabled = false {
        didSet {
            if enabled {
                update()
            } else {
                previousOffset = nil
                updateIndexPaths([])
            }
        }
    }
    
    private var previousOffset: CGPoint?
    
    deinit {
        view.removeObserver(self, forKeyPath: "contentOffset", context: nil)
    }
    
    /// Initializes the receiver with a given view.
    public init(view: V) {
        self.view = view
        super.init()
        self.view.addObserver(self, forKeyPath: "contentOffset", options: [.new], context: nil)
    }
    
    /// Removes all index paths without signalling the delegate. Then updates preheat rect (if enabled).
    public func reset() {
        indexPaths.removeAll()
        previousOffset = nil
        if enabled {
            update()
        }
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if enabled {
            update()
        }
    }

    private func update() {
        guard shouldUpdatePreheatRect() else {
            return
        }
        let isScrollingForward = view.isScrollingForward(previousOffset)
        let preheatRect = view.preheatingRect(isScrollingForward, sizeRatio: preheatRectSizeRatio)
        let indexPaths = Set(view.indexPaths(in: preheatRect)).subtracting(view.indexPathsForVisibleItems)
        updateIndexPaths(indexPaths.sorted(by: { // sort in scroll direction
            if isScrollingForward {
                return $0.section < $1.section || $0.item < $1.item
            } else {
                return $0.section > $1.section || $0.item > $1.item
            }
        }))
        previousOffset = view.contentOffset
    }
    
    private func shouldUpdatePreheatRect() -> Bool {
        func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
            let dx = p2.x - p1.x, dy = p2.y - p1.y
            return sqrt((dx * dx) + (dy * dy))
        }
        guard let previousOffset = previousOffset else {
            return true
        }
        let margin = (view.orientation == .vertical ? view.bounds.height : view.bounds.width) * updateRatio
        return distance(view.contentOffset, previousOffset) > margin
    }
    
    private func updateIndexPaths(_ newIndexPaths: [IndexPath]) {
        let added = newIndexPaths.filter { !indexPaths.contains($0) }
        let removed = indexPaths.filter { !newIndexPaths.contains($0) }
        indexPaths = newIndexPaths
        handler?(added, removed)
    }
}

private extension Preheated where Self: UIScrollView {
    func preheatingRect(_ isScrollingForward: Bool, sizeRatio: CGFloat) -> CGRect {
        let viewport = CGRect(origin: contentOffset, size: bounds.size)
        switch orientation {
        case .vertical:
            let height = viewport.height * sizeRatio
            let y = isScrollingForward ? viewport.maxY : viewport.minY - height
            return CGRect(x: 0, y: y, width: viewport.width, height: height).integral
        case .horizontal:
            let width = viewport.width * sizeRatio
            let x = isScrollingForward ? viewport.maxX : viewport.minX - width
            return CGRect(x: x, y: 0, width: width, height: viewport.height).integral
        }
    }

    func isScrollingForward(_ previousOffset: CGPoint?) -> Bool {
        guard let previousOffset = previousOffset else {
            return true
        }
        switch orientation {
        case .vertical: return contentOffset.y >= previousOffset.y
        case .horizontal: return contentOffset.x >= previousOffset.x
        }
    }
}


public enum ScrollOrientation {
    case vertical, horizontal
}

public protocol Preheated {
    var orientation: ScrollOrientation { get }
    func indexPaths(in rect: CGRect) -> [IndexPath]
    var indexPathsForVisibleItems: [IndexPath] { get }
}


extension UICollectionView: Preheated {
    public var orientation: ScrollOrientation {
        switch (collectionViewLayout as! UICollectionViewFlowLayout).scrollDirection {
        case .vertical: return .vertical
        case .horizontal: return .horizontal
        }
    }
    
    public func indexPaths(in rect: CGRect) -> [IndexPath] {
        guard let attributes = collectionViewLayout.layoutAttributesForElements(in: rect) else {
            return []
        }
        return attributes.filter{ $0.representedElementCategory == .cell }.map{ $0.indexPath }
    }
}


extension UITableView: Preheated {
    public var orientation: ScrollOrientation {
        return .vertical
    }
    
    public func indexPaths(in rect: CGRect) -> [IndexPath] {
        return indexPathsForRows(in: rect) ?? []
    }
    
    public var indexPathsForVisibleItems: [IndexPath] {
        return indexPathsForVisibleRows ?? []
    }
}
