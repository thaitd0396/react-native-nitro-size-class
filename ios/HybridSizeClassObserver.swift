import NitroModules
import UIKit

final class HybridSizeClassObserver: HybridSizeClassObserverSpec {
    private var observerView: SizeClassObserverView?

    func observe(viewTag: Double, onChange: @escaping (SizeClass) -> Void) throws {
        guard viewTag.isFinite, viewTag > 0, viewTag < Double(Int.max) else {
            throw NSError(domain: "HabitifySizeClass", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Expected a valid native view tag."
            ])
        }
        DispatchQueue.main.async { [self] in
            detachObserver()
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
            guard let hostView = windows.lazy.compactMap({ findView(tag: Int(viewTag), in: $0) }).first else {
                onChange(SizeClass(horizontal: .unknown, vertical: .unknown))
                return
            }
            let view = SizeClassObserverView(onChange: onChange)
            observerView = view
            hostView.addSubview(view)
            view.publishSizeClass()
        }
    }

    func stopObserving() throws {
        DispatchQueue.main.async { [self] in
            detachObserver()
        }
    }

    private func detachObserver() {
        observerView?.onChange = nil
        observerView?.removeFromSuperview()
        observerView = nil
    }

    private func findView(tag: Int, in root: UIView) -> UIView? {
        // Fabric stores its React tag in UIView.tag.
        if root.tag == tag {
            return root
        }
        for child in root.subviews {
            if let match = findView(tag: tag, in: child) {
                return match
            }
        }
        return nil
    }

    deinit {
        let view = observerView
        DispatchQueue.main.async {
            view?.onChange = nil
            view?.removeFromSuperview()
        }
    }
}

private final class SizeClassObserverView: UIView {
    var onChange: ((SizeClass) -> Void)?
    private var lastHorizontal: UIUserInterfaceSizeClass?
    private var lastVertical: UIUserInterfaceSizeClass?

    init(onChange: @escaping (SizeClass) -> Void) {
        self.onChange = onChange
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) {
                (view: SizeClassObserverView, _: UITraitCollection) in
                view.publishSizeClass()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        publishSizeClass()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 17.0, *) {
            return
        }
        publishSizeClass()
    }

    func publishSizeClass() {
        guard window != nil else { return }
        let horizontal = traitCollection.horizontalSizeClass
        let vertical = traitCollection.verticalSizeClass
        guard horizontal != lastHorizontal || vertical != lastVertical else { return }
        lastHorizontal = horizontal
        lastVertical = vertical
        onChange?(SizeClass(horizontal: sizeClassValue(horizontal), vertical: sizeClassValue(vertical)))
    }

    private func sizeClassValue(_ value: UIUserInterfaceSizeClass) -> SizeClassValue {
        switch value {
        case .compact: return .compact
        case .regular: return .regular
        default: return .unknown
        }
    }
}
