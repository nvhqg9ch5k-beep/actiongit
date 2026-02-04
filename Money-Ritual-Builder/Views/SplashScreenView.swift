import SwiftUI

struct SplashScreenView: View {
    @Environment(\.colorScheme) private var colorScheme

    
    var body: some View {
        ZStack {
            RitualTheme.deepAmber
                .ignoresSafeArea()
            
            VStack(spacing: 60) {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
    }
}

