import os
import paramiko
import requests
import json
from datetime import datetime, timezone, timedelta

def ssh_multiple_connections(hosts_info, command):
    users = []
    hostnames = []
    for host_info in hosts_info:
        hostname = host_info['hostname']
        username = host_info['username']
        password = host_info['password']
        try:
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(hostname=hostname, port=22, username=username, password=password)
            stdin, stdout, stderr = ssh.exec_command(command)
            user = stdout.read().decode().strip()
            users.append(user)
            hostnames.append(hostname)
            ssh.close()
        except Exception as e:
            print(f"用户：{username}，连接 {hostname} 时出错: {str(e)}")
    return users, hostnames

ssh_info_str = os.getenv('SSH_INFO', '[]')
hosts_info = json.loads(ssh_info_str)

command = 'whoami'
user_list, hostname_list = ssh_multiple_connections(hosts_info, command)
user_num = len(user_list)
content = "SSH服务器登录信息：\n"
for user, hostname in zip(user_list, hostname_list):
    content += f"用户名：{user}，服务器：{hostname}\n"
beijing_timezone = timezone(timedelta(hours=8))
time = datetime.now(beijing_timezone).strftime('%Y-%m-%d %H:%M:%S')
menu = requests.get('https://api.zzzwb.com/v1?get=tg').json()
loginip = requests.get('https://api.ipify.org?format=json').json()['ip']
content += f"本次登录用户共： {user_num} 个\n登录时间：{time}\n登录IP：{loginip}"

push = os.getenv('PUSH')

def mail_push(url):
    data = {
        "body": content,
        "email": os.getenv('MAIL')
    }

    response = requests.post(url, json=data)

    try:
        response_data = json.loads(response.text)
        if response_data['code'] == 200:
            print("推送成功")
        else:
            print(f"推送失败，错误代码：{response_data['code']}")
    except json.JSONDecodeError:
        print("连接邮箱服务器失败了")

def telegram_push(message):
    url = f"https://api.telegram.org/bot{os.getenv('TELEGRAM_BOT_TOKEN')}/sendMessage"
    payload = {
        'chat_id': os.getenv('TELEGRAM_CHAT_ID'),
        'text': message,
        'parse_mode': 'HTML',
        'reply_markup': json.dumps({
            "inline_keyboard": menu,
            "one_time_keyboard": True
         })
    }
    headers = {
        'Content-Type': 'application/json'
    }
    response = requests.post(url, json=payload, headers=headers)
    if response.status_code != 200:
        print(f"发送消息到Telegram失败: {response.text}")

### ------------------
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
import os
import ssl
import smtplib
from datetime import datetime
current_date = datetime.now().strftime('%Y%m%d')

def SendByEmail(recipients=["jinsanity@kindle.com"], 
                CC=None, 
                text='readme.md', 
                subject="update", 
                href="url", 
                div="<div>"):
    smtp_server = "smtp.gmail.com"
    port = 587  # For starttls
    sender_email = os.getenv('EACCOUNT')
    password = os.getenv('EPASSWORD')

    message = MIMEMultipart('alternative')
    message["Subject"] = subject
    message["From"] = sender_email
    message["To"] = ",".join(recipients)
    if CC:
        message['Cc'] = ", ".join(CC)

    # HTML email body
    html = f"""\
    <html>
    <body>
        <p>Please find the attached epub file!
        </p>
        {current_date}
    </body>
    </html>
    """

    # Attach HTML content to the message
    part2 = MIMEText(html, "html")
    message.attach(part2)

    # Attach EPUB file
    epub_path = f"eco/{current_date}.epub"
    
    try:
        with open(epub_path, 'rb') as attachment:
            # Add file as application/octet-stream
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(attachment.read())

        # Encode file in ASCII characters to send by email    
        encoders.encode_base64(part)

        # Add header as key/value pair to attachment part
        part.add_header(
            "Content-Disposition",
            f"attachment; filename= {current_date}.epub"
        )

        # Add attachment to message
        message.attach(part)
    except FileNotFoundError:
        print(f"Warning: EPUB file not found at {epub_path}")
        return

    # Create a secure SSL context
    context = ssl.create_default_context()

    # Try to log in to server and send email
    try:
        server = smtplib.SMTP(smtp_server, port)
        server.ehlo()
        server.starttls(context=context)
        server.ehlo()
        server.login(sender_email, password)
        server.sendmail(sender_email, recipients, message.as_string())
        print("Email has been sent with EPUB attachment")
    except Exception as e:
        print("An error occurred when sending the email:")
        print(e)
    finally:
        server.quit()

if __name__ == "__main__":
    # os.environ['Erecipient'] = 
    # os.environ['Eaccount']   = 
    # os.environ['Epassword']  = 

    SendByEmail(recipients = [os.getenv('ERECIPIENT','jinsanity07_mTCrnk@kindle.com')],
                subject=f'Eco{current_date}')
    if push == "mail":
        mail_push('https://zzzwb.us.kg/test')
    elif push == "telegram":
        telegram_push(content)
    else:
        print("推送失败，推送参数设置错误")

