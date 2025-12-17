import SwiftUI

// MARK: - GlassButton
/// Primary CTA button with glassmorphic styling
@MainActor
struct GlassButton: View {
    let title: String
    let icon: String?
    let style: GlassButtonStyle
    let size: GlassButtonSize
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: GlassButtonStyle = .primary,
        size: GlassButtonSize = .medium,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button {
            NightOutHaptics.light()
            action()
        } label: {
            HStack(spacing: NightOutSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(iconFont)
                    }
                    Text(title)
                        .font(textFont)
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, horizontalPadding)
            .foregroundStyle(textColor)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
    }

    // MARK: - Computed Properties

    private var height: CGFloat {
        switch size {
        case .small: return 36
        case .medium: return 44
        case .large: return 52
        case .extraLarge: return 60
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return NightOutSpacing.md
        case .medium: return NightOutSpacing.lg
        case .large: return NightOutSpacing.xl
        case .extraLarge: return NightOutSpacing.xxl
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small: return NightOutRadius.sm
        case .medium: return NightOutRadius.md
        case .large: return NightOutRadius.lg
        case .extraLarge: return NightOutRadius.lg
        }
    }

    private var textFont: Font {
        switch size {
        case .small: return NightOutTypography.footnote
        case .medium: return NightOutTypography.headline
        case .large: return NightOutTypography.headline
        case .extraLarge: return NightOutTypography.title3
        }
    }

    private var iconFont: Font {
        switch size {
        case .small: return .system(size: 12, weight: .semibold)
        case .medium: return .system(size: 15, weight: .semibold)
        case .large: return .system(size: 17, weight: .semibold)
        case .extraLarge: return .system(size: 20, weight: .semibold)
        }
    }

    private var isFullWidth: Bool {
        size == .large || size == .extraLarge
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            NightOutColors.primaryGradient
        case .secondary:
            NightOutColors.glassBackground
                .background(.ultraThinMaterial)
        case .prominent:
            NightOutColors.neonPink
        case .destructive:
            NightOutColors.liveRed
        case .ghost:
            Color.clear
        }
    }

    private var textColor: Color {
        switch style {
        case .primary, .prominent, .destructive:
            return .white
        case .secondary, .ghost:
            return NightOutColors.chrome
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary:
            return NightOutColors.glassBorder
        default:
            return .clear
        }
    }
}

enum GlassButtonStyle {
    case primary
    case secondary
    case prominent
    case destructive
    case ghost
}

enum GlassButtonSize {
    case small
    case medium
    case large
    case extraLarge
}

// MARK: - GlassCard
/// Container with glassmorphic blur effect
@MainActor
struct GlassCard<Content: View>: View {
    let content: Content
    let padding: CGFloat

    init(padding: CGFloat = NightOutSpacing.lg, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(NightOutColors.glassBackground)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: NightOutRadius.card)
                    .stroke(NightOutColors.glassBorder, lineWidth: 1)
            )
    }
}

// MARK: - ProfileStatItem
/// Stats display component for profile views
@MainActor
struct ProfileStatItem: View {
    let value: String
    let label: String
    let icon: String?

    init(value: String, label: String, icon: String? = nil) {
        self.value = value
        self.label = label
        self.icon = icon
    }

    init(value: Int, label: String, icon: String? = nil) {
        self.value = "\(value)"
        self.label = label
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: NightOutSpacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(NightOutColors.silver)
            }
            Text(value)
                .font(NightOutTypography.statNumber)
                .foregroundStyle(NightOutColors.chrome)
            Text(label)
                .font(NightOutTypography.statLabel)
                .foregroundStyle(NightOutColors.silver)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - SettingsRow
/// Standard settings list item with navigation
@MainActor
struct SettingsRow<Destination: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let value: String?
    let iconColor: Color
    let destination: (() -> Destination)?

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color = NightOutColors.silver,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = nil
        self.iconColor = iconColor
        self.destination = destination
    }

    var body: some View {
        Group {
            if let destination {
                NavigationLink {
                    destination()
                } label: {
                    rowContent
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: NightOutSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.chrome)

                if let subtitle {
                    Text(subtitle)
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.silver)
                }
            }

            Spacer()

            if let value {
                Text(value)
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
            } else if destination != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NightOutColors.dimmed)
            }
        }
        .padding(.vertical, NightOutSpacing.md)
        .frame(minHeight: 44)
    }
}

// Simple settings row without navigation (display only with value)
extension SettingsRow where Destination == EmptyView {
    init(title: String, icon: String, value: String? = nil) {
        self.title = title
        self.icon = icon
        self.subtitle = nil
        self.value = value
        self.iconColor = NightOutColors.silver
        self.destination = nil
    }
}

// MARK: - SettingsActionRow
/// Settings row with action callback instead of navigation
@MainActor
struct SettingsActionRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let iconColor: Color
    let isDestructive: Bool
    let action: () -> Void

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color = NightOutColors.silver,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = isDestructive ? NightOutColors.liveRed : iconColor
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        Button {
            NightOutHaptics.light()
            action()
        } label: {
            HStack(spacing: NightOutSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(NightOutTypography.body)
                        .foregroundStyle(isDestructive ? NightOutColors.liveRed : NightOutColors.chrome)

                    if let subtitle {
                        Text(subtitle)
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.silver)
                    }
                }

                Spacer()
            }
            .padding(.vertical, NightOutSpacing.md)
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - SettingsToggleRow
/// Settings row with toggle switch
@MainActor
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let iconColor: Color
    @Binding var isOn: Bool

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color = NightOutColors.silver,
        isOn: Binding<Bool>
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: NightOutSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.chrome)

                if let subtitle {
                    Text(subtitle)
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.silver)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(NightOutColors.neonPink)
        }
        .padding(.vertical, NightOutSpacing.md)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            NightOutHaptics.light()
            isOn.toggle()
        }
    }
}

// MARK: - SectionHeader
/// Section header for grouped content
@MainActor
struct SectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionTitle: String?

    init(_ title: String, action: (() -> Void)? = nil, actionTitle: String? = nil) {
        self.title = title
        self.action = action
        self.actionTitle = actionTitle
    }

    var body: some View {
        HStack {
            Text(title)
                .font(NightOutTypography.footnote)
                .foregroundStyle(NightOutColors.silver)
                .textCase(.uppercase)

            Spacer()

            if let action, let actionTitle {
                Button {
                    NightOutHaptics.light()
                    action()
                } label: {
                    Text(actionTitle)
                        .font(NightOutTypography.footnote)
                        .foregroundStyle(NightOutColors.neonPink)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, NightOutSpacing.screenHorizontal)
        .padding(.top, NightOutSpacing.lg)
        .padding(.bottom, NightOutSpacing.sm)
    }
}

// MARK: - EmptyStateView
/// Placeholder view for empty content states
@MainActor
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: NightOutSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(NightOutColors.dimmed)

            VStack(spacing: NightOutSpacing.sm) {
                Text(title)
                    .font(NightOutTypography.title3)
                    .foregroundStyle(NightOutColors.chrome)

                Text(message)
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                GlassButton(actionTitle, style: .primary, size: .medium, action: action)
                    .padding(.top, NightOutSpacing.sm)
            }
        }
        .padding(NightOutSpacing.xxl)
    }
}

// MARK: - LoadingView
/// Full-screen loading indicator
@MainActor
struct LoadingView: View {
    let message: String?

    init(_ message: String? = nil) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: NightOutSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: NightOutColors.neonPink))
                .scaleEffect(1.5)

            if let message {
                Text(message)
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NightOutColors.background.ignoresSafeArea())
    }
}

// MARK: - AvatarView
/// User avatar with fallback initials
@MainActor
struct AvatarView: View {
    let url: URL?
    let name: String
    let size: CGFloat

    init(url: URL?, name: String, size: CGFloat = 44) {
        self.url = url
        self.name = name
        self.size = size
    }

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(NightOutColors.glassBorder, lineWidth: 1)
        )
    }

    private var initialsView: some View {
        ZStack {
            NightOutColors.surface
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundStyle(NightOutColors.chrome)
        }
    }

    private var initials: String {
        let components = name.split(separator: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }
}

// MARK: - LiveIndicator
/// Pulsing indicator for live status
@MainActor
struct LiveIndicator: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: NightOutSpacing.xs) {
            Circle()
                .fill(NightOutColors.liveRed)
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.7 : 1.0)

            Text("LIVE")
                .font(NightOutTypography.caption)
                .foregroundStyle(NightOutColors.liveRed)
        }
        .padding(.horizontal, NightOutSpacing.sm)
        .padding(.vertical, NightOutSpacing.xs)
        .background(NightOutColors.liveRed.opacity(0.15))
        .clipShape(Capsule())
        .onAppear {
            withAnimation(NightOutAnimation.pulse) {
                isPulsing = true
            }
        }
    }
}
