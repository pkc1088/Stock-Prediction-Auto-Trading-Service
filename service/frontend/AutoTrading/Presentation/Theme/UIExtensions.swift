//
//  UIExtensions.swift
//  AutoTrading
//
//  Created by loyH on 3/18/25.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import UIKit

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

extension View {
    func basicToolbar(
        title: String = "AutoTrading",
        titleView: AnyView? = nil,
        swipeBack: Bool = true,
        rightButton: AnyView? = nil,
        darkToolBar: Bool = true
    ) -> some View {
        self.toolbar {
            ToolbarItem(placement: .principal) {
                if let titleView {
                    titleView
                        .foregroundStyle(darkToolBar ? .white : .lightBlack )
                }
                else {
                    Text(title)
                        .font(.s_16())
                        .foregroundStyle(darkToolBar ? .white : .lightBlack )
                }
            }
            
            if let rightButton = rightButton {
                ToolbarItem(placement: .topBarTrailing) {
                    rightButton
                        .foregroundStyle(darkToolBar ? .white : .lightBlack )
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!swipeBack)
        .toolbarBackground(darkToolBar ? .lightBlack : .white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    func shadow2(color: Color = .black) -> some View {
        return self
            .compositingGroup()
            .shadow(color: color.opacity(color == .black ? 0.1 : 0.3), radius: 6, x: 0, y: 0)
    }
    
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func dismissKeyboard() -> some View {
        return modifier(ResignKeyboardOnDragGesture())
    }
    
    func readHeight() -> some View {
        self
            .modifier(ReadHeightModifier())
    }
}

private struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged { _ in
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}

private struct ReadHeightModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
        }
    }
    
    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat?
    
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        guard let nextValue = nextValue() else { return }
        value = nextValue
    }
}

extension UIApplication {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension UIApplication: @retroactive UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
