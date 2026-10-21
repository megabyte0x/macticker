import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import sitemap from '@astrojs/sitemap';
import tailwind from '@tailwindcss/vite';
export default defineConfig({site:'https://ticker.megabyte.sh',integrations:[react(),sitemap({filter:page=>!page.endsWith("/404/") && !page.endsWith("/404.html")})],vite:{plugins:[tailwind()]}});
