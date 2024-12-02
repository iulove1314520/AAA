#!/bin/bash

###################
# 基础配置
###################

# 版本信息
VERSION="1.0.1"
SCRIPT_NAME="系统管理脚本"

# 配置文件路径
CONFIG_FILE="/etc/manage_script.conf"
LOG_FILE="/var/log/manage_script.log"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m'

###################
# 基础工具函数
###################

# 日志函数
log() {
    local level=$1
    shift
    local message=$@
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

# 消息打印函数
print_message() { 
    echo -e "${GREEN}[INFO] $1${NC}"
    log "INFO" "$1"
}

print_warning() { 
    echo -e "${YELLOW}[WARN] $1${NC}"
    log "WARN" "$1"
}

print_error() { 
    echo -e "${RED}[ERROR] $1${NC}"
    log "ERROR" "$1"
}

# 等待用户输入
wait_for_key() {
    echo
    read -n 1 -s -r -p "按任意键继续..."
    echo
}

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 sudo 或 root 权限运行此脚本"
        exit 1
    fi
}

# 检查系统类型
check_system_type() {
    if [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# 安装依赖包
install_package() {
    local package=$1
    local system_type=$(check_system_type)
    
    print_message "正在安装 $package..."
    
    case $system_type in
        debian)
            apt-get update
            apt-get install -y "$package"
            ;;
        redhat)
            yum install -y "$package"
            ;;
        *)
            print_error "不支持的系统类型"
            return 1
            ;;
    esac
}

# 备份文件
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_file"
        print_message "已备份文件到: $backup_file"
        return 0
    else
        print_error "文件不存在: $file"
        return 1
    fi
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if netstat -tuln | grep -q ":$port "; then
        return 0
    else
        return 1
    fi
}

# 获取系统信息
get_system_info() {
    {
        echo "系统信息："
        echo "----------------"
        echo "主机名: $(hostname)"
        echo "系统版本: $(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)"
        echo "内核版本: $(uname -r)"
        echo "CPU信息: $(grep "model name" /proc/cpuinfo | head -n1 | cut -d: -f2)"
        echo "CPU核心数: $(nproc)"
        echo "内存总量: $(free -h | awk '/^Mem:/{print $2}')"
        echo "磁盘使用情况:"
        df -h
    } > "/tmp/system_info.txt"
    
    cat "/tmp/system_info.txt"
    rm -f "/tmp/system_info.txt"
}

# 初始化函数
init() {
    echo -e "${GREEN}[INFO] 正在初始化...${NC}"
    
    # 创建必要的目录
    mkdir -p /var/log/manage_script
    mkdir -p /etc/manage_script
    mkdir -p /backup
    
    # 检查并创建配置文件
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" <<EOF
# 系统管理脚本配置文件
BACKUP_DIR="/backup"
LOG_LEVEL="INFO"
MAX_LOG_SIZE="100M"
EOF
    fi
    
    # 检查必要的命令
    local required_commands=(
        "curl"
        "wget"
        "netstat"
        "ss"
        "tar"
        "gzip"
    )
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${YELLOW}[WARN] 正在安装 $cmd...${NC}"
            install_package "$cmd"
        fi
    done
    
    echo -e "${GREEN}[INFO] 初始化完成${NC}"
}

# 清理函数
cleanup() {
    echo -e "${GREEN}[INFO] 正在清理...${NC}"
    # 清理临时文件
    rm -f /tmp/manage_script_*
    # 恢复终端设置
    stty echo
}

# 错误处理函数
error_handler() {
    local line_number=$1
    local error_code=$2
    echo -e "${RED}[ERROR] 脚本执行出错，行号: $line_number，错误代码: $error_code${NC}" >&2
    exit 1
}

# 设置错误处理
set -e
trap 'error_handler ${LINENO} $?' ERR
trap cleanup EXIT
trap 'echo -e "${YELLOW}[WARN] 收到中断信号，正在清理...${NC}"; cleanup; exit 1' INT TERM

###################
# 系统管理函数
###################

# 系统基本配置菜单
system_basic_config_menu() {
    while true; do
        clear
        echo -e "${BLUE}系统基本配置${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择操作："
        echo "1) 主机名设置"
        echo "2) 时区设置"
        echo "3) hosts文件管理"
        echo "4) 用户管理"
        echo "5) 软件源管理"
        echo "6) 系统环境变量"
        echo "7) 开机启动项"
        echo "8) 返回上级菜单"
        echo
        read -p "请输入选项 [1-8]: " choice

        case $choice in
            1) modify_hostname ;;
            2) set_timezone ;;
            3) manage_hosts ;;
            4) user_management ;;
            5) change_mirrors ;;
            6) manage_environment ;;
            7) manage_startup ;;
            8) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
    done
}

# 时区设置函数
set_timezone() {
    clear
    echo -e "${BLUE}时区设置${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    echo "当前时区: $(timedatectl | grep "Time zone")"
    echo
    echo "常用时区："
    echo "1) 亚洲/上海 (UTC+8)"
    echo "2) 亚洲/东京 (UTC+9)"
    echo "3) 美国/纽约 (UTC-5)"
    echo "4) 欧洲/伦敦 (UTC+0)"
    echo "5) 手动输入时区"
    echo
    read -p "请选择时区 [1-5]: " choice

    case $choice in
        1) timezone="Asia/Shanghai" ;;
        2) timezone="Asia/Tokyo" ;;
        3) timezone="America/New_York" ;;
        4) timezone="Europe/London" ;;
        5)
            timedatectl list-timezones
            read -p "请输入时区名称: " timezone
            ;;
        *)
            print_error "无效的选项"
            return 1
            ;;
    esac

    if timedatectl set-timezone "$timezone"; then
        print_message "时区已设置为: $timezone"
        
        # 同步时间
        if ! check_command "chrony"; then
            install_package "chrony"
        fi
        
        systemctl start chronyd
        systemctl enable chronyd
        chronyc makestep
        
        print_message "系统时间已同步"
    else
        print_error "时区设置失败"
    fi
}

# 系统环境变量管理
manage_environment() {
    while true; do
        clear
        echo -e "${BLUE}系统环境变量管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "当前环境变量："
        env | sort
        echo
        echo "请选择操作："
        echo "1) 添加环境变量"
        echo "2) 修改环境变量"
        echo "3) 删除环境变量"
        echo "4) 查看特定环境变量"
        echo "5) 返回上级菜单"
        echo
        read -p "请输入选项 [1-5]: " choice

        case $choice in
            1)
                read -p "请输入变量名: " var_name
                read -p "请输入变量值: " var_value
                echo "export $var_name=$var_value" >> /etc/profile.d/custom.sh
                source /etc/profile.d/custom.sh
                print_message "环境变量已添加"
                ;;
            2)
                read -p "请输入要修改的变量名: " var_name
                read -p "请输入新的变量值: " var_value
                sed -i "/^export $var_name=/c\export $var_name=$var_value" /etc/profile.d/custom.sh
                source /etc/profile.d/custom.sh
                print_message "环境变量已修改"
                ;;
            3)
                read -p "请输入要删除的变量名: " var_name
                sed -i "/^export $var_name=/d" /etc/profile.d/custom.sh
                unset "$var_name"
                print_message "环境变量已删除"
                ;;
            4)
                read -p "请输入要查看的变量名: " var_name
                echo "$var_name = ${!var_name}"
                ;;
            5) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

# 开机启动项管理
manage_startup() {
    while true; do
        clear
        echo -e "${BLUE}开机启动项管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "系统服务启动项："
        systemctl list-unit-files --type=service --state=enabled
        echo
        echo "用户启动项："
        ls -l /etc/rc.local /etc/rc.d/rc.local 2>/dev/null
        echo
        echo "请选择操作："
        echo "1) 添加启动项"
        echo "2) 删除启动项"
        echo "3) 启用/禁用系统服务"
        echo "4) 查看启动项详情"
        echo "5) 返回上级菜单"
        echo
        read -p "请输入选项 [1-5]: " choice

        case $choice in
            1)
                echo "选择添加方式："
                echo "1) 添加系统服务"
                echo "2) 添加启动脚本"
                read -p "请选择 [1-2]: " add_type
                case $add_type in
                    1)
                        read -p "请输入服务名称: " service_name
                        read -p "请输入服务描述: " description
                        read -p "请输入执行命令: " exec_cmd
                        cat > "/etc/systemd/system/$service_name.service" <<EOF
[Unit]
Description=$description
After=network.target

[Service]
Type=simple
ExecStart=$exec_cmd
Restart=always

[Install]
WantedBy=multi-user.target
EOF
                        systemctl daemon-reload
                        systemctl enable "$service_name"
                        print_message "服务已添加并启用"
                        ;;
                    2)
                        read -p "请输入脚本内容（按Ctrl+D结束）: " script_content
                        echo "$script_content" >> /etc/rc.local
                        chmod +x /etc/rc.local
                        print_message "启动脚本已添加"
                        ;;
                    *)
                        print_error "无效的选项"
                        ;;
                esac
                ;;
            2)
                echo "选择删除类型："
                echo "1) 删除系统服务"
                echo "2) 删除启动脚本"
                read -p "请选择 [1-2]: " del_type
                case $del_type in
                    1)
                        read -p "请输入服务名称: " service_name
                        systemctl disable "$service_name"
                        rm -f "/etc/systemd/system/$service_name.service"
                        systemctl daemon-reload
                        print_message "服务已删除"
                        ;;
                    2)
                        read -p "请输入要删除的行号: " line_num
                        sed -i "${line_num}d" /etc/rc.local
                        print_message "启动脚本已删除"
                        ;;
                    *)
                        print_error "无效的选项"
                        ;;
                esac
                ;;
            3)
                read -p "请输入服务名称: " service_name
                read -p "启用还是禁用？(enable/disable): " action
                systemctl "$action" "$service_name"
                print_message "操作完成"
                ;;
            4)
                read -p "请输入服务名称: " service_name
                systemctl status "$service_name"
                ;;
            5) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

###################
# 系统优化函数
###################

# 系统优化菜单
system_optimization_menu() {
    while true; do
        clear
        echo -e "${BLUE}系统优化${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择操作："
        echo "1) 系统参数优化"
        echo "2) 内核参数优化"
        echo "3) 网络性能优化"
        echo "4) 磁盘IO优化"
        echo "5) 内存管理优化"
        echo "6) 服务优化"
        echo "7) 性能监控"
        echo "8) 返回主菜单"
        echo
        read -p "请输入选项 [1-8]: " choice

        case $choice in
            1) system_params_optimization ;;
            2) kernel_optimization ;;
            3) network_optimization ;;
            4) disk_io_optimization ;;
            5) memory_optimization ;;
            6) service_optimization ;;
            7) performance_monitor_menu ;;
            8) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
    done
}

# 性能监控菜单
performance_monitor_menu() {
    while true; do
        clear
        echo -e "${BLUE}性能监控${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择操作："
        echo "1) 实时性能监控"
        echo "2) CPU使用率监控"
        echo "3) 内存使用监控"
        echo "4) 磁盘IO监控"
        echo "5) 网络流量监控"
        echo "6) 进程监控"
        echo "7) 生成性能报告"
        echo "8) 返回上级菜单"
        echo
        read -p "请输入选项 [1-8]: " choice

        case $choice in
            1) realtime_monitor ;;
            2) cpu_monitor ;;
            3) memory_monitor ;;
            4) io_monitor ;;
            5) network_monitor ;;
            6) process_monitor ;;
            7) generate_performance_report ;;
            8) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
    done
}

# 实时性能监控
realtime_monitor() {
    clear
    echo -e "${BLUE}实时性能监控${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # 检查并安装���要工具
    if ! check_command "dstat"; then
        install_package "dstat"
    fi
    
    echo "按Ctrl+C退出监控"
    sleep 2
    dstat -cdngy --proc --top-cpu --top-mem
}

# CPU监控
cpu_monitor() {
    clear
    echo -e "${BLUE}CPU监控${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # 检查并安装必要工具
    if ! check_command "sysstat"; then
        install_package "sysstat"
    fi
    
    echo "CPU使用率统计(每1秒更新)："
    mpstat 1 10
    
    echo
    echo "CPU负载TOP10进程："
    ps aux --sort=-%cpu | head -11
    
    wait_for_key
}

# 内存监控
memory_monitor() {
    clear
    echo -e "${BLUE}内存监控${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    echo "内存使用情况："
    free -h
    echo
    
    echo "内存使用率TOP10进程："
    ps aux --sort=-%mem | head -11
    echo
    
    echo "缓存使用情况："
    vmstat 1 5
    
    wait_for_key
}

# IO监控
io_monitor() {
    clear
    echo -e "${BLUE}IO监控${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # 检查并安装必要工具
    if ! check_command "iotop"; then
        install_package "iotop"
    fi
    
    echo "磁盘IO统计："
    iostat -x 1 5
    echo
    
    echo "IO使用率TOP进程："
    iotop -b -n 1
    
    wait_for_key
}

# 网络流量监控
network_monitor() {
    clear
    echo -e "${BLUE}网络流量监控${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # 检查并安装必要工具
    if ! check_command "iftop"; then
        install_package "iftop"
    fi
    
    echo "网络接口流量统计："
    echo "请选择要监控的网络接口："
    ip -o link show | awk -F': ' '{print $2}'
    read -p "请输入接口名称: " interface
    
    iftop -i "$interface"
}

# 进程监控
process_monitor() {
    while true; do
        clear
        echo -e "${BLUE}进程监控${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择操作："
        echo "1) 查看所有进程"
        echo "2) 查看CPU占用最高的进程"
        echo "3) 查看内存占用最高的进程"
        echo "4) 查看特定进程"
        echo "5) 结束进程"
        echo "6) 返回上级菜单"
        echo
        read -p "请输入选项 [1-6]: " choice

        case $choice in
            1)
                ps aux
                ;;
            2)
                ps aux --sort=-%cpu | head -11
                ;;
            3)
                ps aux --sort=-%mem | head -11
                ;;
            4)
                read -p "请输入进程名称或PID: " process
                if [[ "$process" =~ ^[0-9]+$ ]]; then
                    ps -p "$process" -f
                else
                    ps aux | grep "$process" | grep -v grep
                fi
                ;;
            5)
                read -p "请输入要结束的进程PID: " pid
                read -p "确认要结束进程 $pid? (y/n): " confirm
                if [ "$confirm" = "y" ]; then
                    kill -15 "$pid" 2>/dev/null || kill -9 "$pid"
                    print_message "进程已终止"
                fi
                ;;
            6) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

# 生成性能报告
generate_performance_report() {
    clear
    echo -e "${BLUE}生成性能报告${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    report_dir="/var/log/performance/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$report_dir"
    
    print_message "开始收集系统性能数据..."
    
    # 系统基本信息
    {
        echo "系统性能报告"
        echo "生成时间: $(date)"
        echo "================================"
        echo
        get_system_info
    } > "$report_dir/system_info.txt"
    
    # CPU信息
    {
        echo "CPU使用情况："
        mpstat 1 5
        echo
        echo "CPU负载TOP10进程："
        ps aux --sort=-%cpu | head -11
    } > "$report_dir/cpu_info.txt"
    
    # 内存信息
    {
        echo "内存使用情况："
        free -h
        echo
        echo "内存使用TOP10进程："
        ps aux --sort=-%mem | head -11
        echo
        echo "虚拟内存统计："
        vmstat 1 5
    } > "$report_dir/memory_info.txt"
    
    # 磁盘信息
    {
        echo "磁盘使用情况："
        df -h
        echo
        echo "磁盘IO统计："
        iostat -x
    } > "$report_dir/disk_info.txt"
    
    # 网络信息
    {
        echo "网络连接状态："
        netstat -ant | awk '{print $6}' | sort | uniq -c
        echo
        echo "网络接口统计："
        ip -s link
    } > "$report_dir/network_info.txt"
    
    # 打包报告
    cd /var/log/performance
    tar czf "performance_report_$(date +%Y%m%d_%H%M%S).tar.gz" "$(basename "$report_dir")"
    rm -rf "$report_dir"
    
    print_message "性能报告已生成: /var/log/performance/performance_report_$(date +%Y%m%d_%H%M%S).tar.gz"
    wait_for_key
}

###################
# 网络工具函数
###################

# 网络工具菜单
network_tools_menu() {
    while true; do
        clear
        echo -e "${BLUE}网络工具${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择工具："
        echo "1) 网络连接测试"
        echo "2) 网络接口管理"
        echo "3) 防火墙管理"
        echo "4) DNS工具"
        echo "5) 流量监控"
        echo "6) 端口扫描"
        echo "7) 网络抓包"
        echo "8) 返回主菜单"
        echo
        read -p "请输入选项 [1-8]: " choice

        case $choice in
            1) network_test ;;
            2) interface_management ;;
            3) firewall_management ;;
            4) dns_tools ;;
            5) traffic_monitor ;;
            6) port_scan ;;
            7) packet_capture ;;
            8) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
    done
}

# 网络抓包函数
packet_capture() {
    clear
    echo -e "${BLUE}网络抓包${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # 检查安装tcpdump
    if ! check_command "tcpdump"; then
        install_package "tcpdump"
    fi
    
    # 显示网络接口
    echo "可用网络接口："
    ip -o link show | awk -F': ' '{print $2}'
    echo
    
    read -p "请输入要监听的接口(默认eth0): " interface
    interface=${interface:-eth0}
    
    read -p "请输入过滤条件(例如: port 80): " filter
    read -p "请输入捕获时间(秒): " duration
    read -p "是否保存到文件?(y/n): " save_file
    
    if [ "$save_file" = "y" ]; then
        capture_file="/tmp/capture_$(date +%Y%m%d_%H%M%S).pcap"
        if [ -n "$filter" ]; then
            timeout "$duration" tcpdump -i "$interface" "$filter" -w "$capture_file"
        else
            timeout "$duration" tcpdump -i "$interface" -w "$capture_file"
        fi
        print_message "抓包文件已保存到: $capture_file"
    else
        if [ -n "$filter" ]; then
            timeout "$duration" tcpdump -i "$interface" "$filter"
        else
            timeout "$duration" tcpdump -i "$interface"
        fi
    fi
    
    wait_for_key
}

# DNS工具函数
dns_tools() {
    while true; do
        clear
        echo -e "${BLUE}DNS工具${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择操作："
        echo "1) DNS查询"
        echo "2) 反向DNS查询"
        echo "3) MX记录查询"
        echo "4) NS记录查询"
        echo "5) DNS服务器测试"
        echo "6) 返回上级菜单"
        echo
        read -p "请输入选项 [1-6]: " choice

        case $choice in
            1)
                read -p "请输入域名: " domain
                dig +short "$domain"
                ;;
            2)
                read -p "请输入IP地址: " ip
                dig -x "$ip" +short
                ;;
            3)
                read -p "请输入域名: " domain
                dig MX "$domain" +short
                ;;
            4)
                read -p "请输入域名: " domain
                dig NS "$domain" +short
                ;;
            5)
                read -p "请输入DNS服务器IP: " dns_server
                read -p "请输入要查询的域名: " domain
                dig "@$dns_server" "$domain"
                ;;
            6) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

###################
# 服务管理函数
###################

# 服务管理菜单
service_management_menu() {
    while true; do
        clear
        echo -e "${BLUE}服务管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择操作："
        echo "1) 查看所有服务"
        echo "2) 服务状态管理"
        echo "3) 开机启动管理"
        echo "4) 服务配置管理"
        echo "5) 服务日志管理"
        echo "6) 自定义务"
        echo "7) 返回主菜单"
        echo
        read -p "请输入选项 [1-7]: " choice

        case $choice in
            1) list_services ;;
            2) service_status_management ;;
            3) service_boot_management ;;
            4) service_config_management ;;
            5) service_log_management ;;
            6) custom_service_management ;;
            7) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
    done
}

# 列出所有服务
list_services() {
    clear
    echo -e "${BLUE}系统服务列表${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    echo "运行中的服务："
    systemctl list-units --type=service --state=running
    echo
    echo "已加载的服务："
    systemctl list-units --type=service --all
    wait_for_key
}

# 服务状态管理
service_status_management() {
    while true; do
        clear
        echo -e "${BLUE}服务状态管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择操作："
        echo "1) 启动服务"
        echo "2) 停止服务"
        echo "3) 重启服务"
        echo "4) 重新加载服务"
        echo "5) 查看服务状态"
        echo "6) 返回上级菜单"
        echo
        read -p "请输入选项 [1-6]: " choice

        case $choice in
            1)
                read -p "请输入服务名称: " service_name
                systemctl start "$service_name"
                print_message "服务已启动"
                ;;
            2)
                read -p "请输入服务名称: " service_name
                systemctl stop "$service_name"
                print_message "服务已停止"
                ;;
            3)
                read -p "请输入服务名称: " service_name
                systemctl restart "$service_name"
                print_message "服务已重启"
                ;;
            4)
                read -p "请输入服务名称: " service_name
                systemctl reload "$service_name"
                print_message "服务已重新加载"
                ;;
            5)
                read -p "请输入服务名称: " service_name
                systemctl status "$service_name"
                ;;
            6) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

# 服务开机启动管理
service_boot_management() {
    while true; do
        clear
        echo -e "${BLUE}服务开机启动管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "已启用的服务："
        systemctl list-unit-files --type=service --state=enabled
        echo
        echo "请选择操作："
        echo "1) 启用服务开机启动"
        echo "2) 禁用服务开机启动"
        echo "3) 查看服务启动状态"
        echo "4) 返回上级菜单"
        echo
        read -p "请输入选项 [1-4]: " choice

        case $choice in
            1)
                read -p "请输入服务名称: " service_name
                systemctl enable "$service_name"
                print_message "服务已设置为开机启动"
                ;;
            2)
                read -p "请输入服务名称: " service_name
                systemctl disable "$service_name"
                print_message "服务已禁用开机启动"
                ;;
            3)
                read -p "请输入服务名称: " service_name
                systemctl is-enabled "$service_name"
                ;;
            4) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

###################
# Docker管理函数
###################

# Docker管理菜单
docker_management_menu() {
    while true; do
        clear
        echo -e "${BLUE}Docker管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        
        # 检查Docker是否安装
        if ! check_command "docker"; then
            print_warning "Docker未安装，是否安装？(y/n)"
            read -p "> " install_docker
            if [ "$install_docker" = "y" ]; then
                install_docker
            else
                return
            fi
        fi
        
        echo "请选择操作："
        echo "1) 容器管理"
        echo "2) 镜像管理"
        echo "3) 网络管理"
        echo "4) 数据卷管理"
        echo "5) Docker Compose管理"
        echo "6) Docker系统维护"
        echo "7) 返回主菜单"
        echo
        read -p "请输入选项 [1-7]: " choice

        case $choice in
            1) docker_container_management ;;
            2) docker_image_management ;;
            3) docker_network_management ;;
            4) docker_volume_management ;;
            5) docker_compose_management ;;
            6) docker_system_maintenance ;;
            7) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
    done
}

# 安装Docker
install_docker() {
    clear
    echo -e "${BLUE}安装Docker${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # 检查系统类型
    local system_type=$(check_system_type)
    
    case $system_type in
        debian)
            # 安装必要的包
            apt-get update
            apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            
            # 添加Docker官方GPG密钥
            curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
            
            # 添加Docker仓库
            add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
            
            # 安装Docker
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io
            ;;
        redhat)
            # 安装必要的包
            yum install -y yum-utils device-mapper-persistent-data lvm2
            
            # 添加Docker仓库
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            
            # 安装Docker
            yum install -y docker-ce docker-ce-cli containerd.io
            ;;
        *)
            print_error "不支持的系统类型"
            return 1
            ;;
    esac
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    # 安装Docker Compose
    if ! check_command "docker-compose"; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    print_message "Docker安装完成"
    wait_for_key
}

# Docker容器管理
docker_container_management() {
    while true; do
        clear
        echo -e "${BLUE}Docker容器管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "运行中的容���："
        docker ps
        echo
        echo "所有容器："
        docker ps -a
        echo
        echo "请选择操作："
        echo "1) 启动容器"
        echo "2) 停止容器"
        echo "3) 重启容器"
        echo "4) 删除容器"
        echo "5) 查看容器日志"
        echo "6) 进入容器"
        echo "7) 容器详细信息"
        echo "8) 返回上级菜单"
        echo
        read -p "请输入选项 [1-8]: " choice

        case $choice in
            1)
                read -p "请输入容器ID或名称: " container
                docker start "$container"
                print_message "容器已启动"
                ;;
            2)
                read -p "请输入容器ID或名称: " container
                docker stop "$container"
                print_message "容器已停止"
                ;;
            3)
                read -p "请输入容器ID或名称: " container
                docker restart "$container"
                print_message "容器已重启"
                ;;
            4)
                read -p "请输入容器ID或名称: " container
                read -p "是否同时删除数据卷？(y/n): " del_volumes
                if [ "$del_volumes" = "y" ]; then
                    docker rm -v "$container"
                else
                    docker rm "$container"
                fi
                print_message "容器已删除"
                ;;
            5)
                read -p "请输入容器ID或名称: " container
                docker logs -f "$container"
                ;;
            6)
                read -p "请输入容器ID或名称: " container
                docker exec -it "$container" /bin/bash || docker exec -it "$container" /bin/sh
                ;;
            7)
                read -p "请输入容器ID或名称: " container
                docker inspect "$container"
                ;;
            8) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

# Docker镜像管理
docker_image_management() {
    while true; do
        clear
        echo -e "${BLUE}Docker镜像管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "本地镜像列表："
        docker images
        echo
        echo "请选择操作："
        echo "1) 拉取镜像"
        echo "2) 删除镜像"
        echo "3) 搜索镜像"
        echo "4) 构建镜像"
        echo "5) 导出镜像"
        echo "6) 导入镜像"
        echo "7) 镜像详细信息"
        echo "8) 清理未使用的镜像"
        echo "9) 返回上级菜单"
        echo
        read -p "请输入选项 [1-9]: " choice

        case $choice in
            1)
                read -p "请输入镜像名称: " image
                docker pull "$image"
                ;;
            2)
                read -p "请输入镜像ID或名称: " image
                docker rmi "$image"
                ;;
            3)
                read -p "请输入搜索关键字: " keyword
                docker search "$keyword"
                ;;
            4)
                read -p "请输���Dockerfile路径: " dockerfile_path
                read -p "请输入镜像名称和标签: " image_tag
                docker build -t "$image_tag" "$dockerfile_path"
                ;;
            5)
                read -p "请输入镜像名称: " image
                read -p "请输入保存路径: " save_path
                docker save -o "$save_path" "$image"
                ;;
            6)
                read -p "请输入镜像文件路径: " image_file
                docker load -i "$image_file"
                ;;
            7)
                read -p "请输入镜像ID或名称: " image
                docker inspect "$image"
                ;;
            8)
                docker image prune -a -f
                print_message "未使用的镜像已清理"
                ;;
            9) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

# Docker网络管理
docker_network_management() {
    while true; do
        clear
        echo -e "${BLUE}Docker网络管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "Docker网络列表："
        docker network ls
        echo
        echo "请选择操作："
        echo "1) 创建网络"
        echo "2) 删除网络"
        echo "3) 连接容器到网络"
        echo "4) 断开容器与网络的连接"
        echo "5) 查看网络详情"
        echo "6) 清理未使用的网络"
        echo "7) 返回上级菜单"
        echo
        read -p "请输入选项 [1-7]: " choice

        case $choice in
            1)
                read -p "请输入网络名称: " net_name
                read -p "请选择网络驱动(bridge/overlay/host/none): " net_driver
                docker network create --driver "${net_driver:-bridge}" "$net_name"
                ;;
            2)
                read -p "请输入网络名称: " net_name
                docker network rm "$net_name"
                ;;
            3)
                read -p "请输入容器ID或名称: " container
                read -p "请输入网络名称: " net_name
                docker network connect "$net_name" "$container"
                ;;
            4)
                read -p "请输入容器ID或名称: " container
                read -p "请输入网络名称: " net_name
                docker network disconnect "$net_name" "$container"
                ;;
            5)
                read -p "请输入网络名称: " net_name
                docker network inspect "$net_name"
                ;;
            6)
                docker network prune -f
                print_message "未使用的网络已清理"
                ;;
            7) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

# Docker数据卷管理
docker_volume_management() {
    while true; do
        clear
        echo -e "${BLUE}Docker数据卷管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "数据卷列表："
        docker volume ls
        echo
        echo "请选择操作："
        echo "1) 创建数据卷"
        echo "2) 删除数据卷"
        echo "3) 查看数据卷详情"
        echo "4) 备份数据卷"
        echo "5) 恢复数据卷"
        echo "6) 清理未使用的数据卷"
        echo "7) 返回上级菜单"
        echo
        read -p "请输入选项 [1-7]: " choice

        case $choice in
            1)
                read -p "��输入数据卷名称: " vol_name
                docker volume create "$vol_name"
                ;;
            2)
                read -p "请输入数据卷名称: " vol_name
                docker volume rm "$vol_name"
                ;;
            3)
                read -p "请输入数据卷名称: " vol_name
                docker volume inspect "$vol_name"
                ;;
            4)
                read -p "请输入数据卷名称: " vol_name
                read -p "请输入备份文件路径: " backup_path
                docker run --rm -v "$vol_name":/source -v "$(dirname "$backup_path")":/backup alpine tar czf "/backup/$(basename "$backup_path")" -C /source .
                ;;
            5)
                read -p "请输入备份文件路径: " backup_path
                read -p "请输入要恢复到的数据卷名称: " vol_name
                docker run --rm -v "$vol_name":/dest -v "$(dirname "$backup_path")":/backup alpine tar xzf "/backup/$(basename "$backup_path")" -C /dest
                ;;
            6)
                docker volume prune -f
                print_message "未使用的数据卷已清理"
                ;;
            7) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

# Docker Compose管理
docker_compose_management() {
    while true; do
        clear
        echo -e "${BLUE}Docker Compose管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        
        # 检查Docker Compose是否安装
        if ! check_command "docker-compose"; then
            print_warning "Docker Compose未安装，是否安装？(y/n)"
            read -p "> " install_compose
            if [ "$install_compose" = "y" ]; then
                curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                chmod +x /usr/local/bin/docker-compose
            else
                return
            fi
        fi
        
        echo "请选择操作："
        echo "1) 启动服务"
        echo "2) 停止服务"
        echo "3) 重启服务"
        echo "4) 查看服务状态"
        echo "5) 查看服务日志"
        echo "6) 更新服务"
        echo "7) 删除服务"
        echo "8) 返回上级菜单"
        echo
        read -p "请输入选项 [1-8]: " choice

        case $choice in
            1)
                read -p "请输入项目目录路径: " project_path
                if [ -f "${project_path}/docker-compose.yml" ] || [ -f "${project_path}/compose.yaml" ]; then
                    cd "$project_path" && docker-compose up -d
                    print_message "服务已启动"
                else
                    print_error "未找到docker-compose.yml或compose.yaml文件"
                fi
                ;;
            2)
                read -p "请输入项目目录路径: " project_path
                if [ -f "${project_path}/docker-compose.yml" ] || [ -f "${project_path}/compose.yaml" ]; then
                    cd "$project_path" && docker-compose down
                    print_message "服务已停止"
                else
                    print_error "未找到docker-compose.yml或compose.yaml文件"
                fi
                ;;
            3)
                read -p "请输入项目目录路径: " project_path
                if [ -f "${project_path}/docker-compose.yml" ] || [ -f "${project_path}/compose.yaml" ]; then
                    cd "$project_path" && docker-compose restart
                    print_message "服务已重启"
                else
                    print_error "未找到docker-compose.yml或compose.yaml文件"
                fi
                ;;
            4)
                read -p "请输入项目目录路径: " project_path
                if [ -f "${project_path}/docker-compose.yml" ] || [ -f "${project_path}/compose.yaml" ]; then
                    cd "$project_path" && docker-compose ps
                else
                    print_error "未找到docker-compose.yml或compose.yaml文件"
                fi
                ;;
            5)
                read -p "请输入项目目录路径: " project_path
                if [ -f "${project_path}/docker-compose.yml" ] || [ -f "${project_path}/compose.yaml" ]; then
                    cd "$project_path" && docker-compose logs -f
                else
                    print_error "未找到docker-compose.yml或compose.yaml文件"
                fi
                ;;
            6)
                read -p "请输入项目目录路径: " project_path
                if [ -f "${project_path}/docker-compose.yml" ] || [ -f "${project_path}/compose.yaml" ]; then
                    cd "$project_path" && docker-compose pull && docker-compose up -d
                    print_message "服务已更新"
                else
                    print_error "未找到docker-compose.yml或compose.yaml文件"
                fi
                ;;
            7)
                read -p "请输入项目目录路径: " project_path
                if [ -f "${project_path}/docker-compose.yml" ] || [ -f "${project_path}/compose.yaml" ]; then
                    read -p "是否同时删除数据卷？(y/n): " del_volumes
                    if [ "$del_volumes" = "y" ]; then
                        cd "$project_path" && docker-compose down -v
                    else
                        cd "$project_path" && docker-compose down
                    fi
                    print_message "服务已删除"
                else
                    print_error "未找到docker-compose.yml或compose.yaml文件"
                fi
                ;;
            8) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

# Docker系统维护
docker_system_maintenance() {
    while true; do
        clear
        echo -e "${BLUE}Docker系统维护${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择操作："
        echo "1) 查看Docker系统信息"
        echo "2) 查看Docker磁盘使用情况"
        echo "3) 清理未使用的资源"
        echo "4) 清理构建缓存"
        echo "5) 重启Docker服务"
        echo "6) 更新Docker版本"
        echo "7) 返回上级菜单"
        echo
        read -p "请输入选项 [1-7]: " choice

        case $choice in
            1)
                docker info
                ;;
            2)
                docker system df -v
                ;;
            3)
                docker system prune -a --volumes -f
                print_message "已清理未使用的资源"
                ;;
            4)
                docker builder prune -a -f
                print_message "已清理构建缓存"
                ;;
            5)
                systemctl restart docker
                print_message "Docker服务已重启"
                ;;
            6)
                local system_type=$(check_system_type)
                case $system_type in
                    debian)
                        apt-get update
                        apt-get upgrade -y docker-ce docker-ce-cli containerd.io
                        ;;
                    redhat)
                        yum update -y docker-ce docker-ce-cli containerd.io
                        ;;
                    *)
                        print_error "不支持的系统类型"
                        return 1
                        ;;
                esac
                systemctl restart docker
                print_message "Docker已更新到最新版本"
                ;;
            7) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

###################
# Nginx管理函数
###################

# Nginx管理菜单
nginx_management_menu() {
    while true; do
        clear
        echo -e "${BLUE}Nginx管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        
        # 检查Nginx是否安装
        if ! check_command "nginx"; then
            print_warning "Nginx未安装，是否安装？(y/n)"
            read -p "> " install_nginx
            if [ "$install_nginx" = "y" ]; then
                install_nginx
            else
                return
            fi
        fi
        
        echo "请选择操作："
        echo "1) 站点管理"
        echo "2) SSL证书管理"
        echo "3) 配置管理"
        echo "4) 日志管理"
        echo "5) 性能优化"
        echo "6) 状态监控"
        echo "7) 返回主菜单"
        echo
        read -p "请输入选项 [1-7]: " choice

        case $choice in
            1) nginx_site_management ;;
            2) nginx_ssl_management ;;
            3) nginx_config_management ;;
            4) nginx_log_management ;;
            5) nginx_optimization ;;
            6) nginx_status ;;
            7) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
    done
}

# 安装Nginx
install_nginx() {
    clear
    echo -e "${BLUE}安装Nginx${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    local system_type=$(check_system_type)
    
    case $system_type in
        debian)
            # 添加Nginx官方源
            curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
            echo "deb https://nginx.org/packages/mainline/debian/ $(lsb_release -cs) nginx" > /etc/apt/sources.list.d/nginx.list
            
            # 安装Nginx
            apt-get update
            apt-get install -y nginx
            ;;
        redhat)
            # 添加Nginx源
            cat > /etc/yum.repos.d/nginx.repo <<EOF
[nginx]
name=nginx repo
baseurl=https://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=0
enabled=1
EOF
            
            # 安装Nginx
            yum install -y nginx
            ;;
        *)
            print_error "不支持的系统类型"
            return 1
            ;;
    esac
    
    # 创建必要的目录
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /var/www/html
    
    # 启动Nginx
    systemctl start nginx
    systemctl enable nginx
    
    print_message "Nginx安装完成"
    wait_for_key
}

# Nginx站点管理
nginx_site_management() {
    while true; do
        clear
        echo -e "${BLUE}Nginx站点管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "可用站点："
        ls -l /etc/nginx/sites-available/
        echo
        echo "已启用站点："
        ls -l /etc/nginx/sites-enabled/
        echo
        echo "请选择操作："
        echo "1) 创建新站点"
        echo "2) 删除站点"
        echo "3) 启用站点"
        echo "4) 禁用站点"
        echo "5) 编辑站点配置"
        echo "6) 返回上级菜单"
        echo
        read -p "请输入选项 [1-6]: " choice

        case $choice in
            1)
                read -p "请输入站点名称: " site_name
                read -p "请输入域名: " domain
                read -p "请输入网站根目录: " web_root
                
                # 创建网站根目录
                mkdir -p "$web_root"
                chown -R www-data:www-data "$web_root"
                
                # 创建配置文件
                cat > "/etc/nginx/sites-available/$site_name" <<EOF
server {
    listen 80;
    server_name $domain;
    root $web_root;
    index index.html index.htm index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    access_log /var/log/nginx/${site_name}_access.log;
    error_log /var/log/nginx/${site_name}_error.log;
}
EOF
                print_message "站点配置已创建"
                ;;
            2)
                read -p "请输入要删除的站点名称: " site_name
                rm -f "/etc/nginx/sites-{available,enabled}/$site_name"
                print_message "站点已删除"
                ;;
            3)
                read -p "请输入要启用的配置文件名: " config_file
                ln -s "/etc/nginx/sites-available/$config_file" "/etc/nginx/sites-enabled/"
                print_message "站点已启用"
                ;;
            4)
                read -p "请输入要禁用的配置文件名: " config_file
                rm -f "/etc/nginx/sites-enabled/$config_file"
                print_message "站点已禁用"
                ;;
            5)
                read -p "请输入要编辑的配置文件名: " config_file
                if [ -n "$EDITOR" ]; then
                    $EDITOR "/etc/nginx/sites-available/$config_file"
                else
                    nano "/etc/nginx/sites-available/$config_file"
                fi
                ;;
            6) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        
        # 检查配置并重载
        if nginx -t; then
            systemctl reload nginx
        else
            print_error "Nginx配置检查失败"
        fi
        
        wait_for_key
    done
}

# Nginx SSL证书管理
nginx_ssl_management() {
    while true; do
        clear
        echo -e "${BLUE}SSL证书管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择操作："
        echo "1) 申请Let's Encrypt证书"
        echo "2) 导入已有证书"
        echo "3) 更新证书"
        echo "4) 查看证书信息"
        echo "5) 配置SSL站点"
        echo "6) 返回上级菜单"
        echo
        read -p "请输入选项 [1-6]: " choice

        case $choice in
            1)
                if ! check_command "certbot"; then
                    print_message "正在安装certbot..."
                    if [ -f /etc/debian_version ]; then
                        apt-get install -y certbot python3-certbot-nginx
                    elif [ -f /etc/redhat-release ]; then
                        yum install -y certbot python3-certbot-nginx
                    fi
                fi
                
                read -p "请输入域名: " domain
                certbot --nginx -d "$domain"
                ;;
            2)
                read -p "请输入证书路径: " cert_path
                read -p "请输入私钥路径: " key_path
                read -p "请输入域名: " domain
                
                # 创建证书目录
                mkdir -p "/etc/nginx/ssl/$domain"
                cp "$cert_path" "/etc/nginx/ssl/$domain/cert.pem"
                cp "$key_path" "/etc/nginx/ssl/$domain/key.pem"
                
                # 创建SSL配置
                cat > "/etc/nginx/sites-available/${domain}_ssl" <<EOF
server {
    listen 443 ssl http2;
    server_name $domain;
    
    ssl_certificate /etc/nginx/ssl/$domain/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/$domain/key.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=63072000" always;
    
    root /var/www/html/$domain;
    index index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}

server {
    listen 80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}
EOF
                print_message "SSL配置已创建"
                ;;
            3)
                certbot renew
                systemctl reload nginx
                ;;
            4)
                for cert in /etc/letsencrypt/live/*/cert.pem; do
                    echo "证书: $cert"
                    openssl x509 -in "$cert" -text -noout | grep -E "Subject:|Not Before:|Not After:"
                    echo
                done
                ;;
            5)
                read -p "请输入域名: " domain
                read -p "请输入证书路径: " cert_path
                read -p "请输入私钥路径: " key_path
                
                # 修改站点配置
                sed -i "/server {/a \    ssl_certificate $cert_path;\n    ssl_certificate_key $key_path;\n    listen 443 ssl http2;" "/etc/nginx/sites-available/$domain"
                
                # 添加HTTP跳转HTTPS
                cat > "/etc/nginx/sites-available/${domain}_redirect" <<EOF
server {
    listen 80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}
EOF
                ln -s "/etc/nginx/sites-available/${domain}_redirect" "/etc/nginx/sites-enabled/"
                ;;
            6) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        
        # 检查配置并重载
        if nginx -t; then
            systemctl reload nginx
        else
            print_error "Nginx配置检查失败"
        fi
        
        wait_for_key
    done
}

# Nginx配置管理
nginx_config_management() {
    while true; do
        clear
        echo -e "${BLUE}Nginx配置管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择操作："
        echo "1) 编辑主配置文件"
        echo "2) 管理配置片段"
        echo "3) 检查配置语法"
        echo "4) 查看配置结构"
        echo "5) 备份配置"
        echo "6) 还原配置"
        echo "7) 返回上级菜单"
        echo
        read -p "请输入选项 [1-7]: " choice

        case $choice in
            1)
                if [ -n "$EDITOR" ]; then
                    $EDITOR /etc/nginx/nginx.conf
                else
                    nano /etc/nginx/nginx.conf
                fi
                ;;
            2)
                while true; do
                    clear
                    echo "配置片段管理："
                    echo "1) 创建新配置片段"
                    echo "2) 编辑配置片段"
                    echo "3) 删除配置片段"
                    echo "4) 返回上级菜单"
                    read -p "请选择 [1-4]: " snippet_choice
                    
                    case $snippet_choice in
                        1)
                            read -p "请输入配置片段名称: " snippet_name
                            if [ -n "$EDITOR" ]; then
                                $EDITOR "/etc/nginx/conf.d/$snippet_name.conf"
                            else
                                nano "/etc/nginx/conf.d/$snippet_name.conf"
                            fi
                            ;;
                        2)
                            echo "可用的配置片段："
                            ls -l /etc/nginx/conf.d/
                            read -p "请输入要编辑的文件名: " edit_file
                            if [ -n "$EDITOR" ]; then
                                $EDITOR "/etc/nginx/conf.d/$edit_file"
                            else
                                nano "/etc/nginx/conf.d/$edit_file"
                            fi
                            ;;
                        3)
                            echo "可用的配置片段："
                            ls -l /etc/nginx/conf.d/
                            read -p "请输入要删除的文件名: " del_file
                            rm -f "/etc/nginx/conf.d/$del_file"
                            ;;
                        4) break ;;
                        *)
                            print_error "无效的选项"
                            sleep 2
                            ;;
                    esac
                done
                ;;
            3)
                nginx -t
                ;;
            4)
                tree /etc/nginx/
                ;;
            5)
                backup_dir="/backup/nginx/$(date +%Y%m%d_%H%M%S)"
                mkdir -p "$backup_dir"
                cp -r /etc/nginx/* "$backup_dir/"
                print_message "配置已备份到 $backup_dir"
                ;;
            6)
                echo "可用的备份："
                ls -l /backup/nginx/
                read -p "请输入要还原的备份目录名: " restore_dir
                if [ -d "/backup/nginx/$restore_dir" ]; then
                    cp -r "/backup/nginx/$restore_dir/"* /etc/nginx/
                    print_message "配置已还原"
                else
                    print_error "备份目录不存在"
                fi
                ;;
            7) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        
        # 检查配置并重载
        if nginx -t; then
            systemctl reload nginx
        else
            print_error "Nginx配置检查失败"
        fi
        
        wait_for_key
    done
}

# Nginx日志管理
nginx_log_management() {
    while true; do
        clear
        echo -e "${BLUE}Nginx日志管理${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择操作："
        echo "1) 查看访问日志"
        echo "2) 查看错误日志"
        echo "3) 日志分析"
        echo "4) 配置日志轮转"
        echo "5) 清理旧日志"
        echo "6) 返回上级菜单"
        echo
        read -p "请输入选项 [1-6]: " choice

        case $choice in
            1)
                read -p "请输入要查看的行数(默认50): " lines
                lines=${lines:-50}
                tail -n "$lines" /var/log/nginx/access.log
                ;;
            2)
                read -p "请输入要查看的行数(默认50): " lines
                lines=${lines:-50}
                tail -n "$lines" /var/log/nginx/error.log
                ;;
            3)
                if ! check_command "goaccess"; then
                    print_message "正在安装GoAccess..."
                    if [ -f /etc/debian_version ]; then
                        apt-get install -y goaccess
                    elif [ -f /etc/redhat-release ]; then
                        yum install -y goaccess
                    fi
                fi
                
                echo "选择分析类型："
                echo "1) 实时分析"
                echo "2) 生成HTML报告"
                read -p "请选择 [1-2]: " analysis_type
                
                case $analysis_type in
                    1)
                        goaccess /var/log/nginx/access.log -c
                        ;;
                    2)
                        report_file="/var/www/html/report_$(date +%Y%m%d).html"
                        goaccess /var/log/nginx/access.log -o "$report_file" --log-format=COMBINED
                        print_message "报告已生成: $report_file"
                        ;;
                    *)
                        print_error "无效的选项"
                        ;;
                esac
                ;;
            4)
                if [ -n "$EDITOR" ]; then
                    $EDITOR /etc/logrotate.d/nginx
                else
                    nano /etc/logrotate.d/nginx
                fi
                ;;
            5)
                read -p "是否清理30天前的日志？(y/n): " confirm
                if [ "$confirm" = "y" ]; then
                    find /var/log/nginx/ -type f -name "*.log.*" -mtime +30 -delete
                    print_message "已清理30天前的日志"
                fi
                ;;
            6) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
        wait_for_key
    done
}

# Nginx性能优化
nginx_optimization() {
    clear
    echo -e "${BLUE}Nginx性能优化${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # 备份原始配置
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    
    # 获取系统信息
    cpu_cores=$(nproc)
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    
    # 计算优化参数
    worker_processes=$cpu_cores
    worker_connections=$((total_mem * 10))
    
    # 更新配置文件
    cat > /etc/nginx/nginx.conf <<EOF
user www-data;
worker_processes $worker_processes;
worker_rlimit_nofile 65535;

events {
    worker_connections $worker_connections;
    multi_accept on;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log combined buffer=16k;
    error_log /var/log/nginx/error.log;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    client_max_body_size 16M;
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 4k;

    open_file_cache max=100000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

    # 检查配置并重启
    if nginx -t; then
        systemctl restart nginx
        print_message "Nginx性能优化完成"
    else
        print_error "配置检查失败，已还原配置"
        mv /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
    fi
    
    wait_for_key
}

# 主菜单函数
show_main_menu() {
    while true; do
        clear
        echo -e "${BLUE}$SCRIPT_NAME v$VERSION${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "主菜单："
        echo "1) 系统管理与优化"
        echo "2) Docker管理"
        echo "3) Nginx管理"
        echo "4) 网络工具"
        echo "5) 服务管理"
        echo "6) 退出"
        echo
        read -p "请输入选项 [1-6]: " choice

        case $choice in
            1) system_management_menu ;;
            2) docker_management_menu ;;
            3) nginx_management_menu ;;
            4) network_tools_menu ;;
            5) service_management_menu ;;
            6) 
                echo "感谢使用，再见！"
                exit 0
                ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
    done
}

# 系统管理菜单
system_management_menu() {
    while true; do
        clear
        echo -e "${BLUE}系统管理与优化${NC}"
        echo -e "${BLUE}================================${NC}"
        echo
        echo "请选择操作："
        echo "1) 系统基本配置"
        echo "2) 系统性能优化"
        echo "3) 系统监控与维护"
        echo "4) 系统安全管理"
        echo "5) 软件源管理"
        echo "6) 返回主菜单"
        echo
        read -p "请输入选项 [1-6]: " choice

        case $choice in
            1) system_basic_config_menu ;;
            2) system_optimization_menu ;;
            3) system_monitor_menu ;;
            4) security_management_menu ;;
            5) change_mirrors ;;
            6) return ;;
            *)
                print_error "无效的选项"
                sleep 2
                ;;
        esac
    done
}

# 主函数
main() {
    echo -e "${GREEN}[INFO] 脚本开始执行...${NC}"
    
    # 检查root权限
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[ERROR] 请使用 sudo 或 root 权限运行此脚本${NC}" >&2
        exit 1
    fi
    
    # 检查系统类型
    if ! check_system_type &>/dev/null; then
        echo -e "${RED}[ERROR] 不支持的系统类型${NC}" >&2
        exit 1
    fi
    
    # 初始化
    init
    
    # 显示主菜单
    show_main_menu
}

# 执行主函数
main
