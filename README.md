# Spring 2026 CS 3200 Project

This is the repo for the Dr. Fontenot's Spring 2026 CS 3200 Course Project.

It includes a brief overview of Unboxd, the backend routing and rest api in api/, and the visualization/frontend in app/. Our schema is in database-files. 

This is the link to the demo video: https://drive.google.com/file/d/1Nu7hJ7YIjXaKkktru_eJwfGgLwbN0VHE/view?usp=sharing

## Overview of Unboxd 

Unboxd is a data driven e-commerce platform dedicated to connecting the artists and collectors of the blind box community. Our app seeks to connect collectors with limited-collection blind boxes and provide local artists with a centralized platform to better understand their audience and reach their customers. On our app, Collectors can browse a large catalog of blind boxes and either like or purchase those that catch their eye. By collecting and analyzing these buyer behaviors, Unboxd will enable sellers to better manage inventory, streamline their sales process, and be more equipped to handle the inherent volatility of the blind-box trend cycles. 

This platform will be built to address the needs of four user types. Artists will benefit from a digital platform where they can list unique figurines, collect sales, and track engagement data. Collectors serve as the platform buyer where they can browse, like, and purchase exclusive collections and blind box drops. The platform is supported behind-the-scenes by system administrators who regulate artist and buyer profiles, approve new item listings, and monitor transaction integrity. Platform Marketers additionally serve as a core user whose functionality is centralized around tracking sales trends and analyzing engagement data to inform internal marketing decisions. 

## Backend Logic

There are 5 flask blueprints that support the core functionalities of the 4 core user archetype:

analytics_routes.py: 

For the system administrator, it supports viewing real-time system activity, viewing alerts, monitoring orders, and managing artist applications

For the platform marketer, it supports viewing analytics such as trending searches and the most liked listings. It also supports viewing key metrics such as retention and the number of active users. 

artist_routes.py:

This supports the artist persona. It enables the artist to view their listing and items as well as update their profile.

listing_routes.py:

This supports functions such as viewing a listing and updating it. It also allows for listing moderation to keep the app safe.

items_routes.py:

This supports the artist persona to view their inventory before making a listing and also enables them to indicate if something is limited edition. 

orders_routes.py:

This blueprint allows a buyer persona to view their order history. It also allows the system administrator to view and manage fraud reports. 

## Streamlit 

The files under pages/ contain the frontend logic to actually view and see the web app. It allows the user to login as their role and then implements the visualization that goes with the associated blueprint. 


