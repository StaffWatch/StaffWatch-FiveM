const resourceName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "StaffWatch-FiveM";

export function sendNuiRequest(route, payload = {}) {
    return fetch(`https://${resourceName}/${route}`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8"
        },
        body: JSON.stringify(payload)
    }).catch(() => {});
}
