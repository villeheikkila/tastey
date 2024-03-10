import SwiftUI

@MainActor
@Observable
public final class FeedbackEnvironmentModel {
    public var show = false
    public var toast = Toast(type: .complete(.black))
    public var sensoryFeedback: SensoryFeedbackEvent?

    public init() {}

    public func toggle(_ type: ToastType, disableHaptics: Bool = false) {
        switch type {
        case let .success(title):
            toast = Toast(type: .complete(.green), title: title)
            show = true
            if !disableHaptics {
                trigger(.notification(.success))
            }
        case let .warning(title):
            toast = Toast(type: .error(.red), title: title)
            show = true
        }
    }

    public func trigger(_ type: HapticType) {
        switch type {
        case let .impact(intensity):
            if let intensity {
                sensoryFeedback = intensity == .low ? SensoryFeedbackEvent(.impact(intensity: 0.3)) :
                    SensoryFeedbackEvent(.impact(intensity: 0.7))
            } else {
                sensoryFeedback = SensoryFeedbackEvent(.impact)
            }
        case let .notification(type):
            switch type {
            case .error:
                sensoryFeedback = SensoryFeedbackEvent(.error)
            case .success:
                sensoryFeedback = SensoryFeedbackEvent(.success)
            case .warning:
                sensoryFeedback = SensoryFeedbackEvent(.warning)
            }
        case .selection:
            sensoryFeedback = SensoryFeedbackEvent(.selection)
        }
    }
}

public struct SensoryFeedbackEvent: Identifiable, Equatable {
    public let id: UUID
    public let sensoryFeedback: SensoryFeedback

    init(_ sensoryFeedback: SensoryFeedback) {
        id = UUID()
        self.sensoryFeedback = sensoryFeedback
    }
}

public extension FeedbackEnvironmentModel {
    enum ErrorType {
        case unexpected, custom(String)
    }

    enum ToastType {
        case success(_ title: LocalizedStringKey)
        case warning(_ title: LocalizedStringKey)
    }

    enum FeedbackType: Int, Sendable {
        case success = 0
        case warning = 1
        case error = 2
    }

    enum HapticType {
        public enum Intensity {
            case low, high
        }

        case impact(intensity: Intensity?)
        case notification(_ type: FeedbackType)
        case selection
    }
}

// Vendored from https://github.com/elai950/AlertToast with modifications
@MainActor
public extension View {
    func toast(
        isPresenting: Binding<Bool>,
        duration: Double = 2,
        tapToDismiss: Bool = true,
        offsetY: CGFloat = 0,
        alert: @escaping () -> Toast,
        onTap: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) -> some View {
        modifier(ToastModifier(
            isPresenting: isPresenting,
            duration: duration,
            tapToDismiss: tapToDismiss,
            offsetY: offsetY,
            alert: alert,
            onTap: onTap,
            completion: completion
        ))
    }
}

@MainActor
public struct Toast: View {
    let displayMode: DisplayMode
    let type: AlertType
    let title: LocalizedStringKey?
    let subTitle: LocalizedStringKey?
    let onTap: (() -> Void)?

    public init(displayMode: DisplayMode = .alert,
                type: AlertType,
                title: LocalizedStringKey? = nil,
                subTitle: LocalizedStringKey? = nil,
                onTap: (() -> Void)? = nil)
    {
        self.displayMode = displayMode
        self.type = type
        self.title = title
        self.subTitle = subTitle
        self.onTap = onTap
    }
    
    public var body: some View {
        switch displayMode {
        case .alert:
            alert
        case .hud:
            hud
        case .banner:
            banner
        }
    }

    public var banner: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    switch type {
                    case let .complete(color):
                        Image(systemName: "checkmark")
                            .foregroundColor(color)
                            .accessibilityHidden(true)
                    case let .error(color):
                        Image(systemName: "xmark")
                            .foregroundColor(color)
                            .accessibilityHidden(true)
                    case let .systemImage(name, color):
                        Image(systemName: name)
                            .foregroundColor(color)
                            .accessibilityHidden(true)
                    case let .image(name, color):
                        Image(name)
                            .foregroundColor(color)
                            .accessibilityHidden(true)
                    }

                    if let title {
                        Text(title)
                            .font(.headline.bold())
                    }
                }

                if let subTitle {
                    Text(subTitle)
                        .font(.subheadline)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .multilineTextAlignment(.leading)
            .padding()
            .frame(maxWidth: 400, alignment: .leading)
            .background(.thinMaterial)
            .cornerRadius(10)
            .padding([.horizontal, .bottom])
        }
    }

    public var hud: some View {
        Group {
            HStack(spacing: 16) {
                switch type {
                case let .complete(color):
                    Image(systemName: "checkmark")
                        .hudModifier()
                        .foregroundColor(color)
                        .accessibilityHidden(true)
                case let .error(color):
                    Image(systemName: "xmark")
                        .hudModifier()
                        .foregroundColor(color)
                        .accessibilityHidden(true)
                case let .systemImage(name, color):
                    Image(systemName: name)
                        .foregroundColor(color)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .frame(width: 31, height: 31, alignment: .center)
                        .background(color.opacity(0.23), in: Circle())
                        .accessibilityHidden(true)
                        .onTapGesture {
                            onTap?()
                        }
                case let .image(name, color):
                    Image(name)
                        .hudModifier()
                        .foregroundColor(color)
                        .accessibilityHidden(true)
                }

                if title != nil || subTitle != nil {
                    VStack(alignment: .center, spacing: 1) {
                        if let title {
                            Text(title)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .multilineTextAlignment(.center)
                        }
                        if let subTitle {
                            Text(subTitle)
                                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                .opacity(0.7)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.trailing, 15)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(7)
            .frame(height: 45)
            .background(.thinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.gray.opacity(0.06), lineWidth: 1))
            .shadow(color: .black.opacity(0.1), radius: 5)
            .compositingGroup()
        }
        .padding(.top)
    }

    public var alert: some View {
        VStack {
            switch type {
            case let .complete(color):
                Spacer()
                AnimatedCheckmark(color: color)
                Spacer()
            case let .error(color):
                Spacer()
                AnimatedXmark(color: color)
                Spacer()
            case let .systemImage(name, color):
                Spacer()
                Image(systemName: name)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .accessibilityHidden(true)
                    .foregroundColor(color)
                    .padding(.bottom)
                Spacer()
            case let .image(name, color):
                Spacer()
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .accessibilityHidden(true)
                    .foregroundColor(color)
                    .padding(.bottom)
                Spacer()
            }

            VStack(spacing: 2) {
                if let title {
                    Text(title)
                        .font(.body.bold())
                        .multilineTextAlignment(.center)
                }
                if let subTitle {
                    Text(subTitle)
                        .font( .footnote)
                        .opacity(0.7)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding()
        .frame(maxWidth: 175, maxHeight: 175, alignment: .center)
        .background(.thinMaterial)
        .cornerRadius(10)
    }
}

public extension Toast {
    enum BannerAnimation {
        case slide, pop
    }

    enum DisplayMode: Equatable {
        case alert
        case hud
        case banner(_ transition: BannerAnimation)
    }

    enum AlertType: Equatable {
        case complete(_ color: Color)
        case error(_ color: Color)
        case systemImage(_ name: String, _ color: Color)
        case image(_ name: String, _ color: Color)
    }
}

@MainActor
public struct ToastModifier: ViewModifier {
    @Binding private var isPresenting: Bool
    @State private var duration: Double
    @State private var tapToDismiss = true
    @State private var workItem: DispatchWorkItem?
    @State private var hostRect: CGRect = .zero
    @State private var alertRect: CGRect = .zero

    let offsetY: CGFloat
    let alert: () -> Toast
    let onTap: (() -> Void)?
    let completion: (() -> Void)?

    public init(
        isPresenting: Binding<Bool>,
        duration: Double = 2,
        tapToDismiss: Bool = true,
        offsetY: CGFloat = 0,
        alert: @escaping () -> Toast,
        onTap: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        _isPresenting = isPresenting
        _duration = State(initialValue: duration)
        _tapToDismiss = State(initialValue: tapToDismiss)
        self.offsetY = offsetY
        self.alert = alert
        self.onTap = onTap
        self.completion = completion
    }

    private var screen: CGRect {
        UIScreen.main.bounds
    }

    private var offset: CGFloat {
        -hostRect.midY + alertRect.height
    }

    @ViewBuilder
    public func main() -> some View {
        if isPresenting {
            switch alert().displayMode {
            case .alert:
                alert()
                    .onTapGesture {
                        onTap?()
                        if tapToDismiss {
                            withAnimation(.spring) {
                                workItem?.cancel()
                                isPresenting = false
                                workItem = nil
                            }
                        }
                    }
                    .onDisappear(perform: {
                        completion?()
                    })
                    .transition(AnyTransition.scale(scale: 0.8).combined(with: .opacity))
            case .hud:
                alert()
                    .overlay(
                        GeometryReader { geo -> AnyView in
                            let rect = geo.frame(in: .global)

                            if rect.integral != alertRect.integral {
                                DispatchQueue.main.async {
                                    alertRect = rect
                                }
                            }
                            return AnyView(EmptyView())
                        }
                    )
                    .onTapGesture {
                        onTap?()
                        if tapToDismiss {
                            withAnimation(.spring) {
                                workItem?.cancel()
                                isPresenting = false
                                workItem = nil
                            }
                        }
                    }
                    .onDisappear(perform: {
                        completion?()
                    })
                    .transition(.move(edge: .top).combined(with: .opacity))
            case .banner:
                alert()
                    .onTapGesture {
                        onTap?()
                        if tapToDismiss {
                            withAnimation(.spring) {
                                workItem?.cancel()
                                isPresenting = false
                                workItem = nil
                            }
                        }
                    }
                    .onDisappear(perform: {
                        completion?()
                    })
                    .transition(alert().displayMode == .banner(.slide) ? .slide
                        .combined(with: .opacity) : .move(edge: .bottom))
            }
        }
    }

    @ViewBuilder
    public func body(content: Content) -> some View {
        switch alert().displayMode {
        case .banner:
            content
                .overlay(ZStack {
                    main()
                        .offset(y: offsetY)
                }
                .animation(.spring, value: isPresenting))
                .onChange(of: isPresenting) { _, presented in
                    if presented { onAppearAction() }
                }
        case .hud:
            content
                .overlay(
                    GeometryReader { geo -> AnyView in
                        let rect = geo.frame(in: .global)

                        if rect.integral != hostRect.integral {
                            DispatchQueue.main.async {
                                hostRect = rect
                            }
                        }

                        return AnyView(EmptyView())
                    }
                    .overlay(ZStack {
                        main()
                            .offset(y: offsetY)
                    }
                    .frame(maxWidth: screen.width, maxHeight: screen.height)
                    .offset(y: offset)
                    .animation(.spring, value: isPresenting))
                )
                .onChange(of: isPresenting) { _, presented in
                    if presented {
                        onAppearAction()
                    }
                }
        case .alert:
            content
                .overlay(ZStack {
                    main()
                        .offset(y: offsetY)
                }
                .frame(maxWidth: screen.width, maxHeight: screen.height, alignment: .center)
                .edgesIgnoringSafeArea(.all)
                .animation(.spring, value: isPresenting))
                .onChange(of: isPresenting) { _, presented in
                    if presented {
                        onAppearAction()
                    }
                }
        }
    }

    private func onAppearAction() {
        if duration > 0 {
            workItem?.cancel()

            let task = DispatchWorkItem {
                withAnimation(.spring) {
                    isPresenting = false
                    workItem = nil
                }
            }
            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
        }
    }
}

private extension Image {
    func hudModifier() -> some View {
        renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 23, maxHeight: 23, alignment: .center)
    }
}

@MainActor
private struct AnimatedCheckmark: View {
    @State private var percentage: CGFloat = .zero
    let color: Color
    let size: Int

    init(color: Color = .black, size: Int = 50) {
        self.color = color
        self.size = size
    }

    private var height: CGFloat {
        CGFloat(size)
    }

    private var width: CGFloat {
        CGFloat(size)
    }

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: height / 2))
            path.addLine(to: CGPoint(x: width / 2.5, y: height))
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        .trim(from: 0, to: percentage)
        .stroke(color, style: .init(lineWidth: CGFloat(size / 8), lineCap: .round, lineJoin: .round))
        .animation(.spring.speed(0.75).delay(0.25), value: percentage)
        .onAppear {
            percentage = 1.0
        }
        .frame(width: width, height: height, alignment: .center)
    }
}

@MainActor
private struct AnimatedXmark: View {
    @State private var percentage: CGFloat = .zero
    let color: Color
    let size: Int

    init(color: Color = .black, size: Int = 50) {
        self.color = color
        self.size = size
    }

    private var height: CGFloat {
        CGFloat(size)
    }

    private var width: CGFloat {
        CGFloat(size)
    }

    private var rect: CGRect {
        CGRect(x: 0, y: 0, width: size, height: size)
    }

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxY, y: rect.maxY))
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        .trim(from: 0, to: percentage)
        .stroke(color, style: StrokeStyle(lineWidth: CGFloat(size / 8), lineCap: .round, lineJoin: .round))
        .animation(.spring.speed(0.75).delay(0.25), value: percentage)
        .onAppear {
            percentage = 1.0
        }
        .frame(width: width, height: height, alignment: .center)
    }
}
