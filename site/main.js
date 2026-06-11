// Footer year
document.getElementById("year").textContent = new Date().getFullYear();

// Copy-to-clipboard on any [data-copy] command box
const CHECK_ICON =
  '<svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>';

document.querySelectorAll(".cmd").forEach((box) => {
  const btn = box.querySelector(".copy");
  if (!btn) return;
  btn.addEventListener("click", async () => {
    const text = (box.dataset.copy || "").replace(/&#10;/g, "\n");
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      // Fallback for non-secure contexts
      const ta = document.createElement("textarea");
      ta.value = text;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      ta.remove();
    }
    if (btn.classList.contains("copied")) return; // mid-animation, ignore
    const original = btn.innerHTML;
    btn.innerHTML = CHECK_ICON;
    btn.classList.add("copied");
    setTimeout(() => {
      btn.innerHTML = original;
      btn.classList.remove("copied");
    }, 1600);
  });
});

// Scroll-reveal: fade sections/cards up as they enter the viewport.
(() => {
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  // Elements to reveal on scroll.
  const targets = document.querySelectorAll(
    ".section h2, .section .sub, .card, .tool, .checks, .terminal, .split > div, .cta-inner > *"
  );
  targets.forEach((el) => el.classList.add("reveal"));

  // Stagger items inside the same grid for a cascading effect.
  document.querySelectorAll(".grid, .tool-grid").forEach((grid) => {
    [...grid.children].forEach((child, i) =>
      child.setAttribute("data-d", String((i % 5) + 1))
    );
  });

  if (reduce || !("IntersectionObserver" in window)) {
    targets.forEach((el) => el.classList.add("in"));
    return;
  }

  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          e.target.classList.add("in");
          io.unobserve(e.target);
        }
      });
    },
    { threshold: 0.12, rootMargin: "0px 0px -8% 0px" }
  );
  targets.forEach((el) => io.observe(el));
})();

// Install tabs
const tabs = document.querySelectorAll(".tab");
const panels = document.querySelectorAll(".tab-panel");
tabs.forEach((tab) => {
  tab.addEventListener("click", () => {
    const name = tab.dataset.tab;
    tabs.forEach((t) => t.classList.toggle("is-active", t === tab));
    panels.forEach((p) =>
      p.classList.toggle("is-active", p.dataset.panel === name)
    );
  });
});
