# 📊 Procurement Performance Analysis  

This project analyzes the procurement process performance within **PT Infomedia Nusantara** by evaluating **SLA achievement** and **cost efficiency** using dummy data.  
The goal is to demonstrate data cleaning, transformation, and analysis workflows using **BigQuery** and **Power BI**.  

---

## 🎯 Objective  
To assess the effectiveness of procurement operations through:  
- SLA (Service Level Agreement) performance tracking  
- Cost efficiency and budget utilization analysis  
- Identification of top-performing PICs  

---

## 🧩 Data Overview  
- **Source:** Simulated dummy procurement data  
- **Dataset Size:** ±2,000 rows  
- **Tools Used:** Google BigQuery, Power BI, Google Sheets  

---

## ⚙️ ETL Workflow  
1. **Extract:** Import dummy procurement data from Google Sheets into BigQuery  
2. **Transform:** Clean nulls, convert data types, and calculate SLA & efficiency metrics  
3. **Load:** Store the cleaned dataset (`proc_dummy_clean`) in BigQuery  
4. **Visualize:** Connect Power BI to BigQuery for real-time dashboards  

---

## 📑 Query and Analysis  
All SQL queries used in this project are stored in the file:  
📄 [`proc_analysis.sql`](📊 queries/proc_analysis.sql)  

For detailed explanations of the queries, transformation logic, and analytical results, please refer to:  
📘 [`Procurement Performance Analysis.pdf`](📘 analysis-report/Procurement%20Performance%20Analysis.pdf)  

---

## 📊 Key Results  
- **SLA achievement rate:** 86.28% — most procurements completed on time  
- **Average SLA percentage:** 196.04% — procurements finished nearly twice as fast as target  
- **Overall efficiency:** 5.84% (≈ IDR 14.2B in savings)  
- **Top performers:** Nadia, Michael, and Sofia consistently achieved high SLA & efficiency results  

These findings indicate strong operational reliability and cost control across procurement activities.  

---

## 💡 Business Impact  
- High SLA and efficiency improve operational reliability and resource utilization.  
- Consistent top performers help maintain process excellence.  
- Continuous monitoring supports better decision-making and budget planning.  

---

## 📈 Dashboard Preview  
Visualized in **Power BI**, connected to **BigQuery** for real-time analytics.  
👉 [View full dashboard here](https://bit.ly/dashboard_proc_analysis)

| Dashboard Preview |  
|--------------------|  
| ![Procurement Dashboard](dashboard/Procurement%20Analysis2.png) |  

---

## 🧠 Key Learnings  
- Data cleaning and transformation are critical for accurate insights.  
- Combining SLA and efficiency metrics provides a holistic view of procurement performance.  
- Visualization tools like Power BI enhance storytelling and business decision-making.  

---

## 👩‍💻 Author  
**Hilda Hamdah Husniyyah**   
Data Analyst | Business Intelligence Enthusiast  
📧 hildahamdahusniyyah22@gmail.com • 🌐 https://www.linkedin.com/in/hilda-hamdah-h/ 

---

### 🪪 License  
This project is open for educational and portfolio purposes.  
Licensed under the **MIT License © 2025 Hilda Hamdah Husniyyah**
