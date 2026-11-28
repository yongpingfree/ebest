{{-- 点击带 class="zoom" 的图片链接,在页面内放大查看(含尺寸、文件名、查看原图),支持 ← → 切换、Esc 关闭 --}}
<style>
#lbox{display:none;position:fixed;inset:0;background:rgba(0,0,0,.82);z-index:60;align-items:center;justify-content:center;flex-direction:column;padding:16px}
#lbox.on{display:flex}
#lbox img{max-width:94vw;max-height:78vh;background:#fff;border-radius:4px;object-fit:contain}
#lbox .cap{color:#fff;margin-top:10px;font-size:14px;text-align:center;max-width:94vw;word-break:break-all}
#lbox .cap a{color:#9cf;margin-left:10px}
#lbox button{position:absolute;background:rgba(255,255,255,.18);color:#fff;border:0;border-radius:4px;font-size:22px;cursor:pointer;padding:6px 12px}
#lbox .x{top:14px;right:18px}#lbox .pv{left:14px;top:50%}#lbox .nx{right:14px;top:50%}
a.zoom{cursor:zoom-in}
</style>
<div id="lbox" role="dialog" aria-modal="true">
  <button type="button" class="x" id="lbX" title="{{ __('关闭') }}">×</button>
  <button type="button" class="pv" id="lbP">‹</button>
  <img id="lbImg" alt="">
  <div class="cap"><span id="lbCap"></span><a id="lbOpen" href="#" target="_blank" rel="noopener">{{ __('查看原图') }}</a></div>
  <button type="button" class="nx" id="lbN">›</button>
</div>
<script>
(function () {
  var box = document.getElementById('lbox'), img = document.getElementById('lbImg'), cap = document.getElementById('lbCap'), open = document.getElementById('lbOpen');
  var list = [], idx = 0;
  function show(i) {
    if (!list.length) return;
    idx = (i + list.length) % list.length;
    var a = list[idx];
    img.src = a.href; cap.textContent = a.getAttribute('data-caption') || ''; open.href = a.href;
    document.getElementById('lbP').style.display = document.getElementById('lbN').style.display = list.length > 1 ? '' : 'none';
    box.classList.add('on');
  }
  function close() { box.classList.remove('on'); img.src = ''; }
  document.addEventListener('click', function (e) {
    var a = e.target.closest ? e.target.closest('a.zoom') : null;
    if (!a) return;
    e.preventDefault();
    list = Array.prototype.slice.call(document.querySelectorAll('a.zoom'));
    show(list.indexOf(a));
  });
  box.addEventListener('click', function (e) { if (e.target === box) close(); });
  document.getElementById('lbX').onclick = close;
  document.getElementById('lbP').onclick = function () { show(idx - 1); };
  document.getElementById('lbN').onclick = function () { show(idx + 1); };
  document.addEventListener('keydown', function (e) {
    if (!box.classList.contains('on')) return;
    if (e.key === 'Escape') close(); else if (e.key === 'ArrowLeft') show(idx - 1); else if (e.key === 'ArrowRight') show(idx + 1);
  });
})();
</script>
