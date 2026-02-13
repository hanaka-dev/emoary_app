function initDiaryForm() {
  const root = document.getElementById("diary-form-root");
  if (!root) return;

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

  function updateRows() {
    rows.forEach((row, index) => {
      const displayIndex = index;
      const item = selected[displayIndex];
      const labelEl = row.querySelector("[data-role='selected-chip'] .selected-chip-label");
      const removeBtn = row.querySelector(".selected-chip-remove");
      const slider = row.querySelector("[data-role='slider']");
      const valueEl = row.querySelector("[data-role='slider-value']");
      const selectedChip = row.querySelector("[data-role='selected-chip']");

      if (!item) {
        row.style.display = "none";
        if (labelEl) labelEl.textContent = "";
        if (valueEl) valueEl.textContent = "";
        if (slider) slider.value = "1";
        if (selectedChip) {
          selectedChip.style.background = "";
          selectedChip.style.color = "";
        }
        row.removeAttribute("data-emotion-id");
        row.removeAttribute("data-emotion-color");
        row.style.removeProperty("--track-color");
        return;
      }

      row.style.display = "flex";
      row.dataset.emotionId = String(item.id);
      row.dataset.emotionColor = item.color;
      row.style.setProperty("--track-color", item.color);

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
        /* トラック・つまみの色は CSS の --track-color で適用（updateRows で row にセット済み） */
      }
      if (valueEl) {
        valueEl.textContent = String(item.rate);
      }

      if (removeBtn) {
        removeBtn.onclick = () => {
          deselectEmotion(item.id);
        };
      }
    });

    syncHiddenFields();
    updateLeafLiquid();
  }

  function selectEmotion(id, name, color) {
    if (selected.find((e) => e.id === id)) return;
    if (selected.length >= maxEmotions) return;

    // いずれも初期値1。表示はスライダー値に従う（合計100のロジックは後で調整）
    selected.push({ id, name, color, rate: 1 });
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
  }

  function updateChips() {
    chips.forEach((chip) => {
      const id = parseInt(chip.dataset.emotionId, 10);
      const icon = chip.querySelector(".chip-icon");
      const isSelected = selected.find((e) => e.id === id);

      if (isSelected) {
        chip.classList.add("selected");
        chip.style.display = "";
        if (icon) icon.textContent = "";
      } else {
        chip.classList.remove("selected");
        chip.style.display = "";
        if (icon) icon.textContent = "+";
      }
    });
  }

  let leafLiquidRafId = null;
  let prevSelectedLength = 0;
  let wavifyInstance = null;
  let lastWaveEmotionId = null;

  /** 一番最後に選択された感情（最上面）。Wavifyの色・位置はこの感情に合わせる */
  function getLastSelectedEmotion() {
    return selected.length > 0 ? selected[selected.length - 1] : null;
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
    if (y >= LEAF_Y_BOTTOM) {
      g.style.visibility = "hidden";
      if (wavifyInstance) {
        wavifyInstance.kill();
        wavifyInstance = null;
      }
      lastWaveEmotionId = null;
      return;
    }
    g.style.visibility = "visible";
    var fillColor = color || "#ffec47";
    var fillColorWithAlpha = fillColor.startsWith("rgb")
      ? fillColor.replace(")", ", 0.85)").replace("rgb", "rgba")
      : hexToRgba(fillColor, 0.85);

    var lastEmo = getLastSelectedEmotion();
    var emotionIdForWave = lastEmo ? lastEmo.id : null;
    if (typeof wavify !== "undefined") {
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
        if (lastWaveEmotionId !== emotionIdForWave) {
          wavifyInstance.updateColor({ color: fillColorWithAlpha, timing: 0.3 });
          lastWaveEmotionId = emotionIdForWave;
        }
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

    if (selected.length === 0) {
      if (leafLiquidRafId != null) {
        cancelAnimationFrame(leafLiquidRafId);
        leafLiquidRafId = null;
      }
      while (gradient.firstChild) gradient.removeChild(gradient.firstChild);
      rect.setAttribute("y", String(LEAF_Y_BOTTOM));
      rect.setAttribute("height", "0");
      setSurfaceWave(LEAF_Y_BOTTOM, null);
      prevSelectedLength = 0;
      return;
    }

    const isAddingEmotion = selected.length > prevSelectedLength && prevSelectedLength > 0;
    const sumRates = selected.reduce(function (s, e) { return s + e.rate; }, 0);
    const fillPct = Math.min(100, Math.max(0, sumRates));
    var targetHeight = fillPct <= 0 ? 0 : Math.max(2, Math.round((LEAF_LIQUID_HEIGHT * fillPct) / 100));
    var targetY = LEAF_Y_BOTTOM - targetHeight;

    // グラデーション: 先に選んだ感情が下、後に選んだ感情が上（上からオレンジ・赤の順なら 上=最後)
    while (gradient.firstChild) gradient.removeChild(gradient.firstChild);
    if (selected.length > 0) {
      var cum = 0;
      var cumArr = selected.map(function (item) {
        cum += item.rate;
        return cum;
      });
      var total = cumArr[cumArr.length - 1] || 1;
      selected.forEach(function (item, i) {
        var prevCum = i === 0 ? 0 : cumArr[i - 1];
        var mid = prevCum + item.rate / 2;
        var offsetPct = total > 0 ? (mid / total) * 100 : 0;
        var stop = document.createElementNS("http://www.w3.org/2000/svg", "stop");
        stop.setAttribute("offset", Math.min(100, Math.max(0, offsetPct)) + "%");
        stop.setAttribute("stop-color", item.color);
        gradient.appendChild(stop);
      });
    }

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

  // チップクリック
  chips.forEach((chip) => {
    const id = parseInt(chip.dataset.emotionId, 10);
    const name = chip.dataset.emotionName;
    const color = chip.dataset.emotionColor;

    chip.addEventListener("click", () => {
      const exists = selected.find((e) => e.id === id);
      if (exists) {
        deselectEmotion(id);
      } else {
        selectEmotion(id, name, color);
      }
    });
  });

  // スライダー変更
  rows.forEach((row, index) => {
    const slider = row.querySelector("[data-role='slider']");
    const valueEl = row.querySelector("[data-role='slider-value']");
    if (!slider) return;

    slider.addEventListener("input", (event) => {
      const slotIndex = index;
      const item = selected[slotIndex];
      if (!item) return;
      const newRate = parseInt(event.target.value, 10);
      item.rate = newRate;

      if (valueEl) {
        valueEl.textContent = String(newRate);
      }

      // 表示はスライダー値の和に完全比例（他スロットは触らない。合計100ロジックは後で別途）
      syncHiddenFields();
      updateLeafLiquid();
    });
  });

  // 初期状態：既にサーバから値が入っている場合（戻る遷移など）を反映
  const initialSelected = [];
  for (let i = 0; i < 3; i++) {
    const emoVal = emoHidden[i].value;
    const rateVal = rateHidden[i].value;
    if (emoVal && rateVal) {
      const chip = chips.find((c) => parseInt(c.dataset.emotionId, 10) === parseInt(emoVal, 10));
      if (chip) {
        initialSelected.push({
          id: parseInt(emoVal, 10),
          name: chip.dataset.emotionName,
          color: chip.dataset.emotionColor,
          rate: parseInt(rateVal, 10),
        });
      }
    }
  }
  if (initialSelected.length > 0) {
    selected = initialSelected;
  }

  updateChips();
  updateRows();
}

// 通常のページ読み込み
document.addEventListener("DOMContentLoaded", initDiaryForm);
// Turboで遷移したとき（home→diaries など）も初期化する
document.addEventListener("turbo:load", initDiaryForm);

