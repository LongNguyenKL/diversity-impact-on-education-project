# Project EdSurvey
# Download the EdSurvey package and dataset if this is your first time running code
# install.packages('EdSurvey') 
library(EdSurvey)
# downloadECLS_K(years=2011, root = "C:/", cache=FALSE)
eclsk11 = readECLS_K2011('C:/ECLS_K/2011')
dim(eclsk11)

# PART 1: DATA PREPERATION
# Use the grepl() function to research and find important columns
# cols = colnames(eclsk11)
# matches = grepl('', cols)
# cols[matches]

# racept = grepl('asiapt|hisppt|whitept|blacpt|hawppt|multpt', cols)
# cols[racept]

# Prepare the data with needed columns
cols = colnames(eclsk11)

# Find the columns that represent children Reading/Math/Science performance
score_cols = grepl('rthet|mthet|sthet', cols) 
score_vars = cols[score_cols]

# Create the data table
variables = c('childid',
              's1_id', 's2_id', 's3_id', 's4_id', 's5_id', 's6_id', 's7_id', 's8_id', 's9_id',
              'x2krceth', 'x4rceth', 'x6rceth', 'x7rceth_r', 'x8rceth', 'x9rceth',
              score_vars,
              'x_chsex_r', 'x_hisp_r', 'x_white_r', 'x_black_r', 'x_asian_r', 'x_aminan_r', 'x_multr_r')
k11data = getData(data=eclsk11,
               varnames=variables,
               dropOmittedLevels=TRUE, addAttributes=TRUE)

# PART 2: DATA PREPROCESSING
# Reformat the values of x2krceth and x4rceth
k11data$x2krceth = as.numeric(cut(
  k11data$x2krceth,
  breaks=c(0, 25, 50, 75, 101),
  labels=c(1, 2, 3, 4),
  right=FALSE
))
k11data$x4rceth = as.numeric(cut(
  k11data$x4rceth,
  breaks=c(0, 25, 50, 75, 101),
  labels=c(1, 2, 3, 4),
  right=FALSE
))

# Remove the texts from x6rceth to x9rceth for visual clarity
k11data$x6rceth = as.numeric(gsub(':.*', '', k11data$x6rceth))
k11data$x7rceth_r = as.numeric(gsub(':.*', '', k11data$x7rceth_r))
k11data$x8rceth = as.numeric(gsub(':.*', '', k11data$x8rceth))
k11data$x9rceth = as.numeric(gsub(':.*', '', k11data$x9rceth))

# Add x1rceth, x3rceth, and x5rceth based on s3_id and s5_id
for (i in 1:nrow(k11data)) {
  # x1rceth is always 1
  k11data$x1rceth[i] = 1
  # x3rceth using s3_id
  if (k11data$s3_id[i] == k11data$s2_id[i]) {
    k11data$x3rceth[i] = k11data$x2krceth[i]
  } else if (k11data$s3_id[i] == k11data$s4_id[i]) {
    k11data$x3rceth[i] = k11data$x4rceth[i]
  } else {
    k11data$x3rceth[i] = round(mean(k11data$x2krceth[i], k11data$x4rceth[i]), 0)
  }
  # x5rceth using s5_id
  if (k11data$s5_id[i] == k11data$s4_id[i]) {
    k11data$x5rceth[i] = k11data$x4rceth[i]
  } else if (k11data$s5_id[i] == k11data$s6_id[i]) {
    k11data$x5rceth[i] = k11data$x6rceth[i]
  } else {
    k11data$x5rceth[i] = round(mean(k11data$x4rceth[i], k11data$x6rceth[i]), 0)
  }
}

# Add x1sthetk5 as the data is missing
# Assuming the growth from semester 1 to 2 = from semester 2 to 3
for (i in 1:nrow(k11data)) {
  k11data$x1sthetk5[i] = k11data$x2sthetk5[i] - (k11data$x3sthetk5[i] - k11data$x2sthetk5[i])
}

# Identify the treated group
# Children who spent over 4 semesters at highly diverse schools
k11data$treated = as.numeric(rowSums(
  k11data[, c('x2krceth', 'x3rceth', 'x4rceth', 'x5rceth', 'x6rceth',
              'x7rceth_r', 'x8rceth', 'x9rceth')] > 1) > 4)
table(k11data$treated)

# Find the treatment_date as the first period they attended the diverse school
rcols = c('x1rceth', 'x2krceth', 'x3rceth', 'x4rceth', 'x5rceth', 'x6rceth',
          'x7rceth_r', 'x8rceth', 'x9rceth')

k11data$treatment_sem = NA
for (i in 1:nrow(k11data)) {
  # Skip the control group
  if (k11data$treated[i] == 0) {
    next
  }
  # For the treated group
  for (j in seq_along(rcols)) {
    if (k11data[i, rcols[j]] >= 2) {
      k11data$treatment_sem[i] = j
      break
    }
  }
}

table(k11data$treatment_sem)

# Reformat the dataframe into time-series data
k11data_main = data.frame(
  sem=integer(),
  childid=integer(),
  s_id=integer(),
  rceth=numeric(),
  r_irt=numeric(),
  m_irt=numeric(),
  s_irt=numeric(),
  treated=logical(),
  treatment_sem=integer()
)

# Prepare the columns for my loop function
# We already have the race columns (rcols) listed
scols = c('s1_id', 's2_id', 's3_id', 's4_id', 's5_id', 's6_id', 's7_id',
          's8_id', 's9_id')
rthet_cols = c('x1rthetk5', 'x2rthetk5', 'x3rthetk5', 'x4rthetk5', 'x5rthetk5',
               'x6rthetk5', 'x7rthetk5', 'x8rthetk5', 'x9rthetk5')
mthet_cols = c('x1mthetk5', 'x2mthetk5', 'x3mthetk5', 'x4mthetk5', 'x5mthetk5',
               'x6mthetk5', 'x7mthetk5', 'x8mthetk5', 'x9mthetk5')
sthet_cols = c('x1sthetk5', 'x2sthetk5', 'x3sthetk5', 'x4sthetk5', 'x5sthetk5',
               'x6sthetk5', 'x7sthetk5', 'x8sthetk5', 'x9sthetk5')

# The main data frame that we will be working with
for (i in 1:9) {
  semxdata = data.frame(
    sem=i,
    childid=k11data$childid,
    s_id=k11data[[scols[i]]],
    rceth=k11data[[rcols[i]]],
    r_irt=k11data[[rthet_cols[i]]],
    m_irt=k11data[[mthet_cols[i]]],
    s_irt=k11data[[sthet_cols[i]]],
    treated=k11data$treated,
    treatment_sem=k11data$treatment_sem
    )
  k11data_main = rbind(k11data_main, semxdata)
}

# Add the post and event_time variable to support DiD analysis
for (i in 1:nrow(k11data_main)){
  # Calculate the average IRT-based score. This is our DEPENDENT VARIABLE
  k11data_main$avg_irt[i] = mean(c(k11data_main$r_irt[i], 
                                k11data_main$s_irt[i], 
                                k11data_main$m_irt[i]))
  # Add the event_time variable for staggered DID
  if (k11data_main$treated[i] == 0) {
    k11data_main$event_time[i] = 0
  }
  else{
    k11data_main$event_time[i] = k11data_main$sem[i] - k11data_main$treatment_sem[i]
  }
}

#rm(k11data_main)

# PART 3: DESCRIPTIVE ANALYSIS
library(ggplot2)
library(dplyr)
library(tidyr)

summary(k11data_main)

# Control vs Treatment count
ggplot(k11data_main,
       aes(x = treated,
           fill = factor(treated))) +
  scale_x_discrete(labels = c('Control', 'Treatment')) +
  scale_fill_manual(values = c('lightgrey', 'lightblue'),
                               labels = c('Control', 'Treatment'),
                               name = 'Group') + 
  geom_bar() +
  labs(title = 'Treament vs Control Group Count',
       x = 'Group',
       y = 'Frequency') +
  theme_bw()

# Explore children performance throughout the semesters
irt_trends = k11data_main %>%
  group_by(sem) %>%
  summarise(sem_avg_irt = mean(avg_irt),
            sem_rirt = mean(r_irt),
            sem_mirt = mean(m_irt),
            sem_sirt = mean(s_irt))
irt_trends = irt_trends %>%
  pivot_longer(cols = starts_with('sem_'),
               names_to = 'irt_type',
               values_to = 'average_irt')
# Plot the trend
ggplot(irt_trends,
       aes(x = sem,
           y = average_irt, 
           color = irt_type,
           group = irt_type)) +
  geom_line(linewidth = 1) + 
  labs(title = 'Children Average Performance Recorded over the Semesters',
       color = 'Score Type',
       x = 'Semester',
       y = 'IRT Score') + 
  scale_x_continuous(breaks = 1:9, labels = 1:9) +
  scale_color_discrete(labels = c('Average', 'Math', 'Reading', 'Science'))
  theme_bw()

# PART 4: DID ANALYSIS
# install.packages('fixest')
library(fixest)

did_fe = feols(avg_irt ~ i(event_time, treated, ref = -1) | childid + sem,
               data = k11data_main)
summary(did_fe)

# Testing the parallel trend assumption
# Add a post variable
k11data_main$post = 0
for (i in 1:nrow(k11data_main)){
  if (k11data_main$treated[i] == 1 && k11data_main$event_time[i] >= 0){
    k11data_main$post[i] = 1
  }
}

# Address the parallel trend assumption
# Filter data for pre-treatment period (where post equals 0)
pre_treatment_data = k11data_main[k11data_main$treated == 0 | k11data_main$event_time <= 0, ]

# Calculate the average avg_irt by semester and treatment_sem
pre_treatment_trends = pre_treatment_data %>%
  group_by(sem, treatment_sem, treated) %>%
  summarise(mean_avg_irt = mean(avg_irt))

# Create the line chart
ggplot(pre_treatment_trends,
       aes(x = sem,
           y = mean_avg_irt,
           color = treatment_sem,
           group = treatment_sem)) +
  geom_line(linewidth = 1) +
  labs(title = 'Pre-Treatment IRT Trends by Semester and Treatment Timing',
       color = 'Treatment Semester',
       x = 'Semester',
       y = 'Average IRT') +
  scale_x_continuous(breaks = 1:9, labels = 1:9) +
  theme_bw()

# Plot the trends
all_trends = k11data_main %>%
  group_by(sem, treatment_sem, treated) %>%
  summarise(mean_avg_irt = mean(avg_irt))

# Create the line chart
ggplot(all_trends,
       aes(x = sem,
           y = mean_avg_irt,
           color = treatment_sem,
           group = treatment_sem)) +
  geom_line(linewidth = 1) +
  labs(title = 'Overall IRT Trends by Semester and Treatment Timing',
       color = 'Treatment Semester',
       x = 'Semester',
       y = 'Average IRT') +
  scale_x_continuous(breaks = 1:9, labels = 1:9) +
  theme_bw()
