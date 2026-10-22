---
title: "Why a crypto ticker can show an old price"
description: "Understand one-minute refresh attempts, CoinGecko rate limits and Ticker's stale-price indicators before relying on a menu bar quote."
date: "2026-10-01"
updated: "2026-10-22"
category: "Price data"
related: ["bitcoin-price-mac-menu-bar", "mac-crypto-ticker-alternatives"]
---
A crypto price can remain visible after the app loses access to fresh data. Ticker retains the last successful quotes when a refresh fails, then marks them as outdated. A tilde beside the menu bar price is a reason to check the popup, not an extra decimal or an estimate of price movement.

## Refresh frequency and quote age are different

Ticker attempts to fetch USD prices every 60 seconds. That interval describes the app's requests. It does not guarantee that CoinGecko has a new quote each time or that your internet connection completes every request.

A quote includes a provider timestamp. Ticker treats a quote as stale when that timestamp is more than ten minutes old, missing or unreadable. It also flags the menu bar price after a refresh error, even if the last quote is younger than ten minutes. These rules come from the app's [`Quote.isStale` and `TokenStore.menuTitle` implementation](https://github.com/megabyte0x/macticker/blob/main/Sources/Ticker/TokenStore.swift). The ten-minute cutoff is checked when the quote is evaluated; it is not a promise of uninterrupted background updates while your Mac sleeps.

The percentage-change selector is independent. Choosing 1h, 24h or 1w changes the comparison period displayed in your watchlist. It does not turn one-minute polling into hourly, daily or weekly polling.

## What does each price indicator mean?

<p class="table-hint">Scroll horizontally to compare all columns.</p>
<div class="table-scroll" role="region" aria-label="Ticker price indicators" tabindex="0">

| What you see | What it means | What to do |
| --- | --- | --- |
| A price with a tilde in the menu bar | A refresh failed, or the quote timestamp is stale | Open the popup and check the status |
| A Stale label on a token | Its timestamp is older than ten minutes, missing or unreadable | Check the connection and try Refresh Prices |
| Prices unavailable | A request failed; earlier quotes may remain visible | Wait for the retry rather than assuming the visible value is current |
| An unavailable price | No usable value is available for that token | Check the selected asset and retry later |

</div>

The tilde and Stale label do not mean exactly the same thing. A request failure can add a tilde to a recently fetched menu bar quote without making its timestamp old enough for a Stale label.

## What can interrupt an update?

Your Mac may be offline, the service may be unavailable, or the public API may reject a request. CoinGecko documents its API behavior and rate limits in its [official reference](https://docs.coingecko.com/reference/common-errors-rate-limit). A rate-limited request does not mean your saved watchlist has been deleted.

Ticker uses the public endpoints without asking you for an API key. That is convenient for setup, but it means a refresh is subject to the service's availability and public-access constraints. This guide does not promise a fixed request allowance because the provider can change its limits.

## What to check in Ticker

Open the popup and read its status. “Prices unavailable” means a refresh failed. A Stale label identifies an old or invalid quote timestamp. If your watchlist is empty, add a token before expecting prices.

Once your connection is working, use Refresh Prices in the options menu. Ticker also keeps retrying every minute. Repeated manual clicks are unlikely to fix a provider rate limit; allow time for access to recover.

For tokens with no usable price, the app shows an unavailable value rather than manufacturing a number. Very small positive USD prices use additional decimal precision, and values below the formatting threshold are displayed as less than $0.000001. Those formatting choices should not be confused with stale data.

## Choose a tool for the data you need

A compact ticker is useful for an occasional glance. If your workflow requires exchange-specific bid and ask prices, streaming updates or orders, verify those capabilities in a purpose-built tool. Ticker has no exchange connection or trading interface.

Read the [Mac crypto ticker comparison](/guides/mac-crypto-ticker-alternatives/) for differences in app scope, or the [Bitcoin setup guide](/guides/bitcoin-price-mac-menu-bar/) for the controls that determine what Ticker displays.

Correction, October 22, 2026: an earlier version said the stale timestamp threshold was three minutes. The implementation uses more than 600 seconds, or ten minutes. No app behavior changed for this correction.
