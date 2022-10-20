/*

The function takes int value and an arranged int array 
and put the value into the bin generated from the array elements

e.g. 
a) within array bounds:
to_bins(10, [0, 100, 500], zero_to_dots=FALSE) => '0 - 100'
to_bins(10, [0, 100, 500], zero_to_dots=TRUE) => '... - 100'

out of array bounds:
to_bins(1000, [0, 100, 500], zero_to_dots=FALSE) => NULL
to_bins(1000, [0, 100, 500, 0], zero_to_dots=FALSE) => '500 - ...'
to_bins(1000, [0, 100, 500, 0], zero_to_dots=TRUE) => '500 - ...'

*/

CREATE OR REPLACE FUNCTION analytics.to_bins(x INT64, arr ARRAY <INT64>, zero_to_dots BOOL)
RETURNS STRING
AS ((

  WITH 

  -- create array with (N - 1) bins from the array of length N.
  -- 
  arr_bins AS (
  
  SELECT ARRAY_AGG(arr_bins ORDER BY index) as arr_bins
  FROM (
    SELECT 
      CONCAT(
        REGEXP_REPLACE(
          CAST(arr[SAFE_OFFSET(index)] AS STRING), 
          CASE 
            WHEN zero_to_dots 
              THEN '^0$' 
            ELSE '_' 
          END, 
          '...'
        ),
        ' - ',
        REGEXP_REPLACE(
          CAST(arr[SAFE_OFFSET(index + 1)] AS STRING), 
          CASE 
            WHEN zero_to_dots OR (ARRAY_REVERSE(arr)[OFFSET(0)] = 0) 
              THEN '^0$' 
            ELSE '_' 
          END, 
          '...'
        )
      ) as arr_bins,
      index
    FROM UNNEST(GENERATE_ARRAY(0, ARRAY_LENGTH(arr) - 2)) AS index
    )

  )


  -- as the array must be arranged asc to use with RANGE_BUCKET()
  -- we should exclude last 0 which can be used for "no upper bound"
  , arr_wo_last_0 AS (

  SELECT 
    CASE 
      -- check if the last value of the array is 0
      WHEN ARRAY_REVERSE(arr)[OFFSET(0)] = 0 
        THEN ARRAY_AGG(arr_ ORDER BY index) 
      ELSE arr
    END as arr
  FROM (
    SELECT arr[SAFE_OFFSET(index)] AS arr_, index
    -- exclude the last element of the array from "lower bound column" as it's used only in "upper bound column"
    FROM UNNEST(GENERATE_ARRAY(0, ARRAY_LENGTH(arr) - 2)) AS index
  )
  
  )


  -- find value in the array and return corresponding bin name
  SELECT 
    arr_bins.arr_bins[SAFE_OFFSET(
      RANGE_BUCKET(x, arr_wo_last_0.arr) - 1
    )]
  FROM 
    arr_bins, 
    arr_wo_last_0

));
