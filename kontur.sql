
-- для план-факт анализа, таблица плана
SELECT rPlan.scID,
       rPlan.plan_amount,
       strftime('%m', rPlan.dt) as plan_month,
       strftime('%Y', rPlan.dt) as plan_year
FROM rPlan
         LEFT JOIN Agents A on rPlan.scID = A.scID
WHERE product = 'Бухгалтерия.Контур' AND A.regionCode = 77
ORDER BY plan_year, plan_month

-- для план-факт анализа, таблица факта
SELECT Bills.scID,
       strftime('%m', Bills.PayDate) as fact_month,
       strftime('%Y', Bills.PayDate) as fact_year,
       SUM(BC.Cost)
FROM Bills
         JOIN BillsContent BC on Bills.bID = BC.bID
         JOIN PriceItems PI on BC.piID = PI.piID
         JOIN Agents A on Bills.scID = A.scID
WHERE PayDate IS NOT NULL AND product = 'Бухгалтерия.Контур' AND A.regionCode = 77
GROUP BY 1, 2, 3;

-- для план-факт анализа, объединенные данные по продажам, 77 регион (в Excel лист "план-факт")
WITH fact_table AS (
    SELECT Bills.scID,
           strftime('%m', Bills.PayDate) as fact_month,
           strftime('%Y', Bills.PayDate) as fact_year,
           SUM(BC.Cost) as fact_sales
    FROM Bills
             JOIN BillsContent BC on Bills.bID = BC.bID
             JOIN PriceItems PI on BC.piID = PI.piID
             JOIN Agents A on Bills.scID = A.scID
    WHERE PayDate IS NOT NULL AND product = 'Бухгалтерия.Контур' AND A.regionCode = 77
    GROUP BY 1, 2, 3
),
     plan_table AS (
         SELECT rPlan.scID,
                rPlan.plan_amount,
                strftime('%m', rPlan.dt) as plan_month,
                strftime('%Y', rPlan.dt) as plan_year
         FROM rPlan
                  LEFT JOIN Agents A on rPlan.scID = A.scID
         WHERE product = 'Бухгалтерия.Контур' AND A.regionCode = 77
         ORDER BY plan_year, plan_month
     )
SELECT plan_table.scID,
       plan_amount as plan_sales,
       fact_sales,
       round(fact_sales - plan_amount) as abs_dev,
       round((fact_sales - plan_amount) / plan_amount * 100) as rel_dev,
       plan_year as year,
       plan_month as month
FROM plan_table
         JOIN fact_table on plan_table.scID = fact_table.scID
    AND plan_table.plan_month = fact_table.fact_month
    AND plan_table.plan_year = fact_table.fact_year


-- для анализа тарифов - фактические продажи с разбивкой по тарифам и клиентам
SELECT C.cID,
       cName,
       piName,
       strftime('%m', Bills.PayDate) as fact_month,
       strftime('%Y', Bills.PayDate) as fact_year,
       SUM(BC.Cost)
FROM Bills
         JOIN BillsContent BC on Bills.bID = BC.bID
         JOIN PriceItems PI on BC.piID = PI.piID
         JOIN Agents A on Bills.scID = A.scID
         join Clients C on Bills.cID = C.cID
WHERE PayDate IS NOT NULL AND product = 'Бухгалтерия.Контур' AND A.regionCode = 77
GROUP BY 1, 2, 3, 4, 5;

--для емкости рынка - количество клиентов по годам
SELECT COUNT(DISTINCT C.cID),
       STRFTIME('%Y', B.BDate) as fact_year
FROM Clients C
         JOIN Bills B on C.cID = B.cID
         JOIN BillsContent BC on B.bID = BC.bID
         JOIN PriceItems PI on BC.piID = PI.piID
WHERE PI.product = 'Бухгалтерия.Контур'
  AND C.regCode = 77
  AND C.kpp =''
GROUP BY 2;


-- таблица фактических продаж по всем продуктам (в Excel лист "продажи по продуктам")
SELECT product,
       strftime('%Y', Bills.PayDate) as fact_year,
       SUM(BC.Cost)
FROM Bills
         JOIN BillsContent BC on Bills.bID = BC.bID
         JOIN PriceItems PI on BC.piID = PI.piID
         JOIN Agents A on Bills.scID = A.scID
WHERE PayDate IS NOT NULL AND A.regionCode = 77
GROUP BY 1, 2