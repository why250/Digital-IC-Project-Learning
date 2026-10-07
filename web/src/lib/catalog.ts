import { readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import GithubSlugger from 'github-slugger';
import { Marked, Renderer } from 'marked';

declare const __PROJECT_ROOT__: string;
export const projectRoot = typeof __PROJECT_ROOT__ === 'undefined'
  ? fileURLToPath(new URL('../../../', import.meta.url)) : __PROJECT_ROOT__;
export const classroomURL = 'https://why250-circuits-classroom.pages.dev/';
export const repositoryURL = 'https://github.com/why250/Digital-IC-Project-Learning';
export interface Course {
  id: string; title: string; label: string; summary: string; hours: string;
  prerequisite: string; evidence: string; prefix: string; first: number; last: number;
  lectures: number; icon: string;
}
export const courses: Course[] = [
  { id: 'course', title: '数字基础', label: '01–24', summary: '从寄存器和门开始，理解 SPI、同步更新、综合时序与 CDC。', hours: '60–90 h', prerequisite: '起点：模拟电路与时序直觉', evidence: 'SPI Master 已有 RTL 仿真与教学综合', prefix: '', first: 1, last: 24, lectures: 6, icon: '01' },
  { id: 'mixed_signal', title: '数模混合控制', label: '25–48', summary: '让模拟电路有序启动、稳定采样，用定点测量完成有限、可恢复的校准。', hours: '120–170 h', prerequisite: '同步 RTL、配置 / CDC 与 STA', evidence: '课程与项目契约已提供，控制项目待实现', prefix: '', first: 25, last: 48, lectures: 6, icon: '02' },
  { id: 'delta_sigma_filter', title: 'ΔΣ 后级数字滤波', label: 'DF01–DF08', summary: '把已有 CT 环路经验接到频谱、抽取、CIC / FIR 与定点实现。', hours: '40–70 h', prerequisite: '数学可并行；RTL 前完成 01–10、33–35', evidence: '优先项目：系数、模型与抽取 RTL 待实现', prefix: 'DF', first: 1, last: 8, lectures: 8, icon: '03' },
  { id: 'adc_digital', title: 'ADC 内部数字模块', label: 'AD01–AD20', summary: 'SAR、编码、DEM、样本重排和交织校准，从模拟失配到数字数据通路。', hours: '80–120 h', prerequisite: 'TI 实现需要 CDC / FIFO、定点与 STA', evidence: '七个 RTL top、独立回归与连续码流已有证据', prefix: 'AD', first: 1, last: 20, lectures: 5, icon: '04' },
  { id: 'dac_digital', title: '时间交织 DAC', label: 'TD01–TD12', summary: '理解重构与镜像，先交付正确的码，再处理插值、预加载和通道校正。', hours: '60–90 h', prerequisite: '公共基础与定点；数学可与 DF / AD 并行', evidence: '课程与架构契约已提供，模型 / RTL 待实现', prefix: 'TD', first: 1, last: 12, lectures: 4, icon: '05' },
  { id: 'ams', title: 'Virtuoso AMS', label: 'AM01–AM06', summary: '连接 RTL 边沿与连续时间节点：接口桥、settling、SAR 和 trim 联合验证。', hours: '64–96 h', prerequisite: '01–06 后可做解析；真实运行需 AMS 环境', evidence: '课程已提供；官方示例停在缺连接库的网表阶段', prefix: 'AM', first: 1, last: 6, lectures: 6, icon: '06' },
];

export interface Heading { depth: number; text: string; slug: string }
export interface Document {
  file: string; slug: string; url: string; title: string; content: string;
  headings: Heading[]; courseId?: string; kind: string; search: string;
}
export interface Lesson { id: string; title: string; url: string; readingUrl: string; courseId: string; file: string }
function walk(directory: string): string[] {
  return readdirSync(path.join(projectRoot, directory), { withFileTypes: true }).flatMap(entry => {
    const file = `${directory}/${entry.name}`;
    return entry.isDirectory() ? walk(file) : [file];
  });
}
export function headingsOf(content: string): Heading[] {
  const slugger = new GithubSlugger();
  let fence = '';
  const headings: Heading[] = [];
  for (const line of content.split('\n')) {
    const marker = line.match(/^\s{0,3}(`{3,}|~{3,})/);
    if (marker) {
      if (!fence) fence = marker[1]!;
      else if (marker[1]![0] === fence[0] && marker[1]!.length >= fence.length) fence = '';
      continue;
    }
    if (fence) continue;
    const match = line.match(/^(#{1,6})\s+(.+?)\s*#*\s*$/);
    if (match) {
      const text = match[2]!.replace(/`/g, '').replace(/\[([^\]]+)\]\([^)]+\)/g, '$1');
      headings.push({ depth: match[1]!.length, text, slug: slugger.slug(text) });
    }
  }
  return headings;
}
function documentFor(file: string): Document {
  const content = readFileSync(path.join(projectRoot, file), 'utf8');
  const headings = headingsOf(content);
  const slug = file === 'README.md' ? 'project' : file === 'web/README.md' ? 'website' : file.startsWith('lessons/') ? 'adc-source' : file.slice(5, -3);
  const courseId = courses.find(course => file.startsWith(`docs/${course.id}/`))?.id;
  const basename = path.posix.basename(file);
  const kind = basename.startsWith('00_') ? '总纲' : basename.includes('answers') ? '答案'
    : basename.includes('workbook') ? '记录与验收' : basename.includes('project') || basename.includes('capstone') ? '项目规格'
    : courseId ? '讲义 / 参考' : file.includes('/history/') ? '历史记录' : '工程参考';
  const title = headings[0]?.text ?? basename;
  return { file, slug, url: `/learn/${slug}/`, title, content, headings, courseId, kind,
    search: `${title} ${content}`.toLowerCase().replace(/\s+/g, ' ') };
}
export const documents = [...walk('docs').filter(file => file.endsWith('.md')), 'README.md', 'lessons/adc_digital/README.md', 'web/README.md'].map(documentFor);
export const lessons: Lesson[] = courses.flatMap(course => {
  const chapterDocs = documents.filter(doc => doc.courseId === course.id &&
    Number(path.posix.basename(doc.file).slice(0, 2)) >= 1 &&
    Number(path.posix.basename(doc.file).slice(0, 2)) <= course.lectures);
  const pattern = new RegExp(`^${course.prefix}(\\d{2})(?:[:：\\s]|$)`);
  return chapterDocs.flatMap(doc => doc.headings.filter(heading => heading.depth <= 2 && pattern.test(heading.text)).map(heading => {
    const number = heading.text.match(pattern)![1]!;
    const id = `${course.prefix}${number}`;
    const reading = doc.headings.find(item => item.depth === 3 && item.text === `${id} 参考与实验`);
    if (!reading) throw new Error(`Missing lesson reading and experiment: ${id}`);
    return { id, title: heading.text, url: `${doc.url}#${heading.slug}`, readingUrl: `${doc.url}#${reading.slug}`, courseId: course.id, file: doc.file };
  }));
});
for (const course of courses) {
  const actual = lessons.filter(lesson => lesson.courseId === course.id).map(lesson => lesson.id);
  const expected = Array.from({ length: course.last - course.first + 1 }, (_, i) => `${course.prefix}${String(i + course.first).padStart(2, '0')}`);
  if (actual.join(',') !== expected.join(',')) throw new Error(`Course coverage mismatch: ${course.id}`);
}
export const sourceFiles = walk('lessons').filter(file => !file.includes('/results/') && /\.(sv|sdc|tcl|sh|py)$/.test(file));
const documentByFile = new Map(documents.map(doc => [doc.file, doc]));
const sources = new Set(sourceFiles);
export function resolveLink(fromFile: string, href: string): string {
  if (/^(?:https?:|mailto:|#)/i.test(href)) return href;
  const [rawPath, fragment] = href.split('#');
  const file = path.posix.normalize(path.posix.join(path.posix.dirname(fromFile), decodeURIComponent(rawPath!)));
  const suffix = fragment ? `#${fragment}` : '';
  const doc = documentByFile.get(file);
  if (doc) return `${doc.url}${suffix}`;
  if (file.includes('/results/') || file.startsWith('.tools/')) return '/artifacts/';
  if (sources.has(file)) return `/source/${file}${suffix}`;
  if (file.startsWith('../') || path.posix.isAbsolute(file)) throw new Error(`Invalid repository link: ${fromFile} -> ${href}`);
  return `${repositoryURL}/blob/main/${file}${suffix}`;
}
export function escapeHTML(text: string): string {
  return text.replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]!);
}
export function renderDocument(doc: Document): string {
  const slugger = new GithubSlugger();
  const renderer = new Renderer();
  renderer.heading = function ({ tokens, depth }) {
    const html = this.parser.parseInline(tokens);
    const plain = html.replace(/<[^>]*>/g, '').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>');
    return `<h${depth} id="${escapeHTML(slugger.slug(plain))}">${html}</h${depth}>\n`;
  };
  renderer.link = function ({ href, tokens }) {
    const resolved = resolveLink(doc.file, href);
    const external = /^https?:/.test(resolved);
    return `<a href="${escapeHTML(resolved)}"${external ? ' target="_blank" rel="noreferrer"' : ''}>${this.parser.parseInline(tokens)}</a>`;
  };
  renderer.code = function ({ text, lang }) {
    if (lang === 'mermaid') return `<pre class="mermaid">${escapeHTML(text)}</pre>`;
    return `<pre><code${lang ? ` class="language-${escapeHTML(lang)}"` : ''}>${escapeHTML(text)}</code></pre>\n`;
  };
  return new Marked({ renderer, gfm: true, async: false }).parse(doc.content) as string;
}
