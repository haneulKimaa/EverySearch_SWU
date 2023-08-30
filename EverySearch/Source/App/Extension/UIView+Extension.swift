//
//  UIView+Extension.swift
//  EverySearch
//
//  Created by 김하늘 on 2023/08/30.
//

import UIKit

extension UIView {
    func showToast(_ message: String) {
      guard let keyWindow = UIApplication.shared.keyWindow else { return }
      
      let toastLabel = UILabel()
      toastLabel.text = message
      toastLabel.font = .systemFont(ofSize: 15)
      toastLabel.textColor = .white
      toastLabel.textAlignment = .center
      toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
      toastLabel.alpha = 1.0
      toastLabel.layer.cornerRadius = 23
      toastLabel.clipsToBounds = true
      
      let maxToastWidth = keyWindow.frame.width - 40
      let toastWidth = min(maxToastWidth, toastLabel.intrinsicContentSize.width + 65)
      let toastHeight: CGFloat = 45
      let toastX = (keyWindow.frame.width - toastWidth) / 2
      let toastY = keyWindow.frame.height - 200
      
      toastLabel.frame = CGRect(x: toastX, y: toastY, width: toastWidth, height: toastHeight)
      keyWindow.addSubview(toastLabel)
      
      UIView.animate(withDuration: 0.7, delay: 1.8, options: .curveEaseOut, animations: {
        toastLabel.alpha = 0.0
      }, completion: { _ in
        toastLabel.removeFromSuperview()
      })
    }
}
