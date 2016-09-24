//
//  OverlayView.swift
//  TinderCardsSwift
//
//  Created by Eugene Andreyev on 4/24/15.
//  Copyright (c) 2015 Eugene Andreyev. All rights reserved.
//

import UIKit
import pop

public enum OverlayMode{
    case None
    case Left
    case Right
}


open class OverlayView: UIView {
    
    open var overlayState:OverlayMode = OverlayMode.None

}
