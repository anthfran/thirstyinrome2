import SwiftUI
import MapKit
import Combine

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
    @State private var currentCameraDistance: Double = 1000
    @State private var selectedPlaceID: String?
    @State private var selectedPlace: Place?
    @State private var isHeadingUp = false
    @State private var displayedHeading: Double = 0
    @State private var currentCameraHeading: Double = 0

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
                        .accessibilityLabel(Text("Cluster of \(cluster.count) fountains"))
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint(Text("Zooms to this cluster"))
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
            if let location = viewModel.userLocation {
                Annotation("", coordinate: location.coordinate) {
                    HeadingCone()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .rotationEffect(isHeadingUp ? .zero : .degrees(viewModel.currentHeading - currentCameraHeading))
                }
            }
            UserAnnotation()
        }
        .mapStyle(.standard)
        .mapControls { }
        .ignoresSafeArea()
        .overlay(alignment: .bottomLeading) {
            Button {
                isHeadingUp = false
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
                isHeadingUp = false
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: Self.zoomedInSpan, longitudeDelta: Self.zoomedInSpan)
                ))
            }
            .safeAreaPadding(.bottom)
            .padding(.trailing, 16)
        }
        .overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: 8) {
                MapCompass()
                Button {
                    isHeadingUp.toggle()
                    if isHeadingUp, let location = viewModel.userLocation {
                        displayedHeading = viewModel.currentHeading
                        withAnimation(.easeOut(duration: 0.5)) {
                            cameraPosition = .camera(MapCamera(
                                centerCoordinate: location.coordinate,
                                distance: currentCameraDistance,
                                heading: displayedHeading,
                                pitch: 0
                            ))
                        }
                    }
                } label: {
                    Label("Compass", systemImage: "safari").labelStyle(.iconOnly)
                }
                .buttonStyle(.borderedProminent)
                .tint(isHeadingUp ? .blue : Color(UIColor.systemGray))
                .clipShape(.capsule)
                .shadow(radius: 4)
            }
            .safeAreaPadding(.top)
            .padding(.trailing, 16)
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            mapSpan = context.region.span.latitudeDelta
            currentCameraDistance = context.camera.distance
            currentCameraHeading = context.camera.heading
        }
        .onChange(of: selectedPlaceID) { _, newID in
            selectedPlace = newID.flatMap { id in viewModel.places.first { $0.id == id } }
        }
        .sheet(item: $selectedPlace, onDismiss: { selectedPlaceID = nil }) { place in
            FountainSheet(place: place)
        }
        .onChange(of: viewModel.userLocation) { _, newLocation in
            guard let location = newLocation else { return }
            if !hasJumpedToUserLocation {
                hasJumpedToUserLocation = true
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: ContentView.zoomedInSpan, longitudeDelta: ContentView.zoomedInSpan)
                ))
                return
            }
            guard isHeadingUp else { return }
            cameraPosition = .camera(MapCamera(
                centerCoordinate: location.coordinate,
                distance: currentCameraDistance,
                heading: displayedHeading,
                pitch: 0
            ))
        }
        .onReceive(Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()) { _ in
            guard isHeadingUp, let location = viewModel.userLocation else { return }
            let target = viewModel.currentHeading
            let delta = ((target - displayedHeading + 540).truncatingRemainder(dividingBy: 360)) - 180
            guard abs(delta) >= 0.1 else { return }
            displayedHeading += delta * 0.5
            displayedHeading = ((displayedHeading.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
            cameraPosition = .camera(MapCamera(
                centerCoordinate: location.coordinate,
                distance: currentCameraDistance,
                heading: displayedHeading,
                pitch: 0
            ))
        }
        .onChange(of: cameraPosition) { _, newPosition in
            guard isHeadingUp, newPosition.positionedByUser else { return }
            isHeadingUp = false
        }
    }

    private func zoomToCluster(_ cluster: Cluster) {
        isHeadingUp = false
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

private struct HeadingCone: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        // 45° sector pointing screen-up. In SwiftUI's Y-down coords clockwise: false
        // sweeps visually clockwise (upper-left → top → upper-right = the short 45° arc).
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(-112.5),
                    endAngle: .degrees(-67.5),
                    clockwise: false)
        path.closeSubpath()
        return path
    }
}

#Preview {
    ContentView()
        .environment(PlaceViewModel())
}
