# fraud0 Tag Template for Google Tag Manager

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Official Google Tag Manager (web) tag template for [fraud0](https://www.fraud0.com) — invalid traffic and bot detection. One template covers both parts of the fraud0 onsite setup:

- **Page View (fraud0 Main Tag):** loads the fraud0 detection script and immediately fires the first-hit pixel on every page.
- **Conversion Event:** reports conversions from your confirmation pages so the fraud0 detection model can identify false positives.

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

**Conversion Event.** The tag pushes the conversion into the `window.fraud0` queue (equivalent to the documented snippet `fraud0.push(['purchase', 'order123'])`) and additionally ensures the detection script is present. Script loading is deduplicated by URL, so the script is only loaded once per page even when the Main Tag and several Conversion Event tags fire together. Identical conversions (same type **and** ID) are de-duplicated per page by default — see [Field reference](#field-reference).

The template only communicates with `api.fraud0.com`. The template itself sets no cookies and uses no `localStorage`; the detection script (fz.js) sets the two fraud0 cookies `f0_uid` (365 days) and `f0_sid` (1 day), both host-only.

## What fraud0 writes back to the page

Once the fraud0 API has scored the visit, the detection script pushes its verdict into `window.dataLayer`:

| Event | When it is pushed | Meaning |
|---|---|---|
| `{event: 'fraud0', f0_bot_traffic: 'yes' \| 'no'}` | on every verdict | `yes` = classified as bot, **including verdicts that are still uncertain**. Use it for reporting and segmentation only. |
| `{event: 'f0_event_invalid_traffic'}` | additionally, only when the visit is a bot **and** the verdict is certain | The clean, confirmed-bot-only signal. **This is the event to build triggers and exclusion audiences on.** |

Key facts:

- **`uncertain` is not available in the data layer.** fz.js passes an `uncertain` flag to Tealium (see below) but not to `window.dataLayer`. In GTM, `f0_bot_traffic: 'yes'` therefore means "bot **or** still uncertain", while `f0_event_invalid_traffic` means "bot **and** certain". Only the second is suitable for exclusion.
- **Frequency:** there is **exactly one** `fraud0` event per classic page view — never two for the same page load. On single-page applications there is additionally **one per route change**: five in-app navigations produce five `fraud0` events. `f0_event_invalid_traffic` is equally repeatable and is **not** de-duplicated.
- **The verdict can flip between pushes** (`no` → `yes`): the first contact of a session is often still uncertain and gets corrected on a later page view or route change.
- **Consequence for GTM:** create triggers on these events as **repeatable** ("All Custom Events"), never "once per page" — and build every tag attached to them to tolerate multiple firings. A dedicated GA4 event attached to every `fraud0` push creates an event flood and artefact sessions (observed at scale in production); see [Trigger recipes](#trigger-recipes).

> **⚠️ Tealium takes precedence.** If `window.utag` with a `link` function exists on the page (the signature of a Tealium container), fz.js sends the verdict as `utag.link({tealium_event: 'fraud0_scoring_result', is_bot, uncertain})` and **returns — the data layer events above are then never pushed, silently.** Build Tealium triggers on `fraud0_scoring_result` instead. The template warns about this in GTM preview mode (see [Diagnostics](#diagnostics)).

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

- To fire marketing or personalisation tags **only for verified humans**, trigger them on the `fraud0` event with the condition `f0_bot_traffic equals no` instead of on Page View.
- Trade-off: those tags then start 0.2–0.9 s later (after the verdict) and the very first page of a session may still classify conservatively. See [timing](#when-the-verdict-arrives-timing) and the [Pixel Protect guide](https://help.fraud0.com/1-onsite/d-pixel-protect/pixelprotect01/).

## When the verdict arrives (timing)

The verdict typically arrives **0.2–0.9 seconds after page start** (HAR measurements across several production sites: fz.js load plus one or two API round trips). fz.js does **not** persist the verdict anywhere — there is no status cookie and no result callback; only `f0_uid`/`f0_sid` are stored. Every page load fetches the verdict over the network again.

That makes the value unreliable on early events: in a large-scale production measurement (May 2026, ~870,000 events), the Google tag had already fired before the fraud0 verdict arrived in **roughly 62% of cases** — a `page_view` event parameter read from the `fraud0` push would have been empty that often. The value is dependable on **late events** (`purchase`, `login`, `sign_up`) and as a **user property** (where the last value of the session wins).

**Optional customer recipe — persist the verdict in a first-party status cookie.** This pattern is deliberately *not* part of the template (it writes a cookie, which the template itself never does). Run it as a Custom HTML tag on the Custom Event trigger `fraud0` (All Custom Events):

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

1. **Tags → New → Tag Configuration** → choose **fraud0**.
2. Enter your **fraud0 Customer ID (cid)**. You find it in the [fraud0 Dashboard](https://admin.fraud0.com/settings?tab=tag_management) under **Settings → Tag Management** (the `cid` value in the tag snippet, a UUID).
3. Keep the default Tag Type **Page View (fraud0 Main Tag)**.
4. Open **Advanced Settings** and set **Tag firing priority** to **1000**, so fraud0 fires before all other tags.
5. Under **Advanced Settings → Consent Settings**, choose **No additional consent required** (see [Setup patterns and consent](#setup-patterns-and-consent)).
6. Set **Triggering** to **All Pages** (or an equivalent trigger that fires unconditionally on every page view). Do **not** add a History Change trigger — fz.js tracks SPA route changes itself.
7. Save and publish.

> **Important:** fraud0 must fire **technically and legally independent of consent decisions** — bots do not click consent banners. Whether the Main Tag belongs in GTM at all depends on how your GTM container is loaded: see [Setup patterns and consent](#setup-patterns-and-consent).

## Setup — Conversion Events

Add one tag per conversion type, fired **only on confirmation pages** (post-checkout, post-form-submit, post-signup):

1. **Tags → New → Tag Configuration** → choose **fraud0**.
2. Enter the same **fraud0 Customer ID (cid)**.
3. Set Tag Type to **Conversion Event**.
4. Pick a **Conversion Type** (see table below) and optionally a **Conversion ID**, typically a GTM variable such as `{{Transaction ID}}` or a form name.
5. Keep **Send this conversion only once per page** enabled unless the same conversion should intentionally be reported several times on one page.
6. Open **Advanced Settings** and set **Tag firing priority** to **800**.
7. Set **Triggering** to your confirmation-page trigger (URL-based or a custom event such as `purchase` from your e-commerce data layer).
8. Save and publish.

If a single confirmation page represents more than one conversion (e.g. purchase + newsletter signup), create one tag per conversion and fire both on that page — de-duplication is per type and ID, so both go through.

## Setup patterns and consent

fraud0 must fire **technically and legally independent of consent decisions**. If the detection only runs for visitors who accept consent, fraud0 sees almost exclusively consenting (i.e. overwhelmingly human) traffic — and the bots it exists to catch stay invisible. fraud0 provides notes on the [legal basis](https://help.fraud0.com/3-general-faq/data-processing-privacy-practices/legal-compliance/legal01/) and a [DPA](https://www.fraud0.com/dpa/); clarify the classification with your data protection officer.

Which embed variant is correct depends on **how your GTM container itself is loaded**:

- **Setup A — GTM loads independently of consent** (container snippet in the `<head>`, tags gated individually via consent settings): the Main Tag belongs **in GTM**, trigger All Pages, consent setting "No additional consent required". This template is the right tool.
- **Setup B — GTM itself only loads after opt-in** (e.g. the CMP or a loader injects the container script upon consent): the Main Tag must **not** live in GTM — it would inherit the consent gate. Embed fraud0 directly in the `<body>` (or in a loader that runs before the gate) and use this template only for Conversion Events, if at all.

> **Anti-pattern (seen in production):** the Main Tag sits in GTM **and** additionally carries a blocking rule or a consent exception tied to a consent category. The tag is classified as "essential" on paper but in effect fires only after opt-in. **Check:** open the fraud0 tag in GTM, inspect its firing exceptions and **Advanced Settings → Consent Settings**, remove consent-category requirements and set **No additional consent required**.

The template deliberately contains **no consent-mode APIs** (`isConsentGranted`, `addConsentListener`): a consent check inside the template would contradict the requirement above.

## Field reference

| Field | Shown when | Required | Description |
|---|---|---|---|
| fraud0 Customer ID (cid) | always | yes | Your fraud0 Customer ID (UUID) from the dashboard. Accepts a GTM variable. |
| Tag Type | always | yes | **Page View (fraud0 Main Tag)** — default — or **Conversion Event**. |
| Conversion Type | Tag Type = Conversion Event | yes | `Purchase` (default), `Lead`, `Signup`, `Custom` or `Basic (legacy)`. |
| Custom Conversion Type | Conversion Type = Custom | yes | Identifier such as `trial_started`, `whitepaper_download`, `quote_requested`. Letters, digits, `_`, `-`. The values `1` and `generic` are reserved. |
| Conversion ID (optional) | Tag Type = Conversion Event | no | Unique identifier for this conversion instance (order ID, form name, signup ID). Enables per-conversion reporting. Ignored for Basic. |
| Send this conversion only once per page | Tag Type = Conversion Event | — (default: on) | De-duplicates identical conversions (same type **and** ID) per page, e.g. when a form-submit trigger and a confirmation-page trigger both fire. Different IDs always go through. |

## Conversion types

| Type | Queued as | Typical Conversion ID |
|---|---|---|
| Purchase | `fraud0.push(['purchase', id])` | order ID, e.g. `{{Transaction ID}}` |
| Lead | `fraud0.push(['lead', id])` | form name, e.g. `contact_form` |
| Signup | `fraud0.push(['signup', id])` | signup/user ID |
| Custom | `fraud0.push(['<your_type>', id])` | anything that identifies the instance |
| Basic conversion (legacy) | `fraud0.push([1])` | — (not used) |

Without a Conversion ID, only the type is pushed, e.g. `fraud0.push(['lead'])`.

The conversion interface transmits **only the type and the optional ID — there is no revenue or currency field.** A descriptive type that is unique per conversion kind is what makes conversions separable in fraud0 reporting.

**Avoid Basic conversions.** fraud0 reports `[1]` as the type `generic`, so it cannot be told apart from other basic conversions — and if the entry sits in the queue before the detection script initialises, a legacy code path can count it twice (once via the queue replay as a `CONVERSION` event, once as a conversion flag on the initial page-load event). Typed pushes are not affected. Basic remains selectable for backwards compatibility only.

## Template permissions

The template requests the minimum permissions needed:

| Permission | Scope | Why |
|---|---|---|
| Injects scripts | `https://api.fraud0.com/api/v2/*` | Loads the fraud0 detection script `fz.js`. |
| Sends pixels | `https://api.fraud0.com/api/v2/*` | Fires the first-hit 1×1 pixel of the Main Tag. |
| Accesses global variables | `fraud0` (read/write) | Creates/uses the `window.fraud0` queue for conversion events. |
| Accesses global variables | `utag`, `dataLayer`, `F0Loaded` (read-only) | Preview-mode diagnostics D1–D4 (Tealium, non-array data layer/queue, duplicate installation). Never written, never executed, never read in production. |
| Logs to console | debug environments only | The `[fraud0]` diagnostics in preview mode. The permission itself is restricted to debug, so production stays silent. |
| Reads container data | — | Detects preview/debug mode (`getContainerVersion().debugMode/previewMode`) to gate all diagnostics. |
| Accesses template storage | — | Per-page markers for the pixel/conversion de-duplication and once-per-page diagnostics. Page-scoped, no window globals. |

## Content Security Policy

If your site uses a strict Content Security Policy, allow-list the fraud0 host(s) in `script-src`, `img-src` and `connect-src`. A network status of `blocked: CSP` indicates a missing entry ([FAQ](https://help.fraud0.com/1-onsite/g-onsite-faq/technical-queries/implementation06/)).

| Host | Directives | When needed |
|---|---|---|
| `api.fraud0.com` | `script-src`, `img-src`, `connect-src` | Always — this is the only host the template talks to, sufficient for new setups. |
| `bt.fraud0.com` | `script-src`, `img-src`, `connect-src` | Only if your site still runs the **legacy embed** with this host (existing customers). The template never uses it. |

## Diagnostics

In **GTM preview/debug mode** the template checks the page for the known integration pitfalls and logs `[fraud0]`-prefixed messages to the browser console. **In production (outside preview) nothing is logged and none of these window reads happen** — the logging permission itself is additionally restricted to debug environments.

| # | Condition | Message (abridged) |
|---|---|---|
| D1 | `window.utag.link` exists (Tealium) | Verdict goes to `utag.link` as `fraud0_scoring_result`; the data layer events will **not** fire on this page. |
| D2 | `window.dataLayer` exists but is not an array | Critical: fz.js will throw; no verdict is written back. |
| D3 | `window.fraud0` exists but is not an array | Critical: the conversion queue cannot attach; conversions are lost. |
| D4 | Page View fires for the first time but `window.F0Loaded` is already `true` | Duplicate installation (body embed, legacy `bt.fraud0.com` snippet or second tag) — keep exactly one source. |
| D5 | Page View fires a second time on the same page | Duplicate firing; the first-hit pixel is suppressed (sent at most once per page). Check the trigger — All Pages is enough, History Change is wrong. |
| D6 | Conversion fires before the Main Tag has run | Note (no warning): the conversion is held in the `window.fraud0` queue and sent once fz.js loads. |
| D7 | Conversion type is `basic` | Legacy: reported as `generic`, possible double counting — prefer a descriptive type. |
| D8 | The resolved Customer ID is implausible (not 36 chars / hyphens misplaced) | fraud0 rejects requests with an invalid `cid` — check the GTM variable. The tag still fires (log only). |

## Preflight checklist

Work through this list once per site — it takes about 10 minutes in the browser DevTools plus GTM preview mode:

1. The Page View tag fires on **all** pages, tag firing priority **1000**.
2. Network: `fz.js?cid=…` and `pixel?cid=…&cb=…` both return status **200/204**.
3. Network: **two POSTs** to `/api/v2/event` on a fresh page load (the minimal first-hit event and the full data set).
4. Exactly **one** `fraud0` event per page view in the data layer (one more per SPA route change is expected).
5. Cookies `f0_uid` and `f0_sid` are set (host-only, 365 days / 1 day).
6. **No second** fraud0 script in the DOM (no body embed or legacy `bt.fraud0.com` snippet in parallel).
7. No `window.utag` on the page — otherwise the verdict goes to Tealium, not to the data layer.
8. `window.dataLayer` is an **array**.
9. The GTM container's data layer name is the default `dataLayer` (otherwise install the [bridge](#what-fraud0-writes-back-to-the-page)).
10. The Conversion tag fires **exactly once** per conversion and produces a `CONVERSION` event (third POST to `/api/v2/event`).

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

How to read the output: more than one entry in `fraud0Scripts` = duplicate installation. `tealiumPresent: true` = the data layer events do not fire on this page. `lastVerdict: '(no verdict yet)'` briefly after load is normal — permanently is not. On a SPA, `fraud0Events` grows with every route change — that is expected behaviour, not an error.

## Limitations

Deliberate boundaries of this template, each with the reason:

- **Web containers only.** The template runs in client-side GTM web containers and always talks to `api.fraud0.com` directly. An **SGTM proxy domain is not configurable** — keeping the endpoint fixed keeps the permission list minimal and reviewable. If you proxy fraud0 through your own Server-Side GTM endpoint, keep using the documented SGTM setup instead of this template's Page View tag.
- **Tealium sites receive no data layer events** — fz.js delivers the verdict via `utag.link` and stops (see [What fraud0 writes back](#what-fraud0-writes-back-to-the-page)). This is fz.js behaviour, not template behaviour.
- **Containers with a custom data layer name** need the bridge snippet from [What fraud0 writes back](#what-fraud0-writes-back-to-the-page) — the target name `window.dataLayer` is hard-wired in fz.js.
- **No revenue/currency field.** The fraud0 conversion interface accepts only a type and an optional ID; the template cannot add fields that the data model does not have.
- **`setCustomerUserId` is not covered by the template.** `window.fraud0.setCustomerUserId(…)` is a *function* that only exists after fz.js has initialised — it is **not** replayable through the queue, so a template tag would silently fail depending on load order. Use a Custom HTML tag with the ready callback instead:

  ```html
  <script>
  (function () {
    function setId() { window.fraud0.setCustomerUserId('YOUR-USER-ID'); }
    if (window.fraud0Ready === true) { setId(); }
    else { (window.fraud0ReadyCallbacks = window.fraud0ReadyCallbacks || []).push(setId); }
  })();
  </script>
  ```

- **The legacy host `bt.fraud0.com` is not served by the template.** Existing customers whose embed still loads from `bt.fraud0.com` should **not** run this template's Page View tag in parallel — fz.js initialises only once (`window.F0Loaded`), so the second copy is a wasted download and almost certainly a configuration error (the template warns in preview mode, D4).
- **No "verdict relay" tag type** (writing a status cookie, pushing `f0_status_changed`): the template itself writes no cookies. The pattern is documented as an optional Custom HTML recipe under [timing](#when-the-verdict-arrives-timing).
- **No consent-mode APIs** in the template — fraud0 must run independent of consent; a consent check inside the tag would be semantically wrong (see [Setup patterns and consent](#setup-patterns-and-consent)).
- **No additional variable template** (e.g. for reading the verdict): the Community Template Gallery allows exactly one template per repository.
- Tag firing priority cannot be preset by templates; set it manually as described above (1000 / 800).

## Troubleshooting

Start with the [Preflight checklist](#preflight-checklist) — it covers the frequent cases systematically. In addition:

- **Tag fires but nothing shows in fraud0:** verify the Customer ID (UUID), then check the network panel for requests to `api.fraud0.com` (`pixel` and `fz.js`). In preview mode, watch for `[fraud0]` diagnostics in the console.
- **Requests blocked:** check [CSP allow-listing](#content-security-policy) and ad-blocker behaviour; see the [Verify & Connect guide](https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted03/).
- **Conversions missing:** make sure the Main Tag also fires on the confirmation page (All Pages trigger) and that the conversion tag fires after it (priority 800 < 1000). If the conversion tag fires first, nothing is lost — the queue holds it until fz.js loads (diagnostic D6).
- **fraud0 only sees consenting visitors:** the Main Tag (or the GTM container itself) is consent-gated — see [Setup patterns and consent](#setup-patterns-and-consent).

## Development & tests

The template ships with unit tests (20 scenarios) covering the pixel, script injection, all conversion variants, both de-duplication guards, the preview-mode diagnostics and failure paths. To run them: import `template.tpl` into the GTM Template Editor (**Templates → New → Import**), open the **Tests** tab and click **▶ Run Tests**.

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

Offizielle Google-Tag-Manager-Vorlage (Web) für [fraud0](https://www.fraud0.com) — Erkennung von Invalid Traffic und Bots. Eine Vorlage deckt beide Teile des fraud0-Onsite-Setups ab:

- **Page View (fraud0 Main Tag):** lädt das fraud0-Erkennungsscript und feuert sofort den First-Hit-Pixel auf jeder Seite.
- **Conversion Event:** meldet Conversions von Bestätigungsseiten, damit das fraud0-Modell False Positives erkennen kann.

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

**Page View (Main Tag).** Der Tag feuert sofort einen 1×1-Pixel (`https://api.fraud0.com/api/v2/pixel?cid=…&cb=…`) und lädt asynchron das Erkennungsscript (`https://api.fraud0.com/api/v2/fz.js?cid=…`). Der Pixel feuert unabhängig davon, ob das JavaScript jemals fertig lädt — so erkennt fraud0 auch Bots, die die Seite in den ersten Millisekunden wieder verlassen. Der Pixel wird **höchstens einmal pro Seitenaufruf** gesendet, auch wenn der Tag versehentlich ein zweites Mal feuert.

**Conversion Event.** Der Tag pusht die Conversion in die `window.fraud0`-Queue (äquivalent zum dokumentierten Snippet `fraud0.push(['purchase', 'order123'])`) und stellt zusätzlich sicher, dass das Erkennungsscript vorhanden ist. Das Laden ist pro URL dedupliziert — das Script wird also auch dann nur einmal geladen, wenn Main Tag und mehrere Conversion-Tags auf derselben Seite feuern. Identische Conversions (gleicher Typ **und** gleiche ID) werden standardmäßig pro Seite dedupliziert — siehe [Felder](#felder).

Die Vorlage kommuniziert ausschließlich mit `api.fraud0.com`. Die Vorlage selbst setzt keine Cookies und nutzt keinen `localStorage`; das Erkennungsscript (fz.js) setzt die beiden fraud0-Cookies `f0_uid` (365 Tage) und `f0_sid` (1 Tag), beide host-only.

## Was fraud0 auf die Seite zurückschreibt

Sobald die fraud0-API den Besuch bewertet hat, pusht das Erkennungsscript sein Urteil in `window.dataLayer`:

| Event | Wann gepusht | Bedeutung |
|---|---|---|
| `{event: 'fraud0', f0_bot_traffic: 'yes' \| 'no'}` | bei jedem Urteil | `yes` = als Bot eingestuft, **einschließlich noch unsicherer Urteile**. Nur für Reporting und Segmentierung verwenden. |
| `{event: 'f0_event_invalid_traffic'}` | zusätzlich, nur wenn der Besuch ein Bot ist **und** das Urteil sicher ist | Das saubere Nur-bestätigte-Bots-Signal. **Auf dieses Event gehören Trigger und Ausschluss-Zielgruppen.** |

Die wichtigsten Fakten:

- **`uncertain` steht im Data Layer nicht zur Verfügung.** fz.js übergibt ein `uncertain`-Flag an Tealium (siehe unten), aber nicht an `window.dataLayer`. In GTM bedeutet `f0_bot_traffic: 'yes'` deshalb „Bot **oder** noch unsicher", `f0_event_invalid_traffic` bedeutet „Bot **und** sicher". Nur das zweite taugt für Ausschlüsse.
- **Häufigkeit:** Pro klassischem Seitenaufruf gibt es **genau ein** `fraud0`-Event — nie zwei für denselben Seitenladevorgang. In Single-Page-Applications kommt zusätzlich **eines pro Routenwechsel** dazu: fünf Klicks in der SPA = fünf `fraud0`-Events. `f0_event_invalid_traffic` ist ebenso wiederholbar und wird **nicht** dedupliziert.
- **Das Urteil kann zwischen den Pushes kippen** (`no` → `yes`): der erste Kontakt einer Session ist oft noch unsicher und wird auf einem späteren Seitenaufruf oder Routenwechsel korrigiert.
- **Konsequenz für GTM:** Trigger auf diese Events als **wiederholbar** anlegen („Alle benutzerdefinierten Ereignisse"), niemals „einmal pro Seite" — und jedes daran hängende Tag muss mehrfaches Feuern vertragen. Ein dediziertes GA4-Event an jedem `fraud0`-Push erzeugt eine Event-Flut und Artefakt-Sessions (in Produktion in großem Umfang beobachtet); siehe [Trigger-Rezepte](#trigger-rezepte).

> **⚠️ Tealium hat Vorrang.** Existiert auf der Seite `window.utag` mit einer `link`-Funktion (die Signatur eines Tealium-Containers), sendet fz.js das Urteil als `utag.link({tealium_event: 'fraud0_scoring_result', is_bot, uncertain})` und endet — **die Data-Layer-Events oben werden dann nie gepusht, lautlos.** Tealium-Trigger stattdessen auf `fraud0_scoring_result` aufbauen. Die Vorlage warnt davor im GTM-Vorschaumodus (siehe [Diagnose](#diagnose)).

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

- Marketing- oder Personalisierungs-Tags **nur für verifizierte Menschen** auslösen: Trigger auf das Event `fraud0` mit Bedingung `f0_bot_traffic equals no` statt auf Page View.
- Trade-off: diese Tags starten dann 0,2–0,9 s später (nach dem Urteil), und die allererste Seite einer Session kann noch konservativ eingestuft sein. Siehe [Timing](#wann-das-urteil-eintrifft-timing) und den [Pixel-Protect-Guide](https://help.fraud0.com/1-onsite/d-pixel-protect/pixelprotect01/).

## Wann das Urteil eintrifft (Timing)

Das Urteil liegt typischerweise **0,2–0,9 Sekunden nach Seitenstart** vor (HAR-Messungen auf mehreren Produktiv-Sites: fz.js-Load plus ein bis zwei API-Roundtrips). fz.js persistiert das Urteil **nirgends** — es gibt kein Status-Cookie und keinen Ergebnis-Callback; gespeichert werden nur `f0_uid`/`f0_sid`. Jeder Seitenaufruf holt das Urteil neu über das Netz.

Auf frühen Events ist der Wert deshalb unzuverlässig: In einer produktiven Messung in großem Maßstab (Mai 2026, ~870.000 Events) hatte der Google Tag in **rund 62 % der Fälle** bereits gefeuert, bevor das fraud0-Urteil eintraf — ein aus dem `fraud0`-Push gelesener `page_view`-Parameter wäre entsprechend oft leer gewesen. Belastbar ist der Wert auf **späten Events** (`purchase`, `login`, `sign_up`) und als **User Property** (dort gewinnt der letzte Wert der Session).

**Optionales Kundenrezept — das Urteil in einem First-Party-Status-Cookie persistieren.** Dieses Muster ist bewusst *nicht* Teil der Vorlage (es schreibt ein Cookie, was die Vorlage selbst nie tut). Als Custom-HTML-Tag auf dem Custom-Event-Trigger `fraud0` (Alle benutzerdefinierten Ereignisse) ausführen:

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

1. **Tags → Neu → Tag-Konfiguration** → **fraud0** wählen.
2. **fraud0 Customer ID (cid)** eintragen — zu finden im [fraud0 Dashboard](https://admin.fraud0.com/settings?tab=tag_management) unter **Settings → Tag Management** (der `cid`-Wert im Tag-Snippet, eine UUID).
3. Tag Type auf dem Standard **Page View (fraud0 Main Tag)** belassen.
4. Unter **Erweiterte Einstellungen** die **Priorität der Tag-Auslösung** auf **1000** setzen, damit fraud0 vor allen anderen Tags feuert.
5. Unter **Erweiterte Einstellungen → Einstellungen für die Einwilligung** die Option **Keine zusätzliche Einwilligung erforderlich** wählen (siehe [Setup-Muster und Consent](#setup-muster-und-consent)).
6. **Trigger: All Pages** (bzw. ein Trigger, der bedingungslos auf jedem Seitenaufruf feuert). **Keinen** History-Change-Trigger ergänzen — fz.js erkennt SPA-Routenwechsel selbst.
7. Speichern und veröffentlichen.

> **Wichtig:** fraud0 muss **technisch und rechtlich unabhängig von Einwilligungen auslösen** — Bots klicken keine Consent-Banner. Ob der Main Tag überhaupt in GTM gehört, hängt davon ab, wie der GTM-Container geladen wird: siehe [Setup-Muster und Consent](#setup-muster-und-consent).

## Einrichtung — Conversion Events

Pro Conversion-Typ einen Tag anlegen, der **nur auf Bestätigungsseiten** feuert (nach Checkout, Formular-Absenden, Registrierung):

1. **Tags → Neu → Tag-Konfiguration** → **fraud0** wählen.
2. Dieselbe **fraud0 Customer ID (cid)** eintragen.
3. Tag Type auf **Conversion Event** stellen.
4. **Conversion Type** wählen (Tabelle unten) und optional eine **Conversion ID** angeben — typischerweise eine GTM-Variable wie `{{Transaction ID}}` oder ein Formularname.
5. **Send this conversion only once per page** aktiviert lassen, außer dieselbe Conversion soll bewusst mehrfach pro Seite gemeldet werden.
6. Unter **Erweiterte Einstellungen** die **Priorität der Tag-Auslösung** auf **800** setzen.
7. **Trigger:** euer Bestätigungsseiten-Trigger (URL-basiert oder Custom Event wie `purchase` aus dem E-Commerce-Data-Layer).
8. Speichern und veröffentlichen.

Repräsentiert eine Bestätigungsseite mehrere Conversions (z. B. Kauf + Newsletter-Anmeldung), einfach mehrere Tags anlegen und beide dort feuern — die Deduplizierung greift pro Typ und ID, beide gehen also durch.

## Setup-Muster und Consent

fraud0 muss **technisch und rechtlich unabhängig von Einwilligungen auslösen**. Läuft die Erkennung nur für Besucher, die Consent akzeptieren, sieht fraud0 fast ausschließlich einwilligenden (also überwiegend menschlichen) Traffic — und genau die Bots, für die es existiert, bleiben unsichtbar. fraud0 stellt Hinweise zur [Rechtsgrundlage](https://help.fraud0.com/3-general-faq/data-processing-privacy-practices/legal-compliance/legal01/) und einen [AVV/DPA](https://www.fraud0.com/dpa/) bereit; die Einstufung mit dem Datenschutzbeauftragten abstimmen.

Welche Einbau-Variante richtig ist, hängt davon ab, **wie der GTM-Container selbst geladen wird**:

- **Setup A — GTM lädt einwilligungsunabhängig** (Container-Snippet im `<head>`, Tags einzeln über Consent-Einstellungen gesteuert): der Main Tag gehört **in GTM**, Trigger All Pages, Consent-Einstellung „Keine zusätzliche Einwilligung erforderlich". Diese Vorlage ist das richtige Werkzeug.
- **Setup B — GTM selbst lädt erst nach Opt-in** (z. B. CMP oder Loader injiziert das Container-Script erst bei Zustimmung): der Main Tag darf **nicht** in GTM liegen — er würde das Consent-Gate erben. fraud0 direkt in den `<body>` einbetten (oder in einen Loader, der vor dem Gate läuft) und diese Vorlage höchstens für Conversion Events nutzen.

> **Anti-Pattern (real so vorgefunden):** Der Main Tag liegt in GTM **und** trägt zusätzlich eine Blocking-Rule oder eine Consent-Ausnahme auf eine Einwilligungskategorie. Auf dem Papier ist der Tag „essenziell" eingestuft, faktisch feuert er erst nach Opt-in. **Prüfschritt:** den fraud0-Tag in GTM öffnen, Ausnahme-Trigger und **Erweiterte Einstellungen → Einstellungen für die Einwilligung** kontrollieren, Kategorie-Anforderungen entfernen und **Keine zusätzliche Einwilligung erforderlich** setzen.

Die Vorlage enthält bewusst **keine Consent-Mode-APIs** (`isConsentGranted`, `addConsentListener`): eine Consent-Prüfung in der Vorlage widerspräche der Anforderung oben.

## Felder

| Feld | Sichtbar wenn | Pflicht | Beschreibung |
|---|---|---|---|
| fraud0 Customer ID (cid) | immer | ja | fraud0 Customer ID (UUID) aus dem Dashboard. GTM-Variable möglich. |
| Tag Type | immer | ja | **Page View (fraud0 Main Tag)** — Standard — oder **Conversion Event**. |
| Conversion Type | Tag Type = Conversion Event | ja | `Purchase` (Standard), `Lead`, `Signup`, `Custom` oder `Basic (Legacy)`. |
| Custom Conversion Type | Conversion Type = Custom | ja | Bezeichner wie `trial_started`, `whitepaper_download`, `quote_requested`. Buchstaben, Ziffern, `_`, `-`. Die Werte `1` und `generic` sind reserviert. |
| Conversion ID (optional) | Tag Type = Conversion Event | nein | Eindeutige Kennung der Conversion-Instanz (Bestell-ID, Formularname, Signup-ID). Ermöglicht Reporting pro Conversion. Bei Basic ohne Wirkung. |
| Send this conversion only once per page | Tag Type = Conversion Event | — (Standard: an) | Dedupliziert identische Conversions (gleicher Typ **und** gleiche ID) pro Seite, z. B. wenn Formular-Submit-Trigger und Bestätigungsseiten-Trigger beide feuern. Unterschiedliche IDs gehen immer durch. |

## Conversion-Typen

| Typ | In der Queue | Typische Conversion ID |
|---|---|---|
| Purchase | `fraud0.push(['purchase', id])` | Bestell-ID, z. B. `{{Transaction ID}}` |
| Lead | `fraud0.push(['lead', id])` | Formularname, z. B. `contact_form` |
| Signup | `fraud0.push(['signup', id])` | Signup-/User-ID |
| Custom | `fraud0.push(['<euer_typ>', id])` | beliebige Instanz-Kennung |
| Basic conversion (Legacy) | `fraud0.push([1])` | — (ohne Wirkung) |

Ohne Conversion ID wird nur der Typ gepusht, z. B. `fraud0.push(['lead'])`.

Die Conversion-Schnittstelle überträgt **nur den Typ und die optionale ID — ein Umsatz- oder Währungsfeld existiert nicht.** Eine sprechende, pro Conversion-Art eindeutige Typ-Bezeichnung ist die Voraussetzung dafür, dass sich Conversion-Arten in der fraud0-Auswertung trennen lassen.

**Basic-Conversions vermeiden.** fraud0 meldet `[1]` als Typ `generic` — von anderen Basic-Conversions nicht unterscheidbar. Liegt der Eintrag außerdem in der Queue, bevor das Erkennungsscript initialisiert, kann ein Legacy-Codepfad ihn doppelt werten (einmal über das Queue-Replay als `CONVERSION`-Event, einmal als Conversion-Flag am initialen Page-Load-Event). Typisierte Pushes sind nicht betroffen. Basic bleibt nur aus Kompatibilitätsgründen wählbar.

## Berechtigungen der Vorlage

Die Vorlage fordert die minimal nötigen Berechtigungen an:

| Berechtigung | Umfang | Zweck |
|---|---|---|
| Scripts einfügen | `https://api.fraud0.com/api/v2/*` | Lädt das fraud0-Erkennungsscript `fz.js`. |
| Pixel senden | `https://api.fraud0.com/api/v2/*` | Feuert den First-Hit-Pixel des Main Tags. |
| Globale Variablen | `fraud0` (lesen/schreiben) | Erstellt/nutzt die `window.fraud0`-Queue für Conversion Events. |
| Globale Variablen | `utag`, `dataLayer`, `F0Loaded` (nur lesen) | Vorschaumodus-Diagnosen D1–D4 (Tealium, Nicht-Array-Data-Layer/-Queue, Doppelinstallation). Nie geschrieben, nie ausgeführt, in Produktion nie gelesen. |
| Konsolen-Logging | nur Debug-Umgebungen | Die `[fraud0]`-Diagnosen im Vorschaumodus. Die Berechtigung selbst ist auf Debug beschränkt — Produktion bleibt still. |
| Container-Daten lesen | — | Erkennt den Vorschau-/Debug-Modus (`getContainerVersion().debugMode/previewMode`) und schaltet alle Diagnosen dahinter. |
| Template-Storage | — | Seiten-Marker für Pixel-/Conversion-Deduplizierung und Einmal-pro-Seite-Diagnosen. Auf die Seite beschränkt, keine Fenster-Globals. |

## Content Security Policy

Bei strikter Content Security Policy die fraud0-Hosts in `script-src`, `img-src` und `connect-src` freigeben. Netzwerkstatus `blocked: CSP` deutet auf einen fehlenden Eintrag hin ([FAQ](https://help.fraud0.com/1-onsite/g-onsite-faq/technical-queries/implementation06/)).

| Host | Direktiven | Wann nötig |
|---|---|---|
| `api.fraud0.com` | `script-src`, `img-src`, `connect-src` | Immer — der einzige Host, mit dem die Vorlage spricht; für Neu-Setups ausreichend. |
| `bt.fraud0.com` | `script-src`, `img-src`, `connect-src` | Nur, wenn die Site noch den **Legacy-Embed** mit diesem Host nutzt (Bestandskunden). Die Vorlage nutzt ihn nie. |

## Diagnose

Im **GTM-Vorschau-/Debug-Modus** prüft die Vorlage die Seite auf die bekannten Stolperfallen und schreibt Meldungen mit dem Präfix `[fraud0]` in die Browser-Konsole. **In Produktion (außerhalb der Vorschau) wird nichts geloggt und keiner dieser Fensterzugriffe ausgeführt** — die Logging-Berechtigung ist zusätzlich auf Debug-Umgebungen beschränkt.

| # | Bedingung | Meldung (sinngemäß) |
|---|---|---|
| D1 | `window.utag.link` existiert (Tealium) | Das Urteil geht als `fraud0_scoring_result` an `utag.link`; die Data-Layer-Events feuern auf dieser Seite **nicht**. |
| D2 | `window.dataLayer` existiert, ist aber kein Array | Kritisch: fz.js wirft einen Fehler; kein Urteil wird zurückgeschrieben. |
| D3 | `window.fraud0` existiert, ist aber kein Array | Kritisch: die Conversion-Queue kann nicht andocken; Conversions gehen verloren. |
| D4 | Page View feuert erstmals, aber `window.F0Loaded` ist bereits `true` | Doppelinstallation (Body-Embed, Legacy-`bt.fraud0.com`-Snippet oder zweiter Tag) — nur eine Quelle behalten. |
| D5 | Page View feuert ein zweites Mal auf derselben Seite | Doppelte Auslösung; der First-Hit-Pixel wird unterdrückt (höchstens einmal pro Seite). Trigger prüfen — All Pages genügt, History Change ist falsch. |
| D6 | Conversion feuert, bevor der Main Tag lief | Hinweis (keine Warnung): die Conversion wird in der `window.fraud0`-Queue gehalten und gesendet, sobald fz.js lädt. |
| D7 | Conversion-Typ ist `basic` | Legacy: wird als `generic` gemeldet, mögliche Doppelzählung — sprechenden Typ bevorzugen. |
| D8 | Die aufgelöste Customer ID ist unplausibel (nicht 36 Zeichen / Bindestriche falsch) | fraud0 verwirft Requests mit ungültiger `cid` — GTM-Variable prüfen. Der Tag feuert trotzdem (nur Log). |

## Preflight-Checkliste

Diese Liste einmal pro Site durchgehen — etwa 10 Minuten mit Browser-DevTools plus GTM-Vorschaumodus:

1. Der Page-View-Tag feuert auf **allen** Seiten, Tag-Priorität **1000**.
2. Netzwerk: `fz.js?cid=…` und `pixel?cid=…&cb=…` liefern beide Status **200/204**.
3. Netzwerk: **zwei POSTs** an `/api/v2/event` bei frischem Seitenaufruf (Minimal-Event und Voll-Datensatz).
4. Genau **ein** `fraud0`-Event pro Seitenaufruf im Data Layer (eines mehr pro SPA-Routenwechsel ist erwartet).
5. Cookies `f0_uid` und `f0_sid` sind gesetzt (host-only, 365 Tage / 1 Tag).
6. **Kein zweites** fraud0-Script im DOM (kein Body-Embed oder Legacy-`bt.fraud0.com`-Snippet parallel).
7. Kein `window.utag` auf der Seite — sonst geht das Urteil an Tealium statt in den Data Layer.
8. `window.dataLayer` ist ein **Array**.
9. Der Data-Layer-Name des GTM-Containers ist der Standard `dataLayer` (sonst die [Brücke](#was-fraud0-auf-die-seite-zurückschreibt) einbauen).
10. Der Conversion-Tag feuert **genau einmal** pro Conversion und erzeugt ein `CONVERSION`-Event (dritter POST an `/api/v2/event`).

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

Lesehilfe: Mehr als ein Eintrag in `fraud0Scripts` = Doppelinstallation. `tealiumPresent: true` = die Data-Layer-Events feuern auf dieser Seite nicht. `lastVerdict: '(no verdict yet)'` kurz nach dem Laden ist normal — dauerhaft nicht. In einer SPA wächst `fraud0Events` mit jedem Routenwechsel — das ist erwartetes Verhalten, kein Fehler.

## Einschränkungen

Bewusste Grenzen dieser Vorlage, jeweils mit Begründung:

- **Nur Web-Container.** Die Vorlage läuft in clientseitigen GTM-Web-Containern und spricht immer direkt `api.fraud0.com` an. Eine **SGTM-Proxy-Domain ist nicht konfigurierbar** — der feste Endpunkt hält die Berechtigungsliste minimal und prüfbar. Wer fraud0 über einen eigenen Server-Side-GTM-Endpoint proxied, bleibt beim dokumentierten SGTM-Setup statt des Page-View-Tags dieser Vorlage.
- **Tealium-Sites erhalten keine Data-Layer-Events** — fz.js liefert das Urteil über `utag.link` aus und endet (siehe [Was fraud0 zurückschreibt](#was-fraud0-auf-die-seite-zurückschreibt)). Das ist Verhalten von fz.js, nicht der Vorlage.
- **Container mit eigenem Data-Layer-Namen** brauchen das Brückensnippet aus [Was fraud0 zurückschreibt](#was-fraud0-auf-die-seite-zurückschreibt) — der Zielname `window.dataLayer` ist in fz.js fest verdrahtet.
- **Kein Umsatz-/Währungsfeld.** Die fraud0-Conversion-Schnittstelle nimmt nur Typ und optionale ID an; die Vorlage kann keine Felder ergänzen, die das Datenmodell nicht hat.
- **`setCustomerUserId` wird von der Vorlage nicht abgedeckt.** `window.fraud0.setCustomerUserId(…)` ist eine *Funktion*, die erst nach der fz.js-Initialisierung existiert — sie ist **nicht** über die Queue nachspielbar; ein Vorlagen-Tag würde je nach Ladezeitpunkt still scheitern. Stattdessen ein Custom-HTML-Tag mit dem Ready-Callback verwenden:

  ```html
  <script>
  (function () {
    function setId() { window.fraud0.setCustomerUserId('EURE-USER-ID'); }
    if (window.fraud0Ready === true) { setId(); }
    else { (window.fraud0ReadyCallbacks = window.fraud0ReadyCallbacks || []).push(setId); }
  })();
  </script>
  ```

- **Der Legacy-Host `bt.fraud0.com` wird von der Vorlage nicht bedient.** Bestandskunden, deren Embed noch von `bt.fraud0.com` lädt, sollten den Page-View-Tag dieser Vorlage **nicht** parallel betreiben — fz.js initialisiert nur einmal (`window.F0Loaded`), die zweite Kopie ist ein unnötiger Download und mit hoher Wahrscheinlichkeit ein Konfigurationsfehler (die Vorlage warnt im Vorschaumodus, D4).
- **Kein „Verdict Relay"-Tag-Typ** (Status-Cookie schreiben, `f0_status_changed` pushen): die Vorlage selbst schreibt keine Cookies. Das Muster ist als optionales Custom-HTML-Rezept unter [Timing](#wann-das-urteil-eintrifft-timing) dokumentiert.
- **Keine Consent-Mode-APIs** in der Vorlage — fraud0 muss einwilligungsunabhängig laufen; eine Consent-Prüfung im Tag wäre inhaltlich falsch (siehe [Setup-Muster und Consent](#setup-muster-und-consent)).
- **Keine zusätzliche Variablen-Vorlage** (z. B. zum Auslesen des Urteils): die Community Template Gallery erlaubt genau eine Vorlage pro Repository.
- Vorlagen können keine Tag-Priorität vorgeben; bitte manuell setzen (1000 / 800).

## Fehlerbehebung

Zuerst die [Preflight-Checkliste](#preflight-checkliste) durchgehen — sie deckt die häufigen Fälle systematisch ab. Zusätzlich:

- **Tag feuert, aber nichts kommt in fraud0 an:** Customer ID (UUID) prüfen, dann im Netzwerk-Panel nach Requests an `api.fraud0.com` schauen (`pixel` und `fz.js`). Im Vorschaumodus auf `[fraud0]`-Diagnosen in der Konsole achten.
- **Requests blockiert:** [CSP-Freigabe](#content-security-policy-1) und Ad-Blocker prüfen; siehe [Verify & Connect](https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted03/).
- **Conversions fehlen:** Der Main Tag muss auch auf der Bestätigungsseite feuern (All-Pages-Trigger), der Conversion-Tag danach (Priorität 800 < 1000). Feuert der Conversion-Tag zuerst, geht nichts verloren — die Queue hält die Conversion, bis fz.js lädt (Diagnose D6).
- **fraud0 sieht nur einwilligende Besucher:** der Main Tag (oder der GTM-Container selbst) hängt an einem Consent-Gate — siehe [Setup-Muster und Consent](#setup-muster-und-consent).

## Entwicklung & Tests

Die Vorlage enthält Unit-Tests (20 Szenarien) für Pixel, Script-Injection, alle Conversion-Varianten, beide Deduplizierungs-Guards, die Vorschaumodus-Diagnosen und die Fehlerpfade. Ausführen: `template.tpl` im GTM-Vorlagen-Editor importieren (**Vorlagen → Neu → Importieren**), Tab **Tests** öffnen, **▶ Tests ausführen** klicken.

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
