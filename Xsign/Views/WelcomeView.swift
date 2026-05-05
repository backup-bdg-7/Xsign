import SwiftUI

struct WelcomeView: View {
    @State private var isActive = false
    @State private var progress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            XsignTheme.background
                .ignoresSafeArea()
            
            if isActive {
                MainTabView()
                    .transition(.opacity)
            } else {
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Logo/Icon
                    Image(systemName: "signature")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(XsignTheme.primary)
                    
                    // App Name
                    Text("Welcome to XSign")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(XsignTheme.textPrimary)
                    
                    Text("Sign, manage, and customize your iOS apps with ease.")
                        .font(.body)
                        .foregroundColor(XsignTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Lottie Animation
                    LottieView(name: "welcome_animation", loopMode: .loop)
                        .frame(height: 200)
                    
                    Spacer()
                    
                    // Loading Bar
                    VStack(spacing: 10) {
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(XsignTheme.textSecondary)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(height: 4)
                                    .foregroundColor(XsignTheme.surface)
                                
                                Rectangle()
                                    .frame(width: geometry.size.width * progress, height: 4)
                                    .foregroundColor(XsignTheme.primary)
                                    .animation(.easeInOut(duration: 0.3), value: progress)
                            }
                            .cornerRadius(2)
                        }
                        .frame(height: 4)
                        .padding(.horizontal, 60)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            startLoading()
        }
    }
    
    private func startLoading() {
        // Simulate 6-second loading
        let timer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { _ in
            if progress < 1.0 {
                progress += 0.01
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            timer.invalidate()
            withAnimation(.easeInOut(duration: 0.5)) {
                isActive = true
            }
        }
    }
}

#Preview {
    WelcomeView()
}
