import SwiftUI

@Observable
public final class FeedbackEnvironmentModel {
    public var show = false
    public var toast = Toast(type: .regular, title: "")
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
        case success(_ title: String)
        case warning(_ title: String)
    }

    enum FeedbackType: Int, @unchecked Sendable {
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

public struct Toast: View {
    let displayMode: DisplayMode
    let type: AlertType
    let title: String?
    let subTitle: String?
    let style: AlertStyle?
    let onTap: (() -> Void)?

    public init(displayMode: DisplayMode = .alert,
                type: AlertType,
                title: String? = nil,
                subTitle: String? = nil,
                style: AlertStyle? = nil,
                onTap: (() -> Void)? = nil)
    {
        self.displayMode = displayMode
        self.type = type
        self.title = title
        self.subTitle = subTitle
        self.style = style
        self.onTap = onTap
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
                    case let .error(color):
                        Image(systemName: "xmark")
                            .foregroundColor(color)
                    case let .systemImage(name, color):
                        Image(systemName: name)
                            .foregroundColor(color)
                    case let .image(name, color):
                        Image(name)
                            .foregroundColor(color)
                    case .loading:
                        ActivityIndicator()
                    case .regular:
                        EmptyView()
                    }

                    Text(LocalizedStringKey(title ?? ""))
                        .font(style?.titleFont ?? Font.headline.bold())
                }

                if subTitle != nil {
                    Text(LocalizedStringKey(subTitle!))
                        .font(style?.subTitleFont ?? Font.subheadline)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .multilineTextAlignment(.leading)
            .textColor(style?.titleColor ?? nil)
            .padding()
            .frame(maxWidth: 400, alignment: .leading)
            .alertBackground(style?.backgroundColor ?? nil)
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
                case let .error(color):
                    Image(systemName: "xmark")
                        .hudModifier()
                        .foregroundColor(color)
                case let .systemImage(name, color):
                    Image(systemName: name)
                        .foregroundColor(color)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .frame(width: 31, height: 31, alignment: .center)
                        .background(color.opacity(0.23), in: Circle())
                        .onTapGesture {
                            onTap?()
                        }
                case let .image(name, color):
                    Image(name)
                        .hudModifier()
                        .foregroundColor(color)
                case .loading:
                    ActivityIndicator()
                case .regular:
                    EmptyView()
                }

                if title != nil || subTitle != nil {
                    VStack(alignment: .center, spacing: 1) {
                        if title != nil {
                            Text(LocalizedStringKey(title ?? ""))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .multilineTextAlignment(.center)
                                .textColor(style?.titleColor ?? nil)
                        }
                        if subTitle != nil {
                            Text(LocalizedStringKey(subTitle ?? ""))
                                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                .opacity(0.7)
                                .multilineTextAlignment(.center)
                                .textColor(style?.subtitleColor ?? nil)
                        }
                    }
                    .padding(.trailing, 15)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .padding(7)
            .frame(height: 45)
            .alertBackground(style?.backgroundColor ?? nil)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.gray.opacity(0.06), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.1), radius: 5)
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
                    .foregroundColor(color)
                    .padding(.bottom)
                Spacer()
            case let .image(name, color):
                Spacer()
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .foregroundColor(color)
                    .padding(.bottom)
                Spacer()
            case .loading:
                ActivityIndicator()
            case .regular:
                EmptyView()
            }

            VStack(spacing: type == .regular ? 8 : 2) {
                if title != nil {
                    Text(LocalizedStringKey(title ?? ""))
                        .font(style?.titleFont ?? Font.body.bold())
                        .multilineTextAlignment(.center)
                        .textColor(style?.titleColor ?? nil)
                }
                if subTitle != nil {
                    Text(LocalizedStringKey(subTitle ?? ""))
                        .font(style?.subTitleFont ?? Font.footnote)
                        .opacity(0.7)
                        .multilineTextAlignment(.center)
                        .textColor(style?.subtitleColor ?? nil)
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding()
        .withFrame(type != .regular && type != .loading)
        .alertBackground(style?.backgroundColor ?? nil)
        .cornerRadius(10)
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
        case loading
        case regular
    }

    enum AlertStyle: Equatable {
        case style(backgroundColor: Color? = nil,
                   titleColor: Color? = nil,
                   subTitleColor: Color? = nil,
                   titleFont: Font? = nil,
                   subTitleFont: Font? = nil)

        var backgroundColor: Color? {
            switch self {
            case let .style(backgroundColor: color, _, _, _, _):
                return color
            }
        }

        var titleColor: Color? {
            switch self {
            case let .style(_, color, _, _, _):
                return color
            }
        }

        var subtitleColor: Color? {
            switch self {
            case let .style(_, _, color, _, _):
                return color
            }
        }

        var titleFont: Font? {
            switch self {
            case let .style(_, _, _, titleFont: font, _):
                return font
            }
        }

        var subTitleFont: Font? {
            switch self {
            case let .style(_, _, _, _, subTitleFont: font):
                return font
            }
        }
    }
}

public struct ToastModifier: ViewModifier {
    @Binding private var isPresenting: Bool
    @State private var duration: Double
    @State private var tapToDismiss: Bool = true
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
        #if os(iOS)
            return UIScreen.main.bounds
        #else
            return NSScreen.main?.frame ?? .zero
        #endif
    }

    private var offset: CGFloat {
        #if os(iOS)
            return -hostRect.midY + alertRect.height
        #else
            return (-hostRect.midY + screen.midY) + alertRect.height
        #endif
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
                                self.workItem?.cancel()
                                isPresenting = false
                                self.workItem = nil
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
                                    self.alertRect = rect
                                }
                            }
                            return AnyView(EmptyView())
                        }
                    )
                    .onTapGesture {
                        onTap?()
                        if tapToDismiss {
                            withAnimation(.spring) {
                                self.workItem?.cancel()
                                isPresenting = false
                                self.workItem = nil
                            }
                        }
                    }
                    .onDisappear(perform: {
                        completion?()
                    })
                    .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
            case .banner:
                alert()
                    .onTapGesture {
                        onTap?()
                        if tapToDismiss {
                            withAnimation(.spring) {
                                self.workItem?.cancel()
                                isPresenting = false
                                self.workItem = nil
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
                                self.hostRect = rect
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
        if alert().type == .loading {
            duration = 0
            tapToDismiss = false
        }

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

private struct AnimatedCheckmark: View {
    var color: Color = .black
    var size: Int = 50

    var height: CGFloat {
        return CGFloat(size)
    }

    var width: CGFloat {
        return CGFloat(size)
    }

    @State private var percentage: CGFloat = .zero

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: height / 2))
            path.addLine(to: CGPoint(x: width / 2.5, y: height))
            path.addLine(to: CGPoint(x: width, y: 0))
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

private struct AnimatedXmark: View {
    var color: Color = .black
    var size: Int = 50

    var height: CGFloat {
        return CGFloat(size)
    }

    var width: CGFloat {
        return CGFloat(size)
    }

    var rect: CGRect {
        return CGRect(x: 0, y: 0, width: size, height: size)
    }

    @State private var percentage: CGFloat = .zero

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

#if os(macOS)
    struct ActivityIndicator: NSViewRepresentable {
        func makeNSView(context: NSViewRepresentableContext<ActivityIndicator>) -> NSProgressIndicator {
            let nsView = NSProgressIndicator()

            nsView.isIndeterminate = true
            nsView.style = .spinning
            nsView.startAnimation(context)

            return nsView
        }

        func updateNSView(_: NSProgressIndicator, context _: NSViewRepresentableContext<ActivityIndicator>) {}
    }
#else
    struct ActivityIndicator: UIViewRepresentable {
        func makeUIView(context _: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
            let progressView = UIActivityIndicatorView(style: .large)
            progressView.startAnimating()

            return progressView
        }

        func updateUIView(_: UIActivityIndicatorView, context _: UIViewRepresentableContext<ActivityIndicator>) {}
    }
#endif

#if os(macOS)
    public struct BlurView: NSViewRepresentable {
        public typealias NSViewType = NSVisualEffectView

        public func makeNSView(context _: Context) -> NSVisualEffectView {
            let effectView = NSVisualEffectView()
            effectView.material = .hudWindow
            effectView.blendingMode = .withinWindow
            effectView.state = NSVisualEffectView.State.active
            return effectView
        }

        public func updateNSView(_ nsView: NSVisualEffectView, context _: Context) {
            nsView.material = .hudWindow
            nsView.blendingMode = .withinWindow
        }
    }

#else
    public struct BlurView: UIViewRepresentable {
        public typealias UIViewType = UIVisualEffectView

        public func makeUIView(context _: Context) -> UIVisualEffectView {
            return UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        }

        public func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
            uiView.effect = UIBlurEffect(style: .systemMaterial)
        }
    }

#endif

private struct BackgroundModifier: ViewModifier {
    var color: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        if color != nil {
            content
                .background(color)
        } else {
            content
                .background(BlurView())
        }
    }
}

private struct TextForegroundModifier: ViewModifier {
    var color: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        if color != nil {
            content
                .foregroundColor(color)
        } else {
            content
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

private extension View {
    func alertBackground(_ color: Color? = nil) -> some View {
        modifier(BackgroundModifier(color: color))
    }

    func textColor(_ color: Color? = nil) -> some View {
        modifier(TextForegroundModifier(color: color))
    }

    func withFrame(_ withFrame: Bool) -> some View {
        modifier(WithFrameModifier(withFrame: withFrame))
    }
}

private struct WithFrameModifier: ViewModifier {
    var withFrame: Bool

    var maxWidth: CGFloat = 175
    var maxHeight: CGFloat = 175

    @ViewBuilder
    func body(content: Content) -> some View {
        if withFrame {
            content
                .frame(maxWidth: maxWidth, maxHeight: maxHeight, alignment: .center)
        } else {
            content
        }
    }
}
