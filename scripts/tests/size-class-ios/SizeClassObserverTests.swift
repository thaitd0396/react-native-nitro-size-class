import XCTest
import UIKit
@testable import SizeClassHarness

final class SizeClassObserverTests: XCTestCase {
  @MainActor
  func testObservesLoadedInactiveTabWhenSelected() async throws {
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let tabs = UITabBarController()
    let active = UIViewController()
    let inactive = UIViewController()
    inactive.loadViewIfNeeded()
    inactive.view.tag = 4242
    tabs.setViewControllers([active, inactive], animated: false)
    tabs.selectedViewController = active
    tabs.traitOverrides.horizontalSizeClass = .regular
    window.rootViewController = tabs
    window.makeKeyAndVisible()
    window.layoutIfNeeded()
    XCTAssertNil(inactive.view.window)
    let observer = HybridSizeClassObserver()
    let changed = expectation(description: "Selected tab publishes regular")
    changed.assertForOverFulfill = false
    var values: [SizeClassValue] = []
    try observer.observe(viewTag: 4242) { size in
      values.append(size.horizontal)
      if size.horizontal == .regular { changed.fulfill() }
    }
    await drainMainQueue()
    tabs.selectedViewController = inactive
    window.layoutIfNeeded()
    await fulfillment(of: [changed], timeout: 1)
    XCTAssertEqual(values.last, .regular)
    try observer.stopObserving()
    window.isHidden = true
  }

  @MainActor
  func testTracksTraitsChangedWhileTabIsDetached() async throws {
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let tabs = UITabBarController()
    let first = UIViewController()
    let second = UIViewController()
    second.loadViewIfNeeded()
    second.view.tag = 4243
    tabs.setViewControllers([first, second], animated: false)
    tabs.selectedViewController = second
    tabs.traitOverrides.horizontalSizeClass = .regular
    window.rootViewController = tabs
    window.makeKeyAndVisible()
    window.layoutIfNeeded()

    let observer = HybridSizeClassObserver()
    defer {
      try? observer.stopObserving()
      window.isHidden = true
    }
    let regular = expectation(description: "Initial regular snapshot")
    let compact = expectation(description: "Returned tab publishes compact")
    regular.assertForOverFulfill = false
    compact.assertForOverFulfill = false
    var values: [SizeClassValue] = []
    try observer.observe(viewTag: 4243) { size in
      values.append(size.horizontal)
      if size.horizontal == .regular { regular.fulfill() }
      if size.horizontal == .compact { compact.fulfill() }
    }
    await fulfillment(of: [regular], timeout: 1)
    tabs.selectedViewController = first
    window.layoutIfNeeded()
    let detached = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in second.view.window == nil },
      object: nil
    )
    await fulfillment(of: [detached], timeout: 3)
    tabs.traitOverrides.horizontalSizeClass = .compact
    window.layoutIfNeeded()
    await drainMainQueue()
    XCTAssertEqual(values, [.regular])
    tabs.selectedViewController = second
    window.layoutIfNeeded()
    await fulfillment(of: [compact], timeout: 1)
    XCTAssertEqual(values, [.regular, .compact])
  }

  @MainActor
  func testLookupDoesNotLoadInactiveControllers() async throws {
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let tabs = UITabBarController()
    let inactive = UIViewController()
    tabs.setViewControllers([UIViewController(), inactive], animated: false)
    window.rootViewController = tabs
    window.makeKeyAndVisible()
    window.layoutIfNeeded()
    XCTAssertFalse(inactive.isViewLoaded)
    let observer = HybridSizeClassObserver()
    defer {
      try? observer.stopObserving()
      window.isHidden = true
    }
    let unknown = expectation(description: "Missing tag publishes unknown")
    try observer.observe(viewTag: 999999) { size in
      XCTAssertEqual(size.horizontal, .unknown)
      unknown.fulfill()
    }
    await fulfillment(of: [unknown], timeout: 1)
    XCTAssertFalse(inactive.isViewLoaded)
  }

  @MainActor
  func testStoppedObserverDoesNotPublishWhenTabAppears() async throws {
    let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    let tabs = UITabBarController()
    let inactive = UIViewController()
    inactive.loadViewIfNeeded()
    inactive.view.tag = 4244
    tabs.setViewControllers([UIViewController(), inactive], animated: false)
    tabs.traitOverrides.horizontalSizeClass = .regular
    window.rootViewController = tabs
    window.makeKeyAndVisible()
    window.layoutIfNeeded()
    let observer = HybridSizeClassObserver()
    var values: [SizeClassValue] = []
    try observer.observe(viewTag: 4244) { values.append($0.horizontal) }
    await drainMainQueue()
    try observer.stopObserving()
    await drainMainQueue()
    values.removeAll()
    tabs.selectedViewController = inactive
    window.layoutIfNeeded()
    await drainMainQueue()
    XCTAssertTrue(values.isEmpty)
    window.isHidden = true
  }

  @MainActor
  private func drainMainQueue() async {
    await withCheckedContinuation { continuation in
      DispatchQueue.main.async { continuation.resume() }
    }
  }
}
