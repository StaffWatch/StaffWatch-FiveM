export function createInitialMenuState() {
    return {
        visible: false,
        selectedTabIndex: 0,
        selectedActionIndex: 0,
        tabs: [
            {
                id: "self",
                label: "Self",
                actions: [
                    { id: "toggle_godmode", title: "Toggle Godmode", enabled: true },
                    { id: "self_placeholder_1", title: "Self Placeholder 1" },
                    { id: "self_placeholder_2", title: "Self Placeholder 2" },
                    { id: "self_placeholder_3", title: "Self Placeholder 3" },
                    { id: "self_placeholder_4", title: "Self Placeholder 4" },
                    { id: "self_placeholder_5", title: "Self Placeholder 5" },
                    { id: "self_placeholder_6", title: "Self Placeholder 6" }
                ]
            },
            {
                id: "server",
                label: "Server",
                actions: [
                    { id: "server_placeholder_1", title: "Server Placeholder 1" },
                    { id: "server_placeholder_2", title: "Server Placeholder 2" },
                    { id: "server_placeholder_3", title: "Server Placeholder 3" },
                    { id: "server_placeholder_4", title: "Server Placeholder 4" },
                    { id: "server_placeholder_5", title: "Server Placeholder 5" },
                    { id: "server_placeholder_6", title: "Server Placeholder 6" },
                    { id: "server_placeholder_7", title: "Server Placeholder 7" }
                ]
            },
            {
                id: "players",
                label: "Players",
                actions: [
                    { id: "players_placeholder_1", title: "Players Placeholder 1" },
                    { id: "players_placeholder_2", title: "Players Placeholder 2" },
                    { id: "players_placeholder_3", title: "Players Placeholder 3" },
                    { id: "players_placeholder_4", title: "Players Placeholder 4" },
                    { id: "players_placeholder_5", title: "Players Placeholder 5" },
                    { id: "players_placeholder_6", title: "Players Placeholder 6" },
                    { id: "players_placeholder_7", title: "Players Placeholder 7" }
                ]
            }
        ]
    };
}

export function getSelectedTab(state) {
    return state.tabs[state.selectedTabIndex];
}

export function getSelectedAction(state) {
    const tab = getSelectedTab(state);
    return tab ? tab.actions[state.selectedActionIndex] : null;
}

export function normalizeSelection(state) {
    const tab = getSelectedTab(state);
    if (!tab) {
        state.selectedActionIndex = 0;
        return;
    }

    const actionCount = tab.actions.length;
    if (actionCount === 0) {
        state.selectedActionIndex = 0;
        return;
    }

    state.selectedActionIndex = Math.max(0, Math.min(state.selectedActionIndex, actionCount - 1));
}

export function updateActionContent(state, payload) {
    if (!payload) {
        return false;
    }

    const tabId = String(payload.tabId || "");
    const actionId = String(payload.actionId || "");
    const tab = state.tabs.find((entry) => entry.id === tabId);
    if (!tab) {
        return false;
    }

    const action = tab.actions.find((entry) => entry.id === actionId);
    if (!action) {
        return false;
    }

    if (action.id === "toggle_godmode" && typeof payload.enabled === "boolean") {
        action.enabled = payload.enabled;
    }

    if (typeof payload.title === "string") {
        action.title = payload.title;
    }

    if (typeof payload.subtitle === "string") {
        action.subtitle = payload.subtitle;
    }

    if (typeof payload.subtitleTone === "string") {
        action.subtitleTone = payload.subtitleTone;
    }

    return true;
}
