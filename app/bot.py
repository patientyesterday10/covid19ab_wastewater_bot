from datetime import datetime
import pandas as pd

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

    # Create some useful alt-text for visually impaired:
    # Get trend data:
    df = pd.read_csv("/tmp/output/location_trends.csv")

    df = df.sort_values(by=['percentile'], ascending=False)
    location_text = "Alberta COVID19 Wastewater Trends:"
    for index, row in df.iterrows():
        location_text += "\n{}: {}({}), {}".format(
            row['location'],
            row['value_label'],
            row['percentile'],
            row['trend_label']
        )

    # Upload media files:
    logger.info("Uploading Media Files.")
    media_ids = []

    media_ids.append(
        mdon.media_post("/tmp/output/ab_wastewater.png",
                        mime_type="image/png",
                        file_name="ab_wastewater.png",
                        description="Alberta COVID19 Wastewater Trends. Data Source: https://covid-tracker.chi-csm.ca/",
                        )
    )

    media_ids.append(
        mdon.media_post("/tmp/output/calgary_wastewater.png",
                        mime_type="image/png",
                        description="Calgary COVID19 Wastewater Trends. Data Source: https://covid-tracker.chi-csm.ca/",
                        file_name="calgary_wastewater.png")
    )

    media_ids.append(
        mdon.media_post("/tmp/output/edmonton_wastewater.png",
                        mime_type="image/png",
                        description="Edmonton COVID19 Wastewater Trends. Data Source: https://covid-tracker.chi-csm.ca/",
                        file_name="edmonton_wastewater.png")
    )

    logger.info("Posting Status to Mastodon.")

    main_post = mdon.status_post(
        status="Figures show the level of SARS-COV-2 RNA detected in wastewater sampling across Alberta. "
               "Percentile values reflect where the reading falls within the distribution of samples from that "
               "location. #Covid19AB\nSource: https://covid-tracker.chi-csm.ca/".format(
                datetime.now().strftime("%Y-%m-%d")
                ),
        media_ids=media_ids,
        sensitive=False,
        spoiler_text="Alberta COVID19 Wastewater Trends for {}".format(datetime.now().strftime("%Y-%m-%d")),
        visibility="unlisted",
    )

    main_post_id = main_post['id']
    # Create subsequent post with table for visually impaired.
    mdon.status_post(status=location_text,
                     in_reply_to_id=main_post_id,
                     visibility="unlisted",
                     sensitive=False,
                     )

    logger.info("Done.")
