import { STORAGE_KEY, emptyProgress, parseProgress, mergeProgress, type Progress, type Status } from '../lib/progress';

interface LessonIndex { id: string; title: string; courseId: string }
const index = JSON.parse(document.querySelector('#lesson-index')?.textContent || '[]') as LessonIndex[];
const ids = new Set(index.map(lesson => lesson.id));
let progress: Progress = emptyProgress();
const notice = document.querySelector<HTMLElement>('#notice');
let noticeTimeout: ReturnType<typeof setTimeout>;
function notify(message: string) {
  if (!notice) return;
  notice.textContent = message;
  notice.classList.add('visible');
  clearTimeout(noticeTimeout);
  noticeTimeout = setTimeout(() => notice.classList.remove('visible'), 6000);
}
try {
  const stored = localStorage.getItem(STORAGE_KEY);
  if (stored) progress = parseProgress(JSON.parse(stored), ids);
} catch { notify('学习记录暂时无法读取。请保留导出的备份；当前页面仍可阅读。'); }
function renderProgress(hydrateInputs = false) {
  document.querySelectorAll<HTMLElement>('[data-course-progress]').forEach(element => {
    const items = index.filter(lesson => lesson.courseId === element.dataset.courseProgress);
    const done = items.filter(lesson => progress.entries[lesson.id]?.status === 'done').length;
    element.textContent = `${done} / ${items.length} 已验收`;
  });
  const total = document.querySelector('#total-progress');
  if (total) total.textContent = `${index.filter(lesson => progress.entries[lesson.id]?.status === 'done').length} / ${index.length}`;
  document.querySelectorAll<HTMLElement>('[data-dot]').forEach(element => element.dataset.status = progress.entries[element.dataset.dot!]?.status ?? 'new');
  if (hydrateInputs) {
    document.querySelectorAll<HTMLSelectElement>('[data-progress]').forEach(element => element.value = progress.entries[element.dataset.progress!]?.status ?? 'new');
    document.querySelectorAll<HTMLTextAreaElement>('[data-note]').forEach(element => element.value = progress.entries[element.dataset.note!]?.note ?? '');
  }
}
function persist(): boolean {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(progress)); renderProgress(); return true; }
  catch { notify('浏览器无法保存记录，请导出备份以保留本次内容。'); return false; }
}
renderProgress(true);
document.querySelectorAll<HTMLSelectElement>('[data-progress]').forEach(element => element.addEventListener('change', () => {
  const id = element.dataset.progress!;
  progress.entries[id] = { status: element.value as Status, note: progress.entries[id]?.note ?? '' };
  if (persist()) notify('个人学习状态已保存。');
}));
document.querySelectorAll<HTMLTextAreaElement>('[data-note]').forEach(element => element.addEventListener('input', () => {
  const id = element.dataset.note!;
  progress.entries[id] = { status: progress.entries[id]?.status ?? 'new', note: element.value };
  persist();
}));
document.querySelector('#export-progress')?.addEventListener('click', () => {
  const blob = new Blob([JSON.stringify(progress, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url; anchor.download = 'digital-ic-learning-backup.json'; anchor.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
});
const importInput = document.querySelector<HTMLInputElement>('#import-file');
document.querySelector('#import-progress')?.addEventListener('click', () => importInput?.click());
importInput?.addEventListener('change', async () => {
  const file = importInput.files?.[0];
  if (!file) return;
  try {
    if (file.size > 3_000_000) throw new Error('备份超过 3 MB，请检查文件。');
    const imported = parseProgress(JSON.parse(await file.text()), ids);
    progress = mergeProgress(progress, imported);
    if (persist()) notify('备份已合并，同一课使用导入记录。');
    renderProgress(true);
  } catch (error) { notify(error instanceof Error ? error.message : '无法导入此备份。'); }
  finally { importInput.value = ''; }
});
document.querySelector('#theme-toggle')?.addEventListener('click', () => {
  const dark = document.documentElement.classList.toggle('dark');
  try { localStorage.setItem('digital-ic-theme', dark ? 'dark' : 'light'); } catch {}
});
const search = document.querySelector<HTMLInputElement>('#course-search');
const filter = document.querySelector<HTMLSelectElement>('#course-filter');
function applySearch() {
  const words = (search?.value ?? '').toLowerCase().trim().split(/\s+/).filter(Boolean);
  let count = 0;
  document.querySelectorAll<HTMLElement>('[data-search]').forEach(element => {
    const visible = words.every(word => element.dataset.search?.includes(word)) && (!filter?.value || element.dataset.course === filter.value);
    element.hidden = !visible;
    if (visible) count++;
  });
  const result = document.querySelector('#search-count');
  if (result) result.textContent = `${count} 份材料`;
  const empty = document.querySelector<HTMLElement>('#search-empty');
  if (empty) empty.hidden = count > 0;
}
search?.addEventListener('input', applySearch);
filter?.addEventListener('change', applySearch);
if (filter) filter.value = new URL(location.href).searchParams.get('course') ?? '';
applySearch();
const hours = document.querySelector<HTMLInputElement>('#weekly-hours');
hours?.addEventListener('input', () => {
  const value = Number(hours.value);
  document.querySelectorAll<HTMLElement>('[data-budget]').forEach(element => {
    const [min, max] = element.dataset.budget!.split(',').map(Number);
    element.textContent = `约 ${Math.ceil(min! / value)}–${Math.ceil(max! / value)} 周`;
  });
  const label = document.querySelector('#hours-value');
  if (label) label.textContent = `${value} h / 周`;
});
hours?.dispatchEvent(new Event('input'));
const diagrams = document.querySelectorAll<HTMLElement>('.mermaid');
if (diagrams.length) {
  import('mermaid').then(async ({ default: mermaid }) => {
    mermaid.initialize({ startOnLoad: false, securityLevel: 'strict', theme: document.documentElement.classList.contains('dark') ? 'dark' : 'neutral', fontFamily: 'system-ui' });
    await mermaid.run({ nodes: Array.from(diagrams) });
  }).catch(() => { /* Keep the readable diagram source if rendering is unavailable. */ });
}
