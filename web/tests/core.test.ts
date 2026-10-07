import { test } from 'node:test';
import assert from 'node:assert/strict';
import { documents, courses, lessons, renderDocument, resolveLink, sourceFiles } from '../src/lib/catalog';
import { spiFrame, frameTraces } from '../src/lib/spi';
import { parseProgress, mergeProgress, emptyProgress } from '../src/lib/progress';

test('all 94 lessons have unique IDs, a lecture and an actual rendered anchor', () => {
  assert.equal(lessons.length, 94);
  assert.equal(new Set(lessons.map(lesson => lesson.id)).size, 94);
  for (const lesson of lessons) {
    const doc = documents.find(item => item.file === lesson.file)!;
    const fragment = lesson.url.split('#')[1];
    assert.ok(renderDocument(doc).includes(`id="${fragment}"`), lesson.id);
  }
  assert.equal(courses.length, 6);
});

test('Markdown headings, links and generated-artifact references resolve consistently', () => {
  for (const doc of documents) {
    const html = renderDocument(doc);
    for (const heading of doc.headings) assert.ok(html.includes(`id="${heading.slug}"`), `${doc.file}: ${heading.slug}`);
    for (const match of html.matchAll(/href="([^"]+)"/g)) {
      const href = match[1]!.replaceAll('&amp;', '&');
      if (!href.startsWith('/') && !href.startsWith('#')) continue;
      const [pathname, fragment] = href.split('#');
      if (pathname === '/artifacts/') continue;
      if (pathname?.startsWith('/source/')) { assert.ok(sourceFiles.includes(pathname.slice(8))); continue; }
      const destination = pathname ? documents.find(item => item.url === pathname) : doc;
      assert.ok(destination, `${doc.file} -> ${href}`);
      if (fragment) assert.ok(renderDocument(destination).includes(`id="${decodeURIComponent(fragment)}"`), `${doc.file} -> ${href}`);
    }
  }
  assert.equal(resolveLink('docs/course/01_sync_spi.md', '../../lessons/01_spi_master/results/sim/div25/spi_first_frame.svg'), '/artifacts/');
});

test('SPI ideal protocol matches bit order and independent integer timing for every byte', () => {
  for (const divider of [1, 3, 25]) for (let tx = 0; tx < 256; tx++) {
    const rx = 255 - tx;
    const frame = spiFrame(tx, rx, divider);
    const txSerial = frame.edges.map(edge => edge.tx).join('');
    const rxSerial = frame.edges.map(edge => edge.rx).join('');
    assert.equal(parseInt(txSerial, 2), tx);
    assert.equal(parseInt(rxSerial, 2), rx);
    frame.edges.forEach((edge, i) => {
      assert.equal(edge.atNs / 20, (2 * i + 1) * divider);
      assert.equal(edge.received, parseInt(rxSerial.slice(0, i + 1), 2));
    });
    assert.equal(frame.rxUpdateNs, frame.edges[7]!.atNs);
    assert.equal(frame.releaseNs - frame.rxUpdateNs, 2 * 20 * divider);
    assert.equal(frame.doneWidthNs, 20);
    assert.match(frameTraces(tx, rx, divider).sclk, /^M/);
  }
  assert.equal(spiFrame(0xA5, 0x3C, 25).releaseNs, 8500);
  assert.throws(() => spiFrame(256, 1, 25));
  assert.throws(() => spiFrame(1, 1, 0));
});

test('import validates IDs and status, merges records without deleting unrelated notes', () => {
  const known = new Set(['01', '02']);
  const current = parseProgress({ version: 1, entries: { '01': { status: 'learning', note: '<script>personal text</script>' } } }, known);
  const imported = parseProgress({ version: 1, entries: { '02': { status: 'done', note: 'sample timing' } } }, known);
  assert.deepEqual(mergeProgress(current, imported).entries, { ...current.entries, ...imported.entries });
  assert.equal(mergeProgress(current, emptyProgress()).entries['01']?.note, '<script>personal text</script>');
  assert.throws(() => parseProgress({ version: 1, entries: { unknown: { status: 'done', note: '' } } }, known));
  assert.throws(() => parseProgress({ version: 1, entries: { '01': { status: 'PASS', note: '' } } }, known));
  assert.throws(() => parseProgress({ version: 2, entries: {} }, known));
});
