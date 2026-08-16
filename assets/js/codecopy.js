/* ============================================================================
   ternux — code copy affordance
   Adds a terminal-style header bar with a copy button to every code block
   (docs <pre> and landing-page .cmd blocks), and makes inline <code>
   click-to-copy. Skips decorative terminals. No dependencies.

   Copyright (c) 2026 Sobuj Miah (@soobujmiah) — MIT
   ========================================================================== */
(function () {
  "use strict";

  /* ---- clipboard with fallback (old webviews / restricted contexts) ----- */
  function fallbackCopy(text) {
    var ta = document.createElement("textarea");
    ta.value = text;
    ta.setAttribute("readonly", "");
    ta.style.position = "fixed";
    ta.style.left = "-9999px";
    ta.style.top = "0";
    document.body.appendChild(ta);
    ta.select();
    ta.setSelectionRange(0, ta.value.length);
    var ok = false;
    try { ok = document.execCommand("copy"); } catch (e) { ok = false; }
    document.body.removeChild(ta);
    return ok;
  }

  function copyText(text, btn, done) {
    function finish(ok) {
      if (btn) {
        btn.textContent = ok ? "✓ copied" : "copy failed";
        btn.classList.add("copied");
        btn.setAttribute("aria-live", "polite");
        setTimeout(function () {
          btn.textContent = "copy";
          btn.classList.remove("copied");
        }, 1500);
      }
      if (done) done(ok);
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(
        function () { finish(true); },
        function () { finish(fallbackCopy(text)); }
      );
    } else {
      finish(fallbackCopy(text));
    }
  }

  /* ---- code block header + copy button ---------------------------------- */
  function makeButton() {
    var b = document.createElement("button");
    b.type = "button";
    b.className = "cb-copy";
    b.textContent = "copy";
    b.setAttribute("aria-label", "Copy code to clipboard");
    return b;
  }

  function findLanguage(container) {
    var seen = new Set();
    var el = container;
    while (el && !seen.has(el)) {
      seen.add(el);
      var m = /language-([\w+#.-]+)/.exec(el.className || "");
      if (m) return m[1];
      el = el.parentElement;
    }
    return "";
  }

  function wrapBlock(node) {
    if (node.dataset && node.dataset.cb === "1") return;
    if (node.closest(".term-body") || node.closest(".install") || node.closest(".cb")) return;

    var isCmd = node.classList && node.classList.contains("cmd");

    /* Wrap the outermost wrapper (kramdown nests pre inside .highlight). */
    var target = node;
    var p = node.parentElement;
    if (p && /highlight|highlighter/i.test(p.className || "")) {
      target = p;
    }

    var lang = isCmd ? "command" : (findLanguage(target) || "code");

    var cb = document.createElement("div");
    cb.className = "cb";
    cb.dataset.cb = "1";

    var top = document.createElement("div");
    top.className = "cb-top";

    var dots = document.createElement("span");
    dots.className = "cb-dots";
    dots.setAttribute("aria-hidden", "true");
    dots.innerHTML = "<i></i><i></i><i></i>";

    var lbl = document.createElement("span");
    lbl.className = "cb-lang";
    lbl.textContent = lang;

    var btn = makeButton();

    top.appendChild(dots);
    top.appendChild(lbl);
    top.appendChild(btn);

    target.parentNode.insertBefore(cb, target);
    cb.appendChild(top);
    cb.appendChild(target);

    btn.addEventListener("click", function () {
      var text;
      if (isCmd) {
        /* Normalise per-line indentation introduced by HTML source layout,
           then strip the display-only "$ " prompt prefixes so the pasted
           text is exactly what the shell should run. */
        text = target.textContent
          .replace(/\n[ \t]+/g, "\n")
          .replace(/^\s+|\s+$/g, "")
          .split("\n")
          .map(function (l) { return l.replace(/^\$\s+/, ""); })
          .join("\n");
      } else {
        text = target.textContent.replace(/\s+$/, "");
      }
      copyText(text, btn);
    });
  }

  /* ---- inline code: click to copy ---------------------------------------- */
  function wireInline(codeEl) {
    if (codeEl.closest("pre") || codeEl.closest(".term-body") || codeEl.closest(".cb")) return;
    if (codeEl.dataset && codeEl.dataset.ic === "1") return;
    codeEl.dataset.ic = "1";
    codeEl.title = "Click to copy";
    codeEl.addEventListener("click", function () {
      copyText(codeEl.textContent, null, function (ok) {
        if (ok) {
          codeEl.classList.add("copied");
          setTimeout(function () { codeEl.classList.remove("copied"); }, 900);
        }
      });
    });
  }

  /* ---- init --------------------------------------------------------------- */
  function init() {
    var pres = document.querySelectorAll("pre");
    for (var i = 0; i < pres.length; i++) wrapBlock(pres[i]);

    var cmds = document.querySelectorAll(".cmd");
    for (var j = 0; j < cmds.length; j++) wrapBlock(cmds[j]);

    var codes = document.querySelectorAll("code");
    for (var k = 0; k < codes.length; k++) wireInline(codes[k]);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
