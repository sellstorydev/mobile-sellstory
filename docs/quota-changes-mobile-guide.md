# Quota Changes — Mobile Integration Guide

This guide explains how the web app fetches and displays quota usage and how a mobile app can do the same. It is based on the Subscription page at `/settings/subscription`.

## Data source

- Firestore document: `workspaces/{workspaceId}`
- Fields used:
  - `quota`: per-resource usage/limit
  - `subscription`: current package, cycle, addons, overrides
  - `package`: plan metadata (optional UI info)

Example shape (simplified):

```json
{
  "quota": {
    "users": { "used": 3, "limit": 7 },
    "boards": { "used": 12, "limit": -1 },
    "storageGB": { "used": 4, "limit": 60 },
    "chatPages": { "used": 1, "limit": 5 },
    "customers": { "used": 1500, "limit": -1 },
    "products": { "used": 800, "limit": -1 }
  },
  "subscription": {
    "packageId": "business",
    "billingCycle": "monthly",
    "addons": { "users": 2, "storageGB": 10 },
    "overrides": { "boards": -1 }
  }
}
```

Notes:
- `limit: -1` means unlimited.
- Some projects may store `pages` instead of `chatPages`, and `storage` instead of `storageGB` — see normalization below.

## Web implementation (reference)

- Hook: `src/hooks/useWorkspaceUsage.ts`
  - Subscribes to `workspaces/{workspaceId}` and maps `workspace.quota` through `normalizeUsage`.
- Normalizers: `src/lib/normalize.ts`
  - `normalizeUsage(quotaDoc)` handles legacy aliases and shapes.
  - `normalizePlan` provides a canonical view of included plan quotas.
  - `normalizeAddons`, `normalizeAddonsStrict` harmonize addon keys.
- UI: `src/app/(app)/settings/subscription/UsageAddonsPanel.tsx`
  - Shows Usage bars and a list "Quota changes" comparing current vs proposed plan/addons.

## Canonical quota keys

From `src/lib/usage-types.ts`:
- keys: `users`, `boards`, `pages`, `storageGB`, `customers`, `products`
- Mobile should present the same labels and treat `-1` as ∞.

## Mobile: how to fetch usage

Option A — Realtime subscription:
1. Listen to `workspaces/{workspaceId}`.
2. Take `quota` object from snapshot data.
3. Pass to the same normalization logic as web (re-implement or port `normalizeUsage`).

Example (TypeScript-like pseudocode):

```ts
// Pseudo-mobile code
onSnapshot(doc(db, 'workspaces', workspaceId), snap => {
  const ws = snap.data();
  const usage = normalizeUsage(ws?.quota); // ported from web
  // usage shape:
  // { users: {limit, used}, boards: {limit, used}, storageGB: {limit, used}, pages: {limit, used}, customers: {limit, used}, products: {limit, used} }
});
```

Option B — One-time fetch:
- Use a single `get` call to read the document and map `quota` through the same normalizer.

## Normalization rules (port to mobile)

Copy of logic from `normalizeUsage`:
- For each key, try `quota[key]` first; if not present, use alias:
  - `storageGB` may be stored under `storage`.
  - `pages` may be stored under `chatPages`.
- Each key’s `limit` is derived from: `quota[key].limit` or `quota[key].max` or direct number value; default to `-1` (unlimited) if unknown.
- Each key’s `used` is derived from either `quota.used[key]`, `quota[key].used`, or alias equivalents; default `0`.

Resulting normalized shape matches:

```ts
export type UsageMap = Partial<Record<'users'|'boards'|'pages'|'storageGB'|'customers'|'products', { limit: number; used: number }>>
```

## Showing "Quota changes" (diff)

If your mobile UI needs to preview quota changes when a user selects a new plan/addons:
- Get current plan: from `packages` collection (active plan docs), or ship a local plan catalog.
- Normalize using `normalizePlan(doc)` to get included quotas.
- Merge with overrides (from `workspace.subscription.overrides`).
- Add proposed addons (map mobile UI keys to server keys):
  - `extra_users` -> `users`
  - `extra_boards` -> `boards`
  - `storage_gb` -> `storageGB`
  - `pages` -> `chatPages`
- Effective limit per key = (override ?? baseIncluded) + addonQty; treat any negative as unlimited.

## Pricing/Quote API (if needed)

- Endpoint: `POST /api/billing/quote`
- Body:
```json
{
  "workspaceId": "...",
  "selectedPackageId": "business",
  "billingCycle": "monthly",
  "buyerType": "individual",
  "proposedAddons": { "users": 2, "storageGB": 10, "chatPages": 1 }
}
```
- Response (shape example):
```json
{
  "quoteId": "q_...",
  "subtotal": 3200,
  "vat": 224,
  "wht": 0,
  "payToday": 3424,
  "nextBillDate": 1730419200000,
  "nextBillingTotal": 3200
}
```

Note: In the web UI we map client addon keys to server canonical keys before calling the API (see `UsageAddonsPanel` and `SubscriptionClient`).

## Edge cases to consider

- Missing `quota`: show placeholders; treat limits as `-1` (∞) where appropriate.
- Over-limit state: if `used > limit` with finite limit, display warning.
- Plan overrides: unlimited (`-1`) should dominate (do not add addons to ∞).
- Aliases: ensure `storage` and `storageGB`, `pages` and `chatPages` are handled.
- Permissions/auth: protect Firestore reads with the user’s workspace membership and security rules.

## Minimal mobile types (copy)

```ts
export type QuotaKey = 'users'|'boards'|'pages'|'storageGB'|'customers'|'products';
export type UsageMap = Partial<Record<QuotaKey,{limit:number;used:number}>>;
```

## Where to look in web repo

- Hook: `src/hooks/useWorkspaceUsage.ts`
- Normalizers: `src/lib/normalize.ts` (normalizeUsage, normalizePlan, normalizeAddons*)
- Usage panel (diff logic): `src/app/(app)/settings/subscription/UsageAddonsPanel.tsx`
- Plan catalog (example): `src/lib/subscriptions.ts` or Firestore `packages` collection
- Quote request examples: `src/app/(app)/settings/subscription/SubscriptionClient.tsx`

## TL;DR for mobile

- Read `workspaces/{workspaceId}` → `quota`.
- Apply normalization for aliases.
- Present six keys with used/limit; −1 = ∞.
- For “Quota changes” preview, compute Effective = Included + Overrides + Addons (with ∞ dominance) using normalized plan/addon data.
