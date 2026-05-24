SELECT * FROM vw_Project_of_Dates
ORDER BY Date ASC;

Create View vw_Project_of_Dates_Inventory As
SELECT 
    i.Product_ID,
    p.Product_Name,
    p.Cost_Per_KG,
    -- تصحيح القيمة السالبة للعجوة اللي اكتشفناها سوى
    CASE WHEN i.Stock_On_Hand_KG < 0 THEN 0 ELSE i.Stock_On_Hand_KG END AS Stock_On_Hand_KG,
    i.Wastage_KG,
    i.Wastage_Reason,
    -- حساب تكلفة الهدر المباشرة
    (i.Wastage_KG * p.Cost_Per_KG) AS Wastage_Cost
FROM inventory i
JOIN products p ON i.Product_ID = p.Product_ID;