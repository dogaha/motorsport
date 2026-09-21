select
    driver_id,
    first_name as driver_first_name,
    last_name as driver_last_name,
    concat_ws(' ', first_name, last_name) as driver_full_name,
    dob as driver_dob,
    weight as driver_weight_lbs
from {{ source('silver', 'drivers') }}