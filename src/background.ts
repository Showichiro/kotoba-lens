chrome.runtime.onInstalled.addListener(() => {
  void chrome.action.setBadgeBackgroundColor({ color: "#17332b" });
});

chrome.action.onClicked.addListener((tab) => {
  if (!tab.id) return;
  void chrome.tabs.sendMessage(tab.id, { type: "KOTOBA_LENS_TOGGLE_SUMMARY" }).catch(() => undefined);
});
