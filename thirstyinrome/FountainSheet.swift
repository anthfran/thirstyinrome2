import SwiftUI
import MapKit

struct FountainSheet: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            Text(place.title ?? "Fontanella")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    openAppleMaps()
                } label: {
                    Label("Open in Apple Maps", systemImage: "map")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                Button {
                    openGoogleMaps()
                } label: {
                    Label("Open in Google Maps", systemImage: "map")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }

    private func openAppleMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = place.title ?? "Fontanella"
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
        dismiss()
    }

    private func openGoogleMaps() {
        let daddr = String(format: "%.6f,%.6f", place.lat, place.lon)
        guard let url = URL(string: "comgooglemaps://?daddr=\(daddr)&directionsmode=walking") else { return }
        UIApplication.shared.open(url)
        dismiss()
    }
}
