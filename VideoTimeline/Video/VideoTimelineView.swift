//
//  VideoTimelineView.swift
//  VideoTimeline
//
//  Created by hope on 12/16/22.
//

import UIKit
import CoreMedia
import Combine

protocol VideoTimelineViewDelegate {
    func timelineReady()
}

class VideoTimelineView: UIView, UIScrollViewDelegate {
    private var thumbGenerator: ThumbnailGenerator?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let thumbSize = CGSize(width: 96, height: 96 * 3/4)
    
    private let thumbIntervalSeconds = 5
    
    private var scrollPadding = 0.0
        
    private var thumbLoaded = false
    
    private var seekTime = CurrentValueSubject<CMTime, Never>(.zero)
    
    private var lastSeekTime: CMTime?
    
    private var isDragging = false
    
    var delegate: VideoTimelineViewDelegate?
    
    var player: VideoPlayerIntf? {
        didSet {
            configureThumbScrollView()
        }
    }
    
    private lazy var thumbScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        return scrollView
    }()
    
    private let playheadView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.backgroundColor = UIColor(hex: "#b92424ff")
        return view
    }()
    
    private let timeView: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = UIColor(hex: "#101010ff")
        
        addSubview(thumbScrollView)
        thumbScrollView.constraints(leading: leadingAnchor,
                                    top: topAnchor,
                                    trailing: trailingAnchor,
                                    paddingTop: 20,
                                    height: thumbSize.height)
        
        addSubview(playheadView)
        playheadView.constraints(top: thumbScrollView.bottomAnchor,
                             paddingTop: -12,
                             width: 4,
                             height: 48,
                             centerX: centerXAnchor)
        
        addSubview(timeView)
        timeView.constraints(top: playheadView.bottomAnchor,
                             paddingTop: 8,
                             width: 120,
                             centerX: centerXAnchor)
        timeView.text = "00:00"
    }
    
    private func loadThumbImages() {
        guard let videoURL = player?.url else {
            return
        }
        
        thumbGenerator = ThumbnailGenerator(url: videoURL)
        thumbGenerator?.requestThumbnails(intervalSeconds: thumbIntervalSeconds) { image, index, totalCount in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                
                if index == 0 {
                    let scrollWidth = CGFloat(totalCount) * self.thumbSize.width
                    let rightPadding = scrollWidth <= self.scrollPadding ? 0.0 : self.scrollPadding
                    
                    self.thumbScrollView.contentInset = UIEdgeInsets(top: 0, left: self.scrollPadding, bottom: 0, right: rightPadding)
                    self.thumbScrollView.contentSize = CGSize(width: scrollWidth, height: self.thumbSize.height)
                }
                
                if let cgImage = image {
                    let thumbImageView = UIImageView(image: UIImage(cgImage: cgImage))
                    thumbImageView.contentMode = .scaleAspectFill
                    thumbImageView.frame.size = self.thumbSize
                    thumbImageView.frame.origin = CGPoint(x: CGFloat(index) * self.thumbSize.width, y: 0)
                    thumbImageView.alpha = 0
                    
                    if index == 0 {
                        thumbImageView.layer.masksToBounds = true
                        thumbImageView.layer.cornerRadius = 12
                        thumbImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                    } else if index == totalCount - 1 {
                        thumbImageView.layer.masksToBounds = true
                        thumbImageView.layer.cornerRadius = 12
                        thumbImageView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                    }
                    
                    self.thumbScrollView.addSubview(thumbImageView)
                    
                    UIView.animate(withDuration: 0.3) {
                        thumbImageView.alpha = 1
                    }
                }
                
                if index == totalCount - 1 {
                    self.thumbLoaded = true
                    self.observePlayer()
                    self.delegate?.timelineReady()
                }
            }
        }
    }
    
    private func configureThumbScrollView() {
        scrollPadding = frame.width / 2
        loadThumbImages()
    }
    
    private func observePlayer() {
        guard let videoDuration = player?.duration?.seconds, videoDuration > 0 else {
            return
        }
        
        let scrollWidth = thumbScrollView.contentSize.width
        let moveStep = scrollWidth / videoDuration
        
        player?.currentTimeObservable
            .sink { [weak self] playingTime in
                guard let self = self else {
                    return
                }
                
                self.timeView.text = "\(Int(playingTime.seconds).toHHMMSS)"
                
                if self.player?.status == .playing {
                    let scrollOffset = -self.scrollPadding + playingTime.seconds * moveStep
                    self.thumbScrollView.setContentOffset(CGPoint(x: scrollOffset, y: 0), animated: true)
                }
        }.store(in: &cancellables)
        
        player?.statusObservable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else {
                    return
                }

                if status == .playing {
                    self.isDragging = false // auto scrolling
                }
                
                if status == .finished {
                    // Scroll to zero time
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.player?.seek(to: .zero, completion: nil)
                        self.thumbScrollView.setContentOffset(CGPoint(x: -self.scrollPadding, y: 0), animated: true)
                    }
                }
        }.store(in: &cancellables)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDragging = true
        player?.pause()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let videoDuration = player?.duration, thumbLoaded, isDragging else {
            return
        }
        
        let scrollWidth = thumbScrollView.contentSize.width
        var playHeadPos = thumbScrollView.contentOffset.x + scrollPadding
        
        if playHeadPos > scrollWidth {
            playHeadPos = scrollWidth
        }
        if playHeadPos < 0 {
            playHeadPos = 0
        }
        
        let ratio = playHeadPos / scrollWidth
        let timeValue = Int64(Double(videoDuration.value) * ratio)
        let time = CMTimeMake(value: timeValue, timescale: videoDuration.timescale)
        let minSeekInterval = 0.3
        
        if lastSeekTime == nil {
            lastSeekTime = time
        } else {
            if abs(time.seconds - lastSeekTime!.seconds) < minSeekInterval {
                return
            }
            lastSeekTime = time
        }
        player?.seek(to: time, completion: nil)
    }
}
