//
//  ClearBackGround.swift
//  AutoTrading
//
//  Created by loyH on 5/6/25.
//

import Foundation
import SwiftUI
import UIKit

struct BlackTransparentBackground: UIViewRepresentable {
    
    public func makeUIView(context: Context) -> UIView {
        
        let view = BlackTransparentBackgroundView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
}

class BlackTransparentBackgroundView: UIView {
    open override func layoutSubviews() {
        guard let parentView = superview?.superview else {
            return
        }
        parentView.backgroundColor = .clear
    }
}
