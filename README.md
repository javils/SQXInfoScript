# What?
Is a simple script to get instrument configuration for StrategyQUant X.

# How to install?
To use this script open your MQL5 Data folder and paste the script on the Indicators folder. Then compile it with MetaEditor and when the compilation finished go to Metatrade 5 and launch the script into the chart that you want.

# What data give me the script?.
The script show you the following data:
    * Point value (USD)
    * Pip/Tick step
    * Pip/Tick size
    * Order size step
    * Several Spread info like average, percentiles, mode, etc. Adapted to the Pip/Tick size value.
    * Swap Long (USD)
    * Swap Short (USD)
    * Triple Swap day

# Observations
* The values are converted automatically to USD using the forex pair that you broker have.
* We can't take the comissions because MEtatrader 5 don't allow to get it programatically, at least in August 2024.
* It's only tested in Darwinex, could work in your broker but I don't test in others brokers. So if doesn't work, please contact me and we try to solve the problem :)

# Why?
Because I want to make a tool to configure an instrument in SQX easily and to learn how to configure this data. If you are learning maybe you want to use this program only to check that values you are using are corrects.

# Author
Javier Luque Sanabria