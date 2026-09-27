import SwiftUI

// MARK: - Modern Studio Palette & Tokens

enum ScarlettUI {
    // Signature Accents
    static let scarlettRed = Color(red: 0.88, green: 0.10, blue: 0.18)
    static let accent = Color(red: 1.0, green: 0.45, blue: 0.12)
    static let cyan = Color(red: 0.0, green: 0.78, blue: 1.0)
    static let amber = Color(red: 1.0, green: 0.72, blue: 0.0)
    static let emerald = Color(red: 0.0, green: 0.90, blue: 0.45)

    // Dark Studio Chassis & Surfaces
    static let chassisBackground = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.13, blue: 0.15),
            Color(red: 0.09, green: 0.09, blue: 0.11),
            Color(red: 0.06, green: 0.06, blue: 0.08)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let background = chassisBackground

    static let stripFill = Color(red: 0.15, green: 0.16, blue: 0.19)
    static let stripBorder = Color.white.opacity(0.08)
    static let panelFill = Color(red: 0.11, green: 0.12, blue: 0.14)
    static let panelBackground = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let cardBackground = Color(red: 0.13, green: 0.14, blue: 0.17)

    // Text & Labels
    static let textPrimary = Color(red: 0.95, green: 0.96, blue: 0.98)
    static let textSecondary = Color(red: 0.65, green: 0.68, blue: 0.75)
    static let textMuted = Color(red: 0.42, green: 0.45, blue: 0.52)
    static let labelOnStrip = Color(red: 0.92, green: 0.94, blue: 0.96)
    static let secondaryText = Color(red: 0.65, green: 0.68, blue: 0.75)

    // Audio Controls Tracks & Insets
    static let slotTrack = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let meterTrack = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let faderTrack = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let faderFill = Color.white.opacity(0.04)
    static let faderKnob = Color(red: 0.85, green: 0.87, blue: 0.90)
    static let knobShadow = Color.black.opacity(0.45)
    static let off = Color(red: 0.40, green: 0.43, blue: 0.50)
    static let border = Color.white.opacity(0.09)

    // MARK: - Typography

    static func title(_ size: CGFloat = 12, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func mono(_ size: CGFloat = 11, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // MARK: - Calibrated Meter Gradient

    static let meterGradient = LinearGradient(
        stops: [
            .init(color: Color(red: 0.0, green: 0.85, blue: 0.42), location: 0.0),
            .init(color: Color(red: 0.0, green: 0.90, blue: 0.48), location: 0.70),
            .init(color: Color(red: 1.0, green: 0.80, blue: 0.10), location: 0.74),
            .init(color: Color(red: 1.0, green: 0.65, blue: 0.05), location: 0.88),
            .init(color: Color(red: 1.0, green: 0.18, blue: 0.25), location: 0.92),
            .init(color: Color(red: 1.0, green: 0.10, blue: 0.15), location: 1.0)
        ],
        startPoint: .bottom,
        endPoint: .top
    )

    static func meterColor(_ level: CGFloat, _ base: Color = .green) -> Color {
        level > 0.92 ? Color(red: 1.0, green: 0.18, blue: 0.25) :
        level > 0.72 ? Color(red: 1.0, green: 0.80, blue: 0.10) :
        Color(red: 0.0, green: 0.85, blue: 0.42)
    }
}

// MARK: - Native Chip Style

extension View {
    func chipStyle() -> some View {
        padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(red: 0.18, green: 0.19, blue: 0.23))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
            )
            .foregroundStyle(ScarlettUI.textPrimary)
    }

    func cardStyle(radius: CGFloat = 8, active: Bool = false, activeColor: Color = .yellow) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: radius)
                .fill(ScarlettUI.stripFill)
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(active ? activeColor.opacity(0.85) : ScarlettUI.stripBorder, lineWidth: active ? 1.5 : 0.8)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Section Title

struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(ScarlettUI.title(10, .bold))
            .foregroundStyle(ScarlettUI.textSecondary)
            .tracking(1.0)
    }
}

// MARK: - LED Push Button

struct ToggleButton: View {
    let label: String
    var isOn: Bool = false
    var onColor: Color = .orange
    var offColor: Color = ScarlettUI.textMuted
    var font: Font = .system(size: 9, weight: .bold)
    var controlSize: ControlSize = .small
    var minWidth: CGFloat? = nil
    var height: CGFloat = 20
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(font)
                .foregroundStyle(isOn ? onColor : ScarlettUI.textSecondary)
                .frame(maxWidth: minWidth.map { _ in .infinity })
                .frame(height: height)
                .padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOn ? onColor.opacity(0.18) : Color(red: 0.12, green: 0.13, blue: 0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isOn ? onColor.opacity(0.8) : Color.white.opacity(0.07), lineWidth: isOn ? 1.2 : 0.6)
                        )
                )
                .shadow(color: isOn ? onColor.opacity(0.35) : Color.clear, radius: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Calibrated Studio Meter Bar

struct MeterBar: View {
    var level: CGFloat
    var color: Color = .green
    var hold: CGFloat? = nil
    var onResetHold: (() -> Void)? = nil
    var width: CGFloat = 6
    var height: CGFloat = 160

    var body: some View {
        ZStack(alignment: .bottom) {
            // Track Inset
            RoundedRectangle(cornerRadius: 1.5)
                .fill(ScarlettUI.meterTrack)
                .overlay(
                    RoundedRectangle(cornerRadius: 1.5)
                        .stroke(Color.black.opacity(0.6), lineWidth: 0.5)
                )

            // Dynamic Level with Graded Color
            RoundedRectangle(cornerRadius: 1.5)
                .fill(ScarlettUI.meterGradient)
                .frame(height: max(1, height * min(level, 1)))
                .animation(.linear(duration: 0.05), value: level)

            // Subtle LED Segment Mask (Horizontal Tick Bars)
            VStack(spacing: 3) {
                ForEach(0..<Int(height / 4), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.25))
                        .frame(height: 1)
                }
            }
            .allowsHitTesting(false)

            // Peak Hold Marker (Crisp Glowing White Line)
            if let hold {
                let clamped = min(1, max(0, hold))
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width + 2, height: 1.5)
                    .shadow(color: Color.white.opacity(0.7), radius: 1)
                    .frame(width: width, height: height)
                    .offset(y: height / 2 - 0.75 - clamped * height)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onResetHold?() }
        .help("Double-click: reset peak hold")
    }
}

// MARK: - Realistic Studio Fader

struct Fader: View {
    var position: CGFloat
    var onChange: (CGFloat) -> Void
    var onDoubleTap: (() -> Void)? = nil

    private static let capW: CGFloat = 28
    private static let capH: CGFloat = 34

    var body: some View {
        GeometryReader { geo in
            let trackHeight = geo.size.height
            let faderTravel = max(1, trackHeight - Self.capH)

            ZStack(alignment: .bottom) {
                // Vertical Center Slot Track
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(ScarlettUI.slotTrack)
                    .frame(width: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 1.5)
                            .stroke(Color.black.opacity(0.8), lineWidth: 0.5)
                    )
                    .frame(maxWidth: .infinity)

                // Filled Travel Accent
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 2, height: position * faderTravel)
                    .frame(maxWidth: .infinity)

                // Realistic Console Fader Cap
                faderCap
                    .offset(y: -(position * faderTravel))
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in
                    let clampedY = max(Self.capH / 2, min(trackHeight - Self.capH / 2, v.location.y))
                    let rawPos = 1 - ((clampedY - Self.capH / 2) / faderTravel)
                    onChange(min(1, max(0, rawPos)))
                }
            )
            .onTapGesture(count: 2) { onDoubleTap?() }
        }
    }

    private var faderCap: some View {
        ZStack {
            // Cap Chassis with Metallic Bevel
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.38, green: 0.40, blue: 0.44),
                            Color(red: 0.22, green: 0.23, blue: 0.26),
                            Color(red: 0.16, green: 0.17, blue: 0.19),
                            Color(red: 0.26, green: 0.27, blue: 0.30)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.black.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                )
                .shadow(color: Color.black.opacity(0.6), radius: 3, x: 0, y: 2)

            // Grip Ribs (Above and Below Center)
            VStack(spacing: 2) {
                Rectangle().fill(Color.black.opacity(0.35)).frame(width: 16, height: 1)
                Rectangle().fill(Color.black.opacity(0.35)).frame(width: 16, height: 1)
                Spacer().frame(height: 6)
                Rectangle().fill(Color.black.opacity(0.35)).frame(width: 16, height: 1)
                Rectangle().fill(Color.black.opacity(0.35)).frame(width: 16, height: 1)
            }

            // Center Notch (White Inset Line)
            Rectangle()
                .fill(Color.white)
                .frame(width: Self.capW - 6, height: 2)
                .shadow(color: Color.white.opacity(0.6), radius: 1)
        }
        .frame(width: Self.capW, height: Self.capH)
    }
}

// MARK: - Rotary Knob with Radial Arc Indicator

struct RotaryKnob: View {
    var value: Float // 0.0 to 1.0 (0.5 = center)
    var onColor: Color = .cyan
    var size: CGFloat = 30
    var onChange: (Float) -> Void
    var onReset: (() -> Void)? = nil

    private var normalizedAngle: Double {
        Double((value - 0.5) * 2 * 135) // -135 to +135 degrees
    }

    var body: some View {
        ZStack {
            // Base circular track
            Circle()
                .stroke(Color(red: 0.10, green: 0.11, blue: 0.13), lineWidth: 2.5)
                .frame(width: size, height: size)

            // Reactive colored arc showing balance / pan direction
            if abs(value - 0.5) > 0.01 {
                Circle()
                    .trim(
                        from: value < 0.5 ? CGFloat(0.5 - Double(0.5 - value) * (270.0 / 360.0)) : 0.5,
                        to: value > 0.5 ? CGFloat(0.5 + Double(value - 0.5) * (270.0 / 360.0)) : 0.5
                    )
                    .stroke(
                        value < 0.5 ? Color.cyan : Color.orange,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .frame(width: size, height: size)
            }

            // Center metallic dial cap
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.28, green: 0.29, blue: 0.33),
                            Color(red: 0.16, green: 0.17, blue: 0.20)
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: size / 2 - 3
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                )
                .frame(width: size - 8, height: size - 8)
                .shadow(color: Color.black.opacity(0.5), radius: 2)

            // Pointer needle notch
            Rectangle()
                .fill(Color.white)
                .frame(width: 1.5, height: 6)
                .offset(y: -(size / 2 - 7))
                .rotationEffect(.degrees(normalizedAngle))
        }
        .frame(width: size + 4, height: size + 4)
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { v in
                let dx = v.location.x - (size + 4) / 2
                let dy = v.location.y - (size + 4) / 2
                let rad = atan2(dx, -dy)
                let deg = rad * 180 / .pi
                let clampedDeg = max(-135, min(135, deg))
                let newVal = Float((clampedDeg + 135) / 270)
                onChange(newVal)
            }
        )
        .onTapGesture(count: 2) {
            onReset?()
        }
    }
}
