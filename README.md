<!-- README Template from: https://github.com/othneildrew/Best-README-Template/ -->
<!-- MIT License Copyright (c) 2021 Othneil Drew. -->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]



<!-- PROJECT LOGO -->
<br />
<div align="center" style="align-content: center;">
  <a href="https://github.com/patientyesterday10/covid19ab_wastewater_bot">
    <img src="images/logo.png" alt="Logo" width="200" height="200">
  </a>

<h3 align="center">Alberta COVID19 Wastewater Bot for Mastodon</h3>

  <p align="center">
    This project contains the source code used for the Alberta COVID19 Mastodon BOT, which can be followed here: 
    <a href="https://botsin.space/@covid19ab_wastewater][https://botsin.space/@covid19ab_wastewater">https://botsin.space/@covid19ab_wastewater</a>
    <br />
    <a href="https://github.com/patientyesterday10/covid19ab_wastewater_bot/issues">Report Bug</a>
    ·
    <a href="https://github.com/patientyesterday10/covid19ab_wastewater_bot/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

This project is a Mastodon bot that posts the latest COVID19 wastewater data from
locations across Alberta, Canada. The data is sourced from the 
[Centre for Health Infomatics at the University of Calgary](https://covid-tracker.chi-csm.ca/). 
Figures are generated using R and the [ggplot2](https://ggplot2.tidyverse.org/) library.
The bot is written in Python and uses the [Mastodon.py](https://mastodonpy.readthedocs.io/en/stable/index.html) library to post to Mastodon.

The bot script runs in a containerized Docker environment, and is currently running daily scheduled using Github actions.


[![Sample BOT Posting][product-screenshot]](https://github.com/patientyesterday10/covid19ab_wastewater_bot)


<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With

* [![Python.org][python-shield]][python-url]
* [![R-project.org][r-shield]][r-url]
* [![Docker.com][docker-shield]][docker-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- ROADMAP -->
## Roadmap

See the [open issues](https://github.com/patientyesterday10/covid19ab_wastewater_bot/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>




<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/patientyesterday10/covid19ab_wastewater_bot.svg?style=for-the-badge
[contributors-url]: https://github.com/patientyesterday10/covid19ab_wastewater_bot/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/patientyesterday10/covid19ab_wastewater_bot.svg?style=for-the-badge
[forks-url]: https://github.com/patientyesterday10/covid19ab_wastewater_bot/network/members
[stars-shield]: https://img.shields.io/github/stars/patientyesterday10/covid19ab_wastewater_bot.svg?style=for-the-badge
[stars-url]: https://github.com/patientyesterday10/covid19ab_wastewater_bot/stargazers
[issues-shield]: https://img.shields.io/github/issues/patientyesterday10/covid19ab_wastewater_bot.svg?style=for-the-badge
[issues-url]: https://github.com/patientyesterday10/covid19ab_wastewater_bot/issues
[license-shield]: https://img.shields.io/github/license/patientyesterday10/covid19ab_wastewater_bot.svg?style=for-the-badge
[license-url]: https://github.com/patientyesterday10/covid19ab_wastewater_bot/blob/master/LICENSE.txt
[product-screenshot]: images/screenshot.png

[python-shield]: https://shields.io/badge/Python-blue?logo=python&style=for-the-badge&logoColor=white
[python-url]: https://www.python.org/
[r-shield]: https://shields.io/badge/R-blue?logo=R&style=for-the-badge
[r-url]: https://www.r-project.org/
[docker-shield]: https://shields.io/badge/Docker-blue?logo=docker&style=for-the-badge&logoColor=white
[docker-url]: https://www.docker.com/
