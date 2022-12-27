//
//  VideoView.swift
//  VideoTimeline
//
//  Created by hope on 12/16/22.
//

import UIKit
import AVFoundation

class DefaultVideoView: UIView {
    
    var player: DefaultVideoPlayer? {
        didSet {
            let layer = AVPlayerLayer(player: player?.player)
            layer.frame = self.bounds
            layer.videoGravity = .resizeAspect
            self.layer.addSublayer(layer)
        }
    }
}
