#!/bin/bash

# 配置文件和日志文件路径
CONFIG_FILE="/etc/manage.conf"
LOG_FILE="/var/log/manage.log"

# 加载配置文件
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    # 创建默认配置文件
    sudo mkdir -p $(dirname $CONFIG_FILE)
    echo "# 系统管理脚本配置文件
LOG_LEVEL=info
DOCKER_MIRROR=https://mirrors.aliyun.com/docker-ce/linux/debian
DOCKER_COMPOSE_VERSION=v2.30.1" | sudo tee $CONFIG_FILE
fi

# 创建日志文件
sudo mkdir -p $(dirname $LOG_FILE)
sudo touch $LOG_FILE

# 加载模块
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/modules/base.sh"
source "$SCRIPT_DIR/modules/menu.sh"
source "$SCRIPT_DIR/modules/system.sh"
source "$SCRIPT_DIR/modules/info.sh"
source "$SCRIPT_DIR/modules/network.sh"
source "$SCRIPT_DIR/modules/docker.sh"

# 主函数
main() {
    # 检查依赖
    check_dependencies
    # 检查并安装工具
    check_and_install_tools
    
    while true; do
        show_menu
        read -p "请输入您的选择 [0-4]: " choice
        
        case $choice in
            1)
                show_system_info
                ;;
            2)
                system_config
                ;;
            3)
                manage_network
                ;;
            4)
                manage_docker
                ;;
            0)
                echo "感谢使用，再见！"
                exit 0
                ;;
            *)
                echo "无效的选择，请重试..."
                sleep 2
                ;;
        esac
    done
}

# 启动主程序
main
