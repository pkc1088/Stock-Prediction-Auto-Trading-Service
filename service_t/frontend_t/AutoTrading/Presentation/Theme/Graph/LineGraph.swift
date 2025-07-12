//
//  LineGraph.swift
//  AutoTrading
//
//  Created by loyH on 2/26/25.
//

import Foundation
import SwiftUI
import Charts

struct LineGraph: View {
    var data: [PricePoint]
    @State private var select: String?
    
    var body: some View {
        GeometryReader { geometry in
            let prices = data.map { $0.price }
            let spare = (prices.max()! - prices.min()!) * 0.2
            
            VStack(alignment: .leading, spacing: 20) {
                Spacer().frame(height: 40)
                
                Chart {
                    ForEach(data, id: \.self) { element in
                        LineMark(
                            x: .value("Label", element.date),
                            y: .value("price", element.price)
                        )
                        .foregroundStyle(.balanceBlue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    
                    if let select {
                        RuleMark(x: .value("select", select))
                            .foregroundStyle(.darkGraySet.opacity(0.3))
                            .offset(yStart: -10)
                            .zIndex(-1)
                            .annotation(
                                position: .top,
                                spacing: 0,
                                overflowResolution: .init(
                                    x: .fit(to: .chart),
                                    y: .disabled
                                )
                            ) {
                                VStack(spacing: 4) {
                                    Text(select)
                                        .font(.r_12())
                                        .foregroundStyle(.mediumGray)
                                    Text("$\(String(format: "%.2f", data.first(where: {$0.date == select})!.price))")
                                        .font(.s_16())
                                        .foregroundStyle(.lightBlack)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                    }
                }
                .chartXSelection(value: $select)
                // .chartYScale(domain: minData...maxData)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let price = value.as(Double.self) {
                                Text("\(String(format: "%.0f", price))")
                                    .font(.r_12())
                                    .foregroundStyle(.mediumGray)
                            }
                        }
                    }
                }
                .chartXAxis(.hidden)
                Spacer().frame(height: 10)
            }
        }
    }
}

