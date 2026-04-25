# 情境實戰 — 題目二：API 集群中單台機器回應逾時排查

## 判斷方向

只有一台有問題、其他正常，代表不是程式碼或上游服務的鍋，問題大概率出在這台機器本身或它所在的環境。

## 排查步驟

**1. 先看機器資源狀況**

SSH 進去跑 top / htop / vmstat，看 CPU、Memory、Disk I/O 有沒有異常。常見情況：
- 某個 process 吃滿 CPU 或 memory（可能是 memory leak 或跑了不該跑的東西）
- Disk I/O wait 很高，df -h 看一下磁碟是不是滿了，log 沒 rotate 塞爆磁碟蠻常見的
- swap 被大量使用，代表記憶體不夠開始換頁，效能會直接崩

**2. 檢查網路層**

資源都正常的話就看網路。用 ping / mtr 測到其他機器跟外部的延遲，看是不是這台的網路有問題。如果是雲端環境，有可能是底層宿主機的問題（noisy neighbor），或是這台剛好落在有問題的 AZ / rack 上。

**3. 看 application log**

用 Loki 或直接 tail log，過濾這台機器的 slow request，看是卡在哪個環節。是 DB query 慢、呼叫外部 API timeout、還是 application 本身處理慢。如果有 APM（像 Datadog 或 Jaeger）可以直接看 trace 找到瓶頸。

**4. 比對跟其他機器的差異**

既然只有這台有問題，就去比對跟正常機器的差異：
- OS / runtime 版本有沒有不一致（部署沒更新到、config drift）
- 連線數是不是不均勻，LB 分配有沒有問題導致這台扛太多流量
- crontab 或 sidecar 有沒有在跑額外的任務吃資源

## 當下處理

排查的同時，如果影響到用戶體驗，先從 load balancer 把這台摘掉，讓流量導到其他健康的機器。等查到根因修復後再加回來。

## 後續改善

- 確保 health check 夠敏感，response time 超標就自動從 LB 移除，不要等人發現
- Grafana dashboard 加上 per-instance 的 metrics 面板，下次能更快定位是哪台出問題
- 如果是 infra 層面的問題（磁碟滿、noisy neighbor），考慮用 IaC 確保機器一致性，或直接砍掉重建比較快
