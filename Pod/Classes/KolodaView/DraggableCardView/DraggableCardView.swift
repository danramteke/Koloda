//
//  DraggableCardView.swift
//  TinderCardsSwift
//
//  Created by Eugene Andreyev on 4/23/15.
//  Copyright (c) 2015 Yalantis. All rights reserved.
//

import UIKit
import pop

protocol DraggableCardDelegate: class {
    
    func cardDraggedWithFinishPercent(_ card: DraggableCardView, percent: CGFloat)
    func cardSwippedInDirection(_ card: DraggableCardView, direction: SwipeResultDirection)
    func cardWasReset(_ card: DraggableCardView)
    func cardTapped(_ card: DraggableCardView)
    
}

//Drag animation constants
private let rotationMax: CGFloat = 1.0
private let defaultRotationAngle = CGFloat(M_PI) / 10.0
private let scaleMin: CGFloat = 0.8
public let cardSwipeActionAnimationDuration: TimeInterval  = 0.4

//Reset animation constants
private let cardResetAnimationSpringBounciness: CGFloat = 10.0
private let cardResetAnimationSpringSpeed: CGFloat = 20.0
private let cardResetAnimationKey = "resetPositionAnimation"
private let cardResetAnimationDuration: TimeInterval = 0.2

public class DraggableCardView: UIView {
    
    weak var delegate: DraggableCardDelegate?
    
    private var overlayView: OverlayView?
    private var contentView: UIView?
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var originalLocation: CGPoint = CGPoint(x: 0.0, y: 0.0)
    private var animationDirection: CGFloat = 1.0
    private var dragBegin = false
    private var xDistanceFromCenter: CGFloat = 0.0
    private var yDistanceFromCenter: CGFloat = 0.0
    private var actionMargin: CGFloat = 0.0
    private var firstTouch = true
    
    //MARK: Lifecycle
    init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    override public var frame: CGRect {
        didSet {
            actionMargin = frame.size.width / 2.0
        }
    }
    
    deinit {
        removeGestureRecognizer(panGestureRecognizer)
        removeGestureRecognizer(tapGestureRecognizer)
    }
    
    private func setup() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DraggableCardView.panGestureRecognized))
        addGestureRecognizer(panGestureRecognizer)
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DraggableCardView.tapRecognized))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    //MARK: Configurations
    func configure(_ view: UIView, overlayView: OverlayView?) {
        self.overlayView?.removeFromSuperview()
        
        if let overlay = overlayView {
            self.overlayView = overlay
            overlay.alpha = 0;
            self.addSubview(overlay)
            configureOverlayView()
            self.insertSubview(view, belowSubview: overlay)
        } else {
            self.addSubview(view)
        }
        
        self.contentView?.removeFromSuperview()
        self.contentView = view
        configureContentView()
    }
    
    private func configureOverlayView() {
        if let overlay = self.overlayView {
            overlay.translatesAutoresizingMaskIntoConstraints = false
            
            let width = NSLayoutConstraint(
                item: overlay,
                attribute: NSLayoutAttribute.width,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.width,
                multiplier: 1.0,
                constant: 0)
            let height = NSLayoutConstraint(
                item: overlay,
                attribute: NSLayoutAttribute.height,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.height,
                multiplier: 1.0,
                constant: 0)
            let top = NSLayoutConstraint (
                item: overlay,
                attribute: NSLayoutAttribute.top,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.top,
                multiplier: 1.0,
                constant: 0)
            let leading = NSLayoutConstraint (
                item: overlay,
                attribute: NSLayoutAttribute.leading,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.leading,
                multiplier: 1.0,
                constant: 0)
            addConstraints([width,height,top,leading])
        }
    }
    
    private func configureContentView() {
        if let contentView = self.contentView {
            contentView.translatesAutoresizingMaskIntoConstraints = false
            
            let width = NSLayoutConstraint(
                item: contentView,
                attribute: NSLayoutAttribute.width,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.width,
                multiplier: 1.0,
                constant: 0)
            let height = NSLayoutConstraint(
                item: contentView,
                attribute: NSLayoutAttribute.height,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.height,
                multiplier: 1.0,
                constant: 0)
            let top = NSLayoutConstraint (
                item: contentView,
                attribute: NSLayoutAttribute.top,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.top,
                multiplier: 1.0,
                constant: 0)
            let leading = NSLayoutConstraint (
                item: contentView,
                attribute: NSLayoutAttribute.leading,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.leading,
                multiplier: 1.0,
                constant: 0)
            
            addConstraints([width,height,top,leading])
        }
    }
    
    //MARK: GestureRecozniers
    
    public func panGestureRecognized(gestureRecognizer: UIPanGestureRecognizer) {
        xDistanceFromCenter = gestureRecognizer.translation(in: self).x
        yDistanceFromCenter = gestureRecognizer.translation(in: self).y
        
        let touchLocation = gestureRecognizer.location(in: self)
        
        switch gestureRecognizer.state {
        case .began:
            if firstTouch {
                originalLocation = center
                firstTouch = false
            }
            dragBegin = true
            
            animationDirection = touchLocation.y >= frame.size.height / 2 ? -1.0 : 1.0
            
            layer.shouldRasterize = true
            
            pop_removeAllAnimations()
            break
        case .changed:
            let rotationStrength = min(xDistanceFromCenter / self.frame.size.width, rotationMax)
            let rotationAngle = animationDirection * defaultRotationAngle * rotationStrength
            let scaleStrength = 1 - ((1 - scaleMin) * fabs(rotationStrength))
            let scale = max(scaleStrength, scaleMin)
            
            layer.rasterizationScale = scale * UIScreen.main.scale
            
            let transform = CGAffineTransform(rotationAngle: rotationAngle)
            let scaleTransform = transform.scaledBy(x: scale, y: scale)
            
            self.transform = scaleTransform
            center = CGPoint(x: originalLocation.x + xDistanceFromCenter, y: originalLocation.y + yDistanceFromCenter)
            
            updateOverlayWithFinishPercent(xDistanceFromCenter / frame.size.width)
            //100% - for proportion
            delegate?.cardDraggedWithFinishPercent(self, percent: min(fabs(xDistanceFromCenter * 100 / frame.size.width), 100))
            
            break
        case .ended:
            swipeMadeAction()
            
            layer.shouldRasterize = false
        default :
            break
        }
    }
    
    public func tapRecognized(recogznier: UITapGestureRecognizer) {
        delegate?.cardTapped(self)
    }
    
    //MARK: Private
    private func updateOverlayWithFinishPercent(_ percent: CGFloat) {
        if let overlayView = self.overlayView {
            overlayView.overlayState = percent > 0.0 ? OverlayMode.Right : OverlayMode.Left
            //Overlay is fully visible on half way
            let overlayStrength = min(fabs(2 * percent), 1.0)
            overlayView.alpha = overlayStrength
        }
    }
    
    private func swipeMadeAction() {
        if xDistanceFromCenter > actionMargin {
            rightAction()
        } else if xDistanceFromCenter < -actionMargin {
            leftAction()
        } else {
            resetViewPositionAndTransformations()
        }
    }
    
    private func rightAction() {
        let finishY = originalLocation.y + yDistanceFromCenter
        let finishPoint = CGPoint(x: UIScreen.main.bounds.width * 2, y: finishY)
        
        self.overlayView?.overlayState = OverlayMode.Right
        self.overlayView?.alpha = 1.0
        self.delegate?.cardSwippedInDirection(self, direction: SwipeResultDirection.Right)
        UIView.animate(withDuration: cardSwipeActionAnimationDuration,
            delay: 0.0,
            options: .curveLinear,
            animations: {
                self.center = finishPoint
                
            },
            completion: {
                _ in
                
                self.dragBegin = false
                self.removeFromSuperview()
        })
    }
    
    private func leftAction() {
        let finishY = originalLocation.y + yDistanceFromCenter
        let finishPoint = CGPoint(x: -UIScreen.main.bounds.width, y: finishY)
        
        self.overlayView?.overlayState = OverlayMode.Left
        self.overlayView?.alpha = 1.0
        self.delegate?.cardSwippedInDirection(self, direction: SwipeResultDirection.Left)
        UIView.animate(withDuration: cardSwipeActionAnimationDuration,
            delay: 0.0,
            options: .curveLinear,
            animations: {
                self.center = finishPoint
                
            },
            completion: {
                _ in
                
                self.dragBegin = false
                self.removeFromSuperview()
        })
    }
    
    private func resetViewPositionAndTransformations() {
        self.delegate?.cardWasReset(self)
        
        let resetPositionAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
        
        resetPositionAnimation?.toValue = NSValue(cgPoint: originalLocation)
        resetPositionAnimation?.springBounciness = cardResetAnimationSpringBounciness
        resetPositionAnimation?.springSpeed = cardResetAnimationSpringSpeed
        resetPositionAnimation?.completionBlock = {
            (_, _) in
            
            self.dragBegin = false
        }
        
        pop_add(resetPositionAnimation, forKey: cardResetAnimationKey)
        
        UIView.animate(withDuration: cardResetAnimationDuration,
            delay: 0.0,
            options: [.curveLinear, .allowUserInteraction],
            animations: {
                self.transform = CGAffineTransform(rotationAngle: 0)
                self.overlayView?.alpha = 0
                self.layoutIfNeeded()
                
                return
            },
            completion: {
                _ in
                
                self.transform = CGAffineTransform.identity
                
                return
        })
    }
    
    //MARK: Public
    
    func swipeLeft () {
        if !dragBegin {
            
            let finishPoint = CGPoint(x: -UIScreen.main.bounds.width, y: center.y)
            self.delegate?.cardSwippedInDirection(self, direction: SwipeResultDirection.Left)
            UIView.animate(withDuration: cardSwipeActionAnimationDuration,
                delay: 0.0,
                options: .curveLinear,
                animations: {
                    self.center = finishPoint
                    self.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_4))
                    
                    return
                },
                completion: {
                    _ in
                    
                    self.removeFromSuperview()
                    
                    return
            })
        }
    }
    
    func swipeRight () {
        if !dragBegin {
            
            let finishPoint = CGPoint(x: UIScreen.main.bounds.width * 2, y: center.y)
            self.delegate?.cardSwippedInDirection(self, direction: SwipeResultDirection.Right)
            UIView.animate(withDuration: cardSwipeActionAnimationDuration, delay: 0.0, options: .curveLinear, animations: {
                    self.center = finishPoint
                    self.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_4))
                    
                    return
                },
                completion: {
                    _ in
                    
                    self.removeFromSuperview()
                    
                    return
            })
        }
    }
}
