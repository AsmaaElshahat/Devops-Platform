function showResult(message, type) {
    const el = document.getElementById("result");
    el.textContent = message;
    el.className = "result result-" + type;
}

function showTargetResult(id, message, type) {
    const el = document.getElementById(id);
    el.textContent = message;
    el.className = "result result-" + type;
}

document.getElementById("btnSuccess").addEventListener("click", async () => {
    try {
        const resp = await fetch("/api/simulate/success", { method: "POST" });
        const data = await resp.json();
        showResult(`Success: ${data.message} (${resp.status})`, "ok");
    } catch (e) {
        showResult("Error calling simulate success", "error");
    }
});

document.getElementById("btnNotFound").addEventListener("click", async () => {
    try {
        const resp = await fetch("/api/simulate/not_found", { method: "POST" });
        const data = await resp.json();
        showResult(`Not Found: ${data.message} (${resp.status})`, "warn");
    } catch (e) {
        showResult("Error calling simulate not found", "error");
    }
});

document.getElementById("btnError").addEventListener("click", async () => {
    try {
        const resp = await fetch("/api/simulate/error", { method: "POST" });
        const data = await resp.json();
        showResult(`Error: ${data.message} (${resp.status})`, "error");
    } catch (e) {
        showResult("Error calling simulate error", "error");
    }
});

document.getElementById("vaultForm").addEventListener("submit", async (event) => {
    event.preventDefault();

    const key = document.getElementById("vaultKey").value;
    const value = document.getElementById("vaultValue").value;

    try {
        const resp = await fetch("/api/vault/validate", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ key, value })
        });
        const data = await resp.json();
        const type = data.valid ? "ok" : "error";
        showTargetResult("vaultResult", `${data.status}: ${data.key || key} at ${data.path || "Vault"} (${resp.status})`, type);
    } catch (e) {
        showTargetResult("vaultResult", "Error validating Vault secret", "error");
    }
});

document.getElementById("btnLogs").addEventListener("click", async () => {
    try {
        const resp = await fetch("/api/logs/dummy", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ count: 9 })
        });
        const data = await resp.json();
        showTargetResult("logResult", `Generated ${data.count || 0} backend logs for Loki (${resp.status})`, "ok");
    } catch (e) {
        showTargetResult("logResult", "Error generating backend logs", "error");
    }
});
