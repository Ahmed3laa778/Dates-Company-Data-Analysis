/*
--هظهر كل الجدول الي محتاج يتنظف عشان اشوف هنظف ايه
select * 
From sales_dirty

/* 
لاحظت اني عدد العملاء عندي 15 عميل بالتالي اي قيمة اكبر من 15 هتكون خطأ و انا بشوف البيانات لاحظت اني فيه قيمة بتساوي 99 
فهنعمل كود يجيب كل القيم الي المفروض غلط و المفروض اني انا عندي 5 برودكت اي دي ياعني اي رقم اكبر من 5 هنشيلو برضو و كذالك في الريب اي دي المفروض انهم 8 ف اي رقم اكبر من 8  هنشيلو 
*/

select * 
From sales_dirty
Where Customer_ID >= 'C16' OR Product_ID >= 'P06' OR Rep_ID >= 'R09';

/* هنعمل كود يمسح القيمتين دول لانهم قيمتين شاذين كدا كدا لمي اربط الجداول هتتمسح وحدها لاني مش هيكون ليها
مقابل بس الافضل اننا نمسحها عشان نفتكر و ننبه عنها في التقرير
*/
DELETE FROM sales_dirty Where Customer_ID = 'C99' OR Product_ID >= 'P99';

/* بعد كدا هرجع اتشيك الداتا تاني اشوف فيه محتاج يتصلح
لقيت اني في عمود التاريخ قيم  بساوي Null
فهنشوف عددها كام لو قليل بالنسبة لل1250 صف الي عندي هنشيلهم لاني التاريخ حرج وبيتبني عليه حجات كتير ف التحليل
*/

select Count(*) As NULL_Values
From sales_dirty
Where Date IS NULL 

-- عدد القيم الي ملهمش قيمة بيساوي 10 و ده رقم قليل بالنسبة ل 1250 صف ميستهلش اننا نضحي بدقة التحليل عشانه
-- عشان كدا هنمسح ال10 قيم دول

DELETE FROM sales_dirty Where Date IS NULL;

-- هنتشك انهم اتمسحو و بعدين نشغل اول كويري تاني عشان نشوف الدور علي ايه 
-- الكمية بالكيلو فيها قيم مش موجودة وفيها قيم بالسالب هعمل كويري نشوف بيها ايه دول

Select Qty_KG
From sales_dirty
Order by Qty_KG DESC;

-- في قيمة ب99 الف و ده طبعا مش ماشي مع باقي القيم في العمود نهائي و في قيمة ب-500 ده الي قال عليه انو مرتجع وفي قيم بتساوي نال
-- هنشيل القيم الشاذة زي السالب و الرقم الكبير جدا الي كان ممكن نبدله بالمتوسط بس اننا نشيله اسرع و اامن
DELETE FROM sales_dirty WHERE Qty_KG = 99999 OR Qty_KG = -500;

--دلوقت القيم الي بتساوي نال نشوف عددها الاول
Select Count(*) From sales_dirty Where Qty_KG IS NULL;

-- عددهم 24 خلية
--هنحسب تمن كل منتج و نساوي القيم المفقوده بالمتوسط الحسابي باستخدام CTE

WITH ProductAvgQty AS (
    SELECT Product_ID, AVG(Qty_KG) AS Avg_Qty
    FROM sales_dirty
    WHERE Qty_KG IS NOT NULL 
    GROUP BY Product_ID
)
UPDATE s
SET s.Qty_KG = a.Avg_Qty
FROM sales_dirty s
JOIN ProductAvgQty a ON s.Product_ID = a.Product_ID
WHERE s.Qty_KG IS NULL;

--هنخش علي العمود الي بعده سعر الشحن
-- فيه قيم بتساوي نال و فيه قيمه بتساوي 150 بالسالب
Select Shipping_Cost
From sales_dirty
Order by Shipping_Cost DESC;

-- اول حاجه هنحذف القيمة السالبة
DELETE FROM sales_dirty WHERE Shipping_Cost = -150;

-- هنشوف عدد القيم النالز في العمود

Select Count(*) From sales_dirty Where Shipping_Cost IS NULL;

-- في 15 قيمة نال حالياً ممكن نحذفهم بس احنا هنستخدم نفس الكود الي عملناه في عمود الكمية نجيب المتوسط

WITH CustomerAvgShipping AS (
    SELECT Customer_ID, AVG(Shipping_Cost) AS Avg_Ship
    FROM sales_dirty
    WHERE Shipping_Cost IS NOT NULL
    GROUP BY Customer_ID
)
UPDATE s
SET s.Shipping_Cost = c.Avg_Ship
FROM sales_dirty s
JOIN CustomerAvgShipping c ON s.Customer_ID = c.Customer_ID
WHERE s.Shipping_Cost IS NULL;

*/
-- كدا احنا خلصنا مرحلة التنظيف--

/*
SELECT COUNT(*) FROM sales_dirty

Select *
From sales_dirty
Join products
On sales_dirty.Product_ID = products.Product_ID
*/

/*
SELECT 
    COUNT(s.Trans_ID) AS Total_Transactions,
    SUM(s.Qty_KG) AS Total_Qty_Sold,
    SUM(s.Qty_KG * p.Price_Per_KG * (1 - s.Discount_Pct)) AS Total_Revenue
FROM sales_dirty s
JOIN products p ON s.Product_ID = p.Product_ID;
*/

/*
أي عميل أكتر ربحية؟
*/

SELECT 
    c.Customer_Name, 
    SUM((s.Qty_KG * p.Price_Per_KG * (1 - s.Discount_Pct)) - ((s.Qty_KG * p.Cost_Per_KG) + s.Shipping_Cost)) AS Total_Profit
FROM sales_dirty s
JOIN products p ON s.Product_ID = p.Product_ID
JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Customer_Name
ORDER BY Total_Profit DESC;

/*
أي صنف تمر بيخسرنا؟
*/

SELECT 
    p.Product_Name,
    SUM((s.Qty_KG * p.Price_Per_KG * (1 - s.Discount_Pct)) - ((s.Qty_KG * p.Cost_Per_KG) + s.Shipping_Cost)) AS Sales_Profit
FROM sales_dirty s
JOIN products p ON s.Product_ID = p.Product_ID
GROUP BY p.Product_Name
ORDER BY Sales_Profit ASC;

/*
"نوصي بوقف بيع وتوريد التمر الصفاوي فوراً أو إعادة تسعيره بما لا يقل عن 30 للـ KG لتغطية التكلفة والشحن. كما يجب فتح تحقيق مع إدارة المخازن بسبب الهدر الضخم الناتج عن الإصابة الحشرية."
*/

/*
هل في دولة الشحن ليها بيكلفني اكتر 
*/

/*
تم الاتصال بمدخل البيانات لمعرفة الدولة التي كانت تنقصنا و استبدلناها ب غير معروف و اتضح انها السعودية
*/

UPDATE Customers
SET Country = (SELECT Country FROM Customers WHERE Customer_ID = 'C02')
WHERE Customer_ID = 'C05';

/*
هل في دول تكلفة الشحن ليها عالية زيادة؟
*/

SELECT 
    c.Country,
    SUM(s.Shipping_Cost) AS Total_Shipping_Cost,
    SUM(s.Qty_KG) AS Total_Qty_Shipped,
    SUM(s.Shipping_Cost) / SUM(s.Qty_KG) AS Shipping_Cost_Per_KG
FROM sales_dirty s
JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Country
ORDER BY Total_Shipping_Cost DESC;
 /*
 "هناك خلل واضح في تسعير الشحن لدولة الإمارات؛ حيث نتحمل 4.30 لكل كيلوجرام تمر، وهو ما يقارب 4 أضعاف تكلفة الشحن للسعودية وعمان. نوصي بمراجعة العقود مع شركة الشحن الحالية أو إجبار عملاء الإمارات على تحمل جزء من تكاليف الشحن."
 */
  /*
  تحليل الهدر والأسباب
  */
SELECT 
    p.Product_Name,
    i.Stock_On_Hand_KG,
    i.Wastage_KG,
    (i.Wastage_KG * p.Cost_Per_KG) AS Wastage_Cost,
    i.Wastage_Reason
FROM inventory i
JOIN products p ON i.Product_ID = p.Product_ID
ORDER BY Wastage_Cost DESC;

/*
"نوصي بعمل جرد فعلي فوري لـ تمر عجوة المدينة في المستودعات لتصحيح الرصيد السالب (-200 كجم) على السيستم، حيث أن العجوة هي المنتج الأعلى ربحية للشركة (تدر أكثر من 7.7 مليون صافي ربح)، ولا يجوز ترك بيانات مخزونها تالفة بهذا الشكل."
*/
Update inventory
set Stock_On_Hand_KG = -200
where Stock_On_Hand_KG = 0;

/*
مين الموظف المقصر و مين الموظف الي محقق التارجت بتاعه
*/

SELECT 
    r.Rep_Name,
    r.Target_Sales,
    SUM(s.Qty_KG * p.Price_Per_KG * (1 - s.Discount_Pct)) AS Actual_Revenue,
    (SUM(s.Qty_KG * p.Price_Per_KG * (1 - s.Discount_Pct)) / r.Target_Sales) * 100 AS Achievement_Pct
FROM sales_dirty s
JOIN products p ON s.Product_ID = p.Product_ID
JOIN sales r ON s.Rep_ID = r.Rep_ID
GROUP BY r.Rep_Name, r.Target_Sales
ORDER BY Actual_Revenue DESC;

/*
تحليل حركة المبيعات الشهرية للشركة
*/

SELECT 
    MONTH(Date) AS Month_Num,
    SUM(Qty_KG * Price_Per_KG * (1 - Discount_Pct)) AS Total_Revenue
FROM sales_dirty
join Products On sales_dirty.Product_ID = products.Product_ID
GROUP BY MONTH(Date)
ORDER BY Month_Num;

/*
"نوصي إدارة الإنتاج والمخازن ببدء التعبئة وتجميع المخزون بحد أدنى في شهر ديسمبر و يناير، لتجهيز كميات ضخمة تغطي طلبات شهور (مارس، أبريل، مايو). أي نقص في بضاعة العجوة أو المجدول في هذه الثلاثة شهور سيعني خسارة ملايين المحققة للشركة."
*/

/*
هل زيادة نسبة المبيعات بتخسرنا صافي الربح ولا بتزود المبيعات فعلا؟
*/

SELECT 
    s.Discount_Pct,
    COUNT(s.Trans_ID) AS Total_Transactions,
    SUM(s.Qty_KG) AS Total_Qty_Sold,
    SUM(s.Qty_KG * p.Price_Per_KG * (1 - s.Discount_Pct)) AS Total_Revenue,
    SUM((s.Qty_KG * p.Price_Per_KG * (1 - s.Discount_Pct)) - ((s.Qty_KG * p.Cost_Per_KG) + s.Shipping_Cost)) AS Total_Profit
FROM sales_dirty s
JOIN products p ON s.Product_ID = p.Product_ID
GROUP BY s.Discount_Pct
ORDER BY s.Discount_Pct;
/*
الخصم العالي يدمر الأرباح بدون فائدة (فخ الـ 35%):
عند نسبة خصم 35%، الشركة باعت كمية ضخمة جداً (أكثر من 120 ألف كيلو) عبر 171 فاتورة، ولكن صافي الربح الإجمالي انهار ليكون الأقل في الجدول بالكامل (898,756 فقط!). ومتوسط ربح الفاتورة الواحدة نزل لـ 5 آلاف بعد ما كان فوق الـ 21 ألف. هذا يعني أن الخصم العالي لم يحفز حركة بيع تكفي لتعويض الخسارة، بل كان مجرد هدر للأرباح.

الـ Sweet Spot (النقطة السحرية للخصم):
أفضل نسبة خصم حققت توازن مثالي للشركة هي 10%. عند هذه النسبة، قفز متوسط ربح الفاتورة الواحدة لأعلى قيمة له في الشركة (22,001)، وحققت كميات بيع ممتازة (133 ألف كيلو) وبأرباح إجمالية قوية جداً تخطت الـ 3.6 مليون.
*/

/*
التوصية الاستراتيجية النهائية للمدير:
"نوصي بـ إلغاء ووقف سياسة الخصم بنسبة 35% فوراً؛ حيث تبين أنها تستنزف هوامش أرباح التمور وتتسبب في خسائر غير مبررة للشركة. وفي المقابل، نوصي باعتماد نسبة خصم 10% كحد أقصى (Cap) للحملات الترويجية الكبرى لأنها تحقق أعلى معدل ربحية للفاتورة وتجذب كميات طلب ممتازة."
*/

/*
الجدول النهائي الي هنعمل عليه الداش بورد
*/
Create View vw_Project_of_Dates AS
SELECT 
    s.Trans_ID,
    s.Date,
    -- بيانات العميل
    c.Customer_Name,
    c.Country,
    c.Segment,
    -- بيانات موظف المبيعات
    r.Rep_Name,
    r.Region,
    r.Target_Sales AS Rep_Monthly_Target,
    -- بيانات المنتج
    p.Product_Name,
    p.Category,
    p.Price_Per_KG,
    p.Cost_Per_KG,
    -- بيانات المعاملة المالية
    s.Qty_KG,
    s.Discount_Pct,
    s.Shipping_Cost,
    -- الحسابات المالية التلقائية (العواميد المحسوبة)
    (s.Qty_KG * p.Price_Per_KG * (1 - s.Discount_Pct)) AS Gross_Revenue,
    (s.Qty_KG * p.Cost_Per_KG) AS Product_Cost,
    ((s.Qty_KG * p.Cost_Per_KG) + s.Shipping_Cost) AS Total_Cost,
    ((s.Qty_KG * p.Price_Per_KG * (1 - s.Discount_Pct)) - ((s.Qty_KG * p.Cost_Per_KG) + s.Shipping_Cost)) AS Net_Profit

FROM sales_dirty s
INNER JOIN products p ON s.Product_ID = p.Product_ID
INNER JOIN customers c ON s.Customer_ID = c.Customer_ID
INNER JOIN sales r ON s.Rep_ID = r.Rep_ID;