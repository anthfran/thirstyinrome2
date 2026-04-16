import SwiftUI
import MapKit

struct ContentView: View {
    @Environment(PlaceViewModel.self) private var viewModel
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.899159, longitude: 12.473065),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var hasJumpedToUserLocation = false

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(viewModel.places) { place in
                Marker(
                    place.title ?? "Fontanella",
                    coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
                )
            }
            UserAnnotation()
        }
        .mapStyle(.standard)
        .ignoresSafeArea()
        .onChange(of: viewModel.userLocation) { _, newLocation in
            guard !hasJumpedToUserLocation, let location = newLocation else { return }
            hasJumpedToUserLocation = true
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
}

#Preview {
    ContentView()
        .environment(PlaceViewModel())
}
