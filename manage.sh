#!/bin/bash

# 1. 配置和初始化
CONFIG_FILE="/etc/manage.conf"
LOG_FILE="/var/log/manage.log"

# 2. 基础工具函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a $LOG_FILE
}

check_dependencies() {
    local deps=("curl" "wget" "systemctl")
    for dep in "${deps[@]}"; do
        if ! command -v $dep >/dev/null 2>&1; then
            echo "缺少依赖: $dep"
            return 1
        fi
    done
}

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

check_command_status() {
    if [ $? -eq 0 ]; then
        echo "操作成功"
        return 0
    else
        echo "操作失败"
        return 1
    fi
}

handle_error() {
    local exit_code=$?
    local error_message="$1"
    if [ $exit_code -ne 0 ]; then
        echo "错误: $error_message"
        log "错误: $error_message (退出码: $exit_code)"
        return 1
    fi
    return 0
}

# 3. 显示菜单函数
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

show_system_config_menu() {
    clear
    echo "================================"
    echo "        系统配菜单           "
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

show_network_tools_menu() {
    clear
    echo "================================"
    echo "       网络测试工具菜单         "
    echo "================================"
    echo "1. 查看网络状态"
    echo "2. 查看路由表"
    echo "3. 查询域名"
    echo "4. 扫描端口"
    echo "5. 测试网络带宽"
    echo "6. 查看活动连接"
    echo "7. 抓包"
    echo "0. 返回上级菜单"
    echo "================================"
}

# 4. 系统配置函数
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
                    echo "��户信息："
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

manage_timezone() {
    while true; do
        clear
        echo "========== 时区管理 =========="
        echo "1. 查看当前时区"
        echo "2. 设置时区"
        echo "3. 同步系统时间"
        echo "0. 返回上级菜单"
        echo "=============================="
        
        read -p "请输入您的选择 [0-3]: " choice
        case $choice in
            1)
                clear
                echo "当前时区信息："
                timedatectl
                read -p "按回车键返回..."
                ;;
            2)
                clear
                echo "常用时区列表："
                echo "1. Asia/Shanghai    (中国上海)"
                echo "2. Asia/Hong_Kong   (中国香港)"
                echo "3. Asia/Taipei      (中国台北)"
                echo "4. Asia/Tokyo       (日本东京)"
                echo "5. Asia/Singapore   (新加坡)"
                echo "6. Europe/London    (英国伦敦)"
                echo "7. America/New_York (美国纽约)"
                echo "8. UTC             (协调世界时)"
                echo "9. 手动输入时区"
                echo "0. 返回上级菜单"
                
                read -p "请选择时区 [0-9]: " tz_choice
                case $tz_choice in
                    1) timezone="Asia/Shanghai";;
                    2) timezone="Asia/Hong_Kong";;
                    3) timezone="Asia/Taipei";;
                    4) timezone="Asia/Tokyo";;
                    5) timezone="Asia/Singapore";;
                    6) timezone="Europe/London";;
                    7) timezone="America/New_York";;
                    8) timezone="UTC";;
                    9)
                        echo "可用的时区列表："
                        timedatectl list-timezones
                        read -p "请输入时区名称: " timezone
                        ;;
                    0) return;;
                    *) echo "无效的选择"; sleep 2; continue;;
                esac
                
                if [ -n "$timezone" ]; then
                    sudo timedatectl set-timezone $timezone
                    echo "时区已设置为: $timezone"
                    log "设置时区为 $timezone"
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                echo "正在同步系统时间..."
                if command -v ntpdate >/dev/null 2>&1; then
                    sudo ntpdate pool.ntp.org
                else
                    sudo timedatectl set-ntp true
                fi
                echo "系统时间已同步"
                log "同步系统时间"
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

manage_hosts() {
    while true; do
        clear
        echo "========== 主机管理 =========="
        echo "1. 查看所有主机"
        echo "2. 添加主机"
        echo "3. 删除主机"
        echo "4. 修改主机名"
        echo "0. 返回上级菜单"
        echo "=============================="
        
        read -p "请输入您的选择 [0-4]: " choice
        case $choice in
            1)
                clear
                echo "当前主机列表："
                cat /etc/hosts | grep -v "^#" | awk '{print $2}'
                read -p "按回车键返回..."
                ;;
            2)
                clear
                read -p "请输入要添加的主机名: " hostname
                if [ -n "$hostname" ]; then
                    echo "127.0.0.1 $hostname" | sudo tee -a /etc/hosts
                    echo "主机已添加"
                    log "添加主机 $hostname"
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                read -p "请输入要删除的主机名: " hostname
                if [ -n "$hostname" ]; then
                    sudo sed -i "/$hostname/d" /etc/hosts
                    echo "主机已删除"
                    log "删除主机 $hostname"
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                read -p "请输入新的主机名: " hostname
                if [ -n "$hostname" ]; then
                    sudo hostnamectl set-hostname $hostname
                    echo "主机名已更新"
                    log "修改主机名为 $hostname"
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

manage_swap() {
    while true; do
        clear
        echo "========== 交换分区管理 =========="
        echo "1. 查看Swap状态"
        echo "2. 创建Swap文件"
        echo "3. 删除Swap文件"
        echo "4. 调整Swap大小"
        echo "5. 修改Swap优先级"
        echo "6. 开启/关闭Swap"
        echo "0. 返回上级菜单"
        echo "=================================="
        
        read -p "请输入您的选择 [0-6]: " choice
        case $choice in
            1)
                clear
                echo "Swap使用情况："
                free -h | grep Swap | awk '{printf "总Swap: %s\n已用: %s\n空闲: %s\n", $2, $3, $4}'
                
                echo -e "\nSwap详细信息："
                echo "文件路径              大小    类型    优先级"
                echo "----------------------------------------"
                swapon --show | tail -n +2 | while read line; do
                    name=$(echo $line | awk '{print $1}')
                    size=$(echo $line | awk '{print $3}')
                    type=$(echo $line | awk '{print $4}')
                    prio=$(echo $line | awk '{print $5}')
                    printf "%-20s %-8s %-8s %-8s\n" "$name" "$size" "$type" "$prio"
                done
                
                echo -e "\nSwap分区列表："
                cat /proc/swaps | column -t
                
                echo -e "\nSwap配置信息："
                grep -i swap /etc/fstab
                
                read -p "按回车键返回..."
                ;;
            2)
                clear
                echo "创建Swap文件"
                echo "推荐的Swap大小："
                mem_total=$(free -m | grep Mem | awk '{print $2}')
                echo "系统内存: ${mem_total}MB"
                echo "- 内存小于2GB: 内存的2倍"
                echo "- 内存2-8GB: 等于内存大小"
                echo "- 内存8-64GB: 内存的0.5倍"
                echo "- 内存大于64GB: 至少4GB"
                
                read -p "请输入Swap文件路径(默认:/swapfile): " swap_path
                swap_path=${swap_path:-/swapfile}
                read -p "请输入Swap大小(GB): " swap_size
                
                if [ -n "$swap_size" ]; then
                    echo "正在创建Swap文件..."
                    sudo fallocate -l ${swap_size}G $swap_path || sudo dd if=/dev/zero of=$swap_path bs=1G count=$swap_size
                    sudo chmod 600 $swap_path
                    sudo mkswap $swap_path
                    sudo swapon $swap_path
                    echo "$swap_path none swap sw 0 0" | sudo tee -a /etc/fstab
                    
                    echo "Swap文件创建完成"
                    echo "当前Swap状态："
                    free -h | grep Swap
                    log "创建${swap_size}G的Swap文件: $swap_path"
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                echo "当前Swap文件列表："
                echo "----------------------------------------"
                echo "序号  文件路径              大小    使用量  优先级"
                echo "----------------------------------------"
                
                # 获取并显示所有swap文件，带序号
                declare -a swap_files
                i=1
                while read -r line; do
                    if [[ $line =~ ^/ ]]; then  # 只处理以/开头的行
                        swap_files[$i]=$(echo "$line" | awk '{print $1}')
                        printf "%-5s %-20s %-8s %-8s %-8s\n" "$i" \
                            "$(echo "$line" | awk '{print $1}')" \
                            "$(echo "$line" | awk '{print $3}')" \
                            "$(echo "$line" | awk '{print $4}')" \
                            "$(echo "$line" | awk '{print $5}')"
                        ((i++))
                    fi
                done < <(swapon --show)
                
                if [ ${#swap_files[@]} -eq 0 ]; then
                    echo "当前系统没有激活的Swap文件"
                    read -p "按回车键返回..."
                    continue
                fi
                
                echo -e "\n选择操作："
                echo "1. 通过序号删除"
                echo "2. 手动输入路径"
                echo "0. 返回上级菜单"
                
                read -p "请选择操作方式 [0-2]: " del_choice
                case $del_choice in
                    1)
                        read -p "请输入要删除的Swap文件序号 [1-$((i-1))]: " num
                        if [ -n "$num" ] && [ "$num" -ge 1 ] && [ "$num" -lt "$i" ]; then
                            swap_path="${swap_files[$num]}"
                            if [ -n "$swap_path" ] && [ -f "$swap_path" ]; then
                                echo -e "\n即将删除以下Swap文件："
                                echo "路径: $swap_path"
                                echo "大小: $(du -h "$swap_path" | cut -f1)"
                                echo "优先级: $(swapon --show | grep "$swap_path" | awk '{print $5}')"
                                
                                read -p "确认删除？(y/n): " confirm
                                if [[ $confirm == "y" ]]; then
                                    echo "正在关闭Swap..."
                                    sudo swapoff "$swap_path"
                                    echo "正在从fstab中移除..."
                                    sudo sed -i "\|^$swap_path|d" /etc/fstab
                                    echo "正在删除文件..."
                                    sudo rm "$swap_path"
                                    
                                    echo -e "\nSwap文件已删除"
                                    echo "当前Swap状态："
                                    free -h | grep Swap
                                    log "删除Swap文件: $swap_path"
                                else
                                    echo "操作已取消"
                                fi
                            else
                                echo "Swap文件不存在或无法访问"
                            fi
                        else
                            echo "无效的序号"
                        fi
                        ;;
                    2)
                        echo -e "\n请输入要删除的Swap文件完整路径"
                        echo "提示：可以从上面的列表中复制路径"
                        read -p "路径: " swap_path
                        if [ -n "$swap_path" ] && [ -f "$swap_path" ]; then
                            echo -e "\n即将删除以下Swap文件："
                            echo "路径: $swap_path"
                            echo "大小: $(du -h "$swap_path" | cut -f1)"
                            if swapon --show | grep -q "$swap_path"; then
                                echo "优先级: $(swapon --show | grep "$swap_path" | awk '{print $5}')"
                            else
                                echo "状态: 未激活"
                            fi
                            
                            read -p "确认删除？(y/n): " confirm
                            if [[ $confirm == "y" ]]; then
                                echo "正在关闭Swap..."
                                sudo swapoff "$swap_path" 2>/dev/null
                                echo "正在从fstab中移除..."
                                sudo sed -i "\|^$swap_path|d" /etc/fstab
                                echo "正在删除文件..."
                                sudo rm "$swap_path"
                                
                                echo -e "\nSwap文件已删除"
                                echo "当前Swap状态："
                                free -h | grep Swap
                                log "删除Swap文件: $swap_path"
                            else
                                echo "操作已取消"
                            fi
                        else
                            echo "Swap文件不存在或无法访问"
                        fi
                        ;;
                    0)
                        continue
                        ;;
                    *)
                        echo "无效的选择"
                        ;;
                esac
                read -p "按回车键返回..."
                ;;
            4)
                clear
                echo "当前Swap文件列表："
                swapon --show
                read -p "请输入要调整的Swap文件路径: " swap_path
                read -p "请输入新的大小(GB): " new_size
                
                if [ -n "$swap_path" ] && [ -f "$swap_path" ] && [ -n "$new_size" ]; then
                    # 关闭swap
                    sudo swapoff $swap_path
                    # 调整大小
                    sudo fallocate -l ${new_size}G $swap_path || sudo dd if=/dev/zero of=$swap_path bs=1G count=$new_size
                    # 重新格式化
                    sudo mkswap $swap_path
                    # 重新启用
                    sudo swapon $swap_path
                    
                    echo "Swap大小已调整"
                    echo "当前Swap状态："
                    free -h | grep Swap
                    log "调整Swap文件 $swap_path 大小为 ${new_size}G"
                else
                    echo "Swap文件不存在或参数无效"
                fi
                read -p "按回车键返回..."
                ;;
            5)
                clear
                echo "当前Swap文件列表："
                swapon --show
                read -p "请输入要修改优先级的Swap文件路径: " swap_path
                read -p "请输入新的优先级(-1到32767): " priority
                
                if [ -n "$swap_path" ] && [ -f "$swap_path" ] && [ -n "$priority" ]; then
                    sudo swapoff $swap_path
                    sudo swapon $swap_path -p $priority
                    echo "Swap优先级已修改"
                    echo "当前Swap状态："
                    swapon --show
                    log "修改Swap文件 $swap_path 优先级为 $priority"
                else
                    echo "Swap文件不存在或参数无效"
                fi
                read -p "按回车键返回..."
                ;;
            6)
                clear
                echo "当前Swap状态："
                free -h | grep Swap
                read -p "是否要关闭所有Swap?(y/n): " disable_swap
                
                if [[ $disable_swap == "y" ]]; then
                    sudo swapoff -a
                    echo "所有Swap已关闭"
                    log "关闭所有Swap"
                else
                    sudo swapon -a
                    echo "所有Swap已开启"
                    log "开启所有Swap"
                fi
                echo "当前Swap状态："
                free -h | grep Swap
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

manage_packages() {
    while true; do
        clear
        echo "========== 软件包管理 =========="
        echo "1. 查看所有软件包"
        echo "2. 搜索软件包"
        echo "3. 安装软件包"
        echo "4. 删除软件包"
        echo "5. 更新软件包"
        echo "6. 清理软件包缓存"
        echo "7. 查看软件包详情"
        echo "0. 返回上级菜单"
        echo "================================"
        
        read -p "请输入您的选择 [0-7]: " choice
        case $choice in
            1)
                clear
                echo "当前软件包列表："
                dpkg -l | grep '^ii' | awk '{print $2" "$3}'
                read -p "按回车键返回..."
                ;;
            2)
                clear
                read -p "请输入要搜索的软件包关键字: " keyword
                if [ -n "$keyword" ]; then
                    apt-cache search $keyword
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                read -p "请输入��安装的软件包名称: " package
                if [ -n "$package" ]; then
                    sudo apt-get install -y $package
                fi
                read -p "按回车键返回..."
                ;;
            4)
                clear
                echo "当前软件包列表："
                dpkg -l | grep '^ii' | awk '{print $2" "$3}'
                read -p "请输入要删除的软件包名称: " package
                if [ -n "$package" ]; then
                    sudo apt-get remove -y $package
                fi
                read -p "按回车键返回..."
                ;;
            5)
                clear
                echo "当前软件包列表："
                dpkg -l | grep '^ii' | awk '{print $2" "$3}'
                read -p "请输入要更新的软件包名称: " package
                if [ -n "$package" ]; then
                    sudo apt-get update
                    sudo apt-get install -y $package
                fi
                read -p "按回车键返回..."
                ;;
            6)
                clear
                echo "正在清理软件包缓存..."
                sudo apt-get clean
                read -p "按回车键返回..."
                ;;
            7)
                clear
                echo "当前软件包列表："
                dpkg -l | grep '^ii' | awk '{print $2" "$3}'
                read -p "请输入要查看详情的软件包名称: " package
                if [ -n "$package" ]; then
                    dpkg -s $package
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

# 5. 系统信息函数
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
    echo -e "\n网��统计："
    netstat -s | head -n 20
    read -p "按回车键返回..."
}

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
    echo "磁���使用情况："
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

show_service_status() {
    clear
    echo "========== 系统服务状态 =========="
    echo "1. 查看所有服务状态"
    echo "2. 查看特定服务状态"
    echo "3. 查看服务日志"
    echo "0. 返回上级菜单"
    echo "================================"
    
    read -p "请输入您的选择 [0-3]: " choice
    case $choice in
        1)
            clear
            echo "所有服务状态："
            systemctl status --all
            read -p "按回车键返回..."
            ;;
        2)
            clear
            read -p "请输入要查看的服务名称: " service_name
            if [ -n "$service_name" ]; then
                systemctl status $service_name
                read -p "按回车键返回..."
            fi
            ;;
        3)
            clear
            read -p "请输入要查看的服务名称: " service_name
            if [ -n "$service_name" ]; then
                journalctl -u $service_name
                read -p "按回车键返回..."
            fi
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

show_system_logs() {
    clear
    echo "========== 系统日志信息 =========="
    echo "1. 查看系统日志"
    echo "2. 查看特定日志"
    echo "3. 查看服务日志"
    echo "4. 查看硬件日志"
    echo "0. 返回上级菜单"
    echo "================================"
    
    read -p "请输入您的选择 [0-4]: " choice
    case $choice in
        1)
            clear
            echo "系统日志："
            journalctl -xe
            read -p "按回车键返回..."
            ;;
        2)
            clear
            read -p "请输入要查看的日志文件: " log_file
            if [ -f "$log_file" ]; then
                cat $log_file
                read -p "按回车键返回..."
            else
                echo "日志文件不存在: $log_file"
                read -p "按回车键返回..."
            fi
            ;;
        3)
            clear
            read -p "请输入要查看的服务名称: " service_name
            if [ -n "$service_name" ]; then
                journalctl -u $service_name
                read -p "按回车键返回..."
            fi
            ;;
        4)
            clear
            echo "硬件日志："
            dmesg
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

show_hardware_info() {
    clear
    echo "========== 硬件信息 =========="
    echo "1. 查看CPU信息"
    echo "2. 查看内存信息"
    echo "3. 查看磁盘信息"
    echo "4. 查看网络信息"
    echo "5. 查看硬件状态"
    echo "0. 返回上级菜单"
    echo "================================"
    
    read -p "请输入您的选择 [0-5]: " choice
    case $choice in
        1)
            clear
            echo "CPU信息："
            cat /proc/cpuinfo
            read -p "按回车键返回..."
            ;;
        2)
            clear
            echo "内存信息："
            free -h
            read -p "按回车键返回..."
            ;;
        3)
            clear
            echo "磁盘信息："
            df -h
            read -p "按回车键返回..."
            ;;
        4)
            clear
            echo "网络信息："
            ip addr show
            read -p "按回车键返回..."
            ;;
        5)
            clear
            echo "硬件状态："
            sudo dmidecode -t system
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

# 6. 网络管理函数
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

manage_ip_protocol() {
    while true; do
        show_ip_menu
        read -p "请输入您的选择 [0-9]: " choice
        
        case $choice in
            1)
                clear
                echo "当前IP配置："
                ip addr show
                read -p "按回车键返回..."
                ;;
            2)
                clear
                echo "网络接口列表："
                ip link show
                read -p "请输入接口名称: " interface
                read -p "请输入IP地址(例如:192.168.1.100/24): " ip
                if [ -n "$interface" ] && [ -n "$ip" ]; then
                    sudo ip addr add $ip dev $interface
                    echo "IP地址已添加"
                    log "添加IP地址 $ip 到接口 $interface"
                fi
                read -p "按回车键返回..."
                ;;
            3)
                clear
                echo "当前IP配置："
                ip addr show
                read -p "请输入要删除的IP地址(包含掩码): " ip
                read -p "请输入接口名称: " interface
                if [ -n "$ip" ] && [ -n "$interface" ]; then
                    sudo ip addr del $ip dev $interface
                    echo "IP地址已删除"
                    log "从接口 $interface 删除IP地址 $ip"
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
        echo "未检测到���持的防火墙服务"
    fi
    
    echo -e "\nIP转发状态："
    echo "--------------------------------"
    cat /proc/sys/net/ipv4/ip_forward
    
    echo -e "\n网络负载统计："
    echo "--------------------------------"
    netstat -i
    
    read -p "按回车键返回..."
}

manage_network_interface() {
    while true; do
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
                    log "配置接口 $interface IP地址为 $ip"
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
                read -p "按回���键返回..."
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

manage_routing_config() {
    while true; do
        clear
        echo "========== 路由管理 =========="
        echo "1. 查看路由表"
        echo "2. 添加静态路由"
        echo "3. 删除静态路由"
        echo "4. 修改默认网关"
        echo "5. 查路由跟踪"
        echo "0. 返回上级菜单"
        echo "=============================="
        
        read -p "请输入您选择 [0-5]: " choice
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
                read -p "按车键返回..."
                ;;
            3)
                clear
                echo "当前路由表："
                ip route show
                read -p "请输入要删除的路由网络: " network
                if [ -n "$network" ]; then
                    sudo ip route del $network
                    echo "路由已删除"
                    log "删除路 $network"
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
                    echo -e "\ndig查���结果："
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
                read -p "按回车返回..."
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

# 7. Docker管理函数
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

install_update_docker() {
    clear
    echo "安装或更新Docker..."
    if command -v docker >/dev/null 2>&1; then
        echo "Docker已安装，正在更新..."
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    else
        echo "Docker未安装，正在安装..."
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    fi
    sudo systemctl enable docker
    sudo systemctl start docker
    echo "Docker安装或更新完成"
    read -p "按回车键返回..."
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
                echo "所有容器列表："
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
                read -p "按回车键返..."
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

manage_volumes() {
    while true; do
        clear
        echo "========== 数据卷管理 =========="
        echo "1. 查看所有数据卷"
        echo "2. 创建数据卷"
        echo "3. 删除数据卷"
        echo "4. 清理未使用数据卷"
        echo "5. 查看数据卷详��"
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
                read -p "按回车键回..."
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
                echo "在清理未使用的网络..."
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
                echo "无效���选择"
                sleep 2
                ;;
        esac
    done
}

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
                read -p "请输docker-compose.yml所在目录: " compose_dir
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

# 8. 主函数
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

# 9. 启动主程序
main
