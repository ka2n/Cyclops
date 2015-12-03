//: Playground - noun: a place where people can play

import UIKit
import XCPlayground
import QuartzCore
import Cyclops

let containerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 375.0, height: 667.0))
XCPlaygroundPage.currentPage.liveView = containerView
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

// Draw circle
let circle = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 250.0, height: 250.0))
circle.center = containerView.center
//circle.layer.cornerRadius = 25.0
let startingColor = UIColor(red: (253.0/255.0), green: (159.0/255.0), blue: (47.0/255.0), alpha: 1.0)
circle.backgroundColor = startingColor

let box = UIView(frame: CGRect(x: 30, y: 30, width: 50, height: 50))
box.backgroundColor = UIColor.whiteColor()
circle.addSubview(box)
containerView.addSubview(circle);


let cyclops = Cyclops(file: NSBundle.mainBundle().pathForResource("example", ofType: "json"))!
var anim : CAAnimation

anim = cyclops.animation("example-x rotation", ofProperty: .RotationX)!
circle.layer.addAnimation(anim, forKey: "anim4")

anim = cyclops.animation("example-z rotation", ofProperty: .RotationZ)!
circle.layer.addAnimation(anim, forKey: "anim3")

anim = cyclops.animation("example-position", ofProperty: .Position)!
circle.layer.addAnimation(anim, forKey: "anim2")

anim = cyclops.animation("example-scale", ofProperty: .Scale)!
circle.layer.addAnimation(anim, forKey: "anim1")


//
//anim = cyclops.animation("example-scale")
//if let aaa = anim {
//    circle.layer.addAnimation(aaa, forKey: kCATransition)
//}