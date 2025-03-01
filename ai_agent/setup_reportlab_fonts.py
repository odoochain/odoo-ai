import os
import sys
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

def setup_chinese_fonts():
    # Windows系统字体路径
    windows_font_path = os.path.join(os.environ['SYSTEMROOT'], 'Fonts')
    
    # 常见中文字体列表
    chinese_fonts = [
        ('simhei', 'simhei.ttf', '黑体'),
        ('simsun', 'simsun.ttc', '宋体'),
        ('simkai', 'simkai.ttf', '楷体'),
        ('msyh', 'msyh.ttc', '微软雅黑'),
        ('msyhbd', 'msyhbd.ttc', '微软雅黑粗体'),
    ]
    
    registered_fonts = []
    
    # 注册字体
    for font_name, font_file, font_desc in chinese_fonts:
        font_path = os.path.join(windows_font_path, font_file)
        if os.path.exists(font_path):
            try:
                pdfmetrics.registerFont(TTFont(font_name, font_path))
                registered_fonts.append((font_name, font_desc))
                print(f"已注册字体: {font_desc} ({font_name})")
            except Exception as e:
                print(f"注册字体 {font_desc} 失败: {str(e)}")
    
    if registered_fonts:
        print("\n成功注册以下中文字体:")
        for font_name, font_desc in registered_fonts:
            print(f"- {font_desc} ({font_name})")
        print("\n可以在ReportLab中使用这些字体名称")
    else:
        print("未能注册任何中文字体，可能需要手动配置")

if __name__ == "__main__":
    setup_chinese_fonts()
