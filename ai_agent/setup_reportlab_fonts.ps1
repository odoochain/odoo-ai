# ReportLab中文字体配置脚本 (PowerShell版)
Write-Host "正在配置ReportLab中文字体支持..." -ForegroundColor Green

# 检查Python是否可用
try {
    $pythonVersion = python --version
    Write-Host "检测到Python: $pythonVersion" -ForegroundColor Cyan
} catch {
    Write-Host "未检测到Python，请确保Python已安装并添加到PATH中" -ForegroundColor Red
    exit 1
}

# 检查ReportLab是否已安装
try {
    python -c "import reportlab; print('ReportLab版本:', reportlab.__version__)" 
} catch {
    Write-Host "未检测到ReportLab，正在尝试安装..." -ForegroundColor Yellow
    python -m pip install reportlab
}

# 创建字体配置脚本
$fontConfigScript = @'
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
'@

# 将脚本保存到临时文件
$fontConfigPath = ".\setup_reportlab_fonts.py"
$fontConfigScript | Out-File -FilePath $fontConfigPath -Encoding utf8

# 运行字体配置脚本
Write-Host "正在配置ReportLab中文字体..." -ForegroundColor Cyan
python $fontConfigPath

# 创建示例脚本以验证字体配置
$testScript = @'
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
'@

$testScriptPath = ".\test_reportlab_fonts.py"
$testScript | Out-File -FilePath $testScriptPath -Encoding utf8

Write-Host "ReportLab中文字体配置完成" -ForegroundColor Green
Write-Host "是否要立即测试中文字体? (Y/N)" -ForegroundColor Cyan
$testChoice = Read-Host

if ($testChoice -eq "Y" -or $testChoice -eq "y") {
    Write-Host "正在测试中文字体..." -ForegroundColor Cyan
    python $testScriptPath
    Write-Host "测试PDF已保存到用户主目录" -ForegroundColor Green
} else {
    Write-Host "可以稍后运行以下命令测试中文字体: python $testScriptPath" -ForegroundColor Cyan
}

Read-Host "按Enter键退出"