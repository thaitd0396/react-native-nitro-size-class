import type {HybridObject} from 'react-native-nitro-modules';

export type SizeClassValue = 'unknown' | 'compact' | 'regular';

export interface SizeClass {
  horizontal: SizeClassValue;
  vertical: SizeClassValue;
}

export interface SizeClassObserver extends HybridObject<{ios: 'swift'}> {
  observe(viewTag: number, onChange: (sizeClass: SizeClass) => void): void;
  stopObserving(): void;
}
