Overview
This repository contains a comprehensive analysis of Key Performance Indicators (KPIs) for a payment method company. The aim is to evaluate the efficiency, effectiveness, and reliability of transactions processed by the company. By leveraging both Python and SQL, we offer a multi-dimensional view into various metrics that define payment success.

KPIs Analyzed

    Total Completed Payments: Sum of all successful transactions, broken down by customers and countries.
    Total Failed Payments: Sum of all failed transactions, again categorized by customers and countries.
    Completion Rate: Success rate of transactions for each customer and each country.
    Failure Rate: Rate of failed transactions for each customer and country.
    Transaction Comparison: Direct comparison between successful and failed transactions.
    Daily Transaction Trend: Analysis of transactions on a day-to-day basis.
    Weekly Transaction Trend: Analysis of transactions based on the days of the week.
    Transaction Speed: Time taken for a transaction to either complete or fail.
    Transaction Speed by Country: Speed metrics segmented by countries.

Files and Tools

    Python Analysis (Task_Pablo_Pavon_Kevin.py): Provides a deep-dive into the KPIs using Python libraries like Pandas and Matplotlib.
    SQL Preparation (sql_engine.py): Sets the stage for SQL-based KPI calculation.
    SQL Analysis (Kevin_task_Pablo_Pavon.sql): Executes SQL queries to compute the KPIs.
    Tableau Dashboard: A visual representation of the KPIs. Filters include Client Number, Country Code, Date, and Status Group.

Usage
To get the most out of this repository, begin by examining the SQL and Python scripts to understand the data preparation and analysis steps. Then, navigate to the Tableau Dashboard for a visual interpretation of the KPIs.

Prerequisites
Python 3.x
SQL Server
Tableau
How to Contribute
If you find any issues or have suggestions for additional KPIs, please feel free to open an issue or submit a pull request.
