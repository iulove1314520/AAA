#!/bin/bash

# 配置文件和日志文件路径
CONFIG_FILE="/etc/manage.conf"
LOG_FILE="/var/log/manage.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a $LOG_FILE
}

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

# 在脚本开头添加
check_dependencies() {
    local deps=("curl" "wget" "systemctl")
    for dep in "${deps[@]}"; do
        if ! command -v $dep >/dev/null 2>&1; then
            echo "缺少依赖: $dep"
            return 1
        fi
    done
}

# 1. 基础工具函数
check_and_install_tools() {
    clear
    echo "========== 系统初始化检查 =========="
    
    # 检查是否为root用户
    if [ "$EUID" -ne 0 ]; then
        echo "请使用root权限运行此脚本"
        exit 1
    fi
    
    # 检测包管理器
    if command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt-get"
        UPDATE_CMD="apt-get update"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        UPDATE_CMD="yum update"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        UPDATE_CMD="dnf update"
    else
        echo "未找到支持的包管理器！"
        exit 1
    fi
    
    # 更新包列表
    echo "正在更新系统包列表..."
    if $UPDATE_CMD >/dev/null 2>&1; then
        echo "系统包列表更新成功"
    else
        echo "系统包列表更新失败，请检查网络连接或手动更新"
    fi
    
    echo "========================================="
    read -p "按回车键继续..."
}

# 2. 显示菜单函数
show_menu() {
    clear
    echo "================================"
    echo "      系统管理脚本 v1.0         "
    echo "================================"
    echo "1. 显示系统信息"
    echo "2. 系统配置管理"
    echo "3. 网络管理"
    echo "4. Docker管理"
    echo "0. 退出"
    echo "================================"
}

show_system_config_menu() {
    clear
    echo "================================"
    echo "        系统配置菜单           "
    echo "================================"
    echo "1. 用户管理"
    echo "2. 时区管理"
    echo "3. 主机管理"
    echo "4. 交换分区管理"
    echo "5. 网络加速"
    echo "0. 返回上级菜单"
    echo "================================"
}

show_network_menu() {
    clear
    echo "================================"
    echo "         网络管理菜单           "
    echo "================================"
    echo "1. 防火墙管理"
    echo "2. IP协议管理"
    echo "3. 查看网络状态"
    echo "4. 网络接口管理"
    echo "0. 返回上级菜单"
    echo "================================"
}

show_firewall_menu() {
    clear
    echo "================================"
    echo "         防火墙管理             "
    echo "================================"
    echo "1. 查看防火墙状态"
    echo "2. 关闭防火墙"
    echo "3. 开启防火墙"
    echo "4. 禁用防火墙开机启动"
    echo "5. 开放端口"
    echo "6. 关闭端口"
    echo "7. 查看已开放端口"
    echo "8. 检测端口状态"
    echo "0. 返回上级菜单"
    echo "================================"
}

show_ip_menu() {
    clear
    echo "================================"
    echo "         IP协议管理             "
    echo "================================"
    echo "1. 查看当前IP配置"
    echo "2. 设置IPv4优先"
    echo "3. 设置IPv6优先"
    echo "4. 禁用IPv4"
    echo "5. 禁用IPv6"
    echo "6. 启用IPv4"
    echo "7. 启用IPv6"
    echo "0. 返回上级菜单"
    echo "================================"
}

show_docker_menu() {
    clear
    echo "================================"
    echo "        Docker管理菜单          "
    echo "================================"
    echo "1. 检查Docker状态"
    echo "2. 安装/更新Docker"
    echo "3. 容器管理"
    echo "4. 镜像管理"
    echo "5. 网络管理"
    echo "6. 系统清理"
    echo "7. 配置修改"
    echo "0. 返回上级菜单"
    echo "================================"
}

# 3. 状态检查数
show_system_info() {
    clear
    echo "功能开发中..."
    read -p "按回车键返回..."
}

show_network_status() {
    clear
    echo "=========== 网络状态信息 ==========="
    
    echo "网络接口信息："
    echo "--------------------------------"
    ip addr show
    
    echo -e "\n路由表信息："
    echo "--------------------------------"
    ip route
    
    echo -e "\nDNS配置："
    echo "--------------------------------"
    cat /etc/resolv.conf
    
    echo -e "\n网络连接状态："
    echo "--------------------------------"
    ss -tuln
    
    echo -e "\n防火墙状态："
    echo "--------------------------------"
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw status
    elif command -v firewalld >/dev/null 2>&1; then
        sudo firewall-cmd --state
        sudo firewall-cmd --list-all
    else
        echo "未检测到支持的防火墙服务"
    fi
    
    echo -e "\nIP转发状态："
    echo "--------------------------------"
    cat /proc/sys/net/ipv4/ip_forward
    
    echo -e "\n网络负载统计："
    echo "--------------------------------"
    netstat -i
    
    read -p "按回车键返回..."
}

check_firewall_status() {
    clear
    echo "========== 防火墙状检查 =========="
    if command -v ufw >/dev/null 2>&1; then
        echo "UFW状态："
        sudo ufw status verbose
    elif command -v firewalld >/dev/null 2>&1; then
        echo "FirewallD状态："
        sudo systemctl status firewalld
    else
        echo "未检测到支持的防火墙服务"
    fi
    read -p "按回车键返回..."
}

check_docker_status() {
    clear
    echo "========== Docker状态检查 =========="
    
    # 检查Docker是否安装
    if command -v docker >/dev/null 2>&1; then
        echo -e "\n[Docker信息]"
        echo "Docker已安装"
        echo "Docker版本：" $(docker --version)
        echo "Docker Compose版本：" $(docker-compose --version 2>/dev/null || echo "未安装")
        
        # 检查Docker服务状态
        echo -e "\n[服务状态]"
        if systemctl is-active docker >/dev/null 2>&1; then
            echo "Docker服务：运行中"
        else
            echo "Docker服务：未运行"
        fi
        
        # 检查开机启动状态
        if systemctl is-enabled docker >/dev/null 2>&1; then
            echo "开机启动：已启用"
        else
            echo "开机启动：未启用"
        fi
        
        # 显示Docker信息
        echo -e "\n[系统信息]"
        docker info | grep -E "Server Version|Storage Driver|Logging Driver|Cgroup Driver|Containers:|Images:|Registry"
        
        # 显示资源使用情况
        echo -e "\n[资源使用]"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    else
        echo "Docker未安装"
    fi
    
    read -p "按回车键返回..."
}

check_port_status() {
    clear
    echo "============ 检测端口状态 ============"
    
    # 首先检查并安装nc工具
    if ! command -v nc >/dev/null 2>&1; then
        echo "正在安装nc工具..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y netcat
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y nc
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y nc
        else
            echo "无法安装nc工具，请手动安装"
            read -p "按回车键返回..."
            return
        fi
    fi
    
    read -p "请输入要检测的端口号: " port
    read -p "请选择协议类型 (tcp/udp): " protocol
    
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "效的端口号！端口号必须在1-65535之间"
        read -p "按回车键返回..."
        return
    fi
    
    echo -e "\n正在检测端口 $port 的状态..."
    echo "--------------------------------"
    
    # 检查防火墙状态（如果有）
    if command -v ufw >/dev/null 2>&1; then
        echo "UFW防火墙规则："
        sudo ufw status | grep "$port/$protocol"
    elif command -v firewalld >/dev/null 2>&1; then
        echo "FirewallD防火墙规则："
        sudo firewall-cmd --list-ports | grep "$port/$protocol"
    fi
    
    # 检查端口是否被占用
    echo -e "\n端口监听状态："
    if netstat -tuln | grep ":$port "; then
        echo "端口 $port 已被占用"
        echo -e "\n占用详情："
        sudo lsof -i :$port
    else
        echo "端口 $port 未被占用"
    fi
    
    # 使用nc测试端口连通性
    echo -e "\n端口连通性测试："
    case $protocol in
        tcp)
            if nc -zv -w 2 localhost $port 2>&1; then
                echo "TCP端口 $port 可以访问"
            else
                echo "TCP端口 $port 无法访问"
            fi
            ;;
        udp)
            if nc -zuv -w 2 localhost $port 2>&1; then
                echo "UDP端口 $port 可以访问"
            else
                echo "UDP端口 $port 无法访问"
            fi
            ;;
        *)
            echo "无效的协议类型！"
            ;;
    esac
    
    read -p "按回车键返回..."
}

# 4. 配置管理函数
configure_docker_mirror() {
    local config_file="/etc/docker/daemon.json"
    sudo mkdir -p /etc/docker
    
    echo "选择镜像加速器："
    echo "1. 阿里云"
    echo "2. 腾讯云"
    echo "3. 中科大"
    echo "4. 网易"
    read -p "请选择 [1-4]: " mirror_type
    
    local mirror_url
    case $mirror_type in
        1)
            mirror_url="https://mirrors.aliyun.com/docker-ce/linux/debian"
            ;;
        2)
            mirror_url="https://mirror.ccs.tencentyun.com"
            ;;
        3)
            mirror_url="https://mirrors.ustc.edu.cn/docker-ce/linux/debian"
            ;;
        4)
            mirror_url="https://mirrors.163.com/docker-ce/linux/debian"
            ;;
        *)
            echo "无效的选择"
            return
            ;;
    esac
    
    echo "{
  \"registry-mirrors\": [\"${mirror_url}\"],
  \"log-driver\": \"json-file\",
  \"log-opts\": {
    \"max-size\": \"100m\",
    \"max-file\": \"3\"
  }
}" | sudo tee $config_file
    
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "镜像加速配置完成"
}

configure_docker_logging() {
    clear
    echo "配置Docker日志选项..."
    echo "{
  \"log-driver\": \"json-file\",
  \"log-opts\": {
    \"max-size\": \"100m\",
    \"max-file\": \"3\"
  }
}" | sudo tee -a /etc/docker/daemon.json
    
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "日志配置已更新"
}

configure_docker_dns() {
    clear
    echo "配置Docker DNS..."
    read -p "请输入首选DNS服务器: " dns1
    read -p "请输入备用DNS服务器: " dns2
    
    echo "{
  \"dns\": [\"$dns1\", \"$dns2\"]
}" | sudo tee -a /etc/docker/daemon.json
    
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "DNS配置已更新"
}

modify_docker_config() {
    clear
    echo "========== Docker配置修改 =========="
    echo "1. 配置镜像加速"
    echo "2. 修改存储目录"
    echo "3. 修改日志配置"
    echo "4. 配置容器DNS"
    echo "0. 返回"
    
    read -p "请选择 [0-4]: " config_choice
    case $config_choice in
        1)
            configure_docker_mirror
            ;;
        2)
            change_docker_root
            ;;
        3)
            configure_docker_logging
            ;;
        4)
            configure_docker_dns
            ;;
        0)
            return
            ;;
        *)
            echo "无效的选择"
            ;;
    esac
    read -p "按回车键返回..."
}

change_docker_root() {
    clear
    echo "当前Docker根目录："
    docker info | grep "Docker Root Dir"
    
    read -p "请输入新的存储路径: " new_path
    if [ -n "$new_path" ]; then
        echo "{
  \"data-root\": \"$new_path\"
}" | sudo tee -a /etc/docker/daemon.json
        
        sudo systemctl daemon-reload
        sudo systemctl restart docker
        echo "存储目录已修改，请检查新目录是否生效"
    fi
}

# 5. 操作管理函数
manage_network() {
    while true; do
        show_network_menu
        read -p "请输入您的选择 [0-4]: " choice
        
        case $choice in
            1)
                manage_firewall
                ;;
            2)
                manage_ip_protocol
                ;;
            3)
                show_network_status
                ;;
            4)
                manage_network_interface
                ;;
            0)
                return
                ;;
            *)
                echo "无效的选择，请重试..."
                sleep 2
                ;;
        esac
    done
}

manage_firewall() {
    while true; do
        show_firewall_menu
        read -p "请输入您的选择 [0-8]: " choice
        
        case $choice in
            1)
                check_firewall_status
                ;;
            2)
                stop_firewall
                ;;
            3)
                start_firewall
                ;;
            4)
                disable_firewall
                ;;
            5)
                open_port
                ;;
            6)
                close_port
                ;;
            7)
                list_open_ports
                ;;
            8)
                check_port_status
                ;;
            0)
                return
                ;;
            *)
                echo "无效的选择，请重试..."
                sleep 2
                ;;
        esac
    done
}

manage_docker() {
    while true; do
        show_docker_menu
        read -p "请输入您的选择 [0-7]: " choice
        
        case $choice in
            1)
                check_docker_status
                ;;
            2)
                install_update_docker
                ;;
            3)
                manage_containers
                ;;
            4)
                manage_images
                ;;
            5)
                manage_docker_network
                ;;
            6)
                clean_docker_system
                ;;
            7)
                modify_docker_config
                ;;
            0)
                return
                ;;
            *)
                echo "无效的选择，请重试..."
                sleep 2
                ;;
        esac
    done
}

manage_containers() {
    while true; do
        clear
        echo "============ 容器管理 ============"
        echo "1. 查看所有容器"
        echo "2. 启动容器"
        echo "3. 停止容器"
        echo "4. 重启容器"
        echo "5. 删除容器"
        echo "6. 查看容器日志"
        echo "7. 进入容器终端"
        echo "8. 查看容器详情"
        echo "9. 导出容器"
        echo "0. 返回上级菜单"
        echo "================================"
        
        read -p "请输入您的选择 [0-9]: " choice
        case $choice in
            1)
                clear
                echo "所容器列表："
                docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
                read -p "按回车键返回..."
                ;;
            2)
                clear
                echo "停止的容器列表："
                docker ps -a --filter "status=exited" --format "table {{.ID}}\t{{.Image}}\t{{.Names}}"
                read -p "请输入要启动的容器ID或名称: " container
                if [ -n "$container" ]; then
                    docker start $container
                    echo "容器已启动"
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                echo "运行中的容器列表："
                docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Names}}"
                read -p "请输入要停止的容器ID或名称: " container
                if [ -n "$container" ]; then
                    docker stop $container
                    echo "容器已停止"
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                echo "所有容器列表："
                docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}"
                read -p "请输入要重启的容器ID或名称: " container
                if [ -n "$container" ]; then
                    docker restart $container
                    echo "容器已重启"
                fi
                read -p "按回车键返回..."
                ;;
            5)
                clear
                echo "所有容器列表："
                docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}"
                read -p "请输入要删除的容器ID或名称: " container
                if [ -n "$container" ]; then
                    read -p "是否强制删除？(y/n): " force
                    if [[ $force =~ ^[Yy]$ ]]; then
                        docker rm -f $container
                    else
                        docker rm $container
                    fi
                    echo "容器已删除"
                fi
                read -p "按回车键返回..."
                ;;
            6)
                clear
                echo "运行中的容器列表："
                docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Names}}"
                read -p "请输入要查看日志的容器ID或名称: " container
                if [ -n "$container" ]; then
                    read -p "要查看多少行日志？(默认100): " lines
                    lines=${lines:-100}
                    docker logs --tail $lines -f $container
                fi
                ;;
            7)
                clear
                echo "运行中的容器列表："
                docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Names}}"
                read -p "请输入要进入的容器ID或名称: " container
                if [ -n "$container" ]; then
                    docker exec -it $container /bin/bash || docker exec -it $container /bin/sh
                fi
                ;;
            8)
                clear
                echo "所有容器列表："
                docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}"
                read -p "请输入要查看详情的容器ID或名称: " container
                if [ -n "$container" ]; then
                    docker inspect $container
                fi
                read -p "按回车键返回..."
                ;;
            9)
                clear
                echo "所有容器列表："
                docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}"
                read -p "请输入要导出的容器ID或名称: " container
                if [ -n "$container" ]; then
                    read -p "请输入导出文件名(.tar): " filename
                    docker export $container > $filename
                    echo "容器已导出到 $filename"
                fi
                read -p "按回车键返回..."
                ;;
            0)
                return
                ;;
            *)
                echo "无效的选择，请重试..."
                sleep 2
                ;;
        esac
    done
}

manage_images() {
    while true; do
        clear
        echo "============ 镜像管理 ============"
        echo "1. 查看所有镜像"
        echo "2. 搜索镜像"
        echo "3. 拉取镜像"
        echo "4. 删除镜像"
        echo "5. 导出镜像"
        echo "6. 导入镜像"
        echo "7. 构建镜像"
        echo "8. 镜像历史"
        echo "9. 清理未使用镜像"
        echo "0. 返回上级菜单"
        echo "================================"
        
        read -p "请输入您的选择 [0-9]: " choice
        case $choice in
            1)
                clear
                echo "所有镜像列表："
                docker images
                read -p "按回车键返回..."
                ;;
            2)
                clear
                read -p "请输入要搜索的镜像关键字: " keyword
                if [ -n "$keyword" ]; then
                    docker search $keyword
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                read -p "请输入要拉取的镜像名称: " image
                if [ -n "$image" ]; then
                    docker pull $image
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                echo "所有镜像列表："
                docker images
                read -p "请输入要删除的镜像ID或名称: " image
                if [ -n "$image" ]; then
                    read -p "是否强制删除？(y/n): " force
                    if [[ $force =~ ^[Yy]$ ]]; then
                        docker rmi -f $image
                    else
                        docker rmi $image
                    fi
                fi
                read -p "按回车键返回..."
                ;;
            5)
                clear
                echo "所有镜像列表："
                docker images
                read -p "请输入要导出的镜像名称: " image
                if [ -n "$image" ]; then
                    read -p "请输入导出文件名(.tar): " filename
                    docker save -o $filename $image
                    echo "镜像已导出到 $filename"
                fi
                read -p "按回车键返回..."
                ;;
            6)
                clear
                read -p "请输入要导入的文件名(.tar): " filename
                if [ -f "$filename" ]; then
                    docker load -i $filename
                else
                    echo "文件不存在！"
                fi
                read -p "按回车键返回..."
                ;;
            7)
                clear
                read -p "请输入Dockerfile路径: " dockerfile
                read -p "请输入镜像名称和标签: " tag
                if [ -f "$dockerfile" ]; then
                    docker build -t $tag -f $dockerfile .
                else
                    echo "Dockerfile不存在！"
                fi
                read -p "按回车键返回..."
                ;;
            8)
                clear
                echo "所有镜像列表："
                docker images
                read -p "请输入要查看历史的镜像名称: " image
                if [ -n "$image" ]; then
                    docker history $image
                fi
                read -p "按回车键返回..."
                ;;
            9)
                clear
                echo "正在清理未使用的镜像..."
                docker image prune -a -f
                read -p "按回车键返回..."
                ;;
            0)
                return
                ;;
            *)
                echo "无效的选择，请重试..."
                sleep 2
                ;;
        esac
    done
}

manage_docker_network() {
    while true; do
        clear
        echo "========== Docker网络管理 =========="
        echo "1. 查看所有网络"
        echo "2. 创建网络"
        echo "3. 删除网络"
        echo "4. 查看网络详情"
        echo "5. 连接容器到网络"
        echo "6. 断开容器与网络的连接"
        echo "7. 清理未使用的网络"
        echo "0. 返回上级菜单"
        echo "===================================="
        
        read -p "请输入您的选择 [0-7]: " choice
        case $choice in
            1)
                clear
                echo "所有网络列表："
                docker network ls
                read -p "按回车键返回..."
                ;;
            2)
                clear
                read -p "请输入网络名称: " network
                read -p "请选择网络驱动(bridge/overlay/host/none): " driver
                if [ -n "$network" ]; then
                    docker network create --driver ${driver:-bridge} $network
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                echo "所有网络列表："
                docker network ls
                read -p "请输入要删除的网络名称: " network
                if [ -n "$network" ]; then
                    docker network rm $network
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                echo "所有网络列表："
                docker network ls
                read -p "请输入要查看详情的网络名称: " network
                if [ -n "$network" ]; then
                    docker network inspect $network
                fi
                read -p "按回车键返回..."
                ;;
            5)
                clear
                echo "所有网络列表："
                docker network ls
                echo -e "\n运行中的容器列表："
                docker ps --format "table {{.ID}}\t{{.Names}}"
                read -p "请输入网络名称: " network
                read -p "请输入容器ID或名称: " container
                if [ -n "$network" ] && [ -n "$container" ]; then
                    docker network connect $network $container
                fi
                read -p "按回车键返回..."
                ;;
            6)
                clear
                echo "所有网络列表："
                docker network ls
                echo -e "\n运行中的容器列表："
                docker ps --format "table {{.ID}}\t{{.Names}}"
                read -p "请输入网络名称: " network
                read -p "请输入容器ID或名称: " container
                if [ -n "$network" ] && [ -n "$container" ]; then
                    docker network disconnect $network $container
                fi
                read -p "按回车键返回..."
                ;;
            7)
                clear
                echo "正在清理未使用的网络..."
                docker network prune -f
                read -p "按回车键返回..."
                ;;
            0)
                return
                ;;
            *)
                echo "无效的选择，请重试..."
                sleep 2
                ;;
        esac
    done
}

clean_docker_system() {
    while true; do
        clear
        echo "========== Docker系统清理 =========="
        echo "1. 清理所有未使用的容器"
        echo "2. 清理所有未使用的镜像"
        echo "3. 清理所有未使用的网络"
        echo "4. 清理所有未使用的数据卷"
        echo "5. 清理构建缓存"
        echo "6. 一键清理所有未使用资源"
        echo "7. 显示Docker磁盘使用情况"
        echo "0. 返回上级菜单"
        echo "===================================="
        
        read -p "请输入您的选择 [0-7]: " choice
        case $choice in
            1)
                clear
                echo "正在清理未使用的容器..."
                docker container prune -f
                read -p "按回车键返回..."
                ;;
            2)
                clear
                echo "正在清理未使用的镜像..."
                docker image prune -a -f
                read -p "按回车键返回..."
                ;;
            3)
                clear
                echo "正在清理未使用的网络..."
                docker network prune -f
                read -p "按回车键返回..."
                ;;
            4)
                clear
                echo "正在清理未使用的数据卷..."
                docker volume prune -f
                read -p "按回车键返回..."
                ;;
            5)
                clear
                echo "正在清理构建缓存..."
                docker builder prune -f
                read -p "按回车键返回..."
                ;;
            6)
                clear
                echo "正在清理所有未使用的Docker资源..."
                docker system prune -a -f --volumes
                read -p "按回车键返回..."
                ;;
            7)
                clear
                echo "Docker磁盘使用情况："
                docker system df -v
                read -p "按回车键返回..."
                ;;
            0)
                return
                ;;
            *)
                echo "无效的选择，请重试..."
                sleep 2
                ;;
        esac
    done
}

# 网络接口管理函数
manage_network_interface() {
    clear
    echo "========== 网络接口管理 =========="
    echo "1. 查看网络接口"
    echo "2. 启用网络接口"
    echo "3. 禁用网络接口"
    echo "4. 配置IP地址"
    echo "0. 返回上级菜单"
    echo "================================="
    
    read -p "请输入您的选择 [0-4]: " choice
    case $choice in
        1)
            clear
            echo "网络接口列表："
            ip link show
            read -p "按回车键返回..."
            ;;
        2)
            clear
            echo "网络接口列表："
            ip link show
            read -p "请输入要启用的接口名称: " interface
            if [ -n "$interface" ]; then
                sudo ip link set $interface up
                echo "接口已启用"
                log "启用网络接口 $interface"
            fi
            read -p "按回车键返回..."
            ;;
        3)
            clear
            echo "网络接口列表："
            ip link show
            read -p "请输入要禁用的接口名称: " interface
            if [ -n "$interface" ]; then
                sudo ip link set $interface down
                echo "接口已禁用"
                log "禁用网络接口 $interface"
            fi
            read -p "按回车键返回..."
            ;;
        4)
            clear
            echo "网络接口列表："
            ip addr show
            read -p "请输入要配置的接口名称: " interface
            read -p "请输入IP地址(例如:192.168.1.100/24): " ip
            if [ -n "$interface" ] && [ -n "$ip" ]; then
                sudo ip addr add $ip dev $interface
                echo "IP地址已配置"
                log "配置接口 $interface 的IP地址为 $ip"
            fi
            read -p "按回车键返回..."
            ;;
        0)
            return
            ;;
        *)
            echo "无效的选择，请重试..."
            sleep 2
            ;;
    esac
}

# IP协议管理函数
manage_ip_protocol() {
    clear
    echo "========== IP协议管理 =========="
    echo "1. 查看IP配置"
    echo "2. 设置IPv4优先"
    echo "3. 设置IPv6优先"
    echo "4. 禁用IPv4"
    echo "5. 禁用IPv6"
    echo "6. 启用IPv4"
    echo "7. 启用IPv6"
    echo "0. 返回上级菜单"
    echo "==============================="
    
    read -p "请输入您的选择 [0-7]: " choice
    case $choice in
        1)
            clear
            echo "IP配置信息："
            ip addr show
            read -p "按回车键返回..."
            ;;
        2)
            if [ -f /etc/gai.conf ]; then
                sudo cp /etc/gai.conf /etc/gai.conf.bak
                echo "precedence ::ffff:0:0/96  100" | sudo tee -a /etc/gai.conf
                echo "IPv4优先级已设置"
                log "设置IPv4优先"
            fi
            read -p "按回车键返回..."
            ;;
        3)
            if [ -f /etc/gai.conf ]; then
                sudo cp /etc/gai.conf /etc/gai.conf.bak
                echo "precedence ::ffff:0:0/96  10" | sudo tee -a /etc/gai.conf
                echo "IPv6优先级已设置"
                log "设置IPv6优先"
            fi
            read -p "按回车键返回..."
            ;;
        4)
            echo "net.ipv4.ip_forward=0" | sudo tee -a /etc/sysctl.conf
            sudo sysctl -p
            echo "IPv4已禁用"
            log "禁用IPv4"
            read -p "按回车键返回..."
            ;;
        5)
            echo "net.ipv6.conf.all.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf
            echo "net.ipv6.conf.default.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf
            sudo sysctl -p
            echo "IPv6已禁用"
            log "禁用IPv6"
            read -p "按回车键返回..."
            ;;
        6)
            sudo sed -i '/net.ipv4.ip_forward=0/d' /etc/sysctl.conf
            echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
            sudo sysctl -p
            echo "IPv4已启用"
            log "启用IPv4"
            read -p "按回车键返回..."
            ;;
        7)
            sudo sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
            sudo sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
            echo "net.ipv6.conf.all.disable_ipv6=0" | sudo tee -a /etc/sysctl.conf
            echo "net.ipv6.conf.default.disable_ipv6=0" | sudo tee -a /etc/sysctl.conf
            sudo sysctl -p
            echo "IPv6已启用"
            log "启用IPv6"
            read -p "按回车键返回..."
            ;;
        0)
            return
            ;;
        *)
            echo "无效的选择，请重试..."
            sleep 2
            ;;
    esac
}

# 6. 主程序函数
main() {
    # 检查并安装必要工具
    check_and_install_tools
    
    # 主程序循环
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

# 10. 启动主程序（最后一行）
main
