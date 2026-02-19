function createButtonClasses(isSelected) {
    if (isSelected) {
        return "rounded border px-3 py-3 text-left bg-blue-500/45 border-blue-300/80 text-white";
    }
    return "rounded border border-white/15 px-3 py-3 text-left bg-transparent text-neutral-100";
}

function createTabClasses(isSelected) {
    if (isSelected) {
        return "tab-btn rounded border px-2 py-2 text-sm bg-blue-500/45 border-blue-300/80 text-white";
    }
    return "tab-btn rounded border border-white/15 px-2 py-2 text-sm bg-transparent text-neutral-100";
}

function subtitleToneClass(tone) {
    if (tone === "success") {
        return "text-emerald-400";
    }
    if (tone === "danger") {
        return "text-red-400";
    }
    return "text-neutral-400";
}

function resolveActionSubtitle(action) {
    if (action.id === "toggle_godmode") {
        const enabled = Boolean(action.enabled);
        return {
            text: `Status: ${enabled ? "Enabled" : "Disabled"}`,
            tone: enabled ? "success" : "danger"
        };
    }

    if (!action.subtitle) {
        return null;
    }

    return {
        text: action.subtitle,
        tone: action.subtitleTone
    };
}

export function createMenuRenderer(tabListElement, buttonListElement) {
    return {
        render(state) {
            tabListElement.innerHTML = state.tabs
                .map((tab, index) => {
                    const classes = createTabClasses(index === state.selectedTabIndex);
                    return `<button data-role="tab" data-tab-index="${index}" class="${classes}">${tab.label}</button>`;
                })
                .join("");

            const activeTab = state.tabs[state.selectedTabIndex];
            const actions = activeTab ? activeTab.actions : [];

            buttonListElement.innerHTML = actions
                .map((action, index) => {
                    const classes = createButtonClasses(index === state.selectedActionIndex);
                    const subtitle = resolveActionSubtitle(action);
                    const subtitleHtml = subtitle
                        ? `<span class="mt-1 block text-xs ${subtitleToneClass(subtitle.tone)}">${subtitle.text}</span>`
                        : "";

                    return [
                        `<button data-role="action" data-action-index="${index}" class="${classes}">`,
                        `<span class="block text-sm">${action.title}</span>`,
                        subtitleHtml,
                        "</button>"
                    ].join("");
                })
                .join("");
        }
    };
}
