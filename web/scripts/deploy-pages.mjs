import { spawnSync } from 'node:child_process';
import { cpSync, existsSync, mkdirSync, mkdtempSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';

const { values } = parseArgs({ options: {
  project: { type: 'string', default: 'why250-digital-ic-classroom' },
  'prepare-only': { type: 'boolean', default: false },
} });
const project = values.project;
if (!/^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$/.test(project)) throw new Error('Use a 2–63 character Pages project name.');
const root = fileURLToPath(new URL('../', import.meta.url));
const env = { ...process.env, SITE_URL: `https://${project}.pages.dev` };
function run(script, args, cwd = root, capture = false) {
  const result = spawnSync(process.execPath, [path.join(root, script), ...args], { cwd, env, encoding: 'utf8', stdio: capture ? 'pipe' : 'inherit' });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`${script} failed (${result.status}): ${result.stderr ?? ''}`);
  return result.stdout ?? '';
}
run('node_modules/astro/bin/astro.mjs', ['build']);
for (const route of ['index.html', 'plan/index.html', 'courses/index.html', 'lab/spi/index.html', 'learn/course/01_sync_spi/index.html']) {
  if (!existsSync(path.join(root, 'dist', route))) throw new Error(`Missing required page: ${route}`);
}
mkdirSync(path.join(root, '.wrangler'), { recursive: true });
const directory = mkdtempSync(path.join(root, '.wrangler', 'static-pages-'));
const excluded = new Set(['.prerender', '_worker.js', '_routes.json', 'functions', 'worker', '.git']);
for (const entry of readdirSync(path.join(root, 'dist'))) {
  if (!excluded.has(entry)) cpSync(path.join(root, 'dist', entry), path.join(directory, entry), { recursive: true });
}
let files = 0;
let bytes = 0;
function inspect(folder) {
  for (const entry of readdirSync(folder)) {
    const file = path.join(folder, entry);
    const stat = statSync(file);
    if (stat.isDirectory()) inspect(file);
    else {
      if (stat.size > 25 * 1024 * 1024) throw new Error(`Pages file exceeds 25 MiB: ${file}`);
      files++; bytes += stat.size;
    }
  }
}
inspect(directory);
if (files > 20000) throw new Error(`Pages Free file count exceeded: ${files}`);
console.log(JSON.stringify({ project, site: env.SITE_URL, directory, files, bytes }));
if (values['prepare-only']) process.exit(0);
const wrangler = 'node_modules/wrangler/bin/wrangler.js';
const identity = run(wrangler, ['whoami'], directory, true);
if (/not authenticated/i.test(identity)) throw new Error('Cloudflare Pages login required; use wrangler login before deployment.');
const projects = run(wrangler, ['pages', 'project', 'list'], directory, true);
const pattern = new RegExp(`(?:^|[^a-z0-9-])${project}(?:$|[^a-z0-9-])`, 'm');
if (!pattern.test(projects)) run(wrangler, ['pages', 'project', 'create', project, '--production-branch', 'main', '--force'], directory);
run(wrangler, ['pages', 'deploy', '.', '--project-name', project, '--branch', 'main', '--commit-dirty=true'], directory);
console.log(`DIGITAL_IC_PAGES_DEPLOYED ${env.SITE_URL}`);
