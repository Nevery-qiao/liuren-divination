# 六壬神课占卜工具

这是一个六壬神课占卜的 Python 程序，可用于扣子插件。

## 功能特点

- 支持自定义日期时间占卜
- 自动获取宫位信息
- 支持多种时间格式输入

## 安装依赖

```bash
pip install selenium beautifulsoup4 webdriver-manager
```

## 使用方法

### 直接运行测试

```bash
python divination.py
```

### 作为扣子插件使用

支持两种输入格式：
1. `数字 HH:MM`（例如：1234 05:45）
2. `数字 YYYY-MM-DD-HH:MM`（例如：1234 2024-12-02-06:45）

## 返回结果

返回 JSON 格式的占卜结果，包含：
- 阳历时间
- 阴历时间
- 占卜数字
- 宫位信息（大安、留连、速喜、赤口、小吉、空亡）

## 注意事项

- 需要 Chrome 浏览器环境
- 首次运行会自动下载 ChromeDriver

## 许可证

MIT License
