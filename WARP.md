# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project overview

Python utility for 六壬神课占卜. Given a numeric seed and a time, it builds a URL to an external site, drives headless Chrome via Selenium, parses the rendered HTML with BeautifulSoup, and returns a structured JSON payload. Includes a `handle_event` entrypoint for 扣子插件.

## Commands

- Install runtime dependencies (no virtualenv or lockfile in repo):
  - pip install selenium beautifulsoup4 webdriver-manager
- Run the built-in sample cases:
  - python divination.py
- Call the main function directly (example):
  - python -c "from divination import liuren_divination; import json; print(json.dumps(liuren_divination('1234','05:45'), ensure_ascii=False, indent=2))"
- Tests and linting:
  - No test suite or linter is configured in this repo.

## Architecture and structure

- Single module: `divination.py`
  - parse_time(time_str): Accepts "HH:MM" or "YYYY-MM-DD-HH:MM"; returns Chinese-formatted date and time strings. If only time is given, uses a hardcoded date.
  - get_shi_index(time_str): Maps clock time to a 六壬时辰索引 (1–12) with special handling for 23:00–00:59.
  - build_url(number, time_str): Constructs `http://demo1.w258.cn/2024/xlr/#/pages/pan/pana` with query params: 数字、阳历日期/时间以及固定的农历占位字段。
  - get_gong_info(url): Launches headless Chrome (webdriver-manager auto-installs chromedriver), waits for `.grid`, then parses DOM with selectors:
    - `.yangli` for 阳历时间; `.nongli` for 阴历与“数”；`.grid .item` for 6 宫位条目; sub-elements: `.gong`, `.shen`, `.qin`, `.xing`, `.zhi`, `.ri span`, `.shi`.
    - Sorts positions by fixed order: [大安, 留连, 速喜, 赤口, 小吉, 空亡].
  - liuren_divination(number, time_str): Orchestrates URL build + scrape, maps fields to plugin-friendly JSON with keys: `yangli_time`, `nongli_time`, `divination_number`, `gong_info[]`, `source_url`.
  - handle_event(event): Parses `event['content']` as either "数字 HH:MM" or "数字 YYYY-MM-DD-HH:MM", then calls `liuren_divination` and returns a `{code, data, message}` payload. `__main__` runs two sample cases.

## Data contracts

- Input formats:
  - "数字 HH:MM" (e.g., `1234 05:45`)
  - "数字 YYYY-MM-DD-HH:MM" (e.g., `1234 2024-12-02-06:45`)
- Output schema (success):
  - { code: 200, data: { yangli_time, nongli_time, divination_number, gong_info: [ { position, god, relation, star, branch, number, is_time_palace } ], source_url }, message }
- Error handling:
  - get_gong_info returns `{error, url}` on scrape failure; callers wrap into `{code: 500, ...}`. `handle_event` returns `{code: 400, ...}` on bad input.

## Runtime notes

- Requires Google Chrome installed; `webdriver_manager` will download a matching chromedriver on first run (network access needed). Headless mode is enabled by default.
- Strong coupling to external page structure; changes to class names or layout on `demo1.w258.cn` will break parsing.
- The default date used when only time is provided is hardcoded in `parse_time`; adjust if you need current date semantics.

## README highlights

- Dependencies: `selenium`, `beautifulsoup4`, `webdriver-manager`.
- Usage: `python divination.py` or integrate via the plugin entry `handle_event`.
- Chrome environment required; first run downloads ChromeDriver automatically.
