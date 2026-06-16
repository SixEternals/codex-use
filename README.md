# codex-use 便携版

单命令切换 Codex 中转站/profile，用完自动恢复默认配置。

## 安装

```bash
bash setup.sh
```

## 目录结构

```
~/.codex-pool/          # 配置池（手动管理）
  ├── station_a/
  │   ├── config.toml   # 明文，端点+模型配置
  │   └── auth.json     # 明文，API Key
  └── station_b/
      ├── config.toml
      └── auth.json

~/bin/
  ├── codex             # 透传 wrapper
  └── codex-use         # profile 切换脚本
```

## 日常使用

```bash
codex-use station_a     # 切到中转站 A，进入子 shell
codex "写代码"          # 走 A 站额度
exit                    # 退出，自动恢复默认配置

codex-use station_b     # 切到中转站 B
# ...

codex-use               # 不带参数，列出所有可用配置
```

## 原理

`codex-use` 做的事：
1. 备份 `~/.codex/config.toml` 和 `~/.codex/auth.json`
2. 从 `~/.codex-pool/<profile>/` 复制配置过去
3. 启动子 shell（提示符带 profile 名）
4. `exit` 时 trap 自动恢复备份

## 从服务器加密版迁移

服务器版（`/home/to/your/path/setup_ai_vault.sh`）有 GPG 加密 + 密码保护，适用共享服务器。
便携版去掉了所有加密逻辑，适用个人电脑。
