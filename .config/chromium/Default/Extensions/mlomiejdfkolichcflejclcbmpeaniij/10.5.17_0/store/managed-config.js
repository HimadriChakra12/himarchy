import { isOpera, isWebkit } from '../utils/browser-info.js';
import { debugMode } from '../utils/debug.js';
import store from '../npm/hybrids/src/store.js';

const TRUSTED_DOMAINS_NONE_ID = "<none>";
const ManagedConfig = {
  disableOnboarding: false,
  disableUserControl: false,
  disableUserAccount: false,
  disableTrackersPreview: false,
  trustedDomains: [TRUSTED_DOMAINS_NONE_ID],
  [store.connect]: async () => {
    if (isOpera() || isWebkit()) return {};
    try {
      if (debugMode) {
        const { debugManagedConfig } = await chrome.storage.local.get("debugManagedConfig");
        if (debugManagedConfig) return debugManagedConfig;
      }
      return await chrome.storage.managed.get() || {};
    } catch {
      return {};
    }
  }
};

export { TRUSTED_DOMAINS_NONE_ID, ManagedConfig as default };
