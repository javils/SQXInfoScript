# What?
Is a simple script to get instrument configuration for StrategyQUant X. It gaves the possibility to create and ".xml" file to import directly into Instrument tab in StrategyQuant DataManager section.

# How to install?
We have 2 options:
1. Download the latest ".ex5" file from the Release link (https://github.com/javils/SQXInfoScript/releases) and launch into the chart.
2. To compile the script open your MQL5 Data folder and paste the script on the Indicators folder. Then compile it with MetaEditor and when the compilation finished go to Metatrader 5 and launch the script into the chart that you want.
To be able **to get the Darwinex Commissions you need to add "https://www.darwinex.com" url into Tools > Options > Experts Advisors > Allow WebRequest for listed URL** menu and mark it as enabled.

# What data give me the script?.
The script show you the following data:
* Point value (USD)
* Pip/Tick step
* Pip/Tick size
* Order size step
* Several Spread info like average, percentiles, mode, etc. Adapted to the Pip/Tick size value.
* Commissions from **Darwinex** prepared to set as Size Based (USD) or Percentage Based. **(If is well configured and added "https://www.darwinex.com" as I write in the How to install section)**
* Swap Long (USD)
* Swap Short (USD)
* Triple Swap day

# Observations
* The values are converted automatically to USD using the forex pair that you broker have.
* To take the commissions info I'm using Darwinex API because MT5 doesn't allow get comissions in 10/08/2024.
* It's only tested in Darwinex, could work in your broker but I don't test in others brokers. So if doesn't work, please contact me and we try to solve the problem :)

# Why?
Because I want to make a tool to configure an instrument in SQX easily and to learn how to configure this data. If you are learning maybe you want to use this program only to check that values you are using are corrects.

# Author
Javier Luque Sanabria