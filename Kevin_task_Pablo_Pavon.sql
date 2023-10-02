#We will start by creating the DATABASE:
CREATE DATABASE if not exists kevin_task;
#Activate the DATABASE:
use kevin_task;
#Create both tables:
CREATE TABLE payments (
    payment_number VARCHAR(20) PRIMARY KEY,
    client_number VARCHAR(20),
    bank VARCHAR(50),
    country_codes VARCHAR(50),
    created_at_date DATE,
    created_at_hour TIME,
    updated_at_date DATE,
    updated_at_hour TIME,
    status_group VARCHAR(50),
    currency_code VARCHAR(10),
    amount DECIMAL(10, 2)
);

CREATE TABLE payment_statuses (
    payment_number VARCHAR(20),
    created_at_date DATE,
    created_at_hour TIME,
    updated_at_date DATE,
    updated_at_hour TIME,
    payment_status VARCHAR(50),
    payments_status_group VARCHAR(50),
    PRIMARY KEY (payment_number, created_at_date, created_at_hour)
);

#in order to upload the data sets on each table, we will use the function "Table Data Import Wizard."

#We check that everything looks OK
select * from payments;
select * from payment_statuses;

#We will analyze the total transaction amounts for each client and country, with a focus on completed transactions.
SELECT
  p.client_number,
  p.country_codes,
  p.currency_code,
  SUM(p.amount) AS total_transactions_completed
FROM payments AS p
WHERE p.status_group = 'completed'
GROUP BY p.client_number, p.country_codes, p.currency_code
ORDER BY total_transactions_completed DESC, p.client_number ASC, p.country_codes ASC, p.currency_code ASC;

SELECT
  p.client_number,
  p.currency_code,
  SUM(p.amount) AS total_transactions_completed
FROM payments AS p
WHERE p.status_group = 'completed'
GROUP BY p.client_number, p.currency_code
ORDER BY total_transactions_completed DESC;


#Similar to our previous approach, we will analyze transactions per customer and country, but this time with a focus on the failed transactions.
SELECT
  p.client_number,
  p.country_codes,
  p.currency_code,
  SUM(p.amount) AS total_transactions_failed
FROM payments AS p
WHERE p.status_group = 'failed'
GROUP BY p.client_number, p.country_codes, p.currency_code
ORDER BY total_transactions_failed DESC, p.client_number ASC, p.country_codes ASC, p.currency_code ASC;

SELECT
  p.client_number,
  p.currency_code,
  SUM(p.amount) AS total_transactions_failed
FROM payments AS p
WHERE p.status_group = 'failed'
GROUP BY p.client_number, p.currency_code
ORDER BY total_transactions_failed DESC;

#Combined Completed and Failed payments

WITH Completed AS (
  SELECT
    p.client_number,
    p.currency_code,
    SUM(p.amount) AS total_transactions_completed
  FROM payments AS p
  WHERE p.status_group = 'completed'
  GROUP BY p.client_number, p.currency_code
),
Failed AS (
  SELECT
    p.client_number,
    p.currency_code,
    SUM(p.amount) AS total_transactions_failed
  FROM payments AS p
  WHERE p.status_group = 'failed'
  GROUP BY p.client_number, p.currency_code
)
SELECT
  c.client_number,
  c.currency_code,
  ROUND(c.total_transactions_completed, 2) AS total_transactions_completed,
  ROUND(COALESCE(f.total_transactions_failed, 0), 2) AS total_transactions_failed,
  ROUND((c.total_transactions_completed / (c.total_transactions_completed + COALESCE(f.total_transactions_failed, 0))) * 100, 2) AS completed_percentage,
  ROUND((COALESCE(f.total_transactions_failed, 0) / (c.total_transactions_completed + COALESCE(f.total_transactions_failed, 0))) * 100, 2) AS failed_percentage
FROM Completed AS c
LEFT JOIN Failed AS f ON c.client_number = f.client_number AND c.currency_code = f.currency_code
UNION
SELECT
  f.client_number,
  f.currency_code,
  ROUND(COALESCE(c.total_transactions_completed, 0), 2) AS total_transactions_completed,
  ROUND(f.total_transactions_failed, 2) AS total_transactions_failed,
  ROUND((COALESCE(c.total_transactions_completed, 0) / (COALESCE(c.total_transactions_completed, 0) + f.total_transactions_failed)) * 100, 2) AS completed_percentage,
  ROUND((f.total_transactions_failed / (COALESCE(c.total_transactions_completed, 0) + f.total_transactions_failed)) * 100, 2) AS failed_percentage
FROM Failed AS f
LEFT JOIN Completed AS c ON c.client_number = f.client_number AND c.currency_code = f.currency_code;

#let's analyze how many transactions were created per day
SELECT
  created_at_date AS date_completed,
  DAYNAME(created_at_date) AS day_of_week,
  COUNT(*) AS number_of_completed_transactions
FROM payment_statuses
WHERE payments_status_group = 'completed'
GROUP BY date_completed
ORDER BY date_completed;

#and we can see it per country also:

SELECT 
    p.country_codes AS country,
    DATE(ps.created_at_date) AS date,
    DAYNAME(ps.created_at_date) AS day_of_week,
    COUNT(ps.payment_number) AS total_completed_transactions
FROM payment_statuses AS ps
JOIN payments AS p
ON ps.payment_number = p.payment_number
WHERE ps.payments_status_group = 'completed'
GROUP BY p.country_codes, DATE(ps.created_at_date), DAYNAME(ps.created_at_date)
ORDER BY p.country_codes, DATE(ps.created_at_date);


#now, let's work with the failed transactions:
SELECT 
    DATE(ps.created_at_date) AS date,
    DAYNAME(ps.created_at_date) AS day_of_week,
    COUNT(ps.payment_number) AS total_failed_transactions
FROM payment_statuses AS ps
JOIN payments AS p
ON ps.payment_number = p.payment_number
WHERE ps.payments_status_group = 'failed'
GROUP BY DATE(ps.created_at_date), DAYNAME(ps.created_at_date)
ORDER BY DATE(ps.created_at_date);

#Here we will see the transactions based on the country: 
SELECT 
    p.country_codes AS country,
    DATE(ps.created_at_date) AS date,
    DAYNAME(ps.created_at_date) AS day_of_week,
    COUNT(ps.payment_number) AS total_failed_transactions
FROM payment_statuses AS ps
JOIN payments AS p
ON ps.payment_number = p.payment_number
WHERE ps.payments_status_group = 'failed'
GROUP BY p.country_codes, DATE(ps.created_at_date), DAYNAME(ps.created_at_date)
ORDER BY p.country_codes, DATE(ps.created_at_date) DESC;

#Lets compare completed and failed transactions per day

SELECT 
    p.country_codes AS country,
    DATE(ps.created_at_date) AS date,
    SUM(CASE WHEN ps.payments_status_group IN ('completed', 'failed') THEN 1 ELSE 0 END) AS total_transactions,
    SUM(CASE WHEN ps.payments_status_group = 'completed' THEN 1 ELSE 0 END) AS completed_transactions,
    SUM(CASE WHEN ps.payments_status_group = 'failed' THEN 1 ELSE 0 END) AS failed_transactions,
    CONCAT(FORMAT(SUM(CASE WHEN ps.payments_status_group = 'completed' THEN 1 ELSE 0 END) / SUM(CASE WHEN ps.payments_status_group IN ('completed', 'failed') THEN 1 ELSE 0 END) * 100, 2), '%') AS completed_percentage_day_country,
    CONCAT(FORMAT(SUM(CASE WHEN ps.payments_status_group = 'failed' THEN 1 ELSE 0 END) / SUM(CASE WHEN ps.payments_status_group IN ('completed', 'failed') THEN 1 ELSE 0 END) * 100, 2), '%') AS failed_percentage_day_country
FROM payment_statuses AS ps
JOIN payments AS p
ON ps.payment_number = p.payment_number
WHERE ps.payments_status_group IN ('completed', 'failed')
GROUP BY p.country_codes, DATE(ps.created_at_date)
ORDER BY p.country_codes, DATE(ps.created_at_date) DESC;

#we will analyze the time it takes for the system to complete a transaction 
SELECT 
    ps_started.payment_number,
    TIMESTAMPDIFF(DAY, CONCAT(ps_started.created_at_date, ' ', ps_started.created_at_hour), CONCAT(ps_completed.updated_at_date, ' ', ps_completed.updated_at_hour)) AS days,
    MOD(TIMESTAMPDIFF(HOUR, CONCAT(ps_started.created_at_date, ' ', ps_started.created_at_hour), CONCAT(ps_completed.updated_at_date, ' ', ps_completed.updated_at_hour)), 24) AS hours,
    MOD(TIMESTAMPDIFF(MINUTE, CONCAT(ps_started.created_at_date, ' ', ps_started.created_at_hour), CONCAT(ps_completed.updated_at_date, ' ', ps_completed.updated_at_hour)), 60) AS minutes,
    MOD(TIMESTAMPDIFF(SECOND, CONCAT(ps_started.created_at_date, ' ', ps_started.created_at_hour), CONCAT(ps_completed.updated_at_date, ' ', ps_completed.updated_at_hour)), 60) AS seconds,
    p.country_codes
FROM payment_statuses AS ps_started
JOIN payment_statuses AS ps_completed ON ps_started.payment_number = ps_completed.payment_number
JOIN payments AS p ON ps_started.payment_number = p.payment_number
WHERE ps_started.payments_status_group = 'started' AND ps_completed.payments_status_group = 'completed'
ORDER BY ps_started.payment_number;


#rime it takes fot the system to complete a transaction per country:
SELECT 
    p.country_codes,
    ROUND(AVG(TIME_TO_SEC(TIMEDIFF(CONCAT(ps_completed.updated_at_date, ' ', ps_completed.updated_at_hour), CONCAT(ps_started.created_at_date, ' ', ps_started.created_at_hour)))) / 60) AS average_minutes,
    ROUND(MOD(AVG(TIME_TO_SEC(TIMEDIFF(CONCAT(ps_completed.updated_at_date, ' ', ps_completed.updated_at_hour), CONCAT(ps_started.created_at_date, ' ', ps_started.created_at_hour)))), 60)) AS average_seconds
FROM payment_statuses AS ps_started
JOIN payment_statuses AS ps_completed ON ps_started.payment_number = ps_completed.payment_number
JOIN payments AS p ON ps_started.payment_number = p.payment_number
WHERE ps_started.payments_status_group = 'started' AND ps_completed.payments_status_group = 'completed'
GROUP BY p.country_codes;


#now we will see the AVG time per country, pero day of the week:
SELECT 
    p.country_codes,
    DAYNAME(CONCAT(ps_completed.updated_at_date, ' ', ps_completed.updated_at_hour)) AS day_of_week,
    ROUND(AVG(TIME_TO_SEC(TIMEDIFF(CONCAT(ps_completed.updated_at_date, ' ', ps_completed.updated_at_hour), CONCAT(ps_started.created_at_date, ' ', ps_started.created_at_hour)))) / 60) AS average_minutes,
    ROUND(MOD(AVG(TIME_TO_SEC(TIMEDIFF(CONCAT(ps_completed.updated_at_date, ' ', ps_completed.updated_at_hour), CONCAT(ps_started.created_at_date, ' ', ps_started.created_at_hour)))), 60)) AS average_seconds
FROM payment_statuses AS ps_started
JOIN payment_statuses AS ps_completed ON ps_started.payment_number = ps_completed.payment_number AND ps_started.payments_status_group = 'started' AND ps_completed.payments_status_group = 'completed'
JOIN payments AS p ON ps_started.payment_number = p.payment_number
GROUP BY p.country_codes, DAYNAME(CONCAT(ps_completed.updated_at_date, ' ', ps_completed.updated_at_hour))
ORDER BY p.country_codes, FIELD(day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

#Looking at the data, we can spot something unusual happening on Mondays in the Czech Republic (CZ)

SELECT 
    payment_number,
    updated_at_date AS transaction_date,
    updated_at_hour AS transaction_time,
    DATEDIFF(updated_at_date, created_at_date) AS days,
    HOUR(TIMEDIFF(CONCAT(updated_at_date, ' ', updated_at_hour), CONCAT(created_at_date, ' ', created_at_hour))) AS hours,
    MINUTE(TIMEDIFF(CONCAT(updated_at_date, ' ', updated_at_hour), CONCAT(created_at_date, ' ', created_at_hour))) AS minutes,
    SECOND(TIMEDIFF(CONCAT(updated_at_date, ' ', updated_at_hour), CONCAT(created_at_date, ' ', created_at_hour))) AS seconds
FROM payments
WHERE country_codes = 'CZ'
  AND DAYOFWEEK(CONCAT(updated_at_date, ' ', updated_at_hour)) = 2
  AND status_group = 'completed'
ORDER BY days DESC, hours DESC, minutes DESC, seconds DESC;


#Here we can see every monday for CZ and we can confirm that it was something temporary
SELECT 
    DATE(updated_at_date) as Monday,
    AVG(
        DATEDIFF(updated_at_date, created_at_date) * 24 * 60 +
        TIME_TO_SEC(TIMEDIFF(updated_at_hour, created_at_hour)) / 60
    ) as `Average Transaction Time (minutes)`
FROM
    payments
WHERE
    country_codes = 'CZ' AND
    DAYOFWEEK(updated_at_date) = 2 AND
    status_group = 'completed'
GROUP BY
    DATE(updated_at_date)
ORDER BY
    Monday;

#Now, let's delve into the failed transactions to investigate the underlying patterns.
SELECT 
    subquery.country_codes,
    subquery.day_of_week,
    AVG(subquery.total_seconds) DIV (24 * 3600) AS average_days,
    AVG(subquery.total_seconds) DIV 3600 % 24 AS average_hours,
    AVG(subquery.total_seconds) DIV 60 % 60 AS average_minutes,
    AVG(subquery.total_seconds) % 60 AS average_seconds
FROM (
    SELECT 
        p.country_codes,
        DAYNAME(CONCAT(ps_failed.updated_at_date, ' ', ps_failed.updated_at_hour)) AS day_of_week,
        TIMESTAMPDIFF(SECOND, CONCAT(ps_started.created_at_date, ' ', ps_started.created_at_hour), CONCAT(ps_failed.updated_at_date, ' ', ps_failed.updated_at_hour)) AS total_seconds
    FROM payment_statuses AS ps_started
    JOIN payment_statuses AS ps_failed ON ps_started.payment_number = ps_failed.payment_number
    JOIN payments AS p ON ps_started.payment_number = p.payment_number
    WHERE ps_started.payments_status_group = 'started' AND ps_failed.payments_status_group = 'failed'
) AS subquery
GROUP BY subquery.country_codes, subquery.day_of_week
ORDER BY subquery.country_codes, subquery.day_of_week;

#In the following code, we can see the AVG time in hours it takes for transactions to fail
SELECT 
    country_codes,
    ROUND(AVG(CASE WHEN day_of_week = 'Monday' THEN total_seconds ELSE NULL END) / 3600, 2) AS Monday,
    ROUND(AVG(CASE WHEN day_of_week = 'Tuesday' THEN total_seconds ELSE NULL END) / 3600, 2) AS Tuesday,
    ROUND(AVG(CASE WHEN day_of_week = 'Wednesday' THEN total_seconds ELSE NULL END) / 3600, 2) AS Wednesday,
    ROUND(AVG(CASE WHEN day_of_week = 'Thursday' THEN total_seconds ELSE NULL END) / 3600, 2) AS Thursday,
    ROUND(AVG(CASE WHEN day_of_week = 'Friday' THEN total_seconds ELSE NULL END) / 3600, 2) AS Friday,
    ROUND(AVG(CASE WHEN day_of_week = 'Saturday' THEN total_seconds ELSE NULL END) / 3600, 2) AS Saturday,
    ROUND(AVG(CASE WHEN day_of_week = 'Sunday' THEN total_seconds ELSE NULL END) / 3600, 2) AS Sunday
FROM (
    SELECT 
        p.country_codes,
        DAYNAME(CONCAT(ps_failed.updated_at_date, ' ', ps_failed.updated_at_hour)) AS day_of_week,
        TIMESTAMPDIFF(SECOND, CONCAT(ps_started.created_at_date, ' ', ps_started.created_at_hour), CONCAT(ps_failed.updated_at_date, ' ', ps_failed.updated_at_hour)) AS total_seconds
    FROM payment_statuses AS ps_started
    JOIN payment_statuses AS ps_failed ON ps_started.payment_number = ps_failed.payment_number
    JOIN payments AS p ON ps_started.payment_number = p.payment_number
    WHERE ps_started.payments_status_group = 'started' AND ps_failed.payments_status_group = 'failed'
) AS subquery
GROUP BY country_codes
ORDER BY country_codes;


#Daily Transaction Peaks
#Completed
SELECT
    hour_block,
    SUM(CASE WHEN country_codes = 'EE' THEN 1 ELSE 0 END) AS 'EE',
    SUM(CASE WHEN country_codes = 'LT' THEN 1 ELSE 0 END) AS 'LT',
    SUM(CASE WHEN country_codes = 'CZ' THEN 1 ELSE 0 END) AS 'CZ',
    SUM(CASE WHEN country_codes = 'LV' THEN 1 ELSE 0 END) AS 'LV',
    SUM(CASE WHEN country_codes = 'FI' THEN 1 ELSE 0 END) AS 'FI'
FROM (
    SELECT
        CONCAT(LPAD(HOUR(created_at_hour), 2, '0'), ':00:00 - ',
               LPAD(HOUR(created_at_hour), 2, '0'), ':59:59') AS hour_block,
        country_codes
    FROM payments
    WHERE status_group = 'completed'
) AS subquery
GROUP BY hour_block
ORDER BY hour_block;

#Failed

SELECT
    hour_block,
    SUM(CASE WHEN country_codes = 'EE' THEN 1 ELSE 0 END) AS 'EE',
    SUM(CASE WHEN country_codes = 'LT' THEN 1 ELSE 0 END) AS 'LT',
    SUM(CASE WHEN country_codes = 'CZ' THEN 1 ELSE 0 END) AS 'CZ',
    SUM(CASE WHEN country_codes = 'LV' THEN 1 ELSE 0 END) AS 'LV',
    SUM(CASE WHEN country_codes = 'FI' THEN 1 ELSE 0 END) AS 'FI'
FROM (
    SELECT
        CONCAT(LPAD(HOUR(created_at_hour), 2, '0'), ':00:00 - ',
               LPAD(HOUR(created_at_hour), 2, '0'), ':59:59') AS hour_block,
        country_codes
    FROM payments
    WHERE status_group = 'failed'
) AS subquery
GROUP BY hour_block
ORDER BY hour_block;


















