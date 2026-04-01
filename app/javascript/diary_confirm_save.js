/* Save 確認モーダル: @lottiefiles/dotlottie-web + canvas。
 * data-lottie-src に .lottie / .json の絶対 URL。未指定時は /lottie/success_animation.json */

import { DotLottie } from "https://cdn.jsdelivr.net/npm/@lottiefiles/dotlottie-web@0.69.0/+esm";

const DOTLOTTIE_VERSION = "0.69.0";
const WASM_URL = `https://cdn.jsdelivr.net/npm/@lottiefiles/dotlottie-web@${DOTLOTTIE_VERSION}/dist/dotlottie-player.wasm`;

let diarySaveModalAbort = null;
let wasmConfigured = false;
let activeModalDotLottie = null;

function ensureWasmUrl() {
  if (wasmConfigured) return;
  wasmConfigured = true;
  if (typeof DotLottie.setWasmUrl === "function") {
    DotLottie.setWasmUrl(WASM_URL);
  }
}

function teardownModalDotLottie() {
  if (!activeModalDotLottie) return;
  try {
    activeModalDotLottie.destroy();
  } catch (_) {
    /* ignore */
  }
  activeModalDotLottie = null;
}

function defaultAnimationSrc() {
  return `${window.location.origin}/lottie/success_animation.json`;
}

function initDiarySaveModal() {
  const form = document.querySelector("form[data-diary-save-modal]");
  if (!form) return;

  if (diarySaveModalAbort) diarySaveModalAbort.abort();
  diarySaveModalAbort = new AbortController();
  const { signal } = diarySaveModalAbort;

  const modal = document.getElementById("diary-save-modal");
  const canvas = document.getElementById("diary-save-dotlottie-canvas");
  if (!modal || !canvas) return;

  const srcFromData = form.dataset.lottieSrc;
  const animationSrc = (srcFromData && srcFromData.trim()) || defaultAnimationSrc();

  let allowSubmit = false;

  form.addEventListener(
    "submit",
    function (e) {
      if (allowSubmit) {
        allowSubmit = false;
        return;
      }
      e.preventDefault();
      e.stopPropagation();

      ensureWasmUrl();
      teardownModalDotLottie();

      modal.classList.remove("hidden");
      modal.setAttribute("aria-hidden", "false");

      let settled = false;

      function finish() {
        if (settled) return;
        settled = true;
        teardownModalDotLottie();
        modal.classList.add("hidden");
        modal.setAttribute("aria-hidden", "true");
        allowSubmit = true;
        if (typeof form.requestSubmit === "function") {
          form.requestSubmit();
        } else {
          form.submit();
        }
      }

      function mountDotLottie() {
        if (settled) return;
        try {
          activeModalDotLottie = new DotLottie({
            canvas,
            src: animationSrc,
            autoplay: true,
            loop: false,
            renderConfig: {
              autoResize: true,
              devicePixelRatio: Math.min(typeof window !== "undefined" ? window.devicePixelRatio || 1 : 1, 2),
            },
          });
          activeModalDotLottie.addEventListener("load", function () {
            try {
              activeModalDotLottie.resize();
            } catch (_) {
              /* ignore */
            }
          });
          activeModalDotLottie.addEventListener("complete", finish);
          activeModalDotLottie.addEventListener("loadError", function () {
            window.setTimeout(finish, 2000);
          });
        } catch (_) {
          window.setTimeout(finish, 2000);
        }
      }

      /* display:none 解除直後は canvas のレイアウトが 0 のことがあるので 2 フレーム待ってから初期化 */
      window.requestAnimationFrame(function () {
        window.requestAnimationFrame(mountDotLottie);
      });

      window.setTimeout(finish, 12000);
    },
    { capture: true, signal }
  );
}

document.addEventListener("turbo:load", initDiarySaveModal);
if (document.querySelector("form[data-diary-save-modal]")) {
  queueMicrotask(initDiarySaveModal);
}
