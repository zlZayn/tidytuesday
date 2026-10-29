/* ==========================================================================
   hub.js — 站点入口页（根 index.html）的抽屉、悬浮提示与按需加载逻辑
   --------------------------------------------------------------------------
   这个文件不直接被浏览器加载：code/update_site.R 读取它，内联进
   assets/site/index.template.html 的脚本占位符，产出根 index.html。
   （此处刻意不写出占位符的字面写法——脚本会校验替换后不残留占位符。）

   加载策略（多文件 + 按需加载）：
     - 进入页面即加载**最新一周**（列表首项），只有这一份报告被请求。
     - 之后选某周时，若该周面板还没建，才创建 <iframe> 并设 src。
     - 已创建的面板留在 DOM 中，切回只切 data-active，零请求。

   抽屉交互：
     - 打开：点顶栏图标按钮 / 快捷键 m
     - 关闭：点遮罩、按 Esc、选中某个周之后自动收起
     - 焦点：打开移入抽屉，关闭回到唤出按钮；Tab 在抽屉内循环

   悬浮提示：任何带 data-tip 的元素都会显示统一的黑色提示框
   （外观对齐报告内 tippy），鼠标悬停与键盘聚焦都会触发。
   ========================================================================== */
(function () {
  "use strict";

  var data = JSON.parse(document.getElementById("hub-data").textContent);
  var weeks = data.weeks;

  var listEl   = document.getElementById("weeks-list");
  var stageEl  = document.getElementById("stage");
  var nowEl    = document.getElementById("hub-now");
  var countEl  = document.getElementById("hub-count");
  var genEl    = document.getElementById("hub-gen");
  var drawerEl = document.getElementById("hub-drawer");
  var scrimEl  = document.getElementById("hub-scrim");
  var menuEl   = document.getElementById("hub-menu");
  var closeEl  = document.getElementById("hub-close");

  var FOCUSABLE = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';

  /* 面板表：index -> { panel, frame }
     用来判断「已建则切显隐、未建才创建」。 */
  var panels = {};
  var lastFocus = null;

  function el(tag, cls) {
    var n = document.createElement(tag);
    if (cls) { n.className = cls; }
    return n;
  }

  /* ---------------- 悬浮提示 ---------------- */

  /* 显示/隐藏的延迟（毫秒）。
     悬停要有「等一会儿才浮现」的手感，和报告里 tippy 的观感一致；
     鼠标快速扫过时不弹提示，避免闪烁。
     键盘聚焦不延迟：键盘用户等 0.4 秒才看到提示是纯粹的阻碍。 */
  var TIP_SHOW_DELAY = 400;
  var TIP_HIDE_DELAY = 80;

  var tip = el("div", "hub-tip");
  tip.id = "hub-tip";
  tip.setAttribute("role", "tooltip");
  document.body.appendChild(tip);
  var tipFor = null;
  var tipShowTimer = null;
  var tipHideTimer = null;

  function tipClearTimers() {
    if (tipShowTimer) { clearTimeout(tipShowTimer); tipShowTimer = null; }
    if (tipHideTimer) { clearTimeout(tipHideTimer); tipHideTimer = null; }
  }

  function tipReveal(target) {
    var text = target.getAttribute("data-tip");
    if (!text) { return; }
    tipFor = target;
    tip.textContent = text;
    tipPlace(target);                  /* 先量好位置再显示，避免出现时跳动 */
    tip.setAttribute("data-show", "true");
  }

  /* delay 缺省用 TIP_SHOW_DELAY；键盘聚焦传 0 */
  function tipSchedule(target, delay) {
    tipClearTimers();
    tipFor = target;
    if (delay <= 0) { tipReveal(target); return; }
    tipShowTimer = setTimeout(function () {
      tipShowTimer = null;
      /* 延迟期间目标可能已被移出或被换掉 */
      if (tipFor === target && document.contains(target)) { tipReveal(target); }
    }, delay);
  }

  function tipPlace(target) {
    var r = target.getBoundingClientRect();
    var tr = tip.getBoundingClientRect();
    var place = "bottom";
    var top = r.bottom + 8;
    if (top + tr.height > window.innerHeight - 4) {   /* 底部放不下就翻到上方 */
      top = r.top - tr.height - 8;
      place = "top";
    }
    var left = r.left + r.width / 2 - tr.width / 2;
    left = Math.max(8, Math.min(left, window.innerWidth - tr.width - 8));
    tip.style.left = Math.round(left) + "px";
    tip.style.top = Math.round(Math.max(4, top)) + "px";
    tip.setAttribute("data-place", place);
    /* 箭头始终指向目标中心，而不是提示框中心（提示框可能被夹到屏幕内） */
    tip.style.setProperty("--arrow-x",
      Math.round(r.left + r.width / 2 - left) + "px");
  }

  /* immediate=true 立即隐藏（点走、Esc、滚动等场景）；否则留一点宽限时间，
     使鼠标在相邻元素间移动时提示不闪断。 */
  function tipHide(immediate) {
    tipClearTimers();
    tipFor = null;
    var doHide = function () {
      tipHideTimer = null;
      tip.setAttribute("data-show", "false");
    };
    if (immediate) { doHide(); return; }
    tipHideTimer = setTimeout(doHide, TIP_HIDE_DELAY);
  }

  function tipFrom(node) {
    return (node && node.closest) ? node.closest("[data-tip]") : null;
  }

  document.addEventListener("mouseover", function (e) {
    var t = tipFrom(e.target);
    if (!t) { if (tipFor) { tipHide(false); } return; }
    if (t === tipFor && (tipShowTimer || tip.getAttribute("data-show") === "true")) {
      return;                              /* 已在同一目标上，别重置计时 */
    }
    tipSchedule(t, TIP_SHOW_DELAY);
  });

  document.addEventListener("mouseout", function (e) {
    if (!tipFor && !tipShowTimer) { return; }
    var to = tipFrom(e.relatedTarget);
    if (to === tipFor) { return; }
    tipHide(false);
  });

  /* 键盘聚焦立即显示（与 aria-label 互补，不替代） */
  document.addEventListener("focusin", function (e) {
    var t = tipFrom(e.target);
    if (t) { tipSchedule(t, 0); } else { tipHide(true); }
  });
  document.addEventListener("focusout", function () { tipHide(false); });

  document.addEventListener("click", function () { tipHide(true); });
  window.addEventListener("resize", function () { tipHide(true); });
  window.addEventListener("scroll", function () { tipHide(true); }, true);

  /* ---------------- 抽屉开关 ---------------- */

  /* 两种形态共用同一个 <nav>：
       docked（宽屏默认）—— 钉在顶栏下方的常驻左栏，内容区右移，无遮罩、不抢焦点
       overlay（窄屏 / 手动唤出）—— 原来的浮层抽屉：覆盖内容 + 遮罩 + 焦点陷阱
     形态记在 <body data-nav>，CSS 按它切换布局；JS 只负责状态与焦点语义。 */
  var NAV_MIN = 900;                 /* 与 hub.css 的 899px 断点对齐 */

  function navMode() {
    return document.body.getAttribute("data-nav");
  }
  function setNavMode(mode) {
    document.body.setAttribute("data-nav", mode);
    var docked = (mode === "docked");
    drawerEl.setAttribute("data-open", docked ? "true" : "false");
    if (!docked) {
      /* 浮层态关闭时同步把遮罩收掉；钉住态遮罩由 CSS 直接隐藏 */
      scrimEl.setAttribute("data-open", "false");
      scrimEl.setAttribute("aria-hidden", "true");
    }
    /* 钉住态不是模态：不该有 aria-modal，也不该把 Tab 锁在侧栏里 */
    drawerEl.setAttribute("aria-modal", docked ? "false" : "true");
    drawerEl.setAttribute("role", docked ? "navigation" : "dialog");
    menuEl.setAttribute("aria-expanded", docked ? "true" : "false");
  }

  function drawerOpen() {
    return drawerEl.getAttribute("data-open") === "true";
  }

  function openDrawer() {
    if (drawerOpen()) { return; }
    lastFocus = document.activeElement;
    drawerEl.setAttribute("data-open", "true");
    scrimEl.setAttribute("data-open", "true");
    scrimEl.setAttribute("aria-hidden", "false");
    menuEl.setAttribute("aria-expanded", "true");
    /* 焦点移入抽屉：优先当前周，其次第一个周次（键盘用户可直接回车选中），
       最后才退回抽屉内第一个可聚焦元素。 */
    var target = listEl.querySelector('.tab[aria-current="true"]') ||
                 listEl.querySelector(".tab") ||
                 drawerEl.querySelector(FOCUSABLE);
    if (target) { target.focus(); }
  }

  function closeDrawer() {
    if (!drawerOpen()) { return; }
    tipHide(true);
    drawerEl.setAttribute("data-open", "false");
    scrimEl.setAttribute("data-open", "false");
    scrimEl.setAttribute("aria-hidden", "true");
    menuEl.setAttribute("aria-expanded", "false");
    /* 焦点回到唤出按钮 */
    var back = (lastFocus && document.contains(lastFocus)) ? lastFocus : menuEl;
    back.focus();
  }

  /* 顶栏按钮：从钉住态收起 → 内容区铺满且不弹浮层；
     收起后再点 → 宽屏重新钉住，窄屏才弹浮层。 */
  function collapseNav() {
    tipHide(true);
    drawerEl.setAttribute("data-open", "false");
    scrimEl.setAttribute("data-open", "false");
    scrimEl.setAttribute("aria-hidden", "true");
    menuEl.setAttribute("aria-expanded", "false");
    document.body.setAttribute("data-nav", "collapsed");
    storeCollapsed(true);              /* 记住「用户想看满宽」，刷新后仍收起 */
  }

  menuEl.addEventListener("click", function () {
    if (window.innerWidth >= NAV_MIN) {
      if (navMode() === "docked") { collapseNav(); }
      else { setNavMode("docked"); storeCollapsed(false); }
      return;
    }
    if (drawerOpen()) { closeDrawer(); } else { openDrawer(); }
  });
  closeEl.addEventListener("click", function () {
    if (navMode() === "docked") { collapseNav(); } else { closeDrawer(); }
  });
  scrimEl.addEventListener("click", closeDrawer);

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") {
      /* 钉住态不吞 Esc：它不是模态层，用户按 Esc 未必想收起侧栏；
         浮层态才关（这是浮层的约定动作）。 */
      if (drawerOpen() && navMode() !== "docked") { e.preventDefault(); closeDrawer(); }
      else { tipHide(true); }
      return;
    }
    /* 快捷键：m 唤出 / 收起（输入框里不触发） */
    if ((e.key === "m" || e.key === "M") && !e.ctrlKey && !e.metaKey && !e.altKey) {
      var tag = (e.target && e.target.tagName || "").toLowerCase();
      if (tag !== "input" && tag !== "textarea" && !e.target.isContentEditable) {
        e.preventDefault();
        menuEl.click();                  /* 与点按钮同一套语义，避免两处分支漂移 */
      }
      return;
    }
    /* Tab 循环只约束浮层态：钉住的侧栏是常驻导航，不该把键盘关在里面 */
    if (e.key === "Tab" && drawerOpen() && navMode() !== "docked") {
      var items = Array.prototype.filter.call(
        drawerEl.querySelectorAll(FOCUSABLE),
        function (n) { return n.offsetParent !== null; }
      );
      if (items.length === 0) { return; }
      var first = items[0];
      var last = items[items.length - 1];
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault(); last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault(); first.focus();
      }
    }
  });

  /* ---------------- 周列表 ---------------- */

  /* 标题与日期之间不用文本分隔符：间隔由 CSS 给（.d 的 margin-right），
     「数据检查」这类标记走独立的 .kind 小标签而不是括号文字。 */
  function buildWeek(week, index) {
    var li = el("li", "week");

    var tab = el("button", "tab");
    tab.type = "button";
    tab.setAttribute("aria-current", "false");
    tab.setAttribute("aria-controls", "panel-" + index);
    /* 标题过长时会被省略号截断，提示里给完整信息 */
    tab.setAttribute("data-tip", week.date + " " + week.title +
                               (week.kind ? "（" + week.kind + "）" : ""));

    var t = el("span", "t");
    t.textContent = week.title;
    if (week.kind) {
      var k = el("span", "kind");
      k.textContent = week.kind;
      t.appendChild(k);
    }
    var d = el("span", "d");
    d.textContent = week.date;
    tab.appendChild(t);
    tab.appendChild(d);
    tab.addEventListener("click", function () {
      activate(index);
      /* 浮层态：选中后自动收起，把屏幕还给报告；
         钉住态：侧栏是常驻的，选中不动它（否则每选一周都要重新打开）。 */
      if (navMode() !== "docked") { closeDrawer(); }
    });
    li.appendChild(tab);

    /* 每周 tab 旁边的 GitHub 八爪鱼：指向该周目录，不参与选中 */
    var src = el("a", "src");
    src.href = week.repo;
    src.target = "_blank";
    src.rel = "noopener";
    src.setAttribute("aria-label", week.date + " 在 GitHub 上的目录");
    src.setAttribute("data-tip", "在 GitHub 查看该周目录");
    src.innerHTML = '<svg class="octo" viewBox="0 0 16 16" aria-hidden="true">' +
                    '<use href="#i-octo"></use></svg>';
    li.appendChild(src);

    listEl.appendChild(li);
  }

  /* ---------------- 按需加载 ---------------- */

  function activate(index) {
    var week = weeks[index];

    nowEl.innerHTML = "";
    var d = el("span", "d");
    d.textContent = week.date;
    var t = el("span", "t");
    t.textContent = week.title;
    if (week.kind) {
      var nk = el("span", "kind");
      nk.textContent = week.kind;
      t.appendChild(nk);
    }
    nowEl.appendChild(d);
    nowEl.appendChild(t);

    var tabs = listEl.querySelectorAll(".tab");
    for (var i = 0; i < tabs.length; i++) {
      tabs[i].setAttribute("aria-current", i === index ? "true" : "false");
    }

    /* 首次选中才创建 iframe —— 此前该周不产生任何网络请求 */
    var entry = panels[index];
    if (!entry) {
      var panel = el("div", "panel");
      panel.id = "panel-" + index;

      var hint = el("div", "hint");
      hint.textContent = "正在加载 " + week.date + "（" + week.title + "）…";
      panel.appendChild(hint);

      var frame = document.createElement("iframe");
      frame.title = week.title;
      /* 只隐藏提示，不动 iframe 本身：
         在 load 回调里替换/移除 iframe 节点会触发重复加载甚至无限循环。 */
      frame.addEventListener("load", function () { hint.hidden = true; }, { once: true });

      panel.appendChild(frame);
      stageEl.appendChild(panel);
      frame.src = week.src;   /* 赋值 src 的这一刻才真正发起请求 */

      entry = panels[index] = { panel: panel, frame: frame };
    }

    /* 只切显隐：已加载过的周留在 DOM，切回不重新请求 */
    for (var k in panels) {
      if (Object.prototype.hasOwnProperty.call(panels, k)) {
        panels[k].panel.setAttribute("data-active", String(Number(k) === index));
      }
    }
  }

  weeks.forEach(buildWeek);

  /* 周数进小标签，生成日期单独一行（它指「本页何时生成」，不是某一周的日期） */
  countEl.textContent = weeks.length + " 周";
  genEl.textContent = "生成于 " + data.generated;

  /* ---------------- 初始形态 ---------------- */

  /* 进入页面时的默认：宽屏把周列表钉成左侧栏（内容区右移），窄屏保持收起，
   需要时才点按钮 / 按 M 唤出浮层。
   用户若手动收起过，本次会话内记住这个选择（sessionStorage，跨刷新生效但
   不跨标签页共享；隐私模式下 setItem 可能抛错，一律吞掉）。
   注意：钉住态不移动焦点 —— 页面打开时用户要读报告，不该被拽进侧栏。 */
  var NAV_KEY = "hub-nav-collapsed";

  function storedCollapsed() {
    try { return window.sessionStorage.getItem(NAV_KEY) === "1"; }
    catch (err) { return false; }
  }
  function storeCollapsed(v) {
    try { window.sessionStorage.setItem(NAV_KEY, v ? "1" : "0"); }
    catch (err) { /* 隐私模式 / 禁用存储：退化成每次都用默认值 */ }
  }

  function applyInitialNav() {
    if (window.innerWidth < NAV_MIN) {
      setNavMode("collapsed");
      return;
    }
    setNavMode(storedCollapsed() ? "collapsed" : "docked");
  }

  applyInitialNav();

  /* 跨断点时重新决定形态：从宽到窄必须收起（否则侧栏会挤掉半个报告），
     从窄到宽恢复「默认展开」但尊重本会话内的手动收起。 */
  var resizeTimer = null;
  window.addEventListener("resize", function () {
    if (resizeTimer) { clearTimeout(resizeTimer); }
    resizeTimer = setTimeout(function () {
      resizeTimer = null;
      var wide = window.innerWidth >= NAV_MIN;
      if (!wide) {
        if (navMode() === "docked") { setNavMode("collapsed"); }
      } else if (navMode() === "collapsed" && !storedCollapsed()) {
        setNavMode("docked");
      }
    }, 150);
  });

  /* 进入页面直接展示最新一周（列表首项 = 目录名最大）：
     只请求这一份报告，其余周仍需用户主动选择才加载。 */
  if (weeks.length > 0) { activate(0); }
})();
