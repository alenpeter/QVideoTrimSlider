//
//  QVideoTrimSliderBorder.swift
//  QVideoEditor
//
//  Created by Alen Peter on 16/12/2020.
//  Copyright © 2020 Qbler Technolabs. All rights reserved.
//

import UIKit

class QVideoTrimSliderBorder: UIView {

    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let bundle = Bundle(for: QVideoTrimSliderStartIndicator.self)
        let image = UIImage(named: "BorderLine", in: bundle, compatibleWith: nil)
        
        imageView.frame = self.bounds
        imageView.image = image
        imageView.contentMode = UIView.ContentMode.scaleToFill
        self.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = self.bounds
    }

}
