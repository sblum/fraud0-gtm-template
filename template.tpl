___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "fraud0 Tag",
  "categories": [
    "ANALYTICS",
    "CONVERSIONS"
  ],
  "brand": {
    "id": "brand_dummy",
    "displayName": "fraud0",
    "thumbnail": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAALQAAAC0CAIAAACyr5FlAAACa0lEQVR42u3dO27CQBRA0RC5duGWkh2wJBbGktgBZdoUbGBSWEqi8JFjzd/nVFEkQIKbN3gMzi6E8AaPvHsKEAfiQByIA3EgDsSBOBAH4gBxIA7EgTgQB+JAHIgDcSAOEAfiQByIA3EgDsSBOBAH4gBxIA7EgTgQB+JAHIgDcSAOxAHiQByIA3EgDsRBIwZPwb3D5Zz/Qa/Hkzj+Gqd9xHu7fX6Iu4c44mZBP+85lCEOZYhDGeJQhjiUQd44lOFQVhYmhzLEoQxxKONHkRMrddqFEGooY905kXHazzecH27FndSfQsETckO7Zfy+4bp7WFhGopen/i59nmOLI0Ectb88JgeOVtpU9m/XsmJZsayYHJYVxGFZweSw+rzkeysR+uh1Aq2PI+J5tVh3VepLK4fLucs+ulpWfEJAHIgDcSAOxIE4EAeL9LoJJo4Iet1ft32eqY8Wp4vJwTYmR7pzK8/+7vs+YTukeCWyfW+l+PvN6/HUcR+WFcSBOBAH4kAciIPG2D7PpMXtEJMDkyOZeZP04S5q65unJkecPv71e3HgaAVxIA4QB+JAHIgDcVAJ2+dpvdgkdR1SLCuIgzwrjjgwORBHi8oeLzhaweTo+i3hZq99bnLwVJL/K9v0JRgKzonvSTZ/YnnJJdWT/vdTkyPO8xj3ceefi2+EiANxIA7EgTgQB+JAHIgDcSAOuJPkxNty47Sv/MLn4gDLCuJAHIgDcSAOxIE4EAfiAHEgDsSBOBAH4kAciANxIA4QB+JAHIgDcSAOxIE4EAfiQBwgDsSBOBAH4kAciANxIA7EAeJAHIgDcSAOxEH9vgAOqI7VXbokGQAAAABJRU5ErkJggg\u003d\u003d"
  },
  "description": "Fires the fraud0 Main Tag (detection script + first-hit pixel) or reports a conversion event, depending on configuration. Detects bots and invalid traffic. Requires a fraud0 account.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "customerId",
    "displayName": "fraud0 Customer ID (cid)",
    "simpleValueType": true,
    "alwaysInSummary": true,
    "help": "Your fraud0 Customer ID — a UUID such as 12345678-90ab-cdef-1234-567890abcdef. You can find it in the fraud0 Dashboard under Settings → Tag Management: it is the value of the cid parameter in the tag snippet. A Google Tag Manager variable (e.g. {{fraud0 cid}}) is also accepted.",
    "notSetText": "You must set the fraud0 Customer ID.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      },
      {
        "type": "REGEX",
        "args": [
          "^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|\\{\\{.+\\}\\})$"
        ],
        "errorMessage": "Enter a valid fraud0 Customer ID (UUID format) or a Google Tag Manager variable."
      }
    ]
  },
  {
    "type": "RADIO",
    "name": "tagType",
    "displayName": "Tag Type",
    "simpleValueType": true,
    "defaultValue": "page_view",
    "radioItems": [
      {
        "value": "page_view",
        "displayValue": "Page View (fraud0 Main Tag)",
        "help": "Loads the fraud0 detection script and immediately fires the first-hit pixel. Use exactly one Page View tag, triggered on All Pages. Set the tag firing priority to 1000 (Advanced Settings) so it fires before other tags."
      },
      {
        "value": "conversion",
        "displayValue": "Conversion Event",
        "help": "Reports a conversion to fraud0 so the detection model can identify false positives. Fire it on confirmation pages only (post-checkout, post-signup, post-form-submit). Recommended tag firing priority: 800."
      }
    ]
  },
  {
    "type": "SELECT",
    "name": "conversionType",
    "displayName": "Conversion Type",
    "simpleValueType": true,
    "defaultValue": "purchase",
    "help": "Choose one of the predefined fraud0 conversion types or define a custom type. A descriptive type that is unique per conversion kind is what makes conversions separable in fraud0 reporting — the conversion interface has no revenue or currency field, only the type and an optional ID are transmitted. Avoid 'Basic conversion': it is a legacy mode that fraud0 reports as 'generic' (no distinct type in reporting) and that can be double-counted if it is queued before the detection script initializes. Use it only when no descriptive type is possible.",
    "enablingConditions": [
      {
        "paramName": "tagType",
        "paramValue": "conversion",
        "type": "EQUALS"
      }
    ],
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "selectItems": [
      {
        "value": "purchase",
        "displayValue": "Purchase"
      },
      {
        "value": "lead",
        "displayValue": "Lead"
      },
      {
        "value": "signup",
        "displayValue": "Signup"
      },
      {
        "value": "custom",
        "displayValue": "Custom conversion type"
      },
      {
        "value": "basic",
        "displayValue": "Basic conversion (legacy, reported as 'generic')"
      }
    ],
    "subParams": [
      {
        "type": "TEXT",
        "name": "customConversionType",
        "displayName": "Custom Conversion Type",
        "simpleValueType": true,
        "help": "A short identifier for this conversion type, e.g. trial_started, subscription_renewed, whitepaper_download, quote_requested or appointment_booked. Use one identifier per conversion kind so the types stay separable in fraud0 reporting. Allowed characters: letters, digits, underscore, hyphen. The values '1' and 'generic' are reserved by fraud0. A Google Tag Manager variable is also accepted.",
        "enablingConditions": [
          {
            "paramName": "conversionType",
            "paramValue": "custom",
            "type": "EQUALS"
          }
        ],
        "valueValidators": [
          {
            "type": "NON_EMPTY"
          },
          {
            "type": "REGEX",
            "args": [
              "^([a-zA-Z0-9_-]+|\\{\\{.+\\}\\})$"
            ],
            "errorMessage": "Use letters, digits, underscore or hyphen (or a Google Tag Manager variable)."
          },
          {
            "type": "REGEX",
            "args": [
              "^(?!(1|generic)$).*$"
            ],
            "errorMessage": "'1' and 'generic' are reserved by fraud0 (internal representation of Basic/legacy conversions). Choose a different type name."
          }
        ]
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "conversionId",
    "displayName": "Conversion ID (optional)",
    "simpleValueType": true,
    "help": "Optional unique identifier for this conversion instance — e.g. the order ID for Purchase ({{Transaction ID}}), the form name for Lead (contact_form), or the signup ID for Signup. Enables per-conversion reporting in fraud0 (there is no revenue or currency field — the ID is the only per-instance detail). Ignored for Basic conversions.",
    "enablingConditions": [
      {
        "paramName": "tagType",
        "paramValue": "conversion",
        "type": "EQUALS"
      }
    ]
  },
  {
    "type": "CHECKBOX",
    "name": "dedupeConversion",
    "checkboxText": "Send this conversion only once per page",
    "simpleValueType": true,
    "defaultValue": true,
    "help": "Protects against duplicate conversion pushes when the same trigger fires more than once on a page (e.g. a form-submit trigger plus a confirmation-page trigger). De-duplication is per page and per combination of Conversion Type and Conversion ID — a different ID is always sent. Disable only if the same conversion should intentionally be reported multiple times on one page.",
    "enablingConditions": [
      {
        "paramName": "tagType",
        "paramValue": "conversion",
        "type": "EQUALS"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

/**
 * fraud0 — Invalid Traffic & Bot Detection
 * https://www.fraud0.com | https://help.fraud0.com
 *
 * Page View (Main Tag): loads the fraud0 detection script (fz.js) and fires
 * the first-hit 1x1 pixel immediately, so bots that abandon the page before
 * JavaScript executes are still detected. The pixel is sent at most once per
 * page, even if the tag fires again.
 *
 * Conversion Event: pushes a conversion into the window.fraud0 queue so the
 * detection model can identify false positives, and ensures the detection
 * script is present (one script element per page via the injectScript cache
 * token). Identical conversions (same type and ID) are de-duplicated per
 * page by default.
 *
 * Diagnostics: in GTM preview/debug mode the tag checks the page for known
 * integration pitfalls (Tealium container, non-array dataLayer or fraud0
 * queue, duplicate installation, duplicate firing, legacy conversion type,
 * implausible Customer ID) and logs [fraud0] messages to the console. In
 * production nothing is logged and no additional window reads happen.
 */

const copyFromWindow = require('copyFromWindow');
const createQueue = require('createQueue');
const encodeUriComponent = require('encodeUriComponent');
const generateRandom = require('generateRandom');
const getContainerVersion = require('getContainerVersion');
const getTimestampMillis = require('getTimestampMillis');
const getType = require('getType');
const injectScript = require('injectScript');
const logToConsole = require('logToConsole');
const makeString = require('makeString');
const sendPixel = require('sendPixel');
const templateStorage = require('templateStorage');

const API_BASE = 'https://api.fraud0.com/api/v2/';

// templateStorage keys. The storage lives for the lifetime of the page and is
// shared across all firings of this template; it creates no window globals.
const PIXEL_SENT_KEY = 'f0_pixel_sent';
const CONVERSION_KEY_PREFIX = 'f0_conv_';
const DIAG_KEY_PREFIX = 'f0_diag_';

// ---------------------------------------------------------------------------
// Debug-only diagnostics (GTM preview/debug mode).
// Production stays silent: the "logging" permission is limited to debug
// environments, and every check that reads the window is gated on isDebug.
// ---------------------------------------------------------------------------

const containerVersion = getContainerVersion();
const isDebug = !!(containerVersion &&
    (containerVersion.debugMode || containerVersion.previewMode));

// Logs a diagnostic message for this firing (debug/preview mode only).
const diag = (message) => {
  if (isDebug) {
    logToConsole('[fraud0] ' + message);
  }
};

// Logs a page-level diagnostic at most once per page, no matter how many
// fraud0 tags fire on it (Page View plus several Conversion Events).
const diagOncePerPage = (key, message) => {
  if (!isDebug || templateStorage.getItem(DIAG_KEY_PREFIX + key) === true) {
    return;
  }
  templateStorage.setItem(DIAG_KEY_PREFIX + key, true);
  logToConsole('[fraud0] ' + message);
};

// D1-D3: environment checks. They read window globals, so they run in
// debug/preview mode only.
const runEnvironmentChecks = () => {
  // D1 — Tealium takes precedence in fz.js: the verdict goes to utag.link
  // and the dataLayer events never fire on such pages.
  const utag = copyFromWindow('utag');
  if (getType(utag) === 'object' && utag.link) {
    diagOncePerPage('tealium', 'Tealium detected (window.utag.link): fraud0 ' +
        'delivers its verdict via utag.link as "fraud0_scoring_result". The ' +
        'dataLayer events "fraud0" and "f0_event_invalid_traffic" will NOT ' +
        'fire on this page. See README section "What fraud0 writes back to ' +
        'the page".');
  }

  // D2 — fz.js requires window.dataLayer to be an array and throws otherwise.
  const dataLayer = copyFromWindow('dataLayer');
  if (dataLayer !== undefined && dataLayer !== null &&
      getType(dataLayer) !== 'array') {
    diagOncePerPage('datalayer', 'Critical: window.dataLayer exists but is ' +
        'not an array. The fraud0 detection script will throw and no ' +
        'verdict will be written back to the page. See README section ' +
        '"Preflight checklist".');
  }

  // D3 — fz.js hooks the conversion queue only if window.fraud0 is an array.
  const queue = copyFromWindow('fraud0');
  if (queue !== undefined && queue !== null && getType(queue) !== 'array') {
    diagOncePerPage('queue', 'Critical: window.fraud0 exists but is not an ' +
        'array. The conversion queue cannot attach and conversion events ' +
        'will be lost. See README section "Preflight checklist".');
  }
};

// D8 — plausibility check for the resolved Customer ID: UUID length and
// hyphen positions (sandboxed JS has no RegExp). Diagnostic only.
const isPlausibleCid = (value) => {
  if (value.length !== 36) {
    return false;
  }
  return value.charAt(8) === '-' && value.charAt(13) === '-' &&
      value.charAt(18) === '-' && value.charAt(23) === '-';
};

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

// The Customer ID is required for every tag type.
if (!data.customerId) {
  return data.gtmOnFailure();
}

const cidRaw = makeString(data.customerId);
const cid = encodeUriComponent(cidRaw);
const scriptUrl = API_BASE + 'fz.js?cid=' + cid;

if (isDebug) {
  runEnvironmentChecks();

  // D8 — log only, never gtmOnFailure: a future cid format change at fraud0
  // must not kill the tag.
  if (!isPlausibleCid(cidRaw)) {
    diag('The resolved fraud0 Customer ID does not look like a valid cid ' +
        '(expected a 36-character UUID, got "' + cidRaw + '"). fraud0 ' +
        'rejects requests with an invalid cid. Check the GTM variable. See ' +
        'README section "Preflight checklist".');
  }
}

if (data.tagType === 'conversion') {
  // Resolve the conversion type. An empty value falls back to the UI default
  // "purchase" so the tag never pushes an undefined type.
  const rawType = data.conversionType || 'purchase';
  const conversionType = rawType === 'custom' ?
      data.customConversionType : rawType;
  const isBasic = rawType === 'basic';

  if (!isBasic && !conversionType) {
    return data.gtmOnFailure();
  }

  if (isBasic) {
    // D7 — [1] is reported as "generic" and has a legacy double-count path.
    diag('Conversion type "Basic" is legacy: fraud0 reports it as ' +
        '"generic" (no distinct type in reporting) and, if it is queued ' +
        'before the detection script initializes, it can be counted twice. ' +
        'Prefer a descriptive conversion type. See README section ' +
        '"Conversion types".');
  }

  // D6 — informational only: the queue holds the conversion until fz.js
  // loads, nothing is lost. F0Loaded covers non-template installations.
  if (isDebug && templateStorage.getItem(PIXEL_SENT_KEY) !== true &&
      copyFromWindow('F0Loaded') !== true) {
    diag('Note: the fraud0 Main Tag has not run on this page yet. The ' +
        'conversion is kept in the window.fraud0 queue and is sent once ' +
        'the detection script loads.');
  }

  // G2 — de-duplicate identical conversions (same type AND ID) per page.
  // data.dedupeConversion is only false when the user unchecks the box.
  const dedupeKey = CONVERSION_KEY_PREFIX +
      (isBasic ? '1' : makeString(conversionType)) + '|' +
      (data.conversionId ? makeString(data.conversionId) : '');
  if (data.dedupeConversion !== false &&
      templateStorage.getItem(dedupeKey) === true) {
    diag('Duplicate conversion suppressed: the same conversion (type and ' +
        'ID) was already sent on this page. Uncheck "Send this conversion ' +
        'only once per page" on the tag if this is intentional.');
    return data.gtmOnSuccess();
  }

  // Queue the conversion for the detection script: window.fraud0.push([...])
  const fraud0Push = createQueue('fraud0');
  if (isBasic) {
    fraud0Push([1]);
  } else if (data.conversionId) {
    fraud0Push([makeString(conversionType), makeString(data.conversionId)]);
  } else {
    fraud0Push([makeString(conversionType)]);
  }
  templateStorage.setItem(dedupeKey, true);
} else {
  // Page View (Main Tag).
  if (templateStorage.getItem(PIXEL_SENT_KEY) === true) {
    // D5/G1 — the tag already fired on this page: suppress the first-hit
    // pixel so the signal is not double-counted. injectScript below still
    // runs (deduplicated by URL), so gtmOnSuccess is reported cleanly.
    diag('This Page View tag already fired on this page - the first-hit ' +
        'pixel is sent at most once per page. Check the triggering: one ' +
        '"All Pages" (Page View) trigger is enough; a History Change ' +
        'trigger is wrong for the Main Tag. See README section ' +
        '"Diagnostics".');
  } else {
    // D4 — first firing of this tag, but fz.js is already initialized:
    // there is a second fraud0 installation on the page.
    if (isDebug && copyFromWindow('F0Loaded') === true) {
      diag('The fraud0 detection script is already active on this page ' +
          '(window.F0Loaded is set) although this tag fires for the first ' +
          'time - most likely a duplicate installation (body embed, legacy ' +
          'bt.fraud0.com snippet or a second fraud0 tag). fz.js ' +
          'initializes only once; keep exactly one source. See README ' +
          'section "Limitations".');
    }

    // G1 — fire the first-hit pixel immediately, before the script loads,
    // and mark it as sent for this page.
    templateStorage.setItem(PIXEL_SENT_KEY, true);
    const cacheBuster = '0.' + generateRandom(100000000, 999999999) + '.' +
        getTimestampMillis();
    sendPixel(API_BASE + 'pixel?cid=' + cid + '&cb=' + cacheBuster);
  }
}

// Load the fraud0 detection script. The cacheToken (4th argument) is what
// makes injectScript reuse one script element per page - without it, every
// firing injects fz.js again (fz.js would still initialize only once via
// window.F0Loaded, but each extra element triggers another download).
injectScript(scriptUrl, data.gtmOnSuccess, data.gtmOnFailure, scriptUrl);


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "fraud0"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "utag"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "dataLayer"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "F0Loaded"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "inject_script",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://api.fraud0.com/api/v2/*"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_pixel",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://api.fraud0.com/api/v2/*"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_template_storage",
        "versionId": "1"
      },
      "param": []
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_container_data",
        "versionId": "1"
      },
      "param": []
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Page View fires first-hit pixel and loads detection script
  code: |-
    runCode(mockData);

    assertApi('sendPixel').wasCalled();
    assertThat(sentPixelUrl).contains('https://api.fraud0.com/api/v2/pixel?cid=12345678-90ab-cdef-1234-567890abcdef');
    assertThat(sentPixelUrl).contains('&cb=0.');
    assertThat(injectedScriptUrl).isEqualTo('https://api.fraud0.com/api/v2/fz.js?cid=12345678-90ab-cdef-1234-567890abcdef');
    assertApi('gtmOnSuccess').wasCalled();
- name: Page View does not queue conversion events
  code: |-
    runCode(mockData);

    assertThat(queuedEvents.length).isEqualTo(0);
- name: Conversion with type and ID queues both values
  code: |-
    mockData.tagType = 'conversion';
    mockData.conversionType = 'lead';
    mockData.conversionId = 'contact_form';
    runCode(mockData);

    assertThat(queuedEvents.length).isEqualTo(1);
    assertThat(queuedEvents[0].length).isEqualTo(2);
    assertThat(queuedEvents[0][0]).isEqualTo('lead');
    assertThat(queuedEvents[0][1]).isEqualTo('contact_form');
    assertApi('sendPixel').wasNotCalled();
    assertThat(injectedScriptUrl).isEqualTo('https://api.fraud0.com/api/v2/fz.js?cid=12345678-90ab-cdef-1234-567890abcdef');
    assertApi('gtmOnSuccess').wasCalled();
- name: Conversion without ID queues the type only
  code: |-
    mockData.tagType = 'conversion';
    mockData.conversionType = 'purchase';
    runCode(mockData);

    assertThat(queuedEvents.length).isEqualTo(1);
    assertThat(queuedEvents[0].length).isEqualTo(1);
    assertThat(queuedEvents[0][0]).isEqualTo('purchase');
- name: Basic conversion queues [1] and ignores the Conversion ID
  code: |-
    mockData.tagType = 'conversion';
    mockData.conversionType = 'basic';
    mockData.conversionId = 'should_be_ignored';
    runCode(mockData);

    assertThat(queuedEvents.length).isEqualTo(1);
    assertThat(queuedEvents[0].length).isEqualTo(1);
    assertThat(queuedEvents[0][0]).isEqualTo(1);
    assertApi('sendPixel').wasNotCalled();
- name: Custom conversion uses the custom type
  code: |-
    mockData.tagType = 'conversion';
    mockData.conversionType = 'custom';
    mockData.customConversionType = 'trial_started';
    mockData.conversionId = 'user-123';
    runCode(mockData);

    assertThat(queuedEvents[0][0]).isEqualTo('trial_started');
    assertThat(queuedEvents[0][1]).isEqualTo('user-123');
- name: Numeric Conversion ID is converted to a string
  code: |-
    mockData.tagType = 'conversion';
    mockData.conversionType = 'purchase';
    mockData.conversionId = 10001;
    runCode(mockData);

    assertThat(queuedEvents[0][1]).isEqualTo('10001');
- name: Missing Customer ID fails the tag and sends nothing
  code: |-
    mockData.customerId = undefined;
    runCode(mockData);

    assertApi('gtmOnFailure').wasCalled();
    assertApi('sendPixel').wasNotCalled();
    assertApi('injectScript').wasNotCalled();
    assertThat(queuedEvents.length).isEqualTo(0);
- name: Empty custom conversion type fails the tag
  code: |-
    mockData.tagType = 'conversion';
    mockData.conversionType = 'custom';
    mockData.customConversionType = undefined;
    runCode(mockData);

    assertApi('gtmOnFailure').wasCalled();
    assertThat(queuedEvents.length).isEqualTo(0);
- name: Script load failure calls gtmOnFailure
  code: |-
    mock('injectScript', (url, onSuccess, onFailure) => {
      onFailure();
    });
    runCode(mockData);

    assertApi('gtmOnFailure').wasCalled();
    assertApi('gtmOnSuccess').wasNotCalled();
- name: Page View fires the pixel only once per page
  code: |-
    runCode(mockData);
    runCode(mockData);

    assertThat(sentPixelCount).isEqualTo(1);
    assertThat(injectCount).isEqualTo(2);
    assertThat(injectedCacheToken).isEqualTo('https://api.fraud0.com/api/v2/fz.js?cid=12345678-90ab-cdef-1234-567890abcdef');
    assertApi('gtmOnSuccess').wasCalled();
- name: Conversion with default de-duplication pushes only once
  code: |-
    mockData.tagType = 'conversion';
    mockData.conversionType = 'lead';
    mockData.conversionId = 'contact_form';
    runCode(mockData);
    runCode(mockData);

    assertThat(queuedEvents.length).isEqualTo(1);
    assertApi('gtmOnSuccess').wasCalled();
- name: Conversion de-duplication keys on type and ID
  code: |-
    mockData.tagType = 'conversion';
    mockData.conversionType = 'purchase';
    mockData.conversionId = 'order-A';
    runCode(mockData);
    mockData.conversionId = 'order-B';
    runCode(mockData);

    assertThat(queuedEvents.length).isEqualTo(2);
    assertThat(queuedEvents[0][1]).isEqualTo('order-A');
    assertThat(queuedEvents[1][1]).isEqualTo('order-B');
- name: Disabled de-duplication sends identical conversions again
  code: |-
    mockData.tagType = 'conversion';
    mockData.conversionType = 'purchase';
    mockData.conversionId = 'order-1';
    mockData.dedupeConversion = false;
    runCode(mockData);
    runCode(mockData);

    assertThat(queuedEvents.length).isEqualTo(2);
- name: Tealium present logs exactly one warning and tag works normally
  code: |-
    containerVersion = {debugMode: true, previewMode: true};
    windowGlobals.utag = {link: () => {}};
    runCode(mockData);
    runCode(mockData);

    assertApi('sendPixel').wasCalled();
    assertApi('gtmOnSuccess').wasCalled();
    const tealiumWarnings = consoleMessages.filter(m => m.indexOf('Tealium') !== -1);
    assertThat(tealiumWarnings.length).isEqualTo(1);
- name: Non-array dataLayer logs a warning and tag continues
  code: |-
    containerVersion = {debugMode: true, previewMode: true};
    windowGlobals.dataLayer = {someKey: 'someValue'};
    runCode(mockData);

    assertApi('sendPixel').wasCalled();
    assertApi('gtmOnSuccess').wasCalled();
    const warnings = consoleMessages.filter(m => m.indexOf('window.dataLayer exists but is not an array') !== -1);
    assertThat(warnings.length).isEqualTo(1);
- name: F0Loaded already set logs a warning but pixel and injection still run
  code: |-
    containerVersion = {debugMode: true, previewMode: true};
    windowGlobals.F0Loaded = true;
    runCode(mockData);

    assertThat(sentPixelCount).isEqualTo(1);
    assertThat(injectedScriptUrl).isEqualTo('https://api.fraud0.com/api/v2/fz.js?cid=12345678-90ab-cdef-1234-567890abcdef');
    assertApi('gtmOnSuccess').wasCalled();
    const warnings = consoleMessages.filter(m => m.indexOf('F0Loaded') !== -1);
    assertThat(warnings.length).isEqualTo(1);
- name: No console output outside debug mode
  code: |-
    windowGlobals.utag = {link: () => {}};
    windowGlobals.dataLayer = {someKey: 'someValue'};
    windowGlobals.fraud0 = {someKey: 'someValue'};
    windowGlobals.F0Loaded = true;
    runCode(mockData);
    runCode(mockData);
    mockData.tagType = 'conversion';
    mockData.conversionType = 'basic';
    runCode(mockData);
    runCode(mockData);

    assertThat(consoleMessages.length).isEqualTo(0);
    assertApi('logToConsole').wasNotCalled();
- name: Conversion type defaults to purchase when the field is empty
  code: |-
    mockData.tagType = 'conversion';
    mockData.conversionType = undefined;
    runCode(mockData);

    assertThat(queuedEvents.length).isEqualTo(1);
    assertThat(queuedEvents[0][0]).isEqualTo('purchase');
    assertApi('gtmOnFailure').wasNotCalled();
- name: Implausible Customer ID logs a warning but the tag fires normally
  code: |-
    containerVersion = {debugMode: true, previewMode: true};
    mockData.customerId = 'not-a-valid-uuid';
    runCode(mockData);

    assertApi('sendPixel').wasCalled();
    assertApi('gtmOnSuccess').wasCalled();
    assertApi('gtmOnFailure').wasNotCalled();
    const warnings = consoleMessages.filter(m => m.indexOf('Customer ID') !== -1);
    assertThat(warnings.length).isEqualTo(1);
setup: |-
  const mockData = {
    customerId: '12345678-90ab-cdef-1234-567890abcdef',
    tagType: 'page_view'
  };

  let queuedEvents = [];
  mock('createQueue', queueName => {
    return item => queuedEvents.push(item);
  });

  let injectedScriptUrl;
  let injectedCacheToken;
  let injectCount = 0;
  mock('injectScript', (url, onSuccess, onFailure, cacheToken) => {
    injectedScriptUrl = url;
    injectedCacheToken = cacheToken;
    injectCount++;
    onSuccess();
  });

  let sentPixelUrl;
  let sentPixelCount = 0;
  mock('sendPixel', (url, onSuccess, onFailure) => {
    sentPixelUrl = url;
    sentPixelCount++;
  });

  // Stateful template storage: keeps values across runCode calls within one
  // scenario, like the real per-page templateStorage.
  let storage = {};
  mock('templateStorage', {
    getItem: key => storage[key],
    setItem: (key, value) => { storage[key] = value; },
    removeItem: key => { storage[key] = undefined; },
    clear: () => { storage = {}; }
  });

  // Window globals readable via copyFromWindow (utag, dataLayer, fraud0,
  // F0Loaded). Scenarios add entries as needed.
  let windowGlobals = {};
  mock('copyFromWindow', name => windowGlobals[name]);

  // Debug logging is OFF by default so scenarios behave like production.
  // Diagnostics scenarios switch debugMode/previewMode on.
  let containerVersion = {debugMode: false, previewMode: false};
  mock('getContainerVersion', () => containerVersion);

  let consoleMessages = [];
  mock('logToConsole', message => consoleMessages.push(message));


___NOTES___

fraud0 tag template for Google Tag Manager.
Maintained by sblum GmbH — https://www.sblum.de
Documentation: https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted01/


