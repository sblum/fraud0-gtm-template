# fraud0 Tag Template for Google Tag Manager

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Official Google Tag Manager (web) tag template for [fraud0](https://www.fraud0.com) — invalid traffic and bot detection. One template covers both parts of the fraud0 onsite setup:

- **Page View (fraud0 Main Tag):** loads the fraud0 detection script and immediately fires the first-hit pixel on every page.
- **Conversion Event:** reports conversions from your confirmation pages so the fraud0 detection model can identify false positives.

*Deutsche Version siehe unten / German version below:* [→ Deutsch](#fraud0-tag-vorlage-für-google-tag-manager-deutsch)

---

## Contents

- [How it works](#how-it-works)
- [Installation](#installation)
- [Setup — Page View (Main Tag)](#setup--page-view-main-tag)
- [Setup — Conversion Events](#setup--conversion-events)
- [Field reference](#field-reference)
- [Conversion types](#conversion-types)
- [Template permissions](#template-permissions)
- [Consent, CSP & privacy notes](#consent-csp--privacy-notes)
- [Limitations](#limitations)
- [Troubleshooting](#troubleshooting)
- [Development & tests](#development--tests)
- [Support](#support)
- [License](#license)

## How it works

**Page View (Main Tag).** The tag immediately fires a 1×1 tracking pixel (`https://api.fraud0.com/api/v2/pixel?cid=…&cb=…`) and asynchronously loads the fraud0 detection script (`https://api.fraud0.com/api/v2/fz.js?cid=…`). The pixel fires whether or not the JavaScript ever finishes loading — this is what allows fraud0 to detect bots that abandon the page within the first few hundred milliseconds.

**Conversion Event.** The tag pushes the conversion into the `window.fraud0` queue (equivalent to the documented snippet `fraud0.push(['purchase', 'order123'])`) and additionally ensures the detection script is present. Script loading is deduplicated by URL, so the script is only loaded once per page even when the Main Tag and several Conversion Event tags fire together.

The template only communicates with `api.fraud0.com`. No cookies are set by the template itself.

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
5. Set **Triggering** to **All Pages** (or an equivalent trigger that fires unconditionally on every page view).
6. Save and publish.

> **Important:** fraud0 should run *before* any consent gate. If your GTM container itself only loads after consent, bots that reject consent become invisible to detection. See the [implementation guide](https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted01/) for the decision matrix (SGTM / direct embed / standard GTM).

## Setup — Conversion Events

Add one tag per conversion type, fired **only on confirmation pages** (post-checkout, post-form-submit, post-signup):

1. **Tags → New → Tag Configuration** → choose **fraud0**.
2. Enter the same **fraud0 Customer ID (cid)**.
3. Set Tag Type to **Conversion Event**.
4. Pick a **Conversion Type** (see table below) and optionally a **Conversion ID**, typically a GTM variable such as `{{Transaction ID}}` or a form name.
5. Open **Advanced Settings** and set **Tag firing priority** to **800**.
6. Set **Triggering** to your confirmation-page trigger (URL-based or a custom event such as `purchase` from your e-commerce data layer).
7. Save and publish.

If a single confirmation page represents more than one conversion (e.g. purchase + newsletter signup), create one tag per conversion and fire both on that page.

## Field reference

| Field | Shown when | Required | Description |
|---|---|---|---|
| fraud0 Customer ID (cid) | always | yes | Your fraud0 Customer ID (UUID) from the dashboard. Accepts a GTM variable. |
| Tag Type | always | yes | **Page View (fraud0 Main Tag)** — default — or **Conversion Event**. |
| Conversion Type | Tag Type = Conversion Event | yes | `Basic`, `Lead`, `Purchase`, `Signup` or `Custom`. |
| Custom Conversion Type | Conversion Type = Custom | yes | Identifier such as `trial_started`, `whitepaper_download`, `quote_requested`. Letters, digits, `_`, `-`. |
| Conversion ID (optional) | Tag Type = Conversion Event | no | Unique identifier for this conversion instance (order ID, form name, signup ID). Enables per-conversion reporting. Ignored for Basic. |

## Conversion types

| Type | Queued as | Typical Conversion ID |
|---|---|---|
| Basic conversion | `fraud0.push([1])` | — (not used) |
| Lead | `fraud0.push(['lead', id])` | form name, e.g. `contact_form` |
| Purchase | `fraud0.push(['purchase', id])` | order ID, e.g. `{{Transaction ID}}` |
| Signup | `fraud0.push(['signup', id])` | signup/user ID |
| Custom | `fraud0.push(['<your_type>', id])` | anything that identifies the instance |

Without a Conversion ID, only the type is pushed, e.g. `fraud0.push(['lead'])`.

## Template permissions

The template requests the minimum permissions needed:

| Permission | Scope | Why |
|---|---|---|
| Injects scripts | `https://api.fraud0.com/api/v2/*` | Loads the fraud0 detection script `fz.js`. |
| Sends pixels | `https://api.fraud0.com/api/v2/*` | Fires the first-hit 1×1 pixel of the Main Tag. |
| Accesses global variables | `fraud0` (read/write) | Creates/uses the `window.fraud0` queue for conversion events. |

## Consent, CSP & privacy notes

- fraud0 is designed to run independently of consent decisions; see fraud0's notes on the [legal basis](https://help.fraud0.com/3-general-faq/data-processing-privacy-practices/legal-compliance/legal01/) and the [DPA](https://www.fraud0.com/dpa/). Clarify the setup with your data protection officer.
- If your site uses a strict Content Security Policy, allow-list `api.fraud0.com` (`script-src`, `img-src`, `connect-src`). A network status of `blocked: CSP` indicates a missing allow-list entry ([FAQ](https://help.fraud0.com/1-onsite/g-onsite-faq/technical-queries/implementation06/)).
- The template itself sets no cookies and reads no personal data; data collection is performed by the fraud0 detection script.

## Limitations

- **Web containers only.** This template runs in client-side GTM web containers. If you proxy fraud0 through your own Server-Side GTM endpoint (Variant A of the implementation guide), keep using the documented SGTM setup — this template always talks to `api.fraud0.com` directly.
- **Do not combine** this template's Page View tag with an additional hard-coded fraud0 Main Tag (body embed / Custom HTML) on the same pages, otherwise the detection script may load twice.
- Tag firing priority cannot be preset by templates; set it manually as described above (1000 / 800).

## Troubleshooting

- **Tag fires but nothing shows in fraud0:** verify the Customer ID (UUID), then check the network panel for requests to `api.fraud0.com` (`pixel` and `fz.js`).
- **Requests blocked:** check CSP allow-listing and ad-blocker behaviour; see the [Verify & Connect guide](https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted03/).
- **Conversions missing:** make sure the Main Tag also fires on the confirmation page (All Pages trigger) and that the conversion tag fires after it (priority 800 < 1000).
- **GTM loads after consent:** fraud0 will be blind to the users/bots who reject consent — fix the GTM bootstrap or use another embed variant.

## Development & tests

The template ships with unit tests (10 scenarios) covering the pixel, script injection, all conversion variants and failure paths. To run them: import `template.tpl` into the GTM Template Editor (**Templates → New → Import**), open the **Tests** tab and click **▶ Run Tests**.

Contributions: please open an issue or pull request in this repository. For a new gallery version, commit the change, then add the commit SHA with change notes to the top of `versions` in `metadata.yaml`.

## Support

- fraud0 Knowledge Center: https://help.fraud0.com
- Implementation guide: https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted01/
- Conversion Tag guide: https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted02/
- Support: support@fraud0.com
- Bugs in this template: please use the GitHub Issues of this repository.

## License

[Apache 2.0](LICENSE) — Copyright 2026 fraud0 GmbH

---

# fraud0 Tag-Vorlage für Google Tag Manager (Deutsch)

Offizielle Google-Tag-Manager-Vorlage (Web) für [fraud0](https://www.fraud0.com) — Erkennung von Invalid Traffic und Bots. Eine Vorlage deckt beide Teile des fraud0-Onsite-Setups ab:

- **Page View (fraud0 Main Tag):** lädt das fraud0-Erkennungsscript und feuert sofort den First-Hit-Pixel auf jeder Seite.
- **Conversion Event:** meldet Conversions von Bestätigungsseiten, damit das fraud0-Modell False Positives erkennen kann.

## Funktionsweise

**Page View (Main Tag).** Der Tag feuert sofort einen 1×1-Pixel (`https://api.fraud0.com/api/v2/pixel?cid=…&cb=…`) und lädt asynchron das Erkennungsscript (`https://api.fraud0.com/api/v2/fz.js?cid=…`). Der Pixel feuert unabhängig davon, ob das JavaScript jemals fertig lädt — so erkennt fraud0 auch Bots, die die Seite in den ersten Millisekunden wieder verlassen.

**Conversion Event.** Der Tag pusht die Conversion in die `window.fraud0`-Queue (äquivalent zum dokumentierten Snippet `fraud0.push(['purchase', 'order123'])`) und stellt zusätzlich sicher, dass das Erkennungsscript vorhanden ist. Das Laden ist pro URL dedupliziert — das Script wird also auch dann nur einmal geladen, wenn Main Tag und mehrere Conversion-Tags auf derselben Seite feuern.

Die Vorlage kommuniziert ausschließlich mit `api.fraud0.com` und setzt selbst keine Cookies.

## Installation

**Aus der Community Template Gallery (empfohlen):** In eurem GTM-Web-Container unter **Vorlagen → Tag-Vorlagen → Galerie durchsuchen** nach **fraud0** suchen, **Zum Arbeitsbereich hinzufügen** klicken und die Berechtigungen bestätigen.

**Manueller Import:** `template.tpl` aus diesem Repository herunterladen, in GTM unter **Vorlagen → Tag-Vorlagen → Neu** über das ⋮-Menü → **Importieren** einlesen und speichern.

## Einrichtung — Page View (Main Tag)

Den Main Tag genau einmal anlegen und auf **jeder** Seite feuern:

1. **Tags → Neu → Tag-Konfiguration** → **fraud0** wählen.
2. **fraud0 Customer ID (cid)** eintragen — zu finden im [fraud0 Dashboard](https://admin.fraud0.com/settings?tab=tag_management) unter **Settings → Tag Management** (der `cid`-Wert im Tag-Snippet, eine UUID).
3. Tag Type auf dem Standard **Page View (fraud0 Main Tag)** belassen.
4. Unter **Erweiterte Einstellungen** die **Priorität der Tag-Auslösung** auf **1000** setzen, damit fraud0 vor allen anderen Tags feuert.
5. **Trigger: All Pages** (bzw. ein Trigger, der bedingungslos auf jedem Seitenaufruf feuert).
6. Speichern und veröffentlichen.

> **Wichtig:** fraud0 sollte *vor* jeder Consent-Abfrage laufen. Lädt der GTM-Container selbst erst nach Consent, bleiben Bots, die Consent ablehnen, unsichtbar. Siehe [Implementierungs-Guide](https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted01/) mit Entscheidungsmatrix (SGTM / direkter Embed / Standard-GTM).

## Einrichtung — Conversion Events

Pro Conversion-Typ einen Tag anlegen, der **nur auf Bestätigungsseiten** feuert (nach Checkout, Formular-Absenden, Registrierung):

1. **Tags → Neu → Tag-Konfiguration** → **fraud0** wählen.
2. Dieselbe **fraud0 Customer ID (cid)** eintragen.
3. Tag Type auf **Conversion Event** stellen.
4. **Conversion Type** wählen (Tabelle oben) und optional eine **Conversion ID** angeben — typischerweise eine GTM-Variable wie `{{Transaction ID}}` oder ein Formularname.
5. Unter **Erweiterte Einstellungen** die **Priorität der Tag-Auslösung** auf **800** setzen.
6. **Trigger:** euer Bestätigungsseiten-Trigger (URL-basiert oder Custom Event wie `purchase` aus dem E-Commerce-Data-Layer).
7. Speichern und veröffentlichen.

Repräsentiert eine Bestätigungsseite mehrere Conversions (z. B. Kauf + Newsletter-Anmeldung), einfach mehrere Tags anlegen und beide dort feuern.

## Felder

| Feld | Sichtbar wenn | Pflicht | Beschreibung |
|---|---|---|---|
| fraud0 Customer ID (cid) | immer | ja | fraud0 Customer ID (UUID) aus dem Dashboard. GTM-Variable möglich. |
| Tag Type | immer | ja | **Page View (fraud0 Main Tag)** — Standard — oder **Conversion Event**. |
| Conversion Type | Tag Type = Conversion Event | ja | `Basic`, `Lead`, `Purchase`, `Signup` oder `Custom`. |
| Custom Conversion Type | Conversion Type = Custom | ja | Bezeichner wie `trial_started`, `whitepaper_download`, `quote_requested`. Buchstaben, Ziffern, `_`, `-`. |
| Conversion ID (optional) | Tag Type = Conversion Event | nein | Eindeutige Kennung der Conversion-Instanz (Bestell-ID, Formularname, Signup-ID). Ermöglicht Reporting pro Conversion. Bei Basic ohne Wirkung. |

## Berechtigungen der Vorlage

| Berechtigung | Umfang | Zweck |
|---|---|---|
| Scripts einfügen | `https://api.fraud0.com/api/v2/*` | Lädt das fraud0-Erkennungsscript `fz.js`. |
| Pixel senden | `https://api.fraud0.com/api/v2/*` | Feuert den First-Hit-Pixel des Main Tags. |
| Globale Variablen | `fraud0` (lesen/schreiben) | Erstellt/nutzt die `window.fraud0`-Queue für Conversion Events. |

## Consent, CSP & Datenschutz

- fraud0 ist darauf ausgelegt, unabhängig von Consent-Entscheidungen zu laufen; siehe fraud0-Hinweise zur [Rechtsgrundlage](https://help.fraud0.com/3-general-faq/data-processing-privacy-practices/legal-compliance/legal01/) und den [AVV/DPA](https://www.fraud0.com/dpa/). Setup mit dem Datenschutzbeauftragten abstimmen.
- Bei strikter Content Security Policy `api.fraud0.com` freigeben (`script-src`, `img-src`, `connect-src`). Netzwerkstatus `blocked: CSP` deutet auf einen fehlenden Eintrag hin ([FAQ](https://help.fraud0.com/1-onsite/g-onsite-faq/technical-queries/implementation06/)).

## Einschränkungen

- **Nur Web-Container.** Wer fraud0 über einen eigenen Server-Side-GTM-Endpoint proxied (Variante A des Guides), bleibt beim dokumentierten SGTM-Setup — diese Vorlage spricht immer direkt `api.fraud0.com` an.
- Den Page-View-Tag dieser Vorlage **nicht** mit einem zusätzlich hart eingebauten fraud0 Main Tag (Body-Embed / Custom HTML) auf denselben Seiten kombinieren, sonst kann das Erkennungsscript doppelt laden.
- Vorlagen können keine Tag-Priorität vorgeben; bitte manuell setzen (1000 / 800).

## Fehlerbehebung

- **Tag feuert, aber nichts kommt in fraud0 an:** Customer ID (UUID) prüfen, dann im Netzwerk-Panel nach Requests an `api.fraud0.com` schauen (`pixel` und `fz.js`).
- **Requests blockiert:** CSP-Freigabe und Ad-Blocker prüfen; siehe [Verify & Connect](https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted03/).
- **Conversions fehlen:** Der Main Tag muss auch auf der Bestätigungsseite feuern (All-Pages-Trigger), der Conversion-Tag danach (Priorität 800 < 1000).
- **GTM lädt erst nach Consent:** fraud0 ist dann blind für Nutzer/Bots, die Consent ablehnen — GTM-Bootstrap anpassen oder andere Embed-Variante wählen.

## Entwicklung & Tests

Die Vorlage enthält Unit-Tests (10 Szenarien) für Pixel, Script-Injection, alle Conversion-Varianten und Fehlerpfade. Ausführen: `template.tpl` im GTM-Vorlagen-Editor importieren (**Vorlagen → Neu → Importieren**), Tab **Tests** öffnen, **▶ Tests ausführen** klicken.

Für eine neue Gallery-Version: Änderung committen, dann den Commit-SHA mit Change Notes oben in `versions` der `metadata.yaml` eintragen.

## Support

Knowledge Center: https://help.fraud0.com · Implementierung: [Main Tag](https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted01/) / [Conversion Tag](https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted02/) · E-Mail: support@fraud0.com · Bugs in dieser Vorlage: GitHub Issues dieses Repositories.

## Lizenz

[Apache 2.0](LICENSE) — Copyright 2026 fraud0 GmbH
