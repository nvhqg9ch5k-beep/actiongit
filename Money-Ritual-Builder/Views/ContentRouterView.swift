import SwiftUI

struct ContentRouterView: View {
    @Binding var showSplash: Bool
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        Group {
            if showSplash {
                SplashScreenView(isComplete: Binding(
                    get: { false },
                    set: { newValue in
                        if newValue {
                            showSplash = false
                        }
                    }
                ))
                .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView(isComplete: $hasCompletedOnboarding)
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .id("\(showSplash)-\(hasCompletedOnboarding)")
    }
}
