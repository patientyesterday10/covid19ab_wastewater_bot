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
                        description="Alberta COVID19 Wastewater Trends. Source: https://covid-tracker.chi-csm.ca/",
                        file_name="ab_wastewater.png")
    )

    media_ids.append(
        mdon.media_post("/tmp/output/calgary_wastewater.png",
                        mime_type="image/png",
                        description="Calgary COVID19 Wastewater Trends. Source: https://covid-tracker.chi-csm.ca/",
                        file_name="calgary_wastewater.png")
    )

    media_ids.append(
        mdon.media_post("/tmp/output/edmonton_wastewater.png",
                        mime_type="image/png",
                        description="Edmonton COVID19 Wastewater Trends. Source: https://covid-tracker.chi-csm.ca/",
                        file_name="edmonton_wastewater.png")
    )

    logger.info("Posting Status to Mastodon.")
    mdon.status_post(
        status="Alberta COVID19 Wastewater Trends. Source: https://covid-tracker.chi-csm.ca/",
        media_ids=media_ids
    )

    logger.info("Done.")
