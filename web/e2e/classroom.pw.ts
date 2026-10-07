import { test, expect } from '@playwright/test';

test('home, course search, reader and source navigation', async ({ page }) => {
  const errors: string[] = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1 })).toContainText('从模拟直觉');
  await page.getByRole('link', { name: '开始第一课' }).click();
  await expect(page.locator('article.prose h1')).toContainText('同步 RTL');
  await expect(page.locator('.mermaid svg')).toBeVisible();
  await page.locator('article.prose').getByRole('link', { name: 'RTL', exact: true }).click();
  await expect(page.locator('.source-code')).toContainText('module spi_master');
  await page.goto('/courses/');
  await page.getByRole('searchbox').fill('CIC');
  await expect(page.locator('.document-card:visible').first()).toBeVisible();
  await page.locator('#course-filter').selectOption('delta_sigma_filter');
  await expect(page.locator('.document-card:visible').first()).toHaveAttribute('data-course', 'delta_sigma_filter');
  await page.getByRole('searchbox').fill('there-is-no-such-course-12345');
  await expect(page.locator('#search-empty')).toBeVisible();
  expect(errors).toEqual([]);
});

test('lesson records lead directly to a relevant reading and the project experiment', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/plan/');
  const record = page.locator('[data-lesson="03"]');
  await record.locator('summary').click();
  await record.getByRole('link', { name: '本课选读与实验' }).click();
  await expect(page).toHaveURL(/#03-.*$/);
  await expect(page.getByRole('heading', { name: '03 参考与实验', exact: true })).toBeInViewport();
  const reading = page.locator('h3[id="03-参考与实验"] + ul');
  await expect(reading).toContainText('Non-Blocking Assignments');
  await expect(reading).toContainText('tx_shift');
  await expect(reading.getByRole('link', { name: 'EECS151 ASIC Lab 1：SystemVerilog Primer', exact: true })).toHaveAttribute('href', 'https://eecs151.org/asic/lab1/docs/pg4-verilog/');
  await expect(reading.getByRole('link', { name: '学习日志模板', exact: true })).toHaveAttribute('href', '/learn/learning_log/_template/');
  await page.getByRole('navigation', { name: '本讲逐课选读与实验' }).getByRole('link', { name: /^06：/ }).click();
  await expect(page.getByRole('heading', { name: '06 参考与实验', exact: true })).toBeInViewport();
  await expect(page.locator('h3[id="06-参考与实验"] + ul')).toContainText('EXP-VERIFY-CONTRACT');
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
});

test('learning state and notes persist; valid import merges and invalid import is rejected', async ({ page }) => {
  await page.goto('/plan/');
  const record = page.locator('[data-lesson="01"]');
  await record.locator('summary').click();
  await record.locator('select').selectOption('learning');
  await record.locator('textarea').fill('Q reads the old state; CS setup is one half-period.');
  await page.reload();
  await record.locator('summary').click();
  await expect(record.locator('select')).toHaveValue('learning');
  await expect(record.locator('textarea')).toHaveValue(/Q reads the old state/);
  const downloadEvent = page.waitForEvent('download');
  await page.getByRole('button', { name: '导出学习备份' }).click();
  expect((await downloadEvent).suggestedFilename()).toBe('digital-ic-learning-backup.json');
  await page.locator('#import-file').setInputFiles({ name: 'backup.json', mimeType: 'application/json', buffer: Buffer.from(JSON.stringify({ version: 1, entries: { '02': { status: 'done', note: 'A5 / 3C' } } })) });
  await expect(page.locator('#total-progress')).toHaveText('1 / 94');
  await expect(record.locator('textarea')).toHaveValue(/Q reads the old state/);
  await page.locator('#import-file').setInputFiles({ name: 'bad.json', mimeType: 'application/json', buffer: Buffer.from('{"version":2,"entries":{}}') });
  await expect(page.locator('#notice')).toContainText('文件格式不匹配');
  await expect(page.locator('#total-progress')).toHaveText('1 / 94');
});

test('SPI controls expose the eighth edge and divider timing', async ({ page }) => {
  await page.goto('/lab/spi/');
  await expect(page.locator('#cs-release')).toHaveText('8.5 μs');
  await page.locator('[data-edge="7"]').click();
  await expect(page.locator('#rx-register')).toHaveText('rx_shift = 00111100');
  await expect(page.locator('#sample-explanation')).toContainText('0x3C');
  await page.locator('#divider').selectOption('1');
  await expect(page.locator('#sample-time')).toContainText('300 ns · 第 15 个 clk 周期');
  await expect(page.locator('#cs-release')).toHaveText('340 ns');
  await page.locator('#tx-byte').fill('ZZ');
  await expect(page.locator('#input-error')).toBeVisible();
  await page.getByRole('button', { name: '恢复 A5 / 3C' }).click();
  await expect(page.locator('#input-error')).toBeHidden();
  await expect(page.locator('#cs-release')).toHaveText('8.5 μs');
});

for (const route of ['/', '/plan/', '/courses/', '/learn/course/01_sync_spi/', '/lab/spi/']) {
  test(`mobile layout has no page overflow: ${route}`, async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto(route);
    await expect(page.getByRole('heading', { level: 1 }).first()).toBeVisible();
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  });
}
