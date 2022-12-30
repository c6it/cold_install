# cold_install

一键安装各种冷门科学上网协议脚本，支持TUIC、shadowsocks(2022)、naiveproxy

```shell
curl -O https://raw.githubusercontent.com/tdjnodj/cold_install/main/cold_install.sh && bash cold_install.sh
```

# 提示
需要依赖本项目的api，所以不建议fork使用！

# 项目理念

我相信很大一部分的人搭建节点都是x-ui，剩下的用的脚本也大多数是xray的。另一大部分则是支持v2fly的人。目前由于`hi_hy`脚本，所以用hysteria的人也挺多。我厌倦了主流，开始使用各种冷门的协议。

不是这些协议不够好，而是支持少：一键脚本少，客户端更少。

在使用了[nekoray](https://github.com/MatsuriDayo/nekoray)后，我被作者精心设计的自定义内核震惊了，它让我更简单地使用各种内核。我想：既然客户端这个大难题被解决了，服务端也不能落后！于是，这个项目诞生了。

> 缤纷色彩闪出的美丽 是因它没有 分开每种色彩  --Beyond 《光辉岁月》

百家争鸣，百花齐放，百舸争流。

# PLAN

- [x] [TUIC](https://github.com/EAimTY/tuic)
- [x] [shadowsocks-rust](https://github.com/shadowsocks/shadowsocks-rust)
- [ ] shadowsocks-plugin: [v2ray](https://github.com/shadowsocks/v2ray-plugin) && [QUIC](https://github.com/shadowsocks/qtun) && [KCP](https://github.com/xtaci/kcptun)
- [ ] [naiveproxy](https://github.com/klzgrad/naiveproxy)
- [ ] [mieru](https://github.com/enfein/mieru/)
- [ ] [brook](https://github.com/txthinking/brook)
- [ ] [shadow-tls](https://github.com/ihciah/shadow-tls)
- [ ] [trojan-gfw](https://github.com/trojan-gfw/trojan)

# 感谢

- 网络跳跃: 脚本框架
- [TxThinking](https://github.com/txthinking): [nami](https://github.com/txthinking/nami)、[joker](https://github.com/txthinking/joker)、[jinbe](https://github.com/txthinking/jinbe) 使得任何软件都能成为守护进程。
- naiveproxy: [不良林](https://bulianglin.com)提供的caddyfile。 [taffychan](https://github.com/taffychan/)制作的[脚本](https://github.com/taffychan/naivetest)。 [crazypeace](https://github.com/crazypeace)的[脚本](https://github.com/crazypeace/naive)。 以及伟大原作者[klzgrad](https://github.com/klzgrad/)
