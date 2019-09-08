//
//  VideoImageProvider.swift
//  Lottie_iOS
//
//  Created by Vladimir Sharaev on 08/09/2019.
//  Copyright © 2019 YurtvilleProds. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

class VideoImageProvider: AnimationImageProvider {
    
    let filepath: URL
    var fps: CMTimeScale = 30
    
    /**
     Initializes an image provider with a specific filepath.
     
     - Parameter filepath: The absolute filepath containing the images.
     
     */
    public init(filepath: String) {
        self.filepath = URL(fileURLWithPath: filepath)
    }
    
    public init(filepath: URL) {
        self.filepath = filepath
    }
    
    private var assetImageGenerators = [String: AVAssetImageGenerator]()
    private var images = [String: [CGFloat: Data]]()
    
    public func prepareImagesForAssetName(name: String, completion: @escaping (() -> Void)) {
        
        guard let key = createAVAsset(name: name, directory: nil),
            let imageGenerator = assetImageGenerators[key] else {
                completion()
                return
        }
        
        let fpsCopy = fps
        
        DispatchQueue.global().async { [weak self] in
            
            let maxSeconds = CGFloat(imageGenerator.asset.duration.seconds)
            
            var times = [NSValue]()
            var seconds: CGFloat = 0
            var createTimes = true
            
            while createTimes {
                
                let time = CMTime(seconds: Double(seconds), preferredTimescale: fpsCopy)
                times.append(NSValue(time: time))
                
                seconds = seconds + CGFloat(1) / CGFloat(fpsCopy)
                
                if maxSeconds < seconds {
                    createTimes = false
                    seconds = 0
                }
            }
            
            var images = [CGFloat: Data]()
            imageGenerator.generateCGImagesAsynchronously(forTimes: times,
                                                          completionHandler: { [weak self] (_, image, _, _, _) in
                
                if let image = image {
                    let uiImage = UIImage(cgImage: image)
                    let data = uiImage.jpegData(compressionQuality: 1.0)
                    
                    images[seconds] = data
                }
                
                seconds = seconds + CGFloat(1) / CGFloat(fpsCopy)
                                                            
                if maxSeconds < seconds {
                    self?.images[key] = images
                    
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            })
        }
    }
    
    public func imageForAsset(asset: ImageAsset, seconds: CGFloat?) -> CGImage? {
        
        guard let key = createAVAsset(name: asset.name, directory: asset.directory),
            let images = images[key],
            let data = images[seconds ?? 0],
            let image = UIImage.init(data: data, scale: 1.0)?.cgImage else {
                
                return nil
        }
        
        return image
    }
    
    private func createAVAsset(name: String, directory: String?) -> String? {
        
        // By default name contains .jpeg like image
        let name = name.replacingOccurrences(of: ".jpeg", with: ".mov")
        
        var directPath: String? = filepath.appendingPathComponent(name).path
        if !FileManager.default.fileExists(atPath: directPath ?? "") {
            
            directPath = filepath.appendingPathComponent(directory ?? "").appendingPathComponent(name).path
            if !FileManager.default.fileExists(atPath: directPath ?? "") {
                directPath = nil
            }
        }
        
        guard let path = directPath else {
            return nil
        }
        
        if assetImageGenerators[path] != nil {
            return path
        }
        
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        
        assetImageGenerator.appliesPreferredTrackTransform = true
        assetImageGenerator.requestedTimeToleranceAfter = CMTime.zero
        assetImageGenerator.requestedTimeToleranceBefore = CMTime.zero
        
        assetImageGenerators[path] = assetImageGenerator
        
        return path
    }
}
