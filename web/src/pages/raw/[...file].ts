import { documents, type Document } from '../../lib/catalog';
import type { APIRoute } from 'astro';
export function getStaticPaths() { return documents.map(doc => ({ params: { file: doc.file }, props: { doc } })); }
export const GET: APIRoute = ({ props }) => new Response((props.doc as Document).content, { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
