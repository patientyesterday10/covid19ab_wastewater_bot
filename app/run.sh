#!/bin/sh

# Run R-script to generate plots
echo "Running R-script to generate plots..."
/usr/bin/Rscript /app/covid_plots.R

# List /tmp directory for reference:
echo "Listing /tmp directory..."
ls -l /tmp

# Run python script to post to Mastodon
echo "Running python script to post to Mastodon..."
python /app/bot.py