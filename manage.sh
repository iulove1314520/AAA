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
        echo "请使用root权��运行此脚本"
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
# 主菜单
show_menu() {
    clear
    echo "================================"
    echo "      系统管理脚本 v1.0         "
    echo "================================"
    echo "1. 系统信息"
    echo "2. 系统配置管理"
    echo "3. 网络管理"
    echo "4. Docker管理"
    echo "0. 退出"
    echo "================================"
}

# 系统配置菜单
show_system_config_menu() {
    clear
    echo "================================"
    echo "        系统配��菜单           "
    echo "================================"
    echo "1. 用户管理"
    echo "2. 时区管理"
    echo "3. 主机管理"
    echo "4. 交换分区管理"
    echo "5. 网络加速"
    echo "6. 系统服务管理"
    echo "7. 系统更新"
    echo "8. 软件包管理"
    echo "0. 返回上级菜单"
    echo "================================"
}

# 网络管理菜单
show_network_menu() {
    clear
    echo "================================"
    echo "         网络管理菜单           "
    echo "================================"
    echo "1. 防火墙管理"
    echo "2. IP协议管理"
    echo "3. 查看网络状态"
    echo "4. 网络接口管理"
    echo "5. DNS配置"
    echo "6. 路由管理"
    echo "7. 网络测试工具"
    echo "0. 返回上级菜单"
    echo "================================"
}

# 防火墙管理菜单
show_firewall_menu() {
    clear
    echo "================================"
    echo "         防火墙管理             "
    echo "================================"
    echo "1. 查看防火墙状态"
    echo "2. 开启防火墙"
    echo "3. 关闭防火墙"
    echo "4. 防火墙开机启动设置"
    echo "5. 开放端口"
    echo "6. 关闭端口"
    echo "7. 查看已开放端口"
    echo "8. 端口状态检测"
    echo "9. 防火墙规则管理"
    echo "0. 返回上级菜单"
    echo "================================"
}

# IP协议管理菜单
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
    echo "8. IP转发设置"
    echo "9. IP地址管理"
    echo "0. 返回上级菜单"
    echo "================================"
}

# Docker管理菜单
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
    echo "6. 数据卷管理"
    echo "7. 系统清理"
    echo "8. 配置修改"
    echo "9. Docker Compose管理"
    echo "0. 返回上级菜单"
    echo "================================"
}

# 3. 状态检查数
show_system_info() {
    while true; do
        clear
        echo "================================"
        echo "         系统信息菜单           "
        echo "================================"
        echo "1. 基本系统信息"
        echo "2. CPU信息"
        echo "3. 内存信息"
        echo "4. 磁盘信息"
        echo "5. 网络信息"
        echo "6. 显示所有信息"
        echo "7. 系统服务状态"  # 新增选项
        echo "8. 系统日志信息"  # 新增选项
        echo "9. 硬件信息"      # 新增选项
        echo "0. 返回主菜单"
        echo "================================"
        
        read -p "请输入您的选择 [0-9]: " choice
        case $choice in
            1)
                show_basic_info
                ;;
            2)
                show_cpu_info
                ;;
            3)
                show_memory_info
                ;;
            4)
                show_disk_info
                ;;
            5)
                show_network_info
                ;;
            6)
                show_all_info
                ;;
            7)
                show_service_status
                ;;
            8)
                show_system_logs
                ;;
            9)
                show_hardware_info
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

# 显示基本系统信息
show_basic_info() {
    clear
    echo "=========== 基本系统信息 ==========="
    echo "操作系统：" $(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)
    echo "内核版本：" $(uname -r)
    echo "系统架构：" $(uname -m)
    echo "主机名：" $(hostname)
    echo "当前时区：" $(timedatectl | grep "Time zone" | awk '{print $3}')
    echo "系统时间：" $(date "+%Y-%m-%d %H:%M:%S")
    echo "系统启动时间：" $(uptime -s)
    echo "运行时间：" $(uptime -p)
    echo "当前用户：" $(whoami)
    echo "登录用户：" $(who)
    echo "系统负载：" $(uptime | awk -F'load average: ' '{print $2}')
    echo "系统语言：" $LANG
    echo "默认Shell：" $SHELL
    echo "当前进程数：" $(ps aux | wc -l)
    echo "系统限制：" $(ulimit -a | head -n 5)
    
    echo -e "\n系统资源限制："
    echo "最大文件打开数：" $(ulimit -n)
    echo "最大进程数：" $(ulimit -u)
    
    echo -e "\n系统服务状态："
    systemctl list-units --type=service --state=running | head -n 5
    
    echo -e "\n最近登录记录："
    last | head -n 5
    
    read -p "按回车键返回..."
}

# 显示CPU信息
show_cpu_info() {
    clear
    echo "=========== CPU信息 ==========="
    echo "CPU型号：" $(cat /proc/cpuinfo | grep "model name" | head -n1 | cut -d':' -f2)
    echo "CPU核心数：" $(nproc)
    echo "CPU架构：" $(uname -m)
    echo -e "\nCPU使用情况："
    top -bn1 | head -n3
    echo -e "\nCPU详细信息："
    lscpu
    read -p "按回车键返回..."
}

# 显示内存信息
show_memory_info() {
    clear
    echo "=========== 内存信息 ==========="
    echo "物理内存使用情况："
    free -h | grep "Mem:" | awk '{printf "总内存: %s\n已用: %s\n空闲: %s\n共享: %s\n缓冲/缓存: %s\n可用: %s\n", $2, $3, $4, $5, $6, $7}'
    
    echo -e "\nSwap使用情况："
    free -h | grep "Swap:" | awk '{printf "总Swap: %s\n已用: %s\n空闲: %s\n", $2, $3, $4}'
    
    echo -e "\nSwap统计信息："
    if [ -f /proc/swaps ]; then
        echo "已配置的Swap设备："
        cat /proc/swaps
    fi
    
    echo -e "\n内存详细统计："
    vmstat -s | head -n 10
    
    echo -e "\n缓存使用情况："
    echo "页面缓存：" $(cat /proc/meminfo | grep "Cached" | head -n1 | awk '{print $2/1024 "MB"}')
    echo "缓冲区：" $(cat /proc/meminfo | grep "Buffers" | awk '{print $2/1024 "MB"}')
    
    echo -e "\n内存使用TOP 10进程："
    ps aux --sort=-%mem | head -n 11
    
    echo -e "\n内存使用趋势："
    vmstat 1 5
    
    read -p "按回车键返回..."
}

# 显示磁盘信息
show_disk_info() {
    clear
    echo "=========== 磁盘信息 ==========="
    echo "磁盘使用情况："
    df -h
    echo -e "\n磁盘分区信息："
    lsblk
    echo -e "\n磁盘详细信息："
    fdisk -l 2>/dev/null
    echo -e "\nI/O统计："
    iostat 2>/dev/null || echo "iostat未安装"
    read -p "按回车键返回..."
}

# 显示网络信息
show_network_info() {
    clear
    echo "=========== 网络信息 ==========="
    echo "网络接口："
    ip addr show
    echo -e "\n路由表："
    ip route
    echo -e "\nDNS配置："
    cat /etc/resolv.conf
    echo -e "\n网络连接："
    netstat -tuln
    echo -e "\n网络统计："
    netstat -s | head -n 20
    read -p "按回车键返回..."
}

# 显示所有系统信息
show_all_info() {
    clear
    echo "=========== 系统完整信息 ==========="
    
    echo "【基本系统信息】"
    echo "操作系统：" $(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)
    echo "内核版本：" $(uname -r)
    echo "主机名：" $(hostname)
    echo "当前时区：" $(timedatectl | grep "Time zone" | awk '{print $3}')
    echo "系统时间：" $(date "+%Y-%m-%d %H:%M:%S")
    echo "系统启动时间：" $(uptime -s)
    echo "运行时间：" $(uptime -p)
    echo "当前用户：" $(whoami)
    echo "系统负载：" $(uptime | awk -F'load average: ' '{print $2}')
    
    echo -e "\n【CPU信息】"
    echo "CPU型号：" $(cat /proc/cpuinfo | grep "model name" | head -n1 | cut -d':' -f2)
    echo "CPU核心数：" $(nproc)
    echo "CPU架构：" $(uname -m)
    echo "CPU使用率：" $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')"%"
    
    echo -e "\n【内存信息】"
    echo "物理内存："
    free -h | grep "Mem:"
    echo "Swap使用："
    free -h | grep "Swap:"
    
    echo -e "\n【磁盘信息】"
    echo "磁盘使用情况："
    df -h | grep '^/dev/'
    echo -e "\n磁盘分区信息："
    lsblk
    
    echo -e "\n【网络信息】"
    echo "IP地址："
    ip -4 addr show | grep inet
    echo -e "\nDNS配置："
    cat /etc/resolv.conf | grep nameserver
    
    echo -e "\n【系统服务】"
    echo "运行中的重要服务："
    systemctl list-units --type=service --state=running | head -n 5
    
    echo -e "\n【系统安全】"
    echo "最近的登录记录："
    last | head -n 5
    echo -e "\n失败的登录尝试："
    faillog -a | head -n 5
    
    read -p "按回车键继续..."
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
        
        # 显示运行中的容器
        echo -e "\n[运行中的容器]"
        docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"
        
        # 显示Docker网络
        echo -e "\n[Docker网络]"
        docker network ls
        
        # 显示数据卷
        echo -e "\n[数据卷]"
        docker volume ls
        
        # 显示系统占用
        echo -e "\n[系统占用]"
        docker system df -v
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
    echo -e "\n端口连通性���试："
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

# 在modify_docker_config函数之前添加新的配置函数

# 配置容器默认时区
configure_docker_timezone() {
    clear
    echo "========== 配置容器默认时区 =========="
    echo "1. 使用主机时区"
    echo "2. 使用UTC时间"
    echo "3. 自定义时区"
    
    read -p "请选择时区配置 [1-3]: " tz_choice
    
    local timezone
    case $tz_choice in
        1)
            timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
            ;;
        2)
            timezone="UTC"
            ;;
        3)
            read -p "请输入时区(例如:Asia/Shanghai): " timezone
            ;;
        *)
            echo "无效的选择"
            return
            ;;
    esac
    
    if [ -n "$timezone" ]; then
        echo "{
  \"default-timezone\": \"$timezone\"
}" | sudo tee -a /etc/docker/daemon.json
        
        sudo systemctl daemon-reload
        sudo systemctl restart docker
        echo "时区配置已更新为: $timezone"
    fi
    read -p "按回车键返回..."
}

# 配置容器资源限制
configure_docker_resources() {
    clear
    echo "========== 配置容器资源限制 =========="
    echo "1. 配置默认内存限制"
    echo "2. 配置默认CPU限制"
    echo "3. 配置默认Swap限制"
    echo "4. 配置默认PID限制"
    echo "0. 返回上级菜单"
    
    read -p "请选择要配置的资源 [0-4]: " resource_choice
    
    case $resource_choice in
        1)
            read -p "请输入默认内存限制(例如:2g): " memory_limit
            echo "{
  \"default-memory\": \"$memory_limit\"
}" | sudo tee -a /etc/docker/daemon.json
            ;;
        2)
            read -p "请输入默认CPU核心数限制(例如:2): " cpu_limit
            echo "{
  \"default-cpus\": \"$cpu_limit\"
}" | sudo tee -a /etc/docker/daemon.json
            ;;
        3)
            read -p "请输入默认Swap限制(例如:1g): " swap_limit
            echo "{
  \"default-swap\": \"$swap_limit\"
}" | sudo tee -a /etc/docker/daemon.json
            ;;
        4)
            read -p "请输入默认PID限制(例如:1000): " pid_limit
            echo "{
  \"default-pid-limit\": $pid_limit
}" | sudo tee -a /etc/docker/daemon.json
            ;;
        0)
            return
            ;;
        *)
            echo "无效的选择"
            return
            ;;
    esac
    
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "资源限制配置已更新"
    read -p "按回车键返回..."
}

# 显示当前Docker配置
show_docker_config() {
    clear
    echo "========== 当前Docker配置 =========="
    if [ -f "/etc/docker/daemon.json" ]; then
        echo "daemon.json 内容："
        cat "/etc/docker/daemon.json" | jq '.'
    else
        echo "未找到 daemon.json 配置文件"
    fi
    
    echo -e "\nDocker守护进程配置："
    systemctl show docker | grep -E "Environment|ExecStart"
    
    echo -e "\nDocker信息："
    docker info
    
    read -p "按回车键返回..."
}

# 配置Docker网络选项
configure_docker_network_options() {
    clear
    echo "========== 配置Docker网络选项 =========="
    echo "1. 配置默认网络模式"
    echo "2. 配置网络子网"
    echo "3. 配置网络MTU"
    echo "4. 配置网络代理"
    echo "0. 返回上级菜单"
    
    read -p "请选择要配置的网络选项 [0-4]: " net_choice
    
    case $net_choice in
        1)
            echo "可用的网络模式："
            echo "1) bridge"
            echo "2) host"
            echo "3) none"
            read -p "请选择默认网络模式 [1-3]: " mode_choice
            case $mode_choice in
                1) net_mode="bridge";;
                2) net_mode="host";;
                3) net_mode="none";;
                *) echo "无效的选择"; return;;
            esac
            echo "{
  \"default-network-mode\": \"$net_mode\"
}" | sudo tee -a /etc/docker/daemon.json
            ;;
        2)
            read -p "请输入默认子网(例如:172.17.0.0/16): " subnet
            echo "{
  \"default-address-pools\": [
    {
      \"base\": \"$subnet\",
      \"size\": 24
    }
  ]
}" | sudo tee -a /etc/docker/daemon.json
            ;;
        3)
            read -p "请输入MTU值(例如:1500): " mtu
            echo "{
  \"mtu\": $mtu
}" | sudo tee -a /etc/docker/daemon.json
            ;;
        4)
            read -p "请输入HTTP代理地址: " http_proxy
            read -p "请输入HTTPS代理地址: " https_proxy
            read -p "请输入不使用代理的地址(用逗号分隔): " no_proxy
            mkdir -p /etc/systemd/system/docker.service.d/
            echo "[Service]
Environment=\"HTTP_PROXY=$http_proxy\"
Environment=\"HTTPS_PROXY=$https_proxy\"
Environment=\"NO_PROXY=$no_proxy\"" | sudo tee /etc/systemd/system/docker.service.d/proxy.conf
            ;;
        0)
            return
            ;;
        *)
            echo "无效的选择"
            return
            ;;
    esac
    
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "网络配置已更新"
    read -p "按回车键返回..."
}

# 配置存储驱动
configure_docker_storage_driver() {
    clear
    echo "========== 配置存储驱动 =========="
    echo "可用的存储驱动："
    echo "1. overlay2 (推荐)"
    echo "2. devicemapper"
    echo "3. btrfs (如果支持)"
    echo "4. zfs (如果支持)"
    echo "0. 返回上级菜单"
    
    read -p "请选择存储驱动 [0-4]: " driver_choice
    
    local storage_driver
    case $driver_choice in
        1) storage_driver="overlay2";;
        2) storage_driver="devicemapper";;
        3) storage_driver="btrfs";;
        4) storage_driver="zfs";;
        0) return;;
        *) 
            echo "无效的选择"
            return
            ;;
    esac
    
    echo "{
  \"storage-driver\": \"$storage_driver\"
}" | sudo tee -a /etc/docker/daemon.json
    
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "存储驱动配置已更新"
    read -p "按回车键返回..."
}

# 更新modify_docker_config函数
modify_docker_config() {
    while true; do
        clear
        echo "========== Docker配置修改 =========="
        echo "1. 配置镜像加速"
        echo "2. 修改存储目录"
        echo "3. 修改日志配置"
        echo "4. 配置容器DNS"
        echo "5. 配置容器默认时区"
        echo "6. 配置容器资源限制"
        echo "7. 配置网络选项"
        echo "8. 配置存储驱动"
        echo "9. 查看当前配置"
        echo "0. 返回上级菜单"
        echo "=================================="
        
        read -p "请输入您的选择 [0-9]: " config_choice
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
            5)
                configure_docker_timezone
                ;;
            6)
                configure_docker_resources
                ;;
            7)
                configure_docker_network_options
                ;;
            8)
                configure_docker_storage_driver
                ;;
            9)
                show_docker_config
                ;;
            0)
                return
                ;;
            *)
                echo "无效的选择"
                sleep 2
                ;;
        esac
    done
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
        read -p "请输入您的选择 [0-7]: " choice
        
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
            5)
                manage_dns_config
                ;;
            6)
                manage_routing_config
                ;;
            7)
                run_network_tests
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
        read -p "请输入您的选择 [0-9]: " choice
        
        case $choice in
            1)
                check_firewall_status
                ;;
            2)
                start_firewall
                ;;
            3)
                stop_firewall
                ;;
            4)
                configure_firewall_startup
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
            9)
                manage_firewall_rules
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
        read -p "请输入您的选择 [0-9]: " choice
        
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
                manage_volumes
                ;;
            7)
                clean_docker_system
                ;;
            8)
                modify_docker_config
                ;;
            9)
                manage_compose_projects
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
        echo "3. 取镜像"
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
        echo "8. 配置网络驱动"
        echo "9. 网络连接测试"
        echo "0. 返回上级菜单"
        echo "===================================="
        
        read -p "请输入您的选择 [0-9]: " choice
        case $choice in
            1)
                clear
                echo "Docker网络列表："
                docker network ls
                read -p "按回车键返回..."
                ;;
            2)
                clear
                read -p "请输入网络名称: " network_name
                read -p "请选择网络驱动(bridge/overlay/host/none): " driver
                if [ -n "$network_name" ]; then
                    docker network create --driver ${driver:-bridge} $network_name
                    echo "网络已创建"
                    log "创建Docker网络: $network_name"
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                echo "Docker网络列表："
                docker network ls
                read -p "请输入要删除的网络名称: " network_name
                if [ -n "$network_name" ]; then
                    docker network rm $network_name
                    echo "网络已删除"
                    log "删除Docker网络: $network_name"
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                echo "Docker网络列表："
                docker network ls
                read -p "请输入要查看的网络名称: " network_name
                if [ -n "$network_name" ]; then
                    docker network inspect $network_name
                fi
                read -p "按回车键返回..."
                ;;
            5)
                clear
                echo "Docker网络列表："
                docker network ls
                echo -e "\n容器列表："
                docker ps --format "table {{.ID}}\t{{.Names}}"
                read -p "请输入网络名称: " network_name
                read -p "请输入容器ID或名称: " container_name
                if [ -n "$network_name" ] && [ -n "$container_name" ]; then
                    docker network connect $network_name $container_name
                    echo "容器已连接到网络"
                    log "将容器 $container_name 连接到网络 $network_name"
                fi
                read -p "按回车键返回..."
                ;;
            6)
                clear
                echo "Docker网络列表："
                docker network ls
                echo -e "\n容器列表："
                docker ps --format "table {{.ID}}\t{{.Names}}"
                read -p "请输入网络名称: " network_name
                read -p "请输入容器ID或名称: " container_name
                if [ -n "$network_name" ] && [ -n "$container_name" ]; then
                    docker network disconnect $network_name $container_name
                    echo "容器已断开与网络的连接"
                    log "断开容器 $container_name 与网络 $network_name 的连接"
                fi
                read -p "按回车键返回..."
                ;;
            7)
                clear
                echo "正在清理未使用的网络..."
                docker network prune -f
                log "清理未使用的Docker网络"
                read -p "按回车键返回..."
                ;;
            8)
                clear
                echo "可用的网络驱动："
                echo "1. bridge (默认)"
                echo "2. overlay (Swarm模式)"
                echo "3. host"
                echo "4. none"
                read -p "请选择网络驱动 [1-4]: " driver_choice
                case $driver_choice in
                    1) driver="bridge";;
                    2) driver="overlay";;
                    3) driver="host";;
                    4) driver="none";;
                    *) echo "无效的选择"; return;;
                esac
                read -p "请输入网络名称: " network_name
                if [ -n "$network_name" ]; then
                    docker network create --driver $driver $network_name
                    echo "网络已创建"
                    log "创建Docker网络: $network_name (驱动: $driver)"
                fi
                read -p "按回车键返回..."
                ;;
            9)
                clear
                echo "容器列表："
                docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Networks}}"
                read -p "请输入源容器名称: " source_container
                read -p "请输入目标容器名称: " target_container
                if [ -n "$source_container" ] && [ -n "$target_container" ]; then
                    docker exec $source_container ping -c 4 $target_container
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
                echo "���在清理未使用的网络..."
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
                log "启用网络���口 $interface"
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
    echo "8. IP转发设置"
    echo "9. IP地址管理"
    echo "0. 返回上级菜单"
    echo "==============================="
    
    read -p "请输入您的选择 [0-9]: " choice
    case $choice in
        1)
            clear
            echo "IP���置信息："
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
        8)
            echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
            sudo sysctl -p
            echo "IPv4已启用"
            log "启用IPv4"
            read -p "按回车键返回..."
            ;;
        9)
            manage_ip_addresses
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

# 安装或更新Docker
install_update_docker() {
    clear
    echo "========== Docker安装/更新 =========="
    
    # 检���是��已安装Docker
    if command -v docker >/dev/null 2>&1; then
        current_version=$(docker --version | cut -d ' ' -f3 | tr -d ',')
        echo "当前Docker版本: $current_version"
        read -p "是否要更新Docker？(y/n): " update_choice
        if [[ $update_choice != "y" ]]; then
            return
        fi
    fi
    
    echo "正在安装/更新Docker..."
    # 使用官方安装脚本
    wget -qO- get.docker.com | bash
    
    # 启动Docker服务
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 安装Docker Compose
    echo "正在安装Docker Compose..."
    compose_version="v2.30.1"
    sudo curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 配置用户组
    sudo groupadd docker 2>/dev/null
    sudo usermod -aG docker $USER
    
    # 配置镜像加速
    echo "是否配置国内镜像加速？(y/n): "
    read -p "选择: " mirror_choice
    if [[ $mirror_choice == "y" ]]; then
        configure_docker_mirror
    fi
    
    echo -e "\n安装完成！"
    echo "Docker版本：" $(docker --version)
    echo "Docker Compose版本：" $(docker-compose --version)
    echo -e "\n注意：可能需要重新登录才能使用docker组权限"
    read -p "回车键返回..."
}

# 防火墙管理相关函数
# 启动防火墙
start_firewall() {
    clear
    echo "============ 开启防火墙 ============"
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw enable
        echo "UFW防火墙已开启"
        log "开��UFW防火墙"
    elif command -v firewalld >/dev/null 2>&1; then
        sudo systemctl start firewalld
        sudo systemctl enable firewalld
        echo "FirewallD防火墙已开启"
        log "开启FirewallD防火墙"
    else
        echo "未检测到支持的防火墙服务"
    fi
    read -p "按回车键返回..."
}

# 停止防火墙
stop_firewall() {
    clear
    echo "============ 关闭防火墙 ============"
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw disable
        echo "UFW防火墙已关闭"
        log "关闭UFW防火墙"
    elif command -v firewalld >/dev/null 2>&1; then
        sudo systemctl stop firewalld
        echo "FirewallD防火墙已关闭"
        log "关闭FirewallD防火墙"
    else
        echo "未检测到支持的防火墙服务"
    fi
    read -p "按回车键返回..."
}

# 禁用防火墙开机���动
disable_firewall() {
    clear
    echo "============ 禁用防火墙开机启动 ============"
    if command -v ufw >/dev/null 2>&1; then
        sudo systemctl disable ufw
        echo "UFW防火墙开机启动已禁用"
        log "禁用UFW防火墙开机启动"
    elif command -v firewalld >/dev/null 2>&1; then
        sudo systemctl disable firewalld
        echo "FirewallD防火墙开机启动已禁用"
        log "禁用FirewallD防火墙开机启动"
    else
        echo "未检测到支持的防火墙服务"
    fi
    read -p "按回车键返回..."
}

# 开放端口
open_port() {
    clear
    echo "============ ���放端口 ============"
    read -p "请输入要开放的端口号: " port
    read -p "请选择协议类型 (tcp/udp/both): " protocol
    
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "无效的端口号！端口号必须在1-65535之间"
        read -p "按回车键返回..."
        return
    fi
    
    if command -v ufw >/dev/null 2>&1; then
        case $protocol in
            tcp)
                sudo ufw allow $port/tcp
                log "UFW开放TCP端口 $port"
                ;;
            udp)
                sudo ufw allow $port/udp
                log "UFW开放UDP端口 $port"
                ;;
            both)
                sudo ufw allow $port
                log "UFW开放TCP/UDP端口 $port"
                ;;
            *)
                echo "无效的协议类型！"
                read -p "按回车键返回..."
                return
                ;;
        esac
        echo "端口已开放"
    elif command -v firewalld >/dev/null 2>&1; then
        case $protocol in
            tcp)
                sudo firewall-cmd --permanent --add-port=$port/tcp
                log "FirewallD开放TCP端口 $port"
                ;;
            udp)
                sudo firewall-cmd --permanent --add-port=$port/udp
                log "FirewallD开放UDP端口 $port"
                ;;
            both)
                sudo firewall-cmd --permanent --add-port=$port/tcp
                sudo firewall-cmd --permanent --add-port=$port/udp
                log "FirewallD开放TCP/UDP端口 $port"
                ;;
            *)
                echo "无效的协议类���！"
                read -p "按回车键返回..."
                return
                ;;
        esac
        sudo firewall-cmd --reload
        echo "端口已开放"
    else
        echo "未检测到支持的防火墙服务"
    fi
    read -p "按回车键返回..."
}

# 关闭端口
close_port() {
    clear
    echo "============ 关闭端口 ============"
    read -p "请输入要关闭的端口号: " port
    read -p "请选择协议类型 (tcp/udp/both): " protocol
    
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "无效的端口号！端口号必须在1-65535之间"
        read -p "按回车键返回..."
        return
    fi
    
    if command -v ufw >/dev/null 2>&1; then
        case $protocol in
            tcp)
                sudo ufw deny $port/tcp
                sudo ufw delete allow $port/tcp
                log "UFW关闭TCP端口 $port"
                ;;
            udp)
                sudo ufw deny $port/udp
                sudo ufw delete allow $port/udp
                log "UFW关闭UDP端口 $port"
                ;;
            both)
                sudo ufw deny $port
                sudo ufw delete allow $port
                log "UFW关闭TCP/UDP端口 $port"
                ;;
            *)
                echo "无效的协议类型！"
                read -p "按回车键返回..."
                return
                ;;
        esac
        echo "端口已关闭"
    elif command -v firewalld >/dev/null 2>&1; then
        case $protocol in
            tcp)
                sudo firewall-cmd --permanent --remove-port=$port/tcp
                log "FirewallD关闭TCP端口 $port"
                ;;
            udp)
                sudo firewall-cmd --permanent --remove-port=$port/udp
                log "FirewallD关闭UDP端口 $port"
                ;;
            both)
                sudo firewall-cmd --permanent --remove-port=$port/tcp
                sudo firewall-cmd --permanent --remove-port=$port/udp
                log "FirewallD关闭TCP/UDP端口 $port"
                ;;
            *)
                echo "无效的协议类型！"
                read -p "按回车键返回..."
                return
                ;;
        esac
        sudo firewall-cmd --reload
        echo "端口已关闭"
    else
        echo "未检测到支持的防火墙服务"
    fi
    read -p "按回车键返回..."
}

# 查看已开放端口
list_open_ports() {
    clear
    echo "============ 已开放端口列表 ============"
    if command -v ufw >/dev/null 2>&1; then
        echo "UFW防火墙规则："
        sudo ufw status numbered
    elif command -v firewalld >/dev/null 2>&1; then
        echo "FirewallD防火墙规则："
        echo "TCP端口："
        sudo firewall-cmd --list-ports | tr ' ' '\n' | grep tcp
        echo "UDP端口���"
        sudo firewall-cmd --list-ports | tr ' ' '\n' | grep udp
        echo -e "\n防火墙区域配置："
        sudo firewall-cmd --list-all
    else
        echo "未检测到支持的防火墙服务"
    fi
    
    echo -e "\n当前系统监听端口："
    echo "TCP端口："
    netstat -tuln | grep "LISTEN"
    echo -e "\nUDP端口："
    netstat -tuln | grep "UDP"
    
    read -p "按回车键返回..."
}

# 用户管理功能
user_management() {
    while true; do
        clear
        echo "========== 用户管理 =========="
        echo "1. 查看所有用户"
        echo "2. 添加用户"
        echo "3. 删除用户"
        echo "4. 修改用户密码"
        echo "5. 修改用户权限"
        echo "6. 查看用户详情"
        echo "0. 返回上级菜单"
        echo "=============================="
        
        read -p "请输入您的选择 [0-6]: " choice
        case $choice in
            1)
                clear
                echo "系统用户列表："
                cat /etc/passwd | cut -d: -f1,3,6,7
                read -p "按回车键返回..."
                ;;
            2)
                clear
                read -p "请输入要添加的用户名: " username
                if [ -n "$username" ]; then
                    read -p "是否创建家目录？(y/n): " create_home
                    if [[ $create_home == "y" ]]; then
                        sudo useradd -m $username
                    else
                        sudo useradd $username
                    fi
                    sudo passwd $username
                    echo "用户已添加"
                    log "添加用户 $username"
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                read -p "请输入要删除的用户名: " username
                if [ -n "$username" ]; then
                    read -p "是否删除用户家目录？(y/n): " del_home
                    if [[ $del_home == "y" ]]; then
                        sudo userdel -r $username
                    else
                        sudo userdel $username
                    fi
                    echo "用户已删除"
                    log "删除用户 $username"
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                read -p "请输入要修改密码的用户名: " username
                if [ -n "$username" ]; then
                    sudo passwd $username
                    log "修改用户 $username 的密码"
                fi
                read -p "按回车键返回..."
                ;;
            5)
                clear
                read -p "请输入要修改权限的用户名: " username
                if [ -n "$username" ]; then
                    read -p "是否添加sudo权限？(y/n): " add_sudo
                    if [[ $add_sudo == "y" ]]; then
                        sudo usermod -aG sudo $username
                        echo "已添加sudo权限"
                    else
                        sudo gpasswd -d $username sudo
                        echo "已移除sudo权限"
                    fi
                    log "修改用户 $username 的权限"
                fi
                read -p "按回车键返回..."
                ;;
            6)
                clear
                read -p "请输入要查看的用户名: " username
                if [ -n "$username" ]; then
                    echo "用户信息："
                    id $username
                    echo -e "\n用户组："
                    groups $username
                    echo -e "\n登录记录："
                    last $username | head -n 5
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

# 时区管理功能
manage_timezone() {
    while true; do
        clear
        echo "========== 时区管理 =========="
        echo "1. 查看当前时区"
        echo "2. 修改系统时区"
        echo "3. 同步系统时间"
        echo "4. 修改时间格式"
        echo "0. 返回上级菜单"
        echo "=============================="
        
        read -p "请输入您的选择 [0-4]: " choice
        case $choice in
            1)
                clear
                echo "当前时区信息："
                timedatectl
                read -p "按回车键返回..."
                ;;
            2)
                clear
                echo "可用的时区列表："
                timedatectl list-timezones | grep "Asia"
                read -p "请输入要设置的时区(例如:Asia/Shanghai): " timezone
                if [ -n "$timezone" ]; then
                    sudo timedatectl set-timezone $timezone
                    echo "时区已更新"
                    log "修改系统时区为 $timezone"
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                echo "正在同步系统时间..."
                sudo ntpdate pool.ntp.org || sudo hwclock --systohc
                echo "时间同步完成"
                log "同步系统时间"
                read -p "按回车键返回..."
                ;;
            4)
                clear
                echo "1. 12小时制"
                echo "2. 24小时制"
                read -p "请选择时间格式 [1-2]: " format
                if [ "$format" == "1" ]; then
                    sudo timedatectl set-local-rtc 1
                else
                    sudo timedatectl set-local-rtc 0
                fi
                echo "时间格式已更新"
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

# 主机管理功能
manage_hosts() {
    while true; do
        clear
        echo "========== 主机管理 =========="
        echo "1. 查看主机名"
        echo "2. 修改主机名"
        echo "3. 查看hosts文件"
        echo "4. 编辑hosts文件"
        echo "5. 备份hosts文件"
        echo "6. 恢复hosts文件"
        echo "0. 返回上级菜单"
        echo "=============================="
        
        read -p "请��入您的选择 [0-6]: " choice
        case $choice in
            1)
                clear
                echo "当前主机名："
                hostname
                echo -e "\n主机信息："
                hostnamectl
                read -p "按回车键返回..."
                ;;
            2)
                clear
                read -p "请输入新的主机名: " new_hostname
                if [ -n "$new_hostname" ]; then
                    sudo hostnamectl set-hostname $new_hostname
                    echo "主机名已更新"
                    log "修改主机名为 $new_hostname"
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                echo "hosts文��内容："
                cat /etc/hosts
                read -p "按回车键返回..."
                ;;
            4)
                clear
                sudo nano /etc/hosts
                log "编辑hosts文件"
                read -p "按回车键返回..."
                ;;
            5)
                clear
                sudo cp /etc/hosts /etc/hosts.bak
                echo "hosts文件已备份为 /etc/hosts.bak"
                log "备份hosts文件"
                read -p "按回车键返回..."
                ;;
            6)
                clear
                if [ -f "/etc/hosts.bak" ]; then
                    sudo cp /etc/hosts.bak /etc/hosts
                    echo "hosts文件已恢复"
                    log "恢复hosts文件"
                else
                    echo "未找到备份文件"
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

# 交换分区管理功能
manage_swap() {
    while true; do
        clear
        echo "========== 交换分管理 =========="
        echo "1. 查看Swap状态"
        echo "2. 创建Swap文件"
        echo "3. 启用Swap"
        echo "4. 关闭Swap"
        echo "5. 调整Swap大小"
        echo "6. 删除Swap文件"
        echo "7. 修改Swap优先级"
        echo "0. 返回上级菜单"
        echo "=================================="
        
        read -p "请输入您的选择 [0-7]: " choice
        case $choice in
            1)
                clear
                echo "Swap使用情况："
                free -h | grep Swap
                echo -e "\nSwap详细信息："
                swapon --show
                echo -e "\nSwap优先级："
                cat /proc/swaps
                read -p "按回车键返回..."
                ;;
            2)
                clear
                read -p "请输入Swap文件大小(GB): " swap_size
                read -p "请输入Swap文件路径(默认:/swapfile): " swap_path
                swap_path=${swap_path:-/swapfile}
                
                if [ -n "$swap_size" ]; then
                    echo "正在创建Swap文件..."
                    sudo fallocate -l ${swap_size}G $swap_path
                    sudo chmod 600 $swap_path
                    sudo mkswap $swap_path
                    echo "Swap文件创建完成"
                    log "创建${swap_size}G的Swap文件"
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                read -p "请输入要启用的Swap文件路径: " swap_path
                if [ -f "$swap_path" ]; then
                    sudo swapon $swap_path
                    echo "Swap已启用"
                    log "启用Swap文件 $swap_path"
                else
                    echo "Swap文件不存在"
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                read -p "请输入要关闭的Swap文件路径: " swap_path
                if [ -f "$swap_path" ]; then
                    sudo swapoff $swap_path
                    echo "Swap已关闭"
                    log "关闭Swap文件 $swap_path"
                else
                    echo "Swap文件不存在"
                fi
                read -p "按回车键返回..."
                ;;
            5)
                clear
                read -p "请输入要调整的Swap文件路径: " swap_path
                read -p "请输入新的大小(GB): " new_size
                if [ -f "$swap_path" ] && [ -n "$new_size" ]; then
                    sudo swapoff $swap_path
                    sudo fallocate -l ${new_size}G $swap_path
                    sudo mkswap $swap_path
                    sudo swapon $swap_path
                    echo "Swap大小已调整"
                    log "调整Swap文件 $swap_path 大小为 ${new_size}G"
                fi
                read -p "按回车键返回..."
                ;;
            6)
                clear
                read -p "请输入要删除的Swap文件路径: " swap_path
                if [ -f "$swap_path" ]; then
                    sudo swapoff $swap_path
                    sudo rm $swap_path
                    echo "Swap文件已删除"
                    log "删除Swap文件 $swap_path"
                else
                    echo "Swap文件不存在"
                fi
                read -p "按回车键返回..."
                ;;
            7)
                clear
                read -p "请输入Swap文件路径: " swap_path
                read -p "请输入优先级(-1到32767): " priority
                if [ -f "$swap_path" ] && [ -n "$priority" ]; then
                    sudo swapoff $swap_path
                    sudo swapon $swap_path -p $priority
                    echo "Swap优先级已修��"
                    log "修改Swap文件 $swap_path 优先级为 $priority"
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

# 6. 主程序函数
main() {
    # 检查并安装必要工具
    check_and_install_tools
    
    # 主程序循环
    while true; do
        show_menu
        read -p "请输入您的选择 [0-6]: " choice
        
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

# DNS配置管理
manage_dns_config() {
    while true; do
        clear
        echo "========== DNS配置管理 =========="
        echo "1. 查看当前DNS配置"
        echo "2. 修改DNS服务器"
        echo "3. 添加DNS服务器"
        echo "4. 备份DNS配置"
        echo "5. 恢复DNS配置"
        echo "0. 返回上级菜单"
        echo "================================="
        
        read -p "请输入您的选择 [0-5]: " choice
        case $choice in
            1)
                clear
                echo "当前DNS配置："
                cat /etc/resolv.conf
                read -p "按回车键返回..."
                ;;
            2)
                clear
                echo "当前DNS配置："
                cat /etc/resolv.conf
                echo -e "\n请输入新的DNS服务器地址（每行一个，输入空行结束）："
                sudo cp /etc/resolv.conf /etc/resolv.conf.bak
                echo -n > /tmp/new_resolv.conf
                while true; do
                    read -p "DNS服务器: " dns_server
                    if [ -z "$dns_server" ]; then
                        break
                    fi
                    echo "nameserver $dns_server" >> /tmp/new_resolv.conf
                done
                sudo mv /tmp/new_resolv.conf /etc/resolv.conf
                echo "DNS配置已更新"
                log "修改DNS配置"
                read -p "按回车键返回..."
                ;;
            3)
                clear
                read -p "请输入要添加的DNS服务器地址: " dns_server
                if [ -n "$dns_server" ]; then
                    echo "nameserver $dns_server" | sudo tee -a /etc/resolv.conf
                    echo "DNS服务器已添加"
                    log "添加DNS服务器 $dns_server"
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                sudo cp /etc/resolv.conf /etc/resolv.conf.bak
                echo "DNS配置已备份为 /etc/resolv.conf.bak"
                log "备份DNS配置"
                read -p "按回车键返回..."
                ;;
            5)
                clear
                if [ -f "/etc/resolv.conf.bak" ]; then
                    sudo cp /etc/resolv.conf.bak /etc/resolv.conf
                    echo "DNS配置已恢复"
                    log "恢复DNS配置"
                else
                    echo "未找到备份文件"
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

# 路由管理
manage_routing_config() {
    while true; do
        clear
        echo "========== 路由管理 =========="
        echo "1. 查看路由表"
        echo "2. 添加静态路由"
        echo "3. 删除静态路由"
        echo "4. 修改默认网关"
        echo "5. 查���路由跟踪"
        echo "0. 返回上级菜单"
        echo "=============================="
        
        read -p "请输入您的选择 [0-5]: " choice
        case $choice in
            1)
                clear
                echo "当前路由表："
                ip route show
                read -p "按回车键返回..."
                ;;
            2)
                clear
                read -p "请输入目标网络(例如:192.168.1.0/24): " network
                read -p "请输入网关地址: " gateway
                read -p "请输入网络接口: " interface
                if [ -n "$network" ] && [ -n "$gateway" ] && [ -n "$interface" ]; then
                    sudo ip route add $network via $gateway dev $interface
                    echo "静态路由已添加"
                    log "添加静态路由 $network via $gateway"
                fi
                read -p "按��车键返回..."
                ;;
            3)
                clear
                echo "当前路由表："
                ip route show
                read -p "请输入要删除的路由网络: " network
                if [ -n "$network" ]; then
                    sudo ip route del $network
                    echo "路由已删除"
                    log "删除路由 $network"
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                read -p "请输入新的默认网关: " gateway
                if [ -n "$gateway" ]; then
                    sudo ip route replace default via $gateway
                    echo "默认网关已更新"
                    log "修改默认网关为 $gateway"
                fi
                read -p "按回车键返回..."
                ;;
            5)
                clear
                read -p "请输入要跟踪的目标地址: " target
                if [ -n "$target" ]; then
                    traceroute $target
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

# 网络测试工具
run_network_tests() {
    while true; do
        show_network_tools_menu
        read -p "请输入您的选择 [0-7]: " choice
        case $choice in
            1)
                clear
                read -p "请输入目标地址: " target
                if [ -n "$target" ]; then
                    ping -c 4 $target
                fi
                read -p "按回车键返回..."
                ;;
            2)
                clear
                read -p "请输入目标地址: " target
                if [ -n "$target" ]; then
                    traceroute $target
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                read -p "请输入要查询的域名: " domain
                if [ -n "$domain" ]; then
                    nslookup $domain
                    echo -e "\ndig查询结果："
                    dig $domain
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                read -p "请输入目标地址: " target
                read -p "请输入端口范围(例如:80-100): " ports
                if [ -n "$target" ] && [ -n "$ports" ]; then
                    nmap -p$ports $target
                fi
                read -p "按回车键返回..."
                ;;
            5)
                clear
                echo "正在测试网络带宽..."
                if ! command -v speedtest-cli >/dev/null 2>&1; then
                    echo "正在安装speedtest-cli..."
                    sudo apt-get install -y speedtest-cli || sudo yum install -y speedtest-cli
                fi
                speedtest-cli
                read -p "按回车键返回..."
                ;;
            6)
                clear
                echo "网络连接状态："
                netstat -tuln
                echo -e "\n活动连接："
                ss -s
                read -p "按回车键返回..."
                ;;
            7)
                clear
                if ! command -v tcpdump >/dev/null 2>&1; then
                    echo "正在安装tcpdump..."
                    sudo apt-get install -y tcpdump || sudo yum install -y tcpdump
                fi
                read -p "请输入要监听的接口(默认eth0): " interface
                interface=${interface:-eth0}
                echo "开始抓包(Ctrl+C停止)..."
                sudo tcpdump -i $interface -n
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

# Docker Compose管理
manage_compose_projects() {
    while true; do
        clear
        echo "========== Docker Compose管理 =========="
        echo "1. 查看运行中的项目"
        echo "2. 启动项目"
        echo "3. 停止项目"
        echo "4. 重启项目"
        echo "5. 查看项目日志"
        echo "6. 更新项目镜像"
        echo "7. 删除项目"
        echo "8. 查看项目配置"
        echo "0. 返回上级菜单"
        echo "====================================="
        
        read -p "请输入您的选择 [0-8]: " choice
        case $choice in
            1)
                clear
                echo "运行中的Docker Compose项目："
                docker-compose ls
                read -p "按回车键返回..."
                ;;
            2)
                clear
                read -p "请输入docker-compose.yml所在目录: " compose_dir
                if [ -d "$compose_dir" ]; then
                    cd "$compose_dir"
                    docker-compose up -d
                    echo "项目已启动"
                    log "启动Docker Compose项目: $compose_dir"
                else
                    echo "目录不存在"
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                read -p "请输入docker-compose.yml所在目录: " compose_dir
                if [ -d "$compose_dir" ]; then
                    cd "$compose_dir"
                    docker-compose down
                    echo "项目已停止"
                    log "停止Docker Compose项目: $compose_dir"
                else
                    echo "目录不存在"
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                read -p "请输入docker-compose.yml所在目录: " compose_dir
                if [ -d "$compose_dir" ]; then
                    cd "$compose_dir"
                    docker-compose restart
                    echo "项目已重启"
                    log "重启Docker Compose项目: $compose_dir"
                else
                    echo "目录不存在"
                fi
                read -p "按回车键返回..."
                ;;
            5)
                clear
                read -p "请输入docker-compose.yml所在目录: " compose_dir
                if [ -d "$compose_dir" ]; then
                    cd "$compose_dir"
                    docker-compose logs --tail=100 -f
                fi
                read -p "按回车键返回..."
                ;;
            6)
                clear
                read -p "请输��docker-compose.yml所在目录: " compose_dir
                if [ -d "$compose_dir" ]; then
                    cd "$compose_dir"
                    docker-compose pull
                    docker-compose up -d
                    echo "项目已更新"
                    log "更新Docker Compose项目: $compose_dir"
                else
                    echo "目录不存在"
                fi
                read -p "按回车键返回..."
                ;;
            7)
                clear
                read -p "请输入docker-compose.yml所在目录: " compose_dir
                if [ -d "$compose_dir" ]; then
                    cd "$compose_dir"
                    docker-compose down -v
                    echo "项目已删除"
                    log "删除Docker Compose项目: $compose_dir"
                else
                    echo "目录不存在"
                fi
                read -p "按回车键返回..."
                ;;
            8)
                clear
                read -p "请输入docker-compose.yml所在目录: " compose_dir
                if [ -d "$compose_dir" ]; then
                    cd "$compose_dir"
                    docker-compose config
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

# 数据卷管理
manage_volumes() {
    while true; do
        clear
        echo "========== 数据卷管理 =========="
        echo "1. 查看所有数据卷"
        echo "2. 创建数据卷"
        echo "3. 删除数据卷"
        echo "4. 清理未使用数据卷"
        echo "5. 查看数据卷详情"
        echo "6. 备份数据卷"
        echo "7. 恢复数据卷"
        echo "0. 返回上级菜单"
        echo "================================"
        
        read -p "请输入您的选择 [0-7]: " choice
        case $choice in
            1)
                clear
                echo "数据卷列表："
                docker volume ls
                read -p "按回车键返回..."
                ;;
            2)
                clear
                read -p "请输入数据卷名称: " volume_name
                if [ -n "$volume_name" ]; then
                    docker volume create $volume_name
                    echo "数据卷已创建"
                    log "创建数据卷: $volume_name"
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                echo "数据卷列表："
                docker volume ls
                read -p "请输入要删除的数据卷名称: " volume_name
                if [ -n "$volume_name" ]; then
                    docker volume rm $volume_name
                    echo "数据卷已删除"
                    log "删除数据卷: $volume_name"
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                echo "正在清理未使用的数据卷..."
                docker volume prune -f
                log "清理未使用的数据卷"
                read -p "按回车键返回..."
                ;;
            5)
                clear
                echo "数据卷列表："
                docker volume ls
                read -p "请输入要查看的数据卷名称: " volume_name
                if [ -n "$volume_name" ]; then
                    docker volume inspect $volume_name
                fi
                read -p "按回车键返回..."
                ;;
            6)
                clear
                read -p "请输入要备份的数据卷名称: " volume_name
                read -p "请输入备份文件路径: " backup_path
                if [ -n "$volume_name" ] && [ -n "$backup_path" ]; then
                    docker run --rm -v $volume_name:/source -v $(dirname $backup_path):/backup alpine tar czf /backup/$(basename $backup_path) -C /source .
                    echo "数据卷已备份到: $backup_path"
                    log "备份数据卷 $volume_name 到 $backup_path"
                fi
                read -p "按回车键���回..."
                ;;
            7)
                clear
                read -p "请输入要恢复的数据卷名称: " volume_name
                read -p "请输入备份文件路径: " backup_path
                if [ -n "$volume_name" ] && [ -n "$backup_path" ]; then
                    docker run --rm -v $volume_name:/target -v $(dirname $backup_path):/backup alpine sh -c "cd /target && tar xzf /backup/$(basename $backup_path)"
                    echo "数据卷已恢复"
                    log "恢复数据卷 $volume_name 从 $backup_path"
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

# 系统配置管理函数
system_config() {
    while true; do
        show_system_config_menu
        read -p "请输入您的选择 [0-8]: " choice
        
        case $choice in
            1)
                user_management
                ;;
            2)
                manage_timezone
                ;;
            3)
                manage_hosts
                ;;
            4)
                manage_swap
                ;;
            5)
                manage_network_acceleration
                ;;
            6)
                manage_system_services
                ;;
            7)
                manage_system_update
                ;;
            8)
                manage_packages
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

# 网络加速管理
manage_network_acceleration() {
    while true; do
        clear
        echo "========== 网络加速管理 =========="
        echo "1. 安装BBR"
        echo "2. 查看当前拥塞控制算法"
        echo "3. 切换TCP拥塞控制算法"
        echo "4. 优化网络参数"
        echo "5. 还原默认设置"
        echo "0. 返回上级菜单"
        echo "=================================="
        
        read -p "请输入您的选择 [0-5]: " choice
        case $choice in
            1)
                install_bbr
                ;;
            2)
                show_congestion_control
                ;;
            3)
                change_congestion_control
                ;;
            4)
                optimize_network
                ;;
            5)
                restore_network_defaults
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

# 系统服务管理
manage_system_services() {
    while true; do
        clear
        echo "========== 系统服务管理 =========="
        echo "1. 查看所有服务"
        echo "2. 启动服务"
        echo "3. 停止服务"
        echo "4. 重启服务"
        echo "5. 设置服务开机启动"
        echo "6. 禁用服务开机启动"
        echo "7. 查看服务状态"
        echo "8. 查看服务日志"
        echo "0. 返回上级菜单"
        echo "=================================="
        
        read -p "请输入您的选择 [0-8]: " choice
        case $choice in
            1)
                list_services
                ;;
            2)
                start_service
                ;;
            3)
                stop_service
                ;;
            4)
                restart_service
                ;;
            5)
                enable_service
                ;;
            6)
                disable_service
                ;;
            7)
                show_service_status
                ;;
            8)
                view_service_logs
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

# 系统更新管理
manage_system_update() {
    while true; do
        clear
        echo "========== 系统更新管理 =========="
        echo "1. 更新软件包列表"
        echo "2. 更新所有软件包"
        echo "3. 自动移除无用软件包"
        echo "4. 清理软件包缓存"
        echo "5. 查看可更新的软件包"
        echo "6. 设置自动更新"
        echo "0. 返回上级菜单"
        echo "=================================="
        
        read -p "请输入您的选择 [0-6]: " choice
        case $choice in
            1)
                update_package_list
                ;;
            2)
                upgrade_packages
                ;;
            3)
                autoremove_packages
                ;;
            4)
                clean_package_cache
                ;;
            5)
                show_upgradable_packages
                ;;
            6)
                configure_auto_update
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

# 检查并安装必要的软件包
install_required_packages() {
    local packages=("$@")
    for package in "${packages[@]}"; do
        if ! command -v $package >/dev/null 2>&1; then
            echo "正在安装 $package..."
            if [ "$PKG_MANAGER" = "apt-get" ]; then
                sudo apt-get install -y $package
            elif [ "$PKG_MANAGER" = "yum" ]; then
                sudo yum install -y $package
            elif [ "$PKG_MANAGER" = "dnf" ]; then
                sudo dnf install -y $package
            fi
        fi
    done
}

# 备份配置文件
backup_config() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        sudo cp "$config_file" "${config_file}.bak.$(date +%Y%m%d%H%M%S)"
        echo "已备份配置文件: ${config_file}.bak.$(date +%Y%m%d%H%M%S)"
        return 0
    else
        echo "配置文件不存在: $config_file"
        return 1
    fi
}

# 检查命令执行结果
check_command_status() {
    if [ $? -eq 0 ]; then
        echo "操作成功"
        return 0
    else
        echo "操作失败"
        return 1
    fi
}
