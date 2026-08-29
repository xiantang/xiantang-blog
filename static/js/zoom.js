// 正文图片点击放大：极简 lightbox，无依赖
(function () {
  var imgs = document.querySelectorAll('.post-content p > img:only-child');
  if (!imgs.length) return;

  var overlay = document.createElement('div');
  overlay.className = 'img-lightbox';
  overlay.innerHTML = '<img alt="">';
  document.body.appendChild(overlay);
  var big = overlay.firstChild;

  function close() { overlay.classList.remove('active'); }

  imgs.forEach(function (img) {
    img.addEventListener('click', function () {
      big.src = img.currentSrc || img.src;
      overlay.classList.add('active');
    });
  });

  overlay.addEventListener('click', close);
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') close();
  });
})();
