# Data Quality Notes

- Row counts verified for all 8 tables against source files.
- Reviews load raised a warning; verified score range (1-5), no missing
  dates, no orphan reviews. No impact on analysis.
- 97% of orders are delivered; the remainder (shipped, canceled,
  unavailable, invoiced, processing, created, approved) have no delivery date.
- 8 delivered orders have no delivery date: excluded from delivery analysis.
- 0 orders delivered before purchase date.
- 610 products have no category: labeled "Unknown" in Power Query.
- 547 orders have multiple reviews: deduplicated to latest review per order.
- Delivery vs review analysis covers 95,823 of 96,478 delivered orders;
  the rest have no review or no delivery date.
- 610 products had blank category; replaced with ‘unknown’ in Power Query (blanks were empty strings, not nulls).
- Delivery Days is null for ~3% of orders (not delivered, or delivered with
  missing date). Left as null on purpose so averages exclude them.
- Power BI counts 7,826 late orders (all delivered); the SQL analysis counted 7,661 that also had a review.