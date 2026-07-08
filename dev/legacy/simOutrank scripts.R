setwd("~/Copy/Academy/PaperLand/Working/PM_ER/datasets+experiments")
# Sys.setlocale("LC_ALL", "C")
# Read the data source file
EventLog<-read.csv("./Filter1_MergedPatientsLog.csv")

#remove the 2 idiots, S24 & W2
EventLog<-EventLog[!EventLog$Case.ID=="S24",]
EventLog<-EventLog[!EventLog$Case.ID=="W2",]
EventLog$Case.ID<-droplevels(EventLog$Case.ID)

#####Create Traces#####
#order the data.frame first by patient ID, then by timestamp
EventLog[with(EventLog,order(Case.ID,Complete.Timestamp)),]


# replace event names with string codes
event.Classes<-unique(EventLog$Activity)
codes<-letters[1:length(event.Classes)]

#manually, because I couldn't find a way to escape backslashes...
codes<-paste("\"",codes,sep="")
codes<-paste(codes,"\"",sep="")
dictionary<- paste(event.Classes,codes,sep="=")
translator<-paste(dictionary,collapse=",")
translator <- c(Arrival="a", Assortment.2="b",Diagnosis="c",Blood.Test="d",Blood.Result="e",Clinic.Entrance="f",Exit.ER="g",Prescription="h",Biochem.Test="i",Biochem.Result="j",X.Ray.Test="k",X.Ray.Result="l",Enzyma.Test="m",Enzyma.Result="n",Additional.Test="o",Additional.Result="p",Registration="q",Assortment.1="r",Decision.ER.Treatment="s",Room.Entrance="t",Exit.Room="u")

EventLog$Activity.Code<-translator[EventLog$Activity]

#Support function to concatenate strings

myPaste<- function(x){
  ret<-paste(x,collapse="_")
  return(ret)
}

#Create traces
tracesDF<- aggregate(EventLog$Activity.Code,by=list(EventLog$Case.ID),FUN=myPaste)


#Transform traces from a string to a list
tracesLS<-strsplit(tracesDF[,2],"_")
# Extend each vector with NAs to get vectors of the same length
max.len <- max(sapply(tracesLS, length))
tracesLSEqual <- lapply(tracesLS, function(x) {c(x, rep(NA, max.len - length(x)))})
#Create the data.frame where is column is an activity
tracesSeqDF<-do.call(rbind.data.frame, tracesLSEqual)
names(tracesSeqDF)<-c(1:max.len)

#Create the final data.frame for traces
traces<-data.frame(Case.ID=tracesDF$Group.1,tracesSeqDF)

#####Common Activities#####

#Find distinct activities
activitiesSet<- sort(as.character(unique(unlist(tracesSeqDF))))

#A support function to find the vector of frequencies of each activity
getActVector<-function(row){
  #Create a zero vector
  v<-rep(0,length(activitiesSet))
  #find the frequencies
  a<-table(t(tracesSeqDF[row,]))
  #Find the index of each location in the vector
  idx<-match(names(a),activitiesSet)
  #Fill this slot by the corresponding frequency
  v[idx]<-a
  return(v)
}

#Fill the activities DF
activities<- do.call("rbind", sapply(1:nrow(tracesSeqDF), FUN = getActVector, simplify = FALSE))
colnames(activities)<-activitiesSet

#Cosine Similarity for Activities
library(lsa)
activitiesT<-t(activities)
aSim<-cosine(activitiesT)

#####Common Transitions####

#find all possible transitions
library(gtools)
vars<-permutations(length(activitiesSet),2,activitiesSet,repeats.allowed=T)
allvars<-paste(vars[,1],vars[,2],sep="")

#Create a dataframe to store the transitions within traces

#add empty rows
empty<-numeric(length(allvars))
emptyM<-matrix(rep(empty,nrow(tracesSeqDF)),nr=nrow(tracesSeqDF),byrow=TRUE)
transDF<-as.data.frame(emptyM)
colnames(transDF)<-allvars

library(caTools)
for (i in 1:nrow(tracesSeqDF)){
  tempRow<-as.character(unlist(tracesSeqDF[i,]))
  # remove empty elements
  tempRow<-tempRow[!is.na(tempRow)]
  l<-length(tempRow)
  if(l>1){
    tempCom<-combs(1:l,2)
    tempTrans<-apply(tempCom,1, function(x) paste(tempRow[x[1]],
                                                  tempRow[x[2]],sep=""))
    tempDif<-apply(tempCom,1,function(x) x[2]-x[1])
    tempDist<-1/tempDif
    tempMatrix<-cbind(tempTrans,tempDist)
    
    for (col in tempMatrix[,1]) {transDF[i,col]=sum(as.numeric(tempMatrix[which(tempMatrix[,1]==col),2]))}
  } #end if length>1
  print(i)
} #end for

#Transform the data.frame into a matrix
trans<-data.matrix(transDF)
#the matrix is fairly possible to contain a lot of zero columns
# Remove them to not clutter the transitions similarity
toRemove<-which(colSums(trans)==0)
if(length(toRemove)>0){
  #Transpose the dataframe and calculate the cosine similarity
  transitionsT<-t(trans[,-toRemove])}else {
    transitionsT<-t(trans) 
  }

transSim<-cosine(transitionsT)

##### Edit Distance #####
library(stringdist)

#remove underscores
tracesDF$seq<-gsub("_","",tracesDF$x)
#Calculate edit distance using The Optimal String Alignment distance (osa) is like the 
#Levenshtein distance but also allows transposition of adjacent characters. 
Levenshtein<-stringdistmatrix(tracesDF$seq,tracesDF$seq, method="osa")
#just put names on rows/cols
rownames(Levenshtein)<-tracesDF$Group.1
colnames(Levenshtein)<-tracesDF$Group.1

##### Unique classes of activities ####

# This attributes counts the difference between the number of unique classes 
# of activities that two traces contain.
tracesDF$unique.classes<-mapply(function(x) length(unique(unlist(strsplit(x,split="")))),tracesDF$seq)

#Find all the pairwise differences (between the elements of the vector), in absolute value
# and put them in a symmetric matrix 
Unique.Classes<-abs(t(outer(tracesDF$unique.classes, tracesDF$unique.classes, "-")))
#just put names on rows/cols
rownames(Unique.Classes)<-tracesDF$Group.1
colnames(Unique.Classes)<-tracesDF$Group.1

##### Number of events ####

# This attributes counts the difference between the number of events
#  that two traces contain.
tracesDF$events.num<-mapply(nchar,tracesDF$seq)

#Find all the pairwise differences (between the elements of the vector), in absolute value
# and put them in a symmetric matrix 
Events.Num<-abs(t(outer(tracesDF$events.num, tracesDF$events.num, "-")))
#just put names on rows/cols
rownames(Events.Num)<-tracesDF$Group.1
colnames(Events.Num)<-tracesDF$Group.1

#####Duration#####
#First calculate the duration of each case
#ids<-unique(EventLog$Case.ID) # the case IDs
ids<-levels(EventLog$Case.ID)
startIdx<-match(ids,EventLog$Case.ID) # the starting indices of each case in the Log
timestamps<-as.POSIXct(EventLog$Complete.Timestamp, format="%Y/%m/%d %H:%M:%OS") # get the timestamps

rles<- rle(as.character(EventLog$Case.ID)) # find the length of each case
cases.length <- rles$length[match(ids,rles$values)] # in the right order

startTimes<-timestamps[startIdx]
FinishTimes<-timestamps[startIdx+cases.length-1]

durations<-(FinishTimes-startTimes) # in minutes...

#Find all the pairwise differences (between the elements of the vector), in absolute value
# and put them in a symmetric matrix 
Duration.Difs<-abs(t(outer(durations, durations, "-")))
#just put names on rows/cols
rownames(Duration.Difs)<-ids
colnames(Duration.Difs)<-ids


#### Triage ####
#this is an ordinal criterion, Red=1, Y=2, G=3
# store the triage of each case
Triage.cases<- EventLog$Triage[startIdx]
# replace values with their rank
library(plyr)
Triage.cases<-as.numeric(revalue(Triage.cases, c("R"=1,"Y"=2,"G"=3)))
#Find all the pairwise differences (between the elements of the vector), in absolute value
# and put them in a symmetric matrix 
Triage.Difs<-abs(t(outer(Triage.cases, Triage.cases, "-")))
#just put names on rows/cols
rownames(Triage.Difs)<-ids
colnames(Triage.Difs)<-ids

#### Type ####
#this is a binary criterion: 1 for matching, 0 else

#store the tyoe of each case
Type.cases <- EventLog$Description[startIdx]
#Find if every pair matches and put the result in a symmetric matrix 
Type.match<-abs(t(outer(Type.cases, Type.cases, "==")))
#just put names on rows/cols
rownames(Type.match)<-ids
colnames(Type.match)<-ids

#### Timing ####
#this is a binary criterion: 1 for matching, 0 else

#store the type of each case
Timing.cases <- EventLog$Shift[startIdx]
#Find if every pair matches and put the result in a symmetric matrix 
Timing.match<-abs(t(outer(Timing.cases, Timing.cases, "==")))
#just put names on rows/cols
rownames(Timing.match)<-ids
colnames(Timing.match)<-ids

### Create composite criteria ###
Flow<- Levenshtein-(14*transSim)
Turmoil<- Unique.Classes+Events.Num

##### Outranking ####
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
Activities.concordance<- apply(aSim,1:2, function(x) concordance.partial(x,0.6,0.8))
Activities.discordance<-apply(aSim,1:2, function(x) discordance.partial(x,0.6,0.4))

Flow.concordance<- apply(Flow,1:2, function(x) concordance.partial(x,5,(-4),increasing = FALSE))
Flow.discordance<-apply(Flow,1:2, function(x) discordance.partial(x,5,10,increasing = FALSE))

Triage.concordance<-apply(Triage.Difs,1:2,function(x) concordance.partial(x,1.5,0,increasing = FALSE) )
Triage.discordance<-apply(Triage.Difs,1:2, function(x) discordance.partial(x,1.5,2.5,increasing = FALSE))

Type.concordance<-Type.match
Type.discordance<-(Type.match-Type.match) # a zero matrix

Timing.concordance<-Timing.match
Timing.discordance<-(Timing.match-Timing.match)

Duration.concordance<-apply(Duration.Difs,1:2,function(x) concordance.partial(x,116,26,increasing = FALSE))
Duration.discordance<-apply(Duration.Difs,1:2,function(x) discordance.partial(x,116,200,increasing = FALSE))

Turmoil.concordance<-apply(Turmoil,1:2,function(x) concordance.partial(x,8,2,increasing = FALSE))
Turmoil.discordance<-apply(Turmoil,1:2,function(x) discordance.partial(x,8,16,increasing = FALSE))

#### Aggregation ####
#---Concordance---
concordance.Weighted<-list(21*Activities.concordance,23*Flow.concordance,16*Triage.concordance, 3*Type.concordance,16*Timing.concordance,12*Duration.concordance, 9*Turmoil.concordance)
Concordance <-Reduce('+',concordance.Weighted)

#---Discorddance---
#For each criterion calculate the (1-d)/(1-c) matrix
Activities.Div <- (1-Activities.discordance)/(1-Activities.concordance)
Flow.Div <- (1-Flow.discordance)/(1-Flow.concordance)
Triage.Div <- (1-Triage.discordance)/(1-Triage.concordance)
Type.Div <- (1-Type.discordance)/(1-Type.concordance)
Timing.Div<- (1-Timing.discordance)/(1-Timing.concordance)
Duration.Div <- (1-Duration.discordance)/(1-Duration.concordance)
Turmoil.Div <- (1-Turmoil.discordance)/(1-Turmoil.concordance)

#Check if discordance is greater that concordance for every criterion
#If not, put 1 in the Div matrix, to not affect the multiplication
Activities.IsDisc<- Activities.discordance-Activities.concordance
Activities.Div[Activities.IsDisc<=0]<-1

Flow.IsDisc<- Flow.discordance-Flow.concordance
Flow.Div[Flow.IsDisc<=0]<-1

Triage.IsDisc<- Triage.discordance-Triage.concordance
Triage.Div[Triage.IsDisc<=0]<-1

Type.IsDisc<- Type.discordance-Type.concordance
Type.Div[Type.IsDisc<=0]<-1

Timing.IsDisc<- Timing.discordance-Timing.concordance
Timing.Div[Timing.IsDisc<=0]<-1

Duration.IsDisc<- Duration.discordance-Duration.concordance
Duration.Div[Duration.IsDisc<=0]<-1

Turmoil.IsDisc<- Turmoil.discordance-Turmoil.concordance
Turmoil.Div[Turmoil.IsDisc<=0]<-1

discordance.aggregation <- list(Activities.Div,Flow.Div,Triage.Div,Type.Div,Timing.Div,Duration.Div,Turmoil.Div)
Discordance <- 1- Reduce('*',discordance.aggregation)

#---final aggregation---
S <- pmin(Concordance,1-Discordance)

saveRDS(S, "simMatrix.rds")
S <- readRDS("simMatrix.rds")

#-----------Spectral Clustering---------
diag(S)<-0
# Normalized spectral clustering according to Ng, Jordan, and Weiss (2002)
D= diag(rowSums(S))
emat<-eigen(D)
Dminus<-emat$vectors%*%diag(emat$values^(-1/2))%*%t(emat$vectors)
I <- diag(dim(Dminus)[1]) # since D is a square matrix...
#L.sym= I- Dminus%*%S%*%Dminus, (it's practically the same with the next row)
L.sym=Dminus%*%S%*%Dminus
# Eigenvalues of Laplacian
evL=eigen(L.sym,symmetric=TRUE)
# Create the matric U from the first (last) k eigenvectors
U <- evL$vectors[,1:3]
#Form the matrix T from U by normalizing the rows to norm 1
 # first find the frobenius norms of eigenvectors
fnorms<- c(norm(as.matrix(U[,1],"f")),norm(as.matrix(U[,2],"f")),norm(as.matrix(U[,3],"f")))
  # now divide each element of U with the column norm
T<- sweep(U,2,fnorms,"/")

#kmeans
set.seed(100)
kmL<-kmeans(T,3,nstart=100)


# plot eigenvalues
plot(evL$values, axes=F, xlab = NA,ylab=NA)
box()
axis(side = 1, tck = -.015, labels = NA)
axis(side = 2, tck = -.015, labels = NA)
axis(side = 1, lwd = 0, line = -.8, cex.axis=0.7)
axis(side = 2, lwd = 0, line = -.6, las = 1, cex.axis=0.7)
mtext(side = 1, "Index", line = 1, cex=0.7)
mtext(side = 2, "Eigenvalues", line = 1.4, cex=0.7)

resDF<-data.frame("Case.ID"=tracesDF$Group.1,kmL$cluster)
towriteDF<-merge(EventLog,resDF,by="Case.ID")
#write to a csv file
write.csv(towriteDF, file="clusters_No=3_method=Simoutrank.csv")

#------ Hierarchical Clustering-----
library(proxy)

hca<-hclust(as.dist(1-S), method= "ward.D2")
groups<- cutree(hca, k = 3)

resDF<-data.frame("Case.ID"=tracesDF$Group.1,groups)
towriteDF<-merge(EventLog,resDF,by="Case.ID")
#write to a csv file
write.csv(towriteDF, file="clusters_No=3_method=Simoutrank_Hierarchical.csv")

hcd<-as.dendrogram(hca)



###### Visualisations ######
library(car) 
library(lattice) 
library(ggplot2)
library(vcd)

tracesDF$Durations<-as.numeric(durations)
tracesDF$Triage<-EventLog$Triage[startIdx]
tracesDF$Triage<- factor(tracesDF$Triage, levels = c("G","Y","R"))
tracesDF$Type<-Type.cases
tracesDF$Timing<-Timing.cases
tracesDF$Turmoil<- tracesDF$events.num+tracesDF$unique.classes
tracesDF$Membership <-as.factor(groups)


#boxplot for Durations
ggplot(tracesDF, aes(x=Membership, y=Durations, fill=Membership)) + geom_boxplot() +
  guides(fill=FALSE) + theme_bw()

#histogram from Triage
cbPalette <- c( "#009E73", "#F0E442",  "#D55E00", "#0072B2","#999999", "#E69F00","#CC79A7")
ggplot(tracesDF, aes(x=Membership, fill=Triage)) + 
  geom_histogram(binwidth=.5, position="fill")+ coord_flip()+
scale_fill_manual(values=cbPalette) + theme_bw()+ theme(axis.title.x = element_blank())

#or better
mosaicplot(table(tracesDF$Membership,tracesDF$Triage), col=cbPalette, main="",cex.axis=1.2,shade=c(2,4))
mtext("Cluster Membership", side=1, line=-13)
mtext("Triage", side=2, line=0.5)

#or even more better with vcd
mosaic(~Membership+ Triage, data=tracesDF,shade=TRUE)

#histogram for Type
ggplot(tracesDF, aes(x=Membership, fill=Type)) +  scale_fill_manual(values=cbPalette)+
  geom_histogram(binwidth=.5, position="fill")+ coord_flip()+
  theme_bw()+ theme(axis.title.x = element_blank())
#scale_fill_manual(values=cbPalette)+

#or better
mosaicplot(table(tracesDF$Membership,tracesDF$Type), col=cbPalette, main="",cex.axis=1.2, shade=c(2,4))
#or even more better with vcd
mosaic(~Membership+ Type, data=tracesDF,shade=TRUE)

#histogram for Timing
ggplot(tracesDF, aes(x=Membership, fill=Timing)) + 
  geom_histogram(binwidth=.5, position="fill")+   scale_fill_manual(values=cbPalette)+
  theme_bw()+ coord_flip() + theme(axis.title.x = element_blank())
#or even more better with vcd

mosaic(~Membership+ Timing, data=tracesDF,shade=TRUE)

#boxplot for events.num
ggplot(tracesDF, aes(x=Membership, y=events.num, fill=Membership)) + geom_boxplot() +
  guides(fill=FALSE) + theme_bw()

#box plot of events.num~Duration per Cluster
attach(tracesDF)
myStripStyle <- function(which.panel,factor.levels, ...)
{
  Palette= c("light grey", "light grey","light grey")
  panel.rect(0, 0, 1, 1, col = Palette[which.panel], border = 1)
  panel.text(x = 0.5, y = 0.5,lab = paste("Cluster ",factor.levels[which.panel])) 
}
l<-list(col="black")
y.axis<-sort(unique(events.num))
bwplot(events.num~Durations|Membership,pch="|",strip=myStripStyle ,
       par.settings = list(box.umbrella=l,box.rectangle = l), 
       ylab="Number of Events per case",scales=list(y=list(labels= y.axis)),
       xlab="Duration in minutes")

# dendrograms
#http://sebastianraschka.com/Articles/heatmaps_in_r.html
#http://rpubs.com/gaston/dendrograms
# load code of A2R function
source("http://addictedtor.free.fr/packages/A2R/lastVersion/R/code.R")
# colored dendrogram
#op = par(bg = "#EFEFEF")
op = par(bg = "whitesmoke")
A2Rplot(hca, k = 3, boxes = F, col.up = "gray50", col.down = c("gold","orange", "springgreen3"), main="")
par(op)


##### Chi-square tests ######

# Koehler and Larntz suggest that if the total number of observations is at least 10,
#the number categories is at least 3,
#and the square of the total number of observations is at least 10 times 
#the number of categories, then the chi-square approximation should be reasonable.

#tests for simOutrank
tbl.Triage <- table(tracesDF$Triage,tracesDF$Membership)
# Test the hypothesis whether Triage is independent of Cluster at .05 significance level.
chisq.test(tbl.Triage) 
fisher.test(tbl.Triage)


tbl.Type <- table(tracesDF$Type,tracesDF$Membership)
chisq.test(tbl.Type) 
fisher.test(tbl.Type)

tbl.Turmoil <- table(cut(tracesDF$Turmoil,breaks=c(8,14,20,25)),tracesDF$Membership)
chisq.test(tbl.Turmoil) 
fisher.test(tbl.Turmoil,workspace=2e+07,hybrid=TRUE)

tbl.Timing <- table(tracesDF$Timing,tracesDF$Membership)
t<-as.vector(tbl.Timing)
t<-t[-c(1,5,9)]
tt<-matrix(t,nrow=3)
chisq.test(tt)
fisher.test(tt,workspace=2e+07,hybrid=TRUE)

tbl.Durations <-table(cut(tracesDF$Durations,breaks=c(0,30,60,120,180,400)),tracesDF$Membership)
chisq.test(tbl.Durations)
fisher.test(tbl.Durations,workspace=2e+08,hybrid=TRUE)

# Other techniques
setwd("~/Dropbox/Active/Outranking Similarity/PC tests")
cl.res <- read.csv("./Clusters_agglo_centroid.csv")

#Because the dataframe is an event Log, and not a trace data frame, we need
#to get the indices of every trace
idx<-levels(cl.res$caseID)
start.idx<-match(ids,cl.res$caseID)
traces.other<- cl.res[start.idx,]

traces.other<-merge(x=traces.other,y=tracesDF,by.x="caseID",by.y="Group.1")

tbl.Triage.other<-table(traces.other$Triage.x,traces.other$Membership)
chisq.test(tbl.Triage.other) 
fisher.test(tbl.Triage.other)
#or even more better with vcd
mosaic(~Membership+ Triage.x, data=traces.other,shade=TRUE)

tbl.Type.other<-table(traces.other$Description,traces.other$Membership)
chisq.test(tbl.Type.other) 
fisher.test(tbl.Type.other,workspace=2e+07,hybrid=TRUE)
#or even more better with vcd
mosaic(~kmL.cluster+ Type, data=traces.other,shade=TRUE)

tbl.Turmoil.other<-table(cut(traces.other$Turmoil,breaks=c(8,14,20,25)),traces.other$Membership)
chisq.test(tbl.Turmoil.other) 
fisher.test(tbl.Turmoil.other,workspace=2e+07,hybrid=TRUE)
#or even more better with vcd
mosaic(~kmL.cluster+ Turmoil, data=traces.other,shade=TRUE)

tbl.Timing.other<-table(traces.other$Shift,traces.other$Membership)
t<-as.vector(tbl.Timing.other)
t<-t[-c(1,5,9)]
tt<-matrix(t,nrow=3)
chisq.test(tt)
fisher.test(tt)
#or even more better with vcd
mosaic(~kmL.cluster+ Timing, data=traces.other,shade=TRUE)

tbl.Durations.other <-table(cut(traces.other$Durations,breaks=c(0,60,120,180,400)),traces.other$Membership)
chisq.test(tbl.Durations.other)
fisher.test(tbl.Durations.other,workspace=2e+07,hybrid=TRUE)


attach(traces.other)
l<-list(col="black")
y.axis<-sort(unique(events.num))
bwplot(events.num~Durations|kmL.cluster,pch="|",strip=myStripStyle ,
       par.settings = list(box.umbrella=l,box.rectangle = l), 
       ylab="Number of Events per case",scales=list(y=list(labels= y.axis)),
       xlab="Duration in minutes")
