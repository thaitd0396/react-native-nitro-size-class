import {NitroModules} from 'react-native-nitro-modules';
import type {SizeClassObserver} from './SizeClassObserver.nitro';

export function createSizeClassObserver(): SizeClassObserver {
  return NitroModules.createHybridObject<SizeClassObserver>(
    'SizeClassObserver',
  );
}
