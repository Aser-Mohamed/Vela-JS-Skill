---
name: vela-js-app-development
description: Xiaomi Vela JS 应用开发技能。用于创建、开发和调试运行在小米 IoT 穿戴设备（手表）上的 Vela JS 应用。包含项目结构、manifest 配置、UX 文件编写（template/style/script）、组件使用、接口调用等完整知识。当用户需要开发 Vela JS 应用、创建页面、使用组件或调用系统接口时使用此技能。
---

# Xiaomi Vela JS 应用开发指南

官方文档站点：https://iot.mi.com/vela/quickapp/

## 框架概述

Xiaomi Vela JS 是小米基于 Vela OS 的轻量级 JS 应用框架，面向智能穿戴设备（手表）。采用前端 MVVM 开发范式，使用 `.ux` 文件编写页面，`manifest.json` 配置应用，Flexbox 布局，支持数据绑定和组件化开发。

## 创建项目

### 方式一：使用脚手架（推荐）

检查是否安装了 aiot-toolkit，如果已安装则使用命令创建：
```bash
npm create aiot ux -- --name my-app --template vela-demo
cd my-app
npm install
```

### 方式二：手动创建

如果未安装 aiot-toolkit，参考以下目录结构手动创建项目。应用图标 `src/common/logo.png` 若缺失，用 PIL/ImageMagick 生成一枚带应用首字母的占位图标。

## 项目结构

```
├── README.md              # 项目说明
├── .gitignore             # Git 忽略配置
├── package.json           # npm 配置，定义构建脚本和依赖
└── src/
    ├── manifest.json      # 应用配置（包名、路由、接口声明等）
    ├── app.ux             # 应用级公共脚本和生命周期
    ├── config-watch.json  # 手表设备配置（内容为 {}）
    ├── pages/             # 页面目录
    │   ├── index/
    │   │   └── index.ux
    │   └── detail/
    │       └── detail.ux
    ├── i18n/              # 国际化资源
    │   ├── defaults.json
    │   ├── zh-CN.json
    │   └── en.json
    └── common/            # 公共资源
        └── logo.png       # 应用图标
```

注意：页面放在 `src/pages/` 下，`manifest.json` 中 `router.pages` 的 key 需带 `pages/` 前缀（如 `"pages/index"` 对应 `src/pages/index/`）。

构建后会自动生成 `build/`（中间产物）、`dist/`（rpk 包）目录；`sign/`（签名证书）由 release 命令引导生成。

### package.json 示例

```json
{
  "name": "my-app",
  "version": "1.0.0",
  "scripts": {
    "start": "aiot start --watch",
    "build": "aiot build",
    "release": "aiot release"
  },
  "devDependencies": {
    "aiot-toolkit": "^2.0.5"
  }
}
```

### .gitignore

```
/node_modules
/dist
/build
```

## manifest.json 配置

```json
{
  "package": "com.company.demo",
  "name": "应用名称",
  "icon": "/common/logo.png",
  "versionName": "1.0",
  "versionCode": 1,
  "minPlatformVersion": 1200,
  "deviceTypeList": ["watch"],
  "features": [
    { "name": "system.router" },
    { "name": "system.configuration" }
  ],
  "config": {
    "logLevel": "log",
    "designWidth": 480
  },
  "router": {
    "entry": "pages/index",
    "pages": {
      "pages/index": {
        "component": "index"
      },
      "pages/detail": {
        "component": "detail"
      }
    }
  }
}
```

关键字段：
- `package`：应用包名，格式 com.company.module
- `name`：应用名称，6个汉字以内
- `versionCode`：整数版本号，每次发布+1
- `features`：接口声明数组，使用接口前必须声明
- `config.designWidth`：设计基准宽度，默认480px
- `router.entry`：首页路径，如 `"pages/index"`
- `router.pages`：页面路由配置，key 为页面目录相对 src 的路径（如 `"pages/index"` 对应 `src/pages/index/`），component 为 ux 文件名
- `router.pages[].launchMode`：页面启动模式，支持 "standard"（默认）和 "singleTask"

## UX 文件格式

每个页面/组件由 `.ux` 文件编写，包含 template、style、script 三部分：

```html
<template>
  <!-- 只能有一个根节点 -->
  <div class="page">
    <text class="title">{{title}}</text>
    <input type="button" value="点击" onclick="handleClick" />
  </div>
</template>

<style>
  .page {
    flex-direction: column;
    justify-content: center;
    align-items: center;
  }
  .title {
    font-size: 30px;
    color: #333333;
  }
</style>

<script>
  import router from '@system.router'

  export default {
    private: {
      title: '示例页面'
    },
    onInit() {
      console.log('页面初始化')
    },
    handleClick() {
      router.push({ uri: '/pages/detail' })
    }
  }
</script>
```

也可拆分为独立文件（detail.ux + detail.css + detail.js），此时 ux 文件不包含 template 标签。

## Template 模板语法

### 数据绑定
```html
<text>{{message}}</text>
```

### 条件渲染
```html
<!-- if/elif/else 必须是相邻兄弟节点 -->
<text if="{{show}}">显示</text>
<text elif="{{other}}">其他</text>
<text else>默认</text>

<!-- show 指令：不从DOM移除，仅隐藏 -->
<text show="{{visible}}">内容</text>
```

### 列表渲染
```html
<!-- 基本用法 -->
<div for="{{list}}" tid="id">
  <text>{{$idx}}: {{$item.name}}</text>
</div>

<!-- 自定义变量名 -->
<div for="(index, item) in list" tid="id">
  <text>{{index}}: {{item.name}}</text>
</div>
```

- `tid` 属性指定数组元素唯一ID，用于优化渲染
- for 只能循环数组，不能循环对象
- `<block>` 标签可用于逻辑控制，不产生额外DOM节点

### 事件绑定
```html
<text onclick="handleClick">点击</text>
<text @click="handleClick">简写</text>
<text onclick="handleClick($idx, $item)">传参</text>
```
回调函数末尾自动添加 `evt` 参数。

## Style 样式系统

### 布局
- 采用 CSS Flexbox 布局，默认 `flex-direction: row`
- 盒模型为 `border-box`
- div 为 Flex 容器，text/span 为文本容器

### 长度单位
- `px`：相对于 designWidth 的适配单位（类似 rem），自动按屏幕宽度缩放
- `%`：百分比
- `dp`：设备独立像素（API Level 3+）

### 选择器（支持）
- `.class` / `#id` / `tag` / 并列选择 `.a, .b`
- 优先级：inline > #id > .class > tag
- 暂不支持后代选择器

### 样式预编译
支持 less 和 scss：
```html
<style lang="less">
  @import './style.less';
</style>
```

### 通用样式属性
width, height, min-width, min-height, max-width, max-height, padding, margin, border, border-radius, background-color, background-image, background-size, background-position, color, opacity, display(flex|none), visibility, position(relative|absolute), flex, flex-grow, flex-shrink, flex-direction, align-items, justify-content, box-shadow, left/top/right/bottom

## Script 脚本

### 页面数据对象
```javascript
export default {
  // 页面级数据（三选一，不能与 data 同时使用）
  public: {},     // 允许被外部传入数据覆盖
  protected: {},  // 允许被应用内部页面传参覆盖
  private: {},    // 不允许被覆盖

  // 组件级数据
  data: {},

  // 计算属性
  computed: {
    fullName() {
      return this.firstName + ' ' + this.lastName
    }
  }
}
```

### 页面生命周期
- `onInit()`：数据准备好，可使用页面数据
- `onReady()`：模板编译完成，可获取DOM节点
- `onShow()`：页面显示
- `onHide()`：页面隐藏
- `onDestroy()`：页面销毁，应释放资源
- `onBackPress()`：返回按键，return true 阻止返回
- `onRefresh(query)`：singleTask模式页面重新打开
- `onConfigurationChanged(event)`：系统配置变化（如语言）

### APP 生命周期（app.ux）
- `onCreate()` / `onShow()` / `onHide()` / `onDestroy()` / `onError(e)`

### 全局对象和方法
```javascript
// 访问 app.ux 中定义的数据和方法
this.$app.$def.data1
this.$app.$def.method1()

// 退出应用
this.$app.exit()

// 页面信息
this.$page.name / this.$page.path

// 页面有效性
this.$valid

// DOM操作
this.$element('id')

// 数据监听
this.$watch('propName', 'handlerName')

// 能力查询
this.$canIUse('@system.router.push')

// 下次DOM更新后回调
this.$nextTick(() => { /* ... */ })

// 事件通信
this.$on('eventName', handler)
this.$off('eventName', handler)
this.$emit('eventName', { data: 1 })       // 触发当前组件事件
this.$dispatch('eventName', { data: 1 })    // 向上传递
this.$broadcast('eventName', { data: 1 })   // 向下传递
```

## 自定义组件

### 定义组件（comp.ux）
```html
<template>
  <div>
    <text>{{say}}</text>
  </div>
</template>
<script>
  export default {
    props: ['say'],          // 或 Object 形式设置默认值和类型校验
    data: { localVal: '' },  // 组件只能用 data
    onInit() {},
    onReady() {},
    onDestroy() {}
  }
</script>
```

### 引入组件
```html
<import name="my-comp" src="./comp"></import>
<template>
  <div>
    <my-comp say="{{message}}" prop-object="{{obj}}"></my-comp>
  </div>
</template>
```

### Props
- 驼峰命名在模板中转为短横线：`propObject` → `prop-object`
- 数据单向流动：父→子
- 支持默认值和类型校验（String/Number/Boolean/Function/Object/Array）

### 父子通信
- 父→子：通过 props 传递数据
- 子→父：`this.$emit('eventName', data)` + 父组件 `onemit-evt="handler"`
- 向上传递：`this.$dispatch()` + 父组件 `this.$on()`
- 向下传递：`this.$broadcast()` + 子组件 `this.$on()`

## 页面切换

```javascript
import router from '@system.router'

// 跳转（保留当前页面）
router.push({ uri: '/pages/detail', params: { id: '1' } })

// 替换（销毁当前页面）
router.replace({ uri: '/pages/detail', params: { id: '1' } })

// 返回
router.back()
router.back({ path: '/pages/index' })

// 清空页面栈
router.clear()

// 获取页面信息
router.getLength()
router.getState()   // { index, name, path }
router.getPages()   // [{ name, path }, ...]
```

接收参数：在目标页面的 `protected`（应用内）或 `public`（应用外）中声明同名属性。

## 组件详解

官方组件文档：https://iot.mi.com/vela/quickapp/zh/components/

### 容器组件

**div** — 基础 Flex 容器
[文档](https://iot.mi.com/vela/quickapp/zh/components/container/div.html)

**list + list-item** — 高性能列表
[list 文档](https://iot.mi.com/vela/quickapp/zh/components/container/list.html) | [list-item 文档](https://iot.mi.com/vela/quickapp/zh/components/container/list-item.html)
```html
<list class="list" onscrollbottom="loadMore">
  <list-item type="item" for="{{list}}" tid="id">
    <text>{{$item.name}}</text>
  </list-item>
</list>
```
- `list-item` 必须设置 `type` 属性，相同结构的 item 使用相同 type
- list 事件：`scroll`（{scrollX, scrollY, scrollState}）、`scrollbottom`、`scrolltop`
- list 方法：`scrollTo({index, behavior})` / `scrollBy({top, behavior})`

**scroll** — 滚动容器
[文档](https://iot.mi.com/vela/quickapp/zh/components/container/scroll.html)
```html
<scroll scroll-y="true" style="height: 300px;" onscroll="onScroll">
  <!-- 内容 -->
</scroll>
```
- 属性：`scroll-x` / `scroll-y`（boolean）、`scroll-top` / `scroll-left`（设置滚动位置）
- 样式：`scroll-snap-type` / `scroll-snap-align`（滚动吸附）

**swiper** — 滑块视图
[文档](https://iot.mi.com/vela/quickapp/zh/components/container/swiper.html)
```html
<swiper index="0" autoplay="true" interval="3000" loop="true" onchange="onChange">
  <div><text>页面1</text></div>
  <div><text>页面2</text></div>
</swiper>
```
- 属性：`index` / `autoplay` / `interval` / `loop` / `vertical` / `indicator` / `previousmargin` / `nextmargin`
- 样式：`indicator-color` / `indicator-selected-color` / `indicator-size`
- 事件：`change`（{index}）
- 方法：`swipeTo({index})`

**stack** — 层叠容器
[文档](https://iot.mi.com/vela/quickapp/zh/components/container/stack.html)

### 基础组件

**text** — 文本
[文档](https://iot.mi.com/vela/quickapp/zh/components/basic/text.html)
- 样式：`lines`（行数）、`text-overflow`（clip/ellipsis，需配合 lines）、`color`、`font-size`、`font-weight`、`text-align`、`line-height`、`text-indent`
- 子组件仅支持 `<span>`

**image** — 图片
[文档](https://iot.mi.com/vela/quickapp/zh/components/basic/image.html)
```html
<image src="/common/logo.png" alt="blank" />
```
- 属性：`src`（本地/网络 uri）、`alt`（占位图，设为 "blank" 无占位图）
- 样式：`object-fit`（contain/cover/none/scale-down，默认 cover）
- 事件：`complete`（{width, height}）、`error`

**其他基础组件**：
- `span`：行内文本，仅作 text 子组件 [文档](https://iot.mi.com/vela/quickapp/zh/components/basic/span.html)
- `a`：链接 [文档](https://iot.mi.com/vela/quickapp/zh/components/basic/a.html)
- `progress`：进度条（type: horizontal/circular, percent） [文档](https://iot.mi.com/vela/quickapp/zh/components/basic/progress.html)
- `marquee`：跑马灯 [文档](https://iot.mi.com/vela/quickapp/zh/components/basic/marquee.html)
- `chart`：图表 [文档](https://iot.mi.com/vela/quickapp/zh/components/basic/chart.html)
- `qrcode`：二维码 [文档](https://iot.mi.com/vela/quickapp/zh/components/basic/qrcode.html)
- `barcode`：条形码 [文档](https://iot.mi.com/vela/quickapp/zh/components/basic/barcode.html)
- `image-animator`：帧动画 [文档](https://iot.mi.com/vela/quickapp/zh/components/basic/image-animator.html)

### 表单组件

**input** — 输入/按钮/选择
[文档](https://iot.mi.com/vela/quickapp/zh/components/form/input.html)
```html
<input type="button" value="点击" onclick="onClick" />
<input type="checkbox" checked="{{checked}}" onchange="onCheck" />
<input type="radio" name="group" value="1" onchange="onRadio" />
```
- type：`button` / `checkbox` / `radio`
- 属性：`checked`（checkbox/radio）、`name`、`value`
- 事件：`change`（{name, value, checked}），button 无 change 事件

**picker** — 选择器
[文档](https://iot.mi.com/vela/quickapp/zh/components/form/picker.html)
- type：`text` / `date` / `time` / `multi-text`

**slider** — 滑块 [文档](https://iot.mi.com/vela/quickapp/zh/components/form/slider.html)

**switch** — 开关 [文档](https://iot.mi.com/vela/quickapp/zh/components/form/switch.html)

### 通用属性
所有组件支持：`id`, `style`, `class`, `for`, `if`, `show`, `data-*`
[文档](https://iot.mi.com/vela/quickapp/zh/components/general/properties.html)

### 通用事件
所有组件支持：`touchstart`, `touchmove`, `touchend`, `click`, `longpress`, `swipe`
[文档](https://iot.mi.com/vela/quickapp/zh/components/general/events.html)

### 通用样式
[文档](https://iot.mi.com/vela/quickapp/zh/components/general/style.html) | [颜色](https://iot.mi.com/vela/quickapp/zh/components/general/color.html) | [动画](https://iot.mi.com/vela/quickapp/zh/components/general/animation-style.html) | [背景图](https://iot.mi.com/vela/quickapp/zh/components/general/background-img-styles.html)

## 接口详解

官方接口文档：https://iot.mi.com/vela/quickapp/zh/features/

### 高频接口完整用法

**fetch — 网络请求**
[文档](https://iot.mi.com/vela/quickapp/zh/features/network/fetch.html)
声明：`{ "name": "system.fetch" }`
```javascript
import fetch from '@system.fetch'

// GET 请求
fetch.fetch({
  url: 'https://api.example.com/data',
  responseType: 'json',
  success(res) {
    console.log(res.data)   // Object（json时）
    console.log(res.code)   // HTTP 状态码
    console.log(res.headers)
  },
  fail(data, code) {
    console.log(code)
  }
})

// POST 请求
fetch.fetch({
  url: 'https://api.example.com/submit',
  method: 'POST',
  header: { 'Content-Type': 'application/json' },
  data: JSON.stringify({ key: 'value' }),
  responseType: 'json',
  success(res) { console.log(res.data) }
})
```
- 参数：`url`、`method`（GET/POST/PUT/DELETE...）、`header`、`data`（String/Object/ArrayBuffer）、`responseType`（text/json/file/arraybuffer）
- 返回：`{code, data, headers}`

**audio — 音频播放**
[文档](https://iot.mi.com/vela/quickapp/zh/features/other/audio.html)
声明：`{ "name": "system.audio" }`
```javascript
import audio from '@system.audio'

audio.src = '/common/music.mp3'
audio.autoplay = false
audio.loop = false
audio.volume = 0.8

audio.play()
audio.pause()
audio.stop()

audio.onended = function() { console.log('播放结束') }
audio.onerror = function() { console.log('播放出错') }

audio.getPlayState({
  success(data) {
    // data: { state, src, currentTime, duration, percent, autoplay, loop, volume, muted }
  }
})
```
- 可读写属性：`src`、`currentTime`、`autoplay`、`loop`、`volume`、`muted`
- 只读属性：`duration`
- 事件：`onplay`、`onpause`、`onstop`、`onended`、`onerror`、`onloadeddata`、`ondurationchange`

**prompt — 弹窗提示**
[文档](https://iot.mi.com/vela/quickapp/zh/features/other/prompt.html)
声明：`{ "name": "system.prompt" }`
```javascript
import prompt from '@system.prompt'

prompt.showToast({ message: '操作成功', duration: 2000 })
```

**storage — 键值存储**
[文档](https://iot.mi.com/vela/quickapp/zh/features/data/storage.html)
声明：`{ "name": "system.storage" }`
```javascript
import storage from '@system.storage'

storage.set({ key: 'token', value: 'xxx' })
storage.get({ key: 'token', success(data) { console.log(data) } })
storage.delete({ key: 'token' })
storage.clear()
```

**router — 页面路由**（无需声明）
[文档](https://iot.mi.com/vela/quickapp/zh/features/basic/router.html)
用法见上方"页面切换"章节。

### 其他接口速查

**基本功能**：
- `@system.app`：应用管理 [文档](https://iot.mi.com/vela/quickapp/zh/features/basic/app.html)
- `@system.configuration`：应用配置 [文档](https://iot.mi.com/vela/quickapp/zh/features/basic/configuration.html)
- `@system.device`：设备信息 [文档](https://iot.mi.com/vela/quickapp/zh/features/basic/device.html)

**网络**：
- `@system.request`：下载管理（download/onDownloadComplete） [文档](https://iot.mi.com/vela/quickapp/zh/features/network/request.html)
- `@system.interconnect`：设备互联（instance/send/diagnosis） [文档](https://iot.mi.com/vela/quickapp/zh/features/network/interconnect.html)
- `@system.uploadtask`：上传任务 [文档](https://iot.mi.com/vela/quickapp/zh/features/network/uploadtask.html)

**系统能力**：
- `@system.network`：网络状态（subscribe/unsubscribe/getType） [文档](https://iot.mi.com/vela/quickapp/zh/features/system/network.html)
- `@system.vibrator`：振动 [文档](https://iot.mi.com/vela/quickapp/zh/features/system/vibrator.html)
- `@system.brightness`：屏幕亮度（getValue/setValue/getMode/setMode） [文档](https://iot.mi.com/vela/quickapp/zh/features/system/brightness.html)
- `@system.record`：录音 [文档](https://iot.mi.com/vela/quickapp/zh/features/system/record.html)
- `@system.geolocation`：地理位置（需权限 hapjs.permission.LOCATION） [文档](https://iot.mi.com/vela/quickapp/zh/features/system/geolocation.html)
- `@system.sensor`：传感器（加速度、陀螺仪、心率等） [文档](https://iot.mi.com/vela/quickapp/zh/features/system/sensor.html)
- `@system.event`：系统事件 [文档](https://iot.mi.com/vela/quickapp/zh/features/system/event.html)
- `@system.battery`：电池信息 [文档](https://iot.mi.com/vela/quickapp/zh/features/system/battery.html)
- `@system.volume`：音量控制 [文档](https://iot.mi.com/vela/quickapp/zh/features/system/volume.html)
- `@system.zip`：压缩解压 [文档](https://iot.mi.com/vela/quickapp/zh/features/system/zip.html)
- `@system.alarm`：闹钟（setAlarm/getAlarm/cancelAlarm） [文档](https://iot.mi.com/vela/quickapp/zh/features/system/alarm.html)

**安全**：
- `@system.crypto`：加密（rsa/aes/digest/hmac 等） [文档](https://iot.mi.com/vela/quickapp/zh/features/security/crypto.html)
- `@system.secureelement`：安全元件 [文档](https://iot.mi.com/vela/quickapp/zh/features/security/secureelement.html)

**其他**：
- `@system.file`：文件操作（readText/writeText/list/get/delete/move/copy/mkdir/rmdir） [文档](https://iot.mi.com/vela/quickapp/zh/features/data/file.html)
- `@system.protobuf`：Protobuf 编解码 [文档](https://iot.mi.com/vela/quickapp/zh/features/other/protobuf.html)
- `@system.serviceclient`：服务客户端 [文档](https://iot.mi.com/vela/quickapp/zh/features/other/serviceclient.html)

### 通用错误码
- 200：系统通用错误
- 201：用户拒绝
- 202：参数错误
- 203：功能不支持
- 204：请求超时
- 300：I/O 错误

## 文件存储分区

| 分区 | URI | 读写 | 说明 |
|------|-----|------|------|
| 应用资源 | /path | 只读 | 应用内置资源 |
| Cache | internal://cache/path | 读写 | 缓存文件，可能被系统清理 |
| Files | internal://files/path | 读写 | 永久小文件 |
| Mass | internal://mass/path | 读写 | 大文件，不保证可用 |
| Temp | internal://tmp/path | 只读 | 临时文件，应用重启后失效 |

## 多屏适配

- 使用 `config.designWidth` 设置设计基准宽度
- px 单位会根据实际屏幕宽度自动缩放
- 转换公式：`设计稿1px / 设计稿宽度 = 框架样式1px / designWidth`
- 支持 media query 进行条件样式

## 国际化（i18n）

在 `src/i18n/` 目录下定义 JSON 资源文件：
- 文件命名优先级：`zh-CN.json` > `zh.json` > `defaults.json`
- 支持基础文本、命名插值 `{msg}`、列表插值 `{0}`、单复数 `car | cars`

页面中使用：
```html
<text>{{ $t('message.hello') }}</text>
<text>{{ $t('message.greeting', { name: '小明' }) }}</text>
<text>{{ $tc('message.car', 2) }}</text>
```

```javascript
// script 中
this.$t('message.hello')
this.$tc('message.apple', 2, { count: 6 })
```

语言变化监听：
```javascript
onConfigurationChanged(event) {
  if (event.type === 'locale') {
    console.log('语言已切换')
  }
}
```

## 后台运行

在 manifest.json 的 `config.background.features` 中声明需要后台运行的接口：
```json
{
  "config": {
    "background": {
      "features": ["system.audio", "system.request", "system.geolocation"]
    }
  }
}
```
建议将后台运行逻辑放在 `app.ux` 中，避免页面销毁影响。

## 动态组件

使用 `<component>` 元素的 `is` 属性动态切换组件：
```html
<import src="./part1.ux" name="part1"></import>
<import src="./part2.ux" name="part2"></import>
<template>
  <div>
    <component is="{{'part' + status}}"></component>
  </div>
</template>
```

## 动画样式

### transform
```css
div {
  transform: translate(10px, 20px) rotate(45deg) scale(1.5);
  transform-origin: 50% 50%;
}
```
支持：translate/translateX/translateY、scale/scaleX/scaleY、rotate

### animation + @keyframes
```css
.box {
  animation-name: fadeIn;
  animation-duration: 1s;
  animation-timing-function: ease;
  animation-iteration-count: infinite;
  animation-delay: 0s;
}
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}
```

### transition
```css
.box {
  transition-property: width, background-color;
  transition-duration: 0.3s;
  transition-timing-function: ease-in-out;
  transition-delay: 0s;
}
```

## Media Query 媒体查询

根据设备特征条件应用样式，单位为 dp（设备独立像素）：
```css
@media (shape: circle) {
  .box { border-radius: 50%; }
}
@media (device-type: watch) and (min-width: 200) {
  .box { width: 100%; }
}
@media (shape: circle) or (shape: pill-shaped) {
  .box { padding: 10px; }
}
```

支持的媒体特性：
- `shape`：circle / rect / pill-shaped
- `device-type`：watch / band / smartspeaker
- `width` / `min-width` / `max-width`（dp单位，不带单位书写）
- `height` / `min-height` / `max-height`
- `aspect-ratio` / `min-aspect-ratio` / `max-aspect-ratio`

逻辑操作符：`and` / `not` / `only` / `or` / `,`（逗号等同or）/ `<=` / `>=`

也支持 `@import` 方式：
```css
@import './circle.css' (shape: circle);
```

常见设备 dp 参考：
- Xiaomi Watch S1 Pro/S5：480×480px, DPR=2, 宽=240dp
- Xiaomi Watch S3/S4/H1：466×466px, DPR=2, 宽=233dp
- REDMI Watch 5：432×514px, DPR=2, 宽=216dp
- 小米手环9：192×490px, DPR=2, 宽=96dp

## 条件编译

基于设备特性在编译时选择性包含代码，支持 ux/js/css 文件：
```html
<!-- template 中 -->
<!-- if true: process.env.SHAPE === 'CIRCLE' -->
<div class="circle-layout"></div>
<!-- endif -->

<!-- script 中 -->
// if true: process.env.SHAPE === 'RECT'
console.log('矩形屏幕')
// endif
```

需安装 `conditional-compilation-webpack-plugin` 和 `cross-env`，在 package.json 中配置编译脚本：
```json
{
  "scripts": {
    "build:circle": "cross-env DEVICE_TYPE=WATCH SHAPE=CIRCLE aiot build",
    "build:rect": "cross-env DEVICE_TYPE=WATCH SHAPE=RECT aiot build"
  }
}
```

## hap 链接

router 支持 `hap://` 协议打开其他 JS 应用：
```
hap://app/<package>/[path][?key=value]
```
示例：`hap://app/com.example.demo/Detail?id=1`

## 颜色配置

支持的颜色格式：
- `#rgb` / `#rrggbb` / `#rgba` / `#rrggbbaa`
- `rgb(255, 0, 0)` / `rgba(255, 0, 0, 0.5)`
- `transparent`
- CSS 颜色名：`red`, `blue`, `black`, `white` 等

## 通用组件方法

通过 `this.$element('id')` 获取 DOM 节点后可调用：

### getBoundingClientRect(OBJECT)
获取元素位置和尺寸（需在 onShow 之后调用）：
```javascript
this.$element('box').getBoundingClientRect({
  success(data) {
    // data: { left, right, top, bottom, width, height }
  }
})
```

### focus(OBJECT)
```javascript
this.$element('input1').focus({ focus: true })
```

## 完整页面示例

```html
<template>
  <div class="page">
    <text class="title">{{title}}</text>
    <div class="list-wrap">
      <div for="{{items}}" tid="id" class="item" onclick="onItemClick($item)">
        <image src="{{$item.icon}}" class="icon" />
        <text class="name">{{$item.name}}</text>
      </div>
    </div>
    <div if="{{items.length === 0}}" class="empty">
      <text>暂无数据</text>
    </div>
  </div>
</template>

<style>
  .page {
    flex-direction: column;
    padding: 20px;
  }
  .title {
    font-size: 36px;
    font-weight: bold;
    margin-bottom: 20px;
  }
  .list-wrap {
    flex-direction: column;
  }
  .item {
    flex-direction: row;
    align-items: center;
    padding: 15px 0;
    border-bottom: 1px solid #eeeeee;
  }
  .icon {
    width: 60px;
    height: 60px;
    margin-right: 15px;
  }
  .name {
    font-size: 28px;
    color: #333333;
  }
  .empty {
    justify-content: center;
    align-items: center;
    margin-top: 100px;
  }
</style>

<script>
  import router from '@system.router'
  import storage from '@system.storage'

  export default {
    private: {
      title: '我的应用',
      items: []
    },
    onInit() {
      this.loadData()
    },
    loadData() {
      storage.get({
        key: 'items',
        success: (data) => {
          if (data) {
            this.items = JSON.parse(data)
          }
        }
      })
    },
    onItemClick(item) {
      router.push({
        uri: '/pages/detail',
        params: { id: item.id }
      })
    }
  }
</script>
```

## 开发注意事项与最佳实践

### 内存优化（重要）

手表设备内存有限，必须严格控制内存占用：

1. **与 UI 无关的数据不要放在 ViewModel 中**，避免不必要的数据代理开销：
```javascript
const someObj = { a: 1 }  // ✅ 放在 export default 外部
export default {
  private: {
    someObj: { a: 1 }     // ❌ 不需要绑定到UI的数据不要放这里
  }
}
```

2. **数据更新时原地修改，避免重新赋值整个对象/数组**：
```javascript
// ❌ this.list = [{ name: 'bb' }]
// ✅ this.list[0].name = 'bb'
```

3. **使用 `static` 属性标记不会变化的节点**，减少动态节点内存：
```html
<text static>{{title}}</text>
<image static src="/common/logo.png"/>
<!-- 属性级静态标记 -->
<text if.static="{{show}}" class.static="{{cls}}">内容</text>
<!-- block 级静态标记：内部所有节点只渲染一次 -->
<block static>
  <text>{{fixedTitle}}</text>
</block>
```

4. **页面销毁时清除定时器**：
```javascript
onDestroy() {
  if (this.timer) clearTimeout(this.timer)
}
```

5. **读取的文件/存储数据用完后及时置 null 释放**

6. **调用 `global.runGC()` 手动触发垃圾回收**（不要频繁调用）

7. **不要将页面属性和方法缓存到全局**，否则页面销毁后无法释放内存

### 启动性能优化

1. **避免 setTimeout 延迟跳转**，用 async/await 或回调直接跳转：
```javascript
// ✅ 推荐
async onInit() {
  const data = await this.getData()
  if (!data) router.push({ uri: '/pages/home' })
}
```

2. **logo 页避免 HTTP 请求**，防止弱网阻塞页面跳转

3. **首页数据做本地缓存**，进入时先读缓存展示，同时异步请求更新

4. **UI 先行**，不要等数据全部加载完才渲染页面

5. **减少 console 打印**，特别是长日志和 JSON 对象，release 包用 TerserPlugin 过滤 `console.debug`

### 渲染性能优化

1. **list 超过 10 条使用分页渲染**，避免一次性渲染大量数据
2. **长文案分块渲染**，监听 scroll 事件触底加载下一段
3. **Swiper 多图使用懒加载**，只保留 3 个子组件动态更新数据
4. **减少 border-radius 与背景图同时使用**
5. **图片尺寸与组件尺寸保持一致**，避免运行时缩放
6. **减少标签嵌套层级和动态样式修改**

### 圆形屏幕安全区域

手表屏幕多为圆形，四角为不可见区域，页面布局必须留出安全边距，避免内容被圆弧裁切：

- **上下安全边距**：约屏幕高度的 10%（如 480px 屏幕留 48-50px）
- **左右安全边距**：约屏幕宽度的 7-8%（如 480px 屏幕留 34-38px）
- 内容超出一屏时，使用 `<scroll scroll-y="true">` 包裹，确保可滚动

推荐写法：
```html
<scroll class="page" scroll-y="true">
  <div class="container">
    <!-- 页面内容 -->
  </div>
</scroll>
```
```css
.page {
  width: 100%;
  height: 100%;
}
.container {
  flex-direction: column;
  padding: 50px 36px;
}
```

对于方形屏幕（如 REDMI Watch 5），安全边距可适当减小（上下 20px，左右 16px）。可通过 media query 区分：
```css
@media (shape: circle) {
  .container { padding: 50px 36px; }
}
@media (shape: rect) {
  .container { padding: 20px 16px; }
}
```

### 图片使用规范

- 尽量使用本地图片，避免在线大图
- 在线图片不超过 200KB，尺寸不超过屏幕尺寸
- 首次加载大图时增加 loading，下载后缓存到 `internal://files/`
- 优先使用 PNG8 格式降低体积
- 使用 tinypng.com 等工具压缩图片

### 代码规范

1. `app.ux` 中的代码必须写在 `<script>` 标签内
2. `template` 只能有一个根节点
3. 角度相关 CSS 属性必须带单位：`rotate: 360deg`
4. `list-item` 中谨慎使用 `if/else/show`，保证所有 list-item 结构一致
5. `image` 的 `src` 不要用变量拼接路径（如 `src="/common/{{type}}"`），直接用完整变量 `src="{{imgPath}}"`
6. `input` 等无子元素的标签必须自闭合（如 `<input />`），遵循 XML 规范

### 异常处理

1. 网络异常时给用户提示
2. 数据异常（空数据/接口错误）要有兜底处理
3. 添加 try-catch 捕获 JS 异常
4. 按钮防重复点击，点击后加 loading 防止多次请求
5. `onShow` 中的 fetch 请求注意：息屏亮屏会重新触发 onShow

### 包体积优化

1. 去除未使用的三方依赖，选用轻量替代
2. 公共方法挂载到 `global` 上，避免多页面重复 import
3. 去除未使用的 CSS 和 JS 代码
4. 尽可能减少页面数量

### 通信（interconnect）注意

- 使用 `diagnosis()` 方法判断连接状态，不要轮询 `getApkStatus()`
- 多条数据直接循环发送，不要加 setTimeout 延迟
- 手表 rpk 和手机 app 必须使用相同证书签名

### 异步接口 Promise 封装

推荐将异步回调接口统一封装为 Promise，方便 async/await 使用：
```javascript
function promisify(fn) {
  return (opts = {}) => new Promise((resolve, reject) => {
    fn({
      ...opts,
      success: data => resolve(data),
      fail: (data, code) => reject({ data, code })
    })
  })
}

// 使用
import storage from '@system.storage'
const getItem = promisify(storage.get)
const data = await getItem({ key: 'myKey' })
```
