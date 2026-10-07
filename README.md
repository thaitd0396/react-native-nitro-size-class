# React Native Nitro Size Class

An iOS Nitro module that follows UIKit size classes for the view wrapped by its provider. Its provider and hook expose only the horizontal size class:

```tsx
import {FlatList} from 'react-native';
import {SizeClassProvider, useSizeClass} from 'react-native-nitro-size-class';

function Layout() {
  const {horizontal} = useSizeClass();
  return <FlatList data={items} renderItem={renderItem} numColumns={horizontal === 'regular' ? 2 : 1} key={horizontal} />;
}

function Screen() {
  return <SizeClassProvider><Layout /></SizeClassProvider>;
}
```

`horizontal` is `unknown`, `compact`, or `regular`. The initial value is `unknown` until the provider has laid out and the native observer has attached. Android does not register a native module and keeps `horizontal` `unknown`.

The provider keeps its native View from collapsing and passes its Fabric tag to a Nitro HybridObject. On the main queue, the object locates that exact view across scene windows and attaches a zero-sized UIKit observer. It sends an initial snapshot, tracks horizontal size-class changes, deduplicates identical values, and detaches on unmount. iOS 17+ uses trait registrations; iOS 16 uses `traitCollectionDidChange`. UIKit work stays on the main queue, and pending callbacks are ignored after React cleanup.

## Migration from 0.1.x

Version 0.2.0 removes `vertical` from `SizeClass`. Read `{horizontal}` from `useSizeClass()` and rebuild the native app to use the matching Nitro bindings. Vertical-only trait changes no longer emit updates.

## Installation

```sh
npm install react-native-nitro-size-class react-native-nitro-modules@0.35.10
cd ios && pod install
```

Rebuild the native app after installing. Requires iOS 16.2+, React Native New Architecture, React 19, and Nitro Modules 0.35.10. Verified with React Native 0.85.3. Android keeps `horizontal` `unknown` and does not link an iOS native implementation.

## Development

```sh
npm ci
npm run codegen
npm run typecheck
npm test
npm run build
npm pack --dry-run
```

Nitrogen-generated bindings are checked in. Run `npm run codegen` after changing the `.nitro.ts` spec, then reinstall pods and rebuild the consuming app. The package uses TypeScript for its CommonJS build; Metro resolves its platform-specific TypeScript sources through the `react-native` entry.

References: [original provider/hook API](https://github.com/tyfyakov21/react-native-size-class), [Nitro module guide](https://nitro.margelo.com/docs/getting-started/how-to-build-a-nitro-module).
