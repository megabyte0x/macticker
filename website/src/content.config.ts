import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';
export const collections = {guides:defineCollection({loader:glob({pattern:'*.md',base:'./src/content/guides'}),schema:z.object({title:z.string(),description:z.string(),date:z.string(),category:z.string()})})};
