import SwiftUI

struct OnboardingPage {
    let imageName: String
    let text: String
}

struct OnboardingView: View {
    let pages: [OnboardingPage]
    let onDismiss: () -> Void

    @State private var currentIndex: Int = 0

    private var isFirst: Bool { currentIndex == 0 }
    private var isLast: Bool { currentIndex == pages.count - 1 }

    var body: some View {
        ZStack {
            Image(pages[currentIndex].imageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .id(pages[currentIndex].imageName)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: currentIndex)

            // 底部漸層讓文字更易讀
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.78)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 340)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 略過按鈕
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Text("略過")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color.black.opacity(0.28)))
                    }
                    .padding(.top, 56)
                    .padding(.trailing, 20)
                }

                Spacer()

                // 說明文字
                Text(pages[currentIndex].text)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 1)
                    .padding(.horizontal, 32)
                    .id(currentIndex)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
                    .padding(.bottom, 22)

                // 頁面指示點
                HStack(spacing: 7) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentIndex ? Color.white : Color.white.opacity(0.38))
                            .frame(
                                width: i == currentIndex ? 9 : 6,
                                height: i == currentIndex ? 9 : 6
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                    }
                }
                .padding(.bottom, 22)

                // 導覽按鈕
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            currentIndex -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white, Color.black.opacity(0.38))
                            .shadow(color: .black.opacity(0.25), radius: 4)
                    }
                    .opacity(isFirst ? 0 : 1)
                    .disabled(isFirst)

                    Spacer()

                    Button {
                        if isLast {
                            onDismiss()
                        } else {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                currentIndex += 1
                            }
                        }
                    } label: {
                        Image(systemName: isLast ? "checkmark.circle.fill" : "chevron.right.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                .white,
                                isLast ? Color.green.opacity(0.65) : Color.black.opacity(0.38)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 4)
                    }
                }
                .padding(.horizontal, 44)
                .padding(.bottom, 52)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    let dx = value.translation.width
                    if dx < -40, !isLast {
                        withAnimation(.easeInOut(duration: 0.35)) { currentIndex += 1 }
                    } else if dx > 40, !isFirst {
                        withAnimation(.easeInOut(duration: 0.35)) { currentIndex -= 1 }
                    }
                }
        )
    }
}
