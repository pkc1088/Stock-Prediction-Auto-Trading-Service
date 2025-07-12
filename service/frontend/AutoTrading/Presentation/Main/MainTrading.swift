//
//  MainTrading.swift
//  AutoTrading
//
//  Created by loyH on 4/12/25.
//


import Foundation
import SwiftUI
import ComposableArchitecture
import Translation

@Reducer
struct MainTrading {
    @Reducer(state: .equatable)
    enum Destination {
        case search(MainSearch)
    }
    
    @ObservableState
    struct State: Equatable{
        @Presents var destination: Destination.State?
        
        var holdings: [Holding]
        var stock: Stock
        var buyPrice: String
        var priceError: String?
        var showSuccessPopup: Bool = false
        var showErrorPopup: Bool = false
        
        init(holdings: [Holding] = [], stock: Stock) {
            self.holdings = holdings
            self.stock = stock
            self.buyPrice = String(format: "%.2f", stock.predictedPrice)
        }
    }
    
    enum Action: BindableAction{
        case binding(BindingAction<State>)
        case goToSearch
        case validatePrice
        case startTrading
        case toggleSuccessPopup
        case toggleErrorPopup
        
        case delegate(Delegate)
        case destination(PresentationAction<Destination.Action>)
        @CasePathable
        enum Delegate: Equatable {
        }
    }
    
    var body: some ReducerOf<Self>{
        BindingReducer()
        Reduce{ state, action in
            switch action{
            case .validatePrice:
                if let _ = Double(state.buyPrice) {
                    state.priceError = nil
                } else {
                    state.priceError = "유효한 가격을 입력해주세요"
                }
                return .none
                
            case .goToSearch:
                state.destination = .search(.init())
                return .none
                
            case .startTrading:
                return .run { [symbol = state.stock.symbol, name = state.stock.name, price = state.buyPrice]send in
                    await withCheckedContinuation { continuation in
                        let request = TradeRequest(symbol: symbol, name: name, predictedPrice: Double(price)!)
                        guard let requestData = try? JSONEncoder().encode(request) else {
                            print("trade encoding error")
                            DispatchQueue.main.async {
                                send(.toggleErrorPopup)
                                continuation.resume()
                            }
                            return
                        }
                        HttpRequest()
                            .setPath(.startTrading)
                            .setMethod("POST")
                            .setBody(requestData)
                            .setHeader("Content-Type", "application/json")
                            .sendRequest(
                                onSuccess: { response in
                                    DispatchQueue.main.async {
                                        send(.toggleSuccessPopup)
                                        continuation.resume()
                                    }
                                },
                                onFailure: {
                                    DispatchQueue.main.async {
                                        send(.toggleErrorPopup)
                                        continuation.resume()
                                    }
                                }
                            )
                    }
                }
                
            case .toggleSuccessPopup:
                state.showSuccessPopup.toggle()
                return .none
                
            case .toggleErrorPopup:
                state.showErrorPopup.toggle()
                return .none
                
            case let .destination(.presented(.search(.delegate(delegateAction)))):
                switch delegateAction{
                case let .setStock(stock):
                    state.destination = nil
                    state.stock = stock
                    state.buyPrice = String(stock.predictedPrice)
                    return .none
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


struct MainTradingView: View {
    @Bindable var store: StoreOf<MainTrading>
    @State var index: Int = 0
    @State private var showTranslation = false
    let periods: [String] = ["1W", "1M", "3M", "6Y", "1Y"]
    let periodsCount: [Int] = [7, 30, 90, 180, 365]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView{
                VStack(spacing: 20) {
                    Spacer().frame(height: 10)
                    // 차트 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        // 가격 정보
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("$\(String(format: "%.2f", store.stock.price))")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.lightBlack)
                                Text("\(store.stock.symbol)")
                                    .font(.r_14())
                                    .foregroundStyle(.mediumGray)
                            }
                            Spacer()
                            
                            // 가격 변동률
                            let priceChangePercent = (store.stock.price - store.stock.predictedPrice) / store.stock.predictedPrice * 100
                            let isPriceUp = priceChangePercent >= 0
                            let changeColor: Color = isPriceUp ? .lofiGreen : .red
                            
                            HStack(spacing: 4) {
                                Image(systemName: isPriceUp ? "arrow.up.right" : "arrow.down.right")
                                    .foregroundStyle(changeColor)
                                Text("\(String(format: "%.1f", abs(priceChangePercent)))%")
                                    .font(.r_14())
                                    .foregroundStyle(changeColor)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(changeColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        
                        // 차트
                        LineGraph(data: store.stock.prices.suffix(periodsCount[index]))
                            .frame(height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // 기간 선택 버튼
                        HStack(spacing: 8){
                            ForEach(0..<5) { i in
                                Button(action: {
                                    index = i
                                }, label: {
                                    Text(periods[i])
                                        .font(.r_14())
                                        .foregroundStyle((index == i) ? .white : .lightBlack)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background((index == i) ? .lightBlack : .backgroundGray)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                })
                            }
                        }
                    }
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    // 예측 정보 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        Text("예측 정보")
                            .font(.s_18())
                            .foregroundStyle(.lightBlack)
                        
                        VStack(spacing: 16) {
                            TradingInfoRow(title: "예상 가격", value: "$\(String(format: "%.2f", store.stock.predictedPrice))", valueColor: .lightBlack)
                            
                            // 감성 분석 섹션
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("감성 분석")
                                        .font(.r_14())
                                        .foregroundStyle(.mediumGray)
                                    Spacer()
                                    Button(action: {
                                        showTranslation.toggle()
                                    }) {
                                        HStack(spacing: 2) {
                                            Image(systemName: "translate")
                                                .font(.system(size: 12))
                                            Text("번역")
                                                .font(.r_11())
                                        }
                                        .foregroundStyle(.lightBlack)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.backgroundGray)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .translationPresentation(isPresented: $showTranslation, text: store.stock.sentimentAnalysis)
                                }
                                
                                Text(store.stock.sentimentAnalysis)
                                    .font(.r_14())
                                    .foregroundStyle(.lightBlack)
                                    .multilineTextAlignment(.leading)
                                
                                // 감성 점수 그래프
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Spacer()
                                        Text("\(Int(store.stock.sentimentScore * 100))%")
                                            .font(.r_12())
                                            .foregroundStyle(.mediumGray)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.backgroundGray)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            // 배경 바
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.backgroundGray)
                                                .frame(height: 8)
                                            
                                            // 감성 점수 바
                                            let normalizedScore = (store.stock.sentimentScore + 1) / 2.0 //
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.red.opacity(0.9), .yellow.opacity(0.9), .lofiGreen.opacity(0.9)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: geometry.size.width * normalizedScore, height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            }
                            
                            Divider()
                            
                            // 가격 입력 필드
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 12) {
                                    TextField("매수 가격", text: $store.buyPrice)
                                        .font(.r_14())
                                        .foregroundStyle(.lightBlack)
                                        .keyboardType(.decimalPad)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(.backgroundGray)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .onChange(of: store.buyPrice) { _, _ in
                                            store.send(.validatePrice)
                                        }
                                    
                                    Button(action: {
                                        store.send(.startTrading)
                                        UIApplication.shared.hideKeyboard()
                                    }) {
                                        Text("매수")
                                            .font(.s_14())
                                            .foregroundStyle(.white)
                                            .frame(width: 80)
                                            .padding(.vertical, 10)
                                            .background(store.priceError == nil ? .lofiGreen : .mediumGray)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .disabled(store.priceError != nil)
                                }
                                
                                if let error = store.priceError {
                                    Text(error)
                                        .font(.r_12())
                                        .foregroundStyle(.red)
                                        .padding(.leading, 4)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .background(.backgroundWhite)
            .onTapGesture(perform: {
                UIApplication.shared.hideKeyboard()
            })
            .overlay {
                if store.showSuccessPopup {
                    VStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.lofiGreen)
                            Text("트레이딩이 시작되었습니다")
                                .font(.s_16())
                                .foregroundStyle(.lightBlack)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 32)
                        .onTapGesture {
                            store.send(.toggleSuccessPopup)
                        }
                        Spacer()
                    }
                    .background(.black.opacity(0.5))
                    .ignoresSafeArea()
                }
                
                if store.showErrorPopup {
                    VStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.red)
                            Text("오류가 발생했습니다")
                                .font(.s_16())
                                .foregroundStyle(.lightBlack)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 32)
                        .onTapGesture {
                            store.send(.toggleErrorPopup)
                        }
                        Spacer()
                    }
                    .background(.black.opacity(0.5))
                    .ignoresSafeArea()
                }
            }
            .basicToolbar(
                titleView: AnyView(
                    HStack{
                        VStack(alignment: .leading, spacing: 4){
                            Text(store.stock.symbol)
                                .font(.s_20())
                                .foregroundStyle(.white)
                            Text(store.stock.name)
                                .font(.r_12())
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                ),
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
                NavigationStack{
                    MainSearchView(store: store)
                }
            })
        }
    }
}

// 거래 정보 행 컴포넌트
struct TradingInfoRow: View {
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.r_14())
                .foregroundStyle(.mediumGray)
            Spacer()
            Text(value)
                .font(.r_14())
                .foregroundStyle(valueColor)
        }
    }
}

#Preview {
    MainTradingView(store: Store(initialState: MainTrading.State(holdings: [], stock: testStock1), reducer: {
        MainTrading()
    }))
}
