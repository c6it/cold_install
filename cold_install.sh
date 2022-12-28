#!/bin/bash

# 字体相关
red() {
	echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
	echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
	echo -e "\033[33m\033[01m$1\033[0m"
}

[[ $EUID -ne 0 ]] && red "请在root用户下运行脚本" && exit 1

CMD=(
	"$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)"
	"$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)"
	"$(lsb_release -sd 2>/dev/null)"
	"$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)"
	"$(grep . /etc/redhat-release 2>/dev/null)"
	"$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')"
)

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[36m"
PLAIN="\033[0m"

REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS")
PACKAGE_UPDATE=("apt-get update" "apt-get update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove")

for i in "${CMD[@]}"; do
	SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
	[[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && red "不支持当前VPS系统，请使用主流的操作系统" && exit 1
[[ -z $(type -P curl) ]] && ${PACKAGE_UPDATE[int]} && ${PACKAGE_INSTALL[int]} curl

install_ss() {
    #CPU
    bit=`uname -m`
    if [[ $bit = x86_64 ]]; then
        cpu=x86_64
    elif [[ $bit = aarch64 ]]; then
        cpu=aarch64
    elif [[ $bit = arm ]]; then
        cpu=arm
        echo "使用本CPU时，可能安装失败！"
    else
        red "VPS的CPU架构为$bit 脚本不支持当前CPU架构，请使用amd64或arm64架构的CPU运行脚本" && exit
    fi

    yellow "注意: "
    yellow "1. 请先使用 101 选项  安装依赖。"
    yellow "回想一下有什么没做。"
    echo ""
    read -p "按任意键继续，按ctrl + c退出" rubbish

    read -p "请输入shadowsocks监听端口(100-65535): " port
    [[ -z "${port}" ]] && PORT=$(shuf -i200-65000 -n1)
    if [[ "${port:0:1}" == "0" ]]; then
        red "端口不能以0开头"
        exit 1
    fi
    yellow "当前监听端口: $port"

    answer="5"
    yellow "加密方式: "
    echo "注：带有2022字样的为shadowsocks-2022的加密方式，支持的客户端较少！"
    echo "已剔除不安全的加密方式！"
    red "1. 2022-blake3-chacha8-poly1305"
    red "2. 2022-blake3-chacha20-poly1305"
    red "3. 2022-blake3-aes-256-gcm"
    red "4. 2022-blake3-aes-128-gcm"
    green "5. chacha20-ietf-poly1305(默认)"
    yellow "6. aes-256-gcm"
    yellow "7. aes-128-gcm"
    red "8. plain或none (无加密！)"
    read -p "请选择加密方式: " answer
    case $answer in
        1) method="2022-blake3-chacha8-poly1305" ;;
        2) method="2022-blake3-chacha20-poly1305" ;;
        3) method="2022-blake3-aes-256-gcm" ;;
        4) method="2022-blake3-aes-128-gcm" ;;
        5) method="chacha20-ietf-poly1305" ;;
        6) method="aes-256-gcm" ;;
        7) method="aes-128-gcm" ;;
        8) method="none" ;;
        *) method="chacha20-ietf-poly1305" ;;
    esac
    yellow "当前加密方式: $method"

    green "16位密码:"
    openssl rand -base64 16
    yellow "注意： 不填将会使用32位密码"
    yellow "注意：除2022-blake3-aes-128-gcm使用16位密码外，其他2022系加密方式需要使用32位密码！其他随意"
    read -p "请输入密码: " password
    [[ -z "${password}" ]] && password=$(openssl rand -base64 32)
    yellow "当前密码： ${password}"

    # 安装
    ss_version=$(curl -k https://raw.githubusercontent.com/tdjnodj/cold_install/api/shadowsocks-rust)
    mkdir /etc/shadowsocks-rust
    cd /etc/shadowsocks-rust
    curl -O -L -k https://github.com/shadowsocks/shadowsocks-rust/releases/download/v${ss_version}/shadowsocks-v${ss_version}.${cpu}-unknown-linux-gnu.tar.xz
    tar xvf shadowsocks-v${ss_version}.${cpu}-unknown-linux-gnu.tar.xz

    yellow "正在写入配置......"
    cat >/etc/shadowsocks-rust/config.json <<-EOF
        {
            "server": "::",
            "server_port": $port,
            "password": "$password",
            "method": "$method"
        }

    
EOF
    
    start_ss
    yellow "装完了？"
    shadowshare
}

shadowshare() {
    ip=$(curl ip.sb)
    green "地址: $ip"
    green "端口: $port"
    green "加密方式: $method"
    green "密码: $password"

    echo ""
    yellow "分享链接(可能不兼容shadowsocks-2022): "
    /etc/shadowsocks-rust/ssurl -e /etc/shadowsocks-rust/ssurl
    echo "请讲ip地址改成自己的！"
}

uninstall_ss() {
    rm -rf /etc/shadowsocks-rust
}

start_ss() {
    joker /etc/shadowsocks-rust/ssserver -c /etc/shadowsocks-rust/config.json
    jinbe joker /etc/shadowsocks-rust/ssserver -c /etc/shadowsocks-rust/config.json
}

ss_menu() {
    answer="0"
    echo "shadowsocks-rust"
    yellow "1. 安装 shadowsocks-rust"
    yellow "2. 卸载 shadowsocks-rust"
    yellow "3. 启动 shadowsocks-rust"
    read -p "请选择: " answer
    case $answer in
        1) install_ss ;;
        2) uninstall_ss ;;
        3) start_ss ;;
        *) exit 1 ;;
    esac
}

uninstall_tuic() {
    sudo rm  /etc/TUIC/tuic
    sudo rm /etc/TUIC/config.json
    red "卸载成功！证书保存在 /etc/TUIC "
    echo ""
    yellow "删除证书命令: "
    echo "rm /etc/TUIC/cert.crt"
    echo "rm /etc/TUIC/key.key"
}

start_tuic() {
    joker /etc/TUIC/tuic -c /etc/TUIC/config.json
    jinbe joker /etc/TUIC/tuic -c /etc/TUIC/config.json
    yellow "TUIC 启动成功(?)"
}

tuic_menu(){
    answer="0"
    yellow "管理TUIC"
    echo ""
    yellow "1. 安装TUIC"
    yellow "2. 卸载TUIC"
    yellow "3. 启动tuic"
    echo ""
    read -p "请选择操作: " answer
    case $answer in
        1) install_tuic ;;
        2) uninstall_tuic ;;
        3) start_tuic ;;
        *) echo "请输入正确的选项！" && exit 1
    esac
}

install_tuic() {
    # 判断CPU架构
    bit=`uname -m`
    if [[ $bit = x86_64 ]]; then
        cpu=x86_64
    elif [[ $bit = aarch64 ]]; then
        cpu=aarch64
    else
        red "VPS的CPU架构为$bit 脚本不支持当前CPU架构，请使用amd64或arm64架构的CPU运行脚本" && exit
    fi


    yellow "请先确认安装条件"
    yellow "1. 已经准备好了自己的TLS证书和密钥"
    yellow "2. 确定你的运营商允许代理，以及允许大量UDP流量"
    yellow "3. 已经使用脚本的101选项安装了依赖"
    echo ""
    yellow "再回想一下自己还有什么忘做的吧"
    read -p "输入任意内容继续，按ctrl + c退出: " rubbish

    read -p "请输入tuic监听端口(100-65535): " port
    [[ -z "${port}" ]] && PORT=$(shuf -i200-65000 -n1)
    if [[ "${port:0:1}" == "0" ]]; then
        red "端口不能以0开头"
        exit 1
    fi
    yellow "当前监听端口: $port"

    read -p "请输入密码: " password
    [[ -z "$password" ]] && password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
    yellow "当前密码: $password"

    read -p "请输入证书公钥路径(完整): " cert 
    [[ -z "$cert" ]] && red "请输入路径！" && exit 1
    read -p "请输入证书私钥路径(完整): " key
    [[ -z "$key" ]] && red "请输入路径！" && exit 1
    yellow "当前证书路径: $cert"
    yellow "当前私钥路径: $key"

    read -p "alpn(不懂别填): " alpn

    tuic_version=$(curl https://raw.githubusercontent.com/tdjnodj/cold_install/api/TUIC -k)
    yellow "当前TUIC版本: $tuic_version"
    yellow "开始下载"
    mkdir /etc/TUIC
    cd /etc/TUIC
    curl -O -k -L https://github.com/EAimTY/tuic/releases/download/${tuic_version}/tuic-server-${tuic_version}-${cpu}-linux-gnu
    mv tuic-server-${tuic_version}-${cpu}-linux-gnu tuic
    chmod +x tuic

    yellow "正在写入配置......"
    cp $cert /etc/TUIC/cert.crt
    cp $cert /etc/TUIC/key.key
    touch /etc/TUIC/config.json

    cat >/etc/TUIC/config.json <<-EOF
        {
            "port": $port,
            "token": [ "$password" ],
            "certificate": "/etc/TUIC/cert.crt",
            "private_key": "/etc/TUIC/key.key",

            "congestion_controller": "bbr",
            "alpn": [ "alpn" ]
        }

EOF

    start_tuic

    red "大概安装完了吧......"
    echo ""

    green  "客户端填写信息如下，请妥善保存。"
    yellow "server: 你的域名"
    yellow "port: $port"
    yellow "token: $password"
    yellow "ip: 你的域名或服务器的ip"
    yellow "alpn: $alpn"
}

install_base() {
    yellow "手动执行以下命令: "
    echo "bash <(curl https://bash.ooo/nami.sh)"
    echo "nami install joker"
    echo "nami install jinbe"
}

client_config() {
    yellow "提示： 请先安装python3"
    curl -k -O -L https://raw.githubusercontent.com/tdjnodj/science_config_maker/main/science_config_maker.py && python3 science_config_maker.py
}

menu() {
    clear
    answer="0"
    echo "冷门协议安装一键脚本"
    echo "快捷命令: bash cold_install.sh"
    echo "-----------------------"
    echo "1. TUIC"
    echo "2. shadowsocks-rust"
    echo "-----------------------"
    echo "101. 安装/升级本脚本必须依赖"
    echo ""
    echo "如果你之前没选择过101，请先选择！"
    echo ""
    echo "102. 生成客户端配置"
    echo "0. 退出"
    echo ""
    read -p "请选择操作: " answer
    case $answer in
        0) exit 1 ;;
        1) tuic_menu ;;
        2) ss_menu ;;
        101) install_base ;;
        102) client_config ;;
        *) echo "请输入正确的选项！" && exit 1
    esac
}

action=$1
[[ -z $1 ]] && action=menu

# 偷来的
case "$action" in
	menu | update | uninstall | start | restart | stop | showInfo | showLog) ${action} ;;
	*) echo " 参数错误" && echo " 用法: $(basename $0) [menu|update|uninstall|start|restart|stop|showInfo|showLog]" ;;
esac
