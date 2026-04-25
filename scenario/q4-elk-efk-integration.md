# 情境實戰 — 題目四：新服務串接 ELK/EFK 日誌系統

## 串接方式

依部署環境不同，做法會有差異：

**如果跑在 Kubernetes 上（EFK 常見架構）**

基本上不用動太多東西。EFK 架構下通常已經有 Fluentd / Fluent Bit 以 DaemonSet 跑在每個 node 上，自動收集所有 container 的 stdout/stderr。新服務只要確保 log 是輸出到 stdout 就會自動被收走，不需要額外設定。

要做的事：
- 確認新服務的 log 是寫到 stdout，不是寫到 container 內的檔案
- 在 Fluentd 設定中加一組 filter，用 kubernetes namespace / pod label 去匹配這個新服務，做對應的 log parsing
- 在 Elasticsearch 確認 index pattern，例如用 `logstash-{service_name}-*` 或統一的 `k8s-*` 都行

**如果跑在 EC2 上（ELK 常見架構）**

在機器上裝 Filebeat，設定去讀新服務的 log 檔路徑，送到 Logstash 或直接送 Elasticsearch。

```yaml
# filebeat.yml 範例
filebeat.inputs:
  - type: log
    paths:
      - /var/log/new-service/*.log
    fields:
      service: new-service
    # 如果是多行 log（如 stack trace），設定 multiline
    multiline.pattern: '^\d{4}-\d{2}-\d{2}'
    multiline.negate: true
    multiline.match: after

output.logstash:
  hosts: ["logstash-host:5044"]
```

Logstash 那邊加一組 pipeline，用 grok 或 json filter 把 log 解析成結構化欄位。

## 考量細節

**Log 格式**
- 最好請開發者用 JSON 格式輸出 log，省掉寫 grok pattern 的麻煩，解析也更穩定
- 至少要包含 timestamp、log level、message 這幾個欄位
- 時區要統一（建議 UTC），不然查 log 時間對不上會很痛苦

**Index 管理**
- 設定 ILM（Index Lifecycle Management），自動依天數 rollover、過期自動刪除，不然 Elasticsearch 磁碟遲早爆掉
- 新服務的 index 要不要獨立開，看 log 量決定。量大就獨立，量小就跟其他服務共用

**Kibana 設定**
- 建好對應的 index pattern，讓開發者可以查到
- 幫開發者建一個基本的 dashboard，至少有 error rate 跟 log level 分佈，方便他們快速定位問題

**避免影響既有系統**
- 新服務 log 量如果很大，注意 Elasticsearch 的 capacity 夠不夠，必要時先擴 node
- Logstash / Fluentd 的 pipeline 加上 rate limiting 或 buffer 設定，避免暴量 log 把整個 ELK 打掛連帶影響其他服務
