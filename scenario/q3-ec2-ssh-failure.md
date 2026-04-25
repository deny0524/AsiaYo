# 情境實戰 — 題目三：EC2 無法 SSH 登入排查

## 前提

題目已排除網路跟防火牆（Security Group / NACL），服務本身還活著，所以問題在 SSH 服務或 OS 層面。

## 排查方式

**1. 透過 AWS Systems Manager Session Manager 進去**

如果機器有裝 SSM Agent（Amazon Linux 預設有），直接從 AWS Console 開 Session Manager 連進去，不需要走 SSH。這是最快的方式。

**2. 看 System Log**

在 EC2 Console 上對該 instance 選 Actions → Monitor and troubleshoot → Get system log，看開機跟系統 log 有沒有錯誤訊息，例如 sshd 啟動失敗、filesystem 錯誤等。

**3. 掛載 EBS 到另一台機器檢查**

如果上面兩招都不行：
- Stop 這台 instance（服務要先轉移到其他機器）
- 把它的 root EBS volume detach
- Attach 到一台正常的 EC2 上 mount 起來
- 進去檢查 /etc/ssh/sshd_config、/var/log/auth.log、~/.ssh/authorized_keys、/etc/fstab 等
- 修完後 detach 掛回去啟動

## 可能的肇因

- **磁碟滿了**：log 或暫存檔塞爆磁碟，sshd 無法寫入 session 資料就會拒絕連線
- **sshd 掛了或設定改壞**：有人改了 sshd_config 語法錯誤，或 sshd process 被 kill 掉、OOM 砍掉後沒拉起來
- **SSH key / 權限問題**：authorized_keys 被覆蓋或 .ssh 目錄權限被改掉（SSH 對權限很敏感，700/600 不對就拒絕）
- **PAM 或 SELinux 設定異常**：PAM 模組設定錯誤會擋住認證流程
- **inode 用完**：磁碟空間還有但 inode 耗盡，一樣無法建立新檔案，sshd 會出問題
- **系統資源耗盡**：process 數量達到 ulimit 上限，fork 不出新的 sshd child process

## 恢復與預防

- 查到原因修復後，確認 sshd 正常啟動、能正常登入
- 裝好 SSM Agent 並確認 IAM Role 有權限，下次就不怕 SSH 掛掉沒有備案
- 設定磁碟使用率跟 inode 的監控告警，在塞爆之前就處理
- sshd 設定變更走 IaC 管理，避免手動改壞
