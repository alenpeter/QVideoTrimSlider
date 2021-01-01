//
//  QVideoTrimSliderVideoHelper.swift
//  QVideoEditor
//
//  Created by Alen Peter on 16/12/2020.
//  Copyright © 2020 Qbler Technolabs. All rights reserved.
//

import UIKit
import AVFoundation

class QVideoTrimSliderVideoHelper: NSObject {

    static func thumbnailFromVideo(videoUrl: URL, time: CMTime) -> UIImage{
        let asset: AVAsset = AVAsset(url: videoUrl) as AVAsset
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        do{
            let cgImage = try imgGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage
        }catch{
            
        }
        return UIImage()
    }
    
    static func videoDuration(videoURL: URL) -> Float64{
        let source = AVURLAsset(url: videoURL)
        return CMTimeGetSeconds(source.duration)
    }
    
}
