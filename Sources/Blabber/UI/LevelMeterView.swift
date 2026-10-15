import SwiftUI

/// A live mic-level display: a row of capsule bars, newest level on the
/// right, scrolling left as samples arrive — the Voice Memos idea, kept
/// simple.
///
/// It is intentionally *not* animated with a layout tween. The bars
/// redraw directly from `levels` each audio tick (~45×/sec), so the
/// motion is the real signal, not an interpolation — which also keeps it
/// within the "only transform and opacity" rule (there's no height
/// animation to speak of). When inactive it shows a flat idle baseline.
struct LevelMeterView: View {
    let levels: [Float]
    let isActive: Bool

    private let barCount = 48
    private let barSpacing: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let available = geo.size.width - barSpacing * CGFloat(barCount - 1)
            let barWidth = max(1, available / CGFloat(barCount))

            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(
                            width: barWidth,
                            height: max(2, CGFloat(sample(at: index)) * geo.size.height)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 40)
        .accessibilityElement()
        .accessibilityLabel("Microphone level")
        .accessibilityHidden(!isActive)
    }

    /// Right-aligns the newest sample; pads the left with silence when
    /// fewer than `barCount` samples have arrived.
    private func sample(at index: Int) -> Float {
        let offset = barCount - levels.count
        let j = index - offset
        guard j >= 0, j < levels.count else { return 0 }
        return levels[j]
    }
}
