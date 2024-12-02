#!/bin/bash

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

# 2. 所有show_*菜单函数
show_menu() {
    clear
    echo "================================"
    echo "      系统管理脚本 v1.0         "
    echo "================================"
    echo "1. 显示系统信息"
    echo "2. 系统配置管理"
    echo "3. 网络管理"
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

# 显示网络状态
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

# 3. 所有check_*状态检查函数
check_firewall_status() {
    clear
    echo "========== 防火墙状态检查 =========="
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
        echo "无效的端口号！端口号必须在1-65535之间"
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

# 4. 所有list_*列表函数
list_open_ports() {
    clear
    echo "============ 已开放端口 ============"
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw status
    elif command -v firewalld >/dev/null 2>&1; then
        sudo firewall-cmd --list-ports
    else
        echo "未检测到支持的防火墙服务"
    fi
    read -p "按回车键返回..."
}

# 5. 所有start_*和stop_*操作函数
start_firewall() {
    clear
    echo "============ 开启防火墙 ============"
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw enable
        echo "UFW防火墙已开启"
    elif command -v firewalld >/dev/null 2>&1; then
        sudo systemctl start firewalld
        echo "FirewallD防火墙已开启"
    else
        echo "未检测到支持的防火墙服务"
    fi
    read -p "按回车键返回..."
}

stop_firewall() {
    clear
    echo "============ 关闭防火墙 ============"
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw disable
        echo "UFW防火墙已关闭"
    elif command -v firewalld >/dev/null 2>&1; then
        sudo systemctl stop firewalld
        echo "FirewallD防火墙已关闭"
    else
        echo "未检测到支持的防火墙服务"
    fi
    read -p "按回车键返回..."
}

disable_firewall() {
    clear
    echo "============ 禁用防火墙开机启动 ============"
    if command -v ufw >/dev/null 2>&1; then
        sudo systemctl disable ufw
        echo "UFW防火墙开机启动已禁用"
    elif command -v firewalld >/dev/null 2>&1; then
        sudo systemctl disable firewalld
        echo "FirewallD防火墙开机启动已禁用"
    else
        echo "未检测到支持的防火墙服务"
    fi
    read -p "按回车键返回..."
}

# 6. 所有open_*和close_*操作函数
open_port() {
    clear
    echo "============ 开放端口 ============"
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
                ;;
            udp)
                sudo ufw allow $port/udp
                ;;
            both)
                sudo ufw allow $port
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
                ;;
            udp)
                sudo firewall-cmd --permanent --add-port=$port/udp
                ;;
            both)
                sudo firewall-cmd --permanent --add-port=$port/tcp
                sudo firewall-cmd --permanent --add-port=$port/udp
                ;;
            *)
                echo "无效的协议类型！"
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
                ;;
            udp)
                sudo ufw deny $port/udp
                ;;
            both)
                sudo ufw deny $port
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
                ;;
            udp)
                sudo firewall-cmd --permanent --remove-port=$port/udp
                ;;
            both)
                sudo firewall-cmd --permanent --remove-port=$port/tcp
                sudo firewall-cmd --permanent --remove-port=$port/udp
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

# 7. 所有set_*和show_*配置函数
set_ipv4_priority() {
    clear
    echo "正在设置IPv4优先..."
    if [ -f /etc/gai.conf ]; then
        sudo cp /etc/gai.conf /etc/gai.conf.bak
        sudo sed -i 's/^precedence ::ffff:0:0\/96  100/#precedence ::ffff:0:0\/96  100/' /etc/gai.conf
        echo "precedence ::ffff:0:0/96  100" | sudo tee -a /etc/gai.conf
        echo "IPv4优先级已设置"
    else
        echo "precedence ::ffff:0:0/96  100" | sudo tee /etc/gai.conf
    fi
    read -p "按回车键返回..."
}

set_ipv6_priority() {
    clear
    echo "正在设置IPv6优先..."
    if [ -f /etc/gai.conf ]; then
        sudo cp /etc/gai.conf /etc/gai.conf.bak
        sudo sed -i 's/^precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf
        echo "#precedence ::ffff:0:0/96  100" | sudo tee -a /etc/gai.conf
        echo "IPv6优先级已设置"
    else
        echo "#precedence ::ffff:0:0/96  100" | sudo tee /etc/gai.conf
    fi
    read -p "按回车键返回..."
}

show_ip_config() {
    clear
    echo "=========== IP配置信息 ==========="
    echo "IPv4配置："
    ip -4 addr show
    echo
    echo "IPv6配置："
    ip -6 addr show
    echo
    echo "IP优先级配置："
    grep -r . /proc/sys/net/ipv6/conf/*/disable_ipv6
    cat /proc/sys/net/ipv6/conf/all/disable_ipv6
    read -p "按回车键返回..."
}

# 8. 所有manage_*管理函数
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

manage_ip_protocol() {
    while true; do
        show_ip_menu
        read -p "请输入您的选择 [0-7]: " choice
        
        case $choice in
            1)
                show_ip_config
                ;;
            2)
                set_ipv4_priority
                ;;
            3)
                set_ipv6_priority
                ;;
            4)
                disable_ipv4
                ;;
            5)
                disable_ipv6
                ;;
            6)
                enable_ipv4
                ;;
            7)
                enable_ipv6
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

manage_network_interface() {
    clear
    echo "============ 网络接口管理 ============"
    # 在这里添加网络接口管理的代码
    read -p "按回车键返回..."
}

system_config() {
    while true; do
        show_system_config_menu
        read -p "请输入您的选择 [0-5]: " choice
        
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
                # 直接调用外部BBR脚本
                bash <(curl -sL https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh)
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

# 9. main函数和程序入口
main() {
    # 检查并安装必要工具
    check_and_install_tools
    
    # 主程序循环
    while true; do
        show_menu
        read -p "请输入您的选择 [0-3]: " choice
        
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
