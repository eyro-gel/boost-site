(function () {
  'use strict';
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---- mobile menu ---- */
  var burger = document.querySelector('.burger');
  var mnav = document.getElementById('mnav');
  if (burger && mnav) {
    burger.addEventListener('click', function () {
      var open = burger.getAttribute('aria-expanded') === 'true';
      burger.setAttribute('aria-expanded', String(!open));
      burger.setAttribute('aria-label', open ? 'Open menu' : 'Close menu');
      mnav.classList.toggle('open', !open);
    });
    mnav.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', function () {
        mnav.classList.remove('open');
        burger.setAttribute('aria-expanded', 'false');
        burger.setAttribute('aria-label', 'Open menu');
      });
    });
  }

  /* ---- header shadow on scroll ---- */
  var hdr = document.getElementById('hdr');
  if (hdr) {
    var onScroll = function () { hdr.classList.toggle('stuck', window.scrollY > 8); };
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
  }

  /* ---- reveal + animated score bars ---- */
  // the bar's real width lives in CSS (so it shows without JS); JS only
  // pins it to 0 first so it can animate up when the card comes into view
  document.querySelectorAll('.bar i').forEach(function (b) { b.style.width = '0%'; });
  var fill = function (el) {
    el.querySelectorAll('.bar i').forEach(function (b, i) {
      if (reduce) { b.style.width = ''; return; }
      setTimeout(function () { b.style.width = ''; }, 260 + i * 130);
    });
  };
  var targets = document.querySelectorAll('.rv');
  if (!('IntersectionObserver' in window) || reduce) {
    targets.forEach(function (t) { t.classList.add('in'); });
    document.querySelectorAll('.score').forEach(fill);
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (!e.isIntersecting) return;
        e.target.classList.add('in');
        if (e.target.classList.contains('score')) fill(e.target);
        io.unobserve(e.target);
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0 });
    // threshold 0, not a fraction: a wrapper taller than the viewport can never
    // reach a 12% ratio, so tall sections would never reveal on short windows
    targets.forEach(function (t) { io.observe(t); });
  }

  /* ---- plans / packages family switcher (subpages) ---- */
  var segs = document.querySelectorAll('.seg [data-fam]');
  if (segs.length) {
    var applyFam = function (fam) {
      segs.forEach(function (b) { b.setAttribute('aria-pressed', String(b.dataset.fam === fam)); });
      document.querySelectorAll('.fam-view').forEach(function (g) { g.hidden = g.dataset.fam !== fam; });
      // opaque origins (data:, some sandboxes) reject replaceState — the
      // switch itself must still work, so this is best-effort only
      try {
        var url = new URL(window.location.href);
        url.searchParams.set('focus', fam);
        history.replaceState(null, '', url);
      } catch (e) {}
    };
    segs.forEach(function (b) {
      b.addEventListener('click', function () { applyFam(b.dataset.fam); });
    });
    var initial = null;
    try { initial = new URL(window.location.href).searchParams.get('focus'); } catch (e) {}
    if (initial && document.querySelector('.fam-view[data-fam="' + initial + '"]')) applyFam(initial);
  }

  /* ---- price attributes: empty means "ask", filled means show the figure ---- */
  document.querySelectorAll('.plan-price').forEach(function (el) {
    var v = (el.dataset.price || '').trim();
    if (!v) return;                       // markup already says "Price on request"
    el.innerHTML = '<b>' + v + '</b><span>' + (el.dataset.unit || '') + '</span>';
    var t = el.nextElementSibling;
    if (t && t.classList.contains('plan-terms')) t.textContent = el.dataset.terms || t.textContent;
  });

  /* ---- FAQ: one answer open at a time, with an animated open/close ----
     <details> cannot transition its own height, so the answer is animated
     manually and `open` is only cleared once the collapse has finished.
     One lock for the whole group: a per-item guard still let a second click
     land on a different question mid-animation and leave two open. ---- */
  (function () {
    var faq = [].slice.call(document.querySelectorAll('#faq details'));
    if (!faq.length) return;
    var DUR = reduce ? 0 : 300;
    var EASE = 'cubic-bezier(.22,.61,.36,1)';
    var busy = false;

    var clear = function (el) {
      el.style.transition = ''; el.style.height = ''; el.style.overflow = ''; el.style.opacity = '';
    };

    var expand = function (d, done) {
      var body = d.querySelector('.faq-a');
      d.open = true;
      if (!DUR) { if (done) done(); return; }
      body.style.overflow = 'hidden';
      body.style.height = '0px';
      body.style.opacity = '0';
      var h = body.scrollHeight;
      requestAnimationFrame(function () {
        body.style.transition = 'height ' + DUR + 'ms ' + EASE + ', opacity ' + DUR + 'ms ' + EASE;
        body.style.height = h + 'px';
        body.style.opacity = '1';
      });
      setTimeout(function () { clear(body); if (done) done(); }, DUR + 30);
    };

    var collapse = function (d, done) {
      var body = d.querySelector('.faq-a');
      if (!DUR) { d.open = false; if (done) done(); return; }
      d.classList.add('faq-closing');       // keeps the chevron in step
      body.style.overflow = 'hidden';
      body.style.height = body.scrollHeight + 'px';
      body.style.opacity = '1';
      requestAnimationFrame(function () {
        body.style.transition = 'height ' + DUR + 'ms ' + EASE + ', opacity ' + DUR + 'ms ' + EASE;
        body.style.height = '0px';
        body.style.opacity = '0';
      });
      setTimeout(function () {
        d.open = false;
        d.classList.remove('faq-closing');
        clear(body);
        if (done) done();
      }, DUR + 30);
    };

    faq.forEach(function (d) {
      var sum = d.querySelector('summary');
      if (!sum || !d.querySelector('.faq-a')) return;
      sum.addEventListener('click', function (e) {
        e.preventDefault();
        if (busy) return;
        busy = true;
        var release = function () { busy = false; };
        if (d.open) { collapse(d, release); return; }
        // the outgoing answer closes while the new one opens, so the whole
        // swap takes one duration rather than two
        faq.forEach(function (o) { if (o !== d && o.open) collapse(o); });
        expand(d, release);
      });
    });
  })();

  /* ---- before / after ---- */
  var tabs = document.querySelectorAll('.demo-switch button');
  var show = function (view) {
    document.querySelectorAll('[data-view]').forEach(function (n) { n.hidden = n.dataset.view !== view; });
    document.querySelectorAll('[data-note]').forEach(function (n) { n.hidden = n.dataset.note !== view; });
    tabs.forEach(function (t) { t.setAttribute('aria-selected', String(t.id === 'tab-' + view)); });
    var panel = document.getElementById('panel-demo');
    if (panel) panel.setAttribute('aria-labelledby', 'tab-' + view);
  };
  tabs.forEach(function (t) {
    t.addEventListener('click', function () { show(t.id.replace('tab-', '')); });
  });
})();
