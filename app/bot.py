from mastodon import Mastodon
import os

mdon = Mastodon(
    access_token=os.environ['MASTODON_ACCESS_TOKEN'],
    api_base_url=os.environ['MASTODON_API_BASE_URL'],
)

# Upload media files:
media_ids = []

media_ids.append(
    mdon.media_post("/tmp/ab_wastewater.png",
                    mime_type="image/png",
                    description="Alberta COVID19 Wastewater Trends. Source: https://covid-tracker.chi-csm.ca/",
                    file_name="ab_wastewater.png")
)

media_ids.append(
    mdon.media_post("/tmp/calgary_wastewater.png",
                    mime_type="image/png",
                    description="Calgary COVID19 Wastewater Trends. Source: https://covid-tracker.chi-csm.ca/",
                    file_name="calgary_wastewater.png")
)

media_ids.append(
    mdon.media_post("/tmp/edmonton_wastewater.png",
                    mime_type="image/png",
                    description="Edmonton COVID19 Wastewater Trends. Source: https://covid-tracker.chi-csm.ca/",
                    file_name="edmonton_wastewater.png")
)

mdon.status_post("Alberta COVID19 Wastewater Trends. Source: https://covid-tracker.chi-csm.ca/",media_ids=media_ids)
