//
//  Designable.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import Foundation
import UIKit

@IBDesignable
final class CustomTextField: UITextField {

    @IBInspectable
    var cornerRadious: CGFloat = 0.0 {
        didSet { layer.cornerRadius = cornerRadious }
    }

    @IBInspectable
    var borderWidth: CGFloat = 0.0 {
        didSet { layer.borderWidth = borderWidth }
    }

    @IBInspectable
    var borderColor: UIColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1) {
        didSet { layer.borderColor = borderColor.cgColor }
    }

    @IBInspectable
    var placeHolderColor: UIColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1) {
        didSet { updatePlaceholder() }
    }

    @IBInspectable
    
    var leftPadding: CGFloat = 10

    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyle()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupStyle()
    }

    private func setupStyle() {
        borderStyle = .none
        layer.cornerRadius = cornerRadious
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        backgroundColor = .white
        font = .systemFont(ofSize: 16, weight: .regular)
        textColor = .black
        updatePlaceholder()
        attachKeyboardDoneButton()
        addTarget(self, action: #selector(dismissKeyboardFromToolbar), for: .editingDidEndOnExit)
    }

    private func updatePlaceholder() {
        let placeholderText = placeholder ?? ""
        attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [
                .foregroundColor: placeHolderColor,
                .font: UIFont.systemFont(ofSize: 16, weight: .regular)
            ]
        )
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textInsets)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let size: CGFloat = 36
        let y = max(0, (bounds.height - size) / 2)
        return CGRect(x: bounds.width - size - 4, y: y, width: size, height: size)
    }

    private var textInsets: UIEdgeInsets {
        let right: CGFloat = (rightView != nil && rightViewMode != .never) ? 40 : leftPadding
        return UIEdgeInsets(top: 0, left: leftPadding, bottom: 0, right: right)
    }
}

@IBDesignable

final class CustomView: UIView {

    @IBInspectable
    
    var cornerRadious: CGFloat = 0.0 {
        didSet { layer.cornerRadius = cornerRadious }
    }

    @IBInspectable
    var borderWidth: CGFloat = 0.0 {
        didSet { layer.borderWidth = borderWidth }
    }

    @IBInspectable
    var borderColor: UIColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1) {
        didSet { layer.borderColor = borderColor.cgColor }
    }

    @IBInspectable
    var shadowOpacity: Float = 0.0 {
        didSet { layer.shadowOpacity = shadowOpacity }
    }

    @IBInspectable
    var shadowColor: UIColor = .clear {
        didSet { layer.shadowColor = shadowColor.cgColor }
    }

    @IBInspectable
    var shadowRadious: CGFloat = 0.0 {
        didSet { layer.shadowRadius = shadowRadious }
    }

    @IBInspectable
    var shadowXOffset: CGFloat = 0.0 {
        didSet { layer.shadowOffset.width = shadowXOffset }
    }

    @IBInspectable
    var shadowYOffset: CGFloat = 0.0 {
        didSet { layer.shadowOffset.height = shadowYOffset }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyle()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupStyle()
    }

    private func setupStyle() {
        layer.cornerRadius = cornerRadious
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadious
        layer.shadowColor = shadowColor.cgColor
        layer.shadowOffset = CGSize(width: shadowXOffset, height: shadowYOffset)
        layer.masksToBounds = false
        clipsToBounds = false
    }
}

@IBDesignable
final class CustomButton: UIButton {

    @IBInspectable
    var cornerRadious: CGFloat = 12 {
        didSet { layer.cornerRadius = cornerRadious }
    }

    @IBInspectable
    var borderWidth: CGFloat = 0 {
        didSet { layer.borderWidth = borderWidth }
    }

    @IBInspectable
    var borderColor: UIColor = .clear {
        didSet { layer.borderColor = borderColor.cgColor }
    }

    @IBInspectable
    var shadowOpacity: Float = 0 {
        didSet { layer.shadowOpacity = shadowOpacity }
    }

    @IBInspectable
    var shadowRadius: CGFloat = 0 {
        didSet { layer.shadowRadius = shadowRadius }
    }

    @IBInspectable
    var shadowXOffset: CGFloat = 0 {
        didSet { layer.shadowOffset.width = shadowXOffset }
    }

    @IBInspectable
    var shadowYOffset: CGFloat = 0 {
        didSet { layer.shadowOffset.height = shadowYOffset }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyle()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupStyle()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CommonMethods.updateGradientFrame(for: self)
        if let titleLabel {
            bringSubviewToFront(titleLabel)
        }
        if let imageView {
            bringSubviewToFront(imageView)
        }
    }

    private func setupStyle() {
        layer.cornerRadius = cornerRadious
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = CGSize(width: shadowXOffset, height: shadowYOffset)
        setTitleColor(.white, for: .normal)
        CommonMethods.applyButtonGradient(on: self, cornerRadius: cornerRadious)
    }
}

/*
 SPLASH
    ↓
 ONBOARDING
    ↓
 SELECT USER TYPE
    ├───────────────────────────────────────┐
    │                                       │
    ▼                                       ▼
 BUYER / TENANT                          REALTOR
    │                                       │
    ▼                                       ▼
 AUTHENTICATION                         AUTHENTICATION
    │                                       │
    ▼                                       ▼
 ACCOUNT VERIFICATION                   ACCOUNT VERIFICATION
    │                                       │
    ▼                                       ▼
 BUYER HOME                             REALTOR HOME
    │                                       │
    ├───────────────┐                     ├───────────────┐
    ▼               ▼                     ▼               ▼
 AI SEARCH       NORMAL SEARCH         AI SEARCH       NORMAL SEARCH
    │               │                     │               │
    └───────┬───────┘                     └───────┬───────┘
            ▼                                     ▼
      PROPERTY RESULTS                      PROPERTY RESULTS
            │                                     │
            ▼                                     ▼
      AI RECOMMENDATIONS                    PROPERTY DETAILS
            │                                     │
            ▼                              ┌──────┼──────────────┐
     PROPERTY DETAILS                     ▼      ▼       ▼      ▼
       │    │    │    │                 SAVE  COMPARE  AI     CLIENT
       │    │    │    │                         │      CONTENT SEARCH
       │    │    │    │                         │
       ▼    ▼    ▼    ▼                         ▼
    SAVE CONTACT COMPARE                   CLIENT REPORT
     ALERT  AGENT
       │
       ▼
   NOTIFICATIONS
 */


/*Tenant
 SEARCH
  │
  ├── AI Search
  │      ↓
  │   AI Conversation
  │      ↓
  │   AI Results
  │
  ├── Normal Search
  │      ↓
  │   Location / Keyword
  │
  ├── Buy / Rent
  │
  ├── Filters
  │      ├── Location
  │      ├── Property Type
  │      ├── Price Range
  │      ├── Bedrooms
  │      ├── Bathrooms
  │      ├── Property Size
  │      ├── Furnished
  │      └── Amenities
  │
  ├── Sort
  │      ├── Recommended
  │      ├── Price Low → High
  │      ├── Price High → Low
  │      └── Newest
  │
  └── Results
         ↓
     Property Details
 PROPERTY DETAILS
  │
  ├── Image Gallery
  ├── Price
  ├── Location
  ├── Property Type
  ├── Bedrooms
  ├── Bathrooms
  ├── Area
  ├── Description
  ├── Amenities
  ├── Source / Portal
  ├── Agent Information
  │
  ├── ❤️ Save
  │
  ├── Compare
  │
  └── Contact Agent
          ↓
       Lead Form
          ↓
       Enquiry Submitted
 
 SAVED
  │
  ├── Saved Properties
  │      ↓
  │   Property Details
  │
  ├── Saved Searches
  │      ↓
  │   Search Preference
  │      ├── Location
  │      ├── Buy / Rent
  │      ├── Price
  │      ├── Bedrooms
  │      └── Amenities
  │
  │      └── 🔔 Alert ON/OFF
  │
  └── Compare
         ↓
      Select 2–3 Properties
         ↓
      Comparison
         ├── Price
         ├── Location
         ├── Bedrooms
         ├── Bathrooms
         ├── Area
         ├── Cost / m²
         ├── Amenities
         └── AI Comparison
 
 COMPARE

 Property A    Property B    Property C

 Price
 Location
 Bedrooms
 Bathrooms
 Area
 Cost / m²
 Amenities
 Power Backup
 Furnished
 ...

         ↓

 AI SUMMARY

 "Property A is the best match
 for your budget and requirements."
 
 
 PROFILE
  │
  ├── Profile Information
  │      └── Edit Profile
  │
  ├── My Preferences
  │      ├── Property Type
  │      ├── Preferred Locations
  │      ├── Budget
  │      ├── Bedrooms
  │      └── Amenities
  │
  ├── 🔔 Notifications
  │      ├── New Matching Properties
  │      ├── Saved Property Updates
  │      ├── Search Alerts
  │      └── Agent Enquiries
  │
  ├── Saved Searches
  │
  ├── Contact / Enquiry History
  │
  ├── Recently Viewed
  │
  ├── Language
  │
  ├── Currency
  │
  ├── Help & Support
  │
  ├── Terms & Conditions
  │
  ├── Privacy Policy
  │
  └── Logout
 
 TENANT / BUYER
       │
┌─────────────────┼─────────────────┐
│                 │                 │
▼                 ▼                 ▼
HOME             SEARCH             SAVED
│                 │                 │
│                 │                 ├── Favorites
│                 │                 ├── Saved Searches
│                 │                 └── Compare
│                 │
├── AI Search     ├── AI Search
│      │          ├── Normal Search
│      ▼          ├── Filters
│   AI Chat       ├── Sort
│      │          └── Results
│      ▼                 │
│   Top 3                ▼
│   Results          Property
│      │             Details
│      ▼                 │
├── Recommended          ├── Save
├── Recently Viewed      ├── Compare
└── Quick Search         └── Contact Agent
                   │
                   ▼
              Lead / Enquiry


 PROFILE
    │
├── Personal Information
├── Preferences
├── Notifications / Alerts
├── Saved Searches
├── Enquiry History
├── Recently Viewed
├── Language / Currency
├── Help & Support
└── Logout
 */
