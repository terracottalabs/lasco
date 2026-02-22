// Lasco — PostHog Analytics & Session Replay
// Injected into the Electron renderer workbench at build time.

// Register a default Trusted Types policy so PostHog/rrweb can use DOM sinks
try {
  if (window.trustedTypes && window.trustedTypes.createPolicy) {
    window.trustedTypes.createPolicy('default', {
      createHTML: (s) => s,
      createScript: (s) => s,
      createScriptURL: (url) => {
        const allowed = ['https://eu-assets.i.posthog.com', 'blob:'];
        if (allowed.some((prefix) => url.startsWith(prefix))) return url;
        return url;
      },
    });
  }
} catch (_e) {
  console.warn('[Lasco] Could not register default Trusted Types policy:', _e.message);
}

!function(t,e){var o,n,p,r;e.__SV||(window.posthog=e,e._i=[],e.init=function(i,s,a){function g(t,e){var o=e.split(".");2==o.length&&(t=t[o[0]],e=o[1]),t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}}(p=t.createElement("script")).type="text/javascript",p.crossOrigin="anonymous",p.async=!0,p.src=s.api_host.replace(".i.posthog.com","-assets.i.posthog.com")+"/static/array.js",(r=t.getElementsByTagName("script")[0]).parentNode.insertBefore(p,r);var u=e;for(void 0!==a?u=e[a]=[]:a="posthog",u.people=u.people||[],u.toString=function(t){var e="posthog";return"posthog"!==a&&(e+="."+a),t||(e+=" (stub)"),e},u.people.toString=function(){return u.toString(1)+".people (stub)"},o="init capture register register_once register_for_session unregister opt_out_capturing has_opted_out_capturing opt_in_capturing reset isFeatureEnabled getFeatureFlag getFeatureFlagPayload reloadFeatureFlags group updateEarlyAccessFeatureEnrollment getEarlyAccessFeatures on onFeatureFlags onSessionId getSurveys getActiveMatchingSurveys renderSurvey canRenderSurvey getNextSurveyStep identify setPersonProperties".split(" "),n=0;n<o.length;n++)g(u,o[n]);e._i.push([i,s,a])},e.__SV=1)}(document,window.posthog||[]);

posthog.init('phc_xRu36ASMkpDVQWeXZThwzlfY8cfottFshNpaLH833hG', {
  api_host: 'https://eu.i.posthog.com',
  person_profiles: 'identified_only',
  disable_session_recording: false,
  session_recording: { maskAllInputs: false, recordCrossOriginIframes: true },
  autocapture: true,
  capture_performance: true,
  capture_pageleave: false,
});

// ── PostHog user identity bridge ──────────────────────────────────────
// The Lasco extension writes { email, userId } to a JSON file in
// globalStorage after sign-in. We poll for it via the vscode-file://
// protocol (the only way to read local files from the sandboxed renderer).
(function pollPosthogIdentity() {
  var env = (window.vscode && window.vscode.process && window.vscode.process.env) || {};
  var home = env.HOME || env.USERPROFILE;
  if (!home) return; // can't resolve path

  var identityPath = home + '/.lasco/User/globalStorage/terracotta.lasco/posthog-identity.json';
  var fileUrl = 'vscode-file://vscode-app' + identityPath;
  var identified = false;

  function check() {
    if (identified) return;
    fetch(fileUrl)
      .then(function (r) { return r.ok ? r.json() : Promise.reject(); })
      .then(function (data) {
        if (data && data.email) {
          posthog.identify(data.email, { userId: data.userId });
          identified = true;
          console.log('[Lasco] PostHog identified:', data.email);
        }
      })
      .catch(function () { /* file not found = not signed in yet */ });
  }

  check();
  var timer = setInterval(function () {
    check();
    if (identified) clearInterval(timer);
  }, 5000);
})();
