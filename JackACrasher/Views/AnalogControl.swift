/*
* Copyright (c) 2013-2014 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit

@objc protocol AnalogControlPositionChange {
  func analogControlPositionChanged(
    analogControl: AnalogControl, position: CGPoint)
}


class AnalogControl: UIView {

  var baseCenter: CGPoint = CGPointZero
  var relativePosition: CGPoint! = CGPointZero
  
  @IBOutlet weak var knobImageView: UIImageView!
  @IBOutlet weak var delegate: AnalogControlPositionChange?
 
  
    
  override init(frame viewFrame: CGRect) {
    
    //1
    baseCenter = CGPoint(x: viewFrame.size.width/2,
      y: viewFrame.size.height/2)
    
    //2
    knobImageView = UIImageView(image: UIImage(named: "knob"))
    knobImageView.bounds.size.width /= 2
    knobImageView.bounds.size.height /= 2
    knobImageView.center = baseCenter
    
    super.init(frame: viewFrame)
    
    //3
    userInteractionEnabled = true
    
    //4
    let baseImageView = UIImageView(frame: bounds)
    baseImageView.image = UIImage(named: "base")
    addSubview(baseImageView)
    
    //5
    addSubview(knobImageView)
    
    //6
    assert(CGRectContainsRect(bounds, knobImageView.bounds),
      "Analog control should be larger than the knob in size")
  } 

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
    
    override func layoutSubviews() {
         super.layoutSubviews()
        
        baseCenter = self.knobImageView.center
    }
    

    
    

  func updateKnobWithPosition(position:CGPoint) {
    //1
    var positionToCenter = position - baseCenter
    var direction: CGPoint
    
    if positionToCenter == CGPointZero {
      direction = CGPointZero
    } else {
      direction = positionToCenter.normalized()
    }
    
    //2
    let radius = frame.size.width/2
    var length = positionToCenter.length()
    
    //3
    if length > radius {
      length = radius
      positionToCenter = direction * radius
    }
    
    let relPosition = CGPoint(x: direction.x * (length/radius),
      y: direction.y * (length/radius))

    knobImageView.center = baseCenter + positionToCenter
    relativePosition = relPosition

    delegate?.analogControlPositionChanged(self,
      position: relativePosition)

  }

  //MARK: UI Tougch responder
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        if (touches.count == 0) {
            if let next = nextResponder() {
                next.touchesBegan(touches, withEvent: event)
                return
            }
        }
        
        let touchLocation = (touches.first as? UITouch)!.locationInView(self)
        updateKnobWithPosition(touchLocation)
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        if (touches.count == 0) {
            if let next = nextResponder() {
                next.touchesMoved(touches, withEvent: event)
                return
            }
        }
        
        let touchLocation = (touches.first as? UITouch)!.locationInView(self)
        updateKnobWithPosition(touchLocation)
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
       updateKnobWithPosition(baseCenter)
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        updateKnobWithPosition(self.baseCenter)
    }
    
}
