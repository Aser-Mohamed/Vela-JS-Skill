#!/bin/bash
# Hook: UserPromptSubmit
# Detect vela-workflow triggers and remind user to provide requirement doc & design mockup

PROMPT="$1"

KEYWORDS="创建 Vela 快应用|创建 Vela 应用|创建小米手表快应用|创建小米手表应用|Vela 快应用|vela app|vela quickapp|小米快应用|小米穿戴应用|vela-workflow|记账|天气|闹钟|计时|运动|心率|睡眠|日程|待办|备忘"

if echo "$PROMPT" | grep -qiE "$KEYWORDS"; then
  cat <<'EOF'
⚠️ 检测到 Vela 快应用开发请求。为了生成高质量的应用代码，建议提供：

📄 [必要] 需求文档 — 功能描述、用户场景、核心流程
   格式：文字描述 / Markdown 文件路径 / 飞书文档链接

🎨 [推荐] 设计稿 — UI 布局、交互细节、视觉规范
   格式：Figma 链接 / 设计图片路径 / .pen 文件路径

如果暂时没有，可直接继续，工作流将基于需求描述自动推导。
EOF
fi

exit 0
