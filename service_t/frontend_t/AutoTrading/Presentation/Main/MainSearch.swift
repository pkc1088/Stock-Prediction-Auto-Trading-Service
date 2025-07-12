//
//  MainSearch.swift
//  AutoTrading
//
//  Created by loyH on 3/18/25.
//

import Foundation
import SwiftUI
import ComposableArchitecture


@Reducer
struct MainSearch {
    @ObservableState
    struct State: Equatable{
        var stockName: String = ""
        var isSearching: Bool = false
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case getStock(StockInfo)
        case clearStockName
        case dismiss
        case offIsSearching
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case setStock(Stock)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    var body: some ReducerOf<Self>{
        BindingReducer()
        Reduce{ state, action in
            switch action{
            case let .getStock(stockInfo):
                UIApplication.shared.hideKeyboard()
                state.isSearching = true
                return .run { [stockInfo = stockInfo]send in
                    await withCheckedContinuation { continuation in
                        let request = StockRequest(name: stockInfo.name, symbol: stockInfo.symbol)
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
                                            send(.delegate(.setStock(stock)))
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
            case .clearStockName:
                state.stockName = ""
                return .none
            case .dismiss:
                return .run { _ in
                    await self.dismiss()
                }
            case .offIsSearching:
                state.isSearching = false
                return .none
            case .binding(\.stockName):
                return .run { _ in }
            case .binding:
                return .none
            case .delegate(.setStock(_)):
                state.isSearching = false
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

struct MainSearchView: View {
    @Bindable var store: StoreOf<MainSearch>
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack{
                    Spacer()
                    Spacer().frame(width: 24)
                    Text("종목 검색")
                        .font(.s_16())
                        .foregroundStyle(.lightBlack)
                    Spacer()
                    Button(action: {
                        store.send(.dismiss)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.lightBlack)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()

                // 검색 바
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.mediumGray)
                        
                        TextField("종목명 또는 티커를 입력하세요", text: $store.stockName)
                            .font(.r_14())
                            .foregroundStyle(.lightBlack)
                            .autocorrectionDisabled()
                        
                        if !store.stockName.isEmpty {
                            Button(action: {
                                store.send(.clearStockName)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.mediumGray)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.backgroundGray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                
                // 검색 결과
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        let stockInfoList = SP500.filter { 
                            $0.name.localizedCaseInsensitiveContains(store.stockName) || 
                            $0.symbol.localizedCaseInsensitiveContains(store.stockName) 
                        }
                        
                        if !stockInfoList.isEmpty {
                            // 검색 결과 헤더
                            HStack {
                                Text("검색 결과")
                                    .font(.s_16())
                                    .foregroundStyle(.lightBlack)
                                Text("\(stockInfoList.count)")
                                    .font(.r_14())
                                    .foregroundStyle(.mediumGray)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            
                            // 검색 결과 리스트
                            ForEach(stockInfoList, id: \.self) { stockInfo in
                                Button(action: {
                                    store.send(.getStock(stockInfo))
                                }) {
                                    HStack(spacing: 16) {
                                        // 티커 심볼
                                        Text(stockInfo.symbol)
                                            .font(.s_16())
                                            .foregroundStyle(.lightBlack)
                                            .frame(width: 80, alignment: .leading)
                                        
                                        // 종목명
                                        Text(stockInfo.name)
                                            .font(.r_14())
                                            .foregroundStyle(.mediumGray)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.mediumGray)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())
                                }
                                
                                if stockInfo != stockInfoList.last {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        } else if !store.stockName.isEmpty {
                            // 검색 결과가 없을 때
                            VStack(spacing: 16) {
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.mediumGray)
                                Text("검색 결과가 없습니다")
                                    .font(.s_16())
                                    .foregroundStyle(.lightBlack)
                                Text("다른 키워드로 검색해보세요")
                                    .font(.r_14())
                                    .foregroundStyle(.mediumGray)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        }
                    }
                }
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
    }
}



