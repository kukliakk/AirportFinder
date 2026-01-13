import Foundation

struct Airport: Codable, Identifiable, Hashable {
    private let apiID: Int?
    
    let iata: String?
    let icao: String?
    let name: String
    let location: Location
    let countryCode: String?
    let timeZone: String?
    
    
    var id: String {
        return "\(name)_\(location.lat)_\(location.lon)"
    }
    
    enum CodingKeys: String, CodingKey {
        case apiID = "id"
        case iata, icao, name, location, countryCode, timeZone
    }
    
    var uniqueID: String {
        return iata ?? name
    }
    
    var flagEmoji: String {
        guard let countryCode = countryCode else { return "🌍" }
        let base: UInt32 = 127397
        var s = ""
        for v in countryCode.uppercased().unicodeScalars {
            s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
        }
        return s
    }
    
    var countryNameUA: String {
        guard let code = countryCode else { return "Невідома країна" }
        let ukrLocale = Locale(identifier: "uk_UA")
        return ukrLocale.localizedString(forRegionCode: code) ?? code
    }
    
    static func == (lhs: Airport, rhs: Airport) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Location: Codable, Hashable {
    let lat: Double
    let lon: Double
}

struct AirportResponse: Codable {
    let items: [Airport]
}
