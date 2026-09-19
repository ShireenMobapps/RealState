//
//  AIChatCell.swift
//  AIPoweredRealEstate
//

import UIKit

enum AIChatSender {
    case user
    case assistant
}

struct AIChatMessage {
    let sender: AIChatSender
    let text: String
    let isParameters: Bool
}

final class AIChatCell: UITableViewCell {

    static let identifier = "AIChatCell"
    static var nib: UINib { UINib(nibName: identifier, bundle: nil) }

    @IBOutlet weak var bubbleLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear
        bubbleView.layer.cornerRadius = 16
        bubbleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        bubbleLabel.numberOfLines = 0
        bubbleView.isUserInteractionEnabled = true
        bubbleView.addInteraction(UIContextMenuInteraction(delegate: self))
    }

    func configure(_ message: AIChatMessage) {
        bubbleLabel.text = message.text
        let isUser = message.sender == .user
        if isUser {
            bubbleView.backgroundColor = .darkThemeColor
            bubbleLabel.textColor = .white
            bubbleView.layer.borderWidth = 0
        } else if message.isParameters {
            bubbleView.backgroundColor = UIColor(red: 241/255, green: 245/255, blue: 249/255, alpha: 1)
            bubbleLabel.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
            bubbleView.layer.borderWidth = 1
        } else {
            bubbleView.backgroundColor = .white
            bubbleLabel.textColor = UIColor(red: 33/255, green: 37/255, blue: 41/255, alpha: 1)
            bubbleView.layer.borderWidth = 1
        }
        bubbleView.layer.borderColor = UIColor.cardBorderColor.cgColor
        leadingConstraint.constant = isUser ? 72 : 16
        trailingConstraint.constant = isUser ? -16 : -72
    }
}

extension AIChatCell: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        let text = bubbleLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard text.isEmpty == false else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let copy = UIAction(title: "Copy".localized, image: UIImage(systemName: "doc.on.doc")) { _ in
                UIPasteboard.general.string = text
            }
            return UIMenu(title: "", children: [copy])
        }
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        preview(for: bubbleView)
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        preview(for: bubbleView)
    }

    private func preview(for view: UIView) -> UITargetedPreview {
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.visiblePath = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius)
        return UITargetedPreview(view: view, parameters: parameters)
    }
}
