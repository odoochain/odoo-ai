from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import os

# 创建测试PDF
def test_chinese_fonts():
    pdf_path = os.path.join(os.path.expanduser("~"), "reportlab_test.pdf")
    c = canvas.Canvas(pdf_path)
    
    # 尝试使用已注册的字体
    fonts_to_test = ['simhei', 'simsun', 'simkai', 'msyh']
    y_position = 800
    
    c.setFont("Helvetica", 12)
    c.drawString(100, y_position, "ReportLab Chinese Font Test")
    y_position -= 20
    
    for font in fonts_to_test:
        try:
            c.setFont(font, 12)
            c.drawString(100, y_position, f"{font}: 这是中文测试文本 (This is Chinese text)")
            print(f"使用字体 {font} 添加了文本")
            y_position -= 20
        except Exception as e:
            print(f"使用字体 {font} 失败: {str(e)}")
    
    c.save()
    print(f"测试PDF已保存到: {pdf_path}")

if __name__ == "__main__":
    test_chinese_fonts()
