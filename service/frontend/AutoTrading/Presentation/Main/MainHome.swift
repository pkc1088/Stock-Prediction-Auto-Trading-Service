//
//  MainHome.swift
//  AutoTrading
//
//  Created by loyH on 3/18/25.
//

import Foundation
import SwiftUI
import ComposableArchitecture


@Reducer
struct MainHome {
    @Reducer(state: .equatable)
    enum Destination {
        case search(MainSearch)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        var holdings: [Holding]
        var isNoHoldings: Bool = false
        var isSearching: Bool = false
        
        init(holdings: [Holding] = []) {
            self.holdings = holdings
        }
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case goToSearch
        case goToTrading(String, String)
        case getHoldings
        case setHoldings([Holding])
        case onIsNoHoldings
        case offIsSearching
        
        case delegate(Delegate)
        case destination(PresentationAction<Destination.Action>)
        @CasePathable
        enum Delegate: Equatable {
            case goToTrading(Stock)
        }
    }
    
    var body: some ReducerOf<Self>{
        BindingReducer()
        Reduce{ state, action in
            switch action{
            case .goToSearch:
                state.destination = .search(.init())
                return .none
            case let .goToTrading(name, symbol):
                state.isSearching = true
                return .run { [name, symbol]send in
                    await withCheckedContinuation { continuation in
                        print("stock request \(symbol) \(name)")
                        let request = StockRequest(name: name, symbol: symbol)
                        guard let requestData = try? JSONEncoder().encode(request) else {
                            print("stock encoding error")
                            DispatchQueue.main.async {
                                send(.offIsSearching)
                            }
                            continuation.resume()
                            return
                        }
                        print("request body: \(String(data: requestData, encoding: .utf8) ?? "")")
                        HttpRequest()
                            .setPath(.getStock)
                            .setMethod("POST")
                            .setBody(requestData)
                            .setHeader("Content-Type", "application/json")
                            .sendRequest(
                                onSuccess: { response in
                                    if let stock = try? JSONDecoder().decode(Stock.self, from: response.data(using: .utf8)!) {
                                        DispatchQueue.main.async {
                                            print("stock response \(stock)")
                                            send(.delegate(.goToTrading(stock)))
                                            send(.offIsSearching)
                                            continuation.resume()
                                        }
                                    }
                                    else {
                                        print("stock decode error")
                                        DispatchQueue.main.async {
                                            send(.offIsSearching)
                                        }
                                        continuation.resume()
                                    }
                                },
                                onFailure: {
                                    print("get stock data error")
                                    DispatchQueue.main.async {
                                        send(.offIsSearching)
                                    }
                                    continuation.resume()
                                }
                            )
                    }
                }
            case .getHoldings:
                state.isNoHoldings = false
                print("start get holdings")
                return .run { []send in
                    await withCheckedContinuation { continuation in
                        HttpRequest()
                            .setPath(.getHoldings)
                            .setMethod("GET")
                            .sendRequest(
                                onSuccess: { response in
                                    if let holdingsResponse = try? JSONDecoder().decode(HoldingsResponse.self, from: response.data(using: .utf8)!) {
                                        DispatchQueue.main.async {
                                            print("holdings response \(holdingsResponse)")
                                            send(.setHoldings(holdingsResponse.holdings))
                                            continuation.resume()
                                        }
                                    }
                                    else {
                                        print("holdings decode error")
                                        DispatchQueue.main.async {
                                            send(.onIsNoHoldings)
                                        }
                                        continuation.resume()
                                    }
                                },
                                onFailure: {
                                    print("get holdings data error")
                                    DispatchQueue.main.async {
                                        send(.onIsNoHoldings)
                                    }
                                    continuation.resume()
                                }
                            )
                    }
                }
            case .onIsNoHoldings:
                state.isNoHoldings = true
                return .none
            case let .setHoldings(holdings):
                state.holdings = holdings
                if holdings.isEmpty {
                    state.isNoHoldings = true
                }
                return .none
            case .offIsSearching:
                state.isSearching = false
                return .none
                
            case let .destination(.presented(.search(.delegate(delegateAction)))):
                switch delegateAction{
                case let .setStock(stock):
                    state.destination = nil
                    return .send(.delegate(.goToTrading(stock)))
                }
                
                
            case .destination:
                return .none
            case .delegate:
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}


struct MainHomeView: View {
    @Bindable var store: StoreOf<MainHome>
    
    var body: some View {
        GeometryReader { geometry in
            if !store.holdings.isEmpty{
                ScrollView{
                    VStack(spacing: 16) {
                        // 보유 종목 목록
                        VStack(alignment: .leading, spacing: 12) {
                            Text("보유 종목")
                                .font(.s_18())
                                .foregroundStyle(.lightBlack)
                                .padding(.horizontal, 4)
                            
                            ForEach(store.holdings, id: \.name) { holding in
                                HoldingCard(holding: holding)
                            }
                        }
                    }
                }
                .padding(16)
            }
            else {
                VStack(spacing: 24) {
                    if !store.isNoHoldings {
                        VStack(spacing: 16) {
                            Spacer()
                            ProgressView()
                                .tint(.lightBlack)
                                .scaleEffect(1.2)
                            Text("보유 주식을 불러오는 중입니다")
                                .font(.r_14())
                                .foregroundStyle(.mediumGray)
                            Spacer()
                        }
                    }
                    else {
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 48))
                                .foregroundStyle(.mediumGray)
                            
                            VStack(spacing: 8) {
                                Text("보유 주식이 없습니다")
                                    .font(.s_18())
                                    .foregroundStyle(.lightBlack)
                                Text("첫 주식을 검색해보세요")
                                    .font(.r_14())
                                    .foregroundStyle(.mediumGray)
                            }
                            
                            Button(action: {
                                store.send(.getHoldings)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 16))
                                    Text("다시 시도하기")
                                        .font(.r_14())
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.lightBlack)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            // 로딩 오버레이
            if store.isSearching {
                ZStack {
                    Color.black.opacity(0.7)
                        .background(BlackTransparentBackground())
                        .ignoresSafeArea(.all)
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                        Text("종목 정보를 불러오는 중입니다")
                            .font(.r_14())
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            store.send(.getHoldings)
        }
        .background(.backgroundWhite)
        .basicToolbar(
            rightButton: AnyView(
                Button(action: {
                    store.send(.goToSearch)
                }, label: {
                    Image(systemName: "magnifyingglass")
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.white)
                })
            )
        )
        .fullScreenCover(item: $store.scope(state: \.destination?.search, action: \.destination.search), content: { store in
            NavigationStack {
                MainSearchView(store: store)
            }
        })
    }
    
    @ViewBuilder
    private func HoldingCard(
        holding: Holding
    ) -> some View {
        Button(action: {
            store.send(.goToTrading(holding.name, holding.symbol))
            
        }, label: {
            HStack(spacing: 16) {
                // 종목 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(holding.name)
                        .font(.s_16())
                        .foregroundStyle(.lightBlack)
                    Text(holding.symbol)
                        .font(.r_12())
                        .foregroundStyle(.mediumGray)
                }
                
                Spacer()
                
                // 수익률 정보
                VStack(alignment: .trailing, spacing: 4) {
                    Text("평균 $\(String(format: "%.2f", holding.avgPrice))")
                        .font(.r_14())
                        .foregroundStyle(.lightBlack)
                    Text("\(holding.quantity)주")
                        .font(.r_12())
                        .foregroundStyle(.mediumGray)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.mediumGray)
            }
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        })
    }
}

#Preview {
    MainHomeView(store: Store(initialState: MainHome.State(holdings: [testHolding]), reducer: {
        MainHome()
    }))
}
