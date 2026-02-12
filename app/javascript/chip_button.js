// 選択emotionチップ表示/削除用
function showChip(chipToShowId, chipToHideId) {
    const showChip = document.getElementById(chipToShowId);
    const hideChip = document.getElementById(chipToHideId);
    if (showChip) showChip.style.display = 'block';
    if (hideChip) hideChip.style.display = 'none';
}
