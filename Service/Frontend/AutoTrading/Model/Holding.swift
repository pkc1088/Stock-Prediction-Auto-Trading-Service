//
//  Holding.swift
//  AutoTrading
//
//  Created by loyH on 4/28/25.
//

struct Holding: Equatable, Codable, Hashable {
    var name: String
    var symbol: String
    var quantity: Int
    var avgPrice: Double
}


struct HoldingsResponse: Codable {
    let holdings: [Holding]
}