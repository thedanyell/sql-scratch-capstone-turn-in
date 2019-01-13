-- #1 Find column names in survey table
SELECT *
FROM survey
LIMIT 10;



-- #2 Identify # of responses per question

SELECT question,
   COUNT(DISTINCT user_id) AS num_responses 
FROM survey
GROUP BY question
ORDER BY question;



    
-- #3 Which question(s) of the quiz have a lower completion rates?

-- (Above calculations completed in Excel)

-- What do you think is the reason? 

SELECT question, response,
   COUNT(response) AS num_response 
FROM survey
WHERE question = '3. Which shapes do you like?'
GROUP BY response

UNION

SELECT question, response,
   COUNT(response) AS num_response 
FROM survey
WHERE question = '5. When was your last eye exam?'
GROUP BY response
ORDER BY question, num_response DESC;




-- #4 What are the column names to the tables related to the purchase funnel?

SELECT *
FROM quiz
LIMIT 5;

SELECT *
FROM home_try_on
LIMIT 5;

SELECT *
FROM purchase
LIMIT 5;




-- #5 Create a new table with a LEFT JOIN. Select only the first 10 rows.

SELECT DISTINCT q.user_id,
   h.user_id IS NOT NULL AS 'is_home_try_on',
   h.number_of_pairs,
   p.user_id IS NOT NULL AS 'is_purchase'
FROM quiz q
LEFT JOIN home_try_on h
   ON q.user_id = h.user_id
LEFT JOIN purchase p
   ON p.user_id = q.user_id
LIMIT 10;



-- #6A - Overall Conversion

WITH funnel AS (
SELECT DISTINCT q.user_id,
   h.user_id IS NOT NULL AS is_home_try_on,
   h.number_of_pairs,
   p.user_id IS NOT NULL AS is_purchase
FROM quiz q
LEFT JOIN home_try_on h
   ON q.user_id = h.user_id
LEFT JOIN purchase p   
   ON p.user_id = q.user_id) 
SELECT
   COUNT(*) AS num_quiz,
   SUM(is_home_try_on) AS num_try_on,
   SUM(is_purchase) AS num_purchase,
   1.0 * SUM(is_home_try_on) / COUNT(user_id) * 100 AS 'try_on_%',
   1.0 * SUM(is_purchase) / SUM(is_home_try_on) * 100 AS 'purchase_%',
   1.0 * SUM(is_purchase) / COUNT(user_id)  * 100  AS 'overall_%'
FROM funnel;





-- #6B # Pairs vs # Purchases

WITH funnel AS (
  SELECT q.user_id, 
  h.user_id IS NOT NULL AS  'is_home_try_on',
	h.number_of_pairs, 
  p.user_id IS NOT NULL AS 'is_purchase'
FROM quiz q
LEFT JOIN home_try_on h
	ON q.user_id = h.user_id
LEFT JOIN purchase p
	ON h.user_id = p.user_id
WHERE h.number_of_pairs IS NOT NULL)
SELECT number_of_pairs,
  SUM(is_home_try_on) AS 'num_try_on', 
  SUM(is_purchase) AS 'num_purchase', 
	ROUND(1.0 * SUM(is_purchase) / SUM(is_home_try_on) * 100, 2) AS 'conversion_%'
FROM funnel
GROUP BY number_of_pairs;


-- #6C - # pairs vs $ purchased

WITH funnel AS (
   SELECT q.user_id,
   h.number_of_pairs,    
   p.user_id IS NOT NULL AS 'is_purchase',
   p.price
FROM quiz q
LEFT JOIN home_try_on h
   ON q.user_id = h.user_id
LEFT JOIN purchase p
   ON h.user_id = p.user_id
WHERE h.number_of_pairs IS NOT NULL)
SELECT number_of_pairs AS 'test_group',
   SUM(is_purchase) AS 'num_purchase', 
   ROUND(1.0 * SUM(price), 2) AS 'total_sales',
   ROUND(1.0 * AVG(price), 2) AS 'avg_spend'
FROM funnel
GROUP BY test_group;



-- #6D - Style Quiz Findings

SELECT style, 
   COUNT(style) AS num_response
FROM quiz
GROUP BY 1
ORDER BY 2 DESC;

SELECT fit, 
   COUNT(fit) AS num_response
FROM quiz
GROUP BY 1
ORDER BY 2 DESC;

SELECT shape, 
   COUNT(shape) AS num_response
FROM quiz
GROUP BY 1
ORDER BY 2 DESC;

SELECT color, 
   COUNT(color) AS num_response
FROM quiz
GROUP BY 1
ORDER BY 2 DESC;


-- #6E Purchase Style Findings
SELECT style, model_name, 
 COUNT(model_name) AS num_purchased
FROM purchase
GROUP BY model_name
ORDER BY 3 DESC;

WITH unicolors AS (
SELECT color, style, product_id, 
  COUNT(user_id) AS num_purchased
FROM purchase
GROUP BY product_id)
SELECT DISTINCT style, CASE 
  WHEN color LIKE '%Tortoise%' THEN 'Tortoise'
  WHEN color LIKE '%Black%' THEN 'Black'	  
  WHEN color LIKE '%Fade%' THEN 'Two-Tone'  
  WHEN color LIKE '%Crystal%' THEN 'Crystal'  
  WHEN color LIKE '%Gray%' THEN 'Neutral'  
  ELSE color
  END AS short_color, num_purchased
FROM unicolors
ORDER BY num_purchased DESC;




-- #6F Style conversions

WITH funnel AS ( 
SELECT q.user_id,
   h.user_id IS NOT NULL AS  'is_home_try_on',   
   h.number_of_pairs,   
   p.user_id IS NOT NULL AS 'is_purchase'
FROM quiz q
LEFT JOIN home_try_on h
    ON q.user_id = h.user_id
LEFT JOIN purchase p	
   ON h.user_id = p.user_id
WHERE h.number_of_pairs IS NOT NULL)
SELECT DISTINCT q.style AS 'original_quiz_style',     
   SUM(is_home_try_on) AS 'num_try_on',
   SUM(is_purchase) AS 'num_purchase', 	
   ROUND(1.0 * SUM(is_purchase) / SUM(is_home_try_on) * 100, 2) AS 'conversion_%'
FROM funnel f
LEFT JOIN quiz q
  ON f.user_id = q.user_id
GROUP BY 1
ORDER BY 4 DESC;



-- #6G Quiz to buy color conversions

WITH colorgroup AS (
SELECT q.user_id, q.style AS quiz_style, p.style AS buy_style, q.color AS quiz_color, 
CASE 
    WHEN p.color LIKE '%Tortoise%' THEN 'Tortoise'
	  WHEN p.color LIKE '%Black%' THEN 'Black'	
    WHEN p.color LIKE '%Fade%' THEN 'Two-Tone'
    WHEN p.color LIKE '%Crystal%' THEN 'Crystal'
    WHEN p.color LIKE '%Gray%' THEN 'Neutral'
  ELSE p.color
END AS buy_color
FROM quiz q
LEFT JOIN home_try_on h
	ON q.user_id = h.user_id
LEFT JOIN purchase p
	ON p.user_id = h.user_id
WHERE buy_color IS NOT NULL)
SELECT CASE
	WHEN c.quiz_color != c.buy_color THEN 'no'
	WHEN c.quiz_color = c.buy_color THEN 'yes'
END AS quiz_to_buy_match,
    COUNT(c.user_id) AS num_matched,
    ROUND (1.0 * COUNT(c.user_id) / 495, 2) * 100 AS '%_matched'
FROM colorgroup c
GROUP BY quiz_to_buy_match;





