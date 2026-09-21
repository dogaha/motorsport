SELECT
    sensor_id,
    sensor_name, 
    min_valid AS sensor_lower_limit,
    min_valid AS sensor_upper_limit
FROM {{source('silver','sensors')}}

