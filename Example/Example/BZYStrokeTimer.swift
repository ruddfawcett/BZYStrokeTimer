//
//  BZYStrokeTimer.swift
//  Example
//
//  Created by Rudd Fawcett on 4/28/20.
//

import UIKit

protocol BZYStrokeTimerDelegate {
    func timer(willStart: BZYStrokeTimer)
    func timer(didStart: BZYStrokeTimer)
    
    func timer(willPause: BZYStrokeTimer)
    func timer(didPause: BZYStrokeTimer)
    
    func timer(willResume: BZYStrokeTimer)
    func timer(didResume: BZYStrokeTimer)
    
    func timer(willStop: BZYStrokeTimer)
    func timer(didStop: BZYStrokeTimer)
    
    func timer(timer: BZYStrokeTimer, didAdvance withProgress: CGFloat)
    
    func timer(shouldStart: BZYStrokeTimer) -> Bool
    func timer(shouldPause: BZYStrokeTimer) -> Bool
    func timer(shouldResume: BZYStrokeTimer) -> Bool
}

@IBDesignable
class BZYStrokeTimer: UIView {
    private let defaultLineWidth: CGFloat = 10
    private let defaultDuration: CGFloat = 5
    
    private var shapeLayer: CAShapeLayer!
    private var animationTimer: Timer!
    
    public var clockwise: Bool = true

    private var _unwinds: Bool = true
    public var unwinds: Bool {
        get {
            return self._unwinds
        }
        set {
            if newValue == self.unwinds {
                return
            }
            
            self._unwinds = newValue
            self.shapeLayer.strokeEnd = newValue ? 1 : 0
        }
    }

    public var delegate: BZYStrokeTimerDelegate?
    
    private var elapsedTime: TimeInterval = 0
    
    public var duration: TimeInterval!
    public var running: Bool = false
    public var paused: Bool = false
    
    private var timingFunction: CAMediaTimingFunctionName {
        get {
            return CAMediaTimingFunctionName.easeInEaseOut
        }
    }
    
    private var _lineWidth: CGFloat = 10
    @IBInspectable public var lineWidth: CGFloat {
        get {
            return self._lineWidth
        }
        
        set {
            self._lineWidth = newValue
            self.shapeLayer.lineWidth = newValue
        }
    }
    
    private var _timerColor: UIColor = .black
    @IBInspectable public var timerColor: UIColor {
        get {
            return self._timerColor
        }
        set {
            self._timerColor = newValue
            self.shapeLayer.strokeColor = newValue.cgColor
        }
    }
    
    @IBInspectable public var progress: CGFloat {
        get {
            return self.shapeLayer.strokeEnd
        }
        set {
            if newValue >= 1 {
                self.shapeLayer.strokeEnd = 1
            } else if progress <= 0 {
                self.shapeLayer.strokeEnd = 0
            } else {
                self.shapeLayer.strokeEnd = progress
            }
        }
    }
    
    private var animationCompletion: CGFloat {
        let percentage: CGFloat = CGFloat(self.elapsedTime / self.duration)
        
        if percentage == 1 || percentage >= 1 {
            self.animationTimer.invalidate()
            self.animationTimer = nil
            self.stop()
            return 1
        } else if percentage <= 0 {
            return 0
        } else {
            return percentage
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    func setup() {
        self.shapeLayer = CAShapeLayer()
        self.shapeLayer.lineWidth = self.defaultLineWidth
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        self.shapeLayer.strokeColor = UIColor.black.cgColor
        self.shapeLayer.lineCap = .butt
        self.shapeLayer.frame = self.bounds
        self.shapeLayer.strokeStart = 0
        self.shapeLayer.strokeEnd = 1
        
        self.clockwise = true
        self.unwinds = false
        
        self.layer.addSublayer(self.shapeLayer)
    }
    
    func start() {
        if let _delegate = self.delegate {
            guard _delegate.timer(shouldStart: self) else {
                return
            }
        }
        
        self.delegate?.timer(willStart: self)
        
        self.running = true
        self.paused = false
        
        self.animationTimer = Timer(timeInterval: 0.01, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        self.shapeLayer.strokeEnd = 1.0
        let keypath = self.unwinds ? "strokeStart" : "strokeEnd"
        let wind: CABasicAnimation = self.generateAnimation(duration: self.duration == 0 ? TimeInterval(self.defaultDuration) : self.duration, fromValue: Int(self.shapeLayer.strokeStart), toValue: Int(self.shapeLayer.strokeEnd), keypath: keypath, fillMode: CAMediaTimingFillMode.both)
        wind.timingFunction = CAMediaTimingFunction(name: self.timingFunction)
        wind.isRemovedOnCompletion = false
        self.shapeLayer.path = self.generatePath(withXInset: self.lineWidth, yInset: self.lineWidth, clockWise: self.clockwise).cgPath
        self.shapeLayer.add(wind, forKey: "strokeEndAnimation")
        
        self.delegate?.timer(didStart: self)
    }
    
    func pause() {
        if let _delegate = self.delegate {
            guard _delegate.timer(shouldPause: self) else {
                return
            }
        }
        
        self.delegate?.timer(willPause: self)
        
        let pausedTime: TimeInterval = self.shapeLayer.convertTime(CACurrentMediaTime(), from: nil)
        self.shapeLayer.speed = 0
        self.shapeLayer.timeOffset = pausedTime
        
        self.paused = true
        self.running = false
        
        self.delegate?.timer(didPause: self)
    }
    
    func resume() {
        if let _delegate = self.delegate {
            guard _delegate.timer(shouldResume: self) else {
                return
            }
        }
        
        self.delegate?.timer(willResume: self)
        
        let pausedTime: TimeInterval = self.shapeLayer.timeOffset
        self.shapeLayer.speed = 1
        self.shapeLayer.timeOffset = 0
        self.shapeLayer.beginTime = 0.0
        
        let timeSincePause = self.shapeLayer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        self.shapeLayer.beginTime = timeSincePause
        
        self.paused = false
        self.running = true
        
        self.delegate?.timer(didResume: self)
    }
    
    func stop() {
        self.delegate?.timer(willStop: self)
        
        self.running = false
        self.paused = false
        self.elapsedTime = 0.0
        
        self.delegate?.timer(didStop: self)
    }
    
    override var intrinsicContentSize: CGSize {
        return self.shapeLayer.bounds.size
    }
    
    private func generateAnimation(duration: TimeInterval, fromValue: Int, toValue: Int, keypath: String, fillMode: CAMediaTimingFillMode) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keypath)
        animation.duration = duration
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.fillMode = fillMode
        
        return animation
    }
    
    private func generatePath(withXInset dx: CGFloat, yInset dy: CGFloat, clockWise: Bool) -> UIBezierPath {
        let path = UIBezierPath.init()
        path.move(to: CGPoint(x: self.bounds.midX, y: dy/2))
        path.addLine(to: CGPoint(x: self.bounds.maxX - dx/2, y: dy/2))
        path.addLine(to: CGPoint(x: self.bounds.maxX - dx/2, y: self.bounds.maxY - dy/2))
        path.addLine(to: CGPoint(x: dx/2, y: self.bounds.maxY - dy/2))
        path.addLine(to: CGPoint(x: dx/2, y: dy/2))
        path.addLine(to: CGPoint(x: self.bounds.midX, y: dy/2))
        path.close()

        return self.clockwise ? path : path.reversing()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.shapeLayer.path = self.generatePath(withXInset: self.shapeLayer.lineWidth, yInset: self.shapeLayer.lineWidth, clockWise: self.clockwise).cgPath
    }
    
    @objc func timerFired(sender: Any) {
        if !self.paused {
            self.elapsedTime += 0.01
        }
        
        if self.animationCompletion == 1 || self.elapsedTime >= self.duration {
            self.animationTimer.invalidate()
            self.animationTimer = nil
            self.stop()
        }
        
        if !self.paused {
            self.delegate?.timer(timer: self, didAdvance: self.animationCompletion)
        }
    }
}
