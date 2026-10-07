import { preview } from 'astro';
// Foreground server: Playwright owns this process and the dedicated test port.
const server = await preview({ server: { host: '127.0.0.1', port: 4323 }, vite: { preview: { strictPort: true } } });
for (const signal of ['SIGINT', 'SIGTERM']) process.once(signal, async () => { await server.stop(); process.exit(0); });
await server.closed();
