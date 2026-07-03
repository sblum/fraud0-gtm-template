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
    "displayName": "sblum",
    "id": "github.com_sblum",
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
    "defaultValue": "basic",
    "help": "Choose one of the predefined fraud0 conversion types, a Basic conversion (only reports that a conversion happened), or define a custom type.",
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
        "value": "basic",
        "displayValue": "Basic conversion (no type)"
      },
      {
        "value": "lead",
        "displayValue": "Lead"
      },
      {
        "value": "purchase",
        "displayValue": "Purchase"
      },
      {
        "value": "signup",
        "displayValue": "Signup"
      },
      {
        "value": "custom",
        "displayValue": "Custom conversion type"
      }
    ],
    "subParams": [
      {
        "type": "TEXT",
        "name": "customConversionType",
        "displayName": "Custom Conversion Type",
        "simpleValueType": true,
        "help": "A short identifier for this conversion type, e.g. trial_started, subscription_renewed, whitepaper_download, quote_requested or appointment_booked. Allowed characters: letters, digits, underscore, hyphen. A Google Tag Manager variable is also accepted.",
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
    "help": "Optional unique identifier for this conversion instance — e.g. the order ID for Purchase ({{Transaction ID}}), the form name for Lead (contact_form), or the signup ID for Signup. Enables per-conversion reporting in fraud0. Ignored for Basic conversions.",
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
 * JavaScript executes are still detected.
 *
 * Conversion Event: pushes a conversion into the window.fraud0 queue so the
 * detection model can identify false positives, and ensures the detection
 * script is present (injectScript deduplicates by URL).
 */

const createQueue = require('createQueue');
const encodeUriComponent = require('encodeUriComponent');
const generateRandom = require('generateRandom');
const getTimestampMillis = require('getTimestampMillis');
const injectScript = require('injectScript');
const makeString = require('makeString');
const sendPixel = require('sendPixel');

const API_BASE = 'https://api.fraud0.com/api/v2/';

// The Customer ID is required for every tag type.
if (!data.customerId) {
  return data.gtmOnFailure();
}

const cid = encodeUriComponent(makeString(data.customerId));
const scriptUrl = API_BASE + 'fz.js?cid=' + cid;

if (data.tagType === 'conversion') {
  // Resolve the conversion type.
  const conversionType = data.conversionType === 'custom' ?
      data.customConversionType : data.conversionType;

  if (data.conversionType !== 'basic' && !conversionType) {
    return data.gtmOnFailure();
  }

  // Queue the conversion for the detection script: window.fraud0.push([...])
  const fraud0Push = createQueue('fraud0');
  if (data.conversionType === 'basic') {
    fraud0Push([1]);
  } else if (data.conversionId) {
    fraud0Push([makeString(conversionType), makeString(data.conversionId)]);
  } else {
    fraud0Push([makeString(conversionType)]);
  }
} else {
  // Page View: fire the first-hit pixel immediately, before the script loads.
  const cacheBuster = '0.' + generateRandom(100000000, 999999999) + '.' +
      getTimestampMillis();
  sendPixel(API_BASE + 'pixel?cid=' + cid + '&cb=' + cacheBuster);
}

// Load the fraud0 detection script. injectScript deduplicates by URL, so the
// script is only loaded once even if several fraud0 tags fire on one page.
injectScript(scriptUrl, data.gtmOnSuccess, data.gtmOnFailure);


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
  mock('injectScript', (url, onSuccess, onFailure) => {
    injectedScriptUrl = url;
    onSuccess();
  });

  let sentPixelUrl;
  mock('sendPixel', (url, onSuccess, onFailure) => {
    sentPixelUrl = url;
  });


___NOTES___

fraud0 tag template for Google Tag Manager.
Maintained by sblum GmbH — https://www.sblum.de
Documentation: https://help.fraud0.com/1-onsite/a-implement-onsite/gettingstarted01/


