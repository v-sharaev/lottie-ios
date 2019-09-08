//
//  LayerImageProvider.swift
//  lottie-swift
//
//  Created by Brandon Withrow on 1/25/19.
//

import Foundation
import UIKit

/// Connects a LottieImageProvider to a group of image layers
class LayerImageProvider {
  
  var imageProvider: AnimationImageProvider {
    didSet {
      reloadImages(seconds: nil)
    }
  }
  
  fileprivate(set) var imageLayers: [ImageCompositionLayer]
  let imageAssets: [String : ImageAsset]
  
  init(imageProvider: AnimationImageProvider, assets: [String : ImageAsset]?) {
    self.imageProvider = imageProvider
    self.imageLayers = [ImageCompositionLayer]()
    if let assets = assets {
      self.imageAssets = assets
    } else {
      self.imageAssets = [:]
    }
    reloadImages(seconds: nil)
  }
  
  func addImageLayers(_ layers: [ImageCompositionLayer]) {
    for layer in layers {
      if imageAssets[layer.imageReferenceID] != nil {
        /// Found a linking asset in our asset library. Add layer
        imageLayers.append(layer)
      }
    }
  }
  
  func reloadImages(seconds: CGFloat?) {
    for imageLayer in imageLayers {
      if let asset = imageAssets[imageLayer.imageReferenceID] {
        imageLayer.image = imageProvider.imageForAsset(asset: asset, seconds: seconds)
      }
    }
  }
}
