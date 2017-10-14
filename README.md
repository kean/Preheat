<p align="center"><img src="https://cloud.githubusercontent.com/assets/1567433/14049678/4639abe8-f2d0-11e5-9897-f7af82ff06ec.png" height="180"/>

<p align="center">
<a href="https://cocoapods.org"><img src="https://img.shields.io/cocoapods/v/Preheat.svg"></a>
<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a>
<a href="http://cocoadocs.org/docsets/Preheat"><img src="https://img.shields.io/cocoapods/p/Preheat.svg?style=flat)"></a>
</p>

Automates preheating (prefetching) of content in `UITableView` and `UICollectionView`.

> This library is similar to `UITableViewDataSourcePrefetching` and `UICollectionViewDataSourcePrefetching` added in iOS 10

One way to use `Preheat` is to improve user experience in applications that display collections of images. `Preheat` allows you to detect which cells are soon going to appear on the display, and prefetch images for those cells. You can use `Preheat` with any image loading library, including [Nuke](https://github.com/kean/Nuke) which it was designed for.

The idea of automating preheating was inspired by Apple’s Photos framework [example app](https://developer.apple.com/library/ios/samplecode/UsingPhotosFramework/Introduction/Intro.html).

## Getting Started

- See [Image Preheating Guide](https://kean.github.io/blog/image-preheating)
- Check out example project for [Nuke](https://github.com/kean/Nuke)

## Usage

Here is an example of how you might implement preheating in your application using **Preheat** and **Nuke**:

```swift
import Preheat
import Nuke

class PreheatDemoViewController: UICollectionViewController {
    let preheater = Nuke.Preheater()
    var controller: Preheat.Controller<UICollectionView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        controller = Preheat.Controller(view: collectionView!)
        controller?.handler = { [weak self] addedIndexPaths, removedIndexPaths in
            self?.preheat(added: addedIndexPaths, removed: removedIndexPaths)
        }
    }

    func preheat(added: [IndexPath], removed: [IndexPath]) {
        func requests(for indexPaths: [IndexPath]) -> [Request] {
            return indexPaths.map { Request(url: photos[$0.row]) }
        }
        preheater.startPreheating(with: requests(for: added))
        preheater.stopPreheating(with: requests(for: removed))
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        controller?.enabled = true
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        // When you disable preheat controller it removes all preheating 
        // index paths and calls its handler
        controller?.enabled = false
    }
}
```

## Requirements

- iOS 8.0 / tvOS 9.0
- Xcode 9
- Swift 4

## Installation<a name="installation"></a>

### [CocoaPods](http://cocoapods.org)

To install Preheat add a dependency to your Podfile:

```ruby
# source 'https://github.com/CocoaPods/Specs.git'
# use_frameworks!
# platform :ios, "8.0"

pod "Preheat"
```

### [Carthage](https://github.com/Carthage/Carthage)

To install Preheat add a dependency to your Cartfile:

```
github "kean/Preheat"
```

### Import

Import installed modules in your source files

```swift
import Preheat
```

## License

Preheat is available under the MIT license. See the LICENSE file for more info.
