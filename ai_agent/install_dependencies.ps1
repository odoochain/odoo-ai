# Odoo AI Agent模块依赖安装脚本 (PowerShell版)
Write-Host "正在为Odoo AI Agent模块安装依赖..." -ForegroundColor Green

# 检查执行策略
$currentPolicy = Get-ExecutionPolicy
if ($currentPolicy -eq "Restricted") {
    Write-Host "当前PowerShell执行策略为Restricted，脚本可能无法运行" -ForegroundColor Yellow
    Write-Host "建议临时设置执行策略为Bypass: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass" -ForegroundColor Yellow
    $setPolicyChoice = Read-Host "是否临时设置执行策略为Bypass? (Y/N)"
    if ($setPolicyChoice -eq "Y" -or $setPolicyChoice -eq "y") {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    }
}

# 检查micromamba是否已安装，如果没有则安装
try {
    $micromambaVersion = micromamba --version
    Write-Host "检测到micromamba版本: $micromambaVersion" -ForegroundColor Green
    
    # 检测micromamba安装方式
    $micromambaPath = (Get-Command micromamba).Source
    if ($micromambaPath -like "*scoop*") {
        Write-Host "检测到通过Scoop安装的micromamba: $micromambaPath" -ForegroundColor Cyan
        $isScoopInstall = $true
    } else {
        Write-Host "检测到标准安装的micromamba: $micromambaPath" -ForegroundColor Cyan
        $isScoopInstall = $false
    }
} catch {
    Write-Host "未检测到micromamba，将尝试安装..." -ForegroundColor Yellow
    
    # 检查是否已安装Scoop
    try {
        $scoopVersion = scoop --version
        Write-Host "检测到Scoop版本: $scoopVersion" -ForegroundColor Green
        $hasScoopInstalled = $true
    } catch {
        Write-Host "未检测到Scoop，将先安装Scoop..." -ForegroundColor Yellow
        $hasScoopInstalled = $false
    }
    
    # 如果没有Scoop，先安装Scoop
    if (-not $hasScoopInstalled) {
        try {
            Write-Host "正在安装Scoop..." -ForegroundColor Cyan
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
            
            # 检查安装结果
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                Write-Host "Scoop安装成功" -ForegroundColor Green
            } else {
                Write-Host "Scoop安装失败，请手动安装Scoop后再运行此脚本" -ForegroundColor Red
                exit 1
            }
        } catch {
            Write-Host "Scoop安装失败: $_" -ForegroundColor Red
            Write-Host "请手动安装Scoop后再运行此脚本" -ForegroundColor Red
            exit 1
        }
    }
    
    # 使用Scoop安装micromamba
    try {
        Write-Host "正在使用Scoop安装micromamba..." -ForegroundColor Cyan
        
        # 添加必要的bucket
        scoop bucket add main
        
        # 尝试安装micromamba-cn（中国镜像版本）
        $installChoice = Read-Host "是否安装micromamba中国镜像版本(推荐)? (Y/N)"
        if ($installChoice -eq "Y" -or $installChoice -eq "y" -or [string]::IsNullOrEmpty($installChoice)) {
            scoop install micromamba-cn
            $isScoopInstall = $true
        } else {
            scoop install micromamba
            $isScoopInstall = $true
        }
        
        # 验证安装
        $micromambaVersion = micromamba --version
        Write-Host "micromamba安装成功，版本: $micromambaVersion" -ForegroundColor Green
    } catch {
        Write-Host "micromamba安装失败: $_" -ForegroundColor Red
        Write-Host "请手动安装micromamba后再运行此脚本" -ForegroundColor Red
        exit 1
    }
}

# 初始化micromamba环境
Write-Host "正在初始化micromamba环境..." -ForegroundColor Cyan
try {
    # 根据安装方式选择初始化路径
    if ($isScoopInstall) {
        # 检测Scoop安装的micromamba实际路径
        $scoopBasePath = $null
        
        # 尝试从环境变量获取Scoop路径
        if ($env:SCOOP) {
            $scoopBasePath = $env:SCOOP
            Write-Host "从环境变量检测到Scoop路径: $scoopBasePath" -ForegroundColor Cyan
        }
        
        # 检查常见的Scoop安装位置
        $possibleScoopPaths = @(
            "$env:USERPROFILE\scoop",
            "$env:USERPROFILE\.scoop",
            "D:\scoop",
            "D:\Applications\scoop",
            "D:\tools\scoop",
            "D:\.scoop"
        )
        
        foreach ($path in $possibleScoopPaths) {
            if (Test-Path $path) {
                $scoopBasePath = $path
                Write-Host "检测到Scoop安装路径: $scoopBasePath" -ForegroundColor Cyan
                break
            }
        }
        # 如果找到Scoop路径，尝试确定micromamba根目录
        if ($scoopBasePath) {
            # 检查是否安装了micromamba-cn版本
            $micromambaCnPath = "$scoopBasePath\apps\micromamba-cn\current"
            $micromambaPath = "$scoopBasePath\apps\micromamba\current"
            
            if (Test-Path $micromambaCnPath) {
                Write-Host "检测到micromamba-cn版本" -ForegroundColor Cyan
                $micromambaAppPath = $micromambaCnPath
            } elseif (Test-Path $micromambaPath) {
                Write-Host "检测到标准micromamba版本" -ForegroundColor Cyan
                $micromambaAppPath = $micromambaPath
            } else {
                Write-Host "在Scoop路径中未找到micromamba或micromamba-cn安装目录" -ForegroundColor Yellow
                $micromambaAppPath = $null
            }
            
            # 如果找到了micromamba应用路径，尝试确定根目录
            if ($micromambaAppPath) {
                # 尝试找到配置文件来确定根目录
                $micromambaConfigPath = "$micromambaAppPath\.condarc"
                if (Test-Path $micromambaConfigPath) {
                    $configContent = Get-Content $micromambaConfigPath -ErrorAction SilentlyContinue
                    foreach ($line in $configContent) {
                        if ($line -match "root_prefix:\s*(.+)") {
                            $micromambaRoot = $matches[1]
                            Write-Host "从配置文件检测到micromamba根目录: $micromambaRoot" -ForegroundColor Cyan
                            break
                        }
                    }
                }
                
                # 如果无法从配置确定，尝试其他常见位置
                if (-not $micromambaRoot) {
                    $possibleRootPaths = @(
                        "$micromambaAppPath\envs",
                        "$env:USERPROFILE\.micromamba",
                        "D:\.micromamba",
                        "$env:LOCALAPPDATA\micromamba",
                        "$scoopBasePath\persist\micromamba-cn",
                        "$scoopBasePath\persist\micromamba"
                    )
                    
                    foreach ($path in $possibleRootPaths) {
                        if (Test-Path $path) {
                            $micromambaRoot = $path
                            Write-Host "检测到可能的micromamba根目录: $micromambaRoot" -ForegroundColor Cyan
                            break
                        }
                    }
                    
                    # 如果仍未找到，使用默认位置
                    if (-not $micromambaRoot) {
                        $micromambaRoot = "$micromambaAppPath\envs"
                        Write-Host "使用默认Scoop micromamba路径: $micromambaRoot" -ForegroundColor Cyan
                    }
                }
            } else {
                # 如果未找到应用路径，使用默认位置
                $micromambaRoot = "$scoopBasePath\apps\micromamba-cn\current\envs"
                if (-not (Test-Path $micromambaRoot)) {
                    $micromambaRoot = "$scoopBasePath\apps\micromamba\current\envs"
                }
                Write-Host "使用默认Scoop micromamba路径: $micromambaRoot" -ForegroundColor Cyan
            }
        } else {
            # 如果无法确定Scoop路径，提示用户输入
            Write-Host "无法自动检测Scoop安装路径" -ForegroundColor Yellow
            $userPath = Read-Host "请输入micromamba根目录路径 (默认: $env:USERPROFILE\.micromamba)"
            
            if ([string]::IsNullOrEmpty($userPath)) {
                $micromambaRoot = "$env:USERPROFILE\.micromamba"
            } else {
                $micromambaRoot = $userPath
            }
        }
        
        # 确保目录存在
        if (-not (Test-Path $micromambaRoot)) {
            Write-Host "创建micromamba根目录: $micromambaRoot" -ForegroundColor Cyan
            New-Item -ItemType Directory -Path $micromambaRoot -Force | Out-Null
        }
        
        $initOutput = micromamba shell init -s powershell 
    } else {
        # 标准安装使用默认路径
        $initOutput = micromamba shell init -s powershell
    }
    Write-Host $initOutput -ForegroundColor Gray
    
    # 尝试直接加载hook
    try {
        iex (micromamba shell hook --shell powershell | Out-String)
    } catch {
        Write-Host "直接加载hook失败，尝试其他方式..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "micromamba初始化失败: $_" -ForegroundColor Red
    Write-Host "请检查micromamba是否正确安装" -ForegroundColor Red
    exit 1
}

# 检查hook脚本是否存在并刷新环境变量
# 根据安装方式查找hook脚本
if ($isScoopInstall) {
    $possibleHookPaths = @(
        "$env:USERPROFILE\.micromamba\condabin\micromamba_hook.ps1",
        "$env:USERPROFILE\scoop\apps\micromamba\current\condabin\micromamba_hook.ps1",
        "$env:USERPROFILE\scoop\apps\micromamba-cn\current\condabin\micromamba_hook.ps1",
        "$env:USERPROFILE\scoop\shims\micromamba_hook.ps1",
        "$scoopBasePath\apps\micromamba-cn\current\condabin\micromamba_hook.ps1",
        "$scoopBasePath\apps\micromamba\current\condabin\micromamba_hook.ps1",
        "D:\scoop\apps\micromamba-cn\current\condabin\micromamba_hook.ps1",
        "D:\scoop\apps\micromamba\current\condabin\micromamba_hook.ps1"
    )
} else {
    $possibleHookPaths = @(
        "$env:USERPROFILE\micromamba\condabin\micromamba_hook.ps1"
    )
}

$hookFound = $false
foreach ($hookPath in $possibleHookPaths) {
    if (Test-Path $hookPath) {
        Write-Host "找到hook脚本: $hookPath" -ForegroundColor Cyan
        Write-Host "正在加载micromamba环境变量..." -ForegroundColor Cyan
        try {
            & $hookPath
            $hookFound = $true
            break
        } catch {
            Write-Host "加载环境变量脚本失败: $_" -ForegroundColor Yellow
        }
    }
}

if (-not $hookFound) {
    Write-Host "未找到micromamba hook脚本，将尝试继续安装..." -ForegroundColor Yellow
    Write-Host "如果后续步骤失败，请尝试手动初始化micromamba环境" -ForegroundColor Yellow
}

# 检查环境是否已存在
Write-Host "检查环境是否已存在..." -ForegroundColor Cyan
$envExists = micromamba env list | Select-String "odoo-ai-env"

if ($envExists) {
    Write-Host "环境 odoo-ai-env 已存在" -ForegroundColor Yellow
    $choice = Read-Host "是否要更新现有环境? (Y/N)"
    
    if ($choice -eq "Y" -or $choice -eq "y") {
        Write-Host "将更新现有环境..." -ForegroundColor Cyan
        $ENV_NAME = "odoo-ai-env"
    } else {
        $NEW_ENV_NAME = Read-Host "请输入新环境名称 (默认: odoo-ai-env-new)"
        if ([string]::IsNullOrEmpty($NEW_ENV_NAME)) {
            $NEW_ENV_NAME = "odoo-ai-env-new"
        }
        Write-Host "将创建新环境: $NEW_ENV_NAME" -ForegroundColor Cyan
        $ENV_NAME = $NEW_ENV_NAME
    }
} else {
    Write-Host "环境不存在，将创建新环境..." -ForegroundColor Cyan
    $ENV_NAME = "odoo-ai-env"
}

# 创建新环境
Write-Host "正在创建Python环境..." -ForegroundColor Cyan
$maxRetries = 3
$retryCount = 0
$success = $false

while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        micromamba create -n $ENV_NAME python=3.12 -y
        $success = $true
    } catch {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "创建环境失败，正在重试 ($retryCount/$maxRetries)..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        } else {
            Write-Host "创建环境失败: $_" -ForegroundColor Red
            Write-Host "请检查网络连接和micromamba是否正确安装" -ForegroundColor Red
            exit 1
        }
    }
}

# 激活环境
Write-Host "正在激活环境 $ENV_NAME..." -ForegroundColor Cyan
try {
    micromamba activate $ENV_NAME
    # 验证环境是否已激活
    $currentEnv = micromamba info --envs | Select-String "active environment"
    if ($currentEnv -match $ENV_NAME) {
        Write-Host "环境激活成功: $currentEnv" -ForegroundColor Green
    } else {
        Write-Host "环境可能未正确激活，但将继续安装..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "激活环境失败: $_" -ForegroundColor Red
    Write-Host "将尝试继续安装，但可能会失败..." -ForegroundColor Yellow
}

# 安装基础依赖函数
function Install-Dependencies {
    param (
        [string]$message,
        [scriptblock]$installCommand,
        [int]$maxRetries = 3
    )
    
    Write-Host $message -ForegroundColor Cyan
    $retryCount = 0
    $success = $false
    
    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            & $installCommand
            $success = $true
        } catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Host "安装失败，正在重试 ($retryCount/$maxRetries)..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            } else {
                Write-Host "安装失败: $_" -ForegroundColor Red
                Write-Host "将尝试继续安装其他依赖..." -ForegroundColor Yellow
                return $false
            }
        }
    }
    return $true
}

# 安装基础依赖
Install-Dependencies "正在安装基础依赖..." {
    micromamba install -c conda-forge `
        asn1crypto=1.5.1 `
        babel=2.10.3 `
        cbor2=5.6.2 `
        chardet=5.2.0 `
        cryptography=44.0.1 `
        decorator=5.1.1 `
        docutils=0.20.1 `
        freezegun=1.2.1 `
        idna=3.7 `
        jinja2=3.1.2 `
        libsass=0.22.0 `
        lxml=5.2.1 `
        markupsafe=2.1.5 `
        openpyxl=3.1.2 `
        passlib=1.7.4 `
        pillow=10.3.0 `
        polib=1.2.0 `
        psutil=5.9.8 `
        pyopenssl=25.0.0 `
        pypdf2=2.12.1 `
        pyserial=3.5 `
        python-dateutil=2.8.2 `
        python-stdnum=1.19 `
        pytz=2025.1 `
        pyusb=1.3.1 `
        qrcode=7.4.2 `
        reportlab=4.1.0 `
        requests=2.32.3 `
        urllib3=2.2.2 `
        werkzeug=3.0.1 `
        xlrd=2.0.1 `
        xlsxwriter=3.1.9 `
        xlwt=1.3.0 `
        zeep=4.2.1 -y
}

# 安装Windows特定依赖
Install-Dependencies "正在安装Windows特定依赖..." {
    micromamba install -c conda-forge pywin32 -y
}

# 使用pip安装找不到的conda包
Install-Dependencies "正在安装其他依赖..." {
    # 添加 --disable-pip-version-check 参数来避免版本警告
    python -m pip install --disable-pip-version-check lxml-html-clean pydantic==2.10.6 xmltodict==0.13.0 rss_parser==2.1.0 `
        geoip2==5.0.1 num2words==0.5.13 psycopg2==2.9.10 rjsmin==1.2.0 vobject==0.9.9 `
        PyMuPDF==1.23.22 cachetools
    
    # reportlab-renderPM 已经被整合到最新的reportlab中，不再需要单独安装
}

# 安装AI Agent模块特定依赖的部分：
Install-Dependencies "正在安装AI Agent模块特定依赖..." {
    # 先单独安装可能有冲突的包
    Write-Host "正在安装可能有文件冲突的依赖..." -ForegroundColor Yellow
    micromamba install -c conda-forge xorg-libx11 --force-reinstall -y
    
    # 安装其他依赖
    micromamba install -c conda-forge langchain langchain-core unidecode ipython markdown markdownify graphviz -y
    
    # 单独安装faiss-cpu并验证
    Write-Host "正在安装并验证faiss-cpu..." -ForegroundColor Cyan
    micromamba install -c conda-forge faiss-cpu -y
    
    # 验证faiss是否可用
    Write-Host "验证faiss是否可用..." -ForegroundColor Cyan
    python -c "import faiss; print('faiss导入成功，版本:', faiss.__version__)" || Write-Host "faiss导入失败，尝试使用pip安装..." -ForegroundColor Yellow
    
    # 如果导入失败，尝试使用pip安装
    if ($LASTEXITCODE -ne 0) {
        Write-Host "使用pip安装faiss-cpu..." -ForegroundColor Yellow
        python -m pip install --disable-pip-version-check faiss-cpu
        python -c "import faiss; print('faiss导入成功，版本:', faiss.__version__)" || Write-Host "faiss仍然无法导入，请手动检查安装" -ForegroundColor Red
    }
    
    # 安装PyTorch及CUDA依赖
    Write-Host "正在安装PyTorch及CUDA依赖..." -ForegroundColor Cyan
    try {
        micromamba install pytorch "cuda-runtime <12.0.0" -c pytorch -c conda-forge -c nvidia -y
        
        # 验证PyTorch是否可用
        Write-Host "验证PyTorch是否可用..." -ForegroundColor Cyan
        python -c "import torch; print('PyTorch导入成功，版本:', torch.__version__); print('CUDA可用:', torch.cuda.is_available())" || Write-Host "PyTorch导入失败" -ForegroundColor Yellow
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "PyTorch安装成功" -ForegroundColor Green
        } else {
            Write-Host "PyTorch导入失败，但安装可能已完成" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "PyTorch安装失败: $_" -ForegroundColor Red
        Write-Host "这可能不会影响基本功能，但可能会限制某些AI功能" -ForegroundColor Yellow
    }
}


# 配置ReportLab中文字体支持
Install-Dependencies "正在配置ReportLab中文字体支持..." {
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

    # 将脚本保存到文件
    $fontConfigPath = "$env:MAMBA_ROOT_PREFIX\base\envs\$ENV_NAME\Scripts\setup_reportlab_fonts.py"
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

    $testScriptPath = "$env:USERPROFILE\.micromamba\envs\$ENV_NAME\Scripts\test_reportlab_fonts.py"
    $testScript | Out-File -FilePath $testScriptPath -Encoding utf8
    
    Write-Host "ReportLab中文字体配置完成" -ForegroundColor Green
    Write-Host "可以运行以下命令测试中文字体: python $testScriptPath" -ForegroundColor Cyan
}

# 安装OpenAI和langchain相关包
Install-Dependencies "正在安装OpenAI和langchain相关包..." {
    # 使用micromamba安装langchain和OpenAI相关包
    Write-Host "正在使用micromamba安装langchain-openai和OpenAI..." -ForegroundColor Cyan
    # 修改为单独安装langchain-openai和openai，确保版本正确
    micromamba install -c conda-forge langchain-openai=0.1.25 openai -y
    
    # 安装其他langchain相关包
    Write-Host "正在安装其他langchain相关包..." -ForegroundColor Cyan
    micromamba install -c conda-forge langchain-community==0.2.16 langchain-groq langchain-mistralai -y
    
    # 安装其他可能需要的包
    Write-Host "安装其他AI相关依赖..." -ForegroundColor Cyan
    micromamba install -c conda-forge langgraph -y
    
    # 验证OpenAI包安装
    Write-Host "验证OpenAI包安装..." -ForegroundColor Cyan
    python -c "import openai; import langchain_openai; print('OpenAI版本:', openai.__version__); print('langchain-openai版本:', langchain_openai.__version__)" || Write-Host "OpenAI包验证失败，但安装可能已完成" -ForegroundColor Yellow
    
    # 尝试安装可能缺失的包
    Write-Host "尝试安装其他可能需要的包..." -ForegroundColor Yellow
    python -m pip install --disable-pip-version-check --timeout 30 langchain_anthropic langchain_huggingface || Write-Host "部分包安装失败，但这不会影响主要功能" -ForegroundColor Yellow
}

# 完成
Write-Host "安装完成！" -ForegroundColor Green
Write-Host "请使用 'micromamba activate $ENV_NAME' 激活环境后运行Odoo" -ForegroundColor Green
Write-Host "如果遇到问题，可能需要重新启动PowerShell并手动激活环境" -ForegroundColor Yellow

Read-Host "按Enter键退出"