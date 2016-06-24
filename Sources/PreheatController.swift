// The MIT License (MIT)
//
// Copyright (c) 2016 Alexander Grebenyuk (github.com/kean).

import UIKit

/// Automates prefetching of content in a scroll views. After creating a preheat controller you should enable it by setting `enabled` property to `true`.
public class PreheatController<V where V: UIScrollView, V: PreheatingView> : NSObject {
    /// Gets called when the preheat window changes. Provides an array of index paths that were added and that were removed from the previous preheat window. Index paths are ordered by the distance to the viewport.
    public var handler: ((added: [NSIndexPath], removed: [NSIndexPath]) -> Void)?

    /// The view that the receiver was initialized with.
    public let view: V

    /// Currently preheated index paths.
    public private(set) var indexPaths = [NSIndexPath]()

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
        self.view.addObserver(self, forKeyPath: "contentOffset", options: [.New], context: nil)
    }

    /// Removes all index paths without signalling the delegate. Then updates preheat rect (if enabled).
    public func reset() {
        indexPaths.removeAll()
        previousOffset = nil
        if enabled {
            update()
        }
    }

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if object === view {
            if enabled {
                update()
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: nil)
        }
    }
    
    private func update() {
        guard shouldUpdatePreheatRect() else {
            return
        }
        let isScrollingForward = view.isScrollingForward(previousOffset: previousOffset)
        let preheatRect = view.preheatingRect(isScrollingForward: isScrollingForward, sizeRatio: preheatRectSizeRatio)
        let indexPaths = Set(view.indexPaths(in: preheatRect)).subtract(view.indexPathsForVisibleItems())
        updateIndexPaths(indexPaths.sort({ // sort in scroll direction
            if isScrollingForward {
                return $0.section < $1.section || $0.item < $1.item
            } else {
                return $0.section > $1.section || $0.item > $1.item
            }
        }))
        previousOffset = view.contentOffset
    }
    
    private func shouldUpdatePreheatRect() -> Bool {
        func distance(p1: CGPoint, _ p2: CGPoint) -> CGFloat {
            let dx = p2.x - p1.x, dy = p2.y - p1.y
            return sqrt((dx * dx) + (dy * dy))
        }
        guard let previousOffset = previousOffset else {
            return true
        }
        let margin = (view.orientation == .Vertical ? CGRectGetHeight : CGRectGetWidth)(view.bounds) * updateRatio
        return distance(view.contentOffset, previousOffset) > margin
    }

    private func updateIndexPaths(newIndexPaths: [NSIndexPath]) {
        let added = newIndexPaths.filter { !indexPaths.contains($0) }
        let removed = indexPaths.filter { !newIndexPaths.contains($0) }
        indexPaths = newIndexPaths
        handler?(added: added, removed: removed)
    }
}

private extension PreheatingView where Self: UIScrollView {
    func preheatingRect(isScrollingForward isScrollingForward: Bool, sizeRatio: CGFloat) -> CGRect {
        let viewport = CGRect(origin: contentOffset, size: bounds.size)
        switch orientation {
        case .Vertical:
            let height = CGRectGetHeight(viewport) * sizeRatio
            let y = isScrollingForward ? CGRectGetMaxY(viewport) : CGRectGetMinY(viewport) - height
            return CGRectIntegral(CGRect(x: 0, y: y, width: CGRectGetWidth(viewport), height: height))
        case .Horizontal:
            let width = CGRectGetWidth(viewport) * sizeRatio
            let x = isScrollingForward ? CGRectGetMaxX(viewport) : CGRectGetMinX(viewport) - width
            return CGRectIntegral(CGRect(x: x, y: 0, width: width, height: CGRectGetHeight(viewport)))
        }
    }
    
    func isScrollingForward(previousOffset previousOffset: CGPoint?) -> Bool {
        guard let previousOffset = previousOffset else {
            return true
        }
        switch orientation {
        case .Vertical: return contentOffset.y >= previousOffset.y
        case .Horizontal: return contentOffset.x >= previousOffset.x
        }
    }
}


public enum ScrollOrientation {
    case Vertical, Horizontal
}

public protocol PreheatingView {
    var orientation: ScrollOrientation { get }
    func indexPaths(in rect: CGRect) -> [NSIndexPath]
    func indexPathsForVisibleItems() -> [NSIndexPath]
}


extension UICollectionView: PreheatingView {
    public var orientation: ScrollOrientation {
        switch (collectionViewLayout as! UICollectionViewFlowLayout).scrollDirection {
        case .Vertical: return .Vertical
        case .Horizontal: return .Horizontal
        }
    }

    public func indexPaths(in rect: CGRect) -> [NSIndexPath] {
        guard let attributes = collectionViewLayout.layoutAttributesForElementsInRect(rect) else {
            return []
        }
        return attributes.filter{ $0.representedElementCategory == .Cell }.map{ $0.indexPath }
    }
}


extension UITableView: PreheatingView {
    public var orientation: ScrollOrientation {
        return .Vertical
    }
    
    public func indexPaths(in rect: CGRect) -> [NSIndexPath] {
        return indexPathsForRowsInRect(rect) ?? []
    }

    public func indexPathsForVisibleItems() -> [NSIndexPath] {
        return indexPathsForVisibleRows ?? []
    }
}
