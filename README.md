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

## 语音输入

没在打字时，按住右 Option 键约 0.3 秒开始听，候选框里显示「🎙」和已经识别出的文字；松开右 Option，文字直接输入到当前位置。按 Esc 取消，什么都不输入。

- 只用 macOS 自带的本机离线识别（普通话），声音不上传，不联网，不接入大模型。
- 第一次使用时系统会询问麦克风和语音识别权限，同意后再按住一次即可。程序是本地签名的，每次升级后系统可能会再问一次。
- 本机没有中文离线识别时会提示：到「系统设置 → 键盘 → 听写」里添加普通话。
- 按住右 Option 时又按了别的键（Option 组合键）不会开始听，Option 组合键照常可用。
- 不需要时在输入法菜单里取消勾选「语音输入（按住右 Option 说话）」。

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

本程序修改自 Rime 输入法引擎的 macOS 前端 <https://github.com/rime/squirrel>（1.1.2 版，GPL-3.0），按 GPL-3.0 第 5 条注明来源和修改。2026-10-22 起（SENK 1.0.0）的主要修改：程序名称与标识、两个输入模式各对应一个方案、去掉自动更新组件、注册路径随程序所在位置；打包的 Rime 数据 `essay.txt`（LGPL-3.0）删除了「鼠鬚管」一个词条。之后各版本的修改见 git 提交记录。源文件中原作者的署名保留。

程序包里的第三方组件（librime 及其插件和依赖库、OpenCC、Rime 数据等）的版权声明和许可证见 [THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt)，程序包内的同名文件在 `Contents/Resources/` 下。
