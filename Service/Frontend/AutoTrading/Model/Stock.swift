//
//  Stock.swift
//  AutoTrading
//
//  Created by loyH on 3/18/25.
//
//


struct Stock: Equatable, Codable, Hashable {
    let name: String
    let symbol: String
    var price: Double
    var prices: [PricePoint]
    var predictedPrice: Double
    var sentimentAnalysis: String
    var sentimentScore: Double
}

struct PricePoint: Codable, Equatable, Hashable {
    let date: String
    let price: Double
}

struct StockRequest: Codable {
    let name: String
    let symbol: String
}

struct TradeRequest: Codable {
    let symbol: String
    let name: String
    let predictedPrice: Double
}

