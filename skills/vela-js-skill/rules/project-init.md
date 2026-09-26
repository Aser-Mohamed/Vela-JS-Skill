---
description: 项目初始化规范 — 脚手架命令、检查清单、禁止行为
alwaysApply: true
---

# 项目初始化规范（强制执行）

## 唯一允许的初始化命令

```bash
npx create-aiot ux --name {项目名} --template vela-demo
```

> `--template vela-demo` 用于自动选择模板，避免交互式提示导致命令阻塞。

## 禁止行为清单

| 编号 | 禁止行为 | 原因 |
|------|----------|------|
| N1 | 手动创建 package.json | 脚手架自动生成 |
| N2 | 手动创建 src/manifest.json | 脚手架自动生成 |
| N3 | 手动创建 src/app.ux | 脚手架自动生成 |
| N4 | 手动创建 src/config-watch.json | 脚手架自动生成 |
| N5 | 手动创建 src/i18n/ 目录 | 脚手架自动生成 |
| N6 | 手动创建 src/common/logo.png | 脚手架自动生成 |
| N7 | 使用 hap-toolkit 命令 | 应使用 create-aiot |
| N8 | 修改脚手架生成的基础文件结构 | 保持兼容性 |

## 执行前检查清单

| 检查项 | 检查方法 | 通过条件 |
|--------|----------|----------|
| 项目名规范 | 正则 `/^[a-z][a-z0-9-]*$/` | 仅小写字母、数字、连字符 |
| 目标目录不存在 | `ls {目录}/{项目名}` | 返回"No such file" |
| npm 源可用 | `npm config get registry` | 有效 registry URL |
| npx 可用 | `which npx` | 返回路径 |

## 初始化后允许的操作

- ✅ 添加新页面（src/pages/xxx/index.ux）
- ✅ 修改页面代码逻辑
- ✅ 添加自定义组件
- ✅ 修改样式文件
- ✅ 补全 README.md
- ✅ 补全 .gitignore
