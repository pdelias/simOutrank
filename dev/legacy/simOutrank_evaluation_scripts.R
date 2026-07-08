setwd("~/Dropbox/active/Outranking Similarity/Datasets")

EventLog1<-read.csv("./Log2.n10.Simple.csv")
EventLog2<-read.csv("./Log2.n10.Medium.csv")
EventLog3<-read.csv("./Log2.n10.Default.csv")

# Add a fictional ordinal variable
EventLog1$Urgency <- "R"
EventLog2$Urgency <- "Y"
EventLog3$Urgency <- "G"

##---- adding noise...
set.seed(123) 
noise1<- EventLog1[sample(nrow(EventLog1), 250), ]
noise2<- EventLog2[sample(nrow(EventLog2), 250), ]
noise3<- EventLog3[sample(nrow(EventLog3), 250), ]

EventLog1<- rbind(EventLog1,noise2, noise3)
EventLog2<- rbind(EventLog2,noise1, noise3)
EventLog3<- rbind(EventLog3,noise1, noise2)

EventLog1$Process<-1
EventLog2$Process<-2
EventLog3$Process<-3

global.Log<- rbind(EventLog1,EventLog2, EventLog3)

library(lubridate)
global.Log$startTime <-ymd_hms(global.Log$startTime)

library(data.table)
global.Log.DT <- data.table(global.Log)
global.Log.DT$Case.ID<- global.Log.DT[,.(Case.ID=paste(Process,case,sep="_")),]
setkey(global.Log.DT,Case.ID,startTime)

Log1.DT<- global.Log.DT[Process==1,.(case,event,startTime)]
Log2.DT<- global.Log.DT[Process==2,.(case,event,startTime)]
Log3.DT<- global.Log.DT[Process==3,.(case,event,startTime)]

#### ---- Check Duration as criterion #####
starting.Timestamp <- global.Log.DT[J(unique(Case.ID)),mult="first"]
complete.Timestamp<-global.Log.DT[J(unique(Case.ID)),mult="last"]
durations<- data.frame("Case.ID"=complete.Timestamp$Case.ID, "Dur"=complete.Timestamp$startTime- starting.Timestamp$startTime,"Process"=complete.Timestamp$Process)


library(vioplot)
library(ggplot2)
qplot(factor(Process), as.numeric(Dur), data = durations, geom = "violin")

summary(as.numeric(durations[durations$Process==3,]$Dur))
summary(as.numeric(durations$Dur))
# Go

#this is an ordinal criterion, 1st quartile=1, 2nd=2, etc.
# replace values with their rank
#test with noise 10% (the quartiles)
durations$DurLabel<-cut(as.numeric(durations$Dur),breaks=c(39,86,167,302,1742),labels=c(1,2,3,4))
# test with Log 2
durations$DurLabel<-cut(as.numeric(durations$Dur),breaks=c(54,89,160,300,2274),labels=c(1,2,3,4))
#test with medium
durations$DurLabel<-cut(as.numeric(durations$Dur),breaks=c(46,86,123,208,1345),labels=c(1,2,3,4))
#Find all the pairwise differences (between the elements of the vector), in absolute value
# and put them in a symmetric matrix 
duration.Difs<-abs(t(outer(as.numeric(durations$DurLabel), as.numeric(durations$DurLabel), "-")))
#just put names on rows/cols
rownames(duration.Difs)<-durations$Case.ID
colnames(duration.Difs)<-durations$Case.ID

summary(as.vector(duration.Difs[2001:3000,1001:2000]))
hist(as.vector(duration.Difs[2001:3000,1001:2000]))

####--- Check num of Events------
events.per.case<- global.Log.DT[,.N,by=.(case,Process)]
ggplot(events.per.case, aes(x=as.factor(Process), y=N)) +   geom_violin(trim=FALSE)

summary(events.per.case$N)
# The same as Duration


##### Edit Distance #####
traces.DT<- global.Log.DT[,.(Trace=paste(event,collapse="")),by=.(Case.ID)]

library(stringdist)

#Calculate edit distance using The Optimal String Alignment distance (osa) is like the 
#Levenshtein distance but also allows transposition of adjacent characters. 
Levenshtein<-stringdistmatrix(traces.DT$Trace,traces.DT$Trace, method="osa")
#just put names on rows/cols
rownames(Levenshtein)<-traces.DT$Case.ID
colnames(Levenshtein)<-traces.DT$Case.ID

#summary(as.vector(Levenshtein[2001:3000,2001:3000]))

# NOT RECOMMENDED

#### Common Activities ####

activities.Set<- as.character(sort(global.Log.DT[,unique(event),]))
activities.per.case.DT<- global.Log.DT[,.N,by=.(event,Case.ID)]

library(reshape2)
require(data.table)

#Transform in wide format (activities be the columns)
activities.DT<-dcast.data.table(activities.per.case.DT,Case.ID~event,value.var = "N",fill=0)
#Cosine Similarity for Activities
library(qlcMatrix)

activitiesT<-t(activities.DT[,-1,with=FALSE])
#Coerce as a sparse Matrix
sparse.activitiesT<-  as(activitiesT, "dgCMatrix")
aSim<- cosSparse(sparse.activitiesT)

# library(lsa)
# activitiesT<-t(activities.DT[,-1,with=FALSE])
# aSim<-cosine(activitiesT)

#summary(as.vector(aSim[2001:3000,1001:2000]))
#### Common Transitions #####

#Find all transitions
setkey(global.Log.DT,Case.ID,startTime)
#First find when a new case starts
new.case.idx<- cumsum(rle(global.Log.DT$Case.ID)$lengths)+1

#Create a data table for all transitions. One column will be the activity that occurs first (From) and the other column the second activity (To).

#Create a vector without the last activity
From<- as.character(global.Log.DT$event[-nrow(global.Log.DT)])

#--No discount--
#...and another without the first activity
To<- global.Log.DT$event[-1]

transitions.faulty <- data.table(From= From, To=To,Case.ID=global.Log.DT$Case.ID[-nrow(global.Log.DT)])
transitions<- transitions.faulty[!(new.case.idx-1),]

pasted.transitions<- transitions[,.(Pasted= paste(From,To,sep="_")),Case.ID]
transitions.per.case<- pasted.transitions[,.N,by=.(Pasted,Case.ID)]
#Transform in wide format (transitions be the columns)
transitions.DT<-dcast.data.table(transitions.per.case,Case.ID~Pasted,value.var = "N",fill=0)

#Cosine Similarity for Transitions

transitionsT<-t(transitions.DT[,-1,with=FALSE])
transSim_slow<-cosine(transitionsT)
#---No Discount end

# NEW with discount
To.1 <- as.character(global.Log.DT$event[-1])
To.2<- append(as.character(global.Log.DT$event[-c(1:2)]),"-")
To.3<- append(as.character(global.Log.DT$event[-c(1:3)]),c("-","-"))
To<-c(rbind(To.1,To.2,To.3))

tripleFrom <- c(rbind(From,From,From))
case<- global.Log.DT$Case.ID
tripleCase<- c(rbind(case,case,case))
weight<- rep(c(1,0.5,0.33),length(From))
transitions.faulty <- data.table(From= tripleFrom, To=To,Case.ID=tripleCase[-c((3*nrow(global.Log.DT)-2):(3*nrow(global.Log.DT)))],Weight=weight)

# toremove.1<- 3*new.case.idx-9
# toremove.2<- 3*new.case.idx-7
# toremove.3<- 3*new.case.idx-6
# toremove.4<- 3*new.case.idx-5
# toremove.5<- 3*new.case.idx-4
# toremove.6<- 3*new.case.idx-3
# toremove<- c(rbind(toremove.1,toremove.2,toremove.3,toremove.4,toremove.5,toremove.6)) # The next command does the same in 1 line!
toremove.idx<- as.vector(t(outer(3*new.case.idx,c(9,7,6,5,4,3),"-")))
transitions<- transitions.faulty[!toremove.idx,]

pasted.transitions<- transitions[,.(Pasted= paste(From,To,sep="_"),Weight),Case.ID]
transitions.per.case<- pasted.transitions[,.(W= sum(Weight)),by=.(Pasted,Case.ID)]

#Transform in wide format (transitions be the columns)
transitions.DT<-dcast.data.table(transitions.per.case,Case.ID~Pasted,value.var = "W",fun=sum,fill=0)
#Cosine Similarity for Transitions

transitionsT<-t(transitions.DT[,-1,with=FALSE])
library(qlcMatrix)
#Coerce as a sparse Matrix
sparse.transitionsT<-  as(transitionsT, "dgCMatrix")
transSim<- cosSparse(sparse.transitionsT)

summary(as.vector(transSim[1:1000,1001:2000]))

#### Urgency ####
#this is an ordinal criterion, Red=1, Y=2, G=3
# store the urgency of each case
Urgency.cases<- global.Log.DT[J(unique(Case.ID)),mult="first",.(Case.ID,Process,Urgency)]
# replace values with their rank
library(plyr)
Urgency.cases$Urgency<-as.numeric(revalue(Urgency.cases$Urgency, c("R"=1,"Y"=2,"G"=3)))

# Make it a bit more interesting by putting yellows in the other two groups...
set.seed(123)
toModify<-Urgency.cases[,.I[sample(.N, 50)],by=Process]$V1
Urgency.cases[toModify,Urgency:=2L]

#Find all the pairwise differences (between the elements of the vector), in absolute value
# and put them in a symmetric matrix 
Urgency.Difs<-abs(t(outer(Urgency.cases$Urgency, Urgency.cases$Urgency, "-")))
#just put names on rows/cols
rownames(Urgency.Difs)<- Urgency.cases$Case.ID
colnames(Urgency.Difs)<-Urgency.cases$Case.ID

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
Activities.concordance<- apply(aSim,1:2, function(x) concordance.partial(x,0.5,0.75))
Activities.discordance<-apply(aSim,1:2, function(x) discordance.partial(x,0.5,0.2))

Transitions.concordance<- apply(transSim,1:2, function(x) concordance.partial(x,0.15,0.5))
Transitions.discordance<-apply(aSim,1:2, function(x) discordance.partial(x,0.15,0.1))

Duration.concordance<-apply(duration.Difs,1:2,function(x) concordance.partial(x,1.5,0.5,increasing = FALSE))
Duration.discordance<-apply(duration.Difs,1:2, function(x) discordance.partial(x,1.5,2,increasing = FALSE))

Urgency.concordance<-apply(Urgency.Difs,1:2,function(x) concordance.partial(x,1.5,0,increasing = FALSE) )
Urgency.discordance<-apply(Urgency.Difs,1:2, function(x) discordance.partial(x,1.5,2.5,increasing = FALSE))

# Levenshtein.concordance<-apply(Levenshtein,1:2, function(x) concordance.partial(x,20,10,increasing = FALSE))
# Levenshtein.discordance<-apply(Levenshtein,1:2, function(x) discordance.partial(x,20,120,increasing = FALSE))

#### Aggregation ####
#---Concordance---
concordance.Weighted<-list(0.25*Activities.concordance,0.5*Transitions.concordance,0.25*Duration.concordance,0.5*Urgency.concordance)
Concordance <-Reduce('+',concordance.Weighted)

#---Discorddance---
#For each criterion calculate the (1-d)/(1-c) matrix
Activities.Div <- (1-Activities.discordance)/(1-Activities.concordance)
Transitions.Div <- (1-Transitions.discordance)/(1-Transitions.concordance)
Duration.Div <- (1-Duration.discordance)/(1-Duration.concordance)
Urgency.Div <- (1-Urgency.discordance)/(1-Urgency.concordance)
# Levenshtein.Div <- (1-Levenshtein.discordance)/(1-Levenshtein.concordance)

#Check if discordance is greater that concordance for every criterion
#If not, put 1 in the Div matrix, to not affect the multiplication
Activities.IsDisc<- Activities.discordance-Activities.concordance
Activities.Div[Activities.IsDisc<=0]<-1

Transitions.IsDisc<- Transitions.discordance-Transitions.concordance
Transitions.Div[Transitions.IsDisc<=0]<-1

Duration.IsDisc<- Duration.discordance-Duration.concordance
Duration.Div[Duration.IsDisc<=0]<-1

Urgency.IsDisc<- Urgency.discordance-Urgency.concordance
Urgency.Div[Urgency.IsDisc<=0]<-1

# Levenshtein.IsDisc<- Levenshtein.discordance-Levenshtein.concordance
# Levenshtein.Div[Levenshtein.IsDisc<=0]<-1

discordance.aggregation <- list(Activities.Div,Transitions.Div,Duration.Div,Urgency.Div)
Discordance <- 1- Reduce('*',discordance.aggregation)

#---final aggregation---
S <- pmin(Concordance,1-Discordance)

#------ Hierarchical Clustering-----
library(proxy)

hca<-hclust(as.dist(1-S), method= "ward.D")
groups<- cutree(hca, k = 3)

clusters<- data.frame(Case.ID= durations$Case.ID, Membership=groups)
solution.full<- merge(global.Log.DT,clusters,by="Case.ID")
solution<- solution.full[J(unique(Case.ID)),mult="first"]

table(solution$Process,solution$Membership)
sum(diag(table(solution$Process,solution$Membership)))/sum(table(solution$Process,solution$Membership))


hcd<-as.dendrogram(hca)
plot(hca, hang = -1)
# dendrograms

global.Log.DT<- merge(global.Log.DT,Urgency.cases,by="Case.ID")
write.csv(global.Log.DT,"global_Log2_n10_ord.csv")
saveRDS(S,file="similarity_ord.rds")

###### Evaluate others ######

#Log 2 (500) ord 
toTest<- read.csv("./agglo2_jaccard_min_ss_all.csv") # 0.9293333
toTest<- read.csv("./agglo2_jaccard_complete_ss_all.csv") # 0.5566667
toTest<- read.csv("./agglo2_hamming_min_ss_all.csv") # 0.9293333
toTest<- read.csv("./agglo2_hamming_complete_ss_all.csv")# 0.9293333
toTest<- read.csv("./agglo2_euclidean_complete_all.csv") # 0.636
toTest<- read.csv("./agglo2_euclidean_complete_ss_all.csv") # 0.344
toTest<- read.csv("./agglo2_euclidean_min_ss_all.csv") # 0.9646667
toTest<- read.csv("./agglo2_euclidean_min_all.csv") # 0.9293333
toTest<- read.csv("./agglo2_hamming_complete_all.csv") # 0.7113333
toTest<- read.csv("./agglo2_hamming_min_all.csv") # 0.9326667
toTest<- read.csv("./agglo2_jaccard_min_all.csv") # 0.9726667
toTest<- read.csv("./agglo2_jaccard_complete_all.csv") # 0.7766667
toTest<- read.csv("./agglo2_correlation_complete_ss_all.csv") # 0.9293333
toTest<- read.csv("./agglo2_correlation_min_ss_all.csv") # 0.9293333
toTest<- read.csv("./agglo2_correlation_min_all.csv") # 0.9293333
toTest<- read.csv("./agglo2_correlation_complete_all.csv") # 0.7813333

#Log 2 noise 10% (500) ord 
toTest<- read.csv("./agglo2_n10_correlation_min_all.csv") # 0.9333333
toTest<- read.csv("./agglo2_min10_euclidean_min_all.csv") # 0.9666667
toTest<- read.csv("./agglo2_n10_jaccard_min_all.csv") # 0.9666667
toTest<- read.csv("./agglo2_n10_hamming_min_all.csv") # 0.9333333
toTest<- read.csv("./agglo2_n10_hamming_min_ss_all.csv") # 0.9333333
toTest<- read.csv("./agglo2_n10_jaccard_min_ss_all.csv") # 0.9333333
toTest<- read.csv("./agglo2_n10_euclidean_min_ss_all.csv") # 0.9666667
toTest<- read.csv("./agglo2_n10_correlation_min_ss_all.csv") # 0.9333333


toTest.DT <- data.table(toTest)
setkey(toTest.DT,caseID,timestamp)
solution<- toTest.DT[J(unique(caseID)),mult="first"]

table(solution$Process,solution$Membership)
sum(diag(table(solution$Process,solution$Membership)))/sum(table(solution$Process,solution$Membership)) 

