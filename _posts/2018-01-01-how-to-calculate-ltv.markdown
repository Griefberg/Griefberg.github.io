---
title: "Understanding Customer Lifetime Value (LTV)"
layout: post
date: 2017-10-29 17:45
image: /assets/images/markdown.jpg
headerImage: false
tag:
- marketing analytics
- ltv
category: blog
author: Griefberg
externalLink: false
hidden: true
description: Different methods of calculating LTV
# jemoji: '<img class="emoji" title=":ramen:" alt=":ramen:" src="https://assets.github.com/images/icons/emoji/unicode/1f35c.png" height="20" width="20" align="absmiddle">'
---

There are plenty of articles about LTV calculations: it seems that every marketing company has written about it in their PR blogs. Despite this fact, it wasn't easy for me to find something that combines both theory and practice. That's why after reading 10+ articles about LTV I decided to try to aggregate all acquired knowledge in this paper.

# What is LTV?
The easiest way to understand this concept in theory is to look at customer cohorts. Cohorts term came to marketing from demography and generally means people who made some action during some time period (for example, people who married in 2015). When you compare cohorts, you could get some insights about the changes in people's behaviour. Now imagine that you have a food delivery business. In this case we could define a cohort like all customers who made their first order during, for example, a month. So, there are cohorts of June 2017, July 2017, etc.  Now if you want to get cohorts lifetime value you need to sum all expected returns from them:

\begin{equation}
    \text{Cohort LTV} = \text{Cohort Gross Margin in Month 0} + ... + \text{Cohort Gross Margin in Month N + ...}
\end{equation}

Sure, you could sum just revenue flows, but it's more appropriate to use Gross Margin:  

\begin{equation}
    \text{ Gross Margin = Revenue } * \text { Gross Margin % = Revenue } * \frac{\text{Revenue - COGS}}{\text{Revenue}}
\end{equation}

You could see the formula for Gross Margin above, but what's COGS? This is a cost of goods sold. If you don't know how to calculate it in case of your company, just ask guys from your financial department. Regarding the example of food delivery service, your Gross Margin could be just the sum of the commission your company gets from every order.

If you look at Cohorts LTV formula above, the whole point is that we couldn't get accurate LTV but only try to predict it varying our aggregation assumptions. We could simplify it (and loose some accuracy, of course) in the following way:

\begin{equation}
    \text{ Cohort LTV = Cohort Size } * \text{R}_0 * \text{AGMPU}_0 +  \text{Cohort Size} * \text{R}_1 * \text{AGMPU}_1  +  \text{ ...} \\\
    \text{where} \\\
    \text{Cohort Size – initial cohort size (e.g. 100 people who made their first order in some month, constant) } \\\
    \text{R}_n \text{ – cohort retention rate in month n (e.g 100 % in the 0th month, 35 % in the 1st month, etc.) } \\\
    \text{ AGMPU}_n \text{ – average gross margin per user in month n (e.g. 5 bucks in the 0th month, 11 bucks in 1st month, etc.) }
\end{equation}

Sometimes people discount it by rate to get the present value of future money (yes, 100 dollars next year ≠ 100 dollars today):

\begin{equation}
    \text{ Cohort LTV = Cohort Size } * \text{R}_0 * \text{AGMPU}_0  +  \text{Cohort Size} * \text{R}_1 * \frac{\text{AGMPU}_1}{\text{ (1 + d)}}  +  \text{ ...}  \\\
    \text{where} \\\
    \text{d - discount rate, i.e. the interest rate you can get if you put your money in the bank } \\\ 
    \text{ (by the way, of course, we don't discount cash flow of 0th month) } 
\end{equation}

The final step is just to get rid of this cohort terminology and talk about one customer. Just remove Cohort Size from the formula and we get the formula of Customer Lifetime Value:

\begin{equation}
    \text{ Customer LTV = } \text{R}_0 * \text{AGMPU}_0  + \text{R}_1 * \frac{\text{AGMPU}_1}{\text{ (1 + d)}^1} + \text{ ...} + 
        \text{R}_n * \frac{\text{AGMPU}_n}{\text{ (1 + d)}^n}  + \text{ ... } \qquad  \text{ (1) }
\end{equation}

Understanding $$R_0, R_1$$ is not pretty straightforward without cohorts' context, but just think about it as some kind of probability that a user will bring money in nth period of their customer life cycle.

So, cool! We got it! Let's move to a more practical side. Technically I see two ways of calculating LTV in practice depending of the accuracy we want to achieve and the data we have:  
1. **Simple and less accurate way (more aggregations)**: assume that R and AGMPU are **constant** over customer lifetime
2. **More complicated and a bit more accurate way (less aggregations)**: assume that R and AGMPU are **not constant** over customer lifetime

## Simple and less accurate way (more aggregations)
Okay, let's make the following assumptions:
- **AGMPU** is a constant: every month a customer brings us the same amount of money (we can calculate it on historical data or just assume some amount)
- **R** is a constant: each month R % of the last month customers continue using a service or simply saying each month the constant percent (1 - R) of customers churn (we can calculate it on historical data or assume)  

Assuming this, we get the following:

\begin{equation}
    \text{ Customer LTV = } \text{AGMPU} + \text{R}^1 * \frac{\text{AGMPU}}{\text{(1 + d)}^1} + \text{ ...} + \text{R}^n * \frac{\text{AGMPU}}{\text{ (1 + d)}^n}  + 
            \text{ ... = } \sum_{i=0}^∞ \text{R}^i * \frac{\text{AGMPU}}{\text{ (1 + d)}^i} \qquad  \text{ (2) }
\end{equation}

It means:
- In month 0 a customer brings us just AGMPU 
- In month 1 a customer brings us discounted AGMPU with a probabiliy R
- In month 2 a customer brings us two times discounted AGMPU with a probabiliy R $$*$$ R (e.g. it was 95 % retained users in the month 1, then in month it will be 90.25 % of them)
- In month 3 ...  

Now look at the final formula (2) again. Wait, wait, wait. Something very familiar... Damn, this is [geometric series](https://en.wikipedia.org/wiki/Geometric_series)! Common ratio is $$ \frac{\text{R}}{\text{ (1 + d)}} $$, while AGMPU is the first term of the series. It means that we can use the following formula to calculate the total sum of (3):

\begin{equation}
    \text{ Customer LTV = } \frac{\text{AGMPU}}{1 -\frac{\text{R}}{\text{(1 + d)}}} \text{ = }  \frac{\text{AGMPU} * \text{(1+d)}}{\text{(1 + d} - \text{R})}  \qquad  \text{ (3) }
\end{equation}


If we didn't discount, we would get the following very common formula: 

\begin{equation}
    \text{ Customer LTV = } \frac{AGMPU}{1-R} = \frac{AGMPU}{\text{churn rate}}
\end{equation}

Manipulations above could be also explained using [exponential decay constant](https://en.wikipedia.org/wiki/Exponential_decay), but, as for me, geometric series is the clearest way. However, if you start reading some articles about LTV, you could find that some authors just mention it without any explanation.

Other useful recommendations regarding this approach (3):
- [Some people](http://tomtunguz.com/churn-fallacies/) also multiply the calculated LTV by a factor (ex. 0.75), because a churn rate could be higher in reality.
- If you try to calculate LTV for SaaS, then look [here](http://www.forentrepreneurs.com/ltv/). The logic is the same, you just need to make more assumptions.
- Use the above approach (3) if you have a lack of time or data. 

## More complicated and a bit more accurate way (less aggregations)
The point of more complicated approach is just to take the formula (1) as it is. Don't assume that a retention rate and AGMPU are constants. The algorithm will be the followoing:
1. Calculate historical retention rates and AGMPU for cohorts (of course, if you have historical data, otherwise, use the first approach above).
2. Calculate average historical retention rates and AGMPU weighted on cohorts' sizes. 
3. Fit statistical models for retention rates and AGMPU versus cohorts lifespan. 
4. Predict retention rates and AGMPU for the future using created models  (ideally, you will find such an exponential function for a retention rate that it will go to zero after some lifetime).
5. Calculate LTV using the formula (1)

Yes, it sounds a bit complicated, but really it's not. I will try to explain this approach more precisely in my next post. Tschüss!
