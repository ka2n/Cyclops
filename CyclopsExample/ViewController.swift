//
//  ViewController.swift
//  CyclopsExample
//
//  Created by ka2n on 2015/12/02.
//  Copyright © 2015年 ka2n. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var target: UIView!
    var cyclops : Cyclops?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load JSON
        cyclops = Cyclops(file: NSBundle.mainBundle().pathForResource("example", ofType: "json"))!
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        target.center = view.center
        if let cyc = self.cyclops {
            
            // Generate animations
            let group = CAAnimationGroup()
            group.animations = [
                cyc.animation("example-x rotation", ofProperty: .RotationX)!,
                cyc.animation("example-z rotation", ofProperty: .RotationZ)!,
                cyc.animation("example-position", ofProperty: .Position, center: self.view.center)!,
                cyc.animation("example-scale", ofProperty: .Scale)!
            ]
            group.duration = group.animations!.first!.duration
            group.repeatCount = 10000
            
            // Play and pause immediately to move initial position
            CATransaction.begin()
            target.layer.superlayer?.sublayerTransform.m34 = -0.000555 // perspective transform
            target.layer.addAnimation(group, forKey: "anim")
            
            // Pause
            let pausedTime = target.layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
            target.layer.speed = 0.0;    // 時よ止まれ
            target.layer.timeOffset = pausedTime;
            CATransaction.commit()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    @IBAction func go(sender: AnyObject) {
        
        // Play
        let pausedTime = target.layer.timeOffset
        target.layer.speed = 1.0
        target.layer.timeOffset = 0.0
        target.layer.beginTime = target.layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
    }
}
