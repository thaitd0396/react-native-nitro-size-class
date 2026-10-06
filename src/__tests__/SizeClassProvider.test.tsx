import {act, fireEvent, render, screen} from '@testing-library/react-native';
import {findNodeHandle, Text} from 'react-native';
import {SizeClassProvider, useSizeClass} from '../SizeClassProvider';
import type {SizeClass} from '../SizeClassObserver.nitro';

const mockObserver = {observe: jest.fn(), stopObserving: jest.fn()};
jest.mock('../createSizeClassObserver', () => ({
  createSizeClassObserver: () => mockObserver,
}));
jest.mock('react-native', () => {
  const native =
    jest.requireActual<typeof import('react-native')>('react-native');
  return Object.defineProperties(
    {},
    {
      ...Object.getOwnPropertyDescriptors(native),
      findNodeHandle: {value: jest.fn(() => 42)},
    },
  );
});

function Probe() {
  const {horizontal, vertical} = useSizeClass();
  return <Text>{`${horizontal}/${vertical}`}</Text>;
}

beforeEach(() => jest.clearAllMocks());

test('subscribes after layout and updates traits without recreating the observer', async () => {
  await render(
    <SizeClassProvider>
      <Probe />
    </SizeClassProvider>,
  );
  expect(screen.getByText('unknown/unknown')).toBeTruthy();
  expect(mockObserver.observe).not.toHaveBeenCalled();
  await fireEvent(screen.root!, 'layout');
  expect(findNodeHandle).toHaveBeenCalled();
  expect(mockObserver.observe).toHaveBeenCalledWith(42, expect.any(Function));
  const onChange = mockObserver.observe.mock.calls[0][1] as (
    value: SizeClass,
  ) => void;
  await act(() => onChange({horizontal: 'regular', vertical: 'regular'}));
  expect(screen.getByText('regular/regular')).toBeTruthy();
  await act(() => onChange({horizontal: 'compact', vertical: 'regular'}));
  expect(screen.getByText('compact/regular')).toBeTruthy();
  await fireEvent(screen.root!, 'layout');
  expect(mockObserver.observe).toHaveBeenCalledTimes(1);
});

test('detaches on unmount and ignores pending native callbacks', async () => {
  await render(
    <SizeClassProvider>
      <Probe />
    </SizeClassProvider>,
  );
  await fireEvent(screen.root!, 'layout');
  const onChange = mockObserver.observe.mock.calls[0][1] as (
    value: SizeClass,
  ) => void;
  await screen.unmount();
  expect(mockObserver.stopObserving).toHaveBeenCalledTimes(1);
  await act(() => onChange({horizontal: 'regular', vertical: 'regular'}));
});
