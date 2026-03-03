select * from funnel_events;
select * from subscriptions;
select * from users;
##Overall Funnel Stage Counts##
SELECT 
    funnel_stage,
    COUNT(DISTINCT user_id) AS users_at_stage
FROM funnel_events
GROUP BY funnel_stage
ORDER BY 
    CASE funnel_stage
        WHEN 'Signup' THEN 1
        WHEN 'Email Verified' THEN 2
        WHEN 'Trial Started' THEN 3
        WHEN 'Feature Used' THEN 4
        WHEN 'Subscription Purchased' THEN 5
        WHEN 'Retained 30 Days' THEN 6
    END;
    
##Overall Funnel Conversion Rate##
WITH stage_counts AS (
    SELECT 
        funnel_stage,
        COUNT(DISTINCT user_id) AS users_count
    FROM funnel_events
    GROUP BY funnel_stage
)

SELECT 
    MAX(CASE WHEN funnel_stage = 'Signup' THEN users_count END) AS total_signups,
    MAX(CASE WHEN funnel_stage = 'Subscription Purchased' THEN users_count END) AS total_paid_users,
    ROUND(
        100.0 * 
        MAX(CASE WHEN funnel_stage = 'Subscription Purchased' THEN users_count END) /
        MAX(CASE WHEN funnel_stage = 'Signup' THEN users_count END),
    2) AS conversion_rate_percent
FROM stage_counts;

##Stage-by-Stage Drop-Off %##
WITH stage_counts AS (
    SELECT 
        funnel_stage,
        COUNT(DISTINCT user_id) AS users_count
    FROM funnel_events
    GROUP BY funnel_stage
)

SELECT 
    funnel_stage,
    users_count,
    LAG(users_count) OVER (ORDER BY 
        CASE funnel_stage
            WHEN 'Signup' THEN 1
            WHEN 'Email Verified' THEN 2
            WHEN 'Trial Started' THEN 3
            WHEN 'Feature Used' THEN 4
            WHEN 'Subscription Purchased' THEN 5
            WHEN 'Retained 30 Days' THEN 6
        END
    ) AS previous_stage_users,
    
    ROUND(
        100.0 * 
        (LAG(users_count) OVER (ORDER BY 
            CASE funnel_stage
                WHEN 'Signup' THEN 1
                WHEN 'Email Verified' THEN 2
                WHEN 'Trial Started' THEN 3
                WHEN 'Feature Used' THEN 4
                WHEN 'Subscription Purchased' THEN 5
                WHEN 'Retained 30 Days' THEN 6
            END
        ) - users_count)
        /
        LAG(users_count) OVER (ORDER BY 
            CASE funnel_stage
                WHEN 'Signup' THEN 1
                WHEN 'Email Verified' THEN 2
                WHEN 'Trial Started' THEN 3
                WHEN 'Feature Used' THEN 4
                WHEN 'Subscription Purchased' THEN 5
                WHEN 'Retained 30 Days' THEN 6
            END
        ),
    2) AS drop_off_percent
FROM stage_counts;	

##Funnel Conversion by Acquisition Channel##
SELECT 
    u.acquisition_channel,
    COUNT(DISTINCT CASE WHEN f.funnel_stage = 'Signup' THEN f.user_id END) AS signups,
    COUNT(DISTINCT CASE WHEN f.funnel_stage = 'Subscription Purchased' THEN f.user_id END) AS paid_users,
    
    ROUND(
        100.0 *
        COUNT(DISTINCT CASE WHEN f.funnel_stage = 'Subscription Purchased' THEN f.user_id END)
        /
        COUNT(DISTINCT CASE WHEN f.funnel_stage = 'Signup' THEN f.user_id END),
    2) AS conversion_rate_percent

FROM users u
JOIN funnel_events f 
    ON u.user_id = f.user_id
GROUP BY u.acquisition_channel
ORDER BY conversion_rate_percent DESC;

##A/B Test Funnel Comparison##
SELECT 
    u.experiment_group,
    
    COUNT(DISTINCT CASE WHEN f.funnel_stage = 'Signup' THEN f.user_id END) AS signups,
    COUNT(DISTINCT CASE WHEN f.funnel_stage = 'Subscription Purchased' THEN f.user_id END) AS paid_users,
    
    ROUND(
        100.0 *
        COUNT(DISTINCT CASE WHEN f.funnel_stage = 'Subscription Purchased' THEN f.user_id END)
        /
        COUNT(DISTINCT CASE WHEN f.funnel_stage = 'Signup' THEN f.user_id END),
    2) AS conversion_rate_percent

FROM users u
JOIN funnel_events f 
    ON u.user_id = f.user_id
GROUP BY u.experiment_group;

##Revenue & ARPU Calculation##
SELECT 
    COUNT(DISTINCT s.user_id) AS total_paid_users,
    SUM(s.monthly_price) AS total_monthly_revenue,
    ROUND(AVG(s.monthly_price), 2) AS ARPU
FROM subscriptions s;

##LTV by Acquisition Channel##
SELECT 
    u.acquisition_channel,
    ROUND(AVG(s.monthly_price), 2) AS avg_monthly_value
FROM subscriptions s
JOIN users u
    ON s.user_id = u.user_id
GROUP BY u.acquisition_channel
ORDER BY avg_monthly_value DESC;
    