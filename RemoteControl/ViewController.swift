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
        case left, right, bottom, top, none
    }
    weak var delegate : RemoteControlDelegate?
    var direction : Direction = .none {
        didSet {
            delegate?.remoteControl(self, direction: direction)
            controlDirectionLeft.color = direction == .left ? selectedColor : color
            controlDirectionRight.color = direction == .right ? selectedColor : color
            controlDirectionBottom.color = direction == .bottom ? selectedColor : color
            controlDirectionTop.color = direction == .top ? selectedColor : color
            
        }
    }
    fileprivate var isStart : Bool = false
    var controlDirectionPadding : CGFloat = 2
    let radius : CGFloat = 100
    let circleCenterRadius : CGFloat = 100 - 65
    var color : UIColor = .black
    var selectedColor : UIColor = .white
    fileprivate lazy var controlDirectionLeft : ControlDirectionLayer = {
        let start = abs(controlDirectionBottom.endAngle) + controlDirectionPadding
        let end = start + 90 - controlDirectionPadding
        let l = ControlDirectionLayer(center: .zero, radius: radius, startAngle: -start , endAngle: -end)
        l.color = color
        return l
    }()
    
    fileprivate lazy var controlDirectionRight : ControlDirectionLayer = {
        let start = abs(controlDirectionTop.endAngle) + controlDirectionPadding
        let end = start + 90 - controlDirectionPadding
        let l = ControlDirectionLayer(center: .zero, radius: radius, startAngle: -start , endAngle: -end)
        l.color = color
        return l
    }()
    
    fileprivate lazy var controlDirectionBottom : ControlDirectionLayer = {
        let start = abs(controlDirectionRight.endAngle) + controlDirectionPadding
        let end = start + 90 - controlDirectionPadding
        let l = ControlDirectionLayer(center: .zero, radius: radius, startAngle: -start , endAngle: -end)
        l.color = color
        return l
    }()
    
    fileprivate lazy var controlDirectionTop : ControlDirectionLayer = {
        let start = 45 + controlDirectionPadding
        let end = start + 90 - controlDirectionPadding
        let l = ControlDirectionLayer(center: .zero, radius: radius, startAngle: -start , endAngle: -end)
        l.color = color
        return l
    }()
    
    
    fileprivate lazy var circleCenter : CAShapeLayer = {
        let l = CAShapeLayer()
        l.fillColor = color.cgColor
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        controlDirectionLeft.center = self.center
        controlDirectionBottom.center = self.center
        controlDirectionRight.center = self.center
        controlDirectionTop.center = self.center
        updateLocationCircleCenter(center: self.center)
    }
    fileprivate func prepareUI(){
        layer.addSublayer(controlDirectionLeft)
        layer.addSublayer(controlDirectionBottom)
        layer.addSublayer(controlDirectionRight)
        layer.addSublayer(controlDirectionTop)
        layer.addSublayer(circleCenter)
    }
    
    fileprivate func updateLocationCircleCenter(center : CGPoint) {
        let cirleCenterBezierPath = UIBezierPath(arcCenter: center, radius: circleCenterRadius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: false)
        circleCenter.path = cirleCenterBezierPath.cgPath
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        isStart = self.circleCenter.path?.contains(touch.location(in: self)) ?? false
        return super.beginTracking(touch, with: event)
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard isStart else { return false }
        var location = touch.location(in: self)
        let distance = self.center.distance(to:location)
        if distance > (self.radius - circleCenterRadius) / 2 {
            let k = ((self.radius - circleCenterRadius) / 2) / distance
            let newLocationX = (location.x - center.x) * k + center.x
            let newLocationY = (location.y - center.y) * k + center.y
            location = CGPoint(x: newLocationX, y: newLocationY)
            updateLocationCircleCenter(center: location)
        }else{
            updateLocationCircleCenter(center:location)
        }
        if controlDirectionLeft.constaints(location: location) { self.direction = .left }
        else if controlDirectionRight.constaints(location: location) { self.direction = .right }
        else if controlDirectionBottom.constaints(location: location) { self.direction = .bottom }
        else if controlDirectionTop.constaints(location: location) { self.direction = .top }
        return super.continueTracking(touch, with: event)
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        updateLocationCircleCenter(center: self.center)
        isStart = false
        direction = .none
        super.endTracking(touch, with: event)
    }
    
    
}


class ControlDirectionLayer : CALayer {
    let oneAngle = CGFloat.pi/180
    var startAngle : CGFloat
    var endAngle : CGFloat
    var radius : CGFloat
    var width : CGFloat
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
    
    fileprivate var overlayLayer : CAShapeLayer?
    fileprivate var circularLayer : CAShapeLayer?
    
    init(center : CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, width : CGFloat = 50) {
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.center = center
        self.radius = radius
        self.width = width
        super.init()
        drawLayout()
    }
    
    
    fileprivate lazy var imageLayer : CAShapeLayer = {
        let imageLayer = CAShapeLayer()
        imageLayer.backgroundColor = UIColor.clear.cgColor
        return imageLayer
    }()
    
    fileprivate func createOverlayLayer() -> CAShapeLayer {
        let circularPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle * oneAngle, endAngle: endAngle * oneAngle, clockwise: false)
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
        return shape
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func drawLayout(){
        overlayLayer?.removeFromSuperlayer()
        circularLayer?.removeFromSuperlayer()
        imageLayer.removeFromSuperlayer()
        overlayLayer = createOverlayLayer()
        circularLayer = createCircularLayer()
        
        let image = UIImage(systemName: "chevron.right")
        let x = sin(startAngle + 45)*radius
        let y = sqrt(x*x + radius*radius)
        imageLayer.frame = .init(origin: center, size: .init(width: radius, height: radius))
        let maskLayer = CALayer()
        maskLayer.frame = imageLayer.bounds
        maskLayer.contents = image?.cgImage
        imageLayer.mask = maskLayer
        imageLayer.backgroundColor = UIColor.white.cgColor
//        imageLayer.position = overlayLayer!.position
        print("canh x: \(x)")
        imageLayer.position = .init(x: x, y: y)
        
        
        [overlayLayer!, circularLayer!, imageLayer].forEach(self.addSublayer(_:))
        
    }
    
    func constaints(location : CGPoint) -> Bool {
        guard let path = overlayLayer?.path else {
            return false
        }
        return path.contains(location)
    }
}

extension CGPoint {
    func distance(to : CGPoint) -> CGFloat {
        return sqrt(((to.x - x) * (to.x - x)) + ((to.y - y) * (to.y - y)))
    }
}
