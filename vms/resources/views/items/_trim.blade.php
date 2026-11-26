<style>
#trimModal{display:none;position:fixed;inset:0;background:#fff;z-index:1000;flex-direction:column}
#trimModal.on{display:flex}
#trimModal .th{padding:12px 16px;font-size:18px;display:flex;justify-content:space-between;align-items:center}
#trimModal .th .x{cursor:pointer;font-size:24px;color:#888;border:0;background:none}
#trimModal .tb{flex:1;margin:0 12px;overflow:hidden;position:relative;background:repeating-conic-gradient(#999 0 25%,#bbb 0 50%) 0 0/20px 20px}
#trimModal canvas{position:absolute;left:0;top:0;touch-action:none}
#trimModal .tf{padding:10px 16px;display:flex;gap:8px;align-items:center;justify-content:flex-end}
#trimModal .tf .tip{margin-right:auto;color:#555;font-size:13px}
</style>
<div id="trimModal">
  <div class="th"><span>图片裁剪 <span id="trimName" class="muted" style="font-size:13px"></span></span><button type="button" class="x" id="trimClose">×</button></div>
  <div class="tb" id="trimBox"><canvas id="trimCv"></canvas></div>
  <div class="tf"><span class="tip" id="trimTip"></span>
    <button type="button" class="btn sec" id="trimReset">重置</button>
    <button type="button" class="btn ok" id="trimOk">确定</button></div>
</div>
<script>
(function () {
  var SPECS = @json(config('vms.image_kinds'));
  var modal = document.getElementById('trimModal'), box = document.getElementById('trimBox'),
      cv = document.getElementById('trimCv'), ctx = cv.getContext('2d'),
      tip = document.getElementById('trimTip'), nameEl = document.getElementById('trimName');
  var queue, done, cur, input, spec, img, scale, crop, drag;

  function needTrim(w, h, s) {
    if (s.width && w !== s.width) return true;
    if (s.height && h !== s.height) return true;
    if (s.max_height && h > s.max_height) return true;
    return false;
  }
  function loadImg(file) {
    return new Promise(function (res) {
      var u = URL.createObjectURL(file), i = new Image();
      i.onload = function () { res(i); }; i.onerror = function () { res(null); }; i.src = u;
    });
  }
  // 裁剪框宽高比:宽高都固定 -> 固定比例;只固定宽 -> 自由,但限制最大高度
  function ratio() { return (spec.width && spec.height) ? spec.width / spec.height : 0; }
  function minRatio() { return (spec.width && spec.max_height) ? spec.width / spec.max_height : 0; }

  function reset() {
    var r = ratio(), w = img.width, h = img.height;
    if (r) { if (w / h > r) w = h * r; else h = w / r; }
    else if (minRatio() && w / h < minRatio()) h = w / minRatio();
    crop = { x: (img.width - w) / 2, y: (img.height - h) / 2, w: w, h: h };
    draw();
  }
  function fit() {
    var bw = box.clientWidth, bh = box.clientHeight;
    scale = Math.min(bw / img.width, bh / img.height, 1);
    cv.width = Math.round(img.width * scale); cv.height = Math.round(img.height * scale);
    cv.style.left = ((bw - cv.width) / 2) + 'px'; cv.style.top = ((bh - cv.height) / 2) + 'px';
  }
  function draw() {
    ctx.clearRect(0, 0, cv.width, cv.height);
    ctx.drawImage(img, 0, 0, cv.width, cv.height);
    var x = crop.x * scale, y = crop.y * scale, w = crop.w * scale, h = crop.h * scale;
    ctx.fillStyle = 'rgba(0,0,0,.5)';
    ctx.fillRect(0, 0, cv.width, y); ctx.fillRect(0, y + h, cv.width, cv.height - y - h);
    ctx.fillRect(0, y, x, h); ctx.fillRect(x + w, y, cv.width - x - w, h);
    ctx.strokeStyle = '#1e88e5'; ctx.lineWidth = 2; ctx.strokeRect(x, y, w, h);
    ctx.fillStyle = '#1e88e5';
    [[x, y], [x + w, y], [x, y + h], [x + w, y + h]].forEach(function (p) { ctx.fillRect(p[0] - 5, p[1] - 5, 10, 10); });
    var ow = spec.width || Math.round(crop.w), oh = spec.height || Math.round(crop.h * ow / crop.w);
    tip.textContent = '输出尺寸 ' + ow + '×' + oh + ' 像素。拖动方框移动,拖动角点缩放。';
  }
  function pos(e) { var r = cv.getBoundingClientRect(); return { x: (e.clientX - r.left) / scale, y: (e.clientY - r.top) / scale }; }
  function hit(p) {
    var t = 12 / scale, cs = [['l', 't'], ['r', 't'], ['l', 'b'], ['r', 'b']];
    for (var i = 0; i < 4; i++) {
      var cx = cs[i][0] === 'l' ? crop.x : crop.x + crop.w, cy = cs[i][1] === 't' ? crop.y : crop.y + crop.h;
      if (Math.abs(p.x - cx) < t && Math.abs(p.y - cy) < t) return cs[i];
    }
    if (p.x > crop.x && p.x < crop.x + crop.w && p.y > crop.y && p.y < crop.y + crop.h) return 'move';
    return null;
  }
  cv.addEventListener('pointerdown', function (e) {
    var p = pos(e), h = hit(p); if (!h) return;
    drag = { h: h, p: p, c: Object.assign({}, crop) }; cv.setPointerCapture(e.pointerId);
  });
  cv.addEventListener('pointermove', function (e) {
    var p = pos(e);
    if (!drag) { var h = hit(p); cv.style.cursor = h === 'move' ? 'move' : (h ? 'nwse-resize' : 'default'); return; }
    var dx = p.x - drag.p.x, dy = p.y - drag.p.y, c = drag.c;
    if (drag.h === 'move') {
      crop.x = Math.max(0, Math.min(img.width - c.w, c.x + dx));
      crop.y = Math.max(0, Math.min(img.height - c.h, c.y + dy));
    } else {
      var left = drag.h[0] === 'l', top = drag.h[1] === 't';
      var ax = left ? c.x + c.w : c.x, ay = top ? c.y + c.h : c.y; // 固定的对角点
      var nx = Math.max(0, Math.min(img.width, (left ? c.x : c.x + c.w) + dx));
      var ny = Math.max(0, Math.min(img.height, (top ? c.y : c.y + c.h) + dy));
      var w = Math.max(20, Math.abs(nx - ax)), h2 = Math.max(20, Math.abs(ny - ay)), r = ratio();
      var maxW = left ? ax : img.width - ax, maxH = top ? ay : img.height - ay;
      if (r) {
        h2 = w / r;
        if (h2 > maxH) { h2 = maxH; w = h2 * r; }
        if (w > maxW) { w = maxW; h2 = w / r; }
      } else {
        w = Math.min(w, maxW); h2 = Math.min(h2, maxH);
        if (minRatio() && w / h2 < minRatio()) h2 = w / minRatio();
      }
      crop = { x: left ? ax - w : ax, y: top ? ay - h2 : ay, w: w, h: h2 };
    }
    draw();
  });
  cv.addEventListener('pointerup', function () { drag = null; });

  function output() {
    var ow = spec.width || Math.round(crop.w), oh = spec.height || Math.round(crop.h * ow / crop.w);
    var c = document.createElement('canvas'); c.width = ow; c.height = oh;
    var g = c.getContext('2d'); g.imageSmoothingQuality = 'high';
    g.drawImage(img, crop.x, crop.y, crop.w, crop.h, 0, 0, ow, oh);
    var type = /png|webp/.test(cur.type) ? cur.type : 'image/jpeg';
    return new Promise(function (res) { c.toBlob(res, type, 0.92); }).then(function (b) {
      var ext = type === 'image/png' ? 'png' : (type === 'image/webp' ? 'webp' : 'jpg');
      var nm = cur.name.replace(/\.[^.]+$/, '') + '.' + ext;
      return new File([b], nm, { type: type });
    });
  }
  function next() {
    if (!queue.length) { finish(); return; }
    cur = queue.shift();
    loadImg(cur).then(function (i) {
      if (!i) { done.push(cur); next(); return; } // 非图片交给服务器报错
      if (!needTrim(i.width, i.height, spec)) { done.push(cur); next(); return; }
      img = i; nameEl.textContent = cur.name + '(原图 ' + i.width + '×' + i.height + ')';
      modal.classList.add('on'); fit(); reset();
    });
  }
  function finish() {
    modal.classList.remove('on');
    var dt = new DataTransfer(); done.forEach(function (f) { dt.items.add(f); });
    input.files = dt.files;
    if (!done.length) input.value = '';
  }
  document.getElementById('trimReset').onclick = reset;
  document.getElementById('trimClose').onclick = function () { next(); }; // 放弃当前这张
  document.getElementById('trimOk').onclick = function () {
    output().then(function (f) { done.push(f); next(); });
  };
  window.addEventListener('resize', function () { if (modal.classList.contains('on')) { fit(); draw(); } });

  document.querySelectorAll('input[data-trim-kind]').forEach(function (el) {
    el.addEventListener('change', function () {
      if (el.dataset.trimBusy || !el.files.length) return;
      input = el; spec = SPECS[el.dataset.trimKind]; if (!spec) return;
      queue = Array.prototype.slice.call(el.files); done = [];
      next();
    });
  });
})();
</script>
