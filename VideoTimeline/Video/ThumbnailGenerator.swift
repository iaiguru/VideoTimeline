//
//  ThumbnailGenerator.swift
//  VideoTimeline
//
//  Created by hope on 12/24/22.
//
import AVFoundation

class ThumbnailGenerator {
    
    private let assetImageGenerator: AVAssetImageGenerator
    private let videoDuration: Double
    private var thumbIndex = 0
    
    init(url: URL) {
        let asset = AVAsset(url: url)
        
        videoDuration = asset.duration.seconds
        assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        assetImageGenerator.requestedTimeToleranceBefore = .zero
        assetImageGenerator.requestedTimeToleranceAfter = .zero
    }
    
    deinit {
        assetImageGenerator.cancelAllCGImageGeneration()
    }
    
    func requestThumbnails(intervalSeconds: Int, completion: @escaping (CGImage?, Int, Int) -> Void) {
        let interval = intervalSeconds < 1 ? 1 : intervalSeconds
        let duration = Int(videoDuration)
        var thumbCount = duration / interval
        var thumbTimes = [NSValue]()
        
        if thumbCount * interval < duration {
            thumbCount += 1
        }
        for i in 0..<thumbCount {
            let time = CMTime(value: CMTimeValue(i * interval), timescale: 1)
            thumbTimes.append(NSValue(time: time))
        }
        
        thumbIndex = 0
        assetImageGenerator.generateCGImagesAsynchronously(forTimes: thumbTimes) { [weak self] requestedTime, cgImage, actualTime, result, error in
            guard let self = self else {
                return
            }
            completion(cgImage, self.thumbIndex, thumbTimes.count)
            self.thumbIndex += 1
        }
    }
}
