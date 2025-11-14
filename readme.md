
# 说明 

因serv00服务器要求，如果用户帐户在 90 天内未通过 DevilWEB 或 SSH 面板正确登录，则该帐户将自动从系统中删除，并且无法恢复该帐户收集的数据。

本仓库将用于定时自动化登录serv00的SSH连接执行指令并推送通知，可以实现定期登录保号的作用

tg交流群：[https://t.me/zzzjsjl](https://t.me/zzzjsjl)

**希望大家点个Star🌟🌟🌟支持下**

### 准备工作

- 一个GitHub账号。
- Fork本仓库
- 准备好serv00账号
- 获取您的 Telegram 用户或群组的 Chat ID。

- 在您的 GitHub 仓库中设置以下 Secrets：



### 配置Secrets

- 进入你fork本仓库后自己的仓库页面>“Settings” > “Secrets”中添加以下Secrets：

- `SSH_INFO`：包含SSH连接信息的JSON字符串。以下是示例

  ```json
  [
    {"hostname": "服务器号", "username": "用户名", "password": "密码"},
    {"hostname": "s5.serv00.com", "username": "user", "password": "password"},
    {"hostname": "s6.serv00.com", "username": "user6", "password": "password6"}
  ]
  ```
- ~PUSHPLUS_TOKEN：pushplus申请的token~
- **新版已经将pushplus推送移除，请勿添加PUSHPLUS_TOKEN变量**
- **新版已经将pushplus推送移除，请勿添加PUSHPLUS_TOKEN变量**
- **新版已经将pushplus推送移除，请勿添加PUSHPLUS_TOKEN变量**
- TELEGRAM_BOT_TOKEN：您的 Telegram Bot API Token。示例：`733255939:AAHsoQf-3lOoc1xC8le2d58qlfrCqEXzu74`
- TELEGRAM_CHAT_ID：您的 Telegram Chat ID（可以是您的私人聊天或群组）。示例：`5329499650`
- PUSH：推送渠道值为`mail`或者`telegram`。示例：`mail`
- MAIL：接收通知的邮箱。示例：`mail@mail.com`






### 测试运行

- 在GitHub仓库的“Actions”选项卡中，手动触发运行一次工作流程。
- “Actions”页面>"Run SSH Login">"Run workflow">"Run workflow"
- 检查运行结果，没有报错说明就是运行成功了，可以点击运行记录的列表进去查看运行的详细情况
- 本地开发或调试时，可以运行 `python -m compileall run.py` 来快速检查 `run.py` 是否存在语法错误。该命令会调用 Python 内置的 `compileall` 模块尝试编译文件，如果命令成功退出，就说明文件可以被 Python 解释器正常加载。

### Economist 期刊下载核对

- 工作流会通过 `ebook-convert "$GITHUB_WORKSPACE/recipes/The Economist.recipe" "$(date +%Y%m%d).epub"` 下载 EPUB，以确保始终使用仓库中经过验证的配方。
- 如果你已经在本地安装了 [Calibre](https://calibre-ebook.com/)，可以运行 `./scripts/manual_ebook_check.sh` 来复现同样的命令，脚本会在 `eco/` 目录下生成当天日期的 EPUB 并在结束时确认文件存在。如果系统缺少 `ebook-convert` 且支持 `apt-get`，脚本会自动尝试通过 `apt-get install --no-install-recommends calibre` 安装 Calibre。脚本默认使用仓库 `recipes/The Economist.recipe` 文件，它在官方版本基础上做了兼容性修正，以适配最新的网页结构。
- 之所以需要在仓库中自带该配方，是因为 The Economist 的 API 会不定期返回包含 `rubric` 或 `flyTitle` 字段的字典对象，而 Calibre 内置的原始配方假定这些字段始终是简单字符串，从而导致转换过程抛出异常。通过内置补丁后的配方，我们可以主动将这些字段转换为字符串，保证 GitHub Action 和本地校验脚本在网站结构变更时依然稳定运行。
- 如果脚本无法自动安装 Calibre，会明确提示你需要手动安装依赖；若下载环节因为代理/网络限制而失败，脚本也会保留 Calibre 的错误信息并提示你检查网络环境。



### 定时自动运行

- 此工作流默认每月的 5号 北京时间 19 点运行

- 可以根据自己的需求调整运行时间

  ```yaml
  - cron: '0 11 5 * *'  # 每月的 5号 北京时间 19 点运行
  ```

  

### 注意事项

- **保密性**: Secrets 是敏感信息，请确保不要将它们泄露到公共代码库或未授权的人员。
- **更新和删除**: 如果需要更新或删除 Secrets，可以通过仓库的 Secrets 页面进行管理。

通过以上步骤，你就可以成功将代码 fork 到你的仓库下并运行它了。如果需要进一步的帮助或有其他问题，请随时告知！
