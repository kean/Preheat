<p align="center"><img src="https://cloud.githubusercontent.com/assets/1567433/14049678/4639abe8-f2d0-11e5-9897-f7af82ff06ec.png" height="180"/>

<p align="center">
<a href="https://cocoapods.org"><img src="https://img.shields.io/cocoapods/v/Preheat.svg"></a>
<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a>
<a href="http://cocoadocs.org/docsets/Preheat"><img src="https://img.shields.io/cocoapods/p/Preheat.svg?style=flat)"></a>
</p>

Automates preheating (prefetching) of content in `UITableView` and `UICollectionView`.

> This library is similar to `UITableViewDataSourcePrefetching` added in iOS 10

One of the ways to use `Preheat` is to improve user experience in applications that display collections of images. `Preheat` allows you to detect which cells are soon going to appear on the display, so that you can precache images for those cells. You can use `Preheat` with any image loading library, including [Nuke](https://github.com/kean/Nuke) which it was designed for.

The idea of automating preheating was inspired by Apple’s Photos framework [example app](https://developer.apple.com/library/ios/samplecode/UsingPhotosFramework/Introduction/Intro.html).

## Getting Started

- See [Image Preheating Guide](https://kean.github.io/blog/image-preheating)
- Check out example project for [Nuke](https://github.com/kean/Nuke)

## Usage

Here is an example of how you might implement preheating in your application using **Preheat** and **Nuke**:

```swift
class PreheatDemoViewController: UICollectionViewController, PreheatControllerDelegate {
    var preheatController: PreheatController<UICollectionView>!

    override func viewDidLoad() {
        super.viewDidLoad()

        preheatController = PreheatController(view: collectionView!)
        preheatController.handler = { [weak self] in
            self?.preheatWindowChanged(addedIndexPaths: $0, removedIndexPaths: $1)
        }
    }

    func preheatWindowChanged(addedIndexPaths added: [NSIndexPath], removedIndexPaths removed: [NSIndexPath]) {
        func requestsForIndexPaths(indexPaths: [NSIndexPath]) -> [ImageRequest] {
            return indexPaths.map { ImageRequest(photos[$0.row].URL) }
        }
        Nuke.startPreheatingImages(requestsForIndexPaths(added))
        Nuke.stopPreheatingImages(requestsForIndexPaths(removed))
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        preheatController.enabled = true
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        // When you disable preheat controller it removes all preheating 
        // index paths and calls its handler
        preheatController.enabled = false
    }
}
```

## Requirements

- iOS 8.0+, tvOS 9.0+
- Xcode 7.3+, Swift 2.2+

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

## Contacts

<a href="https://github.com/kean">
<img src="https://cloud.githubusercontent.com/assets/1567433/6521218/9c7e2502-c378-11e4-9431-c7255cf39577.png" height="44" hspace="2"/>
</a>
<a href="https://twitter.com/a_grebenyuk">
<img src="https://cloud.githubusercontent.com/assets/1567433/6521243/fb085da4-c378-11e4-973e-1eeeac4b5ba5.png" height="44" hspace="2"/>
</a>
<a href="https://www.linkedin.com/pub/alexander-grebenyuk/83/b43/3a0">
<img src="https://cloud.githubusercontent.com/assets/1567433/6521256/20247bc2-c379-11e4-8e9e-417123debb8c.png" height="44" hspace="2"/>
</a>

## License

Preheat is available under the MIT license. See the LICENSE file for more info.
