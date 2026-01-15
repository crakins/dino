import SwiftUI
import UIKit

struct iPhoneCountdownView: View {
    let onComplete: () -> Void

    @State private var count = 3
    @State private var scale: CGFloat = 1.5

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Text("\(count)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundColor(countColor)
                .scaleEffect(scale)
        }
        .onAppear {
            feedbackGenerator.prepare()
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
        animateNumber()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            count = 2
            animateNumber()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                count = 1
                animateNumber()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onComplete()
                }
            }
        }
    }

    private func animateNumber() {
        feedbackGenerator.impactOccurred()
        scale = 1.5
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.0
        }
    }
}
