//
//  MainFeature.swift
//  AutoTrading
//
//  Created by loyH on 3/18/25.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct MainFeature{
    @Reducer(state: .equatable)
    enum Path {
        case trading(MainTrading)
    }
    
    @ObservableState
    struct State: Equatable{
        var path = StackState<Path.State>()
        var home = MainHome.State(holdings: [])
        var holdings: [Holding] = []
        var stock: Stock?
    }
    
    enum Action{
        case path(StackActionOf<Path>)
        case home(MainHome.Action)
    }
    
    var body: some ReducerOf<Self>{
        Scope(state: \.home, action: \.home){
            MainHome()
        }
        Reduce {state, action in
            switch action{
            case let .home(.delegate(delegateAction)):
                switch delegateAction{
                case let .goToTrading(stock):
                    state.path.append(.trading(.init(holdings: state.holdings, stock: stock)))
                    return .none
                }
                
            case .path:
                return .none
            case .home:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

struct MainNavigation: View {
    @Bindable var store: StoreOf<MainFeature>
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            MainHomeView(store: self.store.scope(state: \.home, action: \.home))
        } destination: { store in
            switch store.case {
            case let .trading(store):
                MainTradingView(store: store)
            }
        }
    }
}
    
