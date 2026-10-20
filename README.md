# 代码精灵学院网站（静态版 + Quarto 源文件）

## 本地浏览
双击 `index.html` 即可打开静态网页；无需安装 R/Python。建议用 Chrome 或 Edge。

## 接入你已有的 Python/R HTML 页面
- 将 Python HTML 页面及其引用的资源复制到 `python/` 文件夹，主文件建议命名 `index.html`，覆盖占位页。
- 将 R HTML 页面及其引用的资源复制到 `r/` 文件夹，主文件建议命名 `index.html`，覆盖占位页。
- 不要只复制 HTML 而漏掉旁边的图片、CSS、JS 文件；保留原来的相对目录结构。

## Quarto 源文件
`index.qmd` 是故事与内容源文件，代码块复制按钮由 `_quarto.yml` 的 `code-copy: true` 启用。安装 Quarto 后，在本目录运行：

```bash
quarto render
```

渲染结果位于 `_site/`。注意：本包提供了可直接打开的 `index.html` 静态版；Quarto 生成版需要 Quarto CLI 执行渲染。若把 `index.qmd` 里的图片/附件路径用于 Quarto，请确保资源文件仍在同一相对路径下。

## 发布到 GitHub Pages
1. 在 GitHub 新建一个仓库，例如 `bioinformatics-elf-school`。
2. 上传本目录中的网站文件和文件夹（包括 `index.html`、`assets/`、`downloads/`、`data/`、`python/`、`r/`）。
3. 仓库打开 Settings → Pages。
4. 在 Build and deployment 选择 `Deploy from a branch`，分支选 `main`，目录选 `/ (root)`，保存。
5. 等待 Pages 发布完成，使用 GitHub 给出的网址分享给师弟师妹。

如果你以后希望每次编辑 QMD 后自动渲染，可改用 Quarto 官方的 GitHub Pages 发布工作流；当前静态版不需要构建步骤。

## 文件说明
- `index.html`: 可本地直接打开的首页
- `index.qmd`: 可维护的 Quarto 内容源文件（故事、图片、代码块）
- `_quarto.yml`: Quarto 网站配置，启用代码复制
- `assets/`: PPT 页面截图和 AI Tips 图片
- `downloads/`: Word、Python Notebook、R 脚本
- `data/`: 示例 CSV 数据
- `python/`、`r/`: 等待替换成你已有的 HTML 页面

**提示：** 浏览网站不需要安装任何软件；运行 R/Python 代码则仍需要本地或云端执行环境。不要把密钥、私人数据或含敏感信息的样本文件上传到公开仓库。
