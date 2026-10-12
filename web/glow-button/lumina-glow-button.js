/*!
 * LuminaKit — GlowButton
 * Drives the pointer-following glow for .lg-btn elements.
 *
 * Behaviour:
 *   - pointer position is smoothed with a per-frame lerp, so the glow trails
 *     slightly behind the cursor instead of snapping to it
 *   - every element only animates while it is hovered or decaying back to rest
 *   - safe to call init() again after inserting new buttons
 *
 * Usage:
 *   <link rel="stylesheet" href="glow-button/lumina-glow-button.css">
 *   <script src="glow-button/lumina-glow-button.js"></script>
 *   <button class="lg-btn">Continue</button>
 *
 * Or explicitly: LuminaGlowButton.init()
 */

(function (global) {
  "use strict";

  var SELECTOR = ".lg-btn";
  var EASE = 0.18; // 0 = frozen, 1 = no smoothing

  /** @type {Map<Element, State>} */
  var states = new Map();
  var rafId = null;

  /**
   * @typedef {Object} State
   * @property {HTMLElement} el
   * @property {number} targetX
   * @property {number} targetY
   * @property {number} x
   * @property {number} y
   * @property {boolean} hovering
   * @property {boolean} active
   */

  function readPointer(el, event) {
    var rect = el.getBoundingClientRect();
    return {
      x: event.clientX - rect.left,
      y: event.clientY - rect.top
    };
  }

  function write(el, state) {
    el.style.setProperty("--lg-mx", state.x.toFixed(1) + "px");
    el.style.setProperty("--lg-my", state.y.toFixed(1) + "px");
    el.style.setProperty("--lg-hover", state.hovering ? "1" : "0");
  }

  function centerState(el) {
    var rect = el.getBoundingClientRect();
    return {
      x: rect.width / 2,
      y: rect.height / 2
    };
  }

  function attach(el) {
    if (states.has(el)) return;

    var start = centerState(el);
    /** @type {State} */
    var state = {
      el: el,
      targetX: start.x,
      targetY: start.y,
      x: start.x,
      y: start.y,
      hovering: false,
      active: false
    };
    states.set(el, state);

    // Wrap the contents so the label can be lifted above the glow layers.
    // Inline text paints below any positioned pseudo-element, so without this
    // wrapper the glow would cover the label.
    if (!el.querySelector(":scope > .lg-label")) {
      var label = document.createElement("span");
      label.className = "lg-label";
      while (el.firstChild) label.appendChild(el.firstChild);
      el.appendChild(label);
    }

    if (!el.querySelector(".lg-dot")) {
      var dot = document.createElement("span");
      dot.className = "lg-dot";
      dot.setAttribute("aria-hidden", "true");
      el.appendChild(dot);
    }

    el.addEventListener("pointerenter", function (event) {
      if (state.el.matches(":disabled, [aria-disabled='true']")) return;
      var p = readPointer(el, event);
      // start the glow at the entry point so it does not fly in from center
      if (!state.hovering) {
        state.x = p.x;
        state.y = p.y;
      }
      state.targetX = p.x;
      state.targetY = p.y;
      state.hovering = true;
      state.active = true;
      kick();
    });

    el.addEventListener("pointermove", function (event) {
      var p = readPointer(el, event);
      state.targetX = p.x;
      state.targetY = p.y;
      state.active = true;
      kick();
    });

    el.addEventListener("pointerleave", function () {
      state.hovering = false;
      var c = centerState(el);
      state.targetX = c.x;
      state.targetY = c.y;
      state.active = true;
      kick();
    });

    // touch / pen: follow while pressing
    el.addEventListener("pointerdown", function (event) {
      var p = readPointer(el, event);
      state.targetX = p.x;
      state.targetY = p.y;
      state.hovering = true;
      state.active = true;
      kick();
    });

    el.addEventListener("pointerup", function () {
      if (!el.matches(":hover")) state.hovering = false;
      state.active = true;
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
    var stillActive = false;

    states.forEach(function (state) {
      var dx = state.targetX - state.x;
      var dy = state.targetY - state.y;

      if (Math.abs(dx) < 0.08 && Math.abs(dy) < 0.08) {
        state.x = state.targetX;
        state.y = state.targetY;
        if (!state.hovering) state.active = false;
        write(state.el, state);
        return;
      }

      state.x += dx * EASE;
      state.y += dy * EASE;
      write(state.el, state);
      stillActive = true;
    });

    // keep animating while anything is still settling
    if (stillActive) {
      rafId = requestAnimationFrame(tick);
    }
  }

  function init(root) {
    var scope = root || document;
    var nodes = scope.querySelectorAll(SELECTOR);
    for (var i = 0; i < nodes.length; i++) attach(nodes[i]);
    return nodes.length;
  }

  // Auto-init, and again after the DOM is ready for deferred scripts.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      init();
    });
  } else {
    init();
  }

  global.LuminaGlowButton = {
    init: init,
    attach: attach,
    detach: detach
  };
})(window);
