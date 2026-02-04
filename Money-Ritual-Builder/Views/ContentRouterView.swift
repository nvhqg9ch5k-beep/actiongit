import SwiftUI

struct ContentRouterView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    
    @State private var showSplash = true
    @State private var showError = false
    
    @State private var resolvedAddress: String?
    @State private var resolverOutcome: ResolverOutcome = .loading
    @State private var flowPhase: ScreenFlowPhase = .launch

    var body: some View {
        Group {
            ZStack {
                switch flowPhase {
                case .launch:
                    SplashScreenView()
                    
                case .mainApp:
                    if !hasCompletedOnboarding {
                        OnboardingView(isComplete: $hasCompletedOnboarding)
                            .transition(.opacity)
                    } else {
                        MainTabView()
                            .transition(.opacity)
                    }

                case .remotePage(let urlString):
                    if URL(string: urlString) != nil {
                        EmbeddedPageCanvas(pageAddress: urlString)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .ignoresSafeArea(.all, edges: .bottom)
                    } else {
                        Text("Invalid URL")
                    }

                case .errorScreen(let message):
                    VStack(spacing: 20) {
                        Text("Error")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(message)
                        Button("Retry") {
                            Task { await loadEndpointAndTransition() }
                        }
                    }
                    .padding()
                }
            }
            .task {
                await loadEndpointAndTransition()
            }
            .onChange(of: resolverOutcome, initial: true) { _, newValue in
                if case .success = newValue, let url = resolvedAddress, !url.isEmpty {
                    Task {
                        await validateAndShowPage(address: url)
                    }
                }
            }
            
//            if showSplash {
//                SplashScreenView(isComplete: Binding(
//                    get: { false },
//                    set: { newValue in
//                        if newValue {
//                            showSplash = false
//                        }
//                    }
//                ))
//                .transition(.opacity)
//            } else if !hasCompletedOnboarding {
//                OnboardingView(isComplete: $hasCompletedOnboarding)
//                    .transition(.opacity)
//            } else {
//                MainTabView()
//                    .transition(.opacity)
//            }
        }
        .id("\(showSplash)-\(hasCompletedOnboarding)")
    }
    
    private func loadEndpointAndTransition() async {
        await MainActor.run { flowPhase = .launch }

        let (url, state) = await RemoteEndpointResolver.shared.resolveDestination()
        print("URL: \(url)")
        print("State: \(state)")

        await MainActor.run {
            resolvedAddress = url
            resolverOutcome = state
        }

        if url == nil || url?.isEmpty == true {
            switchToMainApp()
        }
    }

    private func switchToMainApp() {
        withAnimation {
            flowPhase = .mainApp
        }
    }

    private func validateAndShowPage(address: String) async {
        guard let url = URL(string: address) else {
            switchToMainApp()
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        req.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: req)

            if let http = response as? HTTPURLResponse,
               (200...299).contains(http.statusCode) {
                await MainActor.run {
                    flowPhase = .remotePage(address)
                }
            } else {
                switchToMainApp()
            }
        } catch {
            switchToMainApp()
        }
    }
}
