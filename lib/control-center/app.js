(() => {
  const fragmentToken = window.location.hash.slice(1);
  let token = fragmentToken;
  if (fragmentToken) {
    try { sessionStorage.setItem("ternux-control-session", fragmentToken); } catch { /* memory session still works */ }
    history.replaceState(null, "", window.location.pathname);
  } else {
    try { token = sessionStorage.getItem("ternux-control-session") || ""; } catch { token = ""; }
  }
  const notice = document.querySelector("#notice");
  const list = document.querySelector("#guest-list");
  const refreshed = document.querySelector("#refresh");

  function escapeHtml(value) {
    return String(value ?? "").replace(/[&<>\"']/g, (character) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
    })[character]);
  }

  function renderGuest(guest, display) {
    const name = escapeHtml(guest.name);
    const profile = guest.desktop_profile ? "Desktop profile" : "Shell guest";
    const running = Boolean(display?.running);
    const stateText = running ? "ACTIVE" : "STOPPED";
    const stateClass = running ? "" : "stopped";
    const current = display?.current_display;
    const target = display?.target_display;
    const displayText = current !== null && current !== undefined
      ? `:${escapeHtml(current)}${target !== null && target !== undefined && current !== target ? ` → :${escapeHtml(target)}` : ""}`
      : target !== null && target !== undefined ? `Target :${escapeHtml(target)}` : "Not assigned";
    const conflict = Boolean(display?.target_conflict);
    const qualified = guest.qualification === "device-qualified";
    const qualification = qualified ? "Record exists" : "Not qualified";
    const qualificationClass = qualified ? "good" : "warn";
    const startCommand = guest.desktop_profile
      ? `tx start ${guest.name}`
      : `tx distro shell ${guest.name}`;
    const initials = String(guest.name).slice(0, 2);
    return `<article class="guest-card">
      <div class="guest-head"><div class="guest-id"><span class="distro-mark" aria-hidden="true">${escapeHtml(initials)}</span><div><div class="guest-name">${name}</div><div class="guest-kind">${profile}</div></div></div><span class="state-pill ${stateClass}">${stateText}</span></div>
      <div class="guest-data">
        <div><span class="data-label">DESKTOP SESSION</span><span class="data-value ${running ? "good" : ""}">${stateText}</span></div>
        <div><span class="data-label">DISPLAY</span><span class="data-value ${conflict ? "warn" : ""}">${conflict ? "Collision · " : ""}${displayText}</span></div>
        <div><span class="data-label">PROFILE</span><span class="data-value">${escapeHtml(profile)}</span></div>
        <div><span class="data-label">DEVICE QUALIFICATION</span><span class="data-value ${qualificationClass}">${qualification}</span></div>
      </div>
      <div class="guest-command"><code>${escapeHtml(startCommand)}</code><button data-copy="${escapeHtml(startCommand)}" aria-label="Copy start command for ${name}">COPY</button></div>
    </article>`;
  }

  function renderMigration(displayData, displayRows) {
    const listNode = document.querySelector("#migration-list");
    const preview = displayData.migration_preview;
    if (!preview || preview.status !== "preview-only" || preview.executor_implemented !== false || preview.ready_to_execute !== false) {
      listNode.innerHTML = '<span class="data-value warn">Migration preview is unavailable or has an unsupported version.</span>';
      return;
    }
    const moves = displayRows.filter((row) => row.migration_action === "move");
    if (!moves.length) {
      listNode.innerHTML = '<span class="migration-clear">No saved guest display assignments need to move.</span>';
      return;
    }
    listNode.innerHTML = moves.map((row) => {
      const blockers = Array.isArray(row.migration_blockers) ? row.migration_blockers : [];
      const blockerLabels = {
        "active-session": "Active desktop must be preserved before migration.",
        "target-conflict": "Target display is occupied.",
        "invalid-registry": "Workspace registry is malformed.",
        "registry-mismatch": "Saved profile and registry assignments disagree.",
      };
      const blockerText = blockers.length
        ? `<span class="migration-blockers">${blockers.map((item) => escapeHtml(blockerLabels[item] || item)).join(" ")}</span>`
        : "";
      return `<div class="migration-row"><div><strong>${escapeHtml(row.name)}</strong>${blockerText}</div><span class="migration-route">:${escapeHtml(row.current_display)} → :${escapeHtml(row.target_display)}</span></div>`;
    }).join("");
  }

  function render(data) {
    const status = data.snapshot.status;
    const guestsData = data.snapshot.guests;
    const displayData = data.snapshot.displays;
    const guestRows = Array.isArray(guestsData.guests) ? guestsData.guests : [];
    const displayRows = Array.isArray(displayData.guests) ? displayData.guests : [];
    const guestReadFailed = guestsData.status !== "ok";
    const displayReadFailed = displayData.status !== "ok";
    const displayByName = new Map(displayRows.map((row) => [row.name, row]));
    const active = guestRows.filter((guest) => displayByName.get(guest.name)?.running).map((guest) => guest.name);
    const conflicts = displayRows.filter((row) => row.target_conflict).length;
    document.querySelector("#host-state").textContent = status.status === "available" ? "Available" : "Needs attention";
    document.querySelector("#host-detail").textContent = status.guest_manager_available ? "Termux CLI ready" : "Guest manager unavailable";
    document.querySelector("#guest-count").textContent = guestReadFailed ? "—" : String(guestsData.count ?? guestRows.length);
    document.querySelector("#active-count").textContent = displayReadFailed ? "—" : String(active.length);
    document.querySelector("#active-detail").textContent = active.length ? active.join(" · ") : "No active desktop detected";
    document.querySelector("#display-state").textContent = displayReadFailed ? "Unavailable" : conflicts ? `${conflicts} conflict${conflicts === 1 ? "" : "s"}` : "Clear";
    document.querySelector("#display-detail").textContent = displayReadFailed ? "Could not read display state" : `Native :${displayData.native_display} reserved`;
    list.innerHTML = guestReadFailed
      ? `<article class="empty-state warning"><span class="empty-icon">!</span><h3>Guest list unavailable</h3><p>${escapeHtml(guestsData.message || "The local guest manager could not return a list.")}</p><code>tx manager status --json</code></article>`
      : guestRows.length
        ? guestRows.map((guest) => renderGuest(guest, displayByName.get(guest.name))).join("")
        : `<article class="empty-state"><span class="empty-icon">⌂</span><h3>No Linux guests yet</h3><p>Install a Ternux desktop from the Termux command line. This dashboard stays read-only.</p><code>ternux install</code></article>`;
    renderMigration(displayData, displayRows);
    document.querySelector("#updated").textContent = `Updated ${new Date(status.timestamp).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}`;
    const partial = guestReadFailed || displayReadFailed || status.status !== "available";
    notice.textContent = partial
      ? "Connected, but one or more status sources are unavailable. See the card details below."
      : "Connected to the local Ternux manager. Snapshot is read only.";
    notice.className = partial ? "notice error" : "notice success";
    wireCopyButtons();
  }

  async function load() {
    if (!token) {
      notice.textContent = "Session key is missing. Close this tab and run `tx control` again in Termux.";
      notice.className = "notice error";
      return;
    }
    refreshed.disabled = true;
    notice.textContent = "Refreshing local workspace status…";
    notice.className = "notice";
    try {
      const response = await fetch("/api/v1/snapshot", {
        headers: { Authorization: `Bearer ${token}` },
        cache: "no-store",
        credentials: "omit",
        redirect: "error",
      });
      if (response.status === 401) {
        try { sessionStorage.removeItem("ternux-control-session"); } catch { /* no persistent token to clear */ }
        throw new Error("Session key expired. Close this tab and run `tx control` again in Termux.");
      }
      if (!response.ok) throw new Error(`Manager request failed (${response.status}).`);
      const payload = await response.json();
      if (!payload.read_only || payload.schema_version !== "1.0.0") throw new Error("Unsupported manager response.");
      render(payload);
    } catch (error) {
      notice.textContent = `${error.message} Use tx manager status --json in Termux for details.`;
      notice.className = "notice error";
    } finally {
      refreshed.disabled = false;
    }
  }

  function wireCopyButtons() {
    document.querySelectorAll("[data-copy]").forEach((button) => {
      if (button.dataset.ready) return;
      button.dataset.ready = "true";
      button.addEventListener("click", async () => {
        try {
          await navigator.clipboard.writeText(button.dataset.copy);
          button.textContent = "COPIED";
        } catch {
          button.textContent = "SELECT CMD";
        }
        window.setTimeout(() => { button.textContent = "COPY"; }, 1500);
      });
    });
  }

  refreshed.addEventListener("click", load);
  wireCopyButtons();
  load();
})();
