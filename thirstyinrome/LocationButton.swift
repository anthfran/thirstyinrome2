import SwiftUI
import CoreLocation

private enum LocationButtonState {
    case ready, noFix, unauthorized
}

struct LocationButton: View {
    @Environment(PlaceViewModel.self) private var viewModel
    @State private var showGPSWaitToast = false
    @State private var showSettingsAlert = false
    @State private var toastDismissTask: Task<Void, Never>?

    let onCenterOnUser: (CLLocation) -> Void

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
        VStack(spacing: 8) {
            if showGPSWaitToast {
                Text("Waiting for GPS signal\u{2026}")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .transition(.opacity)
            }
            Button {
                handleLocationButtonTap()
            } label: {
                Label("My Location", systemImage: locationButtonIcon)
            }
            .buttonStyle(.borderedProminent)
            .tint(locationButtonColor)
            .clipShape(.capsule)
            .shadow(radius: 4)
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
    }

    private func handleLocationButtonTap() {
        switch locationButtonState {
        case .ready:
            guard let location = viewModel.userLocation else { return }
            onCenterOnUser(location)
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
}
