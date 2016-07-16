setwd("C:/Users/Giwrgos/Dropbox/Summer School/Recordings")

test = read.csv("sample_test.csv")
real = test$class
predsA = read.csv("bci_predictionsA.csv")
predsB = read.csv("bci_predictionsB.csv")
real = (real +1)/2


sum(real == predsA[,1])/length(real)
sum(real == predsB[,1])/length(real)

data = data.frame(cbind(real,predsA[,1],predsB[,1],seq(1,length(real))))

par(mfrow=c(3,1))
plot(predsA[,1],col="blue",pch=19,xlab="",main="Team A")
plot(predsB[,1],col="red",pch=19,xlab="",main="Team B")
plot(real,col="black",pch=19,xlab="",main="Real")

ggplot(data, aes(x)) +
    geom_point(aes(y = real, colour = "TRUE")) + 
    geom_point(aes(y = V2, colour = "Team A")) + 
    geom_point(aes(y = V3, colour = "Team B"))



library(ggplot2)
qplot(x,predsA[,1])
qplot(x,predsB[,1])

x = read.csv("Sub1_Ses5_raw.csv")
x$P8=NULL
x$T8=NULL
write.csv(x,"C:/Users/Giwrgos/Desktop/Sub1_Ses5_raw.csv",row.names = F)

x = read.csv("Sub2_Ses5_raw.csv")
x$P8=NULL
x$T8=NULL
write.csv(x,"C:/Users/Giwrgos/Desktop/Sub2_Ses5_raw.csv",row.names = F)

x = read.csv("Sub3_Ses5_raw.csv")
x$P8=NULL
x$T8=NULL
write.csv(x,"C:/Users/Giwrgos/Desktop/Sub3_Ses5_raw.csv",row.names = F)

x = read.csv("Sub4_Ses5_raw.csv")
x$P8=NULL
x$T8=NULL
write.csv(x,"C:/Users/Giwrgos/Desktop/Sub4_Ses5_raw.csv",row.names = F)

x = read.csv("Sub5_Ses5_raw.csv")
x$P8=NULL
x$T8=NULL
write.csv(x,"C:/Users/Giwrgos/Desktop/Sub5_Ses5_raw.csv",row.names = F)

