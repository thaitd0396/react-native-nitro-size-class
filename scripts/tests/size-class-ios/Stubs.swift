protocol HybridSizeClassObserverSpec {}
enum SizeClassValue: Equatable { case unknown, compact, regular }
struct SizeClass { let horizontal: SizeClassValue }
