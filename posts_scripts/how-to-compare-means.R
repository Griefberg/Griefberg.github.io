library(data.table)
dt <- fread('https://raw.githubusercontent.com/vincentarelbundock/Rdatasets/master/csv/Ecdat/Wages1.csv')
head(dt)
dt <- dt[, .(sex, wage)]
means <- dt[, .(avg_wage=mean(wage, na.rm=TRUE)), by='sex']
n <- table(dt$sex) # sample size
stds <- dt[, .(std_wage=sd(wage, na.rm=TRUE)), by='sex'] # standard deviation

# confidence interval
female_low <- means[sex == 'female']$avg_wage + qt(0.025, n['female']) * (stds[sex == 'female']$std_wage / sqrt(n['female']))
female_high <- means[sex == 'female']$avg_wage + qt(0.975, n['female']) * (stds[sex == 'female']$std_wage / sqrt(n['female']))
male_low <- means[sex == 'male']$avg_wage + qt(0.025, n['male']) * (stds[sex == 'male']$std_wage / sqrt(n['male']))
male_high <- means[sex == 'male']$avg_wage + qt(0.975, n['male']) * (stds[sex == 'male']$std_wage / sqrt(n['male']))