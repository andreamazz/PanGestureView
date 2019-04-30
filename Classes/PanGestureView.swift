//
//  PanGestureView.swift
//  PanGestureView
//
//  Created by Arvindh Sukumar on 30/01/16.
//  Copyright © 2016 Arvindh Sukumar. All rights reserved.
//

import UIKit

public enum PanGestureViewSwipeDirection {
  case none
  case down
  case left
  case up
  case right
  
  var isHorizontal: Bool {
    return self == .left || self == .right
  }
}

public class PanGestureView: UIView {
  public var contentView: UIView!
  private var actions: [PanGestureViewSwipeDirection: PanGestureAction] = [:]
  private var actionViews: [PanGestureViewSwipeDirection: PanGestureActionView] = [:]
  private var panGestureRecognizer: UIPanGestureRecognizer!
  private var swipeDirection: PanGestureViewSwipeDirection!
  private var displayLink: CADisplayLink?
  private var currentTranslationInView: CGPoint?
  
  public override init(frame:CGRect) {
    super.init(frame:frame)
    setupView()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupView()
  }
  
  private func setupView() {
    addContentView()
    
    panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(PanGestureView.handlePan(gesture:)))
    panGestureRecognizer.delegate = self
    addGestureRecognizer(panGestureRecognizer)
  }
  
  private func addContentView() {
    contentView = UIView(frame: self.bounds)
    contentView.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
    contentView.translatesAutoresizingMaskIntoConstraints = true
    addSubview(contentView)
  }
  
  public func addAction(action: PanGestureAction) {
    let direction = action.swipeDirection

    actions[direction] = action
    
    if let existingActionView = actionViews[direction] {
      existingActionView.removeFromSuperview()
    }
    
    let view = PanGestureActionView(frame: .zero, action: action)
    view.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(view)
    
    addConstraintsToActionView(actionView: view, direction: direction)
    
    actionViews[direction] = view
  }
  
  func addConstraintsToActionView(actionView: PanGestureActionView, direction: PanGestureViewSwipeDirection) {
    let views: [String: UIView] = ["view": actionView, "contentView": contentView]
    
    let orientation1 = direction.isHorizontal ? "H" : "V"
    let orientation2 = (orientation1 == "H") ? "V" : "H"
    
    let constraint: String
    if direction == .left || direction == .up {
      constraint = "\(orientation1):[contentView]-(<=0@250,0@750)-[view(>=0)]-0-|"
    } else {
      constraint = "\(orientation1):|-0-[view(>=0)]-(<=0@250,0@750)-[contentView]"
    }
    
    self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: constraint, options: [], metrics: [:], views: views))
    self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "\(orientation2):|-0-[view]-0-|", options: [], metrics: [:], views: views))
  }
}

extension PanGestureView: UIGestureRecognizerDelegate {
  func startDisplayLink() {
    displayLink = CADisplayLink(target: self, selector: #selector(PanGestureView.handleDisplayLink(link:)))
    displayLink?.add(to: RunLoop.current, forMode: .default)
  }
  
  func stopDisplayLink() {
    displayLink?.invalidate()
    displayLink = nil
  }
  
  @objc func handleDisplayLink(link: CADisplayLink) {
    guard let translation = currentTranslationInView else { return }
    invertSwipeDirectionIfRequired(translation: translation)
    updatePosition(translation: translation)
  }
  
  @objc func handlePan(gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: gesture.view)
    currentTranslationInView = translation
    let velocity = gesture.velocity(in: gesture.view)
    
    switch gesture.state {
    case .began:
      swipeDirection = swipeDirectionForTranslation(translation: translation, velocity: velocity)
      startDisplayLink()
    case .changed:
      break
    case .cancelled:
      self.stopDisplayLink()
    case .failed:
      self.stopDisplayLink()
    case .ended:
      self.stopDisplayLink()
      if let actionView = self.actionViews[self.swipeDirection], let action = self.actions[self.swipeDirection], actionView.shouldTrigger  {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: [.curveEaseOut, .allowUserInteraction], animations: { () -> Void in
          self.resetView()
        }, completion: { (finished) -> Void in
          if finished {
            action.didTriggerBlock?(self.swipeDirection)
          }
        })
      } else {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
          self.resetView()
        }, completion: nil)
      }
    default:
      break
    }
  }
  
  private func swipeDirectionWasInverted(originalDirection:PanGestureViewSwipeDirection, translation:CGPoint) -> Bool {
    
    var wasInverted = false
    
    switch originalDirection {
    case .left:
      wasInverted = translation.x > 0
    case .right:
      wasInverted = translation.x < 0
    case .up:
      wasInverted = translation.y > 0
    case .down:
      wasInverted = translation.y < 0
    default:
      break
    }
    
    return wasInverted
  }
  
  private func inverseForSwipeDirection(direction: PanGestureViewSwipeDirection) -> PanGestureViewSwipeDirection {
    
    var inverseDirection:PanGestureViewSwipeDirection!
    
    switch direction {
    case .left:
      inverseDirection = .right
    case .right:
      inverseDirection = .left
    case .up:
      inverseDirection = .down
    case .down:
      inverseDirection = .up
    default:
      break
    }
    
    return inverseDirection
  }
  
  private func invertSwipeDirectionIfRequired(translation: CGPoint) {
    if swipeDirectionWasInverted(originalDirection: self.swipeDirection, translation: translation){
      self.swipeDirection = inverseForSwipeDirection(direction: self.swipeDirection)
    }
  }
  
  private func resetView() {
    self.contentView.center = self.center
    self.setNeedsLayout()
    self.layoutIfNeeded()
  }
  
  private func updatePosition(translation:CGPoint) {
    if swipeDirection.isHorizontal {
      let elasticTranslation = elasticPoint(x: Float(translation.x), li: 44, lf: 100)
      contentView.center.x = contentView.frame.size.width / 2 + CGFloat(elasticTranslation)
    } else {
      let elasticTranslation = elasticPoint(x: Float(translation.y), li: 44, lf: 100)
      contentView.center.y = contentView.frame.size.height / 2 + CGFloat(elasticTranslation)
    }
    
    self.setNeedsLayout()
    self.layoutIfNeeded()
    
    if let actionView = actionViews[swipeDirection] {
      if actionView.isActive {
        actionView.shouldTrigger = true
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: { () -> Void in
          actionView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: nil)
      }
      else {
        actionView.shouldTrigger = false
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: { () -> Void in
          actionView.transform = .identity
        }, completion: nil)
      }
    }
    
  }
  
  private func swipeDirectionForTranslation(translation: CGPoint, velocity: CGPoint) -> PanGestureViewSwipeDirection {
    if velocity.x == 0 && velocity.y == 0 {
      return .none
    }
    
    if abs(velocity.x) > abs(velocity.y) {
      // Horizontal swipe
      if translation.x > 0 {
        return .right
      }
      return .left
    }

    if translation.y > 0 {
      return .down
    }
    
    return .up
  }
  
  func elasticPoint(x: Float, li: Float, lf: Float) -> Float {
    if abs(x) >= abs(li) {
      return atanf(tanf((Float.pi * li) / (2 * lf)) * (x / li)) * (2 * lf / Float.pi)
    } else {
      return x
    }
  }
}

fileprivate let MinimumTranslation: CGFloat = 15

class PanGestureActionView: UIView {
  var imageView: UIImageView = UIImageView(frame: .zero)
  var action: PanGestureAction!
  var isActive:Bool = false
  var shouldTrigger:Bool = false
  
  override init(frame:CGRect){
    super.init(frame:frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupView()
  }
  
  convenience init(frame: CGRect, action:PanGestureAction ) {
    self.init(frame:frame)
    self.action = action
    setupView()
    
  }
  
  private func setupView(){
    imageView.alpha = 0
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = action.image?.withRenderingMode(.alwaysTemplate)
    imageView.tintColor = action.tintColor ?? .white
    addSubview(imageView)
    
    self.backgroundColor = action.backgroundColor ?? .white
    setupConstraints()
    
  }
  
  private func setupConstraints() {
    let views: [String: UIView] = ["imageView": imageView]
    
    let orientation1 = self.action.swipeDirection.isHorizontal ? "H" : "V"
    let orientation2 = (orientation1 == "H") ? "V" : "H"
    
    let hConstraintString = "\(orientation1):|-(0@250)-[imageView(<=44)]-(0@250)-|"
    let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: hConstraintString, options: [], metrics: [:], views: views)
    self.addConstraints(hConstraints)
    
    let vConstraintString = "\(orientation2):[imageView(44)]"
    let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: vConstraintString, options: [], metrics: [:], views: views)
    self.addConstraints(vConstraints)
    
    let hCenterConstraint = NSLayoutConstraint(item: imageView, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
    hCenterConstraint.priority = UILayoutPriority(rawValue: 1000)
    self.addConstraint(hCenterConstraint)
    
    let vCenterConstraint = NSLayoutConstraint(item: imageView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
    self.addConstraint(vCenterConstraint)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let length = self.action.swipeDirection.isHorizontal ? self.frame.size.width : self.frame.size.height
    let imageViewLength = self.action.swipeDirection.isHorizontal ? self.imageView.frame.size.width : self.imageView.frame.size.height
    
    if length > imageViewLength {
      let origin = self.action.swipeDirection.isHorizontal ? self.bounds.origin.x : self.bounds.origin.y
      let imageViewOrigin = self.action.swipeDirection.isHorizontal ? self.imageView.frame.origin.x : self.imageView.frame.origin.y
      imageView.alpha = (origin + imageViewOrigin) / MinimumTranslation
    } else {
      imageView.alpha = 0
    }
    
    isActive = (imageView.alpha >= 1)
  }
}
