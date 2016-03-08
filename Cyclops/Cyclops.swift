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
    case PositionX
    case PositionY
    case RotationX
    case RotationY
    case RotationZ
    case Opacity
    
    // Inner use only for now    
    case ScaleX
    case ScaleY
    case ScaleZ
}


public struct CurveData {
    public let frames : [FrameData]
    public let duration : Double
    public let startTime : Double
    public let begin: [Double]
}

public struct FrameData {
    public let time: Double
    public let values: [Double]
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
    
    public func curve(name:String) -> CurveData? {
        return curves[name]
    }
    
    public func animation(name:String, ofProperty prop:Property) -> CAAnimation? {
        return animation(name, ofProperty: prop, value: nil)
    }
    
    public func animation(name:String, ofProperty prop:Property, value: [String:AnyObject]?) -> CAAnimation? {
        guard let curve = curves[name] else { return nil }
        
        if prop == .Scale {
            let combinedAnim = CAAnimationGroup()
            combinedAnim.animations = [
                keyframeAnimation(curve, prop: .ScaleX, value: value),
                keyframeAnimation(curve, prop: .ScaleY, value: value),
                keyframeAnimation(curve, prop: .ScaleZ, value: value)
            ]
            combinedAnim.duration = (combinedAnim.animations?.first!.duration)!
            return combinedAnim
        } else {
            return keyframeAnimation(curve, prop: prop, value: value)
        }
    }
    
    func keyframeAnimation(curve:CurveData, prop:Property, value:[String:AnyObject]?) -> CAAnimation {
        var keyPath = "transform"
        switch prop {
        case .ScaleX:
            keyPath = "transform.scale.x"
        case .ScaleY:
            keyPath = "transform.scale.y"
        case .ScaleZ:
            keyPath = "transform.scale.z"
        case .Position:
            keyPath = "position"
        case .PositionX:
            keyPath = "position.x"
        case .PositionY:
            keyPath = "position.y"
        case .RotationX:
            keyPath = "transform.rotation.x"
        case .RotationY:
            keyPath = "transform.rotation.y"
        case .RotationZ:
            keyPath = "transform.rotation.z"
        case .Opacity:
            keyPath = "opacity"
        case .Scale:
            fatalError("please extract to .ScaleX, .ScaleY, .ScaleZ first.")
        }
        
        let startTime = curve.startTime / 1000.0
        let duration = curve.duration / 1000.0
        
        let anim = CAKeyframeAnimation(keyPath: keyPath)
        anim.duration = max(duration + startTime, curve.frames.last!.time / 1000.0)
        anim.cumulative = false
        
        // Add Keypoints
        anim.keyTimes = curve.frames.map { ($0.time / 1000.0) / anim.duration }
        anim.timingFunctions = curve.frames.map { _ in CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn) }
        anim.values = curve.frames.map { animationValue($0, curve: curve, prop: prop, value: value) }
        
        // Add Initial delay
        anim.keyTimes?.insert(0, atIndex: 0)
        anim.timingFunctions?.insert(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn), atIndex: 0)
        anim.values?.insert(anim.values!.first!, atIndex: 0)
        return anim
    }
    
    
    func animationValue(frame:FrameData, curve:CurveData, prop:Property, value: [String:AnyObject]?) ->  AnyObject {
        switch prop {
        case .ScaleX:
            return (frame.values[0] ?? 100.0) / 100.0
        case .ScaleY:
            return (frame.values[1] ?? 100.0) / 100.0
        case .ScaleZ:
            return (frame.values[2] ?? 100.0) / 100.0
        case .Position:
            var initialX = 0.0
            var initialY = 0.0
            if let center = (value?["initial"] as? NSValue)?.CGPointValue() {
                initialX = Double(center.x)
                initialY = Double(center.y)
            }
            // Make relative position
            let x = (frame.values[0] ?? 0.0) - curve.begin[0] + initialX
            let y = (frame.values[1] ?? 0.0) - curve.begin[1] + initialY
            return NSValue(CGPoint: CGPointMake(CGFloat(x), CGFloat(y)))
        case .PositionX, .PositionY:
            var initial = 0.0
            if let pos = (value?["initial"] as? NSNumber)?.doubleValue {
                initial = pos
            }
            return (frame.values[0] ?? 0.0) - curve.begin[0] + initial
        case .RotationX, .RotationY, .RotationZ:
            let angle = frame.values.first! / 180.0 * M_PI * -1
            let adjust = value?["initialRotation"] as? Double ?? 0.0
            let invert = value?["invert"] as? Bool ?? false
            return angle * (invert ? -1 : 1) + adjust
        case .Opacity:
            return frame.values[0] / 100.0
        case .Scale:
            fatalError("please extract to .ScaleX, .ScaleY, .ScaleZ first.")
        }
    }
}