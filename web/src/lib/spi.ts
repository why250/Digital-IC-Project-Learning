export interface SamplingEdge { bit: number; atNs: number; tx: number; rx: number; received: number }
export function spiFrame(tx: number, rx: number, divider: number) {
  if (![tx, rx].every(value => Number.isInteger(value) && value >= 0 && value <= 255)) throw new Error('SPI data must be an 8-bit byte');
  if (!Number.isInteger(divider) || divider < 1) throw new Error('Divider must be a positive integer');
  const halfNs = divider * 20;
  const edges: SamplingEdge[] = Array.from({ length: 8 }, (_, bit) => ({
    bit, atNs: (2 * bit + 1) * halfNs, tx: (tx >> (7 - bit)) & 1, rx: (rx >> (7 - bit)) & 1,
    received: rx >> (7 - bit),
  }));
  return { tx, rx, halfNs, frequencyMHz: 50 / (2 * divider), releaseNs: 17 * halfNs,
    rxUpdateNs: 15 * halfNs, doneWidthNs: 20, edges };
}

export const tracePath = (points: Array<[number, number]>, row: number) => points.map(([halfCycle, level], i) =>
  `${i === 0 ? 'M' : 'H'}${72 + 40 * halfCycle}${i === 0 ? ` ${row - level * 22}` : `V${row - level * 22}`}`,
).join(' ');
export function frameTraces(tx: number, rx: number, divider: number) {
  const data = (byte: number, clear: boolean): Array<[number, number]> => [
    [-1, 0], [0, byte >> 7],
    ...Array.from({ length: 7 }, (_, i): [number, number] => [2 * (i + 1), (byte >> (6 - i)) & 1]),
    [16, clear ? 0 : byte & 1], [18.5, clear ? 0 : byte & 1],
  ];
  return {
    cs: tracePath([[-1, 1], [0, 0], [17, 1], [18.5, 1]], 58),
    sclk: tracePath([[-1, 0], ...Array.from({ length: 17 }, (_, i): [number, number] => [i, i % 2]), [18.5, 0]], 108),
    mosi: tracePath(data(tx, true), 158),
    miso: tracePath(data(rx, false), 208),
    done: tracePath([[-1, 0], [17, 1], [17 + 1 / divider, 0], [18.5, 0]], 258),
  };
}
