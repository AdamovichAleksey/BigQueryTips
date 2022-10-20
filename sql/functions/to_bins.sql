/*

The function takes int value and an arranged int array 
and put a value into the bin generated from the array elements

Existance of upper boundary must be marked by 0 or NULL as last value in array

e.g. 
a) within array boundaries:
to_bins(10, [0, 100, 500]) => '0 - 100'
to_bins(100, [0, 100, 500]) => '100 - 500'

out of array boundaries:
to_bins(1000, [0, 100, 500]) => NULL
to_bins(1000, [0, 100, 500, 0]) => '500 - ...'
to_bins(1000, [0, 100, 500, NULL]) => '500 - ...'

*/

CREATE OR REPLACE FUNCTION analytics.to_bins(x INT64, arr ARRAY <INT64>)
RETURNS STRING
AS ((

  WITH 

  -- chech if there is the upper boundary
  -- it should be defined by 0 or NULL
  upper_boundary AS (
    SELECT
      ARRAY_REVERSE(arr)[OFFSET(0)] = 0
        OR ARRAY_REVERSE(arr)[OFFSET(0)] IS NULL
        AS without_upper_boundary
  )

  -- as the array must be arranged asc to use with RANGE_BUCKET()
  -- we should exclude last value in case there is no upper boundary
  , arr_wo_last_0 AS (

  SELECT 
    CASE 
      -- if there is the upper boundary
      WHEN (SELECT without_upper_boundary FROM upper_boundary)
        THEN ARRAY_AGG(arr_ ORDER BY index) 
      ELSE arr
    END as arr
  FROM (
    SELECT arr[SAFE_OFFSET(index)] AS arr_, index
    -- exclude the last element of the array from "lower bound column" as it's used only in "upper bound column"
    FROM UNNEST(GENERATE_ARRAY(0, ARRAY_LENGTH(arr) - 2)) AS index
  )
  
  )


  -- create array with (N - 1) bins from the array of length N.
  , arr_bins AS (
  
  SELECT ARRAY_AGG(arr_bins ORDER BY index) as arr_bins
  FROM (
    SELECT 
      CONCAT(
        CAST(arr[SAFE_OFFSET(index)] AS STRING),
        ' - ',
        CASE 
          WHEN 
            (SELECT without_upper_boundary FROM upper_boundary)
            AND
            (index = (ARRAY_LENGTH(arr) - 2))
          THEN '...' 
          ELSE CAST(arr[SAFE_OFFSET(index + 1)] AS STRING) 
        END
        ) AS arr_bins,
      index
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
