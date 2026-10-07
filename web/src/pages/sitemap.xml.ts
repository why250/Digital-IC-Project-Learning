import { documents, sourceFiles } from '../lib/catalog';
import type { APIRoute } from 'astro';
export const GET: APIRoute = ({ site }) => {
  const routes = ['/', '/plan/', '/courses/', '/lab/spi/', '/artifacts/', ...documents.map(doc => doc.url), ...sourceFiles.map(file => `/source/${file}`)];
  return new Response(`<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${routes.map(route => `<url><loc>${new URL(route, site)}</loc></url>`).join('')}</urlset>`, { headers: { 'Content-Type': 'application/xml; charset=utf-8' } });
};
