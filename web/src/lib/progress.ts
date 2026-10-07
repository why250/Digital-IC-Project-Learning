export type Status = 'new' | 'learning' | 'done';
export interface RecordEntry { status: Status; note: string }
export interface Progress { version: 1; entries: Record<string, RecordEntry> }
export const STORAGE_KEY = 'digital-ic-classroom:v1';
export const emptyProgress = (): Progress => ({ version: 1, entries: {} });
export function parseProgress(input: unknown, knownIds: ReadonlySet<string>): Progress {
  if (!input || typeof input !== 'object' || !('version' in input) || input.version !== 1 ||
    !('entries' in input) || !input.entries || typeof input.entries !== 'object' || Array.isArray(input.entries)) {
    throw new Error('文件格式不匹配，请选择本网站导出的学习备份。');
  }
  const entries: Record<string, RecordEntry> = {};
  for (const [id, value] of Object.entries(input.entries)) {
    if (!knownIds.has(id) || !value || typeof value !== 'object' || !('status' in value) ||
      !['new', 'learning', 'done'].includes(String(value.status)) || !('note' in value) ||
      typeof value.note !== 'string' || value.note.length > 20000) throw new Error('备份包含未知课程或无效记录。');
    entries[id] = { status: value.status as Status, note: value.note };
  }
  return { version: 1, entries };
}
export function mergeProgress(current: Progress, imported: Progress): Progress {
  return { version: 1, entries: { ...current.entries, ...imported.entries } };
}
