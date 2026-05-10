#!/data/data/com.termux/files/usr/bin/bash
# Termux MCSManager 安装脚本
set -e

C_RESET='\e[0m'
C_BOLD='\e[1m'
C_CYAN='\e[36m'
C_GREEN='\e[32m'
C_YELLOW='\e[33m'
C_BLUE='\e[34m'
C_RED='\e[31m'
C_MAGENTA='\e[35m'

SEP="=================================================="

info() { echo -e "${C_CYAN}[info]${C_RESET} $1"; }
step() { echo -e "\n${C_BLUE}${C_BOLD}>> $1${C_RESET}"; }
success() { echo -e "${C_GREEN}[成功]${C_RESET} $1"; }
warn() { echo -e "${C_YELLOW}[注意]${C_RESET} $1"; }
error() { echo -e "${C_RED}[错误]${C_RESET} $1"; }

echo -e "${C_MAGENTA}${SEP}${C_RESET}"
echo -e "${C_MAGENTA}   MCSManager 安装工具 (Termux)  ${C_RESET}"
echo -e "${C_MAGENTA}${SEP}${C_RESET}"

# 1. 替换清华源并更新软件源
step "1/8 更换清华源并更新软件源..."
sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 stable main@' $PREFIX/etc/apt/sources.list
apt update && apt upgrade -y
success "软件源已更新到最新。"

# 2. 安装 Node.js
step "2/8 安装 Node.js..."
pkg install -y nodejs
success "Node.js 安装完成。"

# 3. 安装 Java
step "3/8 安装 Java..."
echo -e "请选择 Java 版本:"
echo -e "  ${C_YELLOW}1)${C_RESET} Java 25"
echo -e "  ${C_YELLOW}2)${C_RESET} Java 21"
echo -e "  ${C_YELLOW}3)${C_RESET} Java 17"
read -p "$(echo -e ${C_CYAN}请输入选项 1/2/3: ${C_RESET})" java_choice

case $java_choice in
    1) JAVA_VER="25";;
    2) JAVA_VER="21";;
    3) JAVA_VER="17";;
    *) error "无效选项，安装终止。"; exit 1;;
esac

info "正在安装 openjdk-${JAVA_VER} ..."
pkg install -y openjdk-${JAVA_VER}
success "Java ${JAVA_VER} 安装完成。"

# 4. 检查安装
step "4/8 验证关键组件..."
echo -e "${C_CYAN}Node.js 版本:${C_RESET} $(node -v)"
echo -e "${C_CYAN}Java 版本:${C_RESET} $(java -version 2>&1 | head -n 1)"
success "所有依赖就绪！"

# 5. 安装 wget
step "5/8 安装 wget..."
pkg install -y wget
success "wget 安装完成。"

# 6. 创建 mcsm 目录
step "6/8 创建工作目录..."
MCMS_DIR="$HOME/mcsm"
mkdir -p "$MCMS_DIR"
cd "$MCMS_DIR"
success "目录已创建: $MCMS_DIR"

# 7. 下载 MCSManager
step "7/8 获取 MCSManager 发行包..."
echo -e "请选择下载方式:"
echo -e "  ${C_YELLOW}1)${C_RESET} github加速 (proxy.gitwarp.top)"
echo -e "  ${C_YELLOW}2)${C_RESET} 官方源 (gitHub)"
echo -e "  ${C_YELLOW}3)${C_RESET} 手动导入 (需提前放置文件)"
read -p "$(echo -e ${C_CYAN}请输入选项 1/2/3: ${C_RESET})" choice

case $choice in
    1)
        info "使用加速代理下载..."
        wget https://proxy.gitwarp.top/https://github.com/MCSManager/MCSManager/releases/latest/download/mcsmanager_linux_release.tar.gz
        ;;
    2)
        info "使用官方源下载..."
        wget https://github.com/MCSManager/MCSManager/releases/latest/download/mcsmanager_linux_release.tar.gz
        ;;
    3)
        info "请将 mcsmanager_linux_release.tar.gz 放入 ~/mcsm/ 后按回车..."
        read -p "$(echo -e ${C_CYAN}放置完成后按回车键...${C_RESET})"
        if [ ! -f "$MCMS_DIR/mcsmanager_linux_release.tar.gz" ]; then
            error "未找到文件，请检查路径后重试。"
            exit 1
        fi
        success "已找到本地安装包，跳过下载。"
        ;;
    *)
        error "无效选项，安装终止。"
        exit 1
        ;;
esac

# 8. 解压、安装、修正
step "8/8 解压安装"
echo -e "${C_CYAN}解压 mcsmanager_linux_release.tar.gz ...${C_RESET}"
tar --strip-components=1 -xzvf mcsmanager_linux_release.tar.gz

chmod 777 install.sh
info "执行 install.sh ..."
./install.sh

# 修正守护进程文件
cd "$MCMS_DIR/daemon/lib"
if [ -f "file_zip_linux_arm64" ]; then
    cp file_zip_linux_arm64 file_zip_android_arm64
    success "file_zip_android_arm64 已生成"
else
    warn "未找到 file_zip_linux_arm64，跳过"
fi

if [ -f "pty_linux_arm64" ]; then
    cp pty_linux_arm64 pty_android_arm64
    success "pty_android_arm64 已生成"
else
    warn "未找到 pty_linux_arm64，跳过"
fi

cd "$MCMS_DIR"
chmod 777 start-web.sh

# 添加快捷命令
BASHRC="$HOME/.bashrc"
if ! grep -q "function webs()" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" << 'EOF'

# MCSManager 快捷命令
function webs() {
    cd ~/mcsm && ./start-daemon.sh
}
function web() {
    cd ~/mcsm && ./start-web.sh
}
EOF
fi

# ---------- 重要提示 ----------
echo -e "\n${C_GREEN}${SEP}${C_RESET}"
echo -e "${C_GREEN}  环境安装完成！ʢ˶ᵒ ᵕ ˂˶ʡᶻ  ${C_RESET}"
echo -e "${C_GREEN}${SEP}${C_RESET}"

echo -e "接下来请 ${C_BOLD}新开一个 Termux 会话${C_RESET}，执行:"
echo -e "  ${C_YELLOW}web${C_RESET}"
echo -e ""
echo -e "${C_GREEN}面板地址: ${C_BOLD}http://localhost:23333${C_RESET}"

echo -e "\n${C_YELLOW}*** 重新开启面板指引 ***${C_RESET}"
echo -e "若面板关闭后需要重新启动，请按顺序操作:"
echo -e "  1. 在当前会话执行: ${C_BOLD}webs${C_RESET}"
echo -e "  2. ${C_BOLD}新建会话${C_RESET}，执行: ${C_BOLD}web${C_RESET}"
echo -e "${C_YELLOW}==============================${C_RESET}"

# 等待 10 秒后启动守护进程
echo -e "\n${C_CYAN}当前会话将在 10 秒后自动启动守护进程...${C_RESET}"
sleep 10
./start-daemon.sh
