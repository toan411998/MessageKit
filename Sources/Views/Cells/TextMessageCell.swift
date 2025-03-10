// MIT License
//
// Copyright (c) 2017-2019 MessageKit
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

/// A subclass of `MessageContentCell` used to display text messages.
open class TextMessageCell: MessageContentCell {
  /// The label used to display the message's text.
  open var messageLabel = MessageLabel()
    
    open var translateButton: UIButton = {
        let button = UIButton()
        button.setTitle("", for: .normal)
        let img = UIImage.messageKitImageWith(type: .translate)
        button.setImage(img, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self, action: #selector(onTapTranslate), for: .touchUpInside)
        
        return button
    }()
    
    open var infoView = UIView()
    open var infoLabel = UILabel()
    open var padding: CGFloat = 12.0

  // MARK: - Properties

  /// The `MessageCellDelegate` for the cell.
  open override weak var delegate: MessageCellDelegate? {
    didSet {
      messageLabel.delegate = delegate
    }
  }

  // MARK: - Methods

  open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    if let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes {
      messageLabel.textInsets = attributes.messageLabelInsets
      messageLabel.messageLabelFont = attributes.messageLabelFont
      messageLabel.frame = messageContainerView.bounds
    }
  }

  open override func prepareForReuse() {
    super.prepareForReuse()
    messageLabel.attributedText = nil
    messageLabel.text = nil
      
      infoView.isHidden = true
  }

  open override func setupSubviews() {
    super.setupSubviews()
    messageContainerView.addSubview(messageLabel)
      
      messageContainerView.addSubview(translateButton)
      NSLayoutConstraint.activate([
        translateButton.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -padding),
        translateButton.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -8.0),
        translateButton.widthAnchor.constraint(equalToConstant: 24.0),
        translateButton.heightAnchor.constraint(equalToConstant: 24.0)
      ])
      
      self.addSubview(infoView)
      infoView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        infoView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4.0),
        infoView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4.0),
        infoView.topAnchor.constraint(equalTo: messageContainerView.topAnchor),
        infoView.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor),
      ])
      infoView.layer.cornerRadius = 16
      infoView.clipsToBounds = true
      
      infoView.removeBlurEffects()
      let visualEffectView = UIVisualEffectView.init(effect: UIBlurEffect.init(style: .dark))
      visualEffectView.backgroundColor = UIColor.blur.withAlphaComponent(0.2)
      infoView.addSubview(visualEffectView)
      visualEffectView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        visualEffectView.leadingAnchor.constraint(equalTo: infoView.leadingAnchor),
        visualEffectView.trailingAnchor.constraint(equalTo: infoView.trailingAnchor),
        visualEffectView.topAnchor.constraint(equalTo: infoView.topAnchor),
        visualEffectView.bottomAnchor.constraint(equalTo: infoView.bottomAnchor),
      ])
      
      infoView.addSubview(infoLabel)
      infoLabel.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        infoLabel.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: padding),
        infoLabel.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -padding),
        infoLabel.topAnchor.constraint(equalTo: messageContainerView.topAnchor, constant: padding / 2.0),
        infoLabel.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -padding / 2.0),
      ])
      infoLabel.numberOfLines = 0
  }

  open override func configure(
    with message: MessageType,
    at indexPath: IndexPath,
    and messagesCollectionView: MessagesCollectionView)
  {
    super.configure(with: message, at: indexPath, and: messagesCollectionView)

    guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
      fatalError(MessageKitError.nilMessagesDisplayDelegate)
    }

    let enabledDetectors = displayDelegate.enabledDetectors(for: message, at: indexPath, in: messagesCollectionView)

    messageLabel.configure {
      messageLabel.enabledDetectors = enabledDetectors
      for detector in enabledDetectors {
        let attributes = displayDelegate.detectorAttributes(for: detector, and: message, at: indexPath)
        messageLabel.setAttributes(attributes, detector: detector)
      }
      let textMessageKind = message.kind.textMessageKind
      switch textMessageKind {
      case .text(let text), .emoji(let text):
        let textColor = displayDelegate.textColor(for: message, at: indexPath, in: messagesCollectionView)
        messageLabel.text = text
        messageLabel.textColor = textColor
          infoLabel.text = text
          infoLabel.textColor = textColor
        if let font = messageLabel.messageLabelFont {
          messageLabel.font = font
            infoLabel.font = font
        }
      case .attributedText(let text):
        messageLabel.attributedText = text
          infoLabel.attributedText = text
      default:
        break
      }
    }

      infoView.backgroundColor = messageContainerView.backgroundColor
      infoView.isHidden = !(indexPath.row == 0 && indexPath.section == 0)
      messageContainerView.isHidden = indexPath.row == 0 && indexPath.section == 0

      guard let dataSource = messagesCollectionView.messagesDataSource else {
          return
      }
      translateButton.isHidden = dataSource.isFromCurrentSender(message: message)
  }

  /// Used to handle the cell's contentView's tap gesture.
  /// Return false when the contentView does not need to handle the gesture.
  open override func cellContentView(canHandle touchPoint: CGPoint) -> Bool {
    messageLabel.handleGesture(touchPoint)
  }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        guard isUserInteractionEnabled else { return nil }

        guard !isHidden else { return nil }

        guard alpha >= 0.01 else { return nil }

        guard self.point(inside: point, with: event) else { return nil }


        // add one of these blocks for each button in our collection view cell we want to actually work
        if translateButton.point(inside: convert(point, to: translateButton), with: event) {
            return translateButton
        }

        return super.hitTest(point, with: event)
    }
    
    @objc func onTapTranslate(sender:UIButton!) {
        delegate?.didTapTranslate(in: self)
    }
}
