import SwiftUI
import WatchKit

struct CountdownView: View {
    let onComplete: () -> Void

    @State private var count = 3
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Text("\(count)")
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(countColor)
                .scaleEffect(scale)
        }
        .onAppear {
            startCountdown()
        }
    }

    private var countColor: Color {
        switch count {
        case 3: return .red
        case 2: return .yellow
        case 1: return .green
        default: return .white
        }
    }

    private func startCountdown() {
        // Animate each number
        animateNumber()

        // Schedule countdown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            WKInterfaceDevice.current().play(.click)
            count = 2
            animateNumber()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                WKInterfaceDevice.current().play(.click)
                count = 1
                animateNumber()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    WKInterfaceDevice.current().play(.start)
                    onComplete()
                }
            }
        }
    }

    private func animateNumber() {
        scale = 1.5
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.0
        }
    }
}
