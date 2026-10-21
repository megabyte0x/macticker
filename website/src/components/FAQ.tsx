import type * as React from 'react';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from './ui/accordion';
const items = [
['Which Macs can run Ticker?', 'Ticker requires macOS 26 or newer. This download is built for Apple Silicon Macs (M1 and later).'],
['Do I need an account or an API key?', 'No. Open the app and use the default Bitcoin, Ethereum and Solana watchlist, or search CoinGecko for another token.'],
['How often do prices update?', 'Ticker requests USD prices every minute. CoinGecko may rate-limit requests. A tilde next to the menu bar price and a Stale label identify outdated data.'],
['Can I set alerts or track my portfolio?', 'Ticker shows prices and percentage changes. It does not include price alerts, exchange connections, wallet imports or portfolio accounting.'],
['Is Ticker signed and notarized?', 'Yes. Ticker is signed with Yash Garg’s Developer ID and notarized by Apple. macOS may ask you to confirm opening an app downloaded from the internet. Read the installation page for details.']
];
// forceMount keeps closed answers in the prerendered HTML so crawlers and no-JS readers get them.
// Clearing Radix's inline CSS variables avoids a server-rendered style attribute that the hashed CSP blocks; global.css maps them instead.
const noInlineVars = {'--radix-accordion-content-height':undefined,'--radix-accordion-content-width':undefined} as React.CSSProperties;
export default function FAQ(){return <Accordion type="single" collapsible className="grouped-list">{items.map(([q,a],i)=><AccordionItem value={String(i)} key={q}><AccordionTrigger>{q}</AccordionTrigger><AccordionContent forceMount style={noInlineVars}><p>{a}</p></AccordionContent></AccordionItem>)}</Accordion>}
