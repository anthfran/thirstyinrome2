import SwiftUI
import MapKit

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
    @State private var selectedPlaceID: String?

    private let romeRegion = MKCoordinateRegion(
        center: ContentView.romeCenter,
        span: MKCoordinateSpan(latitudeDelta: ContentView.clusteringThreshold, longitudeDelta: ContentView.clusteringThreshold)
    )

    var body: some View {
        let result = viewModel.clusteringResult()
        Map(position: $cameraPosition, selection: $selectedPlaceID) {
            if mapSpan > ContentView.clusteringThreshold {
                ForEach(result.clusters) { cluster in
                    Annotation("", coordinate: cluster.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 36, height: 36)
                            Text("\(cluster.count)")
                                .foregroundStyle(.white)
                                .font(.system(size: 14, weight: .bold))
                        }
                        .onTapGesture {
                            zoomToCluster(cluster)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Cluster of \(cluster.count) fountains")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint("Zooms to this cluster")
                    }
                }
                ForEach(result.singles) { place in
                    Marker(
                        place.title ?? "Fontanella",
                        coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
                    )
                    .tag(place.id)
                }
            } else {
                ForEach(viewModel.places) { place in
                    Marker(
                        place.title ?? "Fontanella",
                        coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
                    )
                    .tag(place.id)
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
            LocationButton { location in
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: Self.zoomedInSpan, longitudeDelta: Self.zoomedInSpan)
                ))
            }
            .safeAreaPadding(.bottom)
            .padding(.trailing, 16)
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            mapSpan = context.region.span.latitudeDelta
        }
        .confirmationDialog(
            "Get Directions",
            // confirmationDialog requires Bool; derive from selectedPlaceID being non-nil
            isPresented: Binding(
                get: { selectedPlaceID != nil },
                set: { if !$0 { selectedPlaceID = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let id = selectedPlaceID,
               let place = viewModel.places.first(where: { $0.id == id }) {
                Button("Apple Maps") { openAppleMaps(for: place) }
                if canOpenGoogleMaps() {
                    Button("Google Maps") { openGoogleMaps(for: place) }
                }
            }
            Button("Cancel", role: .cancel) { selectedPlaceID = nil }
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

    private func canOpenGoogleMaps() -> Bool {
        guard let url = URL(string: "comgooglemaps://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    private func openAppleMaps(for place: Place) {
        let coordinate = CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = place.title ?? "Fontanella"
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }

    private func openGoogleMaps(for place: Place) {
        let daddr = String(format: "%.6f,%.6f", place.lat, place.lon)
        guard let url = URL(string: "comgooglemaps://?daddr=\(daddr)&directionsmode=walking") else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ContentView()
        .environment(PlaceViewModel())
}
