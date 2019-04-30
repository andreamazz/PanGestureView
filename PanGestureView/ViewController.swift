//
//  ViewController.swift
//  PanGestureView
//
//  Created by Arvindh Sukumar on 30/01/16.
//  Copyright © 2016 Arvindh Sukumar. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  @IBOutlet weak var swipeView: PanGestureView!
  var label: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    self.edgesForExtendedLayout = []
    setupViews()
    setupActions()
  }
  
  private func setupActions() {
    let action = PanGestureAction(swipeDirection: .right, image: UIImage(named: "chevron-left")!)
    action.backgroundColor = UIColor(red:0.25, green:0.74, blue:0.55, alpha:1)
    action.didTriggerBlock = { direction in
      self.actionDidTrigger(action: action)
    }
    swipeView.addAction(action: action)
    
    let action2 = PanGestureAction(swipeDirection: .left, image: UIImage(named: "chevron-right")!)
    action2.backgroundColor = UIColor(red:0.31, green:0.59, blue:0.7, alpha:1)
    action2.didTriggerBlock = { direction in
      self.actionDidTrigger(action: action2)
    }
    swipeView.addAction(action: action2)
    
    let action3 = PanGestureAction(swipeDirection: .up, image: UIImage(named: "chevron-down")!)
    action3.backgroundColor = UIColor(red:0.57, green:0.56, blue:0.95, alpha:1)
    action3.didTriggerBlock = { direction in
      self.actionDidTrigger(action: action3)
    }
    swipeView.addAction(action: action3)
    
    let action4 = PanGestureAction(swipeDirection: .down, image: UIImage(named: "chevron-up")!)
    action4.backgroundColor = UIColor(red:0.96, green:0.7, blue:0.31, alpha:1)
    action4.didTriggerBlock = { direction in
      self.actionDidTrigger(action: action4)
    }
    swipeView.addAction(action: action4)
  }
  
  private func setupViews() {
    let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    container.backgroundColor = UIColor(white: 0.9, alpha: 1)
    container.layer.cornerRadius = 100
    container.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
    
    label = UILabel(frame: CGRect(x: 0, y: 0, width: 140, height: 30))
    label.text = "Pan Anywhere"
    label.textAlignment = .center
    label.center = container.center
    
    container.addSubview(label)
    
    swipeView.contentView.addSubview(container)
    container.center = swipeView.contentView.center
  }
  
  private func actionDidTrigger(action: PanGestureAction) {
    let container = self.label.superview!
    
    UIView.animate(withDuration: 0.4) {
      container.backgroundColor = action.backgroundColor
      self.label.text = "Panned \(action.swipeDirection)"
      self.label.textColor = .white
    }
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
}

