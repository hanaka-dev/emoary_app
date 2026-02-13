/*! Wavify - https://github.com/peacepostman/wavify */
function wavify(wave_element, options) {
  if (typeof options === "undefined") options = {};
  var settings = Object.assign({}, {
    container: options.container ? options.container : "body",
    height: 200,
    amplitude: 100,
    speed: 0.15,
    bones: 3,
    color: "rgba(255,255,255, 0.20)"
  }, options);

  var wave = wave_element;
  var containerEl = typeof settings.container === "string"
    ? document.querySelector(settings.container)
    : settings.container;
  var width = containerEl ? containerEl.getBoundingClientRect().width : 180;
  var height = containerEl ? containerEl.getBoundingClientRect().height : 20;
  var points = [];
  var lastUpdate;
  var totalTime = 0;
  var animationInstance = false;
  var tweenMaxInstance = false;

  function rebuilSettings(params) {
    settings = Object.assign({}, settings, params);
  }

  function drawPoints(factor) {
    var pts = [];
    for (var i = 0; i <= settings.bones; i++) {
      var x = (i / settings.bones) * width;
      var sinSeed = (factor + (i + (i % settings.bones))) * settings.speed * 100;
      var sinHeight = Math.sin(sinSeed / 100) * settings.amplitude;
      var yPos = Math.sin(sinSeed / 100) * sinHeight + settings.height;
      pts.push({ x: x, y: yPos });
    }
    return pts;
  }

  function drawPath(points) {
    var SVGString = "M " + points[0].x + " " + points[0].y;
    var cp0 = {
      x: (points[1].x - points[0].x) / 2,
      y: points[1].y - points[0].y + points[0].y + (points[1].y - points[0].y)
    };
    SVGString += " C " + cp0.x + " " + cp0.y + " " + cp0.x + " " + cp0.y + " " + points[1].x + " " + points[1].y;
    var prevCp = cp0;
    for (var i = 1; i < points.length - 1; i++) {
      var cp1 = {
        x: points[i].x - prevCp.x + points[i].x,
        y: points[i].y - prevCp.y + points[i].y
      };
      SVGString += " C " + cp1.x + " " + cp1.y + " " + cp1.x + " " + cp1.y + " " + points[i + 1].x + " " + points[i + 1].y;
      prevCp = cp1;
    }
    SVGString += " L " + width + " " + height;
    SVGString += " L 0 " + height + " Z";
    return SVGString;
  }

  function draw() {
    var now = window.Date.now();
    if (lastUpdate) {
      var elapsed = (now - lastUpdate) / 1000;
      lastUpdate = now;
      totalTime += elapsed;
      var factor = totalTime * Math.PI;
      if (typeof TweenMax !== "undefined") {
        tweenMaxInstance = TweenMax.to(wave, settings.speed, {
          attr: { d: drawPath(drawPoints(factor)) },
          ease: Power1.easeInOut
        });
      } else {
        wave.setAttribute("d", drawPath(drawPoints(factor)));
      }
    } else {
      lastUpdate = now;
    }
    animationInstance = requestAnimationFrame(draw);
  }

  function debounce(func, wait) {
    var timeout;
    return function () {
      var ctx = this, args = arguments;
      clearTimeout(timeout);
      timeout = setTimeout(function () {
        timeout = null;
        func.apply(ctx, args);
      }, wait);
    };
  }

  var redraw = debounce(function () {
    pause();
    points = [];
    totalTime = 0;
    if (containerEl) {
      width = containerEl.getBoundingClientRect().width;
      height = containerEl.getBoundingClientRect().height;
    }
    lastUpdate = false;
    play();
  }, 250);

  function boot() {
    if (!animationInstance) {
      if (typeof TweenMax !== "undefined") {
        TweenMax.set(wave, { attr: { fill: settings.color } });
      } else {
        wave.setAttribute("fill", settings.color);
      }
      play();
      if (containerEl) window.addEventListener("resize", redraw);
    }
  }

  function reboot(opts) {
    kill();
    if (typeof opts !== "undefined") rebuilSettings(opts);
    if (typeof TweenMax !== "undefined") {
      TweenMax.set(wave, { attr: { fill: settings.color } });
    } else {
      wave.setAttribute("fill", settings.color);
    }
    play();
    if (containerEl) window.addEventListener("resize", redraw);
  }

  function play() {
    if (!animationInstance) animationInstance = requestAnimationFrame(draw);
  }

  function pause() {
    if (animationInstance) {
      cancelAnimationFrame(animationInstance);
      animationInstance = false;
    }
  }

  function updateColor(opts) {
    var timing = (opts && opts.timing !== undefined) ? opts.timing : 1;
    var color = (opts && opts.color !== undefined) ? opts.color : settings.color;
    if (typeof TweenMax !== "undefined") {
      TweenMax.to(wave, timing, {
        attr: { fill: color },
        onComplete: opts && opts.onComplete
      });
    } else {
      wave.setAttribute("fill", color);
    }
  }

  function kill() {
    pause();
    if (typeof TweenMax !== "undefined" && tweenMaxInstance) tweenMaxInstance.kill();
    if (typeof TweenMax !== "undefined") {
      TweenMax.set(wave, { attr: { d: "M0,0", fill: "" }, clearProps: "all" });
    } else {
      wave.setAttribute("d", "M0,0");
      wave.removeAttribute("fill");
    }
    if (containerEl) window.removeEventListener("resize", redraw);
    animationInstance = false;
  }

  boot();
  return { reboot: reboot, play: play, pause: pause, kill: kill, updateColor: updateColor };
}
