#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$PACKAGE_DIR/ios/HybridSizeClassObserver.swift"
DESTINATION="${1:?Usage: bash scripts/test-size-class-ios.sh 'platform=iOS Simulator,id=<UDID>'}"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/size-class-tests.XXXXXX")"

cp "$PACKAGE_DIR"/scripts/tests/size-class-ios/*.swift "$TEST_DIR/"
mv "$TEST_DIR/SizeClassObserverTests.swift" "$TEST_DIR/Tests.swift"
cp "$PACKAGE_DIR/scripts/tests/size-class-ios/create-project.rb" "$TEST_DIR/"
# Only the Nitro protocol/value bindings are stubbed; UIKit runs on the simulator.
sed '/^import NitroModules$/d' "$SOURCE" > "$TEST_DIR/Observer.swift"
ruby "$TEST_DIR/create-project.rb"
echo "Native test artifacts: $TEST_DIR"
xcodebuild test \
  -project "$TEST_DIR/SizeClassTests.xcodeproj" \
  -scheme SizeClassHarness \
  -destination "$DESTINATION" \
  -derivedDataPath "$TEST_DIR/build" \
  -parallel-testing-enabled NO \
  -quiet
