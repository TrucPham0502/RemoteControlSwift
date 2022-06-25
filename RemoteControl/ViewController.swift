//
//  ViewController.swift
//  RemoteControl
//
//  Created by Truc Pham on 21/06/2022.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let remote = RemoteControl()
        remote.frame = UIScreen.main.bounds
        remote.backgroundColor = .orange
        remote.delegate = self
        remote.initial()
        self.view.addSubview(remote)
        
        // Do any additional setup after loading the view.
    }
    
    
}
extension ViewController : RemoteControlDelegate {
    func remoteControl(_ view: RemoteControl, direction: RemoteControl.Direction) {
        print(direction)
    }
}


protocol RemoteControlDelegate : AnyObject {
    func remoteControl(_ view : RemoteControl, direction : RemoteControl.Direction)
}
class RemoteControl : UIControl {
    enum Direction {
        case corner1, corner2, corner3, corner4, none
    }
    weak var delegate : RemoteControlDelegate?
    var direction : Direction = .none {
        didSet {
            guard oldValue != direction else { return }
            delegate?.remoteControl(self, direction: direction)
            controlDirection4.color = direction == .corner4 ? selectedColor : color
            controlDirection2.color = direction == .corner2 ? selectedColor : color
            controlDirection3.color = direction == .corner3 ? selectedColor : color
            controlDirection1.color = direction == .corner1 ? selectedColor : color
            
            controlDirection4.imageColor = direction == .corner4 ? imageDirectionSelectedColor : imageDirectionColor
            controlDirection2.imageColor = direction == .corner2 ? imageDirectionSelectedColor : imageDirectionColor
            controlDirection3.imageColor = direction == .corner3 ? imageDirectionSelectedColor : imageDirectionColor
            controlDirection1.imageColor = direction == .corner1 ? imageDirectionSelectedColor : imageDirectionColor
            
        }
    }
    private(set) var isStartDrag : Bool = false
    var controlDirectionPadding : CGFloat = 2
    var outRadius : CGFloat = 100
    fileprivate var circleCenterRadius : CGFloat = 40
    fileprivate var scaleCircleCenter : CGFloat = 1.8
    fileprivate var startAngle : CGFloat = 45
    var color : UIColor = .black
    var circleCenterColor : UIColor = .black
    var circleCenterSelectedColor : UIColor = .black
    var selectedColor : UIColor = .white
    var imageDirectionSelectedColor : UIColor = .black
    var imageDirectionColor : UIColor = .white
    var lineWidth : CGFloat = 50
    var imageDirection : UIImage?
    fileprivate lazy var controlDirection4 : ControlDirectionLayer = {
        let start = abs(controlDirection3.endAngle) + controlDirectionPadding
        let end = start + 90 - controlDirectionPadding
        let l = ControlDirectionLayer(center: .zero, radius: outRadius, startAngle: -start , endAngle: -end, width: lineWidth, image: imageDirection, padding: controlDirectionPadding)
        l.color = color
        l.imageColor = imageDirectionColor
        return l
    }()
    
    fileprivate lazy var controlDirection2 : ControlDirectionLayer = {
        let start = abs(controlDirection1.endAngle) + controlDirectionPadding
        let end = start + 90 - controlDirectionPadding
        let l = ControlDirectionLayer(center: .zero, radius: outRadius, startAngle: -start , endAngle: -end, width: lineWidth,image: imageDirection, padding: controlDirectionPadding)
        l.color = color
        l.imageColor = imageDirectionColor
        return l
    }()
    
    fileprivate lazy var controlDirection3 : ControlDirectionLayer = {
        let start = abs(controlDirection2.endAngle) + controlDirectionPadding
        let end = start + 90 - controlDirectionPadding
        let l = ControlDirectionLayer(center: .zero, radius: outRadius, startAngle: -start , endAngle: -end, width: lineWidth,image: imageDirection, padding: controlDirectionPadding)
        l.color = color
        l.imageColor = imageDirectionColor
        return l
    }()
    
    fileprivate lazy var controlDirection1 : ControlDirectionLayer = {
        let start = startAngle + controlDirectionPadding
        let end = start + 90 - controlDirectionPadding
        let l = ControlDirectionLayer(center: .zero, radius: outRadius, startAngle: -start , endAngle: -end, width: lineWidth, image: imageDirection, padding: controlDirectionPadding)
        l.color = color
        l.imageColor = imageDirectionColor
        return l
    }()
    
    
    fileprivate lazy var circleCenter : CAShapeLayer = {
        let l = CAShapeLayer()
        l.fillColor = circleCenterColor.cgColor
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initial(){
        prepareUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let superView = self.superview else { return }
        circleCenterRadius = (self.outRadius - (lineWidth / 2)) / scaleCircleCenter
        let center = superView.convert(self.center, to: self)
        controlDirection4.center = center
        controlDirection3.center = center
        controlDirection2.center = center
        controlDirection1.center = center
        updateLocationCircleCenter(center: center)
    }
    fileprivate func prepareUI(){
        layer.addSublayer(controlDirection4)
        layer.addSublayer(controlDirection3)
        layer.addSublayer(controlDirection2)
        layer.addSublayer(controlDirection1)
        layer.addSublayer(circleCenter)
    }
    
    fileprivate func updateLocationCircleCenter(center : CGPoint) {
        let cirleCenterBezierPath = UIBezierPath(arcCenter: center, radius: circleCenterRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: false)
        circleCenter.path = cirleCenterBezierPath.cgPath
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        isStartDrag = self.circleCenter.path?.contains(location) ?? false
        if !isStartDrag {
            if controlDirection4.touchConstaints(location: location) { self.direction = .corner4 }
            else if controlDirection2.touchConstaints(location: location) { self.direction = .corner2 }
            else if controlDirection3.touchConstaints(location: location) { self.direction = .corner3 }
            else if controlDirection1.touchConstaints(location: location) { self.direction = .corner1 }
            else { self.direction = .none }
        }
        sendActions(for: .touchDown)
        return super.beginTracking(touch, with: event)
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if isStartDrag, let superView = self.superview {
            let center = superView.convert(self.center, to: self)
            var location = touch.location(in: self)
            let distance = center.distance(to:location)
            if distance > (self.outRadius - (lineWidth/2) - circleCenterRadius) {
                let k = (self.outRadius - (lineWidth/2) - circleCenterRadius) / distance
                let newLocationX = (location.x - center.x) * k + center.x
                let newLocationY = (location.y - center.y) * k + center.y
                location = CGPoint(x: newLocationX, y: newLocationY)
                updateLocationCircleCenter(center: location)
            }else{
                updateLocationCircleCenter(center:location)
            }
            if controlDirection4.dragConstaints(location: location) { self.direction = .corner4 }
            else if controlDirection2.dragConstaints(location: location) { self.direction = .corner2 }
            else if controlDirection3.dragConstaints(location: location) { self.direction = .corner3 }
            else if controlDirection1.dragConstaints(location: location) { self.direction = .corner1 }
            else { self.direction = .none }
            self.circleCenter.fillColor = circleCenterSelectedColor.cgColor
            sendActions(for:.valueChanged)
        }
        return super.continueTracking(touch, with: event)
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if isStartDrag, let superView = self.superview {
            updateLocationCircleCenter(center: superView.convert(self.center, to: self))
            isStartDrag = false
        }
        if direction != .none { direction = .none }
        self.circleCenter.fillColor = circleCenterColor.cgColor
        sendActions(for: .touchUpInside)
        super.endTracking(touch, with: event)
    }

    
}


class ControlDirectionLayer : CALayer {
    fileprivate let oneAngle = CGFloat.pi/180
    var startAngle : CGFloat
    var endAngle : CGFloat
    fileprivate var radius : CGFloat
    fileprivate var width : CGFloat
    fileprivate var image : UIImage?
    fileprivate var padding : CGFloat
    var imageSize : CGSize = .init(width: 15, height: 25) {
        didSet {
            imageLayer.frame.size = imageSize
        }
    }
    var center : CGPoint = .zero {
        didSet {
            drawLayout()
        }
    }
    var color : UIColor = UIColor.black {
        didSet {
            circularLayer?.strokeColor = color.cgColor
        }
    }
    
    var imageColor : UIColor = UIColor.white {
        didSet {
            imageLayer.backgroundColor = imageColor.cgColor
        }
    }
    
    fileprivate var overlayLayer : CAShapeLayer?
    fileprivate var circularLayer : CAShapeLayer?
    
    init(center : CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, width : CGFloat = 50, image: UIImage? = nil, padding: CGFloat = 0) {
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.center = center
        self.radius = radius
        self.width = width
        self.image = image
        self.padding = padding
        super.init()
        drawLayout()
    }
    fileprivate let imageMaskLayer = CALayer()
    fileprivate lazy var imageLayer : CAShapeLayer = {
        let l = CAShapeLayer()
        l.backgroundColor = imageColor.cgColor
        l.frame.size = imageSize
        return l
    }()
    
    fileprivate func createOverlayLayer() -> CAShapeLayer {
        let circularPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: (startAngle + padding) * oneAngle, endAngle: (endAngle - padding) * oneAngle, clockwise: false)
        circularPath.addLine(to: center)
        circularPath.close()
        let shape = CAShapeLayer()
        shape.path = circularPath.cgPath
        shape.fillColor = UIColor.clear.cgColor
        shape.lineCap = CAShapeLayerLineCap.butt
        return shape
    }
    
    fileprivate func createCircularLayer() -> CAShapeLayer {
        let circularPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle * oneAngle, endAngle: endAngle * oneAngle, clockwise: false)
       
        let shape = CAShapeLayer()
        shape.path = circularPath.cgPath
        shape.strokeColor = color.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.lineCap = CAShapeLayerLineCap.butt
        shape.lineWidth = width
        circularPath.close()
        
        //Image
        imageLayer.removeFromSuperlayer()
        let centerAngle = (startAngle + endAngle + padding) / 2
        let circlePathImage = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle * oneAngle, endAngle: centerAngle * oneAngle, clockwise: false)
        let tinImage = image?.withRenderingMode(.alwaysTemplate)
        imageMaskLayer.frame = imageLayer.bounds
        imageMaskLayer.contents = tinImage?.cgImage
        imageLayer.mask = imageMaskLayer
        imageLayer.backgroundColor = imageColor.cgColor
        imageLayer.position = circlePathImage.currentPoint
        imageLayer.transform = CATransform3DMakeRotation(centerAngle * oneAngle, 0, 0, 1)
        shape.addSublayer(imageLayer)
        
        return shape
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func drawLayout(){
        overlayLayer?.removeFromSuperlayer()
        circularLayer?.removeFromSuperlayer()
        overlayLayer = createOverlayLayer()
        circularLayer = createCircularLayer()
        
        [overlayLayer!, circularLayer!].forEach(self.addSublayer(_:))
        
    }
    
    func dragConstaints(location : CGPoint) -> Bool {
        guard let path = overlayLayer?.path else {
            return false
        }
        return path.contains(location)
    }
    
    func touchConstaints(location : CGPoint) -> Bool {
        guard let circularLayer = self.circularLayer, let path = circularLayer.path else {
            return false
        }
        let outline = path.copy(strokingWithWidth: width, lineCap: .butt, lineJoin: .round, miterLimit: 0)
        return path.contains(location) || outline.contains(location)
    }
}

fileprivate extension CGPoint {
    func distance(to : CGPoint) -> CGFloat {
        return sqrt(((to.x - x) * (to.x - x)) + ((to.y - y) * (to.y - y)))
    }
}
