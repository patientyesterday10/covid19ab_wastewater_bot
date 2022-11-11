#!/bin/bash

# Run R-script to generate plots
Rscript /app/covid_plots.R && \
# Run python script to post to Mastodon
python /app/bot.py