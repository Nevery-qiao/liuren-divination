from urllib.parse import urlencode
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
from datetime import datetime
import time

def parse_time(time_str: str) -> tuple:
    """
    解析时间字符串
    
    Args:
        time_str: 时间字符串，支持以下格式：
                 - HH:MM (例如: 06:45)
                 - YYYY-MM-DD-HH:MM (例如: 2024-12-02-06:45)
    
    Returns:
        tuple: (日期字符串, 时间字符串)
    """
    try:
        # 尝试解析完整日期时间格式
        if '-' in time_str:
            dt = datetime.strptime(time_str, '%Y-%m-%d-%H:%M')
            return (
                f"{dt.year}年{dt.month}月{dt.day}日",
                f"{dt.hour:02d}:{dt.minute:02d}"
            )
        # 只有时间的情况
        else:
            hour, minute = map(int, time_str.split(':'))
            return ("2024年11月2日", f"{hour:02d}:{minute:02d}")
    except ValueError as e:
        raise ValueError("时间格式错误，请使用 HH:MM 或 YYYY-MM-DD-HH:MM 格式")

def get_shi_index(time_str: str) -> int:
    """计算时辰索引"""
    # 如果是完整日期时间，只取时间部分
    if '-' in time_str:
        time_str = time_str.split('-')[-1]
    
    hour, minute = map(int, time_str.split(':'))
    
    if hour >= 23 or hour < 1:
        return 1
    elif hour >= 21:
        return 12
    else:
        total_minutes = hour * 60 + minute
        shi_index = ((total_minutes - 60) // 120) + 2
    
    return shi_index

def build_url(number: str, time_str: str) -> str:
    """构建六壬排盘URL"""
    base_url = "http://demo1.w258.cn/2024/xlr/#/pages/pan/pana"
    shi = get_shi_index(time_str)
    
    # 解析日期和时间
    ydate, ytime = parse_time(time_str)
    
    params = {
        "ri": str(number),
        "shi": str(shi),
        "ydate": ydate,
        "ytime": ytime,
        "lyear": "甲辰",
        "lmonth": "甲戌",
        "lday": "庚午",
        "lshi": "丁亥"
    }
    
    return f"{base_url}?{urlencode(params)}"

def get_gong_info(url: str) -> dict:
    """从网页获取宫位信息"""
    try:
        # 配置 Chrome 选项
        chrome_options = Options()
        chrome_options.add_argument('--headless')  # 无头模式
        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--disable-dev-shm-usage')
        
        # 初始化 WebDriver
        driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), 
                                options=chrome_options)
        
        # 访问URL
        driver.get(url)
        
        # 等待页面加载完成（等待 .grid 元素出现）
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CLASS_NAME, "grid"))
        )
        
        # 获取渲染后的页面内容
        soup = BeautifulSoup(driver.page_source, 'html.parser')
        
        # 1. 获取阳历时间
        yangli = soup.select_one('.yangli')
        time_yangli = ' '.join([span.text for span in yangli.find_all('span')]) if yangli else ''
        
        # 2. 获取阴历时间和数字
        nongli = soup.select_one('.nongli')
        if nongli:
            spans = nongli.find_all('span')
            time_nongli = ''.join([span.text for span in spans if '数' not in span.text])
            number = next((span.text.replace('数', '').strip() for span in spans if '数' in span.text), '')
        
        # 3. 获取宫位信息
        gong_positions = []
        gong_order = ['大安', '留连', '速喜', '赤口', '小吉', '空亡']
        grid = soup.select_one('.grid')
        
        if grid:
            items = grid.find_all(class_='item')
            for item in items:
                gong_info = {
                    "宫位": item.select_one('.gong').text if item.select_one('.gong') else '',
                    "六神": item.select_one('.shen').text if item.select_one('.shen') else '',
                    "六亲": item.select_one('.qin').text if item.select_one('.qin') else '',
                    "星": item.select_one('.xing').text if item.select_one('.xing') else '',
                    "支": item.select_one('.zhi').text if item.select_one('.zhi') else '',
                    "数字": item.select_one('.ri span').text if item.select_one('.ri span') else '0',
                    "时宫": bool(item.select_one('.shi'))
                }
                gong_positions.append(gong_info)
        
        # 按固定顺序排序宫位
        sorted_positions = sorted(gong_positions, 
                                key=lambda x: gong_order.index(x['宫位']) if x['宫位'] in gong_order else 999)
        
        result = {
            'time_yangli': time_yangli.replace('日期：', '').strip(),
            'time_nongli': [
                {'time_nongli': time_nongli},
                {'number': number.strip()}
            ],
            'gong_positions': sorted_positions,
            'url': url
        }
        
        # 关闭浏览器
        driver.quit()
        
        return result
        
    except Exception as e:
        if 'driver' in locals():
            driver.quit()
        return {
            'error': str(e),
            'url': url
        }

def liuren_divination(number: str, time_str: str) -> dict:
    """
    六壬神课占卜函数 - 扣子插件接口
    """
    try:
        url = build_url(number, time_str)
        result = get_gong_info(url)
        
        gong_list = []
        for gong in result['gong_positions']:
            gong_list.append({
                "position": gong['宫位'],
                "god": gong['六神'],
                "relation": gong['六亲'],
                "star": gong['星'],
                "branch": gong['支'],
                "number": gong['数字'],
                "is_time_palace": 1 if gong['时宫'] else 0  # 使用 1/0 代替 true/false
            })
        
        return {
            "code": 200,
            "data": {
                "yangli_time": result['time_yangli'],
                "nongli_time": result['time_nongli'][0]['time_nongli'],
                "divination_number": result['time_nongli'][1]['number'],
                "gong_info": gong_list,
                "source_url": result['url']
            },
            "message": "占卜成功"
        }
        
    except Exception as e:
        return {
            "code": 500,
            "data": None,
            "message": f"占卜失败: {str(e)}"
        }

# 扣子插件入口函数
def handle_event(event):
    """
    扣子插件入口函数
    
    Args:
        event: 扣子事件对象，包含用户输入
        
    Returns:
        dict: 返回给扣子的结果
    """
    try:
        # 解析用户输入
        # 支持两种格式:
        # 1. "数字 HH:MM" (例如: "1234 05:45")
        # 2. "数字 YYYY-MM-DD-HH:MM" (例如: "1234 2024-12-02-06:45")
        parts = event['content'].strip().split()
        if len(parts) != 2:
            raise ValueError("输入格式错误")
            
        number, time_str = parts
        
        # 调用占卜函数
        result = liuren_divination(number, time_str)
        
        return result
        
    except Exception as e:
        return {
            "code": 400,
            "data": None,
            "message": f"输入格式错误，请使用以下格式之一：\n1. 数字 HH:MM（例如：1234 05:45）\n2. 数字 YYYY-MM-DD-HH:MM（例如：1234 2024-12-02-06:45）"
        }

if __name__ == "__main__":
    # 测试用例
    test_cases = [
        {"content": "1234 05:45"},  # 只有时间
        {"content": "1234 2024-12-02-06:45"}  # 完整日期时间
    ]
    
    print("=== 测试结果 ===")
    for test_event in test_cases:
        print(f"\n测试输入: {test_event['content']}")
        result = handle_event(test_event)
        print("结果:", result)
