/* ternux visual effects — progressive, dependency-free, and motion-aware */
(function () {
  "use strict";

  function ready(fn) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", fn);
    } else {
      fn();
    }
  }

  function initScrollFeedback() {
    var header = document.querySelector("[data-site-header]");
    var progress = document.querySelector("[data-scroll-progress]");
    var scheduled = false;

    function update() {
      var root = document.documentElement;
      var distance = Math.max(root.scrollHeight - window.innerHeight, 0);
      var value = distance ? Math.min(Math.max(window.scrollY / distance, 0), 1) : 0;
      if (header) header.classList.toggle("is-scrolled", window.scrollY > 8);
      if (progress) progress.style.transform = "scaleX(" + value.toFixed(4) + ")";
      scheduled = false;
    }

    function schedule() {
      if (scheduled) return;
      scheduled = true;
      window.requestAnimationFrame(update);
    }

    update();
    window.addEventListener("scroll", schedule, { passive: true });
    window.addEventListener("resize", schedule, { passive: true });
  }

  function initCommandCopy() {
    var buttons = document.querySelectorAll("[data-copy-command]");

    Array.prototype.forEach.call(buttons, function (button) {
      var command = document.getElementById("install-command");
      if (!command) return;
      button.setAttribute("aria-live", "polite");

      function finish(ok) {
        var normal = button.getAttribute("data-copy-default") || "copy";
        var result = ok ? button.getAttribute("data-copy-success") : button.getAttribute("data-copy-error");
        button.textContent = result || (ok ? "copied" : "copy failed");
        window.clearTimeout(button.copyResetTimer);
        button.copyResetTimer = window.setTimeout(function () {
          button.textContent = normal;
        }, 1600);
      }

      function fallbackCopy(text) {
        var area = document.createElement("textarea");
        area.value = text;
        area.setAttribute("readonly", "");
        area.style.position = "fixed";
        area.style.opacity = "0";
        document.body.appendChild(area);
        area.select();
        try {
          finish(document.execCommand("copy"));
        } catch (error) {
          finish(false);
        }
        document.body.removeChild(area);
        button.focus();
      }

      button.addEventListener("click", function () {
        var text = command.textContent;
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text).then(function () {
            finish(true);
          }, function () {
            fallbackCopy(text);
          });
        } else {
          fallbackCopy(text);
        }
      });
    });
  }

  function childIndex(element) {
    var index = 0;
    var sibling = element;
    while (sibling.previousElementSibling) {
      sibling = sibling.previousElementSibling;
      index += 1;
    }
    return index;
  }

  function initReveals(motionQuery) {
    var selector = [
      ".landing-page .hero__copy > *",
      ".landing-page .terminal-card",
      ".landing-page .trust-stat",
      ".landing-page .section-heading > *",
      ".landing-page .route-card",
      ".landing-page .command-panel",
      ".landing-page .arch-flow",
      ".landing-page .arch-note",
      ".landing-page .score-card",
      ".landing-page .evidence-card",
      ".landing-page .workload-card",
      ".landing-page .docs-map__group",
      ".landing-page .safety-banner",
      ".docs-page .doc-intro > *",
      ".docs-page .doc-grid > *",
      ".docs-page .path-choice",
      ".docs-page .evidence-key > div",
      ".docs-page .doc-pager__item"
    ].join(",");
    var targets = Array.prototype.slice.call(document.querySelectorAll(selector));
    var observer;

    function clearReveal(element) {
      element.classList.remove("reveal-item", "is-visible");
      element.style.removeProperty("--reveal-delay");
    }

    function show(element) {
      if (element.classList.contains("is-visible")) return;
      element.classList.add("is-visible");
      var delay = Number(element.getAttribute("data-reveal-delay")) || 0;
      window.setTimeout(function () { clearReveal(element); }, 760 + delay);
      if (observer) observer.unobserve(element);
    }

    targets.forEach(function (element) {
      var delay = Math.min(childIndex(element), 4) * 70;
      element.classList.add("reveal-item");
      element.setAttribute("data-reveal-delay", String(delay));
      element.style.setProperty("--reveal-delay", delay + "ms");
    });

    if ("IntersectionObserver" in window) {
      observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) show(entry.target);
        });
      }, { rootMargin: "0px 0px -7% 0px", threshold: 0.06 });
      targets.forEach(function (element) { observer.observe(element); });
    } else {
      targets.forEach(show);
    }

    function disableMotion(event) {
      if (!event.matches) return;
      document.documentElement.classList.remove("motion-enabled");
      targets.forEach(clearReveal);
      if (observer) observer.disconnect();
    }

    if (motionQuery.addEventListener) motionQuery.addEventListener("change", disableMotion);
  }

  function initSpotlights() {
    if (!window.matchMedia("(pointer: fine)").matches) return;
    var selector = [
      ".terminal-card",
      ".route-card",
      ".arch-flow",
      ".arch-note",
      ".score-card",
      ".evidence-card",
      ".workload-card",
      ".docs-map__group",
      ".safety-banner",
      ".doc-card",
      ".path-choice",
      ".doc-pager__item"
    ].join(",");

    document.querySelectorAll(selector).forEach(function (surface) {
      var frame = 0;
      var latestEvent;
      surface.classList.add("spotlight-surface");
      surface.addEventListener("pointermove", function (event) {
        latestEvent = event;
        if (frame) return;
        frame = window.requestAnimationFrame(function () {
          var bounds = surface.getBoundingClientRect();
          surface.style.setProperty("--spot-x", (latestEvent.clientX - bounds.left).toFixed(1) + "px");
          surface.style.setProperty("--spot-y", (latestEvent.clientY - bounds.top).toFixed(1) + "px");
          frame = 0;
        });
      }, { passive: true });
    });
  }

  ready(function () {
    var motionQuery = window.matchMedia("(prefers-reduced-motion: reduce)");
    initScrollFeedback();
    initCommandCopy();

    if (motionQuery.matches) return;
    document.documentElement.classList.add("motion-enabled");
    initReveals(motionQuery);
    initSpotlights();
  });
})();
