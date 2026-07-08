library(MASS)
library(RColorBrewer)
# Vector color
palette <- brewer.pal(3, "Set1") 
my_colors <- palette[as.numeric(iris$Species)]

# Make the graph !
parcoord(iris[,c(1:4)] , col= my_colors  )
# Reorder the variables
parcoord(iris[,c(1,3,4,2)] , col= my_colors  )

# Highlight a group
# Vector color: red if Setosa, grey otherwise.
isSetosa <- ifelse(iris$Species=="setosa","red","grey")

# Make the graph !
parcoord(iris[,c(1,3,4,2)] , col=isSetosa  )


# Libraries
library(GGally)
library(dplyr)

# Data set is provided by R natively
data <- iris

# Plot
data %>%
  arrange(desc(Species)) %>%
  ggparcoord(
    columns = 1:4, groupColumn = 5, order = "anyClass",
    showPoints = TRUE, 
    title = "Original",
    alphaLines = 1
  ) + 
  scale_color_manual(values=c( "#69b3a2", "#E8E8E8", "#E8E8E8") ) +
  theme_bw()+
  theme(
    legend.position="Default",
    plot.title = element_text(size=10)
  ) +
  xlab("")

## https://plot.ly/r/parallel-coordinates-plot/
library(plotly)

df <- read.csv("https://raw.githubusercontent.com/bcdunbar/datasets/master/iris.csv")

p <- df %>%
  plot_ly(type = 'parcoords',
          line = list(color = ~species_id,
                      colorscale = list(c(0,'red'),c(0.5,'green'),c(1,'blue'))),
          text = paste("Species: ", df$species,
                       "<br>length: ", df$petal_length
                       ),
          hoverinfo = 'text',
          dimensions = list(
            list(range = c(2,4.5),
                 label = 'Sepal Width', values = ~sepal_width),
            list(range = c(4,8),
                 constraintrange = c(5,6),
                 label = 'Sepal Length', values = ~sepal_length),
            list(range = c(0,2.5),
                 label = 'Petal Width', values = ~petal_width),
            list(range = c(1,7),
                 label = 'Petal Length', values = ~petal_length)
          )
  )

p


##### Outliers #####
# https://igraph.org/r/doc/cliques.html
library(igraph)
g <- sample_gnp(100, 0.3)
clique_num(g)
cliques(g, min=6)
largest_cliques(g)

# To have a bit less maximal cliques, about 100-200 usually
g <- sample_gnp(100, 0.03)
max_cliques(g)

#### Create vectors of pairs #### 
# Create vectors from matrices / needed for parallel coordinates plots

### FOR ICDSST2020 presentation ####
setwd("~/Google Drive File Stream/My Drive/Academy/PaperLand/Outranking Similarity")

library(bupaR)
library(tidyverse)
library(lubridate)
log<- read_csv("clusters_No=3_method=Simoutrank_Hierarchical.csv")
BuparLog <- log %>% 
  mutate_at(vars(Complete.Timestamp),funs(ymd_hms(.)))%>%
  mutate(status = "complete",Resource="A",activity_instance = 1:nrow(.)) %>%
  eventlog(
    case_id = "Case.ID",
    activity_id = "Activity",
    activity_instance_id = "activity_instance",
    lifecycle_id = "status",
    timestamp = "Complete.Timestamp",
    resource_id = "Resource"
  )

## Simplified map
library(processmapR)
library(edeaR)
BuparLog %>% 
  filter_activity_frequency(percentage = 0.6) %>%
  process_map(type = frequency("relative"))

# map cluster 1
BuparLog %>% 
  filter(groups==3) %>%
  filter_activity_frequency(percentage = 0.9) %>%
  process_map(type = frequency("relative"))
