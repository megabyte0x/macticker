import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';
export const collections = {guides:defineCollection({
  loader:glob({pattern:'*.md',base:'./src/content/guides'}),
  schema:z.object({
    title:z.string(),
    description:z.string(),
    date:z.string().date(),
    updated:z.string().date().optional(),
    category:z.enum(['Comparison','Setup','Price data']),
    related:z.array(z.string()).default([])
  }).refine(data=>!data.updated || data.updated >= data.date, {message:'Updated date must not precede publication'})
})};
