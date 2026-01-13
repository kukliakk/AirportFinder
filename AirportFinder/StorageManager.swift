import Foundation

class StorageManager {
    static let shared = StorageManager()
    private let key = "visited_airports"
    
    func save(airport: Airport) {
        var visited = loadVisited()
        
        let alreadyExists = isVisited(airport: airport, inList: visited)
        
        if !alreadyExists {
            visited.append(airport)
            saveToDisk(visited)
        }
    }
    
    func remove(airport: Airport) {
        var visited = loadVisited()
        visited.removeAll { savedItem in
            return areCoordinatesEqual(savedItem, airport)
        }
        saveToDisk(visited)
    }
    
    func loadVisited() -> [Airport] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Airport].self, from: data) else {
            return []
        }
        return decoded
    }
    
    func isVisited(airport: Airport) -> Bool {
        return isVisited(airport: airport, inList: loadVisited())
    }
    
    private func isVisited(airport: Airport, inList list: [Airport]) -> Bool {
        return list.contains { savedItem in
            return areCoordinatesEqual(savedItem, airport)
        }
    }
    
    private func areCoordinatesEqual(_ a1: Airport, _ a2: Airport) -> Bool {
        let latDiff = abs(a1.location.lat - a2.location.lat)
        let lonDiff = abs(a1.location.lon - a2.location.lon)
        return latDiff < 0.0001 && lonDiff < 0.0001
    }
    
    private func saveToDisk(_ airports: [Airport]) {
        if let encoded = try? JSONEncoder().encode(airports) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
