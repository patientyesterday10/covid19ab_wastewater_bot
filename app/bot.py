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

    with open("/tmp/output/calgary_wastewater.txt", "r") as f:
        yyc_caption = f.read()

    media_ids.append(
        mdon.media_post("/tmp/output/calgary_wastewater.png",
                        mime_type="image/png",
                        description=yyc_caption,
                        file_name="calgary_wastewater.png")
    )

    with open("/tmp/output/edmonton_wastewater.txt", "r") as f:
        yeg_caption = f.read()

    media_ids.append(
        mdon.media_post("/tmp/output/edmonton_wastewater.png",
                        mime_type="image/png",
                        description=yeg_caption,
                        file_name="edmonton_wastewater.png")
    )

    media_ids.append(
        mdon.media_post("/tmp/output/percentile_table.png",
                        mime_type="image/png",
                        description="Percentiles by Location for Alberta COVID19 Wastewater Trends",
                        file_name="percentile_table.png")
    )

    logger.info("Posting Status to Mastodon.")

    main_post = mdon.status_post(
        spoiler_text="#COVID19AB Wastewater Trends",
        status="Alberta #COVID19 Wastewater Update for {}."
               "\n"
               "Figures show the level of SARS-COV-2 RNA detected in wastewater sampling across Alberta. "
               "Percentile values reflect where the reading falls within the distribution of samples from that "
               "location.\n#Covid19AB\nData Source: https://covid-tracker.chi-csm.ca/".format(
                datetime.now().strftime("%Y-%m-%d")),
        media_ids=media_ids,
        sensitive=False,
        visibility="unlisted",
    )

    # Create subsequent post with table for visually impaired.

    with open('/tmp/output/location_trends.txt') as f:
        location_text = f.read()

    # Split into chunks of 500 characters based on sane break points.
    chunks = []
    while len(location_text) > 450:
        chunk = location_text[:450]
        chunk = chunk[:chunk.rfind('\n')]
        chunks.append(chunk)
        location_text = location_text[len(chunk):]
    # Append last location chunk.
    chunks.append(location_text)

    reply_post_id = main_post['id']
    for chunk in chunks:
        reply_post_id = mdon.status_post(
            status=chunk,
            in_reply_to_id=reply_post_id,
            visibility="unlisted",
            sensitive=True,
            spoiler_text="Location reading and trends for {}, {}/{}:".format(
                datetime.now().strftime("%Y-%m-%d"),
                chunks.index(chunk) + 1,
                len(chunks)
            )
        )

    logger.info("Posting Influenza 'A' Trends.")
    media_ids = []

    media_ids.append(
        mdon.media_post("/tmp/output/ab_influenza_a.png",
                        mime_type="image/png",
                        file_name="ab_influenza_a.png",
                        description="Alberta Influenza A Wastewater Trends",
                        )
    )
    if os.path.exists("/tmp/output/ab_influenza_b.png"):
        media_ids.append(
            mdon.media_post("/tmp/output/ab_influenza_b.png",
                            mime_type="image/png",
                            file_name="ab_influenza_b.png",
                            description="Alberta Influenza B Wastewater Trends",
                            )
        )
    else:
        logger.warning("No non-zero Influenza B data yet.")

    media_ids.append(
        mdon.media_post("/tmp/output/ab_rsv.png",
                        mime_type="image/png",
                        file_name="ab_rsv.png",
                        description="Alberta RSV Wastewater Trends",
                        )
    )


    main_post = mdon.status_post(
        spoiler_text="Alberta Influenza & RSV Trends",
        status="Alberta Influenza / RSV Wastewater Update for {}."
               "\n"
               "Figures show the level of virus detected in wastewater sampling across Alberta. "
               "Percentile values reflect where the reading falls within the distribution of samples from that "
               "location.\nData Source: https://covid-tracker.chi-csm.ca/".format(
            datetime.now().strftime("%Y-%m-%d")),
        media_ids=media_ids,
        sensitive=False,
        visibility="unlisted",
    )

    logger.info("Done.")
