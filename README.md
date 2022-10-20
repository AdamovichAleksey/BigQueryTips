# BigQueryTips
Useful functions and tips for BigQuery

### SQL Functions

* [Put value to bin](https://github.com/AdamovichAleksey/BigQueryTips/blob/main/sql/functions/to_bins.sql)
```
  to_bin(10, [0, 100, 500]) => '0 - 100'
  to_bin(1000, [0, 100, 500]) => NULL
  to_bin(1000, [0, 100, 500, NULL]) => '500 - ...'
```


### Extentions
* Grouping Sets (TBD)
