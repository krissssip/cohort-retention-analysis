WITH users_clean AS (
    SELECT 
        user_id,
        promo_signup_flag,
        REPLACE(REPLACE(SPLIT_PART(TRIM(signup_datetime), ' ', 1), '/', '-'), '.', '-') AS raw_signup_date
    FROM public.cohort_users_raw
),

users_parsed AS (
    SELECT *,
        CASE
            WHEN raw_signup_date ~ '^\d{1,2}-\d{1,2}-\d{4}$'
                THEN TO_DATE(raw_signup_date, 'DD-MM-YYYY')
            WHEN raw_signup_date ~ '^\d{1,2}-\d{1,2}-\d{2}$'
                THEN TO_DATE(raw_signup_date, 'DD-MM-YY')
            ELSE NULL
        END AS signup_date
    FROM users_clean
),

events_clean AS (
    SELECT 
        user_id,
        event_type,
        REPLACE(REPLACE(SPLIT_PART(TRIM(event_datetime), ' ', 1), '/', '-'), '.', '-') AS raw_event_date
    FROM public.cohort_events_raw
),

events_parsed AS (
    SELECT *,
        CASE
            WHEN raw_event_date ~ '^\d{1,2}-\d{1,2}-\d{4}$'
                THEN TO_DATE(raw_event_date, 'DD-MM-YYYY')
            WHEN raw_event_date ~ '^\d{1,2}-\d{1,2}-\d{2}$'
                THEN TO_DATE(raw_event_date, 'DD-MM-YY')
            ELSE NULL
        END AS event_date
    FROM events_clean
),

cohorts AS (
    SELECT 
        u.user_id,
        u.promo_signup_flag,
        DATE_TRUNC('month', u.signup_date)::date AS cohort_month,
        DATE_TRUNC('month', e.event_date)::date AS event_month
    FROM users_parsed u
    JOIN events_parsed e 
        ON u.user_id = e.user_id
    WHERE 
        u.signup_date IS NOT NULL
        AND e.event_date IS NOT NULL
        AND e.event_type != 'test_event'
)

SELECT 
    promo_signup_flag,
    cohort_month,
    (
        DATE_PART('year', age(event_month, cohort_month)) * 12 +
        DATE_PART('month', age(event_month, cohort_month))
    ) AS month_offset,
    COUNT(DISTINCT user_id) AS users_total
FROM cohorts
GROUP BY promo_signup_flag, cohort_month, month_offset
ORDER BY promo_signup_flag, cohort_month, month_offset;
