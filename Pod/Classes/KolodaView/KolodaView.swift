//
//  KolodaView.swift
//  TinderCardsSwift
//
//  Created by Eugene Andreyev on 4/24/15.
//  Copyright (c) 2015 Eugene Andreyev. All rights reserved.
//

import UIKit
import pop

public enum SwipeResultDirection {
    case None
    case Left
    case Right
}

//Default values
private let defaultCountOfVisibleCards = 3
private let backgroundCardsTopMargin: CGFloat = 4.0
private let backgroundCardsScalePercent: CGFloat = 0.95
private let backgroundCardsLeftMargin: CGFloat = 8.0
private let backgroundCardFrameAnimationDuration: TimeInterval = 0.2

//Opacity values
private let defaultAlphaValueOpaque: CGFloat = 1.0
private let defaultAlphaValueTransparent: CGFloat = 0.0
private let defaultAlphaValueSemiTransparent: CGFloat = 0.7

//Animations constants
private let revertCardAnimationName = "revertCardAlphaAnimation"
private let revertCardAnimationDuration: TimeInterval = 1.0
private let revertCardAnimationToValue: CGFloat = 1.0
private let revertCardAnimationFromValue: CGFloat = 0.0

private let kolodaAppearScaleAnimationName = "kolodaAppearScaleAnimation"
private let kolodaAppearScaleAnimationFromValue = CGPoint(x: 0.1, y: 0.1)
private let kolodaAppearScaleAnimationToValue = CGPoint(x: 1.0, y: 1.0)
private let kolodaAppearScaleAnimationDuration: TimeInterval = 0.8
private let kolodaAppearAlphaAnimationName = "kolodaAppearAlphaAnimation"
private let kolodaAppearAlphaAnimationFromValue: CGFloat = 0.0
private let kolodaAppearAlphaAnimationToValue: CGFloat = 1.0
private let kolodaAppearAlphaAnimationDuration: TimeInterval = 0.8


public protocol KolodaViewDataSource:class {
    
    func kolodaNumberOfCards(_ koloda: KolodaView) -> UInt
    func kolodaViewForCardAtIndex(_ koloda: KolodaView, index: UInt) -> UIView
    func kolodaViewForCardOverlayAtIndex(_ koloda: KolodaView, index: UInt) -> OverlayView?
    
}

public protocol KolodaViewDelegate:class {
    func kolodaDidSwipedCardAtIndex(_ koloda: KolodaView,index: UInt, direction: SwipeResultDirection)
    func kolodaDidRunOutOfCards(_ koloda: KolodaView)
    func kolodaDidSelectCardAtIndex(_ koloda: KolodaView, index: UInt)
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool
    func kolodaShouldMoveBackgroundCard(_ koloda: KolodaView) -> Bool
    func kolodaDidPresentCard(_ koloda: KolodaView, index: UInt)
    func kolodaShouldTransparentizeNextCard(_ koloda: KolodaView) -> Bool
    func kolodaBackgroundCardAnimation(_ koloda: KolodaView) -> POPPropertyAnimation?
}

public extension KolodaViewDelegate {
    func kolodaDidSwipedCardAtIndex(_ koloda: KolodaView,index: UInt, direction: SwipeResultDirection) {}
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {}
    func kolodaDidSelectCardAtIndex(_ koloda: KolodaView, index: UInt) {}
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool {return true}
    func kolodaShouldMoveBackgroundCard(_ koloda: KolodaView) -> Bool {return true}
    func kolodaShouldTransparentizeNextCard(_ koloda: KolodaView) -> Bool {return true}
    func kolodaBackgroundCardAnimation(_ koloda: KolodaView) -> POPPropertyAnimation? {return nil}
}

public class KolodaView: UIView, DraggableCardDelegate {
    
    public weak var dataSource: KolodaViewDataSource! {
        didSet {
            setupDeck()
        }
    }
    public weak var delegate: KolodaViewDelegate?
    
    private(set) public var currentCardNumber = 0 {
        didSet {
            delegate?.kolodaDidPresentCard(self, index: UInt(currentCardNumber))
        }
    }
    private(set) public var countOfCards = 0
    
    public var countOfVisibleCards = defaultCountOfVisibleCards
    private var visibleCards = [DraggableCardView]()
    private var animating = false
    private var configured = false
    
    public var alphaValueOpaque: CGFloat = defaultAlphaValueOpaque
    public var alphaValueTransparent: CGFloat = defaultAlphaValueTransparent
    public var alphaValueSemiTransparent: CGFloat = defaultAlphaValueSemiTransparent
    
    //MARK: Lifecycle
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    deinit {
        unsubsribeFromNotifications()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if !self.configured {
            
            if self.visibleCards.isEmpty {
                reloadData()
            } else {
                layoutDeck()
            }
            
            self.configured = true
        }
    }
    
    //MARK: Configurations
    
    private func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self, selector: "layoutDeck", name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    private func unsubsribeFromNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func configure() {
        subscribeForNotifications()
    }
    
    private func setupDeck() {
        countOfCards = Int(dataSource!.kolodaNumberOfCards(self))
        
        if countOfCards - currentCardNumber > 0 {
            
            let countOfNeededCards = min(countOfVisibleCards, countOfCards - currentCardNumber)
            
            for index in 0..<countOfNeededCards {
                if let nextCardContentView = dataSource?.kolodaViewForCardAtIndex(self, index: UInt(index)) {
                    let nextCardView = DraggableCardView(frame: frameForCardAtIndex(UInt(index)))
                    
                    nextCardView.delegate = self
                    nextCardView.alpha = index == 0 ? alphaValueOpaque : alphaValueSemiTransparent
                    nextCardView.isUserInteractionEnabled = index == 0
                    
                    let overlayView = overlayViewForCardAtIndex(UInt(index))
                    
                    nextCardView.configure(nextCardContentView, overlayView: overlayView)
                    visibleCards.append(nextCardView)
                    index == 0 ? addSubview(nextCardView) : insertSubview(nextCardView, belowSubview: visibleCards[index - 1])
                }
            }
            
            delegate?.kolodaDidPresentCard(self, index: UInt(currentCardNumber))
        }
    }
    
    public func layoutDeck() {
        for (index, card) in self.visibleCards.enumerated() {
            card.frame = frameForCardAtIndex(UInt(index))
        }
    }
    
    //MARK: Frames
    public func frameForCardAtIndex(_ index: UInt) -> CGRect {
        let bottomOffset:CGFloat = 0
        let topOffset = backgroundCardsTopMargin * CGFloat(self.countOfVisibleCards - 1)
        let xOffset = backgroundCardsLeftMargin * CGFloat(index)
        let scalePercent = backgroundCardsScalePercent
        let width = self.frame.width * pow(scalePercent, CGFloat(index))
        let height = (self.frame.height - bottomOffset - topOffset) * pow(scalePercent, CGFloat(index))
        let multiplier: CGFloat = index > 0 ? 1.0 : 0.0
        let previousCardFrame = index > 0 ? frameForCardAtIndex(max(index - 1, 0)) : CGRect.zero
        let yOffset = (previousCardFrame.height - height + previousCardFrame.origin.y + backgroundCardsTopMargin) * multiplier
        let frame = CGRect(x: xOffset, y: yOffset, width: width, height: height)
        
        return frame
    }
    
    private func moveOtherCardsWithFinishPercent(_ percent: CGFloat) {
        if visibleCards.count > 1 {
            
            for index in 1..<visibleCards.count {
                let previousCardFrame = frameForCardAtIndex(UInt(index - 1))
                var frame = frameForCardAtIndex(UInt(index))
                let distanceToMoveY: CGFloat = (frame.origin.y - previousCardFrame.origin.y) * (percent / 100)
                
                frame.origin.y -= distanceToMoveY
                
                let distanceToMoveX: CGFloat = (previousCardFrame.origin.x - frame.origin.x) * (percent / 100)
                
                frame.origin.x += distanceToMoveX
                
                let widthScale = (previousCardFrame.size.width - frame.size.width) * (percent / 100)
                let heightScale = (previousCardFrame.size.height - frame.size.height) * (percent / 100)
                
                frame.size.width += widthScale
                frame.size.height += heightScale
                
                let card = visibleCards[index]
                
                card.pop_removeAllAnimations()
                card.frame = frame
                card.layoutIfNeeded()
                
                //For fully visible next card, when moving top card
                if let shouldTransparentize = delegate?.kolodaShouldTransparentizeNextCard(self),
                    shouldTransparentize == true {
                    if index == 1 {
                        card.alpha = alphaValueOpaque
                    }
                }
            }
        }
    }
    
    //MARK: Animations
    
    public func applyAppearAnimation() {
        isUserInteractionEnabled = false
        animating = true
        
        let kolodaAppearScaleAnimation = POPBasicAnimation(propertyNamed: kPOPViewScaleXY)!
        
        kolodaAppearScaleAnimation.beginTime = CACurrentMediaTime() + cardSwipeActionAnimationDuration
        kolodaAppearScaleAnimation.duration = kolodaAppearScaleAnimationDuration
        kolodaAppearScaleAnimation.fromValue = NSValue(cgPoint: kolodaAppearScaleAnimationFromValue)
        kolodaAppearScaleAnimation.toValue = NSValue(cgPoint: kolodaAppearScaleAnimationToValue)
        kolodaAppearScaleAnimation.completionBlock = {
            (_, _) in
            
            self.isUserInteractionEnabled = true
            self.animating = false
        }
        
        let kolodaAppearAlphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)!
        
        kolodaAppearAlphaAnimation.beginTime = CACurrentMediaTime() + cardSwipeActionAnimationDuration
        kolodaAppearAlphaAnimation.fromValue = NSNumber(value: Float(kolodaAppearAlphaAnimationFromValue))
        kolodaAppearAlphaAnimation.toValue = NSNumber(value: Float(kolodaAppearAlphaAnimationToValue))
        kolodaAppearAlphaAnimation.duration = kolodaAppearAlphaAnimationDuration
        
        pop_add(kolodaAppearAlphaAnimation, forKey: kolodaAppearAlphaAnimationName)
        pop_add(kolodaAppearScaleAnimation, forKey: kolodaAppearScaleAnimationName)
    }
    
    func applyRevertAnimation(card: DraggableCardView) {
        animating = true
        
        let firstCardAppearAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)!
        
        firstCardAppearAnimation.toValue = NSNumber(value: Float(revertCardAnimationToValue))
        firstCardAppearAnimation.fromValue =  NSNumber(value: Float(revertCardAnimationFromValue))
        firstCardAppearAnimation.duration = revertCardAnimationDuration
        firstCardAppearAnimation.completionBlock = {
            (_, _) in
            
            self.animating = false
        }
        
        card.pop_add(firstCardAppearAnimation, forKey: revertCardAnimationName)
    }
    
    //MARK: DraggableCardDelegate
    
    func cardDraggedWithFinishPercent(_ card: DraggableCardView, percent: CGFloat) {
        animating = true
        
        if let shouldMove = delegate?.kolodaShouldMoveBackgroundCard(self) , shouldMove == true {
            self.moveOtherCardsWithFinishPercent(percent)
        }
    }
    
    func cardSwippedInDirection(_ card: DraggableCardView, direction: SwipeResultDirection) {
        swipedAction(direction)
    }
    
    func cardWasReset(_ card: DraggableCardView) {
        if visibleCards.count > 1 {
            
            UIView.animate(withDuration: backgroundCardFrameAnimationDuration,
                delay: 0.0,
                options: .curveLinear,
                animations: {
                    self.moveOtherCardsWithFinishPercent(0)
                },
                completion: {
                    _ in
                    self.animating = false
                    
                    for index in 1..<self.visibleCards.count {
                        let card = self.visibleCards[index]
                        card.alpha = self.alphaValueSemiTransparent
                    }
            })
        } else {
            animating = false
        }
        
    }
    
    func cardTapped(_ card: DraggableCardView) {
        let index = currentCardNumber + visibleCards.index(of: card)!
        
        delegate?.kolodaDidSelectCardAtIndex(self, index: UInt(index))
    }
    
    //MARK: Private
    
    private func clear() {
        currentCardNumber = 0
        
        for card in visibleCards {
            card.removeFromSuperview()
        }
        
        visibleCards.removeAll(keepingCapacity: true)
        
    }
    
    private func overlayViewForCardAtIndex(_ index: UInt) -> OverlayView? {
        return dataSource.kolodaViewForCardOverlayAtIndex(self, index: index)
    }
    
    //MARK: Actions
    
    private func swipedAction(_ direction: SwipeResultDirection) {
        animating = true
        visibleCards.remove(at: 0)
        
        currentCardNumber += 1
        let shownCardsCount = currentCardNumber + countOfVisibleCards
        if shownCardsCount - 1 < countOfCards {
            
            if let dataSource = self.dataSource {
                
                let lastCardContentView = dataSource.kolodaViewForCardAtIndex(self, index: UInt(shownCardsCount - 1))
                let lastCardOverlayView = dataSource.kolodaViewForCardOverlayAtIndex(self, index: UInt(shownCardsCount - 1))
                let lastCardFrame = frameForCardAtIndex(UInt(currentCardNumber + visibleCards.count))
                let lastCardView = DraggableCardView(frame: lastCardFrame)
                
                lastCardView.isHidden = true
                lastCardView.isUserInteractionEnabled = true
                
                lastCardView.configure(lastCardContentView, overlayView: lastCardOverlayView)
                
                lastCardView.delegate = self
                
                insertSubview(lastCardView, belowSubview: visibleCards.last!)
                visibleCards.append(lastCardView)
            }
        }
        
        if !visibleCards.isEmpty {
            
            for (index, currentCard) in visibleCards.enumerated() {
                var frameAnimation: POPPropertyAnimation
                if let delegateAnimation = delegate?.kolodaBackgroundCardAnimation(self) , delegateAnimation.property.name == kPOPViewFrame {
                    frameAnimation = delegateAnimation
                } else {
                    frameAnimation = POPBasicAnimation(propertyNamed: kPOPViewFrame)
                    (frameAnimation as! POPBasicAnimation).duration = backgroundCardFrameAnimationDuration
                }
                
                let shouldTransparentize = delegate?.kolodaShouldTransparentizeNextCard(self)
                
                if index != 0 {
                    currentCard.alpha = alphaValueSemiTransparent
                } else {
                    frameAnimation.completionBlock = {(_, _) in
                        self.visibleCards.last?.isHidden = false
                        self.animating = false
                        self.delegate?.kolodaDidSwipedCardAtIndex(self, index: UInt(self.currentCardNumber - 1), direction: direction)
                        if (shouldTransparentize == false) {
                            currentCard.alpha = self.alphaValueOpaque
                        }
                    }
                    if (shouldTransparentize == true) {
                        currentCard.alpha = alphaValueOpaque
                    } else {
                        let alphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)!
                        alphaAnimation.toValue = alphaValueOpaque
                        alphaAnimation.duration = backgroundCardFrameAnimationDuration
                        currentCard.pop_add(alphaAnimation, forKey: "alpha")
                    }
                }
                
                currentCard.isUserInteractionEnabled = index == 0
                frameAnimation.toValue = NSValue(cgRect: frameForCardAtIndex(UInt(index)))
                
                currentCard.pop_add(frameAnimation, forKey: "frameAnimation")
            }
        } else {
            delegate?.kolodaDidSwipedCardAtIndex(self, index: UInt(currentCardNumber - 1), direction: direction)
            animating = false
            self.delegate?.kolodaDidRunOutOfCards(self)
        }
        
    }
    
    public func revertAction() {
        if currentCardNumber > 0 && animating == false {
            
            if countOfCards - currentCardNumber >= countOfVisibleCards {
                
                if let lastCard = visibleCards.last {
                    
                    lastCard.removeFromSuperview()
                    visibleCards.removeLast()
                }
            }
            
            currentCardNumber -= 1
            
            
            if let dataSource = self.dataSource {
                let firstCardContentView = dataSource.kolodaViewForCardAtIndex(self, index: UInt(currentCardNumber))
                let firstCardOverlayView = dataSource.kolodaViewForCardOverlayAtIndex(self, index: UInt(currentCardNumber))
                let firstCardView = DraggableCardView()
                
                firstCardView.alpha = alphaValueTransparent
                
                firstCardView.configure(firstCardContentView, overlayView: firstCardOverlayView)
                firstCardView.delegate = self
                
                addSubview(firstCardView)
                visibleCards.insert(firstCardView, at: 0)
                
                firstCardView.frame = frameForCardAtIndex(0)
                
                applyRevertAnimation(card: firstCardView)
            }
            
            for index in 1..<visibleCards.count {
                let currentCard = visibleCards[index]
                let frameAnimation = POPBasicAnimation(propertyNamed: kPOPViewFrame)!
                
                frameAnimation.duration = backgroundCardFrameAnimationDuration
                currentCard.alpha = alphaValueSemiTransparent
                frameAnimation.toValue = NSValue(cgRect: frameForCardAtIndex(UInt(index)))
                currentCard.isUserInteractionEnabled = false
                
                currentCard.pop_add(frameAnimation, forKey: "frameAnimation")
            }
        }
    }
    
    private func loadMissingCards(_ missingCardsCount: Int) {
        if missingCardsCount > 0 {
            
            let cardsToAdd = min(missingCardsCount, countOfCards - currentCardNumber)
            
            for index in 1...cardsToAdd {
                let nextCardView = DraggableCardView(frame: frameForCardAtIndex(UInt(index)))
                
                nextCardView.alpha = alphaValueSemiTransparent
                nextCardView.delegate = self
                
                visibleCards.append(nextCardView)
                insertSubview(nextCardView, belowSubview: visibleCards[index - 1])
            }
        }
        
        reconfigureCards()
    }
    
    private func reconfigureCards() {
        for index in 0..<visibleCards.count {
            if let dataSource = self.dataSource {
                
                let currentCardContentView = dataSource.kolodaViewForCardAtIndex(self, index: UInt(currentCardNumber + index))
                let overlayView = dataSource.kolodaViewForCardOverlayAtIndex(self, index: UInt(currentCardNumber + index))
                let currentCard = visibleCards[index]
                
                currentCard.configure(currentCardContentView, overlayView: overlayView)
            }
        }
    }
    
    public func reloadData() {
        countOfCards = Int(dataSource!.kolodaNumberOfCards(self))
        let missingCards = min(countOfVisibleCards - visibleCards.count, countOfCards - (currentCardNumber + 1))
        
        if countOfCards == 0 {
            return
        }
        
        if currentCardNumber == 0 {
            clear()
        }
        
        if countOfCards - (currentCardNumber + visibleCards.count) > 0 {
            
            if !visibleCards.isEmpty {
                loadMissingCards(missingCards)
            } else {
                setupDeck()
                layoutDeck()
                
                if let shouldApply = delegate?.kolodaShouldApplyAppearAnimation(self) , shouldApply == true {
                    self.alpha = 0
                    applyAppearAnimation()
                }
            }
            
        } else {
            
            reconfigureCards()
        }
    }
    
    public func swipe(direction: SwipeResultDirection) {
        if (animating == false) {
            
            if let frontCard = visibleCards.first {
                
                animating = true
                
                if visibleCards.count > 1 {
                    if let shouldTransparentize = delegate?.kolodaShouldTransparentizeNextCard(self) , shouldTransparentize == true {
                        let nextCard = visibleCards[1]
                        nextCard.alpha = alphaValueOpaque
                    }
                }
                
                switch direction {
                case SwipeResultDirection.None:
                    return
                case SwipeResultDirection.Left:
                    frontCard.swipeLeft()
                case SwipeResultDirection.Right:
                    frontCard.swipeRight()
                }
            }
        }
    }
    
    public func resetCurrentCardNumber() {
        clear()
        reloadData()
    }
    
}
