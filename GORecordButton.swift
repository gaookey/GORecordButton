//
//  GORecordButton.swift
//  GORecordButton
//
//  Created by 高文立 on 2020/6/28.
//

import UIKit

@objc enum GORecordType: Int {
    case click
    case longPressBegin
    case longPressMoving
    case longPressDone
    case longPressCancel
}

@objc protocol GORecordButtonDelegate: AnyObject {
    
    @objc optional func button(_ button: GORecordButton, shouldChangeRecordType type: GORecordType, isDismissHandler: ((_ dismiss: Bool) -> ())?)
}

@objcMembers public class GORecordButton: UIView {
    
    weak var delegate: GORecordButtonDelegate?
    
    var timeInterval: CGFloat = 15
    var outCircleColor = UIColor.lightGray
    var centerCircleColor = UIColor.white
    var progressColor = UIColor.orange
    
    var outCircleNormalScale: CGFloat = 0.8
    var centerCircleNormalScale: CGFloat = 0.5
    var centerCircleProgressingScale: CGFloat = 0.3
    var progressWidthScale: CGFloat = 0.1
    
    private var tempInterval: CGFloat = 0
    private var progress: CGFloat = 0
    private var isProgress = false
    private var isCancel = false
    
    lazy var link: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(runlink))
        link.preferredFramesPerSecond = 60
        link.add(to: RunLoop.current, forMode: .default)
        link.isPaused = true
        return link
    }()
    
    private lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.fillColor = backgroundColor?.cgColor
        return layer
    }()
    
    private lazy var outCircle = CAShapeLayer()
    private lazy var centerCircle = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.width))
        
        backgroundColor = .clear
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        
        var outCircleRadius: CGFloat = 0
        var centerCircleRadius: CGFloat = 0
        if isProgress {
            outCircleRadius = bounds.size.width / 2
            centerCircleRadius = bounds.size.width * centerCircleProgressingScale / 2
        } else {
            outCircleRadius = bounds.size.width * outCircleNormalScale / 2
            centerCircleRadius = bounds.size.width * centerCircleNormalScale / 2
        }
        
        let outCirclePath = UIBezierPath(arcCenter: CGPoint(x: bounds.size.width / 2, y: bounds.size.width / 2), radius: outCircleRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        outCircle.path = outCirclePath.cgPath
        
        let centerCirclePath = UIBezierPath(arcCenter: CGPoint(x: centerCircle.frame.size.width / 2, y: centerCircle.frame.size.width / 2), radius: centerCircleRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        centerCircle.path = centerCirclePath.cgPath
        
        let path = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: bounds.size.width / 2, y: bounds.size.width / 2), radius: bounds.size.width / 2 * (1 - progressWidthScale / 2), startAngle: -.pi / 2, endAngle: .pi / 2 * 3, clockwise: true)
        progressLayer.path = path.cgPath
        progressLayer.strokeEnd = progress
    }
    
    public override func layoutSubviews() {
        
        layer.cornerRadius = frame.size.width / 2
        layer.masksToBounds = true
        
        outCircle.frame = self.bounds
        centerCircle.frame = self.bounds
        
        outCircle.fillColor = self.outCircleColor.cgColor
        centerCircle.fillColor = self.centerCircleColor.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        
        progressLayer.lineWidth = bounds.size.width * progressWidthScale / 2
    }
    
    deinit {
        print("GORecordButton deinit")
    }
}

extension GORecordButton {
    
    func setupUI() {
        
        layer.addSublayer(outCircle)
        layer.addSublayer(centerCircle)
        layer.addSublayer(progressLayer)
        
        self.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:))))
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:))))
    }
    
    @objc func tapGesture(_ gesture: UILongPressGestureRecognizer) {
        
        self.delegate?.button?(self, shouldChangeRecordType: .click, isDismissHandler: { [weak self] (dismiss) in
            if dismiss {
                self?.link.invalidate()
            }
        })
    }
    
    @objc func longPressGesture(_ gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .began {
            
            start()
        } else if gesture.state == .changed {
            let point: CGPoint = gesture.location(in: self)
            if self.point(inside: point, with: nil) {
                self.delegate?.button?(self, shouldChangeRecordType: .longPressMoving, isDismissHandler: { [weak self] (dismiss) in
                    if dismiss {
                        self?.link.invalidate()
                    }
                })
            } else {
                if !isCancel {
                    stop(.longPressCancel)
                }
            }
        } else if gesture.state == .ended {
            if !isCancel {
                stop(.longPressDone)
            }
        } else if gesture.state == .cancelled {
            if !isCancel {
                stop(.longPressCancel)
            }
        }
    }
    
    @objc func runlink() {
        
        guard tempInterval <= timeInterval else {
            stop(.longPressDone)
            return
        }
        
        tempInterval += 1 / 60
        progress = tempInterval / timeInterval
        setNeedsDisplay()
    }
    
    func stop(_ type: GORecordType) {
        
        if type == .longPressCancel {
            isCancel = true
        }
        
        link.isPaused = true
        isProgress = false
        progress = 0
        tempInterval = 0
        progressLayer.isHidden = true
        self.delegate?.button?(self, shouldChangeRecordType: type, isDismissHandler: { [weak self] (dismiss) in
            if dismiss {
                self?.link.invalidate()
            }
        })
        setNeedsDisplay()
    }
    
    func start() {
        
        isCancel = false
        isProgress = true
        progressLayer.isHidden = false
        link.isPaused = false
        
        self.delegate?.button?(self, shouldChangeRecordType: .longPressBegin, isDismissHandler: { [weak self] (dismiss) in
            if dismiss {
                self?.link.invalidate()
            }
        })
    }
}
