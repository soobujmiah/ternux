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
  let actionsBusy = false;

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
    const actionBlocked = display?.migration_required
      ? "Stop this desktop in Termux, apply its display migration, then start it again."
      : "";
    const lifecycleAction = guest.desktop_profile && display && !actionBlocked
      ? `<button class="guest-action" type="button" data-lifecycle="${running ? "stop" : "start"}" data-guest="${escapeHtml(guest.name)}" aria-label="${running ? "Stop" : "Start"} ${name} desktop">${running ? "Stop desktop" : "Start desktop"}</button>`
      : actionBlocked ? `<p class="action-blocked" role="status">${escapeHtml(actionBlocked)}</p>` : "";
    return `<article class="guest-card">
      <div class="guest-head"><div class="guest-id"><span class="distro-mark" aria-hidden="true">${escapeHtml(initials)}</span><div><div class="guest-name">${name}</div><div class="guest-kind">${profile}</div></div></div><span class="state-pill ${stateClass}">${stateText}</span></div>
      <div class="guest-data">
        <div><span class="data-label">DESKTOP SESSION</span><span class="data-value ${running ? "good" : ""}">${stateText}</span></div>
        <div><span class="data-label">DISPLAY</span><span class="data-value ${conflict ? "warn" : ""}">${conflict ? "Collision · " : ""}${displayText}</span></div>
        <div><span class="data-label">PROFILE</span><span class="data-value">${escapeHtml(profile)}</span></div>
        <div><span class="data-label">DEVICE QUALIFICATION</span><span class="data-value ${qualificationClass}">${qualification}</span></div>
      </div>
      <div class="guest-command"><code>${escapeHtml(startCommand)}</code><button data-copy="${escapeHtml(startCommand)}" aria-label="Copy start command for ${name}">COPY</button></div>
      ${lifecycleAction}
    </article>`;
  }

  function renderMigration(displayData, displayRows) {
    const listNode = document.querySelector("#migration-list");
    const preview = displayData.migration_preview;
    if (!preview || preview.status !== "preview-only" || preview.executor_implemented !== true || typeof preview.ready_to_execute !== "boolean" || !/^sha256:[a-f0-9]{64}$/.test(preview.plan_id || "")) {
      listNode.innerHTML = '<span class="data-value warn">Migration preview is unavailable or has an unsupported version.</span>';
      return;
    }
    const moves = displayRows.filter((row) => row.migration_action === "move");
    if (!moves.length) {
      listNode.innerHTML = '<span class="migration-clear">No saved guest display assignments need to move.</span>';
      return;
    }
    const status = preview.ready_to_execute
      ? `<span class="data-value good">Ready for explicit CLI apply</span><code>tx manager migrate --apply ${escapeHtml(preview.plan_id)}</code>`
      : '<span class="data-value warn">Blocked until every guest is stopped and target checks pass.</span>';
    listNode.innerHTML = `${status}${moves.map((row) => {
      const blockers = Array.isArray(row.migration_blockers) ? row.migration_blockers : [];
      const blockerLabels = {
        "active-session": "This guest desktop must be stopped before migration.",
        "other-active-session": "Stop all other managed desktops before applying the migration.",
        "target-conflict": "Target display is occupied.",
        "invalid-registry": "Workspace registry is malformed.",
        "registry-mismatch": "Saved profile and registry assignments disagree.",
        "lifecycle-not-stopped": "Guest lifecycle must be STOPPED before migration.",
      };
      const blockerText = blockers.length
        ? `<span class="migration-blockers">${blockers.map((item) => escapeHtml(blockerLabels[item] || item)).join(" ")}</span>`
        : "";
      return `<div class="migration-row"><div><strong>${escapeHtml(row.name)}</strong>${blockerText}</div><span class="migration-route">:${escapeHtml(row.current_display)} → :${escapeHtml(row.target_display)}</span></div>`;
    }).join("")}`;
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
        : `<article class="empty-state"><span class="empty-icon">⌂</span><h3>No Linux guests yet</h3><p>Install a Ternux desktop from the Termux command line.</p><code>ternux install</code></article>`;
    renderMigration(displayData, displayRows);
    document.querySelector("#updated").textContent = `Updated ${new Date(status.timestamp).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}`;
    const partial = guestReadFailed || displayReadFailed || status.status !== "available";
    notice.textContent = partial
      ? "Connected, but one or more status sources are unavailable. See the card details below."
      : "Connected locally. Desktop start/stop actions require a separate confirmation.";
    notice.className = partial ? "notice error" : "notice success";
    wireCopyButtons();
    wireLifecycleButtons();
  }

  async function mutation(path, payload) {
    const response = await fetch(path, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
        "X-Ternux-CSRF": token,
      },
      body: JSON.stringify(payload),
      cache: "no-store",
      credentials: "omit",
      redirect: "error",
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok) {
      const messages = {
        PLAN_STALE: "Guest state changed before confirmation. Refresh and review a new plan.",
        IDEMPOTENCY_CONFLICT: "This request key was already used for a different action.",
        CONFIRMATION_INVALID_OR_EXPIRED: "The confirmation expired. Request a fresh action plan.",
        GUEST_STATE_UNAVAILABLE: "Ternux cannot safely read the current guest state.",
        GUEST_ACTION_BLOCKED: result.message || "A display or lifecycle check blocks this action. Use the Ternux CLI to resolve it.",
      };
      throw new Error(messages[result.error] || result.message || `Ternux action failed (${response.status}).`);
    }
    return result;
  }

  async function pollJob(jobId, action, guest) {
    const startedAt = Date.now();
    while (Date.now() - startedAt < 340000) {
      const response = await fetch(`/api/v1/jobs/${encodeURIComponent(jobId)}`, {
        headers: { Authorization: `Bearer ${token}` },
        cache: "no-store",
        credentials: "omit",
        redirect: "error",
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok || !payload.job) throw new Error("Ternux cannot read the durable action status.");
      const job = payload.job;
      notice.textContent = `${action === "start" ? "Starting" : "Stopping"} ${guest}: ${job.state.toLowerCase().replaceAll("_", " ")} · ${job.phase}.`;
      notice.className = "notice";
      if (["SUCCEEDED", "FAILED", "INTERRUPTED"].includes(job.state)) {
        if (job.state !== "SUCCEEDED") throw new Error(job.error?.message || `Guest action ${job.state.toLowerCase()}.`);
        return;
      }
      await new Promise((resolve) => window.setTimeout(resolve, 800));
    }
    throw new Error("The action is taking longer than expected. Check the guest status before retrying.");
  }

  function newIdempotencyKey() {
    if (window.crypto?.randomUUID) return window.crypto.randomUUID();
    if (!window.crypto?.getRandomValues) throw new Error("This browser cannot create a secure action key.");
    return Array.from(window.crypto.getRandomValues(new Uint8Array(24)), (value) => value.toString(16).padStart(2, "0")).join("");
  }

  async function runLifecycle(button) {
    if (actionsBusy || button.disabled) return;
    const action = button.dataset.lifecycle;
    const guest = button.dataset.guest;
    if (!/^[a-z][a-z0-9._-]{0,63}$/.test(guest || "") || !["start", "stop"].includes(action)) return;
    actionsBusy = true;
    document.querySelectorAll("[data-lifecycle]").forEach((item) => { item.disabled = true; });
    button.setAttribute("aria-busy", "true");
    notice.textContent = `Preparing a state-bound ${action} plan for ${guest}…`;
    notice.className = "notice";
    try {
      const response = await mutation("/api/v1/guest-plans", { operation: action, guest });
      const plan = response.plan;
      if (!plan || response.status !== "confirmation-required" || plan.guest !== guest || plan.operation !== action) {
        throw new Error("Ternux returned an unsupported guest action plan.");
      }
      if (plan.already_satisfied) {
        await load();
        notice.textContent = `${guest} is already ${action === "start" ? "running" : "stopped"}; no action was needed.`;
        notice.className = "notice success";
        return;
      }
      const display = plan.observed?.current_display;
      const displayText = Number.isInteger(display) ? ` on display :${display}` : "";
      const accepted = window.confirm(`Review Ternux action

${action === "start" ? "Start" : "Stop"} the ${guest} desktop${displayText}?

Ternux checked the current guest state. ${conflict && action === "start" ? "It will verify the target and only remove a socket it proves stale. " : ""}Confirm to continue; the job is recorded and can be checked in this dashboard.`);
      if (!accepted) {
        notice.textContent = `No change made to ${guest}.`;
        notice.className = "notice success";
        return;
      }
      const submitted = await mutation("/api/v1/guest-actions", {
        plan_id: plan.plan_id,
        confirmation: response.confirmation,
        idempotency_key: newIdempotencyKey(),
      });
      const job = submitted.job;
      if (!job?.id) throw new Error("Ternux did not return a durable job identifier.");
      await pollJob(job.id, action, guest);
      await load();
      notice.textContent = `${guest} desktop ${action} completed.`;
      notice.className = "notice success";
    } catch (error) {
      notice.textContent = `${error.message} Check ` + `tx status ${guest}` + " in Termux before retrying.";
      notice.className = "notice error";
    } finally {
      actionsBusy = false;
      button.removeAttribute("aria-busy");
      document.querySelectorAll("[data-lifecycle]").forEach((item) => { item.disabled = false; });
    }
  }

  function wireLifecycleButtons() {
    document.querySelectorAll("[data-lifecycle]").forEach((button) => {
      if (button.dataset.ready) return;
      button.dataset.ready = "true";
      button.addEventListener("click", () => runLifecycle(button));
    });
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
