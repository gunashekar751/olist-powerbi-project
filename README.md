# Olist E-Commerce Analysis: Revenue, Delivery Performance and Customer Satisfaction

End-to-end analysis of about 100K Brazilian e-commerce orders (2016 to 2018). **MySQL** for loading and quality checks, **Power Query** for cleaning, and **Power BI** (data model and DAX) for an executive dashboard.

![Executive Summary Dashboard](screenshots/02_executive_summary.png)

## Contents

1. [Business problem](#business-problem)
2. [Headline findings](#headline-findings)
3. [KPIs](#kpis)
4. [Business questions answered](#business-questions-answered)
5. [Recommendations](#recommendations)
6. [Approach](#approach)
7. [Data model](#data-model)
8. [Data quality decisions](#data-quality-decisions)
9. [Limitations](#limitations)
10. [Repository structure](#repository-structure)

## Business problem

Olist's leadership wants to know which product categories and regions drive revenue, and where late deliveries are hurting customer satisfaction.

## Headline findings

- Revenue is about **R$13.6M** across about **99K orders**.
- **91.9%** of delivered orders arrive on time, but **7,826** arrive late.
- Late orders score **2.57 stars** against **4.29** for on-time orders, a gap of about **1.7 points**.
- Late orders take about **31 days** to arrive, against about **11 days** for on-time orders.
- Late deliveries are concentrated in the **northeast**: AL (23.9%), MA (19.7%), PI (16.0%), CE (15.3%) and SE (15.2%).

## KPIs

| KPI | Value | Definition |
|---|---|---|
| Total Revenue | R$13.59M | Sum of item prices |
| Total Orders | about 99K | Distinct orders with items |
| Delivered Orders | 96,470 | Orders with status On Time or Late |
| On-Time Delivery % | 91.9% | On-time orders / delivered orders |
| Late Orders | 7,826 | Delivered after the estimated delivery date |
| Late Order % | 8.1% | Late orders / delivered orders |
| Avg Delivery Days | 12.1 | Purchase to delivery, undelivered orders excluded |
| Avg Review Score | 4.09 | One review per order (latest kept) |

## Business questions answered

### 1. How has revenue trended over time?

Monthly revenue rose steadily through 2017, then levelled off at roughly **R$1M a month** through 2018. The trend chart covers Jan 2017 to Aug 2018.

### 2. Which categories drive the most revenue?

The top categories by revenue are **health_beauty, watches_gifts, bed_bath_table, sports_leisure, computers_accessories and furniture_decor**.

### 3. How much do late deliveries hurt review scores?

| Delivery status | Orders | Avg delivery days | Avg review score |
|---|---|---|---|
| On time | 88,162 | 10.8 | 4.29 |
| Late | 7,661 | 31.3 | 2.57 |

Late deliveries are about 8% of orders but score **1.7 points lower**. This is an association, not proof that lateness is the only cause. The numbers come from the MySQL query in `sql/01_analysis.sql`.

![SQL result: delivery vs review score](screenshots/01_delivery_vs_reviews.png)

### 4. Which regions have the worst delivery performance?

Late-delivery rates are highest in the northeast: **AL (23.9%), MA (19.7%), PI (16.0%), CE (15.3%), SE (15.2%) and BA (14.0%)**. States with fewer than 200 delivered orders are excluded, so small samples do not mislead.

### 5. How satisfied are customers overall?

The average review score is **4.09 out of 5**. About **58%** of reviews are 5 stars and about **11.5%** are 1 star, so the low scores are a small but visible group, and late delivery is a clear driver of them.

## Recommendations

1. **Fix the northeast first.** Review carrier and logistics performance in AL, MA, PI, CE and SE, where the late rate is roughly double the overall average.
2. **Set realistic delivery estimates** in high-delay regions, so customers are not promised dates the network cannot meet.
3. **Track late-delivery rate by state as a monthly KPI**, with an alert when it passes a target.
4. **Protect the top categories.** Health & beauty, watches and home goods drive the most revenue, so delivery problems there cost the most.

## Approach

1. **Load:** CSVs loaded into MySQL with `LOAD DATA`, with row counts verified for all 8 tables.
2. **Quality checks:** status mix, missing delivery dates, delivered-before-purchased dates, uncategorised products and duplicate reviews. See [data_quality_notes.md](data_quality_notes.md).
3. **Clean (Power Query):** blank categories set to "unknown", English category names merged in, reviews deduplicated to the latest per order, and Delivery Days and Delivery Status columns added.
4. **Model:** a Date table plus one-to-many, single-direction relationships.
5. **Measures (DAX):** revenue, orders, on-time %, late %, review score and time intelligence.
6. **Dashboard:** slicers (year, state, category), five KPI cards and five charts.

## Data model

![Data model](screenshots/03_data_model.png)

`orders` holds order-level facts (status, delivery dates) and `order_items` holds line-level revenue. `customers`, `products`, `sellers` and `Date` are dimensions.

## Data quality decisions

- 610 products have no category and are labelled "unknown".
- 547 orders have more than one review. The latest review is kept.
- 8 delivered orders have no delivery date and are excluded from delivery metrics.
- Delivery Days is left null for undelivered orders, so averages only use completed deliveries.
- The Delivered Orders measure uses `KEEPFILTERS`, so the donut splits On Time and Late correctly.
- 2016 and Sept 2018 are excluded from the trend because the dataset has very few orders in those months.

## Limitations

- Late delivery is associated with lower reviews, but other factors (product quality, seller issues) are not controlled for.
- The SQL analysis counts 7,661 late orders (only those with a review). The dashboard counts 7,826 (all delivered late orders).
- Values are in Brazilian reais (R$) and the data ends in 2018.

## Tools

MySQL, Power BI (Power Query, DAX), Git and GitHub

## Repository structure

```
olist-powerbi-project/
├── sql/                   table creation, loading, quality checks and analysis queries
├── powerbi/               dashboard file (olist_dashboard.pbix)
├── screenshots/           SQL result, dashboard and data model images
├── data_quality_notes.md  data checks and cleaning decisions
└── README.md
```

## How to reproduce

1. Download the *Brazilian E-Commerce Public Dataset by Olist* from Kaggle and place the CSVs in a local `data/` folder (not included in this repo).
2. Run the scripts in `sql/` in MySQL to create the `olist` database and load the tables.
3. Open `powerbi/olist_dashboard.pbix` in Power BI Desktop and point the MySQL data source at your local server (`127.0.0.1`, database `olist`).