library(data.table)
library(jsonlite)
library(ggplot2)
library(locfit)

setwd("/tmp")
dir.create("/tmp/output",showWarnings = F)

if(!exists("json_data")){
  tmpfile <- tempfile(fileext = ".json")
  download.file("https://chi-covid-data.pages.dev/aplWasteWaterAbData.json",tmpfile)
  json_data <- jsonlite::read_json(tmpfile)$data
  unlink(tmpfile)
  rm(tmpfile)
}

data <- rbindlist(lapply(names(json_data),function(x,data=json_data){
  cbind(rbindlist(data[[x]]),location=x)
}))

rm(json_data)

data[,date:=as.Date(date)]
data[,t:=as.numeric(date-min(date)),by=c("location")]

fits <- rbindlist(lapply(unique(data$location),FUN = function(loc){
  loc_data <- data[location==loc,list(date,t,avg,location)]
  # Add data to extrapolate to current date:
  addtl_days <- as.numeric(Sys.Date()-(max(loc_data$date)))
  if(addtl_days>=1){
    loc_data <-rbindlist(list(
      loc_data,
      data.table(date=seq(max(loc_data$date)+1,Sys.Date(),by=1),
                 t=seq(from=max(as.numeric(loc_data$t))+1,to=max(as.numeric(loc_data$t))+addtl_days,by=1),
                 avg=NA,
                 location=loc
                      )
      ))
  }


  fit <- locfit(avg ~ lp(t,nn=0.28), data=loc_data,mint=3,maxit=100,family="gaussian")
  preds <- predict(fit,newdata=loc_data$t,se.fit=T,band="local")

  # CI interval 95%
  ci_int = 0.95
  z <- qnorm(1-((1-ci_int)/2))
  ci_upper <- preds$fit + z * preds$se.fit
  ci_lower <- preds$fit - z * preds$se.fit

  # Combine results into a dataframe
  results <- data.frame(time = loc_data$t,
                        date = loc_data$date,
                        avg = loc_data$avg,
                        fit = preds$fit,
                        ci_lower = ci_lower,
                        ci_upper = ci_upper,
                        location = loc)


  return(results)
}))

fits[!is.na(avg),max_date:=max(date,na.rm=T),by=c("location")]
fits[,max_date:=max(max_date,na.rm=T),by=c("location")]
fits[,location:=paste0(location,"\n(Last Sample: ",max_date,")"),]
fits[,q:=ecdf(avg)(avg),by=c("location")]

p <- ggplot(fits,aes(x=date))+
  geom_ribbon(data=fits[date<=max_date,],aes(ymin=ci_lower,ymax=ci_upper),colour="skyblue4",fill="skyblue2",alpha=0.4,lty=2,lwd=0.4)+
  geom_ribbon(data=fits[date>=max_date,],aes(ymin=ci_lower,ymax=ci_upper),colour="darkorange2",fill="orange",alpha=0.4,lty=2,lwd=0.4)+
  geom_point(aes(y=avg),pch=21,fill="#00000022",size=1)+
  geom_line(data=fits[date<=max_date,],aes(y=fit),lwd=0.6,colour="blue")+
  #geom_line(data=fits[date>=max_date,],aes(y=fit),lwd=0.4,colour="darkorange3")+
  facet_wrap(~location,scales = "free_y",nrow=2)+
  scale_y_continuous(name="Viral Copies per Person\n(Note absolute scale varies by location)")+
  scale_x_date(name=NULL,
               date_breaks="1 month",
               date_labels = "%b",
               date_minor_breaks = "1 week")+
  theme_bw()+
  coord_cartesian(ylim=c(0,NA))+
  labs(title="Alberta: COVID19 in Wastewater",
       subtitle=glue::glue("Date of Latest Sample Varies by Location, Band represents 95% CI"),
       caption=glue::glue("Data Source: Alberta Health, Alberta Precision Laboratories & Centre for Health Informatics\n{Sys.Date()}")
  )

# Save plot
ggsave("output/ab_wastewater.png",plot=p,units="in",width=10,height=4,dpi=150,scale = 1.2)

