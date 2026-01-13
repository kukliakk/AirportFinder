import Foundation
import Combine
import CoreLocation
import UIKit

@MainActor
class AirportSearchViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var searchText: String = ""
    @Published var airports: [Airport] = []
    @Published var visitedAirports: [Airport] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSettingsAlert: Bool = false
    
    private let apiService = APIService()
    private let storageManager = StorageManager.shared
    private let geocoder = CLGeocoder()
    private let locationManager = CLLocationManager()
    
    private var isUserInitiatedLocationRequest = false
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        fetchVisited()
    }
    
    func clearSearch() {
        searchText = ""
        airports = []
        errorMessage = nil
        isLoading = false
    }
    
    func requestUserLocation() {
        isUserInitiatedLocationRequest = true
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            self.showSettingsAlert = true
            isUserInitiatedLocationRequest = false
        case .authorizedAlways, .authorizedWhenInUse: startTrackingLocation()
        @unknown default: break
        }
    }
    
    private func startTrackingLocation() {
        isLoading = true
        errorMessage = nil
        locationManager.startUpdatingLocation()
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            guard self.isUserInitiatedLocationRequest else { return }
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways: self.startTrackingLocation()
            case .denied, .restricted:
                self.isLoading = false
                self.isUserInitiatedLocationRequest = false
            default: break
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        manager.stopUpdatingLocation()
        
        Task { @MainActor in
            self.isUserInitiatedLocationRequest = false
            if self.searchText == "📍 Пошук поруч зі мною..." { return }
            self.searchText = "📍 Пошук поруч зі мною..."
            
            do {
                let results = try await self.apiService.searchAirportsByLocation(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude
                )
                self.handleResults(results)
            } catch {
                self.errorMessage = "Не вдалося завантажити аеропорти."
                self.isLoading = false
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isUserInitiatedLocationRequest = false
            self.isLoading = false

            if let clError = error as? CLError, clError.code != .denied {
                self.errorMessage = "Помилка GPS"
            }
        }
    }
    
    func search() {
        guard !searchText.isEmpty else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var results: [Airport] = []
                if containsCyrillic(searchText) {

                    do {
                        let placemarks = try await geocoder.geocodeAddressString(searchText)
                        if let location = placemarks.first?.location {
                            results = try await apiService.searchAirportsByLocation(
                                lat: location.coordinate.latitude,
                                lon: location.coordinate.longitude
                            )
                        } else {

                            throw NSError(domain: "App", code: 404, userInfo: [NSLocalizedDescriptionKey: "Місто не знайдено"])
                        }
                    } catch {
                        
                        self.errorMessage = "Місто не знайдено. Спробуйте англійською (Chicago) або перевірте назву."
                        self.isLoading = false
                        return
                    }
                } else {
                    results = try await apiService.searchAirports(query: searchText)
                }
                
                self.handleResults(results)
                
            } catch {
                self.airports = []
                self.errorMessage = "Нічого не знайдено або помилка мережі."
                self.isLoading = false
            }
        }
    }
    
    private func handleResults(_ results: [Airport]) {
        let filtered = filterDuplicates(airports: results)
        if filtered.isEmpty {
            self.errorMessage = "Аеропортів не знайдено."
            self.airports = []
        } else {
            self.airports = filtered
        }
        self.isLoading = false
    }
    
    private func filterDuplicates(airports: [Airport]) -> [Airport] {
        var uniqueDict: [String: Airport] = [:]
        for airport in airports {
            let key: String
            if let iata = airport.iata?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), !iata.isEmpty {
                key = iata
            } else {
                key = "\(airport.name)_\(airport.location.lat)"
            }
            if uniqueDict[key] == nil {
                uniqueDict[key] = airport
            }
        }
        return Array(uniqueDict.values).sorted { $0.name < $1.name }
    }
    
    private func containsCyrillic(_ text: String) -> Bool {
        return text.range(of: "\\p{Cyrillic}", options: .regularExpression) != nil
    }
    
    func toggleVisited(airport: Airport) {
        if storageManager.isVisited(airport: airport) {
            storageManager.remove(airport: airport)
        } else {
            storageManager.save(airport: airport)
        }
        fetchVisited()
    }
    
    func fetchVisited() {
        self.visitedAirports = storageManager.loadVisited()
    }
    
    func isVisited(_ airport: Airport) -> Bool {
        return storageManager.isVisited(airport: airport)
    }
}
