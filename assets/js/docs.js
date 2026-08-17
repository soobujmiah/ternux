/* ternux documentation shell — dependency-free navigation, TOC, and paging */
(function () {
  "use strict";

  function ready(fn) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", fn);
    } else {
      fn();
    }
  }

  function normalizePath(value) {
    var path = (value || "/").split("?")[0].split("#")[0];
    path = path.replace(/\/index\.html$/, "/");
    path = path.replace(/\/{2,}/g, "/");
    if (path.length > 1 && /\/$/.test(path) === false && /\.html$/.test(path) === false) {
      path += "/";
    }
    return path;
  }

  function slugify(value) {
    return value
      .toLowerCase()
      .trim()
      .replace(/[^\w\u0980-\u09ff]+/g, "-")
      .replace(/^-+|-+$/g, "") || "section";
  }

  ready(function () {
    var body = document.body;
    var menuButton = document.querySelector("[data-menu-button]");
    var sidebar = document.querySelector("[data-docs-sidebar]");
    var scrim = document.querySelector("[data-sidebar-scrim]");
    var filter = document.querySelector("[data-doc-filter]");
    var docLinks = Array.prototype.slice.call(document.querySelectorAll("[data-doc-link]"));
    var currentPath = normalizePath(window.location.pathname);

    function setMenu(open, restoreFocus) {
      body.classList.toggle("menu-open", open);
      if (menuButton) menuButton.setAttribute("aria-expanded", open ? "true" : "false");
      if (sidebar) sidebar.setAttribute("aria-hidden", open ? "false" : "true");
      if (open && filter) window.setTimeout(function () { filter.focus(); }, 180);
      if (!open && restoreFocus && menuButton) menuButton.focus();
    }

    if (menuButton) {
      menuButton.addEventListener("click", function () {
        setMenu(!body.classList.contains("menu-open"));
      });
    }
    if (scrim) scrim.addEventListener("click", function () { setMenu(false, true); });
    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape" && body.classList.contains("menu-open")) {
        setMenu(false, true);
      }
      if (event.key === "/" && filter && !/input|textarea|select/i.test(document.activeElement.tagName)) {
        event.preventDefault();
        if (window.matchMedia("(max-width: 960px)").matches && !body.classList.contains("menu-open")) {
          setMenu(true);
        } else {
          filter.focus();
        }
      }
    });

    /* Mark the canonical sidebar item. pathname includes the Jekyll baseurl,
       so matching by the canonical URL suffix keeps local and hosted builds aligned. */
    var activeIndex = -1;
    docLinks.forEach(function (link, index) {
      var target = normalizePath(link.getAttribute("data-doc-url"));
      var isActive = currentPath === target || currentPath.slice(-target.length) === target;
      if (isActive) {
        link.classList.add("is-current");
        link.setAttribute("aria-current", "page");
        activeIndex = index;
      }
      link.addEventListener("click", function () { setMenu(false); });
    });

    /* Previous/next follows the exact order in _data/docs.yml. */
    var pager = document.querySelector("[data-doc-pager]");
    if (pager && activeIndex >= 0) {
      var isBn = document.documentElement.lang === "bn";
      [activeIndex - 1, activeIndex + 1].forEach(function (index, direction) {
        if (index < 0 || index >= docLinks.length) return;
        var source = docLinks[index];
        var item = document.createElement("a");
        item.className = "doc-pager__item doc-pager__item--" + (direction === 0 ? "previous" : "next");
        item.href = source.href;
        var label = document.createElement("span");
        label.textContent = direction === 0 ? (isBn ? "আগের পৃষ্ঠা" : "Previous") : (isBn ? "পরের পৃষ্ঠা" : "Next");
        var title = document.createElement("strong");
        title.textContent = source.textContent.trim();
        var arrow = document.createElement("i");
        arrow.setAttribute("aria-hidden", "true");
        arrow.textContent = direction === 0 ? "←" : "→";
        item.appendChild(label);
        item.appendChild(title);
        item.appendChild(arrow);
        pager.appendChild(item);
      });
    }

    /* Filter only the navigation index; it is deliberately transparent rather
       than pretending to be a full-text search. */
    if (filter) {
      filter.addEventListener("input", function () {
        var query = filter.value.trim().toLocaleLowerCase(document.documentElement.lang || "en");
        document.querySelectorAll("[data-nav-group]").forEach(function (group) {
          var visible = 0;
          group.querySelectorAll("[data-nav-item]").forEach(function (item) {
            var match = !query || item.textContent.toLocaleLowerCase(document.documentElement.lang || "en").indexOf(query) !== -1;
            item.hidden = !match;
            if (match) visible += 1;
          });
          group.hidden = visible === 0;
        });
      });
    }

    /* Build a local table of contents from rendered h2/h3 headings. */
    var article = document.querySelector(".doc-article");
    var toc = document.querySelector("[data-page-toc]");
    var tocAside = document.querySelector(".page-toc");
    if (article && toc) {
      var headings = Array.prototype.slice.call(article.querySelectorAll("h2, h3"));
      var used = {};
      headings.forEach(function (heading) {
        var id = heading.id || slugify(heading.textContent);
        if (used[id]) {
          used[id] += 1;
          id += "-" + used[id];
        } else {
          used[id] = 1;
        }
        heading.id = id;

        var anchor = document.createElement("a");
        anchor.href = "#" + id;
        anchor.textContent = heading.textContent.replace(/^#+\s*/, "").trim();
        anchor.className = heading.tagName === "H3" ? "toc-h3" : "toc-h2";
        anchor.addEventListener("click", function () {
          toc.querySelectorAll("a").forEach(function (item) { item.classList.remove("is-active"); });
          anchor.classList.add("is-active");
        });
        toc.appendChild(anchor);
      });

      if (headings.length === 0 && tocAside) tocAside.hidden = true;

      if ("IntersectionObserver" in window && headings.length) {
        var visibleHeadings = {};
        var observer = new IntersectionObserver(function (entries) {
          entries.forEach(function (entry) {
            if (entry.isIntersecting) visibleHeadings[entry.target.id] = entry.target.getBoundingClientRect().top;
            else delete visibleHeadings[entry.target.id];
          });
          var visible = Object.keys(visibleHeadings).sort(function (a, b) { return visibleHeadings[a] - visibleHeadings[b]; });
          if (!visible.length) return;
          toc.querySelectorAll("a").forEach(function (link) {
            link.classList.toggle("is-active", link.getAttribute("href") === "#" + visible[0]);
          });
        }, { rootMargin: "-96px 0px -68% 0px", threshold: [0, 1] });
        headings.forEach(function (heading) { observer.observe(heading); });
      }
    }

    /* Desktop sidebars are always available to assistive technology. */
    function updateSidebarA11y() {
      if (!sidebar) return;
      if (window.matchMedia("(min-width: 961px)").matches) {
        body.classList.remove("menu-open");
        if (menuButton) menuButton.setAttribute("aria-expanded", "false");
        sidebar.removeAttribute("aria-hidden");
      } else if (!body.classList.contains("menu-open")) {
        sidebar.setAttribute("aria-hidden", "true");
      }
    }
    updateSidebarA11y();
    window.addEventListener("resize", updateSidebarA11y);
  });
})();
