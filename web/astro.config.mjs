import { defineConfig } from 'astro/config';
import { fileURLToPath } from 'node:url';

export default defineConfig({
  site: process.env.SITE_URL || 'https://why250-digital-ic-classroom.pages.dev',
  output: 'static',
  trailingSlash: 'always',
  build: { format: 'directory' },
  vite: { define: { __PROJECT_ROOT__: JSON.stringify(fileURLToPath(new URL('../', import.meta.url))) } },
});
