/*!
 * LuminaKit — GlassPanel (optional enhancement)
 * Adds a pointer-following specular sheen to .lg-panel--sheen.
 *
 * The panel works without this file — it is only needed if you want the sheen.
 * Elements without the --sheen class are ignored.
 *
 * Usage:
 *   <link rel="stylesheet" href="glass-panel/lumina-glass-panel.css">
 *   <div class="lg-panel lg-panel--sheen">...</div>
 *   <script src="glass-panel/lumina-glass-panel.js"></script>
 */

(function (global) {
  "use strict";

  var SELECTOR = ".lg-panel--sheen";
  var EASE = 0.14;

  var states = new Map();
  var rafId = null;

  function attach(el) {
    if (states.has(el)) return;

    if (!el.querySelector(":scope > .lg-panel__sheen")) {
      var layer = document.createElement("span");
      layer.className = "lg-panel__sheen";
      layer.setAttribute("aria-hidden", "true");
      el.appendChild(layer);
    }

    var rect = el.getBoundingClientRect();
    var state = {
      el: el,
      targetX: rect.width / 2,
      targetY: rect.height / 2,
      x: rect.width / 2,
      y: rect.height / 2,
      hovering: false
    };
    states.set(el, state);

    function read(event) {
      var r = el.getBoundingClientRect();
      return { x: event.clientX - r.left, y: event.clientY - r.top };
    }

    el.addEventListener("pointerenter", function (event) {
      var p = read(event);
      if (!state.hovering) {
        state.x = p.x;
        state.y = p.y;
      }
      state.targetX = p.x;
      state.targetY = p.y;
      state.hovering = true;
      kick();
    });

    el.addEventListener("pointermove", function (event) {
      var p = read(event);
      state.targetX = p.x;
      state.targetY = p.y;
      kick();
    });

    el.addEventListener("pointerleave", function () {
      state.hovering = false;
      var r = el.getBoundingClientRect();
      state.targetX = r.width / 2;
      state.targetY = r.height / 2;
      kick();
    });
  }

  function detach(el) {
    states.delete(el);
  }

  function kick() {
    if (rafId !== null) return;
    rafId = requestAnimationFrame(tick);
  }

  function tick() {
    rafId = null;
    var busy = false;

    states.forEach(function (state) {
      var dx = state.targetX - state.x;
      var dy = state.targetY - state.y;

      if (Math.abs(dx) < 0.1 && Math.abs(dy) < 0.1) {
        state.x = state.targetX;
        state.y = state.targetY;
      } else {
        state.x += dx * EASE;
        state.y += dy * EASE;
        busy = true;
      }

      state.el.style.setProperty("--lgp-px", state.x.toFixed(1) + "px");
      state.el.style.setProperty("--lgp-py", state.y.toFixed(1) + "px");
      state.el.style.setProperty("--lgp-sheen", state.hovering ? "1" : "0");
    });

    if (busy) rafId = requestAnimationFrame(tick);
  }

  function init(root) {
    var scope = root || document;
    var nodes = scope.querySelectorAll(SELECTOR);
    for (var i = 0; i < nodes.length; i++) attach(nodes[i]);
    return nodes.length;
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      init();
    });
  } else {
    init();
  }

  global.LuminaGlassPanel = { init: init, attach: attach, detach: detach };
})(window);
