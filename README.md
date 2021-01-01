#  QVideoTrimSlider


## Usage

### StoryBoard
Add a new UIVIew with class QVideoTrimSlider

### View Controller
**Import Class**

```swift
import QVideoTrimSlider
```
**Add Outlet for UIView in StoryBoard**

```swift
@IBOutlet weak var trimSlider: QVideoTrimSlider!
```
**Initialise**

```swift
trimSlider.setVideoURL(videoURL: url) // provide local file url of original video
trimSlider.avPlayer = self.avPlayer // optional - so that the position in avplayer can be auto updated when the user updates the seekbar
trimSlider.delegate = self
trimSlider.minSpace = 2 // minimum seconds between start and end
trimSlider.isSeekBarSticky = true
trimSlider.showSeekBar()
trimSlider.setStartPosition(seconds: 0)
trimSlider.setEndPosition(seconds: Float(trimSlider.duration)) //optional
```
**Delegate Methods**

```swift
extension ViewController: QVideoTrimSliderDelegate {
    func QVideoTrimSlider(QVideoTrimSlider: QVideoTrimSlider, didUpdateSeekbar position: Double) {
        /// seekbar (progress indicator) updated
    }
    
    func QVideoTrimSlider(QVideoTrimSlider: QVideoTrimSlider, didUpdateVideoLength startTime: Double, endTime: Double) {
        /// start and/or end time updated
    }
}
```
**Update Seekbar (while playing video)**

```swift
self.avPlayer.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 50), queue: .main) { (cmtime) in
    self.trimSlider.updateSeekBar(seconds: Double(Float(cmtime.value)/Float(cmtime.timescale)))
}
```

**Trim Video**

```swift
trimSlider?.trimVideo(url: url, statTime: 0, endTime: 5) { (outputUrl, error) in
    guard let outputUrl = outputUrl else {
        debugPrint(error.debugDescription)
        return
    }
    // trimmed video url: outputUrl
}
```



