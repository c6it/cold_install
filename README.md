# cold_install

一键安装各种冷门科学上网协议脚本，支持TUIC、shadowsocks(2022)

```shell
curl -O https://raw.githubusercontent.com/tdjnodj/cold_install/main/cold_install.sh && bash cold_install.sh
```

# 提示
需要依赖本项目的api，所以不建议fork使用！

# PLAN

- [x] [TUIC](https://github.com/EAimTY/tuic)
- [x] [shadowsocks-rust](https://github.com/shadowsocks/shadowsocks-rust)
- [ ] shadowsocks-plugin: [v2ray](https://github.com/shadowsocks/v2ray-plugin) && [QUIC](https://github.com/shadowsocks/qtun)
- [ ] [naiveproxy](https://github.com/klzgrad/naiveproxy)
- [ ] [mieru](https://github.com/enfein/mieru/)
- [ ] [brook](https://github.com/txthinking/brook)

# 感谢

- 网络跳跃: 脚本框架
- [TxThinking](https://github.com/txthinking): [nami](https://github.com/txthinking/nami)、[joker](https://github.com/txthinking/joker)、[jinbe](https://github.com/txthinking/jinbe) 使得任何软件都能成为守护进程。
