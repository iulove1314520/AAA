#!/bin/bash

# 显示主菜单
show_menu() {
    clear
    echo "================================"
    echo "      系统管理脚本 v1.0         "
    echo "================================"
    echo "1. 显示系统信息"
    echo "2. 系统配置管理"
    echo "0. 退出"
    echo "================================"
}

# 显示系统信息菜单
show_system_menu() {
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
    echo "0. 返回主菜单"
    echo "================================"
}

# 显示基本系统信息
show_basic_info() {
    clear
    echo "=========== 基本系统信息 ==========="
    echo "操作系统：" $(cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2)
    echo "主机名：" $(hostname)
    echo "内核版本：" $(uname -r)
    echo "系统运行时间：" $(uptime -p)
    echo "当前时区：" $(timedatectl show --property=Timezone --value)
    echo "系统时间：" $(date "+%Y-%m-%d %H:%M:%S %Z")
    echo "UTC时间：" $(date -u "+%Y-%m-%d %H:%M:%S UTC")
    echo "======================================"
    read -p "按回车键返回..."
}

# 显示CPU信息
show_cpu_info() {
    clear
    echo "============= CPU信息 ============="
    echo "CPU型号：" $(cat /proc/cpuinfo | grep "model name" | head -n1 | cut -d: -f2)
    echo "CPU核心数：" $(nproc)
    echo "CPU使用率：" $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')"%"
    echo "CPU负载：" $(uptime | awk -F'load average:' '{print $2}')
    echo "======================================"
    read -p "按回车键返回..."
}

# 显示内存信息
show_memory_info() {
    clear
    echo "============ 内存信息 ============"
    echo "内存总量：" $(free -h | grep Mem | awk '{print $2}')
    echo "已用内存：" $(free -h | grep Mem | awk '{print $3}')
    echo "可用内存：" $(free -h | grep Mem | awk '{print $4}')
    echo "内存使用率：" $(free | grep Mem | awk '{printf "%.2f%", $3/$2 * 100}')
    echo "交换空间总量：" $(free -h | grep Swap | awk '{print $2}')
    echo "已用交换空间：" $(free -h | grep Swap | awk '{print $3}')
    echo "======================================"
    read -p "按回车键返回..."
}

# 显示磁盘信息
show_disk_info() {
    clear
    echo "============ 磁盘信息 ============"
    echo "磁盘分区使用情况："
    echo "-----------------------------------"
    df -h | grep '^/dev/' | awk '{printf "%-20s\n总容量：%-8s\n已用：%-8s\n可用：%-8s\n使用率：%s\n-----------------------------------\n", $6, $2, $3, $4, $5}'
    echo "======================================"
    read -p "按回车键返回..."
}

# 显示网络信息
show_network_info() {
    clear
    echo "============ 网络信息 ============"
    echo "IP地址：" $(hostname -I)
    echo "活动连接数：" $(netstat -an | grep ESTABLISHED | wc -l)
    echo "网络接口信息："
    echo "-----------------------------------"
    ip addr | grep -E '^[0-9]+:|inet' | grep -v '127.0.0.1'
    echo "======================================"
    read -p "按回车键返回..."
}

# 系统信息主函数
show_system_info() {
    while true; do
        show_system_menu
        read -p "请输入您的选择 [0-6]: " choice
        
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
                clear
                show_basic_info
                echo
                show_cpu_info
                echo
                show_memory_info
                echo
                show_disk_info
                echo
                show_network_info
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

# 显示用户管理菜单
show_user_menu() {
    clear
    echo "================================"
    echo "         用户管理菜单           "
    echo "================================"
    echo "1. 显示用户列表"
    echo "2. 添加新用户"
    echo "3. 删除用户"
    echo "4. 修改用户密码"
    echo "5. 显示在线用户"
    echo "0. 返回上级菜单"
    echo "================================"
}

# 显示用户列表
show_user_list() {
    clear
    echo "=========== 系统用户列表 ==========="
    echo "用户名         UID      主目录            Shell"
    echo "----------------------------------------"
    awk -F: '$3 >= 1000 && $3 != 65534 {printf "%-14s %-8s %-18s %s\n", $1, $3, $6, $7}' /etc/passwd
    echo "========================================"
    read -p "按回车键返回..."
}

# 添加新用户
add_new_user() {
    clear
    echo "============ 添加新用户 ============"
    read -p "请输入新用户名: " username
    
    if id "$username" >/dev/null 2>&1; then
        echo "错误：用户 '$username' 已存在！"
    else
        # 获取密码
        while true; do
            read -s -p "请输入密码: " password
            echo
            read -s -p "请确认密码: " password2
            echo
            if [ "$password" = "$password2" ]; then
                break
            else
                echo "错误：两次输入的密码不匹配！请重试..."
            fi
        done

        # 设置用户组
        read -p "是否将用户添加到sudo组(y/n)? " add_sudo
        if [[ $add_sudo =~ ^[Yy]$ ]]; then
            sudo_group="sudo"
            # 部分发行版使用wheel组
            if grep -q "^wheel:" /etc/group; then
                sudo_group="wheel"
            fi
        fi

        # 设置家目录
        read -p "是否创建家目录(y/n)? [y] " create_home
        home_opt="-m"
        if [[ $create_home =~ ^[Nn]$ ]]; then
            home_opt="-M"
        fi

        # 设置shell
        echo "请选择用户的默认shell："
        echo "1) /bin/bash (默认)"
        echo "2) /bin/sh"
        echo "3) /bin/zsh"
        read -p "请选择 [1-3]: " shell_choice
        case $shell_choice in
            2) user_shell="/bin/sh" ;;
            3) user_shell="/bin/zsh" ;;
            *) user_shell="/bin/bash" ;;
        esac

        # 创建用户
        if [[ $add_sudo =~ ^[Yy]$ ]]; then
            useradd $home_opt -s "$user_shell" -G "$sudo_group" "$username"
        else
            useradd $home_opt -s "$user_shell" "$username"
        fi

        # 设置密码
        echo "$username:$password" | chpasswd

        if [ $? -eq 0 ]; then
            echo "用户 '$username' 创建成功！"
            echo "用户信息："
            echo "------------------------"
            echo "用户名: $username"
            echo "家目录: $(grep "^$username:" /etc/passwd | cut -d: -f6)"
            echo "Shell: $user_shell"
            if [[ $add_sudo =~ ^[Yy]$ ]]; then
                echo "附加组: $sudo_group"
            fi
            
            # 设置家目录权限
            if [[ ! $create_home =~ ^[Nn]$ ]]; then
                user_home=$(grep "^$username:" /etc/passwd | cut -d: -f6)
                chown -R "$username:$username" "$user_home"
                chmod 700 "$user_home"
            fi

            # 询问是否设置账户过期时间
            read -p "是否设置账户过期时间(y/n)? " set_expire
            if [[ $set_expire =~ ^[Yy]$ ]]; then
                read -p "请输入账户有效天数: " expire_days
                if [[ "$expire_days" =~ ^[0-9]+$ ]]; then
                    chage -M "$expire_days" "$username"
                    echo "已设置账户 $expire_days 天后过期"
                fi
            fi
        else
            echo "创建用户失败，请检查权限！"
        fi
    fi
    read -p "按回车键返回..."
}

# 删除用户
delete_user() {
    clear
    echo "============ 删除用户 ============"
    read -p "请输入要删除的用户名: " username
    
    if [ "$username" = "root" ]; then
        echo "错误：不能删除root用户！"
        read -p "按回车键返回..."
        return
    fi
    
    if id "$username" >/dev/null 2>&1; then
        # 显示用户信息
        echo "用户信息："
        echo "------------------------"
        echo "用户名: $username"
        echo "UID: $(id -u "$username")"
        echo "主组: $(id -gn "$username")"
        echo "附加组: $(id -Gn "$username")"
        echo "家目录: $(grep "^$username:" /etc/passwd | cut -d: -f6)"
        echo "------------------------"
        
        read -p "确认要删除此用户吗(y/n)? " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            read -p "是否删除用户的家目录和邮件池(y/n)? " del_home
            read -p "是否备份用户数据(y/n)? " backup
            
            if [[ $backup =~ ^[Yy]$ ]]; then
                backup_dir="/tmp/user_backup_${username}_$(date +%Y%m%d)"
                user_home=$(grep "^$username:" /etc/passwd | cut -d: -f6)
                mkdir -p "$backup_dir"
                cp -r "$user_home" "$backup_dir/"
                echo "用户数据已备份到 $backup_dir"
            fi
            
            if [[ $del_home =~ ^[Yy]$ ]]; then
                userdel -r "$username"
            else
                userdel "$username"
            fi
            
            if [ $? -eq 0 ]; then
                echo "用户 '$username' 已成功删除！"
                if [[ $backup =~ ^[Yy]$ ]]; then
                    echo "数据备份位置: $backup_dir"
                fi
            else
                echo "删除用户失败，请检查权限！"
            fi
        else
            echo "已取消删除操作"
        fi
    else
        echo "错误：用户 '$username' 不存在！"
    fi
    read -p "按回车键返回..."
}

# 修改用户密码
change_user_password() {
    clear
    echo "========== 修改用户密码 =========="
    read -p "请输入用户名: " username
    
    if [ "$username" = "root" ] && [ "$EUID" -ne 0 ]; then
        echo "错误：修改root密码需要root权限！"
        read -p "按回车键返回..."
        return
    fi
    
    if id "$username" >/dev/null 2>&1; then
        echo "选择密码修改选项："
        echo "1) 直接修改密码"
        echo "2) 强制用户下次登录时修改密码"
        echo "3) 设置密码过期时间"
        read -p "请选择 [1-3]: " pwd_option
        
        case $pwd_option in
            1)
                passwd "$username"
                ;;
            2)
                passwd -e "$username"
                echo "已设置用户 $username 下次登录时必须修改密码"
                ;;
            3)
                read -p "请输入密码有效天数: " expire_days
                if [[ "$expire_days" =~ ^[0-9]+$ ]]; then
                    chage -M "$expire_days" "$username"
                    echo "已设置密码 $expire_days 天后过期"
                else
                    echo "无效的天数输入"
                fi
                ;;
            *)
                echo "无效的选择"
                ;;
        esac
    else
        echo "错误：用户 '$username' 不存在！"
    fi
    read -p "按回车键返回..."
}

# 显示在线用户
show_online_users() {
    clear
    echo "=========== 在线用户列表 ==========="
    echo "用户名    终端    登录时间    来源"
    echo "----------------------------------------"
    who | awk '{printf "%-10s %-8s %-12s %s\n", $1, $2, $3" "$4, $5}'
    echo "========================================"
    read -p "按回车键返回..."
}

# 用户管理主函数
user_management() {
    while true; do
        show_user_menu
        read -p "请输入您的选择 [0-5]: " choice
        
        case $choice in
            1)
                show_user_list
                ;;
            2)
                add_new_user
                ;;
            3)
                delete_user
                ;;
            4)
                change_user_password
                ;;
            5)
                show_online_users
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

# 系统配置菜单
show_system_config_menu() {
    clear
    echo "================================"
    echo "       系统配置管理菜单         "
    echo "================================"
    echo "1. 用户管理"
    echo "2. 时区管理"
    echo "3. Hosts配置"
    echo "0. 返回主菜单"
    echo "================================"
}

# 系统配置管理主函数
system_config() {
    while true; do
        show_system_config_menu
        read -p "请输入您的选择 [0-3]: " choice
        
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

# 添加时区管理函数
manage_timezone() {
    while true; do
        clear
        echo "============ 时区管理 ============"
        echo "当前时区：" $(timedatectl show --property=Timezone --value)
        echo "当前时间：" $(date "+%Y-%m-%d %H:%M:%S %Z")
        echo "--------------------------------"
        echo "1. 按洲际选择时区"
        echo "2. 搜索时区"
        echo "3. 设置为UTC时区"
        echo "4. 设置为Asia/Shanghai时区"
        echo "5. 同步系统时间"
        echo "0. 返回上级菜单"
        echo "================================"
        
        read -p "请输入您的选择 [0-5]: " choice
        
        case $choice in
            1)
                select_timezone_by_region
                ;;
            2)
                search_timezone
                ;;
            3)
                if timedatectl set-timezone UTC; then
                    echo "已将时区设置为 UTC"
                else
                    echo "设置时区失败，请检查权限！"
                fi
                read -p "按回车键继续..."
                ;;
            4)
                if timedatectl set-timezone Asia/Shanghai; then
                    echo "已将时区设置为 Asia/Shanghai"
                else
                    echo "设置时区失败，请检查权限！"
                fi
                read -p "按回车键继续..."
                ;;
            5)
                echo "正在同步系统时间..."
                if timedatectl set-ntp true; then
                    echo "系统时间同步成功！"
                else
                    echo "时间同步失败，请检查网络连接和NTP服务！"
                fi
                read -p "按回车键继续..."
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

# 按洲际选择时区
select_timezone_by_region() {
    clear
    echo "========== 选择时区区域 =========="
    regions=($(timedatectl list-timezones | cut -d'/' -f1 | sort -u))
    
    # 显示区域列表
    echo "可用的区域："
    for i in "${!regions[@]}"; do
        echo "$((i+1)). ${regions[i]}"
    done
    
    read -p "请选择区域编号: " region_num
    if [ "$region_num" -gt 0 ] && [ "$region_num" -le "${#regions[@]}" ]; then
        selected_region=${regions[$((region_num-1))]}
        
        # 显示选定区域的城市
        clear
        echo "========== 选择城市 =========="
        cities=($(timedatectl list-timezones | grep "^$selected_region/" | cut -d'/' -f2- | sort))
        
        echo "可用的城市："
        for i in "${!cities[@]}"; do
            echo "$((i+1)). ${cities[i]}"
        done
        
        read -p "请选择城市编号: " city_num
        if [ "$city_num" -gt 0 ] && [ "$city_num" -le "${#cities[@]}" ]; then
            selected_timezone="$selected_region/${cities[$((city_num-1))]}"
            if timedatectl set-timezone "$selected_timezone"; then
                echo "已将时区设置为 $selected_timezone"
            else
                echo "设置时区失败，请检查权限！"
            fi
        else
            echo "无效的选择！"
        fi
    else
        echo "无效的选择！"
    fi
    read -p "按回车键继续..."
}

# 搜索时区
search_timezone() {
    clear
    echo "============ 搜索时区 ============"
    read -p "请输入要搜索的时区关键字: " search_key
    
    if [ -n "$search_key" ]; then
        results=($(timedatectl list-timezones | grep -i "$search_key"))
        
        if [ ${#results[@]} -eq 0 ]; then
            echo "未找到匹配的时区！"
        else
            echo "找到以下匹配的时区："
            for i in "${!results[@]}"; do
                echo "$((i+1)). ${results[i]}"
            done
            
            read -p "请选择时区编号(0取消): " tz_num
            if [ "$tz_num" -gt 0 ] && [ "$tz_num" -le "${#results[@]}" ]; then
                selected_timezone=${results[$((tz_num-1))]}
                if timedatectl set-timezone "$selected_timezone"; then
                    echo "已将时区设置为 $selected_timezone"
                else
                    echo "设置时区失败，请检查权限！"
                fi
            elif [ "$tz_num" -ne 0 ]; then
                echo "无效的选择！"
            fi
        fi
    else
        echo "请输入有效的搜索关键字！"
    fi
    read -p "按回车键继续..."
}

# 添加hosts管理菜单
show_hosts_menu() {
    clear
    echo "================================"
    echo "         Hosts配置菜单          "
    echo "================================"
    echo "1. 查看当前主机名"
    echo "2. 修改主机名"
    echo "3. 查看hosts文件"
    echo "4. 添加hosts记录"
    echo "5. 删除hosts记录"
    echo "6. 修改hosts记录"
    echo "7. 备份hosts文件"
    echo "8. 恢复hosts文件"
    echo "0. 返回上级菜单"
    echo "================================"
}

# hosts管理主函数
manage_hosts() {
    while true; do
        show_hosts_menu
        read -p "请输入您的选择 [0-8]: " choice
        
        case $choice in
            1)
                show_hostname
                ;;
            2)
                change_hostname
                ;;
            3)
                view_hosts
                ;;
            4)
                add_hosts_entry
                ;;
            5)
                delete_hosts_entry
                ;;
            6)
                modify_hosts_entry
                ;;
            7)
                backup_hosts
                ;;
            8)
                restore_hosts
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

# 显示当前主机名
show_hostname() {
    clear
    echo "=========== 当前主机名信息 ==========="
    echo "主机名：" $(hostname)
    echo "完整主机名：" $(hostname -f)
    echo "DNS域名：" $(hostname -d)
    echo "IP地址：" $(hostname -i)
    echo "======================================="
    read -p "按回车键返回..."
}

# 修改主机名
change_hostname() {
    clear
    echo "============ 修改主机名 ============"
    current_hostname=$(hostname)
    echo "当前主机名：$current_hostname"
    read -p "请输入新的主机名: " new_hostname
    
    if [ -n "$new_hostname" ]; then
        # 备份hosts文件
        sudo cp /etc/hosts /etc/hosts.bak
        
        # 修改主机名
        if sudo hostnamectl set-hostname "$new_hostname"; then
            # 更新 /etc/hosts 文件中的所有相关条目
            # 1. 更新 127.0.1.1 对应的主机名
            if grep -q "^127.0.1.1" /etc/hosts; then
                sudo sed -i "s/^127.0.1.1.*$/127.0.1.1\t$new_hostname/g" /etc/hosts
            else
                # 如果不存在 127.0.1.1 条目，则添加
                echo "127.0.1.1\t$new_hostname" | sudo tee -a /etc/hosts > /dev/null
            fi
            
            # 2. 更新 127.0.0.1 对应的主机名（如果包含旧主机名）
            if grep -q "^127.0.0.1.*$current_hostname" /etc/hosts; then
                sudo sed -i "s/\b$current_hostname\b/$new_hostname/g" /etc/hosts
            fi
            
            # 3. 确保基本的 localhost 条目存在
            if ! grep -q "^127.0.0.1.*localhost" /etc/hosts; then
                echo "127.0.0.1\tlocalhost" | sudo tee -a /etc/hosts > /dev/null
            fi
            
            echo "主机名已成功修改为：$new_hostname"
            echo "hosts文件已更新"
            echo
            echo "当前hosts文件内容："
            echo "-----------------------------------"
            cat /etc/hosts
            echo "-----------------------------------"
            echo "注意：某些服务可能需要重启才能生效"
            
            # 提示是否需要恢复
            read -p "是否确认更改？(y/n): " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                sudo cp /etc/hosts.bak /etc/hosts
                sudo hostnamectl set-hostname "$current_hostname"
                echo "已恢复到原始设置"
            else
                echo "更改已保存"
            fi
            
            # 清理备份文件
            sudo rm -f /etc/hosts.bak
        else
            echo "修改主机名失败，请检查权限！"
            # 恢复hosts文件
            sudo cp /etc/hosts.bak /etc/hosts
            sudo rm -f /etc/hosts.bak
        fi
    else
        echo "主机名不能为空！"
    fi
    read -p "按回车键返回..."
}

# 查看hosts文件
view_hosts() {
    clear
    echo "============ 当前hosts文件内容 ============"
    echo
    cat /etc/hosts
    echo
    echo "==========================================="
    read -p "按回车键返回..."
}

# 添加hosts记录
add_hosts_entry() {
    clear
    echo "============ 添加hosts记录 ============"
    read -p "请输入IP地址: " ip
    read -p "请输入主机名: " hostname
    
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [ -n "$hostname" ]; then
        # 检查是否已存在
        if grep -q "^$ip.*$hostname" /etc/hosts; then
            echo "错误：该记录已存在！"
        else
            if sudo sh -c "echo '$ip\t$hostname' >> /etc/hosts"; then
                echo "hosts记录添加成功！"
            else
                echo "添加hosts记录失败，请检查权限！"
            fi
        fi
    else
        echo "无效的IP地址或主机名！"
    fi
    read -p "按回车键返回..."
}

# 删除hosts记录
delete_hosts_entry() {
    clear
    echo "============ 删除hosts记录 ============"
    echo "当前hosts文件内容："
    echo "-----------------------------------"
    cat -n /etc/hosts
    echo "-----------------------------------"
    read -p "请输入要删除的行号: " line_num
    
    if [[ "$line_num" =~ ^[0-9]+$ ]]; then
        if [ "$line_num" -le "$(wc -l < /etc/hosts)" ]; then
            echo "将要删除的行："
            sed -n "${line_num}p" /etc/hosts
            read -p "确认删除吗？(y/n): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                if sudo sed -i "${line_num}d" /etc/hosts; then
                    echo "记录已成功删除！"
                else
                    echo "删除失败，请检查权限！"
                fi
            fi
        else
            echo "行号超出范围！"
        fi
    else
        echo "请输入有效的行号！"
    fi
    read -p "按回车键返回..."
}

# 修改hosts记录
modify_hosts_entry() {
    clear
    echo "============ 修改hosts记录 ============"
    echo "当前hosts文件内容："
    echo "-----------------------------------"
    cat -n /etc/hosts
    echo "-----------------------------------"
    read -p "请输入要修改的行号: " line_num
    
    if [[ "$line_num" =~ ^[0-9]+$ ]]; then
        if [ "$line_num" -le "$(wc -l < /etc/hosts)" ]; then
            echo "当前行内容："
            sed -n "${line_num}p" /etc/hosts
            read -p "请输入新的IP地址: " ip
            read -p "请输入新的主机名: " hostname
            
            if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [ -n "$hostname" ]; then
                if sudo sed -i "${line_num}c\\${ip}\t${hostname}" /etc/hosts; then
                    echo "记录已成功修改！"
                else
                    echo "修改失败，请检查权限！"
                fi
            else
                echo "无效的IP地址或主机名！"
            fi
        else
            echo "行号超出范围！"
        fi
    else
        echo "请输入有效的行号！"
    fi
    read -p "按回车键返回..."
}

# 备份hosts文件
backup_hosts() {
    clear
    echo "============ 备份hosts文件 ============"
    backup_dir="/etc/hosts.backup"
    backup_file="${backup_dir}/hosts.$(date +%Y%m%d_%H%M%S)"
    
    # 创建备份目录
    if [ ! -d "$backup_dir" ]; then
        if ! sudo mkdir -p "$backup_dir"; then
            echo "创建备份目录失败！"
            read -p "按回车键返回..."
            return
        fi
    fi
    
    # 备份文件
    if sudo cp /etc/hosts "$backup_file"; then
        echo "hosts文件已备份到：$backup_file"
    else
        echo "备份失败，请检查权限！"
    fi
    read -p "按回车键返回..."
}

# 恢复hosts文件
restore_hosts() {
    clear
    echo "============ 恢复hosts文件 ============"
    backup_dir="/etc/hosts.backup"
    
    if [ ! -d "$backup_dir" ]; then
        echo "未找到备份目录！"
        read -p "按回车键返回..."
        return
    fi
    
    echo "可用的备份文件："
    echo "-----------------------------------"
    ls -lt "$backup_dir" | grep -v '^total'
    echo "-----------------------------------"
    read -p "请输入要恢复的备份文件名: " backup_file
    
    if [ -f "$backup_dir/$backup_file" ]; then
        if sudo cp "$backup_dir/$backup_file" /etc/hosts; then
            echo "hosts文件已恢复！"
        else
            echo "恢复失败，请检查权限！"
        fi
    else
        echo "备份文件不存在！"
    fi
    read -p "按回车键返回..."
}

# 主程序循环
while true; do
    show_menu
    read -p "请输入您的选择 [0-2]: " choice
    
    case $choice in
        1)
            show_system_info
            ;;
        2)
            system_config
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
