let diaryFormListenersAbort = null;

function initDiaryForm() {
  const root = document.getElementById("diary-form-root");
  if (!root) return;

  if (diaryFormListenersAbort) {
    diaryFormListenersAbort.abort();
  }
  diaryFormListenersAbort = new AbortController();
  const signal = diaryFormListenersAbort.signal;

  const readonly = root.dataset.formReadonly === "true";
  const maxEmotions = parseInt(root.dataset.maxEmotions || "3", 10);
  const chips = Array.from(root.querySelectorAll(".emotion-chip"));
  const rows = Array.from(root.querySelectorAll(".emotion-row"));

  const emoHidden = [
    document.getElementById("diary_emo_1"),
    document.getElementById("diary_emo_2"),
    document.getElementById("diary_emo_3"),
  ];
  const rateHidden = [
    document.getElementById("diary_rate_1"),
    document.getElementById("diary_rate_2"),
    document.getElementById("diary_rate_3"),
  ];

  let selected = []; // [{id, name, color, rate}]
  let prevFitSelectedLength = -1;

  /** 感情色を暗くした色（黒をかけた）を rgb で返す */
  function darkenHex(hex, factor) {
    if (!hex || hex.indexOf("#") !== 0) return "rgb(84, 62, 44)";
    const n = parseInt(hex.slice(1), 16);
    const r = Math.round(((n >> 16) & 0xff) * factor);
    const g = Math.round(((n >> 8) & 0xff) * factor);
    const b = Math.round((n & 0xff) * factor);
    return "rgb(" + r + "," + g + "," + b + ")";
  }

  /** つまみ中心にツールチップを合わせる left%（0/100でもつまみがトラック内の 24px〜幅-24px に収まる前提） */
  function getBubbleLeftPercent(slider, value) {
    if (!slider) return value;
    const trackWidth = slider.offsetWidth;
    if (trackWidth <= 0) return value;
    const insetPx = 24;
    const thumbRadiusPx = 12;
    const travelWidth = trackWidth - 2 * insetPx;
    const thumbCenterPx = insetPx + (travelWidth * value / 100);
    const containerWidth = trackWidth - 2 * 12;
    return ((thumbCenterPx - 12) / containerWidth) * 100;
  }

  function syncHiddenFields() {
    for (let i = 0; i < 3; i++) {
      const item = selected[i];
      if (item) {
        emoHidden[i].value = item.id;
        rateHidden[i].value = item.rate;
      } else {
        emoHidden[i].value = "";
        rateHidden[i].value = "";
      }
    }
  }

  /** 感情スライダー制約: 合計100を超えないよう各スライダーの上限を適用し、はみ出た分はクランプして10刻みに丸める */
  function enforceSliderCaps() {
    let sumPrev = 0;
    for (let i = 0; i < selected.length; i++) {
      const maxI = 100 - sumPrev;
      let r = Math.min(selected[i].rate, maxI);
      r = Math.round(r / 10) * 10;
      r = Math.max(0, Math.min(maxI, r));
      selected[i].rate = r;
      sumPrev += r;
    }
  }

  /** 10刻みに丸め（0〜100）、合計が100になるよう先頭で調整 */
  function roundRatesToStep10() {
    if (selected.length === 0) return;
    selected = selected.map((item) => ({
      ...item,
      rate: Math.min(100, Math.max(0, Math.round(item.rate / 10) * 10)),
    }));
    const sum = selected.reduce((s, e) => s + e.rate, 0);
    const diff = 100 - sum;
    if (diff !== 0 && selected.length > 0) {
      selected[0].rate = Math.min(100, Math.max(0, selected[0].rate + diff));
    }
  }

  function updateRows() {
    enforceSliderCaps();
    rows.forEach((row, index) => {
      const displayIndex = index;
      const item = selected[displayIndex];
      const labelEl = row.querySelector("[data-role='selected-chip'] .selected-chip-label");
      const removeBtn = row.querySelector(".selected-chip-remove");
      const slider = row.querySelector("[data-role='slider']");
      const valueBubble = row.querySelector("[data-role='slider-value-bubble']");
      const valueText = row.querySelector("[data-role='slider-value-text']");
      const valueChip = row.querySelector("[data-role='slider-value-chip']");
      const selectedChip = row.querySelector("[data-role='selected-chip']");

      var wrap = row.querySelector("[data-role='slider-wrap']");
      if (!item) {
        row.style.display = "none";
        if (labelEl) labelEl.textContent = "";
        if (valueText) valueText.textContent = "";
        if (valueChip) valueChip.textContent = "";
        if (slider) slider.value = "0";
        if (valueBubble) valueBubble.style.left = "";
        if (selectedChip) {
          selectedChip.style.background = "";
          selectedChip.style.color = "";
        }
        if (wrap) {
          wrap.style.removeProperty("--tick-color");
          wrap.style.removeProperty("--thumb-pct");
        }
        row.removeAttribute("data-emotion-id");
        row.removeAttribute("data-emotion-color");
        row.style.removeProperty("--track-color");
        row.style.removeProperty("--bubble-color");
        return;
      }

      row.style.display = "flex";
      row.dataset.emotionId = String(item.id);
      row.dataset.emotionColor = item.color;
      row.style.setProperty("--track-color", item.color);
      row.style.setProperty("--bubble-color", `linear-gradient(rgba(0,0,0,0.25), rgba(0,0,0,0.25)), ${item.color}`);
      if (wrap) {
        wrap.style.setProperty("--tick-color", darkenHex(item.color, 0.75));
        wrap.style.setProperty("--thumb-pct", String(item.rate));
      }

      if (labelEl) {
        labelEl.textContent = item.name;
      }
      if (selectedChip) {
        // Bチップは感情色の上に半透明の黒を重ねて少し暗くし、文字を見やすく
        selectedChip.style.background = `linear-gradient(rgba(0,0,0,0.25), rgba(0,0,0,0.25)), ${item.color}`;
        selectedChip.style.color = "#ffffff";
      }
      if (slider) {
        slider.value = item.rate;
      }
      if (valueText) {
        valueText.textContent = String(item.rate);
      }
      if (valueBubble && slider) {
        valueBubble.style.left = getBubbleLeftPercent(slider, item.rate) + "%";
      }
      if (valueChip) {
        valueChip.textContent = String(item.rate);
      }

      if (removeBtn && !readonly) {
        removeBtn.onclick = () => {
          deselectEmotion(item.id);
        };
      }
      if (readonly && slider) {
        slider.disabled = true;
        slider.classList.add("cursor-default", "opacity-90");
      }
    });

    syncHiddenFields();
    updateLeafLiquid();
    if (typeof window.fitDiaryToViewport === "function" && selected.length !== prevFitSelectedLength) {
      prevFitSelectedLength = selected.length;
      setTimeout(window.fitDiaryToViewport, 0);
    }
  }

  function selectEmotion(id, name, color) {
    if (selected.find((e) => e.id === id)) return;
    if (selected.length >= maxEmotions) return;

    // 新規追加分は常に0。既存のスライダー値は変更しない
    selected.push({ id, name, color, rate: 0 });
    updateChips();
    updateRows();
  }

  function deselectEmotion(id) {
    selected = selected.filter((e) => e.id !== id);
    // 削除時は残りのスライダーは触らない（10,20,70→3削除で10,20のまま）
    updateChips();
    updateRows();
  }

  function normalizeRates() {
    if (selected.length === 0) return;
    if (selected.length === 1) return;
    const base = Math.floor(100 / selected.length);
    let remainder = 100 - base * selected.length;
    selected = selected.map((item, index) => {
      const extra = remainder > 0 ? 1 : 0;
      if (remainder > 0) remainder -= 1;
      return { ...item, rate: base + extra };
    });
    roundRatesToStep10();
  }

  function updateChips() {
    const atMax = selected.length >= maxEmotions;
    chips.forEach((chip) => {
      const id = parseInt(chip.dataset.emotionId, 10);
      const icon = chip.querySelector(".chip-icon");
      const isSelected = selected.find((e) => e.id === id);

      if (isSelected) {
        chip.classList.add("selected");
        chip.classList.remove("emotion-chip-disabled");
        chip.style.display = "";
        if (icon) icon.textContent = "";
      } else {
        chip.classList.remove("selected");
        if (atMax) {
          chip.classList.add("emotion-chip-disabled");
        } else {
          chip.classList.remove("emotion-chip-disabled");
        }
        chip.style.display = "";
        if (icon) icon.textContent = "+";
      }
    });
  }

  let leafLiquidRafId = null;
  let prevSelectedLength = 0;
  let wavifyInstance = null;
  let lastWaveEmotionId = null;

  /** Wavifyの色に使う感情: 現在残っている（選択中の）感情のうち、一番新しい（配列の最後）で、かつ値が1以上のもの。全て0ならnull */
  function getLastSelectedEmotion() {
    for (let i = selected.length - 1; i >= 0; i--) {
      if (selected[i].rate > 0) return selected[i];
    }
    return null;
  }

  // 葉のクリップpathのY範囲（pathの座標）。液体rectはこの範囲内でないと見えない
  var LEAF_Y_TOP = 21;
  var LEAF_Y_BOTTOM = 154;
  var LEAF_LIQUID_HEIGHT = LEAF_Y_BOTTOM - LEAF_Y_TOP; // 133

  // Wavifyの波の上端を液体の最上面に一致させる（wavifyの path は height:10 で波頂が y≈10 に描かれる）。値を大きくすると波が少し上に寄る
  // ※Wavifyは「液体の一番上」1枚のみ。各色の境界には適用しない（画像仕様通り）
  var WAVIFY_WAVE_TOP = 14;

  function setSurfaceWave(y, color) {
    var g = document.getElementById("surfaceWaveGroup");
    var path = document.getElementById("surfaceWavePath");
    if (!g || !path) return;
    g.setAttribute("transform", "translate(0, " + (y - WAVIFY_WAVE_TOP) + ")");
    var lastEmo = getLastSelectedEmotion();
    if (y >= LEAF_Y_BOTTOM || lastEmo === null) {
      g.style.visibility = "hidden";
      g.style.display = "none";
      path.setAttribute("d", "");
      path.setAttribute("fill", "none");
      if (wavifyInstance) {
        wavifyInstance.kill();
        wavifyInstance = null;
      }
      lastWaveEmotionId = null;
      return;
    }
    g.style.display = "";
    g.style.visibility = "visible";
    var emotionIdForWave = lastEmo.id;
    var fillColor = lastEmo.color;
    var fillColorWithAlpha = fillColor.startsWith("rgb")
      ? fillColor.replace(")", ", 0.85)").replace("rgb", "rgba")
      : hexToRgba(fillColor, 0.85);

    if (typeof wavify !== "undefined") {
      if (lastWaveEmotionId !== emotionIdForWave && wavifyInstance) {
        wavifyInstance.kill();
        wavifyInstance = null;
        lastWaveEmotionId = null;
      }
      if (!wavifyInstance) {
        wavifyInstance = wavify(path, {
          container: "#wavify-container",
          height: 10,
          amplitude: 7,
          bones: 8,
          speed: 0.15,
          color: fillColorWithAlpha
        });
        lastWaveEmotionId = emotionIdForWave;
      } else {
        wavifyInstance.updateColor({ color: fillColorWithAlpha, timing: 0.3 });
        wavifyInstance.play();
      }
    } else {
      path.setAttribute("fill", fillColor);
    }
  }

  function hexToRgba(hex, a) {
    if (hex.length === 4) hex = hex[1] + hex[1] + hex[2] + hex[2] + hex[3] + hex[3];
    var r = parseInt(hex.slice(1, 3), 16);
    var g = parseInt(hex.slice(3, 5), 16);
    var b = parseInt(hex.slice(5, 7), 16);
    return "rgba(" + r + "," + g + "," + b + "," + a + ")";
  }

  function updateLeafLiquid() {
    const container = document.getElementById("leaf-container");
    const rect = document.getElementById("liquidRect");
    const gradient = document.getElementById("liquidGradient");
    if (!container || !rect || !gradient) return;

    if (leafLiquidRafId != null) {
      cancelAnimationFrame(leafLiquidRafId);
      leafLiquidRafId = null;
    }

    var current = selected.slice();
    const sumRates = current.reduce(function (s, e) { return s + e.rate; }, 0);

    if (selected.length === 0 || sumRates <= 0) {
      while (gradient.firstChild) gradient.removeChild(gradient.firstChild);
      rect.setAttribute("y", String(LEAF_Y_BOTTOM));
      rect.setAttribute("height", "0");
      rect.removeAttribute("fill");
      rect.setAttribute("fill", "url(#liquidGradient)");
      setSurfaceWave(LEAF_Y_BOTTOM, null);
      prevSelectedLength = selected.length;
      return;
    }

    const isAddingEmotion = selected.length > prevSelectedLength && prevSelectedLength > 0;
    const fillPct = Math.min(100, Math.max(0, sumRates));
    var targetHeight = Math.max(2, Math.round((LEAF_LIQUID_HEIGHT * fillPct) / 100));
    var targetY = LEAF_Y_BOTTOM - targetHeight;

    // グラデーション: rate > 0 の感情だけ、値に比例して作り直す
    while (gradient.firstChild) gradient.removeChild(gradient.firstChild);
    var withRate = current.filter(function (item) { return item.rate > 0; });
    var cum = 0;
    var cumArr = withRate.map(function (item) {
      cum += item.rate;
      return cum;
    });
    var total = cumArr[cumArr.length - 1] || 1;
    withRate.forEach(function (item, i) {
      var prevCum = i === 0 ? 0 : cumArr[i - 1];
      var mid = prevCum + item.rate / 2;
      var offsetPct = total > 0 ? (mid / total) * 100 : 0;
      var stop = document.createElementNS("http://www.w3.org/2000/svg", "stop");
      stop.setAttribute("offset", Math.min(100, Math.max(0, offsetPct)) + "%");
      stop.setAttribute("stop-color", item.color);
      gradient.appendChild(stop);
    });
    rect.removeAttribute("fill");
    rect.setAttribute("fill", "url(#liquidGradient)");

    // 感情を追加したとき: 水位はスライダー合計に合わせて即反映（51なら51%、100固定にしない）
    if (isAddingEmotion) {
      if (leafLiquidRafId != null) {
        cancelAnimationFrame(leafLiquidRafId);
        leafLiquidRafId = null;
      }
      rect.setAttribute("y", targetY);
      rect.setAttribute("height", targetHeight);
      var lastEmo = getLastSelectedEmotion();
      setSurfaceWave(targetY, lastEmo ? lastEmo.color : null);
      prevSelectedLength = selected.length;
      container.classList.remove("leaf-wobble");
      container.offsetHeight;
      container.classList.add("leaf-wobble");
      setTimeout(function () { container.classList.remove("leaf-wobble"); }, 600);
      return;
    }

    if (leafLiquidRafId != null) cancelAnimationFrame(leafLiquidRafId);
    var startY = parseFloat(rect.getAttribute("y")) || LEAF_Y_BOTTOM;
    var startHeight = parseFloat(rect.getAttribute("height")) || 0;
    // 値10など小さいときも確実に表示: 空から始まる場合は即座に目標をセット（上書きより先に判定）
    if (startHeight <= 0 && targetHeight > 0) {
      rect.setAttribute("y", targetY);
      rect.setAttribute("height", targetHeight);
      var lastEmo = getLastSelectedEmotion();
      setSurfaceWave(targetY, lastEmo ? lastEmo.color : null);
      prevSelectedLength = selected.length;
      container.classList.remove("leaf-wobble");
      container.offsetHeight;
      container.classList.add("leaf-wobble");
      setTimeout(function () { container.classList.remove("leaf-wobble"); }, 600);
      return;
    }
    // アニメーション時のみ: 空状態を「満タンから」に読み替え
    if (selected.length >= 1 && (startHeight <= 0 || startY >= LEAF_Y_BOTTOM) && fillPct < 100) {
      startY = LEAF_Y_TOP;
      startHeight = LEAF_LIQUID_HEIGHT;
    }
    const duration = 800;
    const startTime = performance.now();

    function animate(t) {
      var nowSum = selected.reduce(function (s, e) { return s + e.rate; }, 0);
      if (nowSum <= 0) {
        leafLiquidRafId = null;
        rect.setAttribute("y", String(LEAF_Y_BOTTOM));
        rect.setAttribute("height", "0");
        setSurfaceWave(LEAF_Y_BOTTOM, null);
        return;
      }
      const elapsed = t - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const ease = 1 - Math.pow(1 - progress, 3);
      const y = startY + (targetY - startY) * ease;
      const h = startHeight + (targetHeight - startHeight) * ease;
      rect.setAttribute("y", y);
      rect.setAttribute("height", h);
      var lastEmo = getLastSelectedEmotion();
      setSurfaceWave(y, lastEmo ? lastEmo.color : null);
      if (progress < 1) {
        leafLiquidRafId = requestAnimationFrame(animate);
      } else {
        leafLiquidRafId = null;
      }
    }
    leafLiquidRafId = requestAnimationFrame(animate);
    prevSelectedLength = selected.length;

    container.classList.remove("leaf-wobble");
    container.offsetHeight;
    container.classList.add("leaf-wobble");
    setTimeout(function () { container.classList.remove("leaf-wobble"); }, 600);
  }

  // チップクリック（3つ選択済みのときは未選択チップは押せない）
  if (!readonly) {
    chips.forEach((chip) => {
      chip.addEventListener(
        "click",
        () => {
          const id = parseInt(chip.dataset.emotionId, 10);
          const name = chip.dataset.emotionName || "";
          const color = chip.dataset.emotionColor || "#ffec47";
          const exists = selected.find((e) => e.id === id);
          if (exists) {
            deselectEmotion(id);
          } else {
            if (selected.length >= maxEmotions) return;
            selectEmotion(id, name, color);
          }
        },
        { signal }
      );
    });
  }

  // スライダー変更（10刻み・ツールチップ・右チップ更新）
  if (!readonly) {
    rows.forEach((row, index) => {
      const slider = row.querySelector("[data-role='slider']");
      const valueText = row.querySelector("[data-role='slider-value-text']");
      const valueBubble = row.querySelector("[data-role='slider-value-bubble']");
      const valueChip = row.querySelector("[data-role='slider-value-chip']");
      if (!slider) return;

      slider.addEventListener(
        "input",
        (event) => {
          const slotIndex = index;
          if (slotIndex >= selected.length) return;
          const item = selected[slotIndex];
          if (!item) return;
          let sumPrev = 0;
          for (let j = 0; j < slotIndex; j++) {
            if (selected[j]) sumPrev += selected[j].rate;
          }
          const effectiveMax = 100 - sumPrev;
          const maxRounded = Math.floor(effectiveMax / 10) * 10;
          let newRate = parseInt(event.target.value, 10);
          newRate = Math.min(newRate, effectiveMax);
          newRate = Math.max(0, Math.round(newRate / 10) * 10);
          newRate = Math.min(newRate, maxRounded);
          item.rate = newRate;
          event.target.value = String(newRate);
          var wrap = row.querySelector("[data-role='slider-wrap']");
          if (wrap) {
            wrap.style.setProperty("--thumb-pct", String(newRate));
          }
          enforceSliderCaps();
          updateRows();
        },
        { signal }
      );

      var wrap = row.querySelector("[data-role='slider-wrap']");
      var thumbVisual = row.querySelector("[data-role='slider-thumb-visual']");
      var antiBorder = row.querySelector("[data-role='slider-anti-border']");
      var bumpShown = false;
      function getThumbCenterX() {
        if (!wrap) return 0;
        var rect = wrap.getBoundingClientRect();
        var value = parseInt(slider.value, 10);
        var travelWidth = rect.width - 48;
        return rect.left + 24 + (travelWidth * value / 100);
      }
      function getEffectiveMax() {
        var slotIndex = index;
        var sumPrev = 0;
        for (var j = 0; j < slotIndex; j++) {
          if (selected[j]) sumPrev += selected[j].rate;
        }
        return 100 - sumPrev;
      }
      var bumpPx = 8;
      function showBumpAndAntiBorder(direction) {
        if (!thumbVisual || !antiBorder) return;
        antiBorder.classList.remove("slider-anti-border-left", "slider-anti-border-right");
        antiBorder.classList.add("slider-anti-border-visible", "slider-anti-border-" + direction);
        var tx = direction === "right" ? bumpPx : -bumpPx;
        thumbVisual.classList.add("slider-thumb-bump");
        thumbVisual.style.transform = "translateX(" + tx + "px)";
        antiBorder.style.transform = "translateX(" + tx + "px)";
        setTimeout(function () {
          thumbVisual.style.transform = "";
          antiBorder.style.transform = "";
          setTimeout(function () {
            thumbVisual.classList.remove("slider-thumb-bump");
            antiBorder.classList.remove("slider-anti-border-visible", "slider-anti-border-left", "slider-anti-border-right");
          }, 220);
        }, 180);
      }
      function onPointerMove(e) {
        var clientX = e.clientX != null ? e.clientX : (e.touches && e.touches[0] ? e.touches[0].clientX : 0);
        var slotIndex = index;
        if (slotIndex >= selected.length) return;
        var val = parseInt(slider.value, 10);
        var thumbCenterX = getThumbCenterX();
        var effectiveMax = getEffectiveMax();
        var maxRounded = Math.floor(effectiveMax / 10) * 10;
        if (!bumpShown) {
          if (val >= maxRounded && clientX > thumbCenterX) {
            bumpShown = true;
            showBumpAndAntiBorder("right");
          } else if (val <= 0 && clientX < thumbCenterX) {
            bumpShown = true;
            showBumpAndAntiBorder("left");
          }
        }
      }
      function onPointerUp() {
        bumpShown = false;
        document.removeEventListener("mousemove", onPointerMove);
        document.removeEventListener("mouseup", onPointerUp);
        document.removeEventListener("touchmove", onPointerMove, { passive: true });
        document.removeEventListener("touchend", onPointerUp);
      }
      slider.addEventListener(
        "mousedown",
        function () {
          bumpShown = false;
          document.addEventListener("mousemove", onPointerMove);
          document.addEventListener("mouseup", onPointerUp);
        },
        { signal }
      );
      slider.addEventListener(
        "touchstart",
        function () {
          bumpShown = false;
          document.addEventListener("touchmove", onPointerMove, { passive: true });
          document.addEventListener("touchend", onPointerUp);
        },
        { passive: true, signal }
      );
    });
  }

  // 初期状態：既にサーバから値が入っている場合（戻る遷移など）を反映。rate は10刻みに丸める
  const initialSelected = [];
  for (let i = 0; i < 3; i++) {
    const emoVal = emoHidden[i].value;
    const rateVal = rateHidden[i].value;
    if (emoVal && rateVal) {
      const chip = chips.find((c) => parseInt(c.dataset.emotionId, 10) === parseInt(emoVal, 10));
      if (chip) {
        const raw = parseInt(rateVal, 10);
        const rate = Math.min(100, Math.max(0, Math.round(raw / 10) * 10));
        initialSelected.push({
          id: parseInt(emoVal, 10),
          name: chip.dataset.emotionName,
          color: chip.dataset.emotionColor,
          rate,
        });
      }
    }
  }
  if (initialSelected.length > 0) {
    selected = initialSelected;
    roundRatesToStep10();
  }

  // 葉UI下のバリデーションメッセージ（Submit時・不正データなら表示、OKで閉じる）
  var form = root.closest("form");
  var validationMessageWrap = document.getElementById("validation-message-wrap");
  var validationMessageText = document.getElementById("validation-message-text");
  var validationMessageOk = document.getElementById("validation-message-ok");
  if (!readonly && form && validationMessageWrap && validationMessageText && validationMessageOk) {
    form.addEventListener(
      "submit",
      function (e) {
        e.preventDefault();
        syncHiddenFields();
        var message = null;
        if (selected.length === 0) {
          message = "Please select one or more emotions.";
        } else {
          var sum = selected.reduce(function (s, e) { return s + e.rate; }, 0);
          if (sum !== 100) {
            message = "Ensure the total of the emotion values adds up to 100.";
          }
        }
        if (message) {
          validationMessageText.textContent = message;
          validationMessageWrap.classList.remove("hidden");
          return;
        }
        form.submit();
      },
      { signal }
    );
    validationMessageOk.addEventListener(
      "click",
      function () {
        validationMessageWrap.classList.add("hidden");
      },
      { signal }
    );
  }

  updateChips();
  updateRows();
}

// Turbo のみで初期化（DOMContentLoaded と併用すると同一ページで二重 init になり、チップが効かなくなる）
document.addEventListener("turbo:load", initDiaryForm);
// スクリプトが turbo:load より後に評価された場合のフォールバック（二重は AbortController で吸収）
if (document.getElementById("diary-form-root")) {
  queueMicrotask(initDiaryForm);
}

