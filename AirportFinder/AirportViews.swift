import SwiftUI
import MapKit

struct AirportDetailView: View {
    let airport: Airport
    @ObservedObject var viewModel: AirportSearchViewModel
    
    @State private var currentDate = Date()
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: airport.location.lat, longitude: airport.location.lon),
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))) {
                        Marker(airport.name, coordinate: CLLocationCoordinate2D(latitude: airport.location.lat, longitude: airport.location.lon))
                    }
                    .frame(height: 250)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        
                        Text(airport.name)
                            .font(.title)
                            .bold()
                            .padding(.top, 10)
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text(airport.flagEmoji)
                                .font(.system(size: 40))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Країна: \(airport.countryNameUA)")
                                    .font(.headline)
                                
                                HStack {
                                    if let code = airport.countryCode {
                                        Text("Код: \(code)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    if let iata = airport.iata {
                                        Text("IATA: \(iata)")
                                            .font(.caption)
                                            .bold()
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.15))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        if let tzString = airport.timeZone {
                            HStack(alignment: .top) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text("Місцевий час:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(getFormattedTime(tzID: tzString))
                                        .font(.headline)
                                    Text("Зона: \(tzString)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Divider()
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Координати:")
                                .font(.headline)
                            Text("Lat: \(airport.location.lat), Lon: \(airport.location.lon)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            

                            Button(action: {
                                openMaps(lat: airport.location.lat, lon: airport.location.lon, name: airport.name)
                            }) {
                                HStack {
                                    Image(systemName: "car.fill")
                                    Text("Прокласти маршрут")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .padding(.bottom, 15)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            VStack {
                Divider()
                Button(action: {
                    viewModel.toggleVisited(airport: airport)
                }) {
                    HStack {
                        Image(systemName: viewModel.isVisited(airport) ? "checkmark.circle.fill" : "circle")
                        Text(viewModel.isVisited(airport) ? "Відвідано" : "Додати у відвідані")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isVisited(airport) ? Color.green : Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle("Деталі")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { input in
            currentDate = input
        }
    }
    
    func openMaps(lat: Double, lon: Double, name: String) {
        let url = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=d")!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func getFormattedTime(tzID: String) -> String {
        guard let timeZone = TimeZone(identifier: tzID) else { return tzID }
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: currentDate)
        let seconds = timeZone.secondsFromGMT(for: currentDate)
        let hours = seconds / 3600
        let sign = hours >= 0 ? "+" : ""
        return "\(timeString) (UTC \(sign)\(hours))"
    }
}
