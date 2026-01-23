import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isComplete: Bool
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            title: "A sacred space to build personal money rituals",
            description: "Create your own private practice for cultivating a mindful relationship with money.",
            icon: "sparkles"
        ),
        OnboardingPage(
            title: "Create daily practices that reshape your relationship with money",
            description: "Build rituals that honor your values and support your financial intentions.",
            icon: "leaf.fill"
        ),
        OnboardingPage(
            title: "Private, offline, judgment-free — your rituals, your way",
            description: "This is a private personal habit and ritual journal. Not financial advice or spiritual guidance.",
            icon: "lock.shield.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            RitualTheme.warmIvory(colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Bottom button
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        Button(action: {
                            isComplete = true
                        }) {
                            Text("Begin")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(RitualTheme.warmIvory(colorScheme: colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(RitualTheme.deepAmber)
                                .cornerRadius(RitualTheme.cornerRadius)
                        }
                        .padding(.horizontal, RitualTheme.padding)
                        .padding(.bottom, 40)
                    } else {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(RitualTheme.warmIvory(colorScheme: colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(RitualTheme.deepAmber)
                                .cornerRadius(RitualTheme.cornerRadius)
                        }
                        .padding(.horizontal, RitualTheme.padding)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
}

struct OnboardingPageView: View {
    @Environment(\.colorScheme) private var colorScheme
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(RitualTheme.deepAmber)
                .padding(.bottom, 20)
            
            Text(page.title)
                .font(RitualTheme.ritualTitleFont)
                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, RitualTheme.padding)
            
            Text(page.description)
                .font(RitualTheme.bodyFont)
                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, RitualTheme.padding)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isComplete: .constant(false))
}
