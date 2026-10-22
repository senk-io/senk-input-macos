# SENK五笔（macOS 输入法程序）

macOS 上的 SENK 输入法程序。系统输入法菜单里有两个模式：

| 模式 | 方案 | 说明 |
|---|---|---|
| SENK五笔 | `wubi86_pinyin` | SENK五笔混拼输入法86版 |
| SENK拼音 | `senk_pinyin` | SENK拼音输入法 |

菜单栏显示的模式就是正在用的方案；方案只随系统输入法菜单切换，Control+\`、F4 不切换方案。

方案、词库和安装脚本在 [senk-io/wubi86-pinyin](https://github.com/senk-io/wubi86-pinyin)。一般用那里的安装脚本安装，不需要自己编译。

- 输入引擎：librime 1.16.0，带 lua、octagram、predict 插件
- 用户目录：`~/Library/Rime`
- 日志：`$TMPDIR/rime.senk/`
- 不自动检查更新，也不联网

## 编译

需要 Xcode（命令行工具）。

```sh
git clone --recursive https://github.com/senk-io/senk-input-macos.git
cd senk-input-macos
./action-build.sh                 # 只编译本机架构；两种架构都要时：ARCHS='arm64 x86_64' ./action-build.sh
```

产物是 `build/Build/Products/Release/SenkWubi.app`。

## 安装与卸载（不需要 sudo）

```sh
app="$HOME/Library/Input Methods/SenkWubi.app"
ditto build/Build/Products/Release/SenkWubi.app "$app"
"$app/Contents/MacOS/SenkWubi" --register-input-source
"$app/Contents/MacOS/SenkWubi" --enable-input-source io.senk.inputmethod.SenkWubi.Wubi io.senk.inputmethod.SenkWubi.Pinyin
"$app/Contents/MacOS/SenkWubi" --select-input-source io.senk.inputmethod.SenkWubi.Wubi
```

卸载：

```sh
app="$HOME/Library/Input Methods/SenkWubi.app"
"$app/Contents/MacOS/SenkWubi" --disable-input-source
"$app/Contents/MacOS/SenkWubi" --quit
mv "$app" ~/.Trash/
```

`~/Library/Rime` 里的词库和配置不会被删除。

## 发布

推送 `v<版本号>` 标签（与 `CURRENT_PROJECT_VERSION` 一致）后，GitHub Actions 编译 arm64 + x86_64 版本，发布 `SenkWubi-<版本号>.zip` 和 `SHA256SUMS`。程序为本地签名，未经 Apple 公证。

## 许可证

GPL-3.0，见 [LICENSE.txt](LICENSE.txt)。

本程序修改自 Rime 输入法引擎的 macOS 前端 <https://github.com/rime/squirrel>（1.1.2 版，GPL-3.0），按 GPL-3.0 第 5 条注明来源和修改。主要修改：程序名称与标识、两个输入模式各对应一个方案、去掉自动更新组件、注册路径随程序所在位置。源文件中原作者的署名保留。
