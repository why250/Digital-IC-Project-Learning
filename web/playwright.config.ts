import { defineConfig, devices } from '@playwright/test';
export default defineConfig({
  testDir: './e2e',
  testMatch: '**/*.pw.ts',
  workers: 2,
  retries: 0,
  reporter: 'list',
  use: { baseURL: 'http://127.0.0.1:4323', ...devices['Desktop Chrome'], viewport: { width: 1440, height: 960 }, reducedMotion: 'reduce', screenshot: 'only-on-failure', launchOptions: process.env.PLAYWRIGHT_EXECUTABLE_PATH ? { executablePath: process.env.PLAYWRIGHT_EXECUTABLE_PATH } : {} },
  webServer: { command: 'node e2e/preview.mjs', url: 'http://127.0.0.1:4323', reuseExistingServer: false, timeout: 30000 },
});
