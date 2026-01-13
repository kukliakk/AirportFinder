import Foundation

class APIService {
    private let apiKey = "a54f95468cmsh986886fd8022fe4p1c724bjsnd40900a1647a"
    private let apiHost = "aerodatabox.p.rapidapi.com"
    
    func searchAirports(query: String) async throws -> [Airport] {
        let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://aerodatabox.p.rapidapi.com/airports/search/term?q=\(queryEncoded)&limit=10") else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url)
    }
    
    func searchAirportsByLocation(lat: Double, lon: Double) async throws -> [Airport] {
        guard let url = URL(string: "https://aerodatabox.p.rapidapi.com/airports/search/location/\(lat)/\(lon)/km/100/10") else {
            throw URLError(.badURL)
        }
        return try await performRequest(url: url)
    }
    
    private func performRequest(url: URL) async throws -> [Airport] {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decodedResponse = try JSONDecoder().decode(AirportResponse.self, from: data)
        return decodedResponse.items
    }
}
