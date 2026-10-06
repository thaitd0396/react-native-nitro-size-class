import {
  createContext,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import {findNodeHandle, StyleSheet, View} from 'react-native';
import {createSizeClassObserver} from './createSizeClassObserver';
import type {SizeClass} from './SizeClassObserver.nitro';

const UNKNOWN_SIZE_CLASS: SizeClass = {
  horizontal: 'unknown',
  vertical: 'unknown',
};
const SizeClassContext = createContext<SizeClass>(UNKNOWN_SIZE_CLASS);

export function SizeClassProvider({children}: {children: ReactNode}) {
  const viewRef = useRef<View>(null);
  const [sizeClass, setSizeClass] = useState<SizeClass>(UNKNOWN_SIZE_CLASS);
  const [viewTag, setViewTag] = useState<number | null>(null);

  useEffect(() => {
    if (viewTag === null) {
      return;
    }
    const observer = createSizeClassObserver();
    let active = true;
    observer?.observe(viewTag, nextSizeClass => {
      if (active) {
        setSizeClass(nextSizeClass);
      }
    });
    return () => {
      active = false;
      observer?.stopObserving();
    };
  }, [viewTag]);

  return (
    <View
      ref={viewRef}
      collapsable={false}
      style={styles.container}
      onLayout={() => setViewTag(findNodeHandle(viewRef.current))}>
      <SizeClassContext.Provider value={sizeClass}>
        {children}
      </SizeClassContext.Provider>
    </View>
  );
}

export function useSizeClass(): SizeClass {
  return useContext(SizeClassContext);
}

const styles = StyleSheet.create({container: {flex: 1}});
