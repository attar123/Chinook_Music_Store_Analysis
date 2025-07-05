-- Table 1. Album
-- Columns: album_id, title, artist_Id
-- Check for NULLs:
use chinook
SELECT * FROM Album
WHERE title IS NULL OR album_id IS NULL;
-- Check for duplicates:
SELECT title, artist_Id, COUNT(*) 
FROM Album 
GROUP BY title, artist_Id 
HAVING COUNT(*) > 1;

-- Table 2. Artist
-- Columns: artist_Id, name
-- Check for NULLs:
SELECT * FROM Artist 
WHERE name IS NULL OR artist_Id  IS NULL;
-- Check for duplicates:
SELECT name, COUNT(*) 
FROM Artist 
GROUP BY Name 
HAVING COUNT(*) > 1;

-- Table 3. Customer
-- Columns: customer_id, first_name, last_name, company, address, city, state, country, postal_code, phone	fax, nemail, support_rep_id
-- Check for NULLs:
SELECT * FROM Customer 
WHERE first_name IS NULL OR last_name IS NULL OR email IS NULL;
-- Check for duplicates:
SELECT email, COUNT(*) 
FROM Customer 
GROUP BY email;

-- Table 4. Employee
-- Columns: employee_id, last_name, first_name, title, reports_to, birthdate, hire_date, 
-- address, city, state, country, postal_code, phone, fax, email
-- Check for NULLs:
SELECT * FROM Employee
WHERE last_name IS NULL OR first_name IS NULL OR title IS NULL;
-- Check for duplicates:
SELECT first_name, last_name, title, hire_date, COUNT(*) 
FROM Employee 
GROUP BY first_name, last_name, title, hire_date 
HAVING COUNT(*) > 1;

-- Table 5. Genre
-- Columns: genre_Id, name
-- Check for NULLs:
SELECT * FROM Genre
WHERE genre_Id IS NULL OR name IS NULL;
-- Check for duplicates:
SELECT name, COUNT(*) FROM Genre GROUP BY name HAVING COUNT(*) > 1;

-- Table 6. Invoice
-- Columns: invoice_id, customer_id, invoice_date, billing_address, billing_city, billing_state, billing_country, billing_postal_code,total
-- Check for NULLs:
SELECT * FROM Invoice 
WHERE invoice_id IS NULL OR  customer_id IS NULL OR invoice_date IS NULL OR total IS NULL;
-- Check for duplicates:
SELECT invoice_id,customer_id, invoice_date, total, COUNT(*) 
FROM Invoice 
GROUP BY invoice_id,customer_id, invoice_date, total
HAVING COUNT(*) > 1;

-- Table 7. Invoice_Line ******
-- Columns: invoice_line_id, invoice_id, track_id, unit_price, quantity
-- Check for NULLs:
SELECT * FROM Invoice_Line 
WHERE invoice_id IS NULL OR invoice_line_id IS NULL OR track_id IS NULL OR unit_price IS NULL OR quantity IS NULL;
-- Check for duplicates: ********
SELECT invoice_id, track_id, unit_price, quantity, COUNT(*) as duplicate_count
FROM Invoice_Line
GROUP BY invoice_id, track_id, unit_price, quantity
HAVING COUNT(*) > 1;

-- Table 8. Media_Type
-- Columns: media_type_id, name
-- Check for NULLs:
SELECT * FROM Media_Type WHERE name IS NULL;
-- Check for duplicates: 
SELECT name, COUNT(*) FROM Media_Type GROUP BY name HAVING COUNT(*) > 1;

-- Table 9. playlist *******
-- Columns: playlist_id, name
-- Check for NULLs:
 SELECT * FROM Playlist WHERE Name IS NULL;
 -- Check for duplicates:  ******
 SELECT name, COUNT(*) FROM Playlist GROUP BY name HAVING COUNT(*) > 1;
 
-- Table 10. Playlist_Track
-- Columns: playlist_id, track_id
-- Check for NULLs:
 SELECT * FROM Playlist_Track 
 WHERE playlist_id IS NULL OR track_id IS NULL;
  -- Check for duplicates: 
SELECT playlist_id, track_id, COUNT(*)  FROM Playlist_Track 
GROUP BY playlist_id, track_id
HAVING COUNT(*) > 1;

-- Table 11. Track
-- Columns: track_id, name, album_id, media_type_id, genre_id, composer, milliseconds, bytes, unit_price
-- Check for NULLs:
SELECT * FROM Track
WHERE name IS NULL OR media_type_id IS NULL OR milliseconds IS NULL OR unit_price IS NULL;
-- Check for duplicates: 
SELECT name, album_id, media_type_id, milliseconds, COUNT(*) 
FROM Track 
GROUP BY name, album_id, media_type_id, milliseconds
HAVING COUNT(*) > 1;

-- 2.	Find the top-selling tracks and top artist in the USA and identify their most famous genres.
with top_selling_tracks_artists as (select 
t.name as track_name, art.name as artist_name, g.name as genre_name, 
sum(i.total) as total_sales, 
rank() over (order by sum(i.total) desc) as sales_rank
from invoice i
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join album alb on t.album_id = alb.album_id
join artist art on alb.artist_id = art.artist_id
join genre g on t.genre_id = g.genre_id
where i.billing_country = 'USA'
group by t.name, art.name, g.name)
select * from top_selling_tracks_artists
order by total_sales desc,track_name asc
limit 10;

-- 3.	What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?
--  customer demographic breakdown by country, state and city
select country, coalesce(state, 'NONE') as state, city, 
count(customer_id) as demographic_dist 
from customer 
group by country, state, city 
order by country;
--  customer demographic breakdown by country
select country, count(customer_id) as custumer_count 
from customer 
group by country
order by custumer_count desc;

-- 4.	Calculate the total revenue and number of invoices for each country, state, and city:
select billing_country, billing_state, billing_city, 
sum(total) as total_revenue, 
count(invoice_id) as num_of_invoices 
from invoice 
group by billing_country, billing_state, billing_city 
order by total_revenue desc, num_of_invoices desc;

-- 5.	Find the top 5 customers by total revenue in each country
with top5 as (select  c.country, 
concat(c.first_name, ' ', c.last_name) as customer, 
sum(i.total) as total_revenue, 
rank() over (partition by c.country order by sum(i.total) desc) as countrywise_rank
from customer c 
inner join invoice i on c.customer_id = i.customer_id 
group by c.country, c.first_name, c.last_name)
select country, customer, total_revenue 
from top5 
where countrywise_rank <= 5 
order by country, total_revenue desc;

-- 6.	Identify the top-selling track for each customer
with customer_track_sales as (
select c.customer_id, c.first_name, c.last_name, t.track_id, t.name as track_name, 
sum(il.quantity) as total_quantity, sum(i.total) as total_sales, 
row_number() over (partition by c.customer_id order by sum(i.total) desc) as sales_rank
from customer c 
left join invoice i on c.customer_id = i.customer_id 
left join invoice_line il on i.invoice_id = il.invoice_id 
left join track t on il.track_id = t.track_id 
group by c.customer_id, c.first_name, c.last_name, t.track_id, t.name)
select customer_id, concat(first_name, ' ', last_name) as customer_name, 
track_id, track_name, total_quantity, total_sales 
from customer_track_sales 
where sales_rank = 1 
order by total_sales desc;

-- 7.	Are there any patterns or trends in customer purchasing behavior 
-- (e.g., frequency of purchases, preferred payment methods, average order value)?
with purchase_frequency as (
select c.customer_id, c.first_name, c.last_name, 
count(i.invoice_id) as total_purchases, 
min(date(i.invoice_date)) as first_purchase_date, 
max(date(i.invoice_date)) as latest_purchase_date, 
round(datediff(max(date(i.invoice_date)), min(date(i.invoice_date))) / coalesce(count(i.invoice_id) - 1, 0), 0) 
as avg_days_bet_purchases
from customer c 
join invoice i on c.customer_id = i.customer_id 
group by c.customer_id, c.first_name, c.last_name)
select * from purchase_frequency 
order by avg_days_bet_purchases, total_purchases desc;

-- 8.	What is the customer churn rate?
with previous_customer_purchases as ( 
select  c.customer_id, c.first_name, c.last_name, 
date(i.invoice_date) as invoice_date, 
lead(date(i.invoice_date)) over(partition by c.customer_id order by invoice_date desc) as prev_purchase 
from customer c 
join invoice i on c.customer_id = i.customer_id ), 
prev_purchase_rank as ( 
select  *, row_number() over(partition by customer_id order by prev_purchase desc) as prev_purchase_rn 
from previous_customer_purchases ), 
previous_purchase_date as ( select  *, datediff(invoice_date, prev_purchase) as days_since_last_purchase 
from prev_purchase_rank 
where prev_purchase_rn = 1 
and datediff(invoice_date, prev_purchase) > 180 
order by days_since_last_purchase desc ) 
select  count(pp.customer_id) as churned_customers, 
count(c.customer_id) as total_customers, 
round((count(pp.customer_id) * 100) / count(c.customer_id), 2) as churn_rate 
from customer c  
left join previous_purchase_date pp on c.customer_id = pp.customer_id;

-- 9.	Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists.
-- percentage of total sales contributed by each genre in the USA 
with sales_genre_rank_usa as ( 
select g.name as genre, ar.name as artist,  sum(i.total) as genre_sales, 
dense_rank() over(partition by g.name order by sum(il.unit_price * il.quantity) desc) as genre_rank  
from genre g 
left join track t on g.genre_id = t.genre_id 
left join invoice_line il on t.track_id = il.track_id 
left join invoice i on il.invoice_id = i.invoice_id 
left join album a on t.album_id = a.album_id 
left join artist ar on a.artist_id = ar.artist_id 
where i.billing_country = 'USA' 
group by g.name, ar.name), 
total_sales_usa as (select sum(i.total) as total_sales 
from invoice_line il  
left join invoice i on il.invoice_id = i.invoice_id 
where i.billing_country = 'USA') 
select  s.genre, s.artist, s.genre_sales,t.total_sales, s.genre_rank, 
round((s.genre_sales / t.total_sales) * 100, 2) as percent_sales 
from sales_genre_rank_usa s  
join total_sales_usa t 
order by s.genre_sales desc, s.genre asc;

-- 10.	Find customers who have purchased tracks from at least 3 different genres
select concat(c.first_name, ' ', c.last_name) as customer, 
count(distinct g.genre_id) as genre_count 
from customer c 
left join invoice i on c.customer_id = i.customer_id 
left join invoice_line il on i.invoice_id = il.invoice_id 
left join track t on il.track_id = t.track_id 
left join genre g on t.genre_id = g.genre_id 
group by c.first_name, c.last_name 
having count(distinct g.genre_id) >= 3 
order by genre_count desc;

-- 11.	Rank genres based on their sales performance in the USA
with saleswise_genre_rank as (
select g.name as genre, 
sum(i.total) as total_sales, 
dense_rank() over (order by sum(i.total) desc) as genre_rank 
from genre g 
left join track t on g.genre_id = t.genre_id 
left join invoice_line il on t.track_id = il.track_id 
left join invoice i on il.invoice_id = i.invoice_id 
where i.billing_country = 'USA' 
group by g.name)
select genre, total_sales, genre_rank 
from saleswise_genre_rank 
order by genre_rank;

-- 12.	Identify customers who have not made a purchase in the last 3 months
with customer_last_purchase as (
select c.customer_id, c.first_name, c.last_name, 
max(date(i.invoice_date)) as last_purchase_date 
from customer c 
join invoice i on c.customer_id = i.customer_id 
group by c.customer_id, c.first_name, c.last_name), 
customer_purchases as (
select c.customer_id, c.first_name, c.last_name, 
date(i.invoice_date) as invoice_date 
from customer c 
join invoice i on c.customer_id = i.customer_id) 
select clp.customer_id, clp.first_name, clp.last_name, clp.last_purchase_date 
from customer_last_purchase clp 
left join customer_purchases cp on clp.customer_id = cp.customer_id 
and cp.invoice_date between clp.last_purchase_date - interval 3 month 
and clp.last_purchase_date - interval 1 day 
where cp.invoice_date is null 
order by clp.customer_id;


-- Subjective Questions 
-- 1.	Recommend the three albums from the new record label that should be prioritised for advertising and promotion in the USA based on genre sales analysis.
with recommended_albums as (
select al.title as album_name, a.name as artist_name, g.name as genre_name, 
sum(i.total) as total_sales, sum(il.quantity) as total_quantity, 
row_number() over(order by sum(i.total) desc) as sales_rank
from customer c 
join invoice i on c.customer_id = i.customer_id 
join invoice_line il on i.invoice_id = il.invoice_id 
join track t on il.track_id = t.track_id 
join album al on t.album_id = al.album_id 
join artist a on al.artist_id = a.artist_id 
join genre g on t.genre_id = g.genre_id 
where c.country = 'usa' 
group by al.title, a.name, g.name)
select * from recommended_albums 
order by total_sales desc;

-- 2.	Determine the top-selling genres in countries other than the USA and identify any commonalities or differences.
-- Other than USA
select g.name as genre, sum(il.unit_price * il.quantity) as total_sales
from invoice i
join customer c on i.customer_id = c.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
where c.country <> 'USA'
group by g.name
order by total_sales desc;
-- USA
select g.name as genre, sum(il.unit_price * il.quantity) as total_sales
from invoice i
join customer c on i.customer_id = c.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
where c.country = 'USA'
group by g.name
order by total_sales desc;

-- 3.	Customer Purchasing Behavior Analysis: How do the purchasing habits (frequency, basket size, spending amount) 
-- of long-term customers differ from those of new customers? What insights can these patterns provide about customer 
-- loyalty and retention strategies?
with cte as (select i.customer_id,
max(invoice_date) as max_invoice_date,
min(invoice_date) as min_invoice_date,
abs(timestampdiff(month,min(invoice_date),max(invoice_date))) as time_for_each_customer,
sum(total) as total_sales,
sum(quantity) as total_items,
count(invoice_date) as invoice_frequency
from invoice i
left join customer c on i.customer_id = c.customer_id
left join invoice_line il on i.invoice_id = il.invoice_id
group by i.customer_id
order by time_for_each_customer desc),
average_time as (
select avg(time_for_each_customer) as average_customer_lifetime from cte),
categorization as (
select cte.customer_id, cte.max_invoice_date, cte.min_invoice_date, cte.time_for_each_customer,cte.total_sales,
cte.total_items,cte.invoice_frequency,
case when cte.time_for_each_customer > (select average_customer_lifetime from average_time) then "long-term customer" 
else "short-term customer"end as customer_category
from cte)
select customer_category,sum(total_sales) as total_spending,
sum(total_items) as basket_size, count(invoice_frequency) as frequency
from categorization
group by customer_category;

-- 4.	Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased together by customers? 
-- How can this information guide product recommendations and cross-selling initiatives?
with product_affinity_analysis as (
select c.customer_id, c.first_name, c.last_name, 
a.name as artist_name, g.name as genre_name, 
sum(il.quantity) as total_quantity, 
sum(i.total) as total_sales
from invoice i 
left join invoice_line il on i.invoice_id = il.invoice_id 
left join track t on il.track_id = t.track_id 
left join album al on t.album_id = al.album_id 
left join artist a on al.artist_id = a.artist_id 
left join genre g on t.genre_id = g.genre_id 
left join customer c on i.customer_id = c.customer_id 
group by c.customer_id, c.first_name, c.last_name, a.name, g.name)
select * from product_affinity_analysis 
order by customer_id, total_quantity desc;

-- 5.	Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across different geographic 
-- regions or store locations? How might these correlate with local demographic or economic factors?
with previouscustomerpurchases as (
select c.country,
c.customer_id,c.first_name,c.last_name,date(i.invoice_date) as invoice_date,
lead(date(i.invoice_date)) over(partition by c.customer_id order by invoice_date desc) as prev_purchase
from customer c
join invoice i on c.customer_id = i.customer_id),
prevpurchaserank as (select *,
row_number() over(partition by customer_id order by prev_purchase desc) as prev_purchase_rn
from previouscustomerpurchases),
previouspurchasedate as (select *,
datediff(invoice_date,prev_purchase) as days_since_last_purchase
from prevpurchaserank
where prev_purchase_rn = 1
and datediff(invoice_date,prev_purchase) > 180
order by days_since_last_purchase desc)
select c.country, count(pp.customer_id) as churned_customers,
count(c.customer_id) as total_customers,
round((count(pp.customer_id) * 100) / count(c.customer_id), 2) as churn_rate
from customer c left join previouspurchasedate pp on c.customer_id = pp.customer_id
group by c.country;

-- 6.	Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), 
-- which customer segments are more likely to churn or pose a higher risk of reduced spending? What factors contribute to this risk?
with previouscustomerpurchases as (
select c.country,c.customer_id,c.first_name,c.last_name,date(i.invoice_date) as invoice_date,
lead(date(i.invoice_date)) over(partition by c.customer_id order by invoice_date desc) as prev_purchase
from customer c
join invoice i on c.customer_id = i.customer_id),
prevpurchaserank as (
select *,row_number() over(partition by customer_id order by prev_purchase desc) as prev_purchase_rn
from previouscustomerpurchases),
previouspurchasedate as (
select *,datediff(invoice_date,prev_purchase) as days_since_last_purchase
from prevpurchaserank
where prev_purchase_rn = 1
and datediff(invoice_date,prev_purchase) > 180
order by days_since_last_purchase desc)
select c.country,
count(pp.customer_id) as churned_customers,
count(c.customer_id) as total_customers,
round((count(pp.customer_id) * 100) / count(c.customer_id), 2) as churn_rate
from customer c left join previouspurchasedate pp on c.customer_id = pp.customer_id
group by c.country
order by churn_rate desc, total_customers asc;

-- 7.	Customer Lifetime Value Modeling: How can you leverage customer data (tenure, purchase history, engagement)
--  to predict the lifetime value of different customer segments? This could inform targeted marketing and 
--  loyalty program strategies. Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?
with customertenure as (
select c.customer_id, concat(c.first_name,' ', c.last_name) as customer,
min(i.invoice_date) as first_purchase_date,
max(i.invoice_date) as last_purchase_date,
datediff(max(i.invoice_date), min(i.invoice_date)) as tenure_days,
count(i.invoice_id) as purchase_frequency,
sum(i.total) as total_spent
from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id)
select customer_id,customer, tenure_days,purchase_frequency, total_spent,
round(total_spent / purchase_frequency, 2) as avg_order_value,
datediff(current_date, last_purchase_date) as days_since_last_purchase
from customertenure
order by days_since_last_purchase desc;



-- 10.	How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER 
-- to store the release year of each album?
alter table album 
add column ReleaseYear int(4);
select * from album;

-- 11.	Chinook is interested in understanding the purchasing behavior of customers based on 
-- their geographical location. They want to know the average total amount spent by customers 
-- from each country, along with the number of customers and the average number of tracks purchased per customer. 
-- Write an SQL query to provide this information.
select c.country,
round(avg(track_count)) as average_tracks_per_customer,
sum(i.total) as total_spent,
count(distinct c.customer_id) as no_of_customers,
round(sum(i.total)/ count(distinct c.customer_id),2) as avg_total_spent
from customer c
join invoice i on c.customer_id = i.customer_id
join ( select invoice_id, count(track_id) as track_count
from invoice_line
group by invoice_id) il on i.invoice_id = il.invoice_id
group by c.country
order by avg_total_spent desc,no_of_customers desc;



