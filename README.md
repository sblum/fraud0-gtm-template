# fraud0 Tag Template for Google Tag Manager

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Google Tag Manager (web) tag template for [fraud0](https://www.fraud0.com) — invalid traffic and bot detection. One template covers both parts of the fraud0 onsite setup:

- **Page View (fraud0 Main Tag):** loads the fraud0 detection script and immediately fires the first-hit pixel on every page.
- **Conversion Event:** reports conversions from your confirmation pages. fraud0 shows them in aggregate in the dashboard and reports; they help you evaluate campaigns better, independently of bot traffic, and, as a side effect, support false-positive detection.

*Deutsche Version siehe unten / German version below:* [→ Deutsch](#fraud0-tag-vorlage-für-google-tag-manager-deutsch)

---

## Contents

- [How it works](#how-it-works)
- [What fraud0 writes back to the page](#what-fraud0-writes-back-to-the-page)
- [Trigger recipes](#trigger-recipes)
- [When the verdict arrives (timing)](#when-the-verdict-arrives-timing)
- [Installation](#installation)
- [Setup — Page View (Main Tag)](#setup--page-view-main-tag)
- [Setup — Conversion Events](#setup--conversion-events)
- [Setup patterns and consent](#setup-patterns-and-consent)
- [Field reference](#field-reference)
- [Conversion types](#conversion-types)
- [Template permissions](#template-permissions)
- [Content Security Policy](#content-security-policy)
- [Diagnostics](#diagnostics)
- [Preflight checklist](#preflight-checklist)
- [Limitations](#limitations)
- [Troubleshooting](#troubleshooting)
- [Development & tests](#development--tests)
- [Support](#support)
- [License](#license)

## How it works

**Page View (Main Tag).** The tag immediately fires a 1×1 tracking pixel (`https://api.fraud0.com/api/v2/pixel?cid=…&cb=…`) and asynchronously loads the fraud0 detection script (`https://api.fraud0.com/api/v2/fz.js?cid=…`). The pixel fires whether or not the JavaScript ever finishes loading — this is what allows fraud0 to detect bots that abandon the page within the first few hundred milliseconds. The pixel is sent **at most once per page**, even if the tag accidentally fires a second time.

**Conversion Event.** The tag pushes the conversion into the `window.fraud0` queue (equivalent to the documented snippet `fraud0.push(['purchase', 'order123'])`) and additionally ensures the detection script is present. Script loading is deduplicated across all fraud0 template tags that use the same Customer ID, so the script is only loaded once per page even when the Main Tag and several Conversion Event tags fire together. Identical conversions (same type **and** ID) are de-duplicated per page load by default — see [Field reference](#field-reference).

The template only communicates with `api.fraud0.com`. The template itself sets no cookies and uses no `localStorage`; the detection script (fz.js) sets the two fraud0 cookies `f0_uid` (365 days) and `f0_sid` (1 day), both host-only, and mirrors both values in `localStorage` (used as a fallback when a cookie is missing).

## What fraud0 writes back to the page

Once the fraud0 API has scored the visit, the detection script pushes its verdict into `window.dataLayer`:

| Event | When it is pushed | Meaning |
|---|---|---|
| `{event: 'fraud0', f0_bot_traffic: 'yes' \| 'no'}` | on every verdict | `yes` = classified as bot in the latest response, which **can still be an uncertain verdict**; `no` = not classified as bot (a new, still uncertain visit can also start as `no`). Use it for reporting and segmentation only. |
| `{event: 'f0_event_invalid_traffic'}` | additionally, only when the visit is a bot **and** the verdict is certain | The clean, confirmed-bot-only signal. **This is the event to build triggers and exclusion audiences on.** |

Key facts:

- **`uncertain` is not available in the data layer.** fz.js passes an `uncertain` flag to Tealium (see below) but not to `window.dataLayer`. `f0_bot_traffic` only reflects the bot flag of the latest response, so both `yes` and `no` can be provisional, while `f0_event_invalid_traffic` means "bot **and** certain". Only the second is suitable for exclusion.
- **Frequency:** there is **at most one** `fraud0` event per page load, plus **one per URL change** that fz.js detects afterwards: on single-page applications five in-app navigations produce five `fraud0` events, and `#hash` or `history.replaceState` URL changes on classic pages count as well. After a URL change the verdict arrives about 1 s plus one API round trip later. `f0_event_invalid_traffic` is equally repeatable and is **not** de-duplicated.
- **The verdict can change between pushes** in both directions (`no` → `yes` and `yes` → `no`): the first contact of a session is often still uncertain and gets corrected on a later page view or route change.
- **Consequence for GTM:** a Custom Event trigger on these events fires on every push. Leave the attached tags at **Advanced Settings → Tag firing options → Once per event** (the default), never **Once per page**, and build them to tolerate multiple firings. A dedicated GA4 event attached to every `fraud0` push creates an event flood and artefact sessions; see [Trigger recipes](#trigger-recipes).

> **⚠️ Tealium takes precedence.** If `window.utag.link` exists when the verdict arrives (the signature of a Tealium container), fz.js sends the verdict as `utag.link({tealium_event: 'fraud0_scoring_result', is_bot, uncertain})` and **returns — the data layer events above are then never pushed, silently.** Build Tealium triggers on `fraud0_scoring_result` instead. The template warns about this in GTM preview mode (see [Diagnostics](#diagnostics)).

**The target name is hard-wired.** fz.js writes to `window.dataLayer` — the script URL only carries `cid` and `customer_user_id_only`, there is no parameter to rename the output channel. If your GTM container was set up with a **custom data layer name**, the fraud0 events never reach it. Bridge them with a small forwarder (run it as early as possible, e.g. in the page `<head>` or a high-priority Custom HTML tag on All Pages):

```html
<script>
(function () {
  window.dataLayer = window.dataLayer || [];
  var forward = function (entry) {
    if (entry && (entry.event === 'fraud0' ||
                  entry.event === 'f0_event_invalid_traffic')) {
      window.myDataLayer.push(entry); // <- your container's data layer name
    }
  };
  var originalPush = window.dataLayer.push;
  window.dataLayer.push = function () {
    for (var i = 0; i < arguments.length; i++) { forward(arguments[i]); }
    return originalPush.apply(window.dataLayer, arguments);
  };
  for (var j = 0; j < window.dataLayer.length; j++) { forward(window.dataLayer[j]); }
})();
</script>
```

## Trigger recipes

**1. Exclusion trigger (recommended default).**

- Trigger type: **Custom Event**, event name `f0_event_invalid_traffic`
- Fires on: **All Custom Events** — no condition, no variable needed
- Use it for negative audiences and to block downstream tags. Remember it re-fires on every page a confirmed bot visits — attached logic must be repeat-safe.

**2. GA4 classification (reporting).**

- Create a Data Layer Variable on `f0_bot_traffic`.
- Add it as a **user property** in the configuration settings of your Google tag (and, if needed, as an event parameter in the event settings).
- Do **not** attach a dedicated GA4 event to the `fraud0` push: it fires once per page and route change for **all** traffic, which floods GA4 with events and opens artefact sessions. A value in configuration/event settings adds **zero** extra hits.
- Note the [timing](#when-the-verdict-arrives-timing): on the initial `page_view` the value is frequently not there yet.

**3. Pixel Protect / conditional firing.**

- To fire marketing or personalisation tags **only for visitors classified as human**, trigger them on the `fraud0` event with the condition `f0_bot_traffic equals no` instead of on Page View.
- Trade-off: those tags then start 0.2–0.9 s later (after the verdict), and on the first page of a session the classification can still be uncertain in either direction. See [timing](#when-the-verdict-arrives-timing) and the [Pixel Protect guide](https://help.fraud0.com/1-onsite/d-pixel-protect/pixelprotect01/).

## When the verdict arrives (timing)

The verdict typically arrives **0.2–0.9 seconds after page start** (fz.js load plus one or two API round trips). fz.js does **not** persist the verdict anywhere — there is no status cookie and no result callback; only `f0_uid`/`f0_sid` are stored (cookies plus a `localStorage` mirror). Every page load fetches the verdict over the network again.

That makes the value unreliable on early events: the Google tag frequently fires before the fraud0 verdict has arrived, so a `page_view` event parameter read from the `fraud0` push is often empty. The value is dependable on **late events** (`purchase`, `login`, `sign_up`) and as a **user property** (where the last value of the session wins).

**Optional customer recipe — persist the verdict in a first-party status cookie.** This pattern is deliberately *not* part of the template (it writes a cookie, which the template itself never does — assess this additional cookie with your data protection officer). Run it as a Custom HTML tag on the Custom Event trigger `fraud0` (All Custom Events):

```html
<script>
(function () {
  var v = {{DLV F0}}; // Data Layer Variable reading f0_bot_traffic
  if (v !== 'yes' && v !== 'no') return;
  var prev = (document.cookie.match(/(?:^|;\s*)f0_status=([^;]*)/) || [])[1];
  document.cookie = 'f0_status=' + v + ';path=/;max-age=2592000;SameSite=Lax';
  if (prev !== v) {
    window.dataLayer.push({
      event: 'f0_status_changed',
      f0_status: v,
      f0_status_prev: prev || 'none'
    });
  }
})();
</script>
```

Then read the status through a GTM variable of type **1st-Party Cookie** (`f0_status`) with default value `pending`. The cookie is available synchronously before any tag fires, so every page load after the very first one is race-free, and `f0_status_changed` fires **only on an actual change** — at most one event per status flip instead of one per push.

## Installation

**From the Community Template Gallery (recommended):**

1. In your GTM web container, go to **Templates → Tag Templates → Search Gallery**.
2. Search for **fraud0**, then click **Add to workspace** and confirm the permissions.

**Manual import:**

1. Download `template.tpl` from this repository.
2. In GTM, go to **Templates → Tag Templates → New**, open the ⋮ menu → **Import**, select the file and save.

## Setup — Page View (Main Tag)

Add the Main Tag exactly once and fire it on **every** page:

1. **Tags → New → Tag Configuration** → choose **fraud0 Bot Detection Tag**.
2. Enter your **fraud0 Customer ID (cid)**. In the [fraud0 Dashboard](https://admin.fraud0.com/), select the tag you are implementing and open **Integrations → Tag Management** (the `cid` value in the tag snippet, a UUID; each fraud0 tag has its own cid).
3. Keep the default Tag type **Page View (fraud0 Main Tag)**.
4. Open **Advanced Settings** and set **Tag firing priority** to **1000**, so fraud0 fires before all other tags.
5. Under **Advanced Settings → Consent Settings**, choose **No additional consent required** (see [Setup patterns and consent](#setup-patterns-and-consent)).
6. Set **Triggering** to **All Pages** (or an equivalent trigger that fires unconditionally on every page view). Do **not** add a History Change trigger — fz.js tracks SPA route changes itself.
7. Save and publish.

> **Important:** fraud0 must fire **technically and legally independent of consent decisions** — bots do not click consent banners. Whether the Main Tag belongs in GTM at all depends on how your GTM container is loaded: see [Setup patterns and consent](#setup-patterns-and-consent).

## Setup — Conversion Events

Conversions are shown in the fraud0 dashboard and reports in aggregate — they are not broken down further (e.g. by type or ID). They help you evaluate your campaigns better, independently of bot traffic; as a side effect, they support fraud0's false-positive detection.

Add one tag per conversion type, fired **only on confirmation pages** (post-checkout, post-form-submit, post-signup):

1. **Tags → New → Tag Configuration** → choose **fraud0 Bot Detection Tag**.
2. Enter the same **fraud0 Customer ID (cid)**.
3. Set Tag type to **Conversion Event**.
4. Pick a **Conversion type** (see table below) and optionally a **Conversion ID**, typically a GTM variable such as `{{Transaction ID}}` or a lead reference — no personal data.
5. Keep **Send this conversion only once per page** enabled unless the same conversion should intentionally be reported several times on one page.
6. Open **Advanced Settings** and set **Tag firing priority** to **800**.
7. Set **Triggering** to your confirmation-page trigger (URL-based or a custom event such as `purchase` from your e-commerce data layer).
8. Save and publish.

If a single confirmation page represents more than one conversion (e.g. purchase + newsletter signup), create one tag per conversion and fire both on that page — de-duplication is per type and ID, so both go through.

## Setup patterns and consent

fraud0 must fire **technically and legally independent of consent decisions**. If the detection only runs for visitors who accept consent, fraud0 sees almost exclusively consenting (i.e. overwhelmingly human) traffic — and the bots it exists to catch stay invisible. fraud0 provides notes on the [legal basis](https://help.fraud0.com/3-general-faq/data-processing-privacy-practices/legal-compliance/legal01/) and a [DPA](https://www.fraud0.com/dpa/); clarify the classification with your data protection officer.

Which embed variant is correct depends on **how your GTM container itself is loaded**:

- **Pattern 1 — GTM loads independently of consent** (container snippet in the `<head>`, tags gated individually via consent settings): the Main Tag can live **in GTM**, trigger All Pages, consent setting "No additional consent required". For this case, the template replaces the Custom HTML tag.
- **Pattern 2 — GTM itself only loads after opt-in** (e.g. the CMP or a loader injects the container script upon consent): the Main Tag must **not** live in GTM — it would inherit the consent gate. Embed fraud0 directly in the `<body>` (or in a loader that runs before the gate) and use this template only for Conversion Events, if at all. On confirmation pages the Conversion Event tag then loads fz.js a second time; this is expected and harmless (fz.js initialises only once).

**Coverage:** fraud0 recommends the direct `<body>` embed for maximum coverage (see the [implementation guide](https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted01/)). Via GTM, the Main Tag only runs once the GTM container has loaded — visitors and bots that block `googletagmanager.com` are not seen.

> **Common anti-pattern:** the Main Tag sits in GTM **and** additionally carries a blocking rule or a consent exception tied to a consent category. The tag is classified as "essential" on paper but in effect fires only after opt-in. **Check:** open the fraud0 tag in GTM, inspect its firing exceptions and **Advanced Settings → Consent Settings**, remove consent-category requirements and set **No additional consent required**.

The template deliberately contains **no consent-mode APIs** (`isConsentGranted`, `addConsentListener`): a consent check inside the template would contradict the requirement above.

## Field reference

| Field | Shown when | Required | Description |
|---|---|---|---|
| fraud0 Customer ID (cid) | always | yes | Your fraud0 Customer ID (UUID) from the dashboard. Accepts a GTM variable. |
| Tag type | always | yes | **Page View (fraud0 Main Tag)** — default — or **Conversion Event**. |
| Conversion type | Tag type = Conversion Event | yes | `Purchase` (default), `Lead`, `Signup`, `Custom conversion type` or `Basic conversion (sent as 'generic')`. |
| Custom conversion type | Conversion type = Custom conversion type | yes | Identifier such as `trial_started`, `whitepaper_download`, `quote_requested`. Letters, digits, `_`, `-`. The values `1` and `generic` are reserved. |
| Conversion ID (optional) | Tag type = Conversion Event | no | Identifier for this conversion instance, ideally unique (order ID, lead or registration reference). Technical references only — no personal data such as e-mail addresses, names or user IDs. Ignored for Basic. |
| Send this conversion only once per page | Tag type = Conversion Event | — (default: on) | De-duplicates identical conversions (same type **and** ID) within one page load, e.g. when a form-submission trigger and a custom confirmation event both fire for one AJAX form. Different IDs always go through. On single-page applications one page load spans all virtual pages — use a unique Conversion ID there. |

## Conversion types

| Type | Queued as | Typical Conversion ID |
|---|---|---|
| Purchase | `fraud0.push(['purchase', id])` | order ID, e.g. `{{Transaction ID}}` |
| Lead | `fraud0.push(['lead', id])` | lead reference, e.g. a form submission ID |
| Signup | `fraud0.push(['signup', id])` | registration reference (no personal data) |
| Custom | `fraud0.push(['<your_type>', id])` | anything that identifies the instance |
| Basic conversion | `fraud0.push([1])` (sent as `generic`) | — (not used) |

Without a Conversion ID, only the type is pushed, e.g. `fraud0.push(['lead'])`.

The conversion interface transmits **only the type and the optional ID — there is no revenue or currency field.** fraud0 shows conversions in aggregate in the dashboard and reports; they are not broken down further by type or ID.

**Prefer a descriptive type over Basic.** Basic (`[1]`) is sent as the type `generic` and handled by an older code path in fz.js with timing-dependent side effects (possible double counting; it can also interfere with a conversion queued directly after it). Do not combine Basic and typed conversion tags on the same page. Basic remains selectable for compatibility with existing setups.

## Template permissions

The template requests the minimum permissions needed:

| Permission | Scope | Why |
|---|---|---|
| Injects scripts | `https://api.fraud0.com/api/v2/*` | Loads the fraud0 detection script `fz.js`. |
| Sends pixels | `https://api.fraud0.com/api/v2/*` | Fires the first-hit 1×1 pixel of the Main Tag. |
| Accesses global variables | `fraud0` (read/write) | Creates/uses the `window.fraud0` queue for conversion events. |
| Accesses global variables | `utag`, `dataLayer`, `F0Loaded` (read-only) | Preview-mode diagnostics D1–D4 and D6 (Tealium, non-array data layer/queue, duplicate installation, Main Tag not yet run). Never written, never executed, never read in production. |
| Logs to console | debug environments only | The `[fraud0]` diagnostics in preview mode. The permission itself is restricted to debug, so production stays silent. |
| Reads container data | — | Detects preview/debug mode (`getContainerVersion().debugMode/previewMode`) to gate all diagnostics. |
| Accesses template storage | — | Per-page markers for the pixel/conversion de-duplication and once-per-page diagnostics. Page-scoped, no window globals. |

## Content Security Policy

If your site uses a strict Content Security Policy, allow-list the fraud0 host(s) in `script-src`, `img-src` and `connect-src`. A network status of `blocked: CSP` indicates a missing entry. The [fraud0 CSP FAQ](https://help.fraud0.com/1-onsite/g-onsite-faq/technical-queries/implementation06/) contains the complete recommended baseline policy (including further directives such as `frame-src 'self'`) — use it as the reference.

| Host | Directives | When needed |
|---|---|---|
| `api.fraud0.com` | `script-src`, `img-src`, `connect-src` | Always — this is the only host the template talks to, sufficient for new setups. |
| `bt.fraud0.com` | `script-src`, `img-src`, `connect-src` | Only if your site still runs the **legacy embed** with this host (existing customers). The template never uses it. |

## Diagnostics

In **GTM preview/debug mode** the template checks the page for the known integration pitfalls and logs `[fraud0]`-prefixed messages to the browser console. **In production (outside preview) nothing is logged and none of these window reads happen** — the logging permission itself is additionally restricted to debug environments.

| # | Condition | Message (abridged) |
|---|---|---|
| D1 | `window.utag.link` exists (Tealium) | Verdict goes to `utag.link` as `fraud0_scoring_result`; the data layer events will **not** fire on this page. |
| D2 | `window.dataLayer` exists but is not an array | Critical: fz.js aborts its initialisation; no verdict is written back and conversions are not reported. |
| D3 | `window.fraud0` exists but is not an array | Critical: the conversion queue cannot attach; conversions are lost. |
| D4 | Page View fires for the first time but `window.F0Loaded` is already `true` | Unless a fraud0 Conversion Event tag already fired on the page: duplicate installation (body embed, legacy `bt.fraud0.com` snippet, consent-tool integration or second tag) — keep exactly one source. |
| D5 | Page View fires a second time on the same page | Duplicate firing; the first-hit pixel is suppressed (sent at most once per page). Check the trigger — All Pages is enough, History Change is wrong. |
| D6 | Conversion fires before the Main Tag has run | Note (no warning): the conversion is held in the `window.fraud0` queue and sent once fz.js loads. |
| D7 | Conversion type is `basic` | Sent as `generic` via an older code path (possible double counting) — prefer a descriptive type. |
| D8 | The resolved Customer ID is not a plausible UUID (length, hyphens, hex digits, version/variant) | With an invalid `cid`, fz.js cannot attribute events to your account — check the GTM variable. The tag still fires (log only). |

## Preflight checklist

Work through this list once per site — it takes about 10 minutes in the browser DevTools plus GTM preview mode:

1. The Page View tag fires on **all** pages, tag firing priority **1000**.
2. Network: `fz.js?cid=…` returns status **200** (or 304 / from cache), `pixel?cid=…&cb=…` returns **200** (or 204).
3. Network: after fz.js has loaded, POST requests to `api.fraud0.com/api/v2/event` return 2xx (on the first page view of a new session typically two; later page views may legitimately show only one).
4. At most **one** `fraud0` event per page load in the data layer (one more per SPA route change is expected).
5. Cookies `f0_uid` and `f0_sid` are set (host-only, 365 days / 1 day; also mirrored in `localStorage` — to reset them, clear the site data, not only the cookies).
6. **No second** fraud0 script in the DOM (no body embed, legacy `bt.fraud0.com` snippet or consent-tool integration in parallel) — except on confirmation pages in [Pattern 2](#setup-patterns-and-consent).
7. No `window.utag` on the page — otherwise the verdict goes to Tealium, not to the data layer.
8. `window.dataLayer` is an **array**.
9. The GTM container's data layer name is the default `dataLayer` (otherwise install the [bridge](#what-fraud0-writes-back-to-the-page)).
10. The Conversion tag fires **exactly once** per conversion, followed by an additional POST to `/api/v2/event`.

Paste this snippet into the browser console for an instant status report:

```js
(function () {
  var dl = Array.isArray(window.dataLayer) ? window.dataLayer : [], out = {};
  out.dataLayerIsArray   = Array.isArray(window.dataLayer);
  out.tealiumPresent     = !!(window.utag && window.utag.link);
  out.fzInitialised      = window.F0Loaded === true;
  out.conversionQueueOk  = Array.isArray(window.fraud0);
  out.fraud0Events       = dl.filter(function (e) { return e && e.event === 'fraud0'; });
  out.invalidTrafficHits = dl.filter(function (e) { return e && e.event === 'f0_event_invalid_traffic'; }).length;
  out.lastVerdict        = out.fraud0Events.length
    ? out.fraud0Events[out.fraud0Events.length - 1].f0_bot_traffic
    : '(no verdict yet)';
  out.f0Cookies = document.cookie.split('; ').filter(function (c) { return c.indexOf('f0_') === 0; });
  out.fraud0Scripts = Array.prototype.slice
    .call(document.querySelectorAll('script[src*="fraud0"]'))
    .map(function (s) { return s.src; });
  console.log(out);
  return out;
})();
```

How to read the output: more than one entry in `fraud0Scripts` = duplicate installation (except on confirmation pages in Pattern 2). `tealiumPresent: true` = the data layer events do not fire on this page. `lastVerdict: '(no verdict yet)'` briefly after load is normal — permanently is not. On a SPA, `fraud0Events` grows with every route change — that is expected behaviour, not an error.

## Limitations

Deliberate boundaries of this template, each with the reason:

- **Web containers only.** A setup via server-side GTM (sGTM) is not supported: fz.js always sends its data directly to `api.fraud0.com`, and no alternative endpoint is currently available.
- **Tealium sites receive no data layer events** — fz.js delivers the verdict via `utag.link` and stops (see [What fraud0 writes back](#what-fraud0-writes-back-to-the-page)). This is fz.js behaviour, not template behaviour.
- **Containers with a custom data layer name** need the bridge snippet from [What fraud0 writes back](#what-fraud0-writes-back-to-the-page) — the target name `window.dataLayer` is hard-wired in fz.js.
- **Shopify Web Pixels (Customer Events) are not suitable for fraud0.** If GTM — and with it this template — runs inside a Shopify Web Pixel, the sandbox by default only starts after consent, sees no real user interaction and keeps the verdict away from the storefront's `dataLayer`. Embed the fraud0 Main Tag directly in the theme (`theme.liquid`, right after `<body>`) instead.<!-- TODO: add the link to the fraud0 Shopify documentation once it is live. -->
- **No revenue/currency field.** The fraud0 conversion interface accepts only a type and an optional ID; the template cannot add fields that the data model does not have.
- **`setCustomerUserId` is not covered by the template.** `window.fraud0.setCustomerUserId(…)` is a *function* that only exists after fz.js has initialised — it is **not** replayable through the queue, so a template tag would silently fail depending on load order. Use a Custom HTML tag with the ready callback instead (and pass a pseudonymous ID, not an e-mail address):

  ```html
  <script>
  (function () {
    function setId() { window.fraud0.setCustomerUserId('YOUR-USER-ID'); }
    if (typeof window.onFraud0Ready === 'function') { window.onFraud0Ready(setId); }
    else { (window.fraud0ReadyCallbacks = window.fraud0ReadyCallbacks || []).push(setId); }
  })();
  </script>
  ```

- **`customer_user_id_only` cannot be set.** The template always loads `fz.js?cid=…`. If you need fraud0's mode without the `f0_uid` visitor cookie (`&customer_user_id_only=true`), use the direct embed instead.
- **The legacy host `bt.fraud0.com` is not served by the template.** Existing customers whose embed still loads from `bt.fraud0.com` — or who use the fraud0 integration of their consent tool — should **not** run this template's Page View tag in parallel: fz.js initialises only once (`window.F0Loaded`), so the second copy is a wasted download and almost certainly a configuration error (the template warns in preview mode, D4).
- **No "verdict relay" tag type** (writing a status cookie, pushing `f0_status_changed`): the template itself writes no cookies. The pattern is documented as an optional Custom HTML recipe under [timing](#when-the-verdict-arrives-timing).
- **No consent-mode APIs** in the template — fraud0 must run independent of consent; a consent check inside the tag would be semantically wrong (see [Setup patterns and consent](#setup-patterns-and-consent)).
- **No additional variable template** (e.g. for reading the verdict): it would need its own repository (the Community Template Gallery allows one template per repository); a Data Layer Variable on `f0_bot_traffic` covers this today.
- Tag firing priority cannot be preset by templates; set it manually as described above (1000 / 800).

## Troubleshooting

Start with the [Preflight checklist](#preflight-checklist) — it covers the frequent cases systematically. In addition:

- **Tag fires but nothing shows in fraud0:** verify the Customer ID (UUID), then check the network panel for requests to `api.fraud0.com` (`pixel` and `fz.js`). In preview mode, watch for `[fraud0]` diagnostics in the console.
- **Requests blocked:** check [CSP allow-listing](#content-security-policy) and ad-blocker behaviour; see the [fraud0 CSP FAQ](https://help.fraud0.com/1-onsite/g-onsite-faq/technical-queries/implementation06/). The [Verify & Connect guide](https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted03/) covers the general verification steps.
- **Conversions missing:** make sure the Main Tag also fires on the confirmation page (All Pages trigger) and that the conversion tag fires after it (priority 800 < 1000). If the conversion tag fires first, nothing is lost — the queue holds it until fz.js loads (diagnostic D6).
- **fraud0 only sees consenting visitors:** the Main Tag (or the GTM container itself) is consent-gated — see [Setup patterns and consent](#setup-patterns-and-consent).

## Development & tests

The template ships with unit tests (26 scenarios) covering the pixel, script injection, all conversion variants, both de-duplication guards, the preview-mode diagnostics and failure paths. To run them: import `template.tpl` into the GTM Template Editor (**Templates → New → Import**), open the **Tests** tab and click **▶ Run Tests**.

Contributions: please open an issue or pull request in this repository. For a new gallery version, commit the change, then add the commit SHA with change notes to the top of `versions` in `metadata.yaml`.

## Support

- fraud0 Knowledge Center: https://help.fraud0.com
- Implementation guide: https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted01/
- Conversion Tag guide: https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted02/
- Data layer events: https://help.fraud0.com/1-onsite/c-data-layer-events/datalayer01/
- Support: support@fraud0.com
- Bugs in this template: please use the GitHub Issues of this repository.

## License

[Apache 2.0](LICENSE) — Copyright 2026 fraud0 GmbH

---

# fraud0 Tag-Vorlage für Google Tag Manager (Deutsch)

Google-Tag-Manager-Vorlage (Web) für [fraud0](https://www.fraud0.com) — Erkennung von Invalid Traffic und Bots. Eine Vorlage deckt beide Teile des fraud0-Onsite-Setups ab:

- **Page View (fraud0 Main Tag):** lädt das fraud0-Erkennungsscript und feuert sofort den First-Hit-Pixel auf jeder Seite.
- **Conversion Event:** meldet Conversions von Bestätigungsseiten. fraud0 stellt sie im Dashboard und in den Reportings gesamthaft dar; sie helfen, Kampagnen auch unabhängig vom Bot-Traffic besser zu bewerten, und unterstützen als Nebeneffekt die Erkennung von False Positives.

## Inhalt

- [Funktionsweise](#funktionsweise)
- [Was fraud0 auf die Seite zurückschreibt](#was-fraud0-auf-die-seite-zurückschreibt)
- [Trigger-Rezepte](#trigger-rezepte)
- [Wann das Urteil eintrifft (Timing)](#wann-das-urteil-eintrifft-timing)
- [Installation](#installation-1)
- [Einrichtung — Page View (Main Tag)](#einrichtung--page-view-main-tag)
- [Einrichtung — Conversion Events](#einrichtung--conversion-events)
- [Setup-Muster und Consent](#setup-muster-und-consent)
- [Felder](#felder)
- [Conversion-Typen](#conversion-typen)
- [Berechtigungen der Vorlage](#berechtigungen-der-vorlage)
- [Content Security Policy](#content-security-policy-1)
- [Diagnose](#diagnose)
- [Preflight-Checkliste](#preflight-checkliste)
- [Einschränkungen](#einschränkungen)
- [Fehlerbehebung](#fehlerbehebung)
- [Entwicklung & Tests](#entwicklung--tests)
- [Support](#support-1)
- [Lizenz](#lizenz)

## Funktionsweise

**Page View (Main Tag).** Der Tag feuert sofort einen 1×1-Pixel (`https://api.fraud0.com/api/v2/pixel?cid=…&cb=…`) und lädt asynchron das Erkennungsscript (`https://api.fraud0.com/api/v2/fz.js?cid=…`). Der Pixel feuert unabhängig davon, ob das JavaScript jemals fertig lädt — so erkennt fraud0 auch Bots, die die Seite in den ersten paar hundert Millisekunden wieder verlassen. Der Pixel wird **höchstens einmal pro Seitenaufruf** gesendet, auch wenn der Tag versehentlich ein zweites Mal feuert.

**Conversion Event.** Der Tag pusht die Conversion in die `window.fraud0`-Queue (äquivalent zum dokumentierten Snippet `fraud0.push(['purchase', 'order123'])`) und stellt zusätzlich sicher, dass das Erkennungsscript vorhanden ist. Das Laden ist über alle fraud0-Vorlagen-Tags mit derselben Customer ID dedupliziert — das Script wird also auch dann nur einmal geladen, wenn Main Tag und mehrere Conversion-Tags auf derselben Seite feuern. Identische Conversions (gleicher Typ **und** gleiche ID) werden standardmäßig pro Seitenladevorgang dedupliziert — siehe [Felder](#felder).

Die Vorlage kommuniziert ausschließlich mit `api.fraud0.com`. Die Vorlage selbst setzt keine Cookies und nutzt keinen `localStorage`; das Erkennungsscript (fz.js) setzt die beiden fraud0-Cookies `f0_uid` (365 Tage) und `f0_sid` (1 Tag), beide host-only, und spiegelt beide Werte in den `localStorage` (als Fallback, wenn ein Cookie fehlt).

## Was fraud0 auf die Seite zurückschreibt

Sobald die fraud0-API den Besuch bewertet hat, pusht das Erkennungsscript sein Urteil in `window.dataLayer`:

| Event | Wann gepusht | Bedeutung |
|---|---|---|
| `{event: 'fraud0', f0_bot_traffic: 'yes' \| 'no'}` | bei jedem Urteil | `yes` = in der letzten Antwort als Bot eingestuft, **was noch ein unsicheres Urteil sein kann**; `no` = nicht als Bot eingestuft (ein neuer, noch unsicherer Besuch kann auch mit `no` starten). Nur für Reporting und Segmentierung verwenden. |
| `{event: 'f0_event_invalid_traffic'}` | zusätzlich, nur wenn der Besuch ein Bot ist **und** das Urteil sicher ist | Das saubere Nur-bestätigte-Bots-Signal. **Auf dieses Event gehören Trigger und Ausschluss-Zielgruppen.** |

Die wichtigsten Fakten:

- **`uncertain` steht im Data Layer nicht zur Verfügung.** fz.js übergibt ein `uncertain`-Flag an Tealium (siehe unten), aber nicht an `window.dataLayer`. `f0_bot_traffic` spiegelt nur das Bot-Flag der letzten Antwort — `yes` wie `no` können vorläufig sein —, während `f0_event_invalid_traffic` „Bot **und** sicher“ bedeutet. Nur das zweite taugt für Ausschlüsse.
- **Häufigkeit:** Pro Seitenladevorgang gibt es **höchstens ein** `fraud0`-Event, dazu **eines pro URL-Wechsel**, den fz.js danach erkennt: In Single-Page-Applications ergeben fünf In-App-Navigationen fünf `fraud0`-Events, auf klassischen Seiten zählen auch `#hash`- oder `history.replaceState`-Änderungen der URL. Nach einem URL-Wechsel trifft das Urteil etwa 1 s plus einen API-Roundtrip später ein. `f0_event_invalid_traffic` ist ebenso wiederholbar und wird **nicht** dedupliziert.
- **Das Urteil kann zwischen den Pushes kippen**, in beide Richtungen (`no` → `yes` und `yes` → `no`): Der erste Kontakt einer Session ist oft noch unsicher und wird auf einem späteren Seitenaufruf oder Routenwechsel korrigiert.
- **Konsequenz für GTM:** Ein Trigger vom Typ „Benutzerdefiniertes Ereignis“ auf diese Events feuert bei jedem Push. Die daran hängenden Tags unter **Erweiterte Einstellungen → Optionen für die Tag-Auslösung** auf **Einmal pro Ereignis** (Standard) lassen, nie **Einmal pro Seite**, und so bauen, dass sie mehrfaches Feuern vertragen. Ein dediziertes GA4-Event an jedem `fraud0`-Push erzeugt eine Event-Flut und Artefakt-Sessions; siehe [Trigger-Rezepte](#trigger-rezepte).

> **⚠️ Tealium hat Vorrang.** Existiert beim Eintreffen des Urteils `window.utag.link` (die Signatur eines Tealium-Containers), sendet fz.js das Urteil als `utag.link({tealium_event: 'fraud0_scoring_result', is_bot, uncertain})` und endet — **die Data-Layer-Events oben werden dann nie gepusht, lautlos.** Tealium-Trigger stattdessen auf `fraud0_scoring_result` aufbauen. Die Vorlage warnt davor im GTM-Vorschaumodus (siehe [Diagnose](#diagnose)).

**Der Zielname ist fest verdrahtet.** fz.js schreibt in `window.dataLayer` — aus der Script-URL werden nur `cid` und `customer_user_id_only` gelesen, einen Parameter zum Umbenennen des Ausgabekanals gibt es nicht. Wurde der GTM-Container mit einem **eigenen Data-Layer-Namen** eingerichtet, kommen die fraud0-Events dort nie an. Eine kleine Brücke leitet sie weiter (so früh wie möglich ausführen, z. B. im `<head>` der Seite oder als Custom-HTML-Tag mit hoher Priorität auf All Pages):

```html
<script>
(function () {
  window.dataLayer = window.dataLayer || [];
  var forward = function (entry) {
    if (entry && (entry.event === 'fraud0' ||
                  entry.event === 'f0_event_invalid_traffic')) {
      window.myDataLayer.push(entry); // <- Data-Layer-Name eures Containers
    }
  };
  var originalPush = window.dataLayer.push;
  window.dataLayer.push = function () {
    for (var i = 0; i < arguments.length; i++) { forward(arguments[i]); }
    return originalPush.apply(window.dataLayer, arguments);
  };
  for (var j = 0; j < window.dataLayer.length; j++) { forward(window.dataLayer[j]); }
})();
</script>
```

## Trigger-Rezepte

**1. Ausschluss-Trigger (empfohlener Standard).**

- Trigger-Typ: **Benutzerdefiniertes Ereignis**, Ereignisname `f0_event_invalid_traffic`
- Feuert auf: **Alle benutzerdefinierten Ereignisse** — keine Bedingung, keine Variable nötig
- Für negative Zielgruppen und zum Blockieren nachgelagerter Tags. Das Event wiederholt sich auf jeder Seite, die ein bestätigter Bot besucht — angehängte Logik muss wiederholungsfest sein.

**2. GA4-Klassifikation (Reporting).**

- Eine Data-Layer-Variable auf `f0_bot_traffic` anlegen.
- Als **User Property** in die Konfigurationseinstellungen des Google Tags aufnehmen (bei Bedarf zusätzlich als Event-Parameter in die Ereigniseinstellungen).
- **Kein** dediziertes GA4-Event an den `fraud0`-Push hängen: er feuert für **allen** Traffic einmal pro Seite und Routenwechsel — das flutet GA4 mit Events und öffnet Artefakt-Sessions. Ein Wert in Konfigurations-/Ereigniseinstellungen erzeugt dagegen **null** zusätzliche Hits.
- [Timing](#wann-das-urteil-eintrifft-timing) beachten: auf dem ersten `page_view` ist der Wert häufig noch nicht da.

**3. Pixel Protect / bedingtes Feuern.**

- Marketing- oder Personalisierungs-Tags **nur für als Mensch eingestufte Besucher** auslösen: Trigger auf das Event `fraud0` mit Bedingung `f0_bot_traffic equals no` statt auf Page View.
- Trade-off: Diese Tags starten dann 0,2–0,9 s später (nach dem Urteil), und auf der ersten Seite einer Session kann die Einstufung noch in beide Richtungen unsicher sein. Siehe [Timing](#wann-das-urteil-eintrifft-timing) und den [Pixel-Protect-Guide](https://help.fraud0.com/1-onsite/d-pixel-protect/pixelprotect01/).

## Wann das Urteil eintrifft (Timing)

Das Urteil liegt typischerweise **0,2–0,9 Sekunden nach Seitenstart** vor (fz.js-Load plus ein bis zwei API-Roundtrips). fz.js persistiert das Urteil **nirgends** — es gibt kein Status-Cookie und keinen Ergebnis-Callback; gespeichert werden nur `f0_uid`/`f0_sid` (Cookies plus Spiegelung im `localStorage`). Jeder Seitenaufruf holt das Urteil neu über das Netz.

Auf frühen Events ist der Wert deshalb unzuverlässig: Der Google Tag feuert häufig, bevor das fraud0-Urteil eingetroffen ist — ein aus dem `fraud0`-Push gelesener `page_view`-Parameter ist dann oft leer. Belastbar ist der Wert auf **späten Events** (`purchase`, `login`, `sign_up`) und als **User Property** (dort gewinnt der letzte Wert der Session).

**Optionales Kundenrezept — das Urteil in einem First-Party-Status-Cookie persistieren.** Dieses Muster ist bewusst *nicht* Teil der Vorlage (es schreibt ein Cookie, was die Vorlage selbst nie tut — dieses zusätzliche Cookie mit dem Datenschutzbeauftragten abstimmen). Als Custom-HTML-Tag auf dem Custom-Event-Trigger `fraud0` (Alle benutzerdefinierten Ereignisse) ausführen:

```html
<script>
(function () {
  var v = {{DLV F0}}; // Data-Layer-Variable, die f0_bot_traffic liest
  if (v !== 'yes' && v !== 'no') return;
  var prev = (document.cookie.match(/(?:^|;\s*)f0_status=([^;]*)/) || [])[1];
  document.cookie = 'f0_status=' + v + ';path=/;max-age=2592000;SameSite=Lax';
  if (prev !== v) {
    window.dataLayer.push({
      event: 'f0_status_changed',
      f0_status: v,
      f0_status_prev: prev || 'none'
    });
  }
})();
</script>
```

Den Status anschließend über eine GTM-Variable vom Typ **First-Party-Cookie** (`f0_status`) mit Standardwert `pending` lesen. Das Cookie liegt synchron vor, bevor irgendein Tag feuert — jeder Seitenaufruf nach dem allerersten ist damit race-frei, und `f0_status_changed` feuert **nur bei tatsächlicher Änderung**: höchstens ein Event pro Statuswechsel statt eines pro Push.

## Installation

**Aus der Community Template Gallery (empfohlen):** In eurem GTM-Web-Container unter **Vorlagen → Tag-Vorlagen → Galerie durchsuchen** nach **fraud0** suchen, **Zum Arbeitsbereich hinzufügen** klicken und die Berechtigungen bestätigen.

**Manueller Import:** `template.tpl` aus diesem Repository herunterladen, in GTM unter **Vorlagen → Tag-Vorlagen → Neu** über das ⋮-Menü → **Importieren** einlesen und speichern.

## Einrichtung — Page View (Main Tag)

Den Main Tag genau einmal anlegen und auf **jeder** Seite feuern:

1. **Tags → Neu → Tag-Konfiguration** → **fraud0 Bot Detection Tag** wählen.
2. **fraud0 Customer ID (cid)** eintragen — im [fraud0 Dashboard](https://admin.fraud0.com/) den gewünschten Tag auswählen und **Integrations → Tag Management** öffnen (der `cid`-Wert im Tag-Snippet, eine UUID; jeder fraud0-Tag hat seine eigene cid).
3. Tag type auf dem Standard **Page View (fraud0 Main Tag)** belassen.
4. Unter **Erweiterte Einstellungen** die **Priorität der Tag-Auslösung** auf **1000** setzen, damit fraud0 vor allen anderen Tags feuert.
5. Unter **Erweiterte Einstellungen → Einstellungen für die Einwilligung** die Option **Keine zusätzliche Einwilligung erforderlich** wählen (siehe [Setup-Muster und Consent](#setup-muster-und-consent)).
6. **Trigger: All Pages** (bzw. ein Trigger, der bedingungslos auf jedem Seitenaufruf feuert). **Keinen** History-Change-Trigger ergänzen — fz.js erkennt SPA-Routenwechsel selbst.
7. Speichern und veröffentlichen.

> **Wichtig:** fraud0 muss **technisch und rechtlich unabhängig von Einwilligungen auslösen** — Bots klicken keine Consent-Banner. Ob der Main Tag überhaupt in GTM gehört, hängt davon ab, wie der GTM-Container geladen wird: siehe [Setup-Muster und Consent](#setup-muster-und-consent).

## Einrichtung — Conversion Events

Conversions werden im fraud0-Dashboard und in den Reportings gesamthaft dargestellt — eine weitere Aufschlüsselung (z. B. nach Typ oder ID) gibt es nicht. Sie helfen, Kampagnen auch unabhängig vom Bot-Traffic besser zu bewerten; als Nebeneffekt unterstützen sie die Erkennung von False Positives.

Pro Conversion-Typ einen Tag anlegen, der **nur auf Bestätigungsseiten** feuert (nach Checkout, Formular-Absenden, Registrierung):

1. **Tags → Neu → Tag-Konfiguration** → **fraud0 Bot Detection Tag** wählen.
2. Dieselbe **fraud0 Customer ID (cid)** eintragen.
3. Tag type auf **Conversion Event** stellen.
4. **Conversion type** wählen (Tabelle unten) und optional eine **Conversion ID** angeben — typischerweise eine GTM-Variable wie `{{Transaction ID}}` oder eine Lead-Referenz, keine personenbezogenen Daten.
5. **Send this conversion only once per page** aktiviert lassen, außer dieselbe Conversion soll bewusst mehrfach pro Seite gemeldet werden.
6. Unter **Erweiterte Einstellungen** die **Priorität der Tag-Auslösung** auf **800** setzen.
7. **Trigger:** euer Bestätigungsseiten-Trigger (URL-basiert oder Custom Event wie `purchase` aus dem E-Commerce-Data-Layer).
8. Speichern und veröffentlichen.

Repräsentiert eine Bestätigungsseite mehrere Conversions (z. B. Kauf + Newsletter-Anmeldung), einfach mehrere Tags anlegen und beide dort feuern — die Deduplizierung greift pro Typ und ID, beide gehen also durch.

## Setup-Muster und Consent

fraud0 muss **technisch und rechtlich unabhängig von Einwilligungen auslösen**. Läuft die Erkennung nur für Besucher, die Consent akzeptieren, sieht fraud0 fast ausschließlich einwilligenden (also überwiegend menschlichen) Traffic — und genau die Bots, für die es existiert, bleiben unsichtbar. fraud0 stellt Hinweise zur [Rechtsgrundlage](https://help.fraud0.com/3-general-faq/data-processing-privacy-practices/legal-compliance/legal01/) und einen [DPA (englisch)](https://www.fraud0.com/dpa/) bereit; die Einstufung mit dem Datenschutzbeauftragten abstimmen.

Welche Einbau-Variante richtig ist, hängt davon ab, **wie der GTM-Container selbst geladen wird**:

- **Muster 1 — GTM lädt einwilligungsunabhängig** (Container-Snippet im `<head>`, Tags einzeln über Consent-Einstellungen gesteuert): Der Main Tag kann **in GTM** liegen, Trigger All Pages, Consent-Einstellung „Keine zusätzliche Einwilligung erforderlich“. Für diesen Fall ersetzt die Vorlage den Custom-HTML-Tag.
- **Muster 2 — GTM selbst lädt erst nach Opt-in** (z. B. CMP oder Loader injiziert das Container-Script erst bei Zustimmung): Der Main Tag darf **nicht** in GTM liegen — er würde das Consent-Gate erben. fraud0 direkt in den `<body>` einbetten (oder in einen Loader, der vor dem Gate läuft) und diese Vorlage höchstens für Conversion Events nutzen. Auf Bestätigungsseiten lädt der Conversion-Event-Tag fz.js dann ein zweites Mal; das ist erwartet und unschädlich (fz.js initialisiert nur einmal).

**Abdeckung:** fraud0 empfiehlt für maximale Abdeckung den direkten Einbau im `<body>` (siehe [Implementierungs-Guide](https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted01/)). Über GTM läuft der Main Tag erst, wenn der GTM-Container geladen ist — Besucher und Bots, die `googletagmanager.com` blockieren, bleiben unsichtbar.

> **Häufiges Anti-Pattern:** Der Main Tag liegt in GTM **und** trägt zusätzlich eine Blocking-Rule oder eine Consent-Ausnahme auf eine Einwilligungskategorie. Auf dem Papier ist der Tag „essenziell“ eingestuft, faktisch feuert er erst nach Opt-in. **Prüfschritt:** den fraud0-Tag in GTM öffnen, Ausnahme-Trigger und **Erweiterte Einstellungen → Einstellungen für die Einwilligung** kontrollieren, Kategorie-Anforderungen entfernen und **Keine zusätzliche Einwilligung erforderlich** setzen.

Die Vorlage enthält bewusst **keine Consent-Mode-APIs** (`isConsentGranted`, `addConsentListener`): eine Consent-Prüfung in der Vorlage widerspräche der Anforderung oben.

## Felder

| Feld | Sichtbar wenn | Pflicht | Beschreibung |
|---|---|---|---|
| fraud0 Customer ID (cid) | immer | ja | fraud0 Customer ID (UUID) aus dem Dashboard. GTM-Variable möglich. |
| Tag type | immer | ja | **Page View (fraud0 Main Tag)** — Standard — oder **Conversion Event**. |
| Conversion type | Tag type = Conversion Event | ja | `Purchase` (Standard), `Lead`, `Signup`, `Custom conversion type` oder `Basic conversion (sent as 'generic')`. |
| Custom conversion type | Conversion type = Custom conversion type | ja | Bezeichner wie `trial_started`, `whitepaper_download`, `quote_requested`. Buchstaben, Ziffern, `_`, `-`. Die Werte `1` und `generic` sind reserviert. |
| Conversion ID (optional) | Tag type = Conversion Event | nein | Kennung der Conversion-Instanz, idealerweise eindeutig (Bestell-ID, Lead- oder Registrierungs-Referenz). Nur technische Referenzen — keine personenbezogenen Daten wie E-Mail-Adressen, Namen oder User-IDs. Bei Basic ohne Wirkung. |
| Send this conversion only once per page | Tag type = Conversion Event | — (Standard: an) | Dedupliziert identische Conversions (gleicher Typ **und** gleiche ID) innerhalb eines Seitenladevorgangs, z. B. wenn bei einem AJAX-Formular ein Formular-Submit-Trigger und ein eigenes Bestätigungs-Event beide feuern. Unterschiedliche IDs gehen immer durch. In Single-Page-Applications umfasst ein Seitenladevorgang alle virtuellen Seiten — dort eine eindeutige Conversion ID verwenden. |

## Conversion-Typen

| Typ | In der Queue | Typische Conversion ID |
|---|---|---|
| Purchase | `fraud0.push(['purchase', id])` | Bestell-ID, z. B. `{{Transaction ID}}` |
| Lead | `fraud0.push(['lead', id])` | Lead-Referenz, z. B. eine Formular-Submission-ID |
| Signup | `fraud0.push(['signup', id])` | Registrierungs-Referenz (keine personenbezogenen Daten) |
| Custom | `fraud0.push(['<euer_typ>', id])` | beliebige Instanz-Kennung |
| Basic conversion | `fraud0.push([1])` (gesendet als `generic`) | — (ohne Wirkung) |

Ohne Conversion ID wird nur der Typ gepusht, z. B. `fraud0.push(['lead'])`.

Die Conversion-Schnittstelle überträgt **nur den Typ und die optionale ID — ein Umsatz- oder Währungsfeld existiert nicht.** fraud0 stellt Conversions im Dashboard und in den Reportings gesamthaft dar; nach Typ oder ID werden sie nicht weiter aufgeschlüsselt.

**Sprechenden Typ statt Basic bevorzugen.** Basic (`[1]`) wird als Typ `generic` gesendet und in fz.js über einen älteren Codepfad mit zeitabhängigen Nebenwirkungen verarbeitet (mögliche Doppelzählung; zudem kann eine direkt danach eingereihte Conversion beeinträchtigt werden). Basic und typisierte Conversion-Tags daher nicht auf derselben Seite kombinieren. Basic bleibt für bestehende Setups wählbar.

## Berechtigungen der Vorlage

Die Vorlage fordert die minimal nötigen Berechtigungen an:

| Berechtigung | Umfang | Zweck |
|---|---|---|
| Scripts einfügen | `https://api.fraud0.com/api/v2/*` | Lädt das fraud0-Erkennungsscript `fz.js`. |
| Pixel senden | `https://api.fraud0.com/api/v2/*` | Feuert den First-Hit-Pixel des Main Tags. |
| Globale Variablen | `fraud0` (lesen/schreiben) | Erstellt/nutzt die `window.fraud0`-Queue für Conversion Events. |
| Globale Variablen | `utag`, `dataLayer`, `F0Loaded` (nur lesen) | Vorschaumodus-Diagnosen D1–D4 und D6 (Tealium, Nicht-Array-Data-Layer/-Queue, Doppelinstallation, Main Tag noch nicht gelaufen). Nie geschrieben, nie ausgeführt, in Produktion nie gelesen. |
| Konsolen-Logging | nur Debug-Umgebungen | Die `[fraud0]`-Diagnosen im Vorschaumodus. Die Berechtigung selbst ist auf Debug beschränkt — Produktion bleibt still. |
| Container-Daten lesen | — | Erkennt den Vorschau-/Debug-Modus (`getContainerVersion().debugMode/previewMode`) und schaltet alle Diagnosen dahinter. |
| Template-Storage | — | Seiten-Marker für Pixel-/Conversion-Deduplizierung und Einmal-pro-Seite-Diagnosen. Auf die Seite beschränkt, keine Fenster-Globals. |

## Content Security Policy

Bei strikter Content Security Policy die fraud0-Hosts in `script-src`, `img-src` und `connect-src` freigeben. Netzwerkstatus `blocked: CSP` deutet auf einen fehlenden Eintrag hin. Die [fraud0-CSP-FAQ](https://help.fraud0.com/1-onsite/g-onsite-faq/technical-queries/implementation06/) enthält die vollständige empfohlene Basis-Policy (inkl. weiterer Direktiven wie `frame-src 'self'`) — sie ist die maßgebliche Referenz.

| Host | Direktiven | Wann nötig |
|---|---|---|
| `api.fraud0.com` | `script-src`, `img-src`, `connect-src` | Immer — der einzige Host, mit dem die Vorlage spricht; für Neu-Setups ausreichend. |
| `bt.fraud0.com` | `script-src`, `img-src`, `connect-src` | Nur, wenn die Site noch den **Legacy-Embed** mit diesem Host nutzt (Bestandskunden). Die Vorlage nutzt ihn nie. |

## Diagnose

Im **GTM-Vorschau-/Debug-Modus** prüft die Vorlage die Seite auf die bekannten Stolperfallen und schreibt Meldungen mit dem Präfix `[fraud0]` in die Browser-Konsole. **In Produktion (außerhalb der Vorschau) wird nichts geloggt und keiner dieser Fensterzugriffe ausgeführt** — die Logging-Berechtigung ist zusätzlich auf Debug-Umgebungen beschränkt.

| # | Bedingung | Meldung (sinngemäß) |
|---|---|---|
| D1 | `window.utag.link` existiert (Tealium) | Das Urteil geht als `fraud0_scoring_result` an `utag.link`; die Data-Layer-Events feuern auf dieser Seite **nicht**. |
| D2 | `window.dataLayer` existiert, ist aber kein Array | Kritisch: fz.js bricht die Initialisierung ab; kein Urteil wird zurückgeschrieben, Conversions werden nicht gemeldet. |
| D3 | `window.fraud0` existiert, ist aber kein Array | Kritisch: die Conversion-Queue kann nicht andocken; Conversions gehen verloren. |
| D4 | Page View feuert erstmals, aber `window.F0Loaded` ist bereits `true` | Sofern nicht bereits ein fraud0-Conversion-Event-Tag auf der Seite feuerte: Doppelinstallation (Body-Embed, Legacy-`bt.fraud0.com`-Snippet, Consent-Tool-Integration oder zweiter Tag) — nur eine Quelle behalten. |
| D5 | Page View feuert ein zweites Mal auf derselben Seite | Doppelte Auslösung; der First-Hit-Pixel wird unterdrückt (höchstens einmal pro Seite). Trigger prüfen — All Pages genügt, History Change ist falsch. |
| D6 | Conversion feuert, bevor der Main Tag lief | Hinweis (keine Warnung): die Conversion wird in der `window.fraud0`-Queue gehalten und gesendet, sobald fz.js lädt. |
| D7 | Conversion-Typ ist `basic` | Wird als `generic` über einen älteren Codepfad gesendet (mögliche Doppelzählung) — sprechenden Typ bevorzugen. |
| D8 | Die aufgelöste Customer ID ist keine plausible UUID (Länge, Bindestriche, Hex-Zeichen, Version/Variante) | Mit ungültiger `cid` kann fz.js Events nicht eurem Account zuordnen — GTM-Variable prüfen. Der Tag feuert trotzdem (nur Log). |

## Preflight-Checkliste

Diese Liste einmal pro Site durchgehen — etwa 10 Minuten mit Browser-DevTools plus GTM-Vorschaumodus:

1. Der Page-View-Tag feuert auf **allen** Seiten, Tag-Priorität **1000**.
2. Netzwerk: `fz.js?cid=…` liefert Status **200** (oder 304 / aus dem Cache), `pixel?cid=…&cb=…` liefert **200** (oder 204).
3. Netzwerk: Nach dem Laden von fz.js liefern POST-Requests an `api.fraud0.com/api/v2/event` Status 2xx (beim ersten Seitenaufruf einer neuen Session typischerweise zwei; spätere Seitenaufrufe dürfen legitim nur einen zeigen).
4. Höchstens **ein** `fraud0`-Event pro Seitenladevorgang im Data Layer (eines mehr pro SPA-Routenwechsel ist erwartet).
5. Cookies `f0_uid` und `f0_sid` sind gesetzt (host-only, 365 Tage / 1 Tag; zusätzlich im `localStorage` gespiegelt — zum Zurücksetzen die Websitedaten löschen, nicht nur die Cookies).
6. **Kein zweites** fraud0-Script im DOM (kein Body-Embed, Legacy-`bt.fraud0.com`-Snippet oder Consent-Tool-Integration parallel) — außer auf Bestätigungsseiten in [Muster 2](#setup-muster-und-consent).
7. Kein `window.utag` auf der Seite — sonst geht das Urteil an Tealium statt in den Data Layer.
8. `window.dataLayer` ist ein **Array**.
9. Der Data-Layer-Name des GTM-Containers ist der Standard `dataLayer` (sonst die [Brücke](#was-fraud0-auf-die-seite-zurückschreibt) einbauen).
10. Der Conversion-Tag feuert **genau einmal** pro Conversion, danach folgt ein zusätzlicher POST an `/api/v2/event`.

Dieses Snippet in die Browser-Konsole einfügen — es liefert einen sofortigen Statusbericht:

```js
(function () {
  var dl = Array.isArray(window.dataLayer) ? window.dataLayer : [], out = {};
  out.dataLayerIsArray   = Array.isArray(window.dataLayer);
  out.tealiumPresent     = !!(window.utag && window.utag.link);
  out.fzInitialised      = window.F0Loaded === true;
  out.conversionQueueOk  = Array.isArray(window.fraud0);
  out.fraud0Events       = dl.filter(function (e) { return e && e.event === 'fraud0'; });
  out.invalidTrafficHits = dl.filter(function (e) { return e && e.event === 'f0_event_invalid_traffic'; }).length;
  out.lastVerdict        = out.fraud0Events.length
    ? out.fraud0Events[out.fraud0Events.length - 1].f0_bot_traffic
    : '(no verdict yet)';
  out.f0Cookies = document.cookie.split('; ').filter(function (c) { return c.indexOf('f0_') === 0; });
  out.fraud0Scripts = Array.prototype.slice
    .call(document.querySelectorAll('script[src*="fraud0"]'))
    .map(function (s) { return s.src; });
  console.log(out);
  return out;
})();
```

Lesehilfe: Mehr als ein Eintrag in `fraud0Scripts` = Doppelinstallation (außer auf Bestätigungsseiten in Muster 2). `tealiumPresent: true` = die Data-Layer-Events feuern auf dieser Seite nicht. `lastVerdict: '(no verdict yet)'` kurz nach dem Laden ist normal — dauerhaft nicht. In einer SPA wächst `fraud0Events` mit jedem Routenwechsel — das ist erwartetes Verhalten, kein Fehler.

## Einschränkungen

Bewusste Grenzen dieser Vorlage, jeweils mit Begründung:

- **Nur Web-Container.** Ein Setup über Server-Side GTM (sGTM) wird nicht unterstützt: fz.js sendet seine Daten immer direkt an `api.fraud0.com`, ein alternativer Endpunkt steht derzeit nicht zur Verfügung.
- **Tealium-Sites erhalten keine Data-Layer-Events** — fz.js liefert das Urteil über `utag.link` aus und endet (siehe [Was fraud0 zurückschreibt](#was-fraud0-auf-die-seite-zurückschreibt)). Das ist Verhalten von fz.js, nicht der Vorlage.
- **Container mit eigenem Data-Layer-Namen** brauchen das Brückensnippet aus [Was fraud0 zurückschreibt](#was-fraud0-auf-die-seite-zurückschreibt) — der Zielname `window.dataLayer` ist in fz.js fest verdrahtet.
- **Shopify-Web-Pixel (Kundenereignisse) eignen sich nicht für fraud0.** Läuft GTM — und damit diese Vorlage — in einem Shopify-Web-Pixel, startet die Sandbox standardmäßig erst nach Einwilligung, sieht keine echte Nutzerinteraktion und hält das Urteil vom `dataLayer` des Shops fern. Den fraud0 Main Tag stattdessen direkt im Theme einbinden (`theme.liquid`, direkt nach `<body>`).<!-- TODO: Link zur fraud0-Shopify-Doku ergänzen, sobald sie live ist. -->
- **Kein Umsatz-/Währungsfeld.** Die fraud0-Conversion-Schnittstelle nimmt nur Typ und optionale ID an; die Vorlage kann keine Felder ergänzen, die das Datenmodell nicht hat.
- **`setCustomerUserId` wird von der Vorlage nicht abgedeckt.** `window.fraud0.setCustomerUserId(…)` ist eine *Funktion*, die erst nach der fz.js-Initialisierung existiert — sie ist **nicht** über die Queue nachspielbar; ein Vorlagen-Tag würde je nach Ladezeitpunkt still scheitern. Stattdessen ein Custom-HTML-Tag mit dem Ready-Callback verwenden (und eine pseudonyme ID übergeben, keine E-Mail-Adresse):

  ```html
  <script>
  (function () {
    function setId() { window.fraud0.setCustomerUserId('EURE-USER-ID'); }
    if (typeof window.onFraud0Ready === 'function') { window.onFraud0Ready(setId); }
    else { (window.fraud0ReadyCallbacks = window.fraud0ReadyCallbacks || []).push(setId); }
  })();
  </script>
  ```

- **`customer_user_id_only` lässt sich nicht setzen.** Die Vorlage lädt immer `fz.js?cid=…`. Wer den fraud0-Modus ohne das Besucher-Cookie `f0_uid` braucht (`&customer_user_id_only=true`), nutzt stattdessen den direkten Einbau.
- **Der Legacy-Host `bt.fraud0.com` wird von der Vorlage nicht bedient.** Bestandskunden, deren Embed noch von `bt.fraud0.com` lädt — oder die die fraud0-Integration ihres Consent-Tools nutzen —, sollten den Page-View-Tag dieser Vorlage **nicht** parallel betreiben: fz.js initialisiert nur einmal (`window.F0Loaded`), die zweite Kopie ist ein unnötiger Download und mit hoher Wahrscheinlichkeit ein Konfigurationsfehler (die Vorlage warnt im Vorschaumodus, D4).
- **Kein „Verdict Relay“-Tag-Typ** (Status-Cookie schreiben, `f0_status_changed` pushen): die Vorlage selbst schreibt keine Cookies. Das Muster ist als optionales Custom-HTML-Rezept unter [Timing](#wann-das-urteil-eintrifft-timing) dokumentiert.
- **Keine Consent-Mode-APIs** in der Vorlage — fraud0 muss einwilligungsunabhängig laufen; eine Consent-Prüfung im Tag wäre inhaltlich falsch (siehe [Setup-Muster und Consent](#setup-muster-und-consent)).
- **Keine zusätzliche Variablen-Vorlage** (z. B. zum Auslesen des Urteils): sie bräuchte ein eigenes Repository (die Community Template Gallery erlaubt eine Vorlage pro Repository); eine Data-Layer-Variable auf `f0_bot_traffic` deckt das heute ab.
- Vorlagen können keine Tag-Priorität vorgeben; bitte manuell setzen (1000 / 800).

## Fehlerbehebung

Zuerst die [Preflight-Checkliste](#preflight-checkliste) durchgehen — sie deckt die häufigen Fälle systematisch ab. Zusätzlich:

- **Tag feuert, aber nichts kommt in fraud0 an:** Customer ID (UUID) prüfen, dann im Netzwerk-Panel nach Requests an `api.fraud0.com` schauen (`pixel` und `fz.js`). Im Vorschaumodus auf `[fraud0]`-Diagnosen in der Konsole achten.
- **Requests blockiert:** [CSP-Freigabe](#content-security-policy-1) und Ad-Blocker prüfen; siehe die [fraud0-CSP-FAQ](https://help.fraud0.com/1-onsite/g-onsite-faq/technical-queries/implementation06/). [Verify & Connect](https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted03/) beschreibt die allgemeinen Prüfschritte.
- **Conversions fehlen:** Der Main Tag muss auch auf der Bestätigungsseite feuern (All-Pages-Trigger), der Conversion-Tag danach (Priorität 800 < 1000). Feuert der Conversion-Tag zuerst, geht nichts verloren — die Queue hält die Conversion, bis fz.js lädt (Diagnose D6).
- **fraud0 sieht nur einwilligende Besucher:** der Main Tag (oder der GTM-Container selbst) hängt an einem Consent-Gate — siehe [Setup-Muster und Consent](#setup-muster-und-consent).

## Entwicklung & Tests

Die Vorlage enthält Unit-Tests (26 Szenarien) für Pixel, Script-Injection, alle Conversion-Varianten, beide Deduplizierungs-Guards, die Vorschaumodus-Diagnosen und die Fehlerpfade. Ausführen: `template.tpl` im GTM-Vorlagen-Editor importieren (**Vorlagen → Neu → Importieren**), Tab **Tests** öffnen, **▶ Tests ausführen** klicken.

Beiträge: bitte als Issue oder Pull Request in diesem Repository. Für eine neue Gallery-Version: Änderung committen, dann den Commit-SHA mit Change Notes oben in `versions` der `metadata.yaml` eintragen.

## Support

- fraud0 Knowledge Center: https://help.fraud0.com
- Implementierungs-Guide: https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted01/
- Conversion-Tag-Guide: https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted02/
- Data-Layer-Events: https://help.fraud0.com/1-onsite/c-data-layer-events/datalayer01/
- Support: support@fraud0.com
- Bugs in dieser Vorlage: GitHub Issues dieses Repositories.

## Lizenz

[Apache 2.0](LICENSE) — Copyright 2026 fraud0 GmbH
