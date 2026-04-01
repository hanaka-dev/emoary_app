// デモアカウント: タブを閉じる・ページを離れるときに追加分の日記をサーバーで削除（sendBeacon）
;(function () {
  if (typeof window === "undefined") return
  if (window.__emoaryDemoTabPurgeBound) return
  window.__emoaryDemoTabPurgeBound = true

  window.addEventListener("pagehide", function (event) {
    if (event.persisted) return
    var meta = document.querySelector('meta[name="emoary-demo-tab-purge-url"]')
    if (!meta) return
    var url = meta.getAttribute("content")
    var tokenEl = document.querySelector('meta[name="csrf-token"]')
    var token = tokenEl && tokenEl.getAttribute("content")
    if (!url || !token) return
    var body = new URLSearchParams()
    body.append("authenticity_token", token)
    navigator.sendBeacon(url, body)
  })
})()
