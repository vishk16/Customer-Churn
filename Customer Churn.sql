use CustomerChurn;

-- Total Number of customers
SELECT
COUNT(DISTINCT [Customer ID]) AS customer_count
FROM dbo.telecom_customer_churn$;

-- check for duplicates in customer ID
SELECT [Customer ID],
COUNT( [Customer ID] )as count
FROM dbo.telecom_customer_churn$
GROUP BY [Customer ID]
HAVING count([Customer ID]) > 1;

-- DEEP DIVE ANALYSIS

-- How much revenue did maven lose to churned customers?
SELECT [Customer Status], 
COUNT([Customer ID]) AS customer_count,
ROUND((SUM([Total Revenue]) * 100.0) / SUM(SUM([Total Revenue])) OVER(), 1) AS Revenue_Percentage 
FROM dbo.telecom_customer_churn$
GROUP BY [Customer Status]; 

-- Typical tenure for new customers?
-- Typical tenure for churners
SELECT
    CASE 
        WHEN [Tenure in Months] <= 6 THEN '6 months'
        WHEN [Tenure in Months] <= 12 THEN '1 Year'
        WHEN [Tenure in Months] <= 24 THEN '2 Years'
        ELSE '> 2 Years'
    END AS Tenure,
    ROUND(COUNT([Customer ID]) * 100.0 / SUM(COUNT([Customer ID])) OVER(),1) AS Churn_Percentage
FROM
dbo.telecom_customer_churn$
WHERE
[Customer Status] = 'Churned'
GROUP BY
    CASE 
        WHEN [Tenure in Months] <= 6 THEN '6 months'
        WHEN [Tenure in Months] <= 12 THEN '1 Year'
        WHEN [Tenure in Months] <= 24 THEN '2 Years'
        ELSE '> 2 Years'
    END
ORDER BY
Churn_Percentage DESC;

-- How much revenue has maven lost?
 SELECT 
  [Customer Status], 
  CEILING(SUM([Total Revenue])) AS Revenue,     -- ceiling is used to Round up the figures
  ROUND((SUM([Total Revenue]) * 100.0) / SUM(SUM([Total Revenue])) OVER(), 1) AS Revenue_Percentage
FROM 
  dbo.telecom_customer_churn$
GROUP BY 
  [Customer Status];


-- Which cities have the highest churn rates?
SELECT
    TOP 4 City,
    COUNT([Customer ID]) AS Churned,
    CEILING(COUNT(CASE WHEN [Customer Status] = 'Churned' THEN [Customer ID] ELSE NULL END) * 100.0 / COUNT([Customer ID])) AS Churn_Rate
FROM
    dbo.telecom_customer_churn$
GROUP BY
    City
HAVING
    COUNT([Customer ID])  > 30
AND
    COUNT(CASE WHEN [Customer Status] = 'Churned' THEN [Customer ID] ELSE NULL END) > 0
ORDER BY
    Churn_Rate DESC;


	-- Why did customers leave and how much did it cost?
SELECT 
  [Churn Category],  
  ROUND(SUM([Total Revenue]),0)AS Churned_Rev,
  CEILING((COUNT([Customer ID]) * 100.0) / SUM(COUNT([Customer ID])) OVER()) AS Churn_Percentage
FROM 
  dbo.telecom_customer_churn$
WHERE 
    [Customer Status] = 'Churned'
GROUP BY 
  [Churn Category]
ORDER BY 
  Churn_Percentage DESC; 


-- why exactly did customers churn?
SELECT TOP 5
    [Churn Reason],
    [Churn Category],
    ROUND(COUNT([Customer ID]) *100 / SUM(COUNT([Customer ID])) OVER(), 1) AS churn_percentage
FROM
    dbo.telecom_customer_churn$
WHERE
    [Customer Status] = 'Churned'
GROUP BY 
[Churn Reason],
[Churn Category]
ORDER BY churn_percentage DESC;


-- What offers did churners have?
SELECT  
    Offer,
    ROUND(COUNT([Customer ID]) * 100.0 / SUM(COUNT([Customer ID])) OVER(), 1) AS churned
FROM
    dbo.telecom_customer_churn$
WHERE
    [Customer Status] = 'Churned'
GROUP BY
Offer
ORDER BY 
churned DESC;


-- What Internet Type did churners have?
SELECT
    [Internet Type],
    COUNT([Customer ID]) AS Churned,
    ROUND(COUNT([Customer ID]) * 100.0 / SUM(COUNT([Customer ID])) OVER(), 1) AS Churn_Percentage
FROM
    dbo.telecom_customer_churn$
WHERE 
    [Customer Status] = 'Churned'
GROUP BY
[Internet Type]
ORDER BY 
Churned DESC;



-- What Internet Type did 'Competitor' churners have?
SELECT
    [Internet Type],
    [Churn Category],
    ROUND(COUNT([Customer ID]) * 100.0 / SUM(COUNT([Customer ID])) OVER(), 1) AS Churn_Percentage
FROM
    dbo.telecom_customer_churn$
WHERE 
    [Customer Status] = 'Churned'
    AND [Churn Category] = 'Competitor'
GROUP BY
[Internet Type],
[Churn Category]
ORDER BY Churn_Percentage DESC;

-- What contract were churners on?
SELECT 
    Contract,
    COUNT([Customer ID]) AS Churned,
    ROUND(COUNT([Customer ID]) * 100.0 / SUM(COUNT([Customer ID])) OVER(), 1) AS Churn_Percentage
FROM 
    dbo.telecom_customer_churn$
WHERE
    [Customer Status] = 'Churned'
GROUP BY
    Contract
ORDER BY 
    Churned DESC;

-- Did churners have premium tech support?
SELECT 
    [Premium Tech Support],
    COUNT([Customer ID]) AS Churned,
    ROUND(COUNT([Customer ID]) *100.0 / SUM(COUNT([Customer ID])) OVER(),1) AS Churn_Percentage
FROM
    dbo.telecom_customer_churn$
WHERE 
    [Customer Status] = 'Churned'
GROUP BY [Premium Tech Support]
ORDER BY Churned DESC;

-- What contract were churners on?
SELECT 
    Contract,
    COUNT([Customer ID]) AS Churned,
    ROUND(COUNT([Customer ID]) * 100.0 / SUM(COUNT([Customer ID])) OVER(), 1) AS Churn_Percentage
FROM 
    dbo.telecom_customer_churn$
WHERE
    [Customer Status] = 'Churned'
GROUP BY
    Contract
ORDER BY 
    Churned DESC;


-- Are high value customers at risk?

SELECT 
    CASE 
        WHEN (num_conditions >= 3) THEN 'High Risk'
        WHEN num_conditions = 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level,
    COUNT([Customer ID]) AS num_customers,
    ROUND(COUNT([Customer ID]) *100.0 / SUM(COUNT([Customer ID])) OVER(),1) AS cust_percentage,
    num_conditions  
FROM 
    (
    SELECT 
        [Customer ID],
        SUM(CASE WHEN Offer = 'Offer E' OR Offer = 'None' THEN 1 ELSE 0 END)+
        SUM(CASE WHEN Contract = 'Month-to-Month' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN [Premium Tech Support] = 'No' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN [Internet Service] = 'Fiber Optic' THEN 1 ELSE 0 END) AS num_conditions
    FROM 
        dbo.telecom_customer_churn$
    WHERE 
        [Monthly Charge] > 70.05 
        AND [Customer Status] = 'Stayed'
        AND [Number of Referrals] > 0
        AND [Tenure in Months] > 6
    GROUP BY 
        [Customer ID]
    HAVING 
        SUM(CASE WHEN Offer = 'Offer E' OR Offer = 'None' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN Contract = 'Month-to-Month' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN [Premium Tech Support] = 'No' THEN 1 ELSE 0 END) +
        SUM(CASE WHEN [Internet Type] = 'Fiber Optic' THEN 1 ELSE 0 END) >= 1
    ) AS subquery
GROUP BY 
    CASE 
        WHEN (num_conditions >= 3) THEN 'High Risk'
        WHEN num_conditions = 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END, num_conditions; 


-- why did customer's churn exactly?
SELECT TOP 10
    [Churn Reason],
    [Churn Category],
    ROUND(COUNT([Customer ID]) *100 / SUM(COUNT([Customer ID])) OVER(), 1) AS churn_perc
FROM
    dbo.telecom_customer_churn$
WHERE
    [Customer Status] = 'Churned'
GROUP BY 
[Churn Reason],
[Churn Category]
ORDER BY churn_perc DESC;

-- HOW old were churners?
SELECT  
    CASE
        WHEN Age <= 30 THEN '19 - 30 yrs'
        WHEN Age <= 40 THEN '31 - 40 yrs'
        WHEN Age <= 50 THEN '41 - 50 yrs'
        WHEN Age <= 60 THEN '51 - 60 yrs'
        ELSE  '> 60 yrs'
    END AS Age,
    ROUND(COUNT([Customer ID]) * 100 / SUM(COUNT([Customer ID])) OVER(), 1) AS Churn_Percentage
FROM 
    dbo.telecom_customer_churn$
WHERE
    [Customer Status] = 'Churned'
GROUP BY
    CASE
        WHEN Age <= 30 THEN '19 - 30 yrs'
        WHEN Age <= 40 THEN '31 - 40 yrs'
        WHEN Age <= 50 THEN '41 - 50 yrs'
        WHEN Age <= 60 THEN '51 - 60 yrs'
        ELSE  '> 60 yrs'
    END
ORDER BY
Churn_Percentage DESC;

-- What gender were churners?
SELECT
    Gender,
    ROUND(COUNT([Customer ID]) *100.0 / SUM(COUNT([Customer ID])) OVER(), 1) AS Churn_Percentage
FROM
    dbo.telecom_customer_churn$
WHERE
    [Customer Status] = 'Churned'
GROUP BY
    Gender
ORDER BY
Churn_Percentage DESC;

-- Did churners have dependents
SELECT
    CASE
        WHEN [Number of Dependents] > 0 THEN 'Has Dependents'
        ELSE 'No Dependents'
    END AS Dependents,
    ROUND(COUNT([Customer ID]) *100 / SUM(COUNT([Customer ID])) OVER(), 1) AS Churn_Percentage

FROM
    dbo.telecom_customer_churn$
WHERE
    [Customer Status] = 'Churned'
GROUP BY 
CASE
        WHEN [Number of Dependents] > 0 THEN 'Has Dependents'
        ELSE 'No Dependents'
    END
ORDER BY Churn_Percentage DESC;

-- Were churners married
SELECT
    Married,
    ROUND(COUNT([Customer ID]) *100.0 / SUM(COUNT([Customer ID])) OVER(), 1) AS Churn_Percentage
FROM
    dbo.telecom_customer_churn$
WHERE
    [Customer Status] = 'Churned'
GROUP BY
    Married
ORDER BY
Churn_Percentage DESC;

-- Do churners have phone lines
SELECT
    [Phone Service],
    ROUND(COUNT([Customer ID]) * 100.0 / SUM(COUNT([Customer ID])) OVER(), 1) AS Churned
FROM
    dbo.telecom_customer_churn$
WHERE
    [Customer Status] = 'Churned'
GROUP BY 
    [Phone Service];


-- Do churners have internet service
SELECT
    [Internet Service],
    ROUND(COUNT([Customer ID]) * 100.0 / SUM(COUNT([Customer ID])) OVER(), 1) AS Churned
FROM
    dbo.telecom_customer_churn$
WHERE
    [Customer Status] = 'Churned'
GROUP BY 
    [Internet Service];


-- Did they give referrals
SELECT
    CASE
        WHEN [Number of Referrals] > 0 THEN 'Yes'
        ELSE 'No'
    END AS Referrals,
    ROUND(COUNT([Customer ID]) * 100.0 / SUM(COUNT([Customer ID])) OVER(), 1) AS Churned
FROM
    dbo.telecom_customer_churn$
WHERE
    [Customer Status] = 'Churned'
GROUP BY 
    CASE
        WHEN [Number of Referrals] > 0 THEN 'Yes'
        ELSE 'No'
    END;


-- What Internet Type did 'Competitor' churners have?
SELECT
    [Internet Type],
    [Churn Category],
    ROUND(COUNT([Customer ID]) * 100.0 / SUM(COUNT([Customer ID])) OVER(), 1) AS Churn_Percentage
FROM
    dbo.telecom_customer_churn$
WHERE 
    [Customer Status] = 'Churned'
    AND [Churn Category] = 'Competitor'
GROUP BY
[Internet Type],
[Churn Category]
ORDER BY Churn_Percentage DESC;