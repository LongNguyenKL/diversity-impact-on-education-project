# The Impact of Racial Diversity on School Performance and Early Childhood Development: A Causal Inference Approach

## Overview
This project investigates the causal impact of racial diversity in schools on early academic performance and children's development. This topic holds significant societal relevance, especially given the ongoing public and political discourse surrounding Diversity, Equity, and Inclusion (DEI) initiatives in the United States. 

The study employs a causal inference approach, primarily utilizing a staggered Difference-in-Difference (DiD) analysis with Fixed Effects. The goal is to provide a comprehensive understanding for policymakers and educational institutions to inform more effective DEI strategies and foster environments where children can thrive. 

![DID](https://github.com/LongNguyenKL/diversity-impact-on-education-project/blob/main/assets/did.png)

## Documentation
* ProjectEdSurvey.R: the source code of the study, including all the processes and analysis.
* report_childk5p.edited.docx: the final report of the study.
* project_report.pptx: summarized report using PowerPoint slides.
* EdSurvey-ECLS.pds: detailed description of the longitudinal study by NCES.

## Dataset
The project leveraged data from the **Early Childhood Longitudinal Studies (ECLS) kindergarten cohort of 2010-11** collected by the US Department of Education and the National Center for Educational Statistics (NCES). 

The ECLS program provides extensive data on child development, school readiness, and early school experiences, including various factors like family, school, and community. Each child record contains assessment data, questionnaires, weights, imputation flags, and administrative variables. The raw dataset is expansive, containing 18,174 rows and 26,061 columns. 

## Key Features (Steps Conducted in the Project)
The project involved extensive data preparation and a robust analytical approach:

### 1. Data Preparation
* **Variable Selection:** Identified and extracted key variables related to student performance (IRT scores), school racial composition (`rceth`), and student/school identifiers from the large raw dataset. 
* **Dataset De-flattening:** Transformed the initial wide-format dataset (one row per child across all semesters) into a long, time-series format. This involved creating a new row for each child per semester, including relevant variables like `childid`, `sem` (semester number), `s_id`, `rceth`, individual subject IRT scores, and generated variables (`treated`, `treatment_sem`, `event_time`, `post`).  An `avg_irt` score was computed as the primary target variable. 

### 2. Descriptive Analysis
Initial descriptive statistics were generated for all variables. Trends in children's average IRT-based scores across subjects were explored over the semesters, showing a general improvement in cognitive skills over time. 

![irt](https://github.com/LongNguyenKL/diversity-impact-on-education-project/blob/main/assets/eda.png)

### 3. Difference-in-Differences (DiD) Analysis
* **Staggered DiD Implementation:** A staggered DiD model was employed to account for the variability in the timing of "treatment" (when a child first attended a diverse school) across different individuals. This allowed for a nuanced analysis of the causal effect over time using the `event_time` variable, which represents semesters relative to the treatment start. 
* **Fixed Effects Model:** A fixed effects regression model was utilized, controlling for time-invariant individual characteristics (e.g., natural abilities via `childid` fixed effects) and common time-specific effects (e.g., increasing curriculum difficulty via `sem` fixed effects). The `avg_irt` score was the dependent variable, with the interaction between `event_time` and `treated` representing the causal effect. Semester 1 (`event_time = -1`) was set as the consistent pre-treatment baseline.

![result](https://github.com/LongNguyenKL/diversity-impact-on-education-project/blob/main/assets/Screenshot%202025-05-07%20221133.png)

### 4. Robustness Checks
The critical **parallel trends assumption** for DiD analysis was examined. The analysis indicated that the parallel trends assumption was generally met, despite minor deviations. 

![trend](https://github.com/LongNguyenKL/diversity-impact-on-education-project/blob/main/assets/trend.png)

## Results
The study's findings indicate a **positive and gradual impact of attending a diverse school on children’s academic performance over the semesters.** 

* Specifically, one semester after the treatment, the difference in average IRT scores between the treatment and control groups was 0.067 higher than the pre-treatment difference. This difference gradually increased to 0.167 by `event_time` = 7, demonstrating a tangible, albeit not drastic, impact of diversity. 
* The fixed effects model exhibited a high Adjusted R-squared value of 0.9525, indicating that the model effectively explains 95.25% of the variance in IRT scores. 

## Lessons Learned

### Actionable Insights
The model demonstrates a generally positive and increasing effect of attending a diverse school at a younger age.  [cite_start]This growth pattern underscores the potential for significant long-term academic gains from racial diversity and inclusivity. Policymakers and school administrators are encouraged to implement and sustain DEI policies and programs. These initiatives can foster equitable environments, challenge biases, and facilitate learning from diverse perspectives. 

### Limitations & Future Research
* **Diversity Definition:** The study's primary measure of diversity, "percentage of non-white children," might not fully capture the complex dynamics of racial diversity if dominated by a single non-white group or if it doesn't account for social interactions within the school. Other variables (e.g., school resources, support systems) from the NCSE dataset might offer more accurately represent diversity, including gender and socioeconomic factors. 
* **Treatment Definition:** The "treatment" in this study was not based on the direct implementation of specific DEI initiatives, which makes a precise investigation of the treatment effect challenging.
* **Parallel Trends Assumption:** While visually checked, further statistical testing beyond visualization, such as a pre-treatment model, could provide even stronger assurance that the critical parallel trends assumption for DiD analysis is met.
