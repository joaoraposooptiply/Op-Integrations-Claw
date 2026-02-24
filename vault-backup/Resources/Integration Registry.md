---
tags: [registry, integrations, reference, critical]
updated: 2026-02-24
---

# Integration Registry — Complete

> All 25 integrations with tap/target/ETL/API/docs links.

## Legend
⚪ Not cataloged | 🔵 Researched | 🟡 In Progress | 🟢 Live | 🔴 Broken
★ = Uses new Generic ETL template

| # | Integration | Tap | Target | ETL | API | Confluence |
|---|-------------|-----|--------|-----|-----|------------|
| 1 | Amazon Seller | [tap-amazon-seller](https://github.com/hotgluexyz/tap-amazon-seller) | — | amazon/etl.ipynb | [SP-API](https://developer-docs.amazon.com/sp-api/) / [Swagger](https://spapi.cyou/swagger/index.html) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2717188110) |
| 2 | Amazon Vendor | [tap-amazon-vendor-central](https://gitlab.com/hotglue/tap-amazon-vendor-central) | — | amazon-vendor/etl.ipynb | — | — |
| 3 | BigCommerce | [tap-bigcommerce-v2](https://github.com/hotgluexyz/tap-bigcommerce-v2) | [target-bigcommerce](https://gitlab.com/hotglue/target-bigcommerce) | bigcommerce/etl.ipynb | — | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2315354128) |
| 4 | BigQuery | [tap-bigquery](https://github.com/hotgluexyz/tap-bigquery) | [target-bigquery](https://github.com/hotgluexyz/target-bigquery.git) | bigquery/etl.ipynb | — | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2526511105) |
| 5 | Bol.com | [tap-bol](https://gitlab.com/hotglue/tap-bol) | — | bol.com/etl.ipynb | [Retailer API](https://api.bol.com/retailer/public/Retailer-API/index.html) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2524643339) |
| 6 | EasyEcom | [tap-easyecom](https://github.com/hotgluexyz/tap-easyecom) | [target-easyecom](https://github.com/hotgluexyz/target-easyecom) | EasyEcom/etl.ipynb | [API Docs](https://api-docs.easyecom.io/) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2928476161) |
| 7 | Exact Online | [tap-exact](https://gitlab.com/hotglue/tap-exact) | [target-exact](https://github.com/hotgluexyz/target-exact) | exact/etl.ipynb | [REST API](https://start.exactonline.nl/docs/HlpRestAPIResources.aspx) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2391113740) |
| 8 | Lightspeed C | [tap-lightspeed](https://github.com/hotgluexyz/tap-lightspeed) | [target-lightspeed](https://github.com/hotgluexyz/target-lightspeed) | LightSpeed/etl.ipynb | [eCom API](https://developers.lightspeedhq.com/ecom/introduction/introduction/) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2777874433) |
| 9 | Lightspeed R | [tap-lightspeed-rseries](https://github.com/mariocostaoptiply/tap-lightspeed-rseries.git) | [target-lightspeed-r-series](https://gitlab.com/mariocosta_opt/target-lightspeed-r-series.git) | LightSpeed_r_series/etl.ipynb | [Retail API](https://developers.lightspeedhq.com/retail/introduction/introduction/) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3422748673) |
| 10 | Logic4 | [tap-logic4](https://github.com/hotgluexyz/tap-logic4) | [target-logic4](https://github.com/hotgluexyz/target-logic4) | logic4/etl.ipynb | [Swagger](https://api.logic4server.nl/swagger/index.html) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2745597953) |
| 11 | Magento | [tap-magento](https://github.com/hotgluexyz/tap-magento) | [target-magento](https://gitlab.com/hotglue/target-magento) | magento/etl.ipynb | — | [Warehouse](https://optiply.atlassian.net/wiki/spaces/IN/pages/2443083785) / [Non-Warehouse](https://optiply.atlassian.net/wiki/spaces/IN/pages/2344845313) |
| 12 | Montapacking | [tap-montapacking](https://gitlab.com/hotglue/tap-montapacking) | [target-montapacking-v2](https://github.com/hotgluexyz/target-montapacking-v2) | montapacking/etl.ipynb | [API v6](https://api-v6.monta.nl/index.html) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2301886535) |
| 13 | MSSQL | [tap-mssql](https://github.com/hotgluexyz/tap-mssql) | [target-mssql](https://github.com/hotgluexyz/target-mssql) | mssql/etl.ipynb | — | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3223355393) |
| 14 | NetSuite | [tap-netsuite-rest](https://github.com/hotgluexyz/tap-netsuite-rest.git) | [target-netsuite-v2](https://github.com/hotgluexyz/target-netsuite-v2) | netsuite/etl.ipynb | [REST API](https://system.netsuite.com/help/helpcenter/en_US/APIs/REST_API_Browser/record/v1/2023.1/index.html) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3100180481) |
| 15 | Odoo | [tap-odoo](https://gitlab.com/hotglue/tap-odoo) | [target-odoo-v3](https://github.com/hotgluexyz/target-odoo-v3) | Odoo/etl.ipynb | XML-RPC (problematic) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2433482756) |
| 16 | QLS | [tap-qls](https://gitlab.com/hotglue/tap-qls) | [target-qlsv2](https://github.com/hotgluexyz/target-qlsv2) | qls/etl.ipynb | [Swagger](https://api.pakketdienstqls.nl/swagger/) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2301853930) |
| 17 | ★ Sherpaan | [tap-sherpaan](https://github.com/Optiply/tap-sherpaan.git) | [target-sherpaan](https://github.com/joaoraposooptiply/target-sherpaan.git) | sherpaan/etl.ipynb | [SOAP/asmx](https://sherpaservices-prd.sherpacloud.eu/406/Sherpa.asmx) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3170369561) |
| 18 | Shopify | [tap-shopify](https://github.com/hotgluexyz/tap-shopify.git) | [target-shopify-v2](https://gitlab.com/joaoraposo/target-shopify-v2.git) | shopify/etl.ipynb | — | — |
| 19 | Tilroy | [tap-tilroy](https://github.com/joaoraposooptiply/tap-tilroy.git) | [target-tilroy](https://github.com/joaoraposooptiply/target-tilroy.git) ⚠️ untested | tilroy/etl.ipynb | [API Overview](https://tilroy-dev.atlassian.net/wiki/spaces/TAD/pages/870481921) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3218735105) |
| 20 | Vendit | [tap-vendit](https://github.com/joaoraposooptiply/tap-vendit.git) | [target-vendit](https://github.com/joaoraposooptiply/target-vendit.git) | vendit/etl.ipynb | [Swagger](https://api.staging.vendit.online/VenditPublicApiSpec/index.html) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3170369648) |
| 21 | WooCommerce | [tap-woocommerce](https://github.com/hotgluexyz/tap-woocommerce) | [target-woocommerce-v2](https://github.com/hotgluexyz/target-woocommerce-v2) | woocommerce/etl.ipynb | [REST API](https://woocommerce.com/document/woocommerce-rest-api/) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2301853870) |
| 22 | Zoho Books | [tap-zoho](https://gitlab.com/hotglue/tap-zoho) | [target-zohobooks-v2](https://gitlab.com/hotglue/target-zohobooks-v2) | zohobooks/etl.ipynb | [API v3](https://www.zoho.com/books/api/v3/introduction/) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2299428865) |
| 23 | Zoho Inventory | [tap-zoho-inventory](https://github.com/hotgluexyz/tap-zoho-inventory) | [target-zoho-inventory](https://github.com/hotgluexyz/target-zoho-inventory) | zoho-inventory/ | [API v1](https://www.zoho.com/inventory/api/v1/introduction/) | [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2412380174) |

## Notes
- **Sherpaan** ★ = Most recent, best ETL using new Generic template patterns
- **Tilroy** target is NOT tested/done
- **Amazon Seller/Vendor** have no targets (sell-order-only integrations?)
- **Bol.com** has no target
- **Odoo** uses XML-RPC — "awful for debugging data", mostly full syncs
- **Taps split across GitHub (hotgluexyz) and GitLab (hotglue)**
- Some taps/targets are on personal repos (joaoraposooptiply, mariocostaoptiply)

## Repo Locations
- **ETLs:** `/Users/jay/Documents/Optiply/optiply-scripts/import/{integration}/etl.ipynb`
- **Generic Template:** `/Users/jay/Documents/Optiply/optiply-scripts/import/Generic/etl.ipynb`
- **Utils:** `/Users/jay/Documents/Optiply/optiply-scripts/import/Generic/utils/`

## Related
- [[Cloud System Schema]] — standard schema for BigQuery/AWS/Azure customers
- [[Snapshot Queries]] — SQL queries for HotGlue snapshot construction
