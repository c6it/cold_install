#!/bin/bash

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

install_tuic() {
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
    yellow "回想一下自己还有什么忘做的"
    read -p "输入任意内容继续，按ctrl + c退出: " rubbish

    read -p "请输入tuic监听端口(100-65535): " port
    [[ -z "${PORT}" ]] && PORT=$(shuf -i200-65000 -n1)
    if [[ "${PORT:0:1}" == "0" ]]; then
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

    tuic_version=$(curl https://raw.githubusercontent.com/tdjnodj/cold_install/api/TUIC -k)
    yellow "当前TUIC版本: $tuic_version"
    yellow "开始下载"
    mkdir /etc/TUIC
    cd /etc/TUIC
    curl -O -k -L https://github.com/EAimTY/tuic/releases/download/${tuic_version}/tuic-server-${tuic_version}-${cpu}-linux-gnu
    mv tuic-server-${tuic_version}-${cpu}-linux-gnu tuic
    chmod +x tuic

    yellow "正在写入配置......"
    cp $cert /etc/tuic/cert.cert
    cp $cert /etc/tuic/key.key
    touch /etc/tuic/config.json

    cat >/etc/tuic/config.json <<-EOF
        {
            "port": $port,
            "token": "$password",
            "certificate": "/etc/tuic/cert.crt",
            "private_key": "/etc/tuic/key.key",

            "congestion_controller": "bbr",
            "alpn": "h3"
        }

EOF

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
    yellow "正在安装 nami......"
    bash <(curl https://bash.ooo/nami.sh)
    yellow "正在安装joker......"
    nami install joker
    yellow "正在安装jinbe......"
    nami install jinbe
    yellow "安装完成！(大概吧"
}

client_config() {
    yellow "提示： 请先安装python3"
    curl -k -O -L https://raw.githubusercontent.com/tdjnodj/science_config_maker/main/science_config_maker.py && python3 science_config_maker.py
}

menu() {
    clear
    echo "冷门协议安装一键脚本"
    echo "快捷命令: bash cold_install.sh"
    echo "-----------------------"
    echo "1. 安装TUIC"
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
        1) install_tuic ;;
        101) install_base ;;
        102) client_config ;;
        *) echo "请输入正确的选项！" && exit 1
    esac
}
