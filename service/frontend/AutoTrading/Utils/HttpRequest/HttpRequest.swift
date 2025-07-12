//
//  HttpRequest.swift
//  AutoTrading
//
//  Created by loyH on 4/12/25.
//

import Foundation

let apiURL = "https://723f-61-42-109-11.ngrok-free.app"

enum RequestPath: String {
    case getStock = "/predict"
    case getHoldings = "/holding"
    case startTrading = "/trade"
}


class HttpRequest {
    
    private var components: URLComponents?
    private var request: URLRequest?
    private var retry: Int = 0
    
    init(_ url: String = apiURL) {
        self.components = .init(string: url)
    }
    
    func setPath(_ path: RequestPath) -> Self {
        components?.path = path.rawValue
        return self
    }
    
    func setParams(name: String, value: String?) -> Self {
        if self.components?.queryItems == nil {
            self.components?.queryItems = [
                URLQueryItem(name: name, value: value)
            ]
        } else {
            self.components?.queryItems?.append(URLQueryItem(name: name, value: value))
        }
        
        return self
    }
    
    func setMethod(_ method: String) -> Self {
        guard let url = components?.url else { return self }
        
        request = URLRequest(url: url)
        if components?.path == RequestPath.getStock.rawValue {
            request?.timeoutInterval = 360
        }
        
        request?.httpMethod = method
        request?.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return self
    }
    
    func setHeader(_ name: String, _ value: String) -> Self {
        request?.setValue(value, forHTTPHeaderField: name)
        return self
    }
    
    func setBody(_ body: String) -> Self {
        request?.httpBody = body.data(using: .utf8)
        return self
    }
    
    func setBody(_ body: Data) -> Self {
        request?.httpBody = body
        return self
    }
    
    func setToken(_ token: String) -> Self {
        request?.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return self
    }
    
    func sendRequest(onSuccess: @escaping (String) -> (), onFailure: @escaping () -> ()) {
        guard let request else {
            print("request Error")
            onFailure()
            return
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                #if DEBUG
                print("HttpRequest/sendRequest: error from server - \(error)")
                #endif
                // 리트라이
//                if self.retry < 2 {
//                    self.retry += 1
//                    self.sendRequest(onSuccess: onSuccess, onFailure: onFailure)
//                } else {
//                    print("retry Error")
//                    onFailure()
//                }
                return
            }
            guard let data else { return }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 400 {
                    print("reponse Error \(httpResponse.statusCode)")
                    onFailure()
                } else {
                    guard let str = String(data: data, encoding: .utf8) else { return }
                    print("returned Str = \(str) ")
                    print(httpResponse.statusCode)
                    onSuccess(str)
                }
            }
        }
        task.resume()
    }
    
    func sendRequestToken(onSuccess: @escaping (String) -> (), onFailure: @escaping () -> ()) {
        guard let request else {
            print("request Error")
            onFailure()
            return
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                #if DEBUG
                print("HttpRequest/sendRequest: error from server - \(error)")
                #endif
                if self.retry < 2 {
                    self.retry += 1
                    self.sendRequestToken(onSuccess: onSuccess, onFailure: onFailure)
                } else {
                    print("retry Error")
                    onFailure()
                }
                return
            }
            guard let data else { return }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 400 {
                    print("reponse Error \(httpResponse.statusCode)")
                    onFailure()
                } else {
                    guard let str = String(data: data, encoding: .utf8) else { return }
                    print("returned Str = \(str) ")
                    print(httpResponse.statusCode)
                    
                    if let accessToken = httpResponse.value(forHTTPHeaderField: "access") {
                        onSuccess(accessToken)
                    } else {
                        onFailure()
                    }
                    
                }
            }
        }
        task.resume()
    }
}
