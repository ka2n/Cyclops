//
//  Cyclops.swift
//  Cyclops
//
//  Created by ka2n on 2015/12/02.
//  Copyright © 2015年 ka2n. All rights reserved.
//

import Foundation
import QuartzCore
import QuartzCore.CAAnimation

public enum Property {
    case Scale
    case Position
    case RotationX
    case RotationY
    case RotationZ
}

struct CurveData {
    let frames : [FrameData]
    let duration : Double
    let startTime : Double
    let begin: [Double]
}

struct FrameData {
    let time: Double
    let values: [Double]
}

private func JSONObjectWithData(data: NSData) -> AnyObject? {
    do {
        return try NSJSONSerialization.JSONObjectWithData(data, options: [])
    } catch {
        return nil
    }
}


public class Cyclops {

    var curves = [String:CurveData]()
    
    public convenience init?(file:String?) {
        let json = file
            .flatMap { NSData(contentsOfFile: $0) }
            .flatMap { JSONObjectWithData($0) }
        guard json != nil else { return nil }
        self.init(object: json)
    }
    
    public convenience init(object:AnyObject?) {
        self.init()
        guard let obj = object as? Dictionary<String, AnyObject> else { return }
        
        self.curves = obj.reduce([String: CurveData]()) { (var dict, elem) in
            if let curve = parseCurve(elem.1) {
                dict[elem.0] = curve
            }
            return dict
        }
    }
    
    private func parseCurve(curveData: AnyObject?) -> CurveData? {
        guard let curve = curveData else { return nil }
        guard let duration = curve["duration"] as? Double else { return nil }
        guard let startTime = curve["startTime"] as? Double else { return nil }
        guard let rawFrames = curve["frameData"] as? [AnyObject] else { return nil }
        let frames = rawFrames.map { parseFrame($0) }
        
        return CurveData(frames: frames, duration: duration, startTime: startTime, begin: frames.first!.values)
    }
    
    private func parseFrame(frameData: AnyObject?) -> FrameData {
        var time : Double = 0.0
        var values : [Double] = []
        
        if let frame = frameData {
            time = frame["t"] as? Double ?? time
            values = frame["val"] as? [Double] ?? values
        }
        return FrameData(time: time, values: values)
    }
    
//    public func initialTransform(options:[(String, Property, [String:AnyObject]?)]) -> CATransform3D {
//        var transforms = [CATransform3D]()
//        for (name, prop, opt) in options {
//            guard let curve = curves[name] else { continue }
//            var center = CGPointZero
//            if opt != nil {
//                if let centerOpt = opt["center"] {
//                    center = centerOpt
//                }
//            }
//        }
//        
//        // Merge
//        var transform = CATransform3DIdentity
//        for trans in transforms {
//            transform = CATransform3DConcat(transform, trans)
//        }
//        return transform
//    }
    
    public func animation(name:String, ofProperty prop:Property) -> CAAnimation? {
        return animation(name, ofProperty: prop, center: CGPointZero)
    }
    
    public func animation(name:String, ofProperty prop:Property, center: CGPoint) -> CAAnimation? {
        guard let curve = curves[name] else { return nil }
        
        let startTime = curve.startTime / 1000.0
        let duration = curve.duration / 1000.0
        
        
        if prop == .Scale {
            let combinedAnim = CAAnimationGroup()
            combinedAnim.animations = []
            combinedAnim.duration = max(duration + startTime, (curve.frames.last?.time ?? 0) / 1000.0)
            for (idx, keyPath) in ["transform.scale.x", "transform.scale.y", "transform.scale.z"].enumerate() {
                let anim = CAKeyframeAnimation(keyPath: keyPath)
                anim.cumulative = false
                anim.duration = max(duration + startTime, (curve.frames.last?.time ?? 0) / 1000.0)
                anim.keyTimes = curve.frames.map { ($0.time / 1000.0) / anim.duration }
                anim.timingFunctions = curve.frames.map { _ in CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn) }
                anim.values = curve.frames.map { frame in
                    let factor = (frame.values[idx] ?? 100.0) / 100.0
                    return factor
                }
                // Add Initial delay
                anim.keyTimes?.insert(0, atIndex: 0)
                anim.timingFunctions?.insert(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn), atIndex: 0)
                anim.values?.insert(anim.values!.first!, atIndex: 0)
                
                combinedAnim.animations!.append(anim)
            }
            return combinedAnim
        } else {
            var keyPath = "transform"
            switch prop {
            case .Scale:
                keyPath = "transform.scale"
            case .Position:
                keyPath = "position"
            case .RotationX:
                keyPath = "transform.rotation.x"
            case .RotationY:
                keyPath = "transform.rotation.y"
            case .RotationZ:
                keyPath = "transform.rotation.z"
            }

            // Main Animations
            let anim = CAKeyframeAnimation(keyPath: keyPath)
            anim.duration = max(duration + startTime, (curve.frames.last?.time ?? 0) / 1000.0)
            anim.cumulative = false
            
            anim.keyTimes = curve.frames.map { ($0.time / 1000.0) / anim.duration }
            
            anim.timingFunctions = curve.frames.map { _ in CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn) }
            
            anim.values = curve.frames.map { animationValue($0, curve: curve, prop: prop, center: center) }
            
            // Add Initial delay
            anim.keyTimes?.insert(0, atIndex: 0)
            anim.timingFunctions?.insert(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn), atIndex: 0)
            anim.values?.insert(anim.values!.first!, atIndex: 0)
            
            return anim
        }
    }
    
    func animationValue(frame:FrameData, curve:CurveData, prop:Property, center: CGPoint) ->  AnyObject {
        switch prop {
        case .Scale:
            let x = (frame.values[0] ?? 100.0) / 100.0
            let y = (frame.values[1] ?? 100.0) / 100.0
            let z = (frame.values[2] ?? 100.0) / 100.0
            return NSValue(CATransform3D: CATransform3DMakeScale(CGFloat(x), CGFloat(y), CGFloat(z)))
        case .Position:
            // Make relative position
            let x = curve.begin[0] - (frame.values[0] ?? 0.0) + Double(center.x)
            let y = curve.begin[1] - (frame.values[1] ?? 0.0) + Double(center.y)
            return NSValue(CGPoint: CGPointMake(CGFloat(x), CGFloat(y)))
        case .RotationX, .RotationY, .RotationZ:
            let angle = frame.values.first! / 180.0 * M_PI
            return angle
        default:
            return NSValue()
        }
    }
}