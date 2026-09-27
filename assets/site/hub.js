/* ==========================================================================
   hub.js — 站点入口页（根 index.html）的 tab 与按需加载逻辑
   --------------------------------------------------------------------------
   这个文件不直接被浏览器加载：code/update_site.R 读取它，内联进
   assets/site/index.template.html 的脚本占位符，产出根 index.html。
   （此处刻意不写出占位符的字面写法——脚本会校验替换后不残留占位符。）

   加载策略（方案 B：多文件 + 按需加载）：
     - 首屏只建左侧 tab 列表，不创建任何 iframe，因此不产生任何报告请求。
     - 点某个 tab 时，若该周面板还没建，才创建 <iframe> 并设 src，只下载那一周。
     - 已创建的面板留在 DOM 中，切回只切 data-active，零请求。
   ========================================================================== */
(function () {
  "use strict";

  var data = JSON.parse(document.getElementById("hub-data").textContent);
  var weeks = data.weeks;

  var listEl = document.getElementById("weeks-list");
  var stageEl = document.getElementById("stage");
  var emptyEl = document.getElementById("stage-empty");
  var titleEl = document.getElementById("viz-title");
  var dateEl = document.getElementById("viz-date");
  var footEl = document.getElementById("hub-foot");

  var OCTO = '<svg class="octo" width="15" height="15" viewBox="0 0 16 16" aria-hidden="true">' +
             '<use href="#i-octo"></use></svg>';

  /* 面板表：i -> { panel, frame }
     只读缓存，用来判断「已建则切显隐、未建才创建」。 */
  var panels = {};

  function el(tag, cls) {
    var n = document.createElement(tag);
    if (cls) { n.className = cls; }
    return n;
  }

  /* 建左侧一个条目：可点的 tab + 独立的 GitHub 八爪鱼链接 */
  function buildWeek(week, index) {
    var li = el("li", "week");

    var tab = el("button", "tab");
    tab.type = "button";
    tab.setAttribute("aria-selected", "false");
    tab.setAttribute("aria-controls", "panel-" + index);

    var t = el("span", "t");
    t.textContent = week.title + (week.kind ? " · " + week.kind : "");
    var d = el("span", "d");
    d.textContent = week.date;
    tab.appendChild(t);
    tab.appendChild(d);
    tab.addEventListener("click", function () { activate(index); });
    li.appendChild(tab);

    /* 每周 tab 旁边的 GitHub 八爪鱼：指向该周目录，不参与 tab 切换 */
    var src = el("a", "src");
    src.href = week.repo;
    src.target = "_blank";
    src.rel = "noopener";
    src.title = week.date + " 的源码与产物（GitHub）";
    src.setAttribute("aria-label", week.date + " 在 GitHub 上的目录");
    src.innerHTML = OCTO;
    li.appendChild(src);

    listEl.appendChild(li);
    return tab;
  }

  function activate(index) {
    var week = weeks[index];

    /* 顶部标题与日期 */
    titleEl.textContent = week.title + (week.kind ? " · " + week.kind : "");
    dateEl.textContent = week.date;

    /* 首屏空态让位给面板 */
    if (emptyEl) { emptyEl.hidden = true; }

    /* 左侧高亮 */
    var tabs = listEl.querySelectorAll(".tab");
    for (var i = 0; i < tabs.length; i++) {
      tabs[i].setAttribute("aria-selected", i === index ? "true" : "false");
    }

    /* 首次点击才创建 iframe —— 此前该周不产生任何网络请求 */
    var entry = panels[index];
    if (!entry) {
      var panel = el("div", "panel");
      panel.id = "panel-" + index;

      var hint = el("div", "hint");
      hint.textContent = "正在加载 " + week.date + "（" + week.title + "）…";
      panel.appendChild(hint);

      var frame = document.createElement("iframe");
      frame.title = week.title;
      frame.loading = "eager";
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

  footEl.textContent = "共 " + weeks.length + " 周 · 报告按需加载 · " +
                       "自动生成于 " + data.generated + " · 由 code/update_site.R 维护";

  /* 刻意不在此处调用 activate()：
     首屏只渲染周列表，不创建 iframe，因此不产生任何报告请求。
     用户点击某个周次时才加载那一周。 */
})();
