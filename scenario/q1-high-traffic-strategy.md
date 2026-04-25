# 情境實戰 — 題目一：活動網頁百倍流量應對

## 核心思路

活動頁通常以靜態內容居多，第一步就是把靜態資源往前推、後端能少扛就少扛。

## 上線前準備

**靜態資源走 CDN**
- 圖片、JS/CSS 全部透過 CloudFront 發送，設好 Cache-Control 拉高命中率
- 如果整頁都是靜態的，直接 S3 + CloudFront 就搞定，根本不需要後端

**Auto Scaling 提前擴**
- 不要等流量來了才 scale，用 Scheduled Scaling 在活動前就先把機器拉起來
- max capacity 要設上限，不然異常流量會把帳單炸掉

**DB 保護**
- 前面擋一層 Redis 快取，能不查 DB 就不查
- 視情況加 Read Replica 或暫時升級 instance type

**ELB Pre-warming**
- 預期流量真的很大的話，提前跟 AWS 申請 ELB pre-warming，避免 ALB 自己變瓶頸

## 壓測驗證

架構改完一定要壓測，用 k6 或 Locust 打到預期流量的 1.5~2 倍，看哪裡先爆。重點觀察 response time、error rate、DB connection 數量，確認 auto scaling 反應速度夠不夠快。

## 活動期間

- Prometheus 收 metrics，Loki 收 log，Grafana 統一看 dashboard。5xx rate 跟 response time 設 alert rule，觸發就推 Slack 或 PagerDuty 通知 on-call
- 準備降級方案：流量超標就開 WAF rate limiting，非核心功能可以暫時關掉
- CloudFront 層放一個靜態 sorry page，origin 真的掛了至少不會回白畫面

## 活動結束

scaling 縮回去、Read Replica 砍掉、DB 降回原本規格。把這次的監控數據跟壓測結果留著，下次活動就有 baseline 可以參考。
