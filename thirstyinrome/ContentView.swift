import SwiftUI
import MapKit

private enum LocationButtonState {
    case ready, noFix, unauthorized
}

struct ContentView: View {
    private static let romeCenter = CLLocationCoordinate2D(latitude: 41.899159, longitude: 12.473065)
    // Intentionally matches romeRegion span so clustering switches exactly when zoomed in enough to see individual markers
    private static let clusteringThreshold: Double = 0.027
    private static let zoomedInSpan: Double = 0.01

    @Environment(PlaceViewModel.self) private var viewModel
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: ContentView.romeCenter,
            span: MKCoordinateSpan(latitudeDelta: ContentView.zoomedInSpan, longitudeDelta: ContentView.zoomedInSpan)
        )
    )
    @State private var hasJumpedToUserLocation = false
    @State private var mapSpan: Double = ContentView.zoomedInSpan
    @State private var showGPSWaitToast = false
    @State private var showSettingsAlert = false
    @State private var toastDismissTask: Task<Void, Never>?

    private let romeRegion = MKCoordinateRegion(
        center: ContentView.romeCenter,
        span: MKCoordinateSpan(latitudeDelta: ContentView.clusteringThreshold, longitudeDelta: ContentView.clusteringThreshold)
    )

    private var locationButtonState: LocationButtonState {
        switch viewModel.authorizationStatus {
        case .notDetermined, .denied, .restricted:
            return .unauthorized
        case .authorizedWhenInUse, .authorizedAlways:
            return viewModel.userLocation != nil ? .ready : .noFix
        @unknown default:
            return .unauthorized
        }
    }

    private var locationButtonIcon: String {
        locationButtonState == .noFix ? "location.slash.fill" : "location.fill"
    }

    private var locationButtonColor: Color {
        switch locationButtonState {
        case .ready:        return .blue
        case .noFix:        return Color(red: 0.83, green: 0.18, blue: 0.18)
        case .unauthorized: return Color(UIColor.systemGray)
        }
    }

    var body: some View {
        let result = viewModel.clusteringResult()
        Map(position: $cameraPosition) {
            if mapSpan > ContentView.clusteringThreshold {
                ForEach(result.clusters) { cluster in
                    Annotation("", coordinate: cluster.coordinate) {
                        Button {
                            zoomToCluster(cluster)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 36, height: 36)
                                Text("\(cluster.count)")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                ForEach(result.singles) { place in
                    Marker(
                        place.title ?? "Fontanella",
                        coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
                    )
                }
            } else {
                ForEach(viewModel.places) { place in
                    Marker(
                        place.title ?? "Fontanella",
                        coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
                    )
                }
            }
            UserAnnotation()
        }
        .mapStyle(.standard)
        .ignoresSafeArea()
        .overlay(alignment: .bottomLeading) {
            Button {
                cameraPosition = .region(romeRegion)
            } label: {
                Label("Rome", systemImage: "building.columns")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.75, green: 0.22, blue: 0.17))
            .clipShape(.capsule)
            .shadow(radius: 4)
            .safeAreaPadding(.bottom)
            .padding(.leading, 16)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                handleLocationButtonTap()
            } label: {
                Label("My Location", systemImage: locationButtonIcon)
            }
            .buttonStyle(.borderedProminent)
            .tint(locationButtonColor)
            .clipShape(.capsule)
            .shadow(radius: 4)
            .safeAreaPadding(.bottom)
            .padding(.trailing, 16)
        }
        .overlay(alignment: .bottom) {
            if showGPSWaitToast {
                Text("Waiting for GPS signal\u{2026}")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .transition(.opacity)
                    .padding(.bottom, 80)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showGPSWaitToast)
        .alert("Location Access Required", isPresented: $showSettingsAlert) {
            Button("Open Settings") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To re-center on your position, enable Location in Settings.")
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            mapSpan = context.region.span.latitudeDelta
        }
        .onChange(of: viewModel.userLocation) { _, newLocation in
            guard !hasJumpedToUserLocation, let location = newLocation else { return }
            hasJumpedToUserLocation = true
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: ContentView.zoomedInSpan, longitudeDelta: ContentView.zoomedInSpan)
            ))
        }
    }

    private func handleLocationButtonTap() {
        switch locationButtonState {
        case .ready:
            guard let location = viewModel.userLocation else { return }
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: ContentView.zoomedInSpan, longitudeDelta: ContentView.zoomedInSpan)
            ))
        case .noFix:
            showGPSWaitToast = true
            toastDismissTask?.cancel()
            toastDismissTask = Task {
                do {
                    try await Task.sleep(for: .seconds(2))
                    showGPSWaitToast = false
                } catch {}
            }
        case .unauthorized:
            switch viewModel.authorizationStatus {
            case .notDetermined:
                viewModel.requestAuthorization()
            default:
                showSettingsAlert = true
            }
        }
    }

    private func zoomToCluster(_ cluster: Cluster) {
        let lats = cluster.places.map(\.lat)
        let lons = cluster.places.map(\.lon)
        let minLat = lats.min()!
        let maxLat = lats.max()!
        let minLon = lons.min()!
        let maxLon = lons.max()!
        let latDelta = max(maxLat - minLat, 0.005) * 1.3
        let lonDelta = max(maxLon - minLon, 0.005) * 1.3
        cameraPosition = .region(MKCoordinateRegion(
            center: cluster.coordinate,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        ))
    }
}

#Preview {
    ContentView()
        .environment(PlaceViewModel())
}
