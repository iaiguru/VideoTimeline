//
//  VideoPlayer.swift
//  VideoTimeline
//
//  Created by hope on 12/16/22.
//

import Foundation
import AVFoundation
import Combine

public enum VideoPlayerStatus {
    case initial
    case loading
    case failed
    case readyToPlay
    case playing
    case paused
    case finished
}

protocol VideoPlayerIntf {
    var url: URL? { get set }
    
    var status: VideoPlayerStatus { get }
    
    var statusObservable: AnyPublisher<VideoPlayerStatus, Never> { get }
    
    var duration: CMTime? { get }
    
    var currentTimeObservable: AnyPublisher<CMTime, Never> { get }
    
    var videoSize: CGSize? { get }
    
    func play()
    
    func pause()
    
    func seek(to time: CMTime, completion: ((Bool) -> Void)?)
}

class DefaultVideoPlayer: NSObject, VideoPlayerIntf {
    
    private(set) var player = AVPlayer()
    
    private let observedKeyPaths = [
        #keyPath(AVPlayer.timeControlStatus),
        #keyPath(AVPlayer.currentItem.status),
    ]
    
    private var timeObserver: Any?
    
    private static var observerContext = 0
    
    private var _status = CurrentValueSubject<VideoPlayerStatus, Never>(.initial)
    
    private(set) lazy var statusObservable: AnyPublisher<VideoPlayerStatus, Never> = {
        _status.eraseToAnyPublisher()
    }()
    
    var status: VideoPlayerStatus {
        _status.value
    }
    
    private var _currentTime = CurrentValueSubject<CMTime, Never>(.zero)
    
    private(set) lazy var currentTimeObservable: AnyPublisher<CMTime, Never> = {
        _currentTime.eraseToAnyPublisher()
    }()
    
    var url: URL? {
        get {
            (player.currentItem?.asset as? AVURLAsset)?.url
        }
        
        set {
            if let url = newValue {
                replaceCurrentItem(AVPlayerItem(url: url))
            } else {
                replaceCurrentItem(nil)
            }
        }
    }
    
    var duration: CMTime? {
        player.currentItem?.duration
    }
    
    var videoSize: CGSize? {
        guard let videoTrack = player.currentItem?.asset.tracks(withMediaType: .video).first else {
            return nil
        }
        return videoTrack.naturalSize.applying(videoTrack.preferredTransform)
    }
    
    init(playerItem: AVPlayerItem? = nil) {
        super.init()
        
        addPlayerObserve()
        if let playerItem = playerItem {
            replaceCurrentItem(playerItem)
        }
    }
    
    convenience init(asset: AVAsset) {
        self.init(playerItem: AVPlayerItem(asset: asset))
    }
    
    convenience init(url: URL) {
        let asset = AVAsset(url: url)
        self.init(asset: asset)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removePlayerObserve()
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func seek(to time: CMTime, completion: ((Bool) -> Void)?) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] success in
            guard let self = self else {
                return
            }
            if success {
                self._currentTime.value = self.player.currentTime()
            }
            completion?(success)
        }
    }
    
    private func replaceCurrentItem(_ playerItem: AVPlayerItem?) {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: player.currentItem)
        player.replaceCurrentItem(with: playerItem)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinishPlaying),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: playerItem)
    }
    
    private func addPlayerObserve() {
        for keyPath in observedKeyPaths {
            player.addObserver(self, forKeyPath: keyPath, options: [.new, .initial], context: &DefaultVideoPlayer.observerContext)
        }
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 20),
                                                      queue: .main) { [weak self] time in
            guard let self = self else {
                return
            }
            self._currentTime.value = time
        }
    }
    
    private func removePlayerObserve() {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        for keyPath in observedKeyPaths {
            player.removeObserver(self, forKeyPath: keyPath, context: &DefaultVideoPlayer.observerContext)
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        _status.value = .finished
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &DefaultVideoPlayer.observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            switch player.timeControlStatus {
            case .playing:
                _status.value = .playing
            case .paused:
                _status.value = .paused
            default:
                _status.value = .loading
            }
        } else if keyPath == #keyPath(AVPlayer.currentItem.status), let playerItem = player.currentItem {
            switch playerItem.status {
            case .readyToPlay:
                _status.value = .readyToPlay
            default:
                _status.value = .failed
            }
        }
    }
}
