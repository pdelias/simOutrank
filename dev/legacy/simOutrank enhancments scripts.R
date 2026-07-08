library(tidyverse)
library(data.table)


setwd("/Volumes/GoogleDrive/My Drive/Academy/PaperLand/Outranking Similarity/Robustness enhancements")

Log<- read_csv("Illustrative event Log.csv")
dt<-data.table(Log)
setkey(dt,Case.ID,Timestamp)

# Make a tibble just for case attributes
case.Log<- Log %>% 
  select(Case.ID,Status,Satisfaction) %>%
  group_by(Case.ID) %>%
  slice(1)

# For similarity matrix
# Satisfaction  is a binary criterion: 1 for matching (both High or both Low), 0 else
# The same for status

#Find if every pair matches and put the result in a symmetric matrix 
Satisfaction.match<-abs(t(outer(case.Log$Satisfaction, case.Log$Satisfaction, "==")))
#just put names on rows/cols
rownames(Satisfaction.match)<-case.Log$Case.ID
colnames(Satisfaction.match)<-case.Log$Case.ID

#Find if every pair matches and put the result in a symmetric matrix 
Status.match<-abs(t(outer(case.Log$Status, case.Log$Status, "==")))
#just put names on rows/cols
rownames(Status.match)<-case.Log$Case.ID
colnames(Status.match)<-case.Log$Case.ID

######-----Activities------
#--- Common Activities
activities.Set<- as.character(sort(dt[,unique(Activity),]))
activities.per.case.DT<- dt[,.N,by=.(Activity,Case.ID)]

library(reshape2)
require(data.table)

#Transform in wide format (activities be the columns)
activities.DT<-dcast.data.table(activities.per.case.DT,Case.ID~Activity,value.var = "N",fill=0)
#Cosine Similarity for Activities
library(qlcMatrix)

activitiesT<-t(activities.DT[,-1,with=FALSE])
#Coerce as a sparse Matrix
sparse.activitiesT<-  as(activitiesT, "dgCMatrix")
aSim<- cosSparse(sparse.activitiesT)
rownames(aSim)<- activities.DT$Case.ID

summary(as.vector(aSim))
hist(as.vector(aSim),breaks=5)
quantile(as.vector(aSim),0.15)

#### Common Transitions ####
Traces <- Log %>%
  arrange(Case.ID, Timestamp) %>%
  group_by(Case.ID)%>%
  summarise(Trace = paste(Activity, collapse=""))

case.Log<- left_join(case.Log,Traces)

# Edit Distance #
library(stringdist)
#Calculate edit distance using The Optimal String Alignment distance (osa) is like the 
#Levenshtein distance but also allows transposition of adjacent characters. 
Levenshtein<-stringdistmatrix(case.Log$Trace,case.Log$Trace, method="osa")
#just put names on rows/cols
rownames(Levenshtein)<-case.Log$Case.ID
colnames(Levenshtein)<-case.Log$Case.ID

##### -----Outranking------ ####
#returns partial concordance index
concordance.partial<-function(val,indifference,similarity, increasing=TRUE){
  if(increasing){
    if(val>similarity){
      ret<-1
    }else if(val>=indifference){
      ret<-(val-indifference)/(similarity-indifference)
    } else (ret<-0)}
  else
  {
    if(val<similarity){
      ret<-1
    }else if(val<=indifference){
      ret<-(val-indifference)/(similarity-indifference)
    } else (ret<-0)
  }
  return(ret)
}
vec.concordance.partial<-Vectorize(concordance.partial,vectorize.args="val")
#returns partial discordance index
discordance.partial<-function(val,indifference,veto, increasing=TRUE){
  if(increasing){
    if(val<=veto){
      ret<-1
    }else if(val<=indifference){
      ret<-(indifference-val)/(indifference-veto)
    } else (ret<-0)}
  else
  {
    if(val>=veto){
      ret<-1
    }else if(val>=indifference){
      ret<-(indifference-val)/(indifference-veto)
    } else (ret<-0)
  }
  return(ret)
}


#### partial indices for criteria ####

Activities.concordance<- apply(aSim,1:2, function(x) concordance.partial(x,0.7,0.8))
Activities.discordance<-apply(aSim,1:2, function(x) discordance.partial(x,0.7,0.4))


Transitions.concordance<- apply(Levenshtein,1:2, function(x) concordance.partial(x,3,2,increasing = F))
Transitions.discordance<-apply(aSim,1:2, function(x) discordance.partial(x,3,6, increasing = F))

Satisfaction.concordance<-apply(Satisfaction.match,1:2,function(x) concordance.partial(x,0,1))
Satisfaction.discordance<-apply(Satisfaction.match,1:2, function(x) discordance.partial(x,0,-1))

Status.concordance<-apply(Status.match,1:2,function(x) concordance.partial(x,0,1) )
Status.discordance<-apply(Status.match,1:2, function(x) discordance.partial(x,0,-1))

#### Aggregation ####
#---Concordance---
concordance.Weighted<-list(0.2*Activities.concordance,0.2*Transitions.concordance,0.3*Satisfaction.concordance,0.3*Status.concordance)

Concordance <-Reduce('+',concordance.Weighted)

#---Discordance---
#For each criterion calculate the (1-d)/(1-c) matrix
Activities.Div <- (1-Activities.discordance)/(1-Activities.concordance)
Transitions.Div <- (1-Transitions.discordance)/(1-Transitions.concordance)
Satisfaction.Div <- (1-Satisfaction.discordance)/(1-Satisfaction.concordance)
Status.Div <- (1-Status.discordance)/(1-Status.concordance)


#Check if discordance is greater that concordance for every criterion
#If not, put 1 in the Div matrix, to not affect the multiplication
Activities.IsDisc<- Activities.discordance-Activities.concordance
Activities.Div[Activities.IsDisc<=0]<-1

Transitions.IsDisc<- Transitions.discordance-Transitions.concordance
Transitions.Div[Transitions.IsDisc<=0]<-1

Satisfaction.IsDisc<- Satisfaction.discordance-Satisfaction.concordance
Satisfaction.Div[Satisfaction.IsDisc<=0]<-1

Status.IsDisc<- Status.discordance-Status.concordance
Status.Div[Status.IsDisc<=0]<-1

discordance.aggregation <- list(Activities.Div,Transitions.Div,Satisfaction.Div,Status.Div)
Discordance <- 1- Reduce('*',discordance.aggregation)

#---final aggregation---
S <- pmin(Concordance,1-Discordance)

Discordance.enh<- Discordance
Discordance.enh[6:8,11:25]<-1 
Discordance.enh[11:25,6:8]<-1
S<- pmin(Concordance,1-Discordance.enh)

#S<- S[1:23,1:23] # Removing outliers in the illustrative example
#S<-  readRDS("/Volumes/GoogleDrive/My Drive/Academy/PaperLand/Outranking Similarity/Datasets/Simplification/similarity_Matrix_BPIC11.rds")
S<- readRDS("/Volumes/GoogleDrive/My Drive/Academy/PaperLand/Outranking Similarity/Datasets/similarity_ord.rds")
#-----------Spectral Clustering---------

# Normalized spectral clustering according to Ng, Jordan, and Weiss (2002)
D= diag(rowSums(S))
L= D-S
emat<-eigen(D)
Dminus<-emat$vectors%*%diag(emat$values^(-1/2))%*%t(emat$vectors)
#I <- diag(dim(Dminus)[1]) # since D is a square matrix...
#L.sym= I- Dminus%*%S%*%Dminus # (it's practically the same with the next row)
L.sym=Dminus%*%L%*%Dminus
# Eigenvalues of Laplacian
evL=eigen(L.sym,symmetric=TRUE)
plot(tail(evL$values,30))
# Create the matrix U from the first (last) k eigenvectors
U<- t(tail(t(evL$vectors),4))
#U <- evL$vectors[,1:3]

#Form the matrix T from U by normalizing the rows to norm 1
# first find the frobenius norms of eigenvectors
#fnorms<- c(norm(as.matrix(U[,1],"f")),norm(as.matrix(U[,2],"f")),norm(as.matrix(U[,3],"f")),norm(as.matrix(U[,4],"f")))

fnorms<- c(norm(as.matrix(U[,1],"f")),
           norm(as.matrix(U[,2],"f")),
           norm(as.matrix(U[,3],"f")),
           norm(as.matrix(U[,4],"f")))
           #norm(as.matrix(U[,5],"f")))
           # norm(as.matrix(U[,6],"f")),
           # norm(as.matrix(U[,7],"f")))

# now divide each element of U with the column norm
T<- sweep(U,2,fnorms,"/")

#kmeans
set.seed(1000) 
kmL<-kmeans(T,4,nstart=100)
table(kmL$cluster)

Log<- read_csv("~/Google Drive File Stream/My Drive/Academy/PaperLand/Outranking Similarity/Datasets/global_Log2_n10_ord.csv")
cases.names<- Log %>%
  group_by(Case.ID)%>%
  slice(1) %>%
  select(Case.ID) 

rownames(S)<- cases.names$Case.ID
colnames(S)<- cases.names$Case.ID

resDF<-data.frame("Case.ID"=rownames(S),kmL$cluster)


#Log<- read_csv("~/Google Drive File Stream/My Drive/Academy/PaperLand/Outranking Similarity/Datasets/Simplification/Revision ITOR/Trans_L_BPIC11_simOutrank.csv")
#Log<- select(Log,-Membership)
Log.cl<- left_join(Log,resDF, by="Case.ID")
simOutrank.enh.cl1<- Log.cl %>% filter(kmL.cluster==1) %>% select(Case.ID, startTime, event, kmL.cluster)
simOutrank.enh.cl2<- Log.cl %>% filter(kmL.cluster==2)%>% select(Case.ID, startTime, event, kmL.cluster)
simOutrank.enh.cl3<- Log.cl %>% filter(kmL.cluster==3)%>% select(Case.ID, startTime, event, kmL.cluster)
simOutrank.enh.cl4<- Log.cl %>% filter(kmL.cluster==4)%>% select(Case.ID, startTime, event, kmL.cluster)
#simOutrank.enh.cl5<- Log.cl %>% filter(kmL.cluster==5)%>% select(Case.ID, startTime, event, kmL.cluster)
#simOutrank.enh.cl6<- Log.cl %>% filter(kmL.cluster==6)%>% select(Case.ID, Complete.Timestamp, Activity.Code, kmL.cluster)
#simOutrank.enh.cl7<- Log.cl %>% filter(kmL.cluster==7)%>% select(Case.ID, Complete.Timestamp, Activity.Code, kmL.cluster)


### PRocess models ####
library(bupaR)
library(heuristicsmineR)
library(petrinetR)
library(Matrix)

# create.logs4BupaR <- function(myLog){
#   myLog %>%
#     mutate(status = "complete",
#            activity_instance = 1:nrow(.),
#            Resource = NA) %>%
#     eventlog(
#       case_id = "Case.ID",
#       activity_id = "Activity.Code",
#       activity_instance_id = "activity_instance",
#       lifecycle_id = "status",
#       timestamp = "Complete.Timestamp",
#       resource_id = "Resource"
#     )
# }
library(lubridate)

create.logs4BupaR <- function(myLog){
  myLog %>%
    mutate(status = "complete",
           activity_instance = 1:nrow(.),
           Resource = NA,
           Complete.Timestamp = dmy_hms(startTime)) %>%
    eventlog(
      case_id = "Case.ID",
      activity_id = "event",
      activity_instance_id = "activity_instance",
      lifecycle_id = "status",
      timestamp = "Complete.Timestamp",
      resource_id = "Resource"
    )
}

#data<- read_xes("./Datasets/simOutrank_1_cl7.xes")
data = create.logs4BupaR(simOutrank.enh.cl4)
M<-dependency_matrix(data, threshold = .7)
dim(M)
nnzero(M)

###### Handling Outliers #######
library(lpSolve)

# Greedy method
rsums<- rowSums(S)
outliers <- which(rank(rsums, ties.method='min') <= floor(length(rsums)*0.1))
S<- S[-outliers,-outliers]




# set the number of outliers to be removed
k= floor(length(nrow(S))*0.0025)
# we need n*n vars for r_i,j and n nars for o_i
r_num = nrow(S)^2
o_num = nrow(S)
vector_s = as.vector(S)


# Set coefficients of the objective function
f.obj <- c(vector_s, rep(0,o_num))

## Constraints
# constraint about \sum{o}= k
constr1 = c(rep(0,r_num),rep(1,o_num))

#constraint about o_i <= r_i,j
constr2 <- matrix(0, o_num, length(f.obj))
for(i in 1:o_num){
  
      tempSet = c(rep(0,i-1),rep(-1,1),rep(0,o_num-i))
      tempRow = c(rep(tempSet,o_num),rep(-tempSet,1))
      constr2[i,]<- tempRow
}

#constraint about o_i<= r_j,i
constr3 <- matrix(0,o_num, length(f.obj))
o_zeros<- rep(0,o_num)
o_minus<- rep(-1,o_num)
for(i in 1:o_num){
  tempSetr = c(rep(o_zeros,i-1),rep(o_minus,1),rep(o_zeros,o_num-i))
  tempSeto = c(rep(0,i-1),rep(1,1),rep(0,o_num-i))
  constr3[i,]<- c(tempSetr,tempSeto)
}

f.con = rbind(constr1,constr2,constr3)

# Set unequality signs
f.dir <- c("=", rep("<=",2*o_num))

# Set right hand side coefficients
f.rhs <- c(k,rep(0,2*o_num))

# Final value (z)
lp("min", f.obj, f.con, f.dir, f.rhs,all.bin = TRUE)

# Variables final values
solution<- lp("min", f.obj, f.con, f.dir, f.rhs,all.bin = TRUE)$solution                   
library(usethis)
usethis::edit_r_environ()

#### Different settings ######

### Outliers - different percentages of trimming ####
library(ggthemes)
trim<- read_csv("Datasets/Outliers_trimmingPLG.csv")

trim<- trim %>%
  #select(-Nodes,Arcs) %>%
  pivot_longer(c(CN, CNC, CNCK), names_to = "Metric", values_to = "Figure") %>%
  filter(Percentage %in% c(0,5,10,15, 20))


ggplot(trim, aes(x = Percentage, y = Figure)) + 
  geom_line(aes(group = Value, color = Value, linetype=Value)) + 
  facet_wrap(~Metric,scales="free_y") +
  scale_color_manual(values=c("darkred", "steelblue"))+
  scale_linetype_manual(values=c("solid","twodash"))  +
  theme_clean() +
  theme(legend.position="bottom")+
  labs(x = "Percentage of trimming", y = "Performance")

 #### MUST LINK ####
library(clValid)
#The connectivity has a value between 0 and infinity and should be minimized.
valid_con<-connectivity(as.dist(1-S), kmL$cluster)
# Dunn Index combines measures of compactness and separation of the clusters. The Dunn Index is the ratio between the smallest distance between observations not in the same cluster to the largest intra-cluster distance. It has a value between 0 and infinity and should be maximized.
valid_dunn<-dunn(as.dist(1-S), kmL$cluster)

c(valid_con,valid_dunn)


## Must-link evaluation
cases.Log<- Log.cl %>%
  group_by(Case.ID)%>%
  slice(1)

### FAIL ATTEMPTS WITH BPIC11 LOG ####
#Baseline - num of Start.Deps per cluster
cases.Log %>%
  group_by(kmL.cluster) %>%
  summarise(num.Deps = n_distinct(Start.Depart), size=n())

# -num of clusters per Start.Dep
cases.Log %>%
  group_by(Start.Depart) %>%
  summarise(num.cl = n_distinct(kmL.cluster), size=n())


#Find if every pair matches and put the result in a symmetric matrix 
StartDep.match<-abs(t(outer(cases.Log$Start.Depart, cases.Log$Start.Depart, "==")))
#just put names on rows/cols
rownames(StartDep.match)<-cases.Log$Case.ID
colnames(StartDep.match)<-cases.Log$Case.ID

toExclude<- which(cases.Log$Start.Depart %in% c("General Lab Clinical Chemistry","Nursing ward","Emergency room","Endoscopy","Maternity ward"))
# These three departments are excluded from the must-link constraints.
StartDep.match[toExclude,]= 0
StartDep.match[,toExclude]= 0
diag(StartDep.match)= 0

S<- S+ (2*StartDep.match)

#Find if every pair matches and put the result in a symmetric matrix 
Treat.match<-abs(t(outer(cases.Log$Treat.101, cases.Log$Treat.101, "==")))
#just put names on rows/cols
rownames(Treat.match)<-cases.Log$Case.ID
colnames(Treat.match)<-cases.Log$Case.ID


S<- S*Treat.match


# Plot of distribution dep per cluster
# Stacked + percent
stacked.cases<- cases.Log %>%
  group_by(Start.Depart, kmL.cluster) %>%
  summarise(n = n()) %>%
  mutate(freq = prop.table(n))

# The palette with grey:
cbp1 <- c("#999999", "#E69F00", "#56B4E9", "#009E73",
          "#F0E442", "#0072B2", "#D55E00")

ggplot(stacked.cases, aes(fill=as.factor(kmL.cluster), y=freq ,x=Start.Depart)) + 
  geom_bar(position="fill", stat="identity") +
  scale_fill_manual(values = cbp1)+
  theme_bw() +
  theme(legend.position="bottom", legend.box = "horizontal")+
  guides(fill = guide_legend(title.position = "left", label.hjust = 1,nrow=1))+
  theme(axis.text.x = element_text(angle = -60, vjust = 0.2, hjust=0.1))+
  labs(x = "Start Department", y = "Percentage of cluster in the Department",fill="Cluster")
 ### MUST LINK ARTIFICIAL LOG 500 ####


#proportion of Urgency categories per cluster
stacked.cases<-cases.Log %>%
  group_by(kmL.cluster, Urgency.y) %>%
  summarise(n = n()) %>%
  mutate(freq = prop.table(n))

stacked.data<- read_csv("Datasets/MustLink_Urgency.csv")
stacked.cases<- stacked.data %>%
  filter(Method=="Domain")

# The palette
cbp1 <- c("steelblue","darkred","#009E73" )

ggplot(stacked.cases, aes(fill=as.factor(Urgency.y), y=freq ,x=kmL.cluster)) + 
  geom_bar(position="fill", stat="identity") +
  scale_fill_manual(values = cbp1)+
  theme_bw() +
  theme(legend.position="bottom", legend.box = "horizontal")+
  guides(fill = guide_legend(title.position = "left", label.hjust = 1,nrow=1))+
  theme(axis.text.x = element_text(angle = 0, vjust = 0.2, hjust=0.1))+
  labs(x = "Cluster", y = "Percentage of Urgency category",fill="Urgency")

#Find if every pair matches and put the result in a symmetric matrix 
Urgency.match<-abs(t(outer(cases.Log$Urgency.y, cases.Log$Urgency.y, "!=")))

S<- S^Urgency.match
