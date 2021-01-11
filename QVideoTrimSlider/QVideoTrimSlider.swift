//
//  QVideoTrimSlider.swift
//  QVideoEditor
//
//  Created by Alen Peter on 16/12/2020.
//  Copyright © 2020 Qbler Technolabs. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices

@objc public protocol QVideoTrimSliderDelegate: class {
    func QVideoTrimSlider(QVideoTrimSlider: QVideoTrimSlider, didUpdateVideoLength startTime: Double, endTime: Double)
    func QVideoTrimSlider(QVideoTrimSlider: QVideoTrimSlider, didUpdateSeekbar position: Double)
    
    @objc optional func sliderGesturesBegan()
    @objc optional func sliderGesturesEnded()
}

public class QVideoTrimSlider: UIView, UIGestureRecognizerDelegate {

    private enum DragHandleChoice {
        case start
        case end
    }
    
    public weak var delegate: QVideoTrimSliderDelegate? = nil

    var startIndicator      = QVideoTrimSliderStartIndicator()
    var endIndicator        = QVideoTrimSliderEndIndicator()
    var topLine             = QVideoTrimSliderBorder()
    var bottomLine          = QVideoTrimSliderBorder()
    var seekBar   = QVideoTrimSliderSeekBar()
    var draggableView       = UIView()

    public var startTimeView       = QVideoTrimSliderTimeView()
    public var endTimeView         = QVideoTrimSliderTimeView()

    let thumbnailsManager   = QVideoTrimSliderThumbnailsManager()
    public var duration: Double   = 0.0
    var videoURL            = URL(fileURLWithPath: "")

    var progressPercentage: CGFloat = 0         // Represented in percentage
    var startPercentage: CGFloat    = 0         // Represented in percentage
    var endPercentage: CGFloat      = 100       // Represented in percentage

    let topBorderHeight: CGFloat      = 5
    let bottomBorderHeight: CGFloat   = 5

    let indicatorWidth: CGFloat = 20.0

    public var minSpace: Float = 1              // In Seconds
    public var maxSpace: Float = 0              // In Seconds
    
    public var isSeekBarSticky: Bool = false
    public var isSeekBarDraggable: Bool = true
    
    var isUpdatingThumbnails = false
    var isReceivingGesture: Bool = false
    
    public var avPlayer: AVPlayer? = nil
    
    public enum ABTimeViewPosition{
        case top
        case bottom
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setup(){
        self.isUserInteractionEnabled = true

        // Setup Start Indicator
        let startDrag = UIPanGestureRecognizer(target:self,
                                               action: #selector(startDragged(recognizer:)))

        startIndicator = QVideoTrimSliderStartIndicator(frame: CGRect(x: 0,
                                                        y: -topBorderHeight,
                                                        width: 20,
                                                        height: self.frame.size.height + bottomBorderHeight + topBorderHeight))
        startIndicator.layer.anchorPoint = CGPoint(x: 1, y: 0.5)
        startIndicator.addGestureRecognizer(startDrag)
        self.addSubview(startIndicator)

        // Setup End Indicator

        let endDrag = UIPanGestureRecognizer(target:self,
                                             action: #selector(endDragged(recognizer:)))

        endIndicator = QVideoTrimSliderEndIndicator(frame: CGRect(x: 0,
                                                    y: -topBorderHeight,
                                                    width: indicatorWidth,
                                                    height: self.frame.size.height + bottomBorderHeight + topBorderHeight))
        endIndicator.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        endIndicator.addGestureRecognizer(endDrag)
        self.addSubview(endIndicator)


        // Setup Top and bottom line

        topLine = QVideoTrimSliderBorder(frame: CGRect(x: 0,
                                         y: -topBorderHeight,
                                         width: indicatorWidth,
                                         height: topBorderHeight))
        self.addSubview(topLine)

        bottomLine = QVideoTrimSliderBorder(frame: CGRect(x: 0,
                                            y: self.frame.size.height,
                                            width: indicatorWidth,
                                            height: bottomBorderHeight))
        self.addSubview(bottomLine)

        self.addObserver(self,
                         forKeyPath: "bounds",
                         options: NSKeyValueObservingOptions(rawValue: 0),
                         context: nil)

        // Setup Progress Indicator

        let progressDrag = UIPanGestureRecognizer(target:self,
                                                  action: #selector(progressDragged(recognizer:)))

        seekBar = QVideoTrimSliderSeekBar(frame: CGRect(x: 0,
                                                              y: -topBorderHeight,
                                                              width: 10,
                                                              height: self.frame.size.height + bottomBorderHeight + topBorderHeight))
        seekBar.addGestureRecognizer(progressDrag)
        self.addSubview(seekBar)

        // Setup Draggable View

        let viewDrag = UIPanGestureRecognizer(target:self,
                                              action: #selector(viewDragged(recognizer:)))

        draggableView.addGestureRecognizer(viewDrag)
        self.draggableView.backgroundColor = .clear
        self.addSubview(draggableView)
        self.sendSubviewToBack(draggableView)

        // Setup time labels

        startTimeView = QVideoTrimSliderTimeView(size: CGSize(width: 60, height: 30), position: 1)
        startTimeView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.addSubview(startTimeView)

        endTimeView = QVideoTrimSliderTimeView(size: CGSize(width: 60, height: 30), position: 1)
        endTimeView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.addSubview(endTimeView)
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "bounds"{
            self.updateThumbnails()
        }
    }

    // MARK: Public functions

    public func setSeekBarImage(image: UIImage){
        self.seekBar.imageView.image = image
    }

    public func hideSeekBar(){
        self.seekBar.isHidden = true
    }

    public func showSeekBar(){
        self.seekBar.isHidden = false
    }

    public func updateSeekBar(seconds: Double){
        if !isReceivingGesture {
            let endSeconds = secondsFromValue(value: self.endPercentage)
            
            if seconds >= endSeconds {
                self.resetProgressPosition()
            } else {
                self.progressPercentage = self.valueFromSeconds(seconds: Float(seconds))
            }

            layoutSubviews()
        }
    }

    public func setStartIndicatorImage(image: UIImage){
        self.startIndicator.imageView.image = image
    }

    public func setEndIndicatorImage(image: UIImage){
        self.endIndicator.imageView.image = image
    }

    public func setBorderImage(image: UIImage){
        self.topLine.imageView.image = image
        self.bottomLine.imageView.image = image
    }

    public func setTimeView(view: QVideoTrimSliderTimeView){
        self.startTimeView = view
        self.endTimeView = view
    }
    
    func didUpdateSeekBar(progress: Double) {
        self.delegate?.QVideoTrimSlider(QVideoTrimSlider: self, didUpdateSeekbar: progress)
        self.avPlayer?.seek(to: CMTimeMake(value: Int64(progress), timescale: 1))
    }
    
    public func setTimeViewPosition(position: ABTimeViewPosition){
        switch position {
        case .top:

            break
        case .bottom:

            break
        }
    }

    public func setVideoURL(videoURL: URL){
        self.duration = QVideoTrimSliderVideoHelper.videoDuration(videoURL: videoURL)
        self.videoURL = videoURL
        DispatchQueue.main.async {
            self.superview?.layoutSubviews()
        }
        self.updateThumbnails()
    }

    public func updateThumbnails(){
        if !isUpdatingThumbnails{
            self.isUpdatingThumbnails = true
            let backgroundQueue = DispatchQueue(label: "com.app.queue", qos: .background, target: nil)
            backgroundQueue.async {
                _ = self.thumbnailsManager.updateThumbnails(view: self, videoURL: self.videoURL, duration: self.duration)
                self.isUpdatingThumbnails = false
            }
        }
    }

    public func setStartPosition(seconds: Float){
        self.startPercentage = self.valueFromSeconds(seconds: seconds)
        layoutSubviews()
    }

    public func setEndPosition(seconds: Float){
        self.endPercentage = self.valueFromSeconds(seconds: seconds)
        layoutSubviews()
    }

    // MARK: - Private functions

    // MARK: - Crop Handle Drag Functions
    @objc private func startDragged(recognizer: UIPanGestureRecognizer){
        self.processHandleDrag(
            recognizer: recognizer,
            drag: .start,
            currentPositionPercentage: self.startPercentage,
            currentIndicator: self.startIndicator
        )
    }
    
    @objc private func endDragged(recognizer: UIPanGestureRecognizer){
        self.processHandleDrag(
            recognizer: recognizer,
            drag: .end,
            currentPositionPercentage: self.endPercentage,
            currentIndicator: self.endIndicator
        )
    }

    private func processHandleDrag(
        recognizer: UIPanGestureRecognizer,
        drag: DragHandleChoice,
        currentPositionPercentage: CGFloat,
        currentIndicator: UIView
        ) {
        
        self.updateGestureStatus(recognizer: recognizer)
        
        let translation = recognizer.translation(in: self)
        
        var position: CGFloat = positionFromValue(value: currentPositionPercentage) // self.startPercentage or self.endPercentage
        
        position = position + translation.x
        
        if position < 0 { position = 0 }
        
        if position > self.frame.size.width {
            position = self.frame.size.width
        }

        let positionLimits = getPositionLimits(with: drag)
        position = checkEdgeCasesForPosition(with: position, and: positionLimits.min, and: drag)

        if Float(self.duration) > self.maxSpace && self.maxSpace > 0 {
            if drag == .start {
                if position < positionLimits.max {
                    position = positionLimits.max
                }
            } else {
                if position > positionLimits.max {
                    position = positionLimits.max
                }
            }
        }
        
        recognizer.setTranslation(CGPoint.zero, in: self)
        
        currentIndicator.center = CGPoint(x: position , y: currentIndicator.center.y)
        
        let percentage = currentIndicator.center.x * 100 / self.frame.width
        
        let startSeconds = secondsFromValue(value: self.startPercentage)
        let endSeconds = secondsFromValue(value: self.endPercentage)
        
        self.delegate?.QVideoTrimSlider(QVideoTrimSlider: self, didUpdateVideoLength: startSeconds, endTime: endSeconds)
        
        var progressPosition: CGFloat = 0.0
        
        if drag == .start {
            self.startPercentage = percentage
        } else {
            self.endPercentage = percentage
        }
        
        if drag == .start {
            progressPosition = positionFromValue(value: self.startPercentage)
            
        } else {
            if recognizer.state != .ended {
                progressPosition = positionFromValue(value: self.endPercentage)
            } else {
                progressPosition = positionFromValue(value: self.startPercentage)
            }
        }
        
        seekBar.center = CGPoint(x: progressPosition , y: seekBar.center.y)
        let progressPercentage = seekBar.center.x * 100 / self.frame.width
        
        if self.progressPercentage != progressPercentage {
            let progressSeconds = secondsFromValue(value: progressPercentage)
            self.didUpdateSeekBar(progress: progressSeconds)
        }
        
        self.progressPercentage = progressPercentage
        
        layoutSubviews()
    }
    
    @objc func progressDragged(recognizer: UIPanGestureRecognizer){
        if !isSeekBarDraggable {
            return
        }
        
        updateGestureStatus(recognizer: recognizer)
        
        let translation = recognizer.translation(in: self)

        let positionLimitStart  = positionFromValue(value: self.startPercentage)
        let positionLimitEnd    = positionFromValue(value: self.endPercentage)

        var position = positionFromValue(value: self.progressPercentage)
        position = position + translation.x

        if position < positionLimitStart {
            position = positionLimitStart
        }

        if position > positionLimitEnd {
            position = positionLimitEnd
        }

        recognizer.setTranslation(CGPoint.zero, in: self)

        seekBar.center = CGPoint(x: position , y: seekBar.center.y)

        let percentage = seekBar.center.x * 100 / self.frame.width

        let progressSeconds = secondsFromValue(value: progressPercentage)

        self.didUpdateSeekBar(progress: progressSeconds)

        self.progressPercentage = percentage

        layoutSubviews()
    }

    @objc func viewDragged(recognizer: UIPanGestureRecognizer){
        updateGestureStatus(recognizer: recognizer)
        
        let translation = recognizer.translation(in: self)

        var progressPosition = positionFromValue(value: self.progressPercentage)
        var startPosition = positionFromValue(value: self.startPercentage)
        var endPosition = positionFromValue(value: self.endPercentage)

        startPosition = startPosition + translation.x
        endPosition = endPosition + translation.x
        progressPosition = progressPosition + translation.x

        if startPosition < 0 {
            startPosition = 0
            endPosition = endPosition - translation.x
            progressPosition = progressPosition - translation.x
        }

        if endPosition > self.frame.size.width{
            endPosition = self.frame.size.width
            startPosition = startPosition - translation.x
            progressPosition = progressPosition - translation.x
        }

        recognizer.setTranslation(CGPoint.zero, in: self)

        seekBar.center = CGPoint(x: progressPosition , y: seekBar.center.y)
        startIndicator.center = CGPoint(x: startPosition , y: startIndicator.center.y)
        endIndicator.center = CGPoint(x: endPosition , y: endIndicator.center.y)

        let startPercentage = startIndicator.center.x * 100 / self.frame.width
        let endPercentage = endIndicator.center.x * 100 / self.frame.width
        let progressPercentage = seekBar.center.x * 100 / self.frame.width

        if self.progressPercentage != progressPercentage{
            let progressSeconds = secondsFromValue(value: progressPercentage)
            self.didUpdateSeekBar(progress: progressSeconds)
        }

        self.startPercentage = startPercentage
        self.endPercentage = endPercentage
        self.progressPercentage = progressPercentage

        layoutSubviews()
    }
    
    // MARK: - Drag Functions Helpers
    private func positionFromValue(value: CGFloat) -> CGFloat{
        let position = value * self.frame.size.width / 100
        return position
    }
    
    private func getPositionLimits(with drag: DragHandleChoice) -> (min: CGFloat, max: CGFloat) {
        if drag == .start {
            return (
                positionFromValue(value: self.endPercentage - valueFromSeconds(seconds: self.minSpace)),
                positionFromValue(value: self.endPercentage - valueFromSeconds(seconds: self.maxSpace))
            )
        } else {
            return (
                positionFromValue(value: self.startPercentage + valueFromSeconds(seconds: self.minSpace)),
                positionFromValue(value: self.startPercentage + valueFromSeconds(seconds: self.maxSpace))
            )
        }
    }
    
    private func checkEdgeCasesForPosition(with position: CGFloat, and positionLimit: CGFloat, and drag: DragHandleChoice) -> CGFloat {
        if drag == .start {
            if Float(self.duration) < self.minSpace {
                return 0
            } else {
                if position > positionLimit {
                    return positionLimit
                }
            }
        } else {
            if Float(self.duration) < self.minSpace {
                return self.frame.size.width
            } else {
                if position < positionLimit {
                    return positionLimit
                }
            }
        }
        
        return position
    }
    
    private func secondsFromValue(value: CGFloat) -> Double{
        return duration * Double((value / 100))
    }

    private func valueFromSeconds(seconds: Float) -> CGFloat{
        return CGFloat(seconds * 100) / CGFloat(duration)
    }
    
    private func updateGestureStatus(recognizer: UIGestureRecognizer) {
        if recognizer.state == .began {
            
            self.isReceivingGesture = true
            self.delegate?.sliderGesturesBegan?()
            
        } else if recognizer.state == .ended {
            
            self.isReceivingGesture = false
            self.delegate?.sliderGesturesEnded?()
        }
    }
    
    private func resetProgressPosition() {
        self.progressPercentage = self.startPercentage
        let progressPosition = positionFromValue(value: self.progressPercentage)
        seekBar.center = CGPoint(x: progressPosition , y: seekBar.center.y)
        
        let startSeconds = secondsFromValue(value: self.progressPercentage)
        self.didUpdateSeekBar(progress: startSeconds)
    }

    // MARK: -

    override public func layoutSubviews() {
        super.layoutSubviews()

        startTimeView.timeLabel.text = self.secondsToFormattedString(totalSeconds: secondsFromValue(value: self.startPercentage))
        endTimeView.timeLabel.text = self.secondsToFormattedString(totalSeconds: secondsFromValue(value: self.endPercentage))

        let startPosition = positionFromValue(value: self.startPercentage)
        let endPosition = positionFromValue(value: self.endPercentage)
        let progressPosition = positionFromValue(value: self.progressPercentage)

        startIndicator.center = CGPoint(x: startPosition, y: startIndicator.center.y)
        endIndicator.center = CGPoint(x: endPosition, y: endIndicator.center.y)
        seekBar.center = CGPoint(x: progressPosition, y: seekBar.center.y)
        draggableView.frame = CGRect(x: startIndicator.frame.origin.x + startIndicator.frame.size.width,
                                     y: 0,
                                     width: endIndicator.frame.origin.x - startIndicator.frame.origin.x - endIndicator.frame.size.width,
                                     height: self.frame.height)


        topLine.frame = CGRect(x: startIndicator.frame.origin.x + startIndicator.frame.width,
                               y: -topBorderHeight,
                               width: endIndicator.frame.origin.x - startIndicator.frame.origin.x - endIndicator.frame.size.width,
                               height: topBorderHeight)

        bottomLine.frame = CGRect(x: startIndicator.frame.origin.x + startIndicator.frame.width,
                                  y: self.frame.size.height,
                                  width: endIndicator.frame.origin.x - startIndicator.frame.origin.x - endIndicator.frame.size.width,
                                  height: bottomBorderHeight)

        // Update time view
        startTimeView.center = CGPoint(x: startIndicator.center.x, y: startTimeView.center.y)
        endTimeView.center = CGPoint(x: endIndicator.center.x, y: endTimeView.center.y)
    }


    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedBounds = CGRect(x: -startIndicator.frame.size.width,
                                    y: -topLine.frame.size.height,
                                    width: self.frame.size.width + startIndicator.frame.size.width + endIndicator.frame.size.width,
                                    height: self.frame.size.height + topLine.frame.size.height + bottomLine.frame.size.height)
        return extendedBounds.contains(point)
    }


    private func secondsToFormattedString(totalSeconds: Double) -> String{
        let hours:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }

    deinit {
      // removeObserver(self, forKeyPath: "bounds")
    }
    
    public func trimVideo(url: URL, statTime:Double, endTime:Double, completion: @escaping (URL?, Error?) -> ())
    {
        let manager = FileManager.default

        guard let documentDirectory = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {return}
        let mediaType = "mp4"

        if mediaType == kUTTypeMovie as String || mediaType == "mp4" as String {
            let asset = AVAsset(url: url)
            let length = Double(asset.duration.value) / Double(asset.duration.timescale)
            print("video length: \(length) seconds")

            let start = statTime
            let end = endTime

            var outputURL = documentDirectory.appendingPathComponent("output")
            
            do {
                try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
                let name = UUID().uuidString
                outputURL = outputURL.appendingPathComponent("\(name).mp4")
            } catch let error {
                debugPrint(error)
            }

            //Remove existing file
            _ = try? manager.removeItem(at: outputURL)


            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.mp4

            let startTime = CMTime(seconds: Double(start), preferredTimescale: 1000)
            let endTime = CMTime(seconds: Double(end), preferredTimescale: 1000)
            let timeRange = CMTimeRange(start: startTime, end: endTime)

            exportSession.timeRange = timeRange
            exportSession.exportAsynchronously {
                switch exportSession.status {
                    case .completed:
                        debugPrint("exported at \(outputURL)")
                        completion(outputURL, nil)
                    case .failed:
                        debugPrint("failed \(exportSession.error.debugDescription)")
                        completion(nil, exportSession.error)
                    case .cancelled:
                        debugPrint("cancelled \(exportSession.error.debugDescription)")
                        completion(nil, exportSession.error)
                    default: break
                }
            }
        }
    }
}
