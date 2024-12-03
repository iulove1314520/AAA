#!/bin/bash
# 基础工具函数模块

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a $LOG_FILE
}

# 检查依赖
check_dependencies() {
    local deps=("curl" "wget" "systemctl")
    for dep in "${deps[@]}"; do
        if ! command -v $dep >/dev/null 2>&1; then
            echo "缺少依赖: $dep"
            return 1
        fi
    done
}

# 检查并安装工具
check_and_install_tools() {
    # ... (原check_and_install_tools函数内容)
}

# 安装必要软件包
install_required_packages() {
    # ... (原install_required_packages函数内容)
}

# 备份配置文件
backup_config() {
    # ... (原backup_config函数内容)
}

# 检查命令执行结果
check_command_status() {
    # ... (原check_command_status函数内容)
}

# 错误处理
handle_error() {
    # ... (原handle_error函数内容)
} 