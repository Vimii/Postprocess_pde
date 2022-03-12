# Postprocess_pde
ビジュアル情報処理の最終課題にて作成。

* Bloom
* Depth Of Field
* Chromatic Aberration

## 操作方法

### 共通
* Shiftでモード切替（Bloom->DoF->CA）
* マウスクリックで球を投げる
* マウスでスライダーを制御

### Bloom

* Thresholdスライダーを制御することでBloomの掛かり具合を制御できる。
* 左が元画像。中央が加算するBloomバッファ。右が合成後の画像。

### Depth of Field

* マウス位置の深度値がマウス横に表示されている。
* Enterを押すとその時点の画面でDoFが作成される。（作成中は処理時間がかかる）
* DoF合成画像が表示されたら、ThresholdとfocusDistの変数を変更することでDoFの強度とフォーカス距離を変更することができる。
* もう一度Enterを押すことで元の画面に戻る。

### Chromatic Aberration

* rangeスライダを調整することで強度を変更できる。
