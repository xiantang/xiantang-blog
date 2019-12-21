kubectl -n k8s-marketing-automation exec -ti k8s-marketing-automation-opm-687d45b94d-4vvt6 bash --kubeconfig=/Users/xiantang/project-conf/k8s-config

kubectl -n   k8s-marketing-automation  get pods --kubeconfig=/Users/xiantang/project-conf/k8s-config





```json
{
    //纬度
    "dimensions": [
        "tm"
    ],
    // 粒度
    "granularities": [
        {
            "id": "tm",
            "interval": 3600000,
            "period": "abs:1573488000000,1573574399999"
        }
    ],
    // 指标
    "metrics": [
        {
            "id": "uc",
            "type": "prepared",
            "name": "用户量"
        }
    ],
    "targetUser": "uv",
    //时间
     "timeRange": "day:2,1",
     // 是否只进行聚合计算
    "aggregation": true,
    // 聚合函数
    "aggregator": "sum"
}
```

