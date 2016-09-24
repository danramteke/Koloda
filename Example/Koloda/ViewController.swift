//
//  ViewController.swift
//  TinderCardsSwift
//
//  Created by Eugene Andreyev on 4/23/15.
//  Copyright (c) 2015 Eugene Andreyev. All rights reserved.
//

import UIKit
import Koloda
import pop

private var numberOfCards: UInt = 5

class ViewController: UIViewController, KolodaViewDataSource, KolodaViewDelegate {
    public func kolodaDidPresentCard(_ koloda: KolodaView, index: UInt) {
        
    }

    
    @IBOutlet weak var kolodaView: KolodaView!
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        kolodaView.dataSource = self
        kolodaView.delegate = self
        
        self.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
    }
    
    
    //MARK: IBActions
    @IBAction func leftButtonTapped() {
        kolodaView?.swipe(direction: SwipeResultDirection.Left)
    }
    
    @IBAction func rightButtonTapped() {
        kolodaView?.swipe(direction: SwipeResultDirection.Right)
    }
    
    @IBAction func undoButtonTapped() {
        kolodaView?.revertAction()
    }
    
    //MARK: KolodaViewDataSource
    func kolodaNumberOfCards(_ koloda: KolodaView) -> UInt {
        return numberOfCards
    }
    
    func kolodaViewForCardAtIndex(_ koloda: KolodaView, index: UInt) -> UIView {
        return UIImageView(image: UIImage(named: "Card_like_\(index + 1)"))
    }
    func kolodaViewForCardOverlayAtIndex(_ koloda: KolodaView, index: UInt) -> OverlayView? {
        return Bundle.main.loadNibNamed("OverlayView",
            owner: self, options: nil)?[0] as? OverlayView
    }
    
    //MARK: KolodaViewDelegate
    
    func kolodaDidSwipedCardAtIndex(_ koloda: KolodaView, index: UInt, direction: SwipeResultDirection) {
    //Example: loading more cards
        if index >= 3 {
            numberOfCards = 6
            kolodaView.reloadData()
        }
    }
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
    //Example: reloading
        kolodaView.resetCurrentCardNumber()
    }
    
    func kolodaDidSelectCardAtIndex(_ koloda: KolodaView, index: UInt) {
        UIApplication.shared.openURL(URL(string: "http://yalantis.com/")!)
    }
    
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool {
        return true
    }
    
    func kolodaShouldMoveBackgroundCard(_ koloda: KolodaView) -> Bool {
        return true
    }
    
    func kolodaShouldTransparentizeNextCard(_ koloda: KolodaView) -> Bool {
        return true
    }
    
    func kolodaBackgroundCardAnimation(_ koloda: KolodaView) -> POPPropertyAnimation? {
        return nil
    }

}

