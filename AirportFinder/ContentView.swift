import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = AirportSearchViewModel()
    
    var body: some View {
        TabView {

            NavigationView {
                VStack(spacing: 0) {
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("Місто або код...", text: $viewModel.searchText)
                                    .submitLabel(.search)
                                    .onSubmit {
                                        viewModel.search()
                                    }
                                
                                if !viewModel.searchText.isEmpty {
                                    Button(action: { viewModel.searchText = "" }) {
                                        Image(systemName: "multiply.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            if !viewModel.airports.isEmpty || !viewModel.searchText.isEmpty {
                                Button(action: {
                                    hideKeyboard()
                                    viewModel.clearSearch()
                                }) {
                                    Image(systemName: "house.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                        .padding(10)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                .transition(.scale)
                            }
                        }
                        
                        if viewModel.airports.isEmpty {
                            Button(action: {
                                hideKeyboard()
                                viewModel.requestUserLocation()
                            }) {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text("Знайти найближчий аеропорт")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    
                    ZStack {
                        Color(.systemBackground)
                            .onTapGesture {
                                hideKeyboard()
                            }
                        
                        if viewModel.isLoading {
                            ProgressView("Шукаємо...")
                        } else if let error = viewModel.errorMessage {
                            VStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                Text(error)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                            .onTapGesture { hideKeyboard() }
                        } else if viewModel.airports.isEmpty {
                            VStack(spacing: 20) {
                                Spacer()
                                Image(systemName: "globe.europe.africa.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.blue.opacity(0.2))
                                
                                Text("Картотека Аеропортів")
                                    .font(.title2)
                                    .bold()
                                
                                Text("Введіть назву міста або натисніть\nкнопку визначення локації")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                                Spacer()
                                Spacer()
                            }
                            .onTapGesture { hideKeyboard() }
                        } else {
                            List(viewModel.airports) { airport in
                                NavigationLink(destination: AirportDetailView(airport: airport, viewModel: viewModel)) {
                                    AirportRow(airport: airport)
                                }
                            }
                            .listStyle(.plain)
                            .scrollDismissesKeyboard(.immediately)
                        }
                    }
                }
                .navigationTitle("Пошук")
                .navigationBarTitleDisplayMode(.inline)
                .alert("Потрібен доступ до локації", isPresented: $viewModel.showSettingsAlert) {
                    Button("Налаштування", role: .none) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Скасувати", role: .cancel) {}
                } message: {
                    Text("Будь ласка, перейдіть в налаштування і дозвольте програмі використовувати GPS.")
                }
            }
            .tabItem {
                Label("Пошук", systemImage: "magnifyingglass")
            }
            

            NavigationView {
                Group {
                    if viewModel.visitedAirports.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "airplane.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Ви ще не зберегли жодного аеропорту")
                                .foregroundColor(.gray)
                        }
                    } else {
                        List(viewModel.visitedAirports) { airport in
                            NavigationLink(destination: AirportDetailView(airport: airport, viewModel: viewModel)) {
                                AirportRow(airport: airport)
                            }
                        }
                    }
                }
                .navigationTitle("Мої подорожі")
                .onAppear {
                    viewModel.fetchVisited()
                }
            }
            .tabItem {
                Label("Відвідані", systemImage: "airplane.circle")
            }
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AirportRow: View {
    let airport: Airport
    
    var body: some View {
        HStack {
            Text(airport.flagEmoji)
                .font(.largeTitle)
            
            VStack(alignment: .leading) {
                Text(airport.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    if let iata = airport.iata {
                        Text(iata)
                            .font(.caption)
                            .bold()
                            .padding(3)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    Text(airport.countryNameUA)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
