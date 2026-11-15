# requirement

1, a seperate interface for vendors to onboard new products, including
- product photo
- product title
- product description
- product logo if applicable
- product sku
- onboard quantity
- preferred delivery mode

all information required in batch import XLSX should be provided （refer to # product related info section)

2, the information exported to two seperate xlsx files, for eBest team to do batch upload daily or on demand.

3, for eBest deliver products, vendor to organize delivery to eBest warehouse, and update onbaord status

4, weekly reconsolication on product data betwween vendor onboarding system and eBest OMS database

5, overall workflow

vendor input information -> data export to eBest operator -> eBest operator batch import to inventory
-> product should be visible from eBest app with 0 inventory -> vendor to confirm all details look fine in app
-> vendor to update inventory and ready to sale date -> data sync to eBest system
-> customer order online -> 1) for vendor delivery product, seperate order sent to vendor for delivery; eBest deliver the rest as normal process; 2) for eBest delivery product, eBest deliver as normal productss; 3) for just in time delivery, vendor to receive cutoff order list by 11:30PM and vendor to deliver to eBest warehouse before 8am next day
-> if any product not delviered or returned, inventory inforamtion updated in eBest system, and back to vendor system
-> eBest charge vendor based on sales data (to cover cost of platform, warehouse and delivery)
-> vendor to update inventory if low in stock or if needed as business nature -> data sync to eBest system
-> for any change in product inforamtion, daily export to eBest operator for batch update

# product related info

1, sample images

https://cdn.minimall.donkibuy.com/images/7313b3fc-b407-410c-8007-8076ca8dfa79-ws16qvg9p.jpg

2, different image entries required during onboarding, showing in onboard_images.jpg

3, batch import XLSX files, refer to two xls/xlsx files in onboaridng folder

4, OMS DB schemas: OMS_schema.sql

5, two sample datas: samples - products table.csv and stock_sample.csv

# delivery

1, two diferent delivery mode

- vendor delivery, in the case, same order needs to be split into two different dispatch
- vendor sends the products to eBest warehouse, and eBest deliver
- vendor does not stock product in eBest warehouse, for any order, vendor to deliver to eBest warehouse on next day by 8am with customer and label sorted

2, proposed product status
- vendor onboarded
- in warehouse (either vendor's own warehouse or eBest)
- ready for sale (product visible in eBest app)

# dependency
1, eBest interfaces for product onboarding
2, eBest interfaces to retrieve product inventory and sales volume
3, eBest interfaces to update product inventory

# issues

1, if same SKU from different vendors, and also eBest own sourcing
- how to display in App (same product, differnet entries and pricing)

2, if same SKU from different vendors, and also eBest own sourcing
- how to handle warehouse
  - is seperate zone required
  - same SKU might have different packaging and expiry date from different sourcing
  - in delivery, warehouse need to differetiate order between different vendors and dispatch right product from right vendor to end customer