//
//  QVideoTrimSliderTimeView.swift
//  QVideoEditor
//
//  Created by Alen Peter on 16/12/2020.
//  Copyright © 2020 Qbler Technolabs. All rights reserved.
//

import UIKit

open class QVideoTrimSliderTimeView: UIView {

    let space: CGFloat = 8.0
    
    public var timeLabel       = UILabel()
    public var backgroundView  = UIView() {
        willSet(newBackgroundView){
            self.backgroundView.removeFromSuperview()
        }
        didSet {
            self.frame = CGRect(x: 0,
                                y: -backgroundView.frame.height - space,
                                width: backgroundView.frame.width,
                                height: backgroundView.frame.height)
            
            self.addSubview(backgroundView)
            self.sendSubviewToBack(backgroundView)
        }
    }
    
    public var marginTop: CGFloat       = 5.0
    public var marginBottom: CGFloat    = 5.0
    public var marginLeft: CGFloat      = 5.0
    public var marginRight: CGFloat     = 5.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public init(size: CGSize, position: Int){
        let frame = CGRect(x: 0,
                           y: -size.height - space,
                           width: size.width,
                           height: size.height)
        super.init(frame: frame)
        
        // Add Background View
        self.backgroundView.frame = self.bounds
        self.backgroundView.backgroundColor = UIColor.lightGray
        self.addSubview(self.backgroundView)
        
        // Add time label
        self.timeLabel = UILabel()
        self.timeLabel.textAlignment = .center
        self.timeLabel.textColor = UIColor.white
        self.timeLabel.font = UIFont(name: "Helvetica", size: 13)
        self.backgroundView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        self.addSubview(self.timeLabel)

    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundView.frame = self.bounds
		let timeLabelFrameWidth = self.frame.width - (marginRight + marginLeft)
		let timeLabelFrameHeight = self.frame.height - (marginBottom + marginTop)
        self.timeLabel.frame = CGRect(x: marginLeft,
                                      y: marginTop - self.timeLabel.bounds.height / 2,
                                      width: timeLabelFrameWidth,
                                      height: timeLabelFrameHeight)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
