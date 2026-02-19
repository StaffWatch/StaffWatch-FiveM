import { sendNuiRequest } from "./nuiApi.js";
import { createMenuRenderer } from "./menuRenderer.js";
import {
    createInitialMenuState,
    getSelectedAction,
    getSelectedTab,
    normalizeSelection,
    updateActionContent
} from "./menuState.js";

export function createMenuController() {
    const menuElement = document.getElementById("menu");
    const tabListElement = document.getElementById("tabList");
    const buttonListElement = document.getElementById("buttonList");
    const state = createInitialMenuState();
    const renderer = createMenuRenderer(tabListElement, buttonListElement);

    function render() {
        renderer.render(state);
    }

    function closeMenu() {
        sendNuiRequest("closeMenu");
    }

    function executeSelectedAction() {
        const tab = getSelectedTab(state);
        const action = getSelectedAction(state);
        if (!tab || !action) {
            return;
        }

        sendNuiRequest("executeMenuAction", {
            tabId: tab.id,
            tabLabel: tab.label,
            actionId: action.id,
            actionIndex: state.selectedActionIndex + 1,
            title: action.title
        });
    }

    function setVisible(visible) {
        state.visible = Boolean(visible);
        menuElement.classList.toggle("hidden", !state.visible);

        if (state.visible) {
            state.selectedTabIndex = 0;
            state.selectedActionIndex = 0;
            normalizeSelection(state);
        }

        render();
    }

    function switchTab(direction) {
        const tabCount = state.tabs.length;
        if (tabCount === 0) {
            return;
        }

        state.selectedTabIndex = (state.selectedTabIndex + direction + tabCount) % tabCount;
        state.selectedActionIndex = 0;
        normalizeSelection(state);
        render();
    }

    function moveSelection(direction) {
        const tab = getSelectedTab(state);
        if (!tab || tab.actions.length === 0) {
            return;
        }

        const count = tab.actions.length;
        state.selectedActionIndex = (state.selectedActionIndex + direction + count) % count;
        render();
    }

    function handleGlobalMessage(event) {
        const data = event.data;
        if (!data || typeof data.action !== "string") {
            return;
        }

        if (data.action === "setVisible") {
            setVisible(data.visible);
            return;
        }

        if (data.action === "updateMenuAction") {
            if (updateActionContent(state, data)) {
                normalizeSelection(state);
                render();
            }
        }
    }

    function handleClick(event) {
        const tabButton = event.target.closest("[data-role='tab']");
        if (tabButton) {
            const nextTab = Number(tabButton.dataset.tabIndex);
            if (!Number.isNaN(nextTab) && nextTab >= 0 && nextTab < state.tabs.length) {
                state.selectedTabIndex = nextTab;
                state.selectedActionIndex = 0;
                normalizeSelection(state);
                render();
            }
            return;
        }

        const actionButton = event.target.closest("[data-role='action']");
        if (actionButton) {
            const nextIndex = Number(actionButton.dataset.actionIndex);
            const tab = getSelectedTab(state);
            if (!tab || Number.isNaN(nextIndex) || nextIndex < 0 || nextIndex >= tab.actions.length) {
                return;
            }

            state.selectedActionIndex = nextIndex;
            render();
            executeSelectedAction();
        }
    }

    function handleKeyDown(event) {
        if (menuElement.classList.contains("hidden")) {
            return;
        }

        if (event.key === "Escape" || event.key === "Backspace") {
            event.preventDefault();
            closeMenu();
            return;
        }

        if (event.key === "ArrowLeft") {
            event.preventDefault();
            switchTab(-1);
            return;
        }

        if (event.key === "ArrowRight") {
            event.preventDefault();
            switchTab(1);
            return;
        }

        if (event.key === "ArrowUp") {
            event.preventDefault();
            moveSelection(-1);
            return;
        }

        if (event.key === "ArrowDown") {
            event.preventDefault();
            moveSelection(1);
            return;
        }

        if (event.key === "Enter") {
            event.preventDefault();
            executeSelectedAction();
        }
    }

    return {
        init() {
            render();
            window.addEventListener("message", handleGlobalMessage);
            document.addEventListener("click", handleClick);
            window.addEventListener("keydown", handleKeyDown);
        }
    };
}
