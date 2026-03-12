# YouTube Comment Network Analysis

## Project Overview
This project analyzes user interaction patterns in YouTube comment sections by constructing and examining a weighted user–video bipartite network. Using comment data collected from multiple high-view videos, the project explores how engagement is distributed across users and videos, identifies highly connected nodes, and uncovers structural characteristics of interaction concentration.

The project was designed to move beyond simple descriptive statistics and instead frame comment behavior as a networked interaction system, allowing for a more structured analysis of participation intensity, content reach, and interaction concentration.

## Objectives
The main objectives of this project are to:

- collect and clean YouTube comment data from multiple popular videos
- construct a weighted bipartite network linking users and videos
- measure user participation and video-level engagement patterns
- identify highly active users and highly central videos
- visualize the structure of the interaction network and derive analytical insights

## Data Source
- Platform: YouTube
- Data collection method: YouTube API and R-based data extraction workflow
- Data scope: comments from 10+ high-view videos
- Network scale: 300+ nodes in the final weighted bipartite network

> Note: This repository contains processed analytical outputs and project code only. If raw data is restricted by platform policy or privacy considerations, only derived or anonymized data should be shared.

## Analytical Workflow

### 1. Data Collection and Cleaning
- collected comment data from multiple high-traffic YouTube videos
- standardized field names and removed invalid or duplicated observations
- cleaned user/video identifiers to support network construction
- transformed comment-level records into network-ready relational data

### 2. Network Construction
- built a weighted user–video bipartite network
- represented links based on commenting relationships
- incorporated edge weights to reflect interaction intensity or participation frequency
- prepared network objects for structural analysis and visualization

### 3. Indicator Design
At the **user level**, the project focuses on:
- participation intensity
- engagement breadth
- interaction concentration

At the **video level**, the project focuses on:
- audience coverage
- comment activity
- structural influence in the network

### 4. Exploratory Analysis and Visualization
- examined the distribution of user activity across videos
- identified concentrated participation patterns
- visualized the weighted bipartite structure
- highlighted core users and key videos with strong structural positions

## Key Findings
Some representative findings from the analysis include:

- user participation was highly uneven, with a small group of highly active users contributing disproportionately to the interaction structure
- some videos occupied structurally central positions not only because of total comment volume, but also because they attracted broader and more interconnected participation
- the bipartite network perspective provided a clearer view of cross-video engagement behavior than isolated single-video summaries
- interaction concentration suggests that a small subset of users and videos can significantly shape the visible communication structure of the comment ecosystem
