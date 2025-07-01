//
//  TestData.swift
//  AutoTrading
//
//  Created by loyH on 4/28/25.
//

import Foundation

let testStock1: Stock = Stock(
    name: "Apple .inc",
    symbol: "AAPL",
    price: 150.00,
    prices: (1...365).map { day in
        PricePoint(
            date: String(day),
            price: Double.random(in: 100...500)
        )
    },
    predictedPrice: 200.23,
    sentimentAnalysis: "The news reports present a mixed sentiment towards Apple. While the return of Fortnite to the App Store is positive, concerns remain about Apple's reliance on China for production, leading to vulnerability to tariffs and sluggish performance. The overall impact is slightly negative.",
    sentimentScore: 0.21
)

let testStock2: Stock = Stock(
    name: "Alphabet A",
    symbol: "GOOGL",
    price: 130.00,
    prices: (100...465).map { day in
        PricePoint(
            date: String(day),
            price: Double.random(in: 100...1000)
        )
    },
    predictedPrice: 1000.221,
    sentimentAnalysis: "The news reports present a mixed sentiment towards Apple. While the return of Fortnite to the App Store is positive, concerns remain about Apple's reliance on China for production, leading to vulnerability to tariffs and sluggish performance. The overall impact is slightly negative.",
    sentimentScore: 0.81
)

let testHolding: Holding = Holding(name: "Apple .inc", symbol: "AAPL", quantity: 10, avgPrice: 140.0)


func testChartData() -> [(label: String, price: Float)] {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    let startDate = dateFormatter.date(from: "2024-07-04")! // 299일 전
    var testData: [(label: String, price: Float)] = []
    
    for i in 0..<50 {
        if let date = Calendar.current.date(byAdding: .day, value: i, to: startDate) {
            let label = dateFormatter.string(from: date)
            let price = Float.random(in: 0...100)
            testData.append((label: label, price: price))
        }
    }
    
    return testData
}
