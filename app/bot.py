from datetime import datetime

from mastodon import Mastodon
import os
import logging

if __name__ == "__main__":

    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)


    logger.info("Starting bot at {}".format(os.environ.get('MASTODON_API_BASE_URL')))

    mdon = Mastodon(
        access_token=os.environ['MASTODON_ACCESS_TOKEN'],
        api_base_url=os.environ['MASTODON_API_BASE_URL'],
    )

    # Upload media files:
    logger.info("Uploading Media Files.")
    media_ids = []

    media_ids.append(
        mdon.media_post("/tmp/output/ab_wastewater.png",
                        mime_type="image/png",
                        file_name="ab_wastewater.png",
                        description="Alberta COVID19 Wastewater Trends",
                        )
    )

    logger.info("Posting Status to Mastodon.")

    today = datetime.now().strftime("%Y-%m-%d")
    status_covid = f"COVID19 Wastewater Update for {today}:\n\nFigures show the level of SARS-COV-2 RNA detected in wastewater sampling across Alberta.\n\n#Covid19AB #Alberta #Wastewater #COVID19 #SARSCoV2\nData Source: https://covid-tracker.chi-csm.ca/"

    # Check if length exceeds 500 characters, if so remove hashtags using Regex:
    if len(status_covid) > 500:
        logger.warning("Status exceeds 500 characters, COVID19 post will be truncated.")
        import re
        while len(status_covid)>500:
            status_covid = re.sub(r"#\w+", "", status_covid, count=1)

    main_post = mdon.status_post(
        spoiler_text="Alberta COVID19 Wastewater Trends",
        status=status_covid,
        media_ids=media_ids,
        sensitive=False,
        visibility="unlisted",
    )

    logger.info("Done.")
