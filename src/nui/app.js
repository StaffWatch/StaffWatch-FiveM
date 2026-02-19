const resourceName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "StaffWatch-FiveM";
const menu = document.getElementById("menu");
const buttonList = document.getElementById("buttonList");
const tabButtons = Array.from(document.querySelectorAll(".tab-btn"));
const tabs = [
    {
        name: "Self",
        actions: [
            "Self Placeholder 1",
            "Self Placeholder 2",
            "Self Placeholder 3",
            "Self Placeholder 4",
            "Self Placeholder 5",
            "Self Placeholder 6",
            "Self Placeholder 7"
        ]
    },
    {
        name: "Server",
        actions: [
            "Server Placeholder 1",
            "Server Placeholder 2",
            "Server Placeholder 3",
            "Server Placeholder 4",
            "Server Placeholder 5",
            "Server Placeholder 6",
            "Server Placeholder 7"
        ]
    },
    {
        name: "Players",
        actions: [
            "Players Placeholder 1",
            "Players Placeholder 2",
            "Players Placeholder 3",
            "Players Placeholder 4",
            "Players Placeholder 5",
            "Players Placeholder 6",
            "Players Placeholder 7"
        ]
    }
];

let menuItems = [];
let selectedTabIndex = 0;
let selectedIndex = 0;

function closeMenu() {
    fetch(`https://${resourceName}/closeMenu`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8"
        },
        body: JSON.stringify({})
    }).catch(() => {});
}

function executeSelection() {
    const selectedButton = menuItems[selectedIndex];
    if (!selectedButton) {
        return;
    }

    fetch(`https://${resourceName}/executeMenuAction`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8"
        },
        body: JSON.stringify({
            tab: tabs[selectedTabIndex].name,
            index: selectedIndex + 1,
            label: selectedButton.textContent
        })
    }).catch(() => {});
}

function updateTabs() {
    tabButtons.forEach((button, index) => {
        const isSelected = index === selectedTabIndex;
        button.classList.toggle("bg-blue-500/45", isSelected);
        button.classList.toggle("border-blue-300/80", isSelected);
        button.classList.toggle("text-white", isSelected);
        button.classList.toggle("bg-transparent", !isSelected);
        button.classList.toggle("text-neutral-100", !isSelected);
    });
}

function updateSelection() {
    menuItems.forEach((item, index) => {
        const isSelected = index === selectedIndex;
        item.classList.toggle("bg-blue-500/45", isSelected);
        item.classList.toggle("border-blue-300/80", isSelected);
        item.classList.toggle("text-white", isSelected);
        item.classList.toggle("bg-transparent", !isSelected);
        item.classList.toggle("text-neutral-100", !isSelected);
    });
}

function moveSelection(direction) {
    if (menuItems.length === 0) {
        return;
    }
    selectedIndex = (selectedIndex + direction + menuItems.length) % menuItems.length;
    updateSelection();
}

function renderMenuItems() {
    const currentTab = tabs[selectedTabIndex];
    buttonList.innerHTML = currentTab.actions.map((action, index) => (
        `<button data-index="${index}" class="menu-item rounded border border-white/15 px-3 py-3 text-left">${action}</button>`
    )).join("");

    menuItems = Array.from(document.querySelectorAll(".menu-item"));
    menuItems.forEach((item, index) => {
        item.addEventListener("click", () => {
            selectedIndex = index;
            updateSelection();
            executeSelection();
        });
    });
}

function switchTab(direction) {
    selectedTabIndex = (selectedTabIndex + direction + tabs.length) % tabs.length;
    selectedIndex = 0;
    renderMenuItems();
    updateTabs();
    updateSelection();
}

window.addEventListener("message", (event) => {
    const data = event.data;
    if (!data || data.action !== "setVisible") {
        return;
    }

    menu.classList.toggle("hidden", !data.visible);
    if (data.visible) {
        selectedTabIndex = 0;
        selectedIndex = 0;
        renderMenuItems();
        updateTabs();
        updateSelection();
    }
});

tabButtons.forEach((button) => {
    button.addEventListener("click", () => {
        selectedTabIndex = Number(button.dataset.tab) || 0;
        selectedIndex = 0;
        renderMenuItems();
        updateTabs();
        updateSelection();
    });
});

window.addEventListener("keydown", (event) => {
    if (menu.classList.contains("hidden")) {
        return;
    }

    if (event.key === "Escape") {
        event.preventDefault();
        closeMenu();
        return;
    }

    if (event.key === "Backspace") {
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
        executeSelection();
    }
});

renderMenuItems();
updateTabs();
updateSelection();
